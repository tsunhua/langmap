# LangMap ISO 639-3 語言身份全棧重建規格

> **狀態：待實作。** 本規格落實 [ADR 0004](../../adr/0004-language-codes-redesigned-around-iso639-3.md)，取代既有 Glottolog、BCP 47 content profile 與 Language Variety／Profile 模型的施工依據。

**日期：** 2026-08-11  
**範圍：** `backend/`、`web/`、`scripts/`、D1 baseline、UI 本地化  
**資料策略：** Greenfield；現有 D1 資料全部可丟棄

## 1. 摘要

LangMap 改以 ISO 639-3 個體語言代碼識別語言，以 Language Locale 表達書寫系統與地區差異，以語言代碼加 canonical text hash 識別 Expression。地域佐證、文字讀音、UI Locale 與使用者語言偏好分屬清楚的領域模型，但共同引用 Language Locale。

本次不提供舊資料遷移、runtime alias 或 `language_profile_code` 相容層。資料庫、API、前端與資料工具在同一施工計劃中切換到新 baseline。

## 2. 目標

1. 同一語言與文字預設只建立一個 Expression，不因 script 或地區分裂 mapping 節點。
2. Language Locale 能表達 ISO region 以下的使用者自訂地點路徑。
3. Expression 可累積多份、可追溯的地域佐證及多種文字讀音。
4. 維護者能在發現多義混線後手動拆分 Expression，且保留 mapping edge ID 與 votes。
5. UI Locale 與 Language Locale 關聯，達 60% 自身翻譯覆蓋率後自動啟用，也能由管理員手動啟用。
6. 使用者可選第一與第二 Language Locale；UI 詞句逐 key 依第一語言、第二語言、英語原文 fallback。
7. 保留 Language Detail 與 Map Lens；代表座標是可選顯示資料，所有地圖內容都有文字列表替代。
8. 移除 Glottolog／BCP 47 profile runtime、資料表、前端建立流程及資料產物。

## 3. 非目標

- 不保存或遷移現有 D1 資料。
- 不建立全球地點 registry、行政區階層或外部 place ID 對齊。
- 不自動偵測多義詞，不建立背景審查佇列。
- 不建立 sense gloss、sense entity 或自動語義分類。
- 不建立讀音 scheme registry，不解析或驗證 IPA、拼音等內容語法。
- 不保存音檔；音檔日後使用獨立模型。
- 不在 locale 之間自動繼承地域佐證、讀音或 UI 翻譯。
- 不重新設計既有視覺風格。

## 4. 核心不變量

1. `lang_code` 必須存在於 pinned ISO 639-3 個體語言 registry。
2. `script_code` 必須存在於 pinned ISO 15924 registry。
3. `region_code` 必須存在於 pinned ISO 3166-1 alpha-2 registry。
4. Language Locale code 只能由後端 canonical builder 生成。
5. Expression identity 欄位建立後不可直接修改。
6. 同一 `(lang_code, canonical_text, homograph_index)` 只能存在一筆 Expression。
7. Mapping edge 端點以 Expression ID 穩定排序，且同一 pair 只能存在一條 edge。
8. 地域佐證與讀音記錄各自保留來源，不壓成單一布林關係。
9. Fallback 譯文永不計入某個 UI Locale 的自身覆蓋率。
10. Active UI Locale 不因覆蓋率下降而自動退回 draft。
11. 所有查詢、圖遍歷、列表與拆分配置都有穩定排序及數量上限。

## 5. 架構與模組邊界

### 5.1 Language Identity

負責 reference registry、Language Locale grammar、canonical code、建立與查詢。Route 不得自行拼接或解析 locale code。

預定模組：

```text
backend/src/services/languageIdentity.ts
backend/src/types/language.ts
backend/src/routes/languageRegistry.ts
backend/src/routes/languageLocales.ts
```

### 5.2 Expression Domain

負責 canonical text、hash ID、Expression 建立／重用、地域佐證、讀音與手動拆分。Contribution、UI translation 與一般 Expression API 必須共用同一 service。

預定模組：

```text
backend/src/services/expressionDomain.ts
backend/src/utils/expressionIdentity.ts
backend/src/routes/expressions.ts
backend/src/routes/contributions.ts
```

### 5.3 UI Localization

負責 translation candidate、coverage、UI Locale 狀態、bundle revision 與逐 key fallback。Mapping vote 只能透過此 service 通知受影響 locale，不得在 route 內複製 coverage SQL。

預定模組：

```text
backend/src/services/localizationDomain.ts
backend/src/services/userPreferences.ts
backend/src/routes/localization.ts
backend/src/routes/preferences.ts
```

## 6. Reference registries

### 6.1 資料表

```sql
CREATE TABLE languages (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL
);

CREATE TABLE scripts (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE regions (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  CHECK ((latitude IS NULL) = (longitude IS NULL))
);
```

`regions` 使用 ISO 3166-1 alpha-2，但領域、schema、API 與 UI 一律稱為 region；不把所有標準項目稱為 country。

### 6.2 來源與生命週期

新目錄 `scripts/language-reference/` 保存 pinned upstream、manifest、生成器與測試。Manifest 至少記錄標準名稱、來源 URL、下載日期、檔案 checksum 與產物筆數。

生成器只輸出 ISO 639-3 individual scope 項目、ISO 15924 正式 code，以及 ISO 3166-1 alpha-2 項目。Script direction 使用一份版本控制、逐 code 可審核的 pinned overlay；未明確支援的 script 不可由名稱猜測方向。Region 代表座標同樣來自獨立的選填 curated overlay，並記錄來源與授權；ISO registry 本身不被視為座標來源。輸出固定排序、可重跑且不可依賴 runtime network。

Runtime 不提供建立或修改 registry row 的 API。

## 7. Language Locale

### 7.1 Grammar

```text
language_locale_code = lang "-" script "-" region ("_" place_segment)*
lang                 = [a-z]{3}
script               = [A-Z][a-z]{3}
region               = [A-Z]{2}
place_segment        = [A-Z][A-Za-z]*
```

例如：

```text
nan-Hant-CN
nan-Hant-CN_Quanzhou_Nanan
nan-Latn-TW_Tainan
eng-Latn-US_NewYork
```

Place segment 由使用者自訂；不正規化拼寫、不對齊外部地點資料，也不以 `_` 分隔同一地名的單字。`NewYork` 是一段，`New_York` 是兩層，因此後者不應用來表達 New York。

### 7.2 資料表

```sql
CREATE TABLE language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

只含頂層 region 的 locale，其 `place_path` 是空字串；code 不含尾隨 `_`。座標只代表地圖顯示點，不表示使用範圍。若 locale 無座標而 region 有代表點，API 可回傳 region fallback coordinate，但必須標示 `coordinate_source = 'region'`；locale 自身座標標示為 `coordinate_source = 'locale'`。

### 7.3 來源慣例

來源分兩層。共享的具名來源存於 `sources` 表，每筆 row 用 `source_id` 指向它，並以獨立的 `source_ref` 記錄該筆具體出處（帶參數的 URL、頁碼、條目 ID 等）。`language_locales`、`expressions`、`expression_locale_attestations`、`expression_readings` 共用此模型。

```sql
CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

`sources.type` 決定 `name` 的性質與 `source_ref` 的驗證規則：

| type | `sources.name`（共享） | row 的 `source_ref`（具體出處） |
|---|---|---|
| `url` | 站台／資源名稱 | 完整 URL，含 query params（`https://…/entry?p=123`） |
| `publication` | 出版品書目標籤 | 頁碼、條目、卷期等定位 |
| `system` | 系統來源名稱 | 版本／實例 tag |

四張表的 `source_id`／`source_ref` 皆 nullable，且 `source_ref` 不得脫離 `source_id` 單獨存在（CHECK）。使用者身分由 `created_by` 記錄：

- `source_id` NULL → 使用者直接斷言，provenance 就是 `created_by`。
- `source_id` 指向 `sources`、`source_ref` NULL → 引用整個來源。
- `source_id` 指向 `sources`、`source_ref` 非 NULL → 引用來源內具體出處。

系統產生的 row 一律指向預先建好的 `system` source，`source_ref` 區分實例：

- Seed（如 `eng-Latn-US`）：對應 system source，`source_ref` 如 `seed:<system_id>:<version>`。
- Pinned 匯入：system source，`source_ref` 如 `dataset:<manifest_dataset_id>:<version>`，上游 URL 與 checksum 另由匯入 manifest 記錄。
- Split 產生的新 Expression：system source，`source_ref = 'split:<expression_split_id>'`，操作者記於 `expression_splits.created_by`（§10.2）。
- UI source copy 的 English Expression：system source，`source_ref = 'ui:<project_id>:<message_key>:<revision>'`（§12.2）。

引用提交時 service 以 `(type, name)` 查找或建立 `sources` row，再寫入 `source_id`；caller 不直接傳 `source_id`。`name` 為空或 `source_ref` 脫離 `source_id` 都必須拒絕。SQLite 的 UNIQUE 對 NULL 視為相異，因此 `source_id` 為 NULL 的重複 row 由 service 層去重（「重複資料回傳既有記錄」），不依賴 constraint。

## 8. Expression identity

### 8.1 Canonical text

```text
canonical_text = input.trim().normalize('NFC')
```

不轉小寫、不壓縮內部空白、不做語言專屬正規化。Canonical text 為空時拒絕建立。

### 8.2 Hash

```text
digest    = SHA-256(UTF-8(canonical_text))
short     = digest[0..15]              // 前 16 bytes，128 bits
text_hash = RFC4648_BASE32(short)
              .toLowerCase()
              .removePadding()
```

Base32 alphabet 固定為 `abcdefghijklmnopqrstuvwxyz234567`，輸出固定 26 字元。測試向量：

```text
canonical_text = hello
SHA-256        = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
text_hash      = ftze3os7wcrq4jxihmvmlopcty
expression_id  = eng:ftze3os7wcrq4jxihmvmlopcty
```

### 8.3 ID

```text
homograph_index = 1 → {lang_code}:{text_hash}
homograph_index > 1 → {lang_code}:{text_hash}.{homograph_index}
```

同一語言下若 short hash 已存在，service 必須比較完整 canonical text。不同文字命中同一 short hash 時回 `EXPRESSION_HASH_COLLISION`，不得合併或自動加 salt。

### 8.4 資料表

```sql
CREATE TABLE expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

移除 `audio_url`、region 欄位、`meaning_id`、`variation_status` 與舊 `language_profile_code`。Identity 欄位沒有一般 PATCH API；錯字修正建立新 Expression，再由管理操作搬移需要保留的引用。

## 9. 地域佐證與讀音

### 9.1 可追溯地域佐證

```sql
CREATE TABLE expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (expression_id, language_locale_code, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

使用者直接斷言時 `source_id`／`source_ref` 為 NULL，provenance 是 `created_by`；附帶引用時 `source_id` 指向 `sources`、`source_ref` 為具體出處（見 §7.3）。API 讀取 locale 列表時按 locale code 排序並聚合 `attestation_count`，但不能丟棄來源明細。

### 9.2 文字讀音

```sql
CREATE TABLE expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (
    expression_id,
    language_locale_code,
    scheme,
    value,
    source_id,
    source_ref
  ),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

Scheme grammar：

```regex
^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$
```

有效例：`ipa`、`pinyin`、`wade-giles`、`phonics:synthetic`。建立 reading 時必須在同一原子操作建立 `source_id`／`source_ref` 完全相同的 locale attestation（皆為 NULL 時亦同）；重複資料回傳既有記錄。

## 10. Mapping 與手動拆分

### 10.1 Edge

```sql
CREATE TABLE expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

Edge ID 使用 ULID。Batch contribution 先以字典序 canonicalize pair，再用唯一約束重用既有 edge。Votes 繼續引用 edge ID，因此 split 更換端點時 votes 不變。

### 10.2 Split audit

```sql
CREATE TABLE expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);
```

Split 只允許 admin。Request 提供至少一個直接相鄰 edge ID。原子操作依序：

1. 驗證來源 Expression 與所有 edge。
2. 以 `MAX(homograph_index) + 1` 配置下一序號。
3. 先建立 split audit，再讓新 Expression 的 `source_id` 指向 split 專用的 system source、`source_ref = 'split:<split_id>'`、`created_by` 為操作 admin，建立同 lang、text、hash 的新 Expression。
4. 將選定 edge 的來源端點替換為新 Expression，重新排序 pair。
5. 保留 edge ID、score 與 votes。
6. 寫入 split 與 move audit。
7. 重新計算受影響 UI Locale coverage／revision。

Split 不自動複製或搬移 readings、locale attestations、handbook items。任何驗證、唯一 pair 或寫入失敗都必須整體回滾。

## 11. User preferences

```sql
CREATE TABLE user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

後端以 key registry 維護允許的 preference 及 Zod schema。首個 key：

```text
preference_key = language.locales
value_json     = {
  "primary": "nan-Hant-TW_Tainan",
  "secondary": "cmn-Hant-TW"
}
```

`primary` 必填；`secondary` 可省略但不能是 `null`，且不能與 primary 相同。兩者必須引用已存在的 Language Locale。Locale 是否有 active UI Locale 不影響偏好保存。

匿名偏好保存於前端 localStorage，不寫入 D1。

## 12. UI localization

### 12.1 UI Locale

```sql
CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

不保存 `native_name`、`direction` 或 `fallback_code`。本地名稱由 Language Locale `name` 取得，英文名稱由 `name_en` 取得，direction 由 script registry 取得。

系統 seed `eng-Latn-US` 作 `langmap-web` 的 source UI Locale，固定為 active，`activation_source = 'system'`；一般狀態操作不可將它封存或降級。

### 12.2 UI messages

`ui_messages.source_expression_id` 改為 TEXT FK。Source copy 更新時讓新 English Expression 的 `source_id` 指向 UI copy 專用的 system source、`source_ref = 'ui:<project_id>:<message_key>:<revision>'`，建立新的 immutable English Expression 並替換該 key 的 source ID；舊 mapping 自然不再是新 source 的 candidate。

### 12.3 Coverage

```text
coverage = translated_active_keys / total_active_keys
```

分母是 project 中 `status = 'active'` 的 UI messages。分子每個 key 最多計一次，且 candidate 必須：

1. 與 source expression 有直接 mapping。
2. Target Expression 的 lang code 等於 UI Locale 的 lang code。
3. Target Expression 至少有一筆該完整 Language Locale 的地域佐證。
4. Edge score `>= 0`。
5. Placeholder set 與目前 source 完全一致。
6. 不是從其他 locale fallback 取得。

`total_active_keys = 0` 時 coverage 回傳 `0`，不得自動啟用。

Candidate 選擇固定依 edge score 降序、edge created_at 升序、target Expression ID 升序。

### 12.4 Activation

- Draft coverage 達 `0.60` 時自動轉 active，`activation_source = 'auto'`。
- Admin 可在任意 coverage 手動啟用 draft，`activation_source = 'manual'`。
- Active coverage 下降時只更新 coverage 顯示，不自動降級。
- Admin 可封存 draft 或 active locale。
- Draft 只供 workbench 預覽；archived 不接受一般翻譯提交，也不參與 bundle。

新增 translation mapping、mapping vote、UI message 啟用／退役、split edge move 都必須通知 localization service 重算受影響 locale 並增加 revision。

### 12.5 Per-key fallback

```text
primary active candidate
  ?? secondary active candidate
  ?? English source text
```

不做 parent region、同語言、同 script 或固定 locale fallback。Primary／secondary 沒有 active UI Locale 時直接跳過。Fallback 結果不計入 coverage。

Bundle 回傳每個 key 的 `resolved_from`，方便前端除錯與 workbench 預覽。

## 13. API 契約

所有 route 使用 `/api/v2` prefix 與 `{ success, data?, error?, message? }` 回應。

### 13.1 Registry 與 Language Locale

```text
GET  /language-registry/languages?q=&limit=&offset=
GET  /language-registry/scripts?q=&limit=&offset=
GET  /language-registry/regions?q=&limit=&offset=
GET  /language-locales?lang_code=&script_code=&region_code=&q=&limit=&offset=
POST /language-locales
GET  /language-locales/:code
```

`POST /language-locales` 接受結構化欄位，不接受 caller 傳入 code。`source` 選填，含共享來源的 `type` 與 `name`（service 依 `(type, name)` 查找或建立 `sources` row）及具體出處 `ref`；省略時表示使用者直接建立，`created_by` 由認證自動帶入：

```json
{
  "lang_code": "nan",
  "script_code": "Hant",
  "region_code": "CN",
  "place_segments": ["Quanzhou", "Nanan"],
  "name": "閩南語",
  "name_en": "Quanzhou Southern Min",
  "latitude": 24.96,
  "longitude": 118.68,
  "source": { "type": "url", "name": "臺灣閩南語常用詞辭典", "ref": "https://sutian.moe.edu.tw/entry?p=123" }
}
```

### 13.2 Expressions

```text
GET  /expressions/search
POST /expressions
GET  /expressions/:id
GET  /expressions/:id/mappings
POST /expressions/:id/locale-attestations
POST /expressions/:id/readings
POST /expressions/:id/split
```

建立 Expression：

```json
{
  "lang_code": "nan",
  "text": "食",
  "language_locale_code": "nan-Hant-TW_Tainan"
}
```

Locale 選填；提供時建立 `source_id`／`source_ref` 皆為 NULL、`created_by` 為當前使用者的地域佐證。既有 base Expression 回傳 `200` 與 `created = false`；新建回傳 `201` 與 `created = true`。

Split body：

```json
{ "edge_ids": ["01...", "01..."] }
```

### 13.3 Preferences

```text
GET /preferences
PUT /preferences/language.locales
```

未知 preference key 回 `UNKNOWN_PREFERENCE_KEY`。

### 13.4 Localization

```text
GET  /localization/projects/:projectId/locales
POST /localization/projects/:projectId/locales
POST /localization/projects/:projectId/locales/:code/activate
POST /localization/projects/:projectId/locales/:code/archive
GET  /localization/projects/:projectId/workbench/:code
POST /localization/projects/:projectId/mappings
POST /localization/projects/:projectId/mappings/batch
GET  /localization/projects/:projectId/messages?primary=&secondary=
```

登入者未傳 query 時使用已保存 preference；匿名者未傳 query 時直接使用 English。Query 永遠需經 Language Locale validator。

## 14. 穩定錯誤碼

至少定義：

```text
INVALID_LANG_CODE
INVALID_SCRIPT_CODE
INVALID_REGION_CODE
INVALID_PLACE_SEGMENT
INVALID_LANGUAGE_LOCALE_CODE
LANGUAGE_LOCALE_EXISTS
EXPRESSION_HASH_COLLISION
EXPRESSION_NOT_FOUND
EXPRESSION_SPLIT_EMPTY
EXPRESSION_SPLIT_EDGE_NOT_ADJACENT
EXPRESSION_SPLIT_CONFLICT
INVALID_READING_SCHEME
INVALID_SOURCE
UNKNOWN_PREFERENCE_KEY
INVALID_LANGUAGE_PREFERENCE
UI_LOCALE_NOT_ACTIVE
UI_LOCALE_ARCHIVED
UI_LOCALE_ALREADY_ACTIVE
UI_LOCALE_NOT_FOUND
UI_LOCALE_SYSTEM_LOCKED
VOTE_INVALID_VALUE
VOTE_TARGET_NOT_FOUND
CONTRIBUTION_TOO_FEW_EXPRESSIONS
```

資料庫 constraint error 不直接暴露給 caller；service 將預期衝突映射成上述 code，未知錯誤仍走統一 internal error handling。

## 15. 前端設計

### 15.1 移除舊建立流程

移除 BCP 47／Glottolog 專用元件與 composable：

```text
LanguageTagBuilder
LanguageSubtagSelect
GlottologMatchList
LanguageMetadataForm
LanguageCreateDialog
useLanguageCreation
```

新增：

```text
LanguagePicker
LanguageLocalePicker
LanguageLocaleCreateDialog
LanguageLocaleCodePreview
```

建立 dialog 依序選 language、script、region、選填 place segments、`name`（本地名稱）、`name_en`（英文名稱）、選填代表座標；code preview 使用與後端同 grammar 的純展示 helper，但後端生成值才是權威。

### 15.2 Contribution

每個詞句需要 Language 與 text，Language Locale 選填。Locale 不存在時可開建立 dialog。Batch 提交保持完全圖語義，並在失敗時保留使用者輸入。

### 15.3 Mapping Detail

Graph node 只顯示 Expression lang，不挑選單一 locale。Inspector 顯示 locale attestations、reading scheme/value/source，按 locale code、scheme、created_at、ID 穩定排序。

Admin split flow 使用直接 mapping 的可操作列表選 edge；確認畫面必須明示不複製 readings、locale attestations 或 handbook items。Graph 之外保留完整鍵盤列表替代。

### 15.4 Language pages 與 Map Lens

Language List 只顯示已有 Expression、Language Locale 或 active UI Locale 的語言，不把完整 ISO registry 當內容列表。

Language Detail 顯示 `name_en`（English exonym）、`name`（本地名稱）、Language Locales、Expression／reading 數及地圖點。Map Lens 優先使用 locale coordinate，缺少時可使用 region representative coordinate，並清楚標示；無任何座標的 locale 仍出現在文字列表。

### 15.5 Translation Workbench

Workbench 能從既有 Language Locale 建立 draft UI Locale，顯示自身 coverage、translated／total keys、狀態與 activation source。達 60% 後刷新為 active；admin 有手動 activate／archive 操作。Fallback candidate 只用於預覽，不增加 coverage。

### 15.6 LangSwitcher

改成 primary 與 optional secondary Language Locale 選擇器。登入者更新 `user_preferences`，匿名者保存 localStorage。Secondary 與 primary 相同時阻擋保存。控制元件需有 accessible name、鍵盤操作、可見 focus，觸控目標至少 44px。

## 16. Greenfield baseline 與工具清理

1. 刪除現有 `backend/migrations/` language-profile 時代 migrations，建立新的 `0001_initial_schema.sql`。
2. 同步重寫 `backend/schema.sql`；兩者必須產生等價 schema。
3. 重置 migration lock、production baseline fingerprint 與本地 rebuild 測試 fixture。
4. 刪除 `scripts/v2/` 中 Glottolog、IANA BCP 47、profile、variety、location 與 migration manifest tooling／artifacts。
5. 新增 `scripts/language-reference/` pinned registry 生成流程。
6. 保留 `scripts/i18n/`，但將 system catalog locale 改成 `eng-Latn-US`、`cmn-Hant-TW`、`cmn-Hans-CN` 等完整 Language Locale。
7. 所有舊資料庫以刪除並重建方式切換；不提供 rollback data migration。

既有以下文件只保留為歷史背景，不再作為施工權威：

- `2026-07-26-language-codes-and-community-ui-i18n.md`
- `2026-07-27-community-language-creation.md`
- `2026-08-02-language-common-and-variant-profiles.md`
- `2026-08-03-language-variety-profile-model-design.md`
- 依上述規格產生的既有 plans

## 17. 測試策略

### 17.1 Backend unit／integration

- NFC、trim、內部空白及 case 保留。
- SHA-256/128/Base32 固定向量與 26 字元 grammar。
- Base ID、`.2`／`.3` ID 及 hash collision guard。
- ISO registry 與 locale grammar 的成功／失敗案例。
- 代表座標成對約束及 coordinate source。
- Expression 建立／重用及 optional locale。
- 多來源地域佐證去重與來源明細；`sources` 查找或建立、`source_id`／`source_ref` 兩層驗證、`source_ref` 脫離 `source_id` 拒絕與 service 層去重。
- Reading scheme、source、同 transaction attestation。
- Split 權限、配置、edge move、pair ordering、vote 保留、audit、rollback。
- Contribution clique 與 duplicate pair reuse。
- Coverage 59% 不啟用、60% 啟用、manual activation、active 不降級。
- Fallback 不計 coverage。
- Primary → secondary → English 逐 key resolution。
- Preference key、JSON schema、locale existence 與 distinct validation。
- 所有 graph traversal 的 cycle、duplicate、limit 與穩定排序。

### 17.2 Frontend

- Locale 建立步驟、code preview、place segment 與 coordinate validation。
- Contribution optional locale 與 error input preservation。
- Mapping inspector attestation／reading grouping。
- Admin split selection、warning、success navigation。
- Workbench coverage、activation 與 draft preview。
- Primary／secondary preference persistence、匿名 localStorage、登入同步。
- Language Detail／Map Lens 的 locale coordinate、region fallback 與無座標列表。
- Desktop 與 mobile overflow、44px targets、focus、accessible names。

### 17.3 Tooling

- Registry generator 可重現、穩定排序、checksum 與筆數下限。
- Fresh D1 rebuild 成功。
- `schema.sql`、migration 與 fingerprint 一致。
- 新 schema 不含 `languoids`、`language_subtags`、`language_varieties`、`language_profiles`、`language_locations`。

## 18. 驗收

```bash
cd backend && npm test
cd web && npm test
cd web && npm run build
python3 -m unittest discover scripts
./build.sh
git diff --check
```

人工驗收至少覆蓋：

1. 建立 `nan-Hant-CN_Quanzhou_Nanan`。
2. 為同一 Expression 加入兩個 locales 與兩種 readings。
3. Batch contribution 建立 clique。
4. Admin 拆分一組 mappings 且 votes 保留。
5. UI Locale 從 59% 到 60% 自動啟用。
6. 手動啟用未達門檻 locale。
7. Primary 缺 key 時使用 secondary，再缺時使用 English。
8. 有／無座標 locale 都能在 Map Lens 的文字列表找到。
9. 桌面與行動 viewport 均無溢出，圖形功能都有列表替代。

## 19. 已知取捨

- 使用者自訂 place segment 可能有異拼、同名或重複，首版不合併。
- 128-bit short hash 理論上可能碰撞；完整文字比較與明確錯誤阻止靜默資料合併。
- 可追溯地域佐證增加資料列與聚合成本，換取來源審查能力。
- 通用 `user_preferences.value_json` 無法用 D1 FK 約束內部 locale；由 key-specific Zod schema 與 service 查詢保證。
- 60% 啟用允許混合語言 UI；逐 key secondary／English fallback 是刻意設計。
- Active locale 可能長期低於 60%；不自動停用是為了避免使用者偏好突然失效。
- Map representative coordinate 不是語言分布，不應用來推論覆蓋範圍。
