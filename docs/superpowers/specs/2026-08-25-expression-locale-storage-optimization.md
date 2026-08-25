# D1 詞典核心資料與索引空間優化設計

日期：2026-08-25

狀態：設計已確認，待實作

## 1. 摘要

LangMap 將以一套 canonical tables 直接承載人工內容與詞典內容，不再保留 packed dictionary mirror、release、claim、binding、evidence 或 attestation audit 模型。

本設計採用以下原則：

1. 採 greenfield 重建，不複製既有大型表，也不保證舊 expression／edge URL 相容。
2. expression、edge、language、locale、source、handbook 等高頻 ID 改用不可重用的整數。
3. API 以十進位字串表示數字 ID，例如 `/mapping/2056`；D1 不另存 public ID。
4. 詞典直接匯入 `expressions`、`expression_readings`、`expression_locale_links` 與 `expression_edges`。
5. 定義、標籤與 AI reconciliation 證據只保留在離線 artifact；例句建立為獨立 expression 與 mapping。
6. AI 只自動執行高信心 sense 合併；低信心資料建立新的 `homograph_index`。
7. 大型列表使用索引順序與 cursor，不使用深層 `OFFSET` 或 SQL temporary sort。
8. 每個現有 D1 索引都必須有明確的保留、替換或隨表刪除結論。
9. 完整 canonical D1 的硬性空間預算低於 5 GiB。

## 2. 範圍與非目標

### 2.1 範圍

- canonical language／locale registry。
- expressions、readings、locale links、mapping edges。
- morphology form edges 與 POS bitmask。
- votes、handbooks、UI localization 與 user preferences 的必要外鍵及索引。
- structured JSONL 的逐部詞典匯入與 AI 高信心合併。
- 本地 D1 的空間、匯入吞吐與核心查詢驗收。

### 2.2 非目標

- 不保留舊 `cmn:hash`、`d00002056` 或其他文字 ID alias。
- 不做既有大型 D1 表的 expand/contract backfill。
- 不建立 packed dictionary、release、claim 或線上 reconciliation audit tables。
- 不把定義或標籤匯入線上 D1。
- 不建立全文搜尋 FTS index；詞句搜尋改為 prefix search。
- 不提供全站最新 expression、全站 edge feed 或 `/users/me` 活動列表。
- 不為已移除功能保留相容 view、route、response 欄位或索引。

## 3. Greenfield 重建與 ID 契約

### 3.1 重建策略

現有大型資料可丟棄。實作時直接建立最終 schema，再由 structured JSONL 重新匯入；不得先把 packed dictionary 搬到 canonical tables，再做第二次整數化重建。

本地開發環境使用 fresh D1 rebuild。遠端環境若存在需要保留的內容，必須另行取得明確授權並建立獨立切換方案；本 spec 不授權直接刪除遠端資料。

重建期間只允許匯入必要的小型 seed。大型舊 expression、reading、edge、release、claim、evidence 與 packed rows 不回填。

### 3.2 數字 ID

會暴露到 API 或被大量外鍵引用的主表使用：

```sql
id INTEGER PRIMARY KEY AUTOINCREMENT
```

`AUTOINCREMENT` 確保已刪除的 ID 不會被重新分配。適用於：

- `languages`
- `language_locales`
- `sources`
- `expressions`
- `expression_edges`
- `expression_form_edges`
- `expression_splits`
- `handbooks`
- `handbook_sections`

純關聯表不新增 surrogate ID，改用複合主鍵與 `WITHOUT ROWID`。

### 3.3 API ID

- API 將數字 ID 以十進位字串返回，例如 `"2056"`。
- 路由使用 `/mapping/2056`、`/expressions/2056`。
- request parser 只接受正整數，並拒絕超出 JavaScript safe integer 的值。
- 排序、join、FK 與 cursor 都使用 D1 的整數 ID。
- 不保留舊 ID mapping table 或文字 public ID 欄位。

### 3.4 保留文字自然鍵

以下短文字具有實際業務語義，繼續保留：

- `scripts.code`
- `regions.code`
- morphology／POS codes
- `project_id`
- `message_key`
- `preference_key`
- reading `scheme`
- language／locale 的公開 `code`

## 4. Language 與 locale registry

### 4.1 Languages

```sql
CREATE TABLE languages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name_en TEXT NOT NULL
  -- 其餘既有顯示欄位按目前功能保留
);
```

`expressions` 不再重複保存 `lang_code`，改存 `language_id INTEGER`。API 查詢時 join `languages` 投影 code。

### 4.2 Language locales

```sql
CREATE TABLE language_locales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  language_id INTEGER NOT NULL,
  script_code TEXT,
  orthography TEXT,
  region_code TEXT,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  FOREIGN KEY (language_id) REFERENCES languages(id),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code)
);

CREATE UNIQUE INDEX idx_language_locales_identity
ON language_locales (
  language_id,
  COALESCE(script_code, ''),
  COALESCE(orthography, ''),
  COALESCE(region_code, ''),
  place_path
);
```

此唯一索引同時負責 locale 組合去重及按 `language_id` 列出 locale，不再建立額外 `language_id` index。

### 4.3 不保留 language profile 模型

目前 canonical runtime 使用 language 與 language locale。舊名稱 `language_profile_code` 必須改為 `language_locale_id` 或對外的 `language_locale_code`，不得建立 `language_profiles` 表或延續混合命名。

## 5. Expressions

### 5.1 最終資料模型

```sql
CREATE TABLE expressions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  language_id INTEGER NOT NULL,
  text TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1
    CHECK (homograph_index >= 1),
  pos_mask INTEGER NOT NULL DEFAULT 0
    CHECK (pos_mask >= 0),
  source_id INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (language_id, text, homograph_index),
  FOREIGN KEY (language_id) REFERENCES languages(id),
  FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_expressions_language_created
ON expressions(language_id, created_at DESC);
```

只保留三種存取結構：

1. integer rowid primary key。
2. `(language_id, text, homograph_index)` identity unique。
3. `(language_id, created_at DESC)` 語言內最新列表。

### 5.2 移除欄位

從線上 `expressions` 移除：

- `text_hash`
- `description`
- `tags_json`
- `source_ref`
- `review_status`
- `updated_at`

`created_by` 與 `created_at` 保留。`created_by` 不建立查詢索引，也不恢復使用者活動列表。

### 5.3 Identity 與 homograph

- expression identity 是 `(language_id, canonical text, homograph_index)`。
- canonical text 規則必須由匯入器與 API 共用。
- 同一文字的第一個 sense 使用 `homograph_index = 1`。
- 新增且不能高信心合併的 sense 使用目前最大 index 加一。
- index 永不重排、永不重用。
- 合併兩個既有 sense 時保留較小 index，較大 index 作廢。
- 作廢 index 記入離線 sense registry；後續配號以線上現存及離線作廢 index 的最大值加一，不因刪除或合併而回收。
- 初次全量重建依離線 sense fingerprint 穩定排序後配發 index。

### 5.4 詞性 bitmask

`parts_of_speech` 增加：

```sql
bit_index INTEGER NOT NULL UNIQUE
  CHECK (bit_index BETWEEN 0 AND 62)
```

規則：

- `bit_index` 一旦分配不得更改或重用。
- `sort_order` 只控制顯示，不影響 bit。
- 一個 expression 可同時具有多個 POS bit。
- 未識別詞性不寫入 mask，記入離線匯入報告。

## 6. Locale membership 與 readings

### 6.1 Expression locale links

```sql
CREATE TABLE expression_locale_links (
  expression_id INTEGER NOT NULL,
  locale_id INTEGER NOT NULL,
  PRIMARY KEY (expression_id, locale_id),
  FOREIGN KEY (expression_id)
    REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (locale_id)
    REFERENCES language_locales(id) ON DELETE RESTRICT
) WITHOUT ROWID;

CREATE INDEX idx_expression_locale_links_locale
ON expression_locale_links(locale_id, expression_id);
```

兩個方向都有實際用途：

- PK 支援 expression 詳情取得全部 locales。
- reverse index 支援大型語料的 locale 計數、篩選與反向查詢。

此表不保存獨立 ID、source、建立者或時間。

### 6.2 Locale API

不建立 `expression_locale_attestations` 相容 view。移除舊 attestation route，改用：

```text
PUT    /api/v2/expressions/:id/locales/:localeCode
DELETE /api/v2/expressions/:id/locales/:localeCode
```

`PUT` 必須 idempotent；response 使用 locale code，不生成 attestation ID。Expression 詳情 response 使用 `locales`，不再返回 `attestations`。

### 6.3 Expression readings

Reading 沒有獨立詳情、按 ID 更新或刪除功能，因此不保存 reading ID：

```sql
CREATE TABLE expression_readings (
  expression_id INTEGER NOT NULL,
  locale_id INTEGER NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id INTEGER,
  PRIMARY KEY (expression_id, locale_id, scheme, value),
  FOREIGN KEY (expression_id)
    REFERENCES expressions(id) ON DELETE CASCADE,
  FOREIGN KEY (locale_id)
    REFERENCES language_locales(id) ON DELETE RESTRICT,
  FOREIGN KEY (source_id)
    REFERENCES sources(id) ON DELETE SET NULL
) WITHOUT ROWID;
```

- 同一 reading 重複匯入時不增加 row。
- API／前端以四個主鍵欄位組成 list key。
- 多個 source 提供相同 reading 時，只保留固定排名最高的代表 `source_id`。

## 7. Sources

```sql
CREATE TABLE sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  UNIQUE (type, name)
);
```

線上 D1 只在 `expressions.source_id` 與 `expression_readings.source_id` 保存一個代表 source。所有 `source_ref` 及其他表的 source 欄位移除。

每部詞典在離線設定中具有固定 `source_rank`：

- 高信心合併後保留 rank 較高 source。
- fresh rebuild 必須先按 `(type, name)` 穩定排序建立 source registry，確保 source ID 配發可重現。
- rank 相同時以此穩定配發的 source ID 決定，確保結果不受詞典匯入順序影響。
- 低 rank 後續匯入不得覆蓋高 rank source。
- 完整 source 集合只存在離線 reconciliation artifact。

## 8. Expression edges 與 mapping

### 8.1 最終資料模型

```sql
CREATE TABLE expression_edges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  expression_a_id INTEGER NOT NULL,
  expression_b_id INTEGER NOT NULL,
  relation_mask INTEGER NOT NULL DEFAULT 1
    CHECK (relation_mask BETWEEN 1 AND 7),
  score INTEGER NOT NULL DEFAULT 0,
  created_by INTEGER,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_expression_edges_b_id
ON expression_edges(expression_b_id);
```

最終只有三種存取結構：

1. integer rowid primary key。
2. pair unique；同時支援 `expression_a_id` 前綴查詢。
3. `expression_b_id` 反向查詢索引。

不保存 `source` 或 `created_at`，不建立 creator、score 或 feed index。使用者與系統建立的 edge 都保存數字 `created_by`；詞典匯入使用專用 system user。

### 8.2 Relation mask

- bit 0（`1`）：一般詞句映射。
- bit 1（`2`）：同義關係。
- bit 2（`4`）：例句映射。

同一 pair 有多種關係時做 bitwise OR，不新增重複 edge，也不得用 `MIN(relation_kind)` 丟棄資訊。

### 8.3 Mapping 列表

Mapping 列表顯示某 expression 的一跳直接鄰居。它保留分頁，但取消 `OFFSET` 與 score／時間排序：

1. 先以 pair unique 查 `expression_a_id = :id`，按 `expression_b_id` 索引順序返回。
2. 再以 `idx_expression_edges_b_id` 查 `expression_b_id = :id`，按隱含 rowid／edge ID 順序返回。
3. cursor 保存目前階段與最後索引鍵。
4. 不使用 SQL temporary sort，也不在前端排序。

### 8.4 Mapping graph

Graph 最多 3 hops、200 nodes，每個節點最多展開 50 個鄰居。Traversal 使用與 mapping 列表相同的兩方向 adjacency scan，每層以 D1 batch 讀取：

- 不按 score 決定納入順序。
- 不先載入高連接節點的全部 edges。
- 不使用 SQL temporary sort。
- 達到上限立即停止並返回 omitted count。

Graph API 支援可選的 `target_language`：

```text
GET /api/v2/expressions/:id/graph?hops=2&target_language=cmn
```

- 未指定時顯示所有語言。
- 指定時保留 root，第一層只保留指定語言的直接 mapping。
- 多層 graph 只在 root language 與 target language 之間交替展開。
- 排除第三種語言與同語言內部 edge。
- 查詢 join neighbor expression 的 `language_id` 過濾，不在 edge 重複保存 language ID。

## 9. Votes 與 handbook hot

### 9.1 Edge votes

```sql
CREATE TABLE edge_votes (
  user_id INTEGER NOT NULL,
  edge_id INTEGER NOT NULL,
  vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
  PRIMARY KEY (user_id, edge_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE INDEX idx_edge_votes_edge ON edge_votes(edge_id);
```

### 9.2 Handbook votes

```sql
CREATE TABLE handbook_votes (
  user_id INTEGER NOT NULL,
  handbook_id INTEGER NOT NULL,
  vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
  PRIMARY KEY (user_id, handbook_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
) WITHOUT ROWID;

CREATE INDEX idx_handbook_votes_handbook ON handbook_votes(handbook_id);
```

兩表不保存 vote ID、target type、建立或更新時間。投票寫入與 cached score 更新必須在同一 D1 batch 完成：

- 相同 vote 再次點擊可取消。
- `1` 與 `-1` 可互相切換。
- `expression_edges.score = SUM(edge_votes.vote)`。
- `handbooks.score = SUM(handbook_votes.vote)`。
- 測試必須包含 cached score reconciliation。

## 10. Handbooks

### 10.1 Handbooks

`handbooks.id` 改為整數，`language_profile_code` 改為 `language_locale_id INTEGER`。保留 `score` 與 handbook hot 功能。

```sql
CREATE INDEX idx_handbooks_visibility_created
ON handbooks(visibility, created_at DESC, id ASC);

CREATE INDEX idx_handbooks_visibility_score
ON handbooks(visibility, score DESC, created_at DESC, id ASC);
```

刪除 `(user_id, created_at, id)` 活動索引。

### 10.2 Handbook sections

```sql
-- id INTEGER PRIMARY KEY AUTOINCREMENT
UNIQUE (handbook_id, position)

CREATE INDEX idx_handbook_sections_parent
ON handbook_sections(handbook_id, parent_section_id, position, id);
```

`UNIQUE(handbook_id, position)` 已支援同一本 handbook 的順序，不建立額外 `(handbook_id, position, id)` index。

### 10.3 Handbook section items

```sql
CREATE TABLE handbook_section_items (
  section_id INTEGER NOT NULL,
  position INTEGER NOT NULL,
  expression_id INTEGER NOT NULL,
  PRIMARY KEY (section_id, position),
  UNIQUE (section_id, expression_id),
  FOREIGN KEY (section_id)
    REFERENCES handbook_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (expression_id)
    REFERENCES expressions(id) ON DELETE RESTRICT
) WITHOUT ROWID;
```

資料本身按 section／position 儲存，不再建立 `idx_handbook_section_items_section`。

## 11. Morphology 與 split undo

### 11.1 Form edges

```sql
CREATE TABLE expression_form_edges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  form_id INTEGER NOT NULL,
  lemma_id INTEGER NOT NULL,
  created_by INTEGER,
  CHECK (form_id <> lemma_id),
  UNIQUE (form_id, lemma_id),
  FOREIGN KEY (form_id) REFERENCES expressions(id),
  FOREIGN KEY (lemma_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_expression_form_edges_lemma_id
ON expression_form_edges(lemma_id);
```

移除 `pair_low`、`pair_high`、`source`、`created_at` 與獨立 form index。`UNIQUE(form_id, lemma_id)` 已支援 form 查詢。

使用 `BEFORE INSERT` trigger 拒絕既有反向 pair：

```sql
WHEN EXISTS (
  SELECT 1 FROM expression_form_edges
  WHERE form_id = NEW.lemma_id
    AND lemma_id = NEW.form_id
)
```

### 11.2 Form features

```sql
CREATE TABLE expression_form_edge_features (
  edge_id INTEGER NOT NULL,
  feature_code TEXT NOT NULL,
  PRIMARY KEY (edge_id, feature_code),
  FOREIGN KEY (edge_id)
    REFERENCES expression_form_edges(id) ON DELETE CASCADE,
  FOREIGN KEY (feature_code)
    REFERENCES morphological_features(code) ON DELETE RESTRICT
) WITHOUT ROWID;
```

目前沒有 feature-first 查詢，刪除 `idx_expression_form_edge_features_feature_code`。

### 11.3 Compact split undo log

Split 功能保留極簡撤銷紀錄：

```sql
CREATE TABLE expression_splits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_expression_id INTEGER NOT NULL,
  target_expression_id INTEGER NOT NULL,
  created_by INTEGER,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE expression_split_moves (
  split_id INTEGER NOT NULL,
  edge_id INTEGER NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id)
    REFERENCES expression_splits(id) ON DELETE CASCADE,
  FOREIGN KEY (edge_id)
    REFERENCES expression_edges(id) ON DELETE RESTRICT
) WITHOUT ROWID;
```

不再保存 previous／new endpoints 或建立時間。撤銷前必須整批驗證：

- 所有 edge 仍存在且仍連接 target。
- 移回 source 後不會撞上既有 pair。
- target 沒有新增其他引用。

任何條件不符即拒絕整次撤銷，不允許部分回復。成功撤銷後刪除 split row，並 cascade 刪除 moves。

### 11.4 小型 morphology registries

以下約束保留：

- `morphological_dimensions`: PK(code)、UNIQUE(sort_order)。
- `morphological_features`: PK(code)、UNIQUE(dimension_code, sort_order)。
- `parts_of_speech`: PK(code)、UNIQUE(sort_order)、UNIQUE(bit_index)。

這些表只有數十列，不以犧牲完整性換取極少量空間。

## 12. UI localization、preferences 與 users

### 12.1 UI localization

保留：

- `ui_locales PRIMARY KEY(project_id, locale_id)`。
- `ui_messages PRIMARY KEY(project_id, message_key)`。
- `idx_ui_messages_source_expression(project_id, status, source_expression_id)`。

`locale_id`、`source_expression_id` 及其他 expression FK 全部改為整數。

### 12.2 User preferences

保留 `PRIMARY KEY(user_id, preference_key)`，不新增 surrogate ID 或其他索引。Locale preference value 使用整數 `locale_id`，API 再投影 code。

### 12.3 Users

保留：

- integer primary key。
- `UNIQUE(username)`。
- `UNIQUE(email)`。

刪除與兩個 UNIQUE 完全重複的 explicit indexes。`/users/me` 可繼續返回使用者資料，但不再查詢或返回 activity。

## 13. 移除 release／claim 與 packed mirror

以下表整表刪除：

- `dictionary_dataset_releases`
- `dictionary_dataset_state`
- `dictionary_expression_bindings`
- `expression_edge_evidence`
- `expression_pos_attestations`
- `dictionary_languages`
- `dictionary_locales`
- `dictionary_terms`
- `dictionary_readings`
- `dictionary_edges`

同時移除：

- `dictionary_expression_rows`
- `dictionary_reading_rows`
- `dictionary_edge_rows`
- packed union views
- `dictionaryReleaseSchemaAvailable()`
- `activeReleasePredicate()`
- `releaseObjectEligibilityPredicate()`
- `edgeEligibilityPredicate()`
- `dictionaryManagedObjectPredicate()`
- release／claim／binding／evidence importer 寫入與測試

所有 public query 直接讀 canonical tables，不再有 active release visibility gate。

`d1_migrations` 是 migration framework 系統表，保留不動。

## 14. 搜尋、排序與分頁

### 14.1 Prefix search

移除不可使用 B-tree 的 `%query%` substring search。Expression 搜尋必須指定 language，並使用 `(language_id, text, homograph_index)` index 做 exact／prefix search。

- exact 使用 `language_id = ? AND text = ?`。
- prefix 使用 `language_id = ? AND text >= ? AND text < ?`，上下界由共用 canonical-text 模組按 SQLite `BINARY` collation 產生。
- 不依賴不同環境可能有差異的 `LIKE` case-sensitivity 或 collation 行為。

不建立 FTS index，也不提供跨全部語言的無限制 substring search。

### 14.2 Language expression lists

取消全站最新 expression。語言頁只保留：

- `alpha`：使用 identity unique 的文字順序。
- `new`：使用 `(language_id, created_at DESC)`。

列表取消深層 `OFFSET` 與每頁 `COUNT(*)`：

- alpha cursor：`(text, homograph_index)`。
- new cursor：`(created_at, id)`。
- response 返回 `next_cursor` 與 `has_more`。
- 語言及 locale 總數由 `/languages/:code` 統計 response 提供。

### 14.3 移除的排序與 feed

- 移除 expression `hot`／popular 排序。
- 移除 edge `/feed/hot`、`/feed/new` 及首頁 edge feed。
- 移除 edge score／created time 排序。
- handbook `hot` 保留，並由 `handbook_votes` 驅動。
- 核心列表與 graph 查詢不得出現 `USE TEMP B-TREE`。

## 15. AI 高信心 reconciliation

### 15.1 執行位置

AI reconciliation 在寫入 D1 前於離線 staging 執行。D1 不保存 prompt、模型輸出、candidate、claim 或 confidence rows。

### 15.2 合併規則

- candidate 限定為相同 `language_id + canonical text`。
- 判斷輸入可使用全部已抽取欄位，包括定義、POS、reading、例句與跨語言映射。
- confidence 必須至少 `0.98`，且不存在明顯 POS／mapping 矛盾。
- cluster 中任意兩筆都必須通過門檻；不得以 A≈B、B≈C 推導 A≈C。
- 低於門檻即不合併，建立新的 homograph。
- 不同拼寫不合併成同一 expression；需要時建立 mapping edge。

### 15.3 欄位聚合

高信心合併後：

- POS masks 做 bitwise OR。
- locale links 做 set union。
- readings 依複合 PK 去重。
- edges 依 canonical pair 去重，relation masks 做 bitwise OR。
- source 依固定 rank 選出一個代表值。
- 定義與標籤不寫入 D1。
- 例句建立為獨立 expression，並用 relation bit 2（值 `4`）的 edge 連接。

### 15.4 離線 artifact

離線 reconciliation artifact 保存可重建所需的 sense fingerprint、cluster、confidence、模型版本與完整抽取欄位。它不回寫線上 D1，也不得成為 runtime API 依賴。

## 16. 逐部詞典匯入

### 16.1 順序

詞典按預估 canonical row 數由小到大處理。每部詞典依序完成：

1. structured JSONL 驗證。
2. 離線 staging 與 normalization。
3. AI reconciliation 與 sense clustering。
4. canonical IDs／source selection。
5. D1 分批寫入。
6. 該部詞典驗收。

### 16.2 D1 寫入順序

1. sources、languages、locales。
2. expressions。
3. locale links。
4. readings。
5. edges。

每類 rows 先按其 primary／unique key 排序，再分批寫入。Canonical D1 從一開始使用最終 schema 與最終索引，不在每部詞典後反覆 drop／rebuild indexes。

### 16.3 Chunk 與恢復

- 使用可調 chunk；以 1,000、5,000、10,000 rows 的固定樣本 benchmark 選擇。
- 初始候選值為每批 5,000 rows，不視為永久最佳值。
- 每個 chunk 使用 idempotent upsert。
- checkpoint 只存在離線工作目錄。
- 中斷後從最後完成 chunk 繼續；D1 不建立 import state／release table。
- 每完成一部詞典，網站即可查詢已寫入的 canonical rows。

## 17. 現有 83 個索引的最終處置

本節逐表覆蓋 `d1-index-audit-2026-08-25.csv` 中的全部 83 個現有索引。自動索引不得直接 `DROP INDEX`；需透過刪表或 table rebuild 改變其約束。

| 現有表 | 現有索引 | 最終處置 |
|---|---|---|
| `d1_migrations` | `sqlite_autoindex_d1_migrations_1` | 保留；framework constraint |
| `dictionary_dataset_releases` | `idx_dictionary_releases_dataset_created`、`sqlite_autoindex_dictionary_dataset_releases_1`、`sqlite_autoindex_dictionary_dataset_releases_2` | 隨表刪除 |
| `dictionary_dataset_state` | `sqlite_autoindex_dictionary_dataset_state_1` | 隨表刪除 |
| `dictionary_edges` | `idx_dictionary_edges_a_id`、`idx_dictionary_edges_b_id`、`sqlite_autoindex_dictionary_edges_1` | 隨表刪除；不得另計重複節省 |
| `dictionary_expression_bindings` | `idx_dictionary_bindings_expression`、`sqlite_autoindex_dictionary_expression_bindings_1` | 隨表刪除 |
| `dictionary_languages` | `sqlite_autoindex_dictionary_languages_1` | 隨表刪除 |
| `dictionary_locales` | `sqlite_autoindex_dictionary_locales_1` | 隨表刪除 |
| `dictionary_readings` | `sqlite_autoindex_dictionary_readings_1` | 隨表刪除 |
| `dictionary_terms` | `sqlite_autoindex_dictionary_terms_1` | 隨表刪除 |
| `expression_edge_evidence` | `idx_dictionary_edge_evidence_edge`、`sqlite_autoindex_expression_edge_evidence_1` | 隨表刪除 |
| `expression_edges` | `idx_expression_edges_a_id` | 移除；target pair unique 支援 a-side |
| `expression_edges` | `idx_expression_edges_b_id` | 重建為整數 b-side index |
| `expression_edges` | `idx_expression_edges_created_at`、`idx_expression_edges_created_by_at`、`idx_expression_edges_score_feed` | 移除及刪除依賴功能 |
| `expression_edges` | `sqlite_autoindex_expression_edges_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `expression_edges` | `sqlite_autoindex_expression_edges_2` | 重建為 integer pair unique |
| `expression_form_edge_features` | `idx_expression_form_edge_features_feature_code` | 移除；無 feature-first query |
| `expression_form_edge_features` | `sqlite_autoindex_expression_form_edge_features_1` | 重建為 WITHOUT ROWID composite PK |
| `expression_form_edges` | `idx_expression_form_edges_form_id` | 移除；pair unique 前綴取代 |
| `expression_form_edges` | `idx_expression_form_edges_lemma_id` | 重建為 integer lemma index |
| `expression_form_edges` | `sqlite_autoindex_expression_form_edges_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `expression_form_edges` | `sqlite_autoindex_expression_form_edges_2` | 重建為 integer `(form_id,lemma_id)` unique |
| `expression_form_edges` | `sqlite_autoindex_expression_form_edges_3` | 移除 pair_low／pair_high 後消失 |
| `expression_locale_attestations` | `sqlite_autoindex_expression_locale_attestations_1`、`sqlite_autoindex_expression_locale_attestations_2` | 隨舊表刪除；由 locale links 的 PK＋reverse index 取代 |
| `expression_pos_attestations` | `idx_dictionary_pos_expression`、`idx_dictionary_pos_release`、`sqlite_autoindex_expression_pos_attestations_1` | 隨表刪除；由 `expressions.pos_mask` 取代 |
| `expression_readings` | `sqlite_autoindex_expression_readings_1`、`sqlite_autoindex_expression_readings_2` | 舊 ID PK 與 unique 消失；重建為 WITHOUT ROWID content PK |
| `expression_split_moves` | `sqlite_autoindex_expression_split_moves_1` | 重建為 integer WITHOUT ROWID `(split_id,edge_id)` PK |
| `expression_splits` | `sqlite_autoindex_expression_splits_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `expressions` | `idx_expressions_created_at` | 由 `(language_id,created_at DESC)` 取代；全站 new 移除 |
| `expressions` | `idx_expressions_created_by_at` | 移除；activity 功能移除 |
| `expressions` | `sqlite_autoindex_expressions_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `expressions` | `sqlite_autoindex_expressions_2` | 重建為 `(language_id,text,homograph_index)` unique |
| `expressions` | `sqlite_autoindex_expressions_3` | 移除 `text_hash` 後消失 |
| `handbook_section_items` | `idx_handbook_section_items_section` | 移除；WITHOUT ROWID position PK 取代 |
| `handbook_section_items` | `sqlite_autoindex_handbook_section_items_1`、`sqlite_autoindex_handbook_section_items_2` | 重建為 position PK＋expression unique |
| `handbook_sections` | `idx_handbook_sections_handbook` | 移除；`UNIQUE(handbook_id,position)` 取代 |
| `handbook_sections` | `idx_handbook_sections_parent` | 重建為 integer parent query index |
| `handbook_sections` | `sqlite_autoindex_handbook_sections_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `handbook_sections` | `sqlite_autoindex_handbook_sections_2` | 重建為 integer handbook／position unique |
| `handbooks` | `idx_handbooks_score` | 由 `(visibility,score,created_at,id)` 取代 |
| `handbooks` | `idx_handbooks_user_created_at` | 移除；activity 功能移除 |
| `handbooks` | `idx_handbooks_visibility_created` | 重建為 integer-ID public-new index |
| `handbooks` | `sqlite_autoindex_handbooks_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `language_locales` | `sqlite_autoindex_language_locales_1` | code PK 改為 integer PK＋`UNIQUE(code)` |
| `language_locales` | `sqlite_autoindex_language_locales_2` | 由 NULL-safe identity unique index 取代 |
| `languages` | `idx_languages_code` | 移除重複 explicit index |
| `languages` | `sqlite_autoindex_languages_1` | code PK 改為 integer PK＋`UNIQUE(code)` |
| `morphological_dimensions` | `sqlite_autoindex_morphological_dimensions_1`、`sqlite_autoindex_morphological_dimensions_2` | 保留 PK(code) 與 sort unique |
| `morphological_features` | `sqlite_autoindex_morphological_features_1`、`sqlite_autoindex_morphological_features_2` | 保留 PK(code) 與 dimension／sort unique |
| `parts_of_speech` | `sqlite_autoindex_parts_of_speech_1`、`sqlite_autoindex_parts_of_speech_2` | 保留並新增 bit_index unique |
| `regions` | `idx_regions_code` | 移除重複 explicit index |
| `regions` | `sqlite_autoindex_regions_1` | 保留 PK(code) |
| `scripts` | `idx_scripts_code` | 移除重複 explicit index |
| `scripts` | `sqlite_autoindex_scripts_1` | 保留 PK(code) |
| `sources` | `sqlite_autoindex_sources_1` | TEXT PK rebuild 後消失；target 使用 integer rowid PK |
| `sources` | `sqlite_autoindex_sources_2` | 重建為 `(type,name)` unique |
| `ui_locales` | `sqlite_autoindex_ui_locales_1` | 重建為 `(project_id,locale_id)` PK |
| `ui_messages` | `idx_ui_messages_source_expression` | 保留，expression FK 改 integer |
| `ui_messages` | `sqlite_autoindex_ui_messages_1` | 保留 `(project_id,message_key)` PK |
| `user_preferences` | `sqlite_autoindex_user_preferences_1` | 保留 `(user_id,preference_key)` PK |
| `users` | `idx_users_email`、`idx_users_username` | 移除重複 explicit indexes |
| `users` | `sqlite_autoindex_users_1`、`sqlite_autoindex_users_2` | 保留 username／email unique |
| `votes` | `idx_votes_target`、`idx_votes_user_created_at`、`sqlite_autoindex_votes_1`、`sqlite_autoindex_votes_2` | 舊表刪除；由 edge_votes／handbook_votes 的 composite PK＋target indexes 取代 |

## 18. Schema 施工順序

本設計是破壞式 greenfield cutover，不使用一個巨型 backfill migration。實作計畫必須拆成可驗證階段：

1. 更新 `backend/schema.sql` 為最終 baseline。
2. 新增 destructive schema migrations，明確標記只適用 disposable／已授權環境。
3. 先移除依賴 packed/release tables 的 routes、services、views 與 tests。
4. 建立 integer registry、canonical tables 與最終 indexes。
5. 更新 API types、route params、frontend types 與 cursor contracts。
6. fresh rebuild 本地 D1。
7. 匯入小型 seed 與最小一部詞典，完成 smoke test。
8. 依小到大順序完成其餘詞典。

Schema 改動必須同步：

- `backend/schema.sql`
- `backend/migrations/`
- `scripts/db/migration-lock.json`
- schema contract tests
- backend／frontend API types
- importer 與相關測試

## 19. 驗收與效能基準

### 19.1 Schema 與資料完整性

- 所有大型 ID 與 FK 使用 INTEGER。
- INTEGER PRIMARY KEY 不產生額外 PK autoindex。
- 所有 `WITHOUT ROWID` tables 與複合 PK 符合本 spec。
- 無 dictionary mirror、release、claim、binding、evidence 或 attestation audit tables／views。
- 無 orphan FK、重複 reading、重複 locale pair 或重複 edge pair。
- relation masks、POS masks 與 source rank 結果正確。
- split undo 成功與衝突拒絕都有測試。
- handbook vote 與 edge vote 的 cached score 可完整 reconciliation。

### 19.2 API 與功能

- 所有 expression／edge／handbook URL 使用 decimal string ID。
- locale PUT／DELETE idempotent。
- `cod` 等多義詞可存在多個 homograph，且各自映射正確。
- prefix search、alpha/new cursor、mapping cursor 不重複或漏資料。
- graph target-language filter、node limit、hop limit、cycle handling 正確。
- `/users/me` 不再返回 activity。
- handbook new／hot 與 vote 功能正確。
- 已移除 feed、hot expression、substring search 與舊 attestation API 返回明確契約錯誤或不再註冊 route。

### 19.3 匯入 benchmark

使用同一份 100,000-record 樣本分別測試 chunk 1,000、5,000、10,000，記錄：

- raw records 與 canonical expressions／readings／edges 數。
- staging、AI reconciliation、D1 寫入各階段耗時。
- 三類 canonical rows/s。
- 匯入前後 bytes 與 bytes/canonical row。
- peak D1 file size。
- 高信心合併、新 homograph、拒絕合併數。

每部詞典完成後保存相同格式的 benchmark ledger。新版本在相同資料與 cache 條件下不得比已採用 baseline 慢超過 10%。

### 19.4 查詢 benchmark

在至少一部小詞典及一部百萬級詞典上，記錄 warm p50／p95：

- language expression first page。
- alpha／new cursor next page。
- exact／prefix expression search。
- locale filter 與 count。
- expression detail。
- mapping direct list。
- 1／2／3-hop graph，含 target language。
- handbook new／hot。

使用 `EXPLAIN QUERY PLAN` 驗證核心查詢沒有 `USE TEMP B-TREE`。任何索引調整都必須在相同資料、相同條件下測量前後結果；未改善或落在測量噪音內的新增索引不得保留。

### 19.5 空間預算

- 完整 canonical D1 必須低於 5 GiB。
- 每部詞典後以 `dbstat`、page count 與 file size 記錄 table／index bytes。
- 若依目前 bytes/row 推算完整匯入會超過 4.5 GiB，停止下一部匯入並重新檢查欄位與索引。
- 離線 structured JSONL 與 reconciliation artifacts 不計入 D1 預算，但必須與 D1 分開統計。
- packed tables 與其 indexes 的刪除收益不得在報告中重複計算。

## 20. 風險與回退

- Greenfield cutover 不保留舊 ID 或大型舊資料；回退只能重建舊 schema 並重新匯入舊備份。
- 單一代表 `source_id` 不保存完整多來源集合；完整集合只能由離線 artifact 重建。
- AI 高信心誤合併會污染 canonical graph；門檻、cluster 完整檢查與離線 artifact 是必要防線。
- 無 FTS 時不支援 substring search；這是空間換功能的明確取捨。
- Locale reverse index 會增加 link table 空間，但大型 locale 篩選已確認需要保留。
- Mapping graph 不按 score 選擇節點；熱門高連接 expression 只展開固定數量鄰居。
- Split undo 只在 edge 與 target 未被後續修改到衝突時成功，不能承諾任意時間無條件撤銷。
- 遠端 destructive reset 不在本 spec 的自動執行授權內。
