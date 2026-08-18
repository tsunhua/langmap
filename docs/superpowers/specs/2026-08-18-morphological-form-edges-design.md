# 詞形變化邊設計

日期：2026-08-18

狀態：已核准設計，待實作

## 1. 背景

LangMap 的節點是 expression：某一語言中一段具體文字，身份為 `(lang_code, canonical_text, homograph_index)`。`gato`、`gata`、`gatos` 是三個獨立詞句；`食べる`、`食べます`、`食べた` 亦然。系統只做 `trim` + Unicode NFC，沒有 lemma，也沒有語言專屬正規化。

現有 `expression_edges` 表示「這兩個詞句表達同一件事」：無向、無類型，批次貢獻時做成完全圖。`/mapping/:id` 以詞句為中心展示跨語對照，不是詞典屈折表。

西語陰陽性與單複數、英語不規則動詞、日語活用，本質上是同一詞位內部的有向、帶標籤形態關係。若把變化形丟進語義完全圖，圖譜會把單複數、敬體過去式當成同一句話的對譯，日語一詞數十形還會以 \(N^2\) 灌爆邊數。語義邊回答的是 same meaning；形態邊回答的是 same lexeme, different form。

變化形必須保持一等公民：`gata` 可對 `female cat`，`食べた` 可對 `ate`。搜尋變化形時，也要能看到原形的對照，但不能把兩層併成同一團 clique。

## 2. 目標

- 以獨立有向星型邊連接變化形與辭書形，邊上掛可疊加的封閉形態特徵。
- 一個變化形可指向多個原形；一個 expression 可同時當變化形與原形。
- 特徵與維度名稱走 expression mapping 國際化，不進 UI message bundle，不加逐語系欄位。
- 第一版 seed 英文、簡體中文、繁體中文、日文、西班牙文名稱。
- 搜尋保持字面命中，結果附形態摘要。
- 詞句／mapping 詳情分語義層與形態層；圖譜只畫語義邊。
- 登錄表按三語完整範式設計合法碼；資料只靠人工提交，空格表示沒有證據。

## 3. 非目標

- 不修改 `expression_edges` 的語意、遍歷或批次完全圖。
- 圖譜不畫形態邊，不沿形態邊再走語義再走形態。
- 不自動生成或補齊範式。
- 不在本規格實作 Wiktionary／UniMorph 匯入；表的 `source` 預留給後續匯入。
- 不存詞性（POS）。
- 不存派生（`gatito`、`uneatable`）。
- 形態邊不讚踩、不刪除、不以請求體整組覆寫特徵。
- 不擴充 `POST /contributions/batch`。
- `POST /expressions/:id/split` 不搬移、不複製形態邊。
- 不修改 `apple/`。
- 不把特徵名稱加入 `langmap-web` 的 vue-i18n catalog。

## 4. 核心不變量

1. 形態關係是有向星型：變化形指向辭書形；不經中間變化形轉接。
2. 兩端必須是已存在的 expression，且 `lang_code` 相同。
3. 不得自連；已有 `A→B` 時不得再寫 `B→A`。
4. 同一 `(form_id, lemma_id)` 只有一條形態邊。
5. 特徵是原子登錄碼的集合，掛在邊上，可為空，寫入時與既有集合做聯集。
6. 一個 form 可指向多個 lemma；一個 expression 可同時出現在 `form_id` 與 `lemma_id`。
7. 辭書形本身不標「這是原形」；未出現的肯定、常體、主動等值以缺席表示。
8. 程式與匯入永遠認 `code`；畫面只顯示經名稱解析器得到的本地化名稱。
9. 語義圖譜遍歷只讀 `expression_edges`。
10. 所有形態查詢、列表與 seed 寫入都有穩定排序及數量上限。

## 5. 資料模型

下一號增量 migration 為 `0020_morphological_form_edges.sql`，並同步更新 `backend/schema.sql` 與 `scripts/db/migration-lock.json`。

### 5.1 維度與特徵登錄表

```sql
CREATE TABLE morphological_dimensions (
  code TEXT PRIMARY KEY,
  name_expression_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  UNIQUE (sort_order),
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id)
);

CREATE TABLE morphological_features (
  code TEXT PRIMARY KEY,
  dimension_code TEXT NOT NULL,
  name_expression_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  UNIQUE (dimension_code, sort_order),
  FOREIGN KEY (dimension_code) REFERENCES morphological_dimensions(code),
  FOREIGN KEY (name_expression_id) REFERENCES expressions(id)
);
```

`name_expression_id` 指向該列英文名稱的 canonical expression，規則與語言名相同：

- `lang_code = 'eng'`
- `text` 等於該列的英文顯示名（見 §7）
- 使用既有 expression identity／find-or-create，不得為同一英文名重複建詞句
- 由系統 seed 建立並綁定；登錄列不得為 `NULL`

維度用來排範式表的欄／列標題。特徵是原子碼，不存複合格子名（不存 `1sg-present-indicative`）。

### 5.2 形態邊

```sql
CREATE TABLE expression_form_edges (
  id TEXT PRIMARY KEY,
  form_id TEXT NOT NULL,
  lemma_id TEXT NOT NULL,
  pair_low TEXT NOT NULL,
  pair_high TEXT NOT NULL,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (form_id <> lemma_id),
  CHECK (pair_low < pair_high),
  UNIQUE (form_id, lemma_id),
  UNIQUE (pair_low, pair_high),
  FOREIGN KEY (form_id) REFERENCES expressions(id),
  FOREIGN KEY (lemma_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_form_edge_features (
  edge_id TEXT NOT NULL,
  feature_code TEXT NOT NULL,
  PRIMARY KEY (edge_id, feature_code),
  FOREIGN KEY (edge_id) REFERENCES expression_form_edges(id),
  FOREIGN KEY (feature_code) REFERENCES morphological_features(code)
);
```

- Edge ID 使用 ULID。
- `pair_low`／`pair_high` 為 `form_id` 與 `lemma_id` 的字典序對，用來在資料庫層禁止互指。Service 寫入前必須先算好這對值；route 不得自行排序。
- `source` 是純文字標籤（`'contribution'`、`'import'`、`'seed'`），不是 FK 到 `sources`。
- 兩端同語言、存在性、非空特徵碼，由 service 校驗。D1 無法以 CHECK 跨表比對 `lang_code`。
- 需要索引：`expression_form_edges(form_id)`、`expression_form_edges(lemma_id)`、`expression_form_edge_features(feature_code)`。

### 5.3 與既有表的關係

- 不改 `expressions`、`expression_edges`、`expression_splits`。
- Split 產生新 homograph 後，舊形態邊仍指向舊 expression id。連錯了再手改。
- 名稱譯文是普通 `expression_edges` + locale attestation，不走形態邊。

## 6. 特徵詞彙

登錄表預先 seed 下列封閉清單。後續匯入若需新碼，另開 migration 加列，不改邊的形狀。

| `sort_order` | 維度 `code` | 特徵 `code`（同維度內依此序） |
|---:|---|---|
| 10 | `gender` | `masculine` `feminine` `neuter` |
| 20 | `number` | `singular` `plural` |
| 30 | `person` | `person-1` `person-2` `person-3` |
| 40 | `tense` | `present` `past` `imperfect` `future` |
| 50 | `mood` | `indicative` `subjunctive` `imperative` `conditional` |
| 60 | `nonfinite` | `infinitive` `gerund` `past-participle` |
| 70 | `degree` | `comparative` `superlative` |
| 80 | `polarity` | `negative` |
| 90 | `politeness` | `polite` |
| 100 | `voice` | `passive` `causative` |
| 110 | `construction` | `te-form` `potential` `volitional` `desiderative` `progressive` |
| 120 | `aspect` | `perfect` |
| 130 | `person-variant` | `voseo` |

同一維度內特徵 `sort_order` 從 1 起連續編號。例：

- `gatas → gato {feminine, plural}`
- `食べさせられました → 食べる {causative, passive, polite, past}`
- `goes → go {person-3, singular, present}`
- `went → go {past}`
- `gone → go {past-participle}`
- `habló → hablar {person-3, singular, past, indicative}`

西語辭書形即不定詞，不必把 `comer` 連到自己並標 `infinitive`。英語 `to eat` 若與 `eat` 分成兩個 expression，才用 `infinitive`。

## 7. 名稱國際化

### 7.1 解析

特徵與維度名稱復用語言名同一套合格候選規則（直接語義邊、target `lang_code` 等於請求 locale 的語言、完整 locale attestation、`score >= 0`），回退順序為：

1. primary UI locale
2. secondary UI locale
3. 英文 canonical expression 的 `text`
4. `code`

不得沿形態邊或圖譜多跳取名稱。未知、格式無效的 UI locale 忽略並繼續回退，不得因此 400／500。

實作上應抽出「依 `name_expression_id` 批次解析顯示名」的共用函式，供語言、locale 與形態登錄表共用；不要為形態名稱複製一份 SQL／回退。`IdentityKind` 不必新增 `'feature'`，解析入口吃的是 expression id 列表，不是 identity code。

所有回傳本地化特徵／維度名的讀取 API 接受既有 `ui_locale`、`secondary_ui_locale`。

### 7.2 Seed 範圍

每個維度與每個特徵建立或重用：

| 語言 | Locale 佐證 | 文字 |
|---|---|---|
| `eng` | `eng-Latn-US` | §7.3 英文名，此列同時是 `name_expression_id` |
| `cmn` | `cmn-Hans-CN` | §7.3 簡體 |
| `cmn` | `cmn-Hant-TW` | §7.3 繁體（與簡體是兩個 expression，因文字不同） |
| `jpn` | `jpn-Jpan-JP` | §7.3 日文 |
| `spa` | `spa-Latn-ES` | §7.3 西班牙文 |

每個非英文名稱 expression 與對應英文名建立一條直接 `expression_edge`，`source = 'seed'`。名稱 expression 使用既有 identity；若 `past`、`plural` 等英文已存在，重用，不預先拆同形詞。若日後語義圖被普通詞義污染，再以既有 split 處理。

Seed 由受控腳本或 migration 以 find-or-create 寫入，不手寫 hash id。腳本必須可重跑：已存在的 expression、edge、attestation 重用。系統 `created_by` 可為 `NULL`。

介面鉻（「詞形變化」「原形的對照」等區塊標題）走 vue-i18n，不走本登錄表。

### 7.3 顯示名

| `code` | eng | cmn-Hans-CN | cmn-Hant-TW | jpn | spa |
|---|---|---|---|---|---|
| `gender` | gender | 性 | 性 | 性 | género |
| `number` | number | 数 | 數 | 数 | número |
| `person` | person | 人称 | 人稱 | 人称 | persona |
| `tense` | tense | 时态 | 時態 | 時制 | tiempo |
| `mood` | mood | 语气 | 語氣 | 法 | modo |
| `nonfinite` | non-finite | 非限定 | 非限定 | 非定形 | no finito |
| `degree` | degree | 程度 | 程度 | 程度 | grado |
| `polarity` | polarity | 极性 | 極性 | 極性 | polaridad |
| `politeness` | politeness | 敬体 | 敬體 | 丁寧 | cortesía |
| `voice` | voice | 语态 | 語態 | 態 | voz |
| `construction` | construction | 构式 | 構式 | 活用形 | construcción |
| `aspect` | aspect | 体 | 體 | 相 | aspecto |
| `person-variant` | person variant | 人称变体 | 人稱變體 | 人称の変異 | variante de persona |
| `masculine` | masculine | 阳性 | 陽性 | 男性 | masculino |
| `feminine` | feminine | 阴性 | 陰性 | 女性 | femenino |
| `neuter` | neuter | 中性 | 中性 | 中性 | neutro |
| `singular` | singular | 单数 | 單數 | 単数 | singular |
| `plural` | plural | 复数 | 複數 | 複数 | plural |
| `person-1` | first person | 第一人称 | 第一人稱 | 一人称 | primera persona |
| `person-2` | second person | 第二人称 | 第二人稱 | 二人称 | segunda persona |
| `person-3` | third person | 第三人称 | 第三人稱 | 三人称 | tercera persona |
| `present` | present | 现在时 | 現在時 | 現在 | presente |
| `past` | past | 过去时 | 過去時 | 過去 | pretérito |
| `imperfect` | imperfect | 未完成过去时 | 未完成過去時 | 未完了過去 | imperfecto |
| `future` | future | 将来时 | 將來時 | 未来 | futuro |
| `indicative` | indicative | 直陈式 | 直陳式 | 直説法 | indicativo |
| `subjunctive` | subjunctive | 虚拟式 | 虛擬式 | 接続法 | subjuntivo |
| `imperative` | imperative | 命令式 | 命令式 | 命令法 | imperativo |
| `conditional` | conditional | 条件式 | 條件式 | 条件法 | condicional |
| `infinitive` | infinitive | 不定式 | 不定式 | 不定詞 | infinitivo |
| `gerund` | gerund | 动名词 | 動名詞 | 動名詞 | gerundio |
| `past-participle` | past participle | 过去分词 | 過去分詞 | 過去分詞 | participio |
| `comparative` | comparative | 比较级 | 比較級 | 比較級 | comparativo |
| `superlative` | superlative | 最高级 | 最高級 | 最上級 | superlativo |
| `negative` | negative | 否定 | 否定 | 否定 | negativo |
| `polite` | polite | 敬体 | 敬體 | 丁寧 | cortés |
| `passive` | passive | 被动 | 被動 | 受身 | pasivo |
| `causative` | causative | 使役 | 使役 | 使役 | causativo |
| `te-form` | te-form | て形 | て形 | て形 | forma te |
| `potential` | potential | 可能形 | 可能形 | 可能形 | potencial |
| `volitional` | volitional | 意志形 | 意志形 | 意向形 | volitivo |
| `desiderative` | desiderative | 希望形 | 希望形 | 希望形 | desiderativo |
| `progressive` | progressive | 进行体 | 進行體 | 進行形 | progresivo |
| `perfect` | perfect | 完成体 | 完成體 | 完了 | perfecto |
| `voseo` | voseo | 沃塞奥 | 沃塞奧 | ボセオ | voseo |

英文顯示名是給人看的標籤，不是機器碼：`person-1` 的英文為 `first person`，`past-participle` 為 `past participle`，`te-form` 為 `te-form`。

## 8. API

前綴 `/api/v2`，回應 `{ success, data?, error?, message? }`。本規格三條形態端點都不走 `paginated` helper：`GET /morphological-features` 回全表；兩條 `form-edges` 端點用物件包 `as_form`／`as_lemma`（或 POST 的單一邊）。`limit` 只作用於 `GET /expressions/:id/form-edges`，clamp 到 `[1, 50]`，預設 20，**每個方向各自計算**。詳情頁若要一次看滿單頁上限，必須顯式傳 `limit=50`。

### 8.1 `GET /morphological-features`

公開。回傳全部維度，每個維度內含已解析名稱的特徵，按 `sort_order`。

```json
{
  "dimensions": [
    {
      "code": "number",
      "name": "數",
      "name_en": "number",
      "sort_order": 20,
      "features": [
        { "code": "singular", "name": "單數", "name_en": "singular", "sort_order": 1 },
        { "code": "plural", "name": "複數", "name_en": "plural", "sort_order": 2 }
      ]
    }
  ]
}
```

此端點是貢獻選擇器的唯一特徵來源。前端不得硬編碼特徵碼列表。

### 8.2 `POST /expressions/:id/form-edges`

需登入。`:id` 是變化形。

```json
{
  "lemma_expression_id": "spa:…",
  "features": ["feminine", "plural"]
}
```

1. 兩端必須已存在。新詞先走既有 `POST /expressions`。
2. 校驗：同語言、非自己、無反向邊、每個 feature 皆在登錄表。請求內重複 code 先去重。
3. `(form_id, lemma_id)` find-or-create。
4. 省略 `features`：既有特徵不動；新建邊則為空。
5. 提供 `features`：與既有集合做聯集。
6. 整筆寫入原子；任一未知特徵整筆拒絕。
7. `source = 'contribution'`。後續匯入走同一 service，只改 `source`。

新建回 `201` + `created=true`；重用邊回 `200` + `created=false`。回應含邊、lemma 摘要、目前特徵集合。特徵名與語言名依 query 的 `ui_locale`／`secondary_ui_locale` 解析，規則與 GET 相同；未傳則回退英文 `text`，再回退 `code`。

不提供從原形一次張貼完整範式的批次端點。

### 8.3 `GET /expressions/:id/form-edges`

公開。一次回兩個方向：

```json
{
  "as_form": [
    {
      "edge_id": "…",
      "lemma": { "id": "…", "text": "gato", "lang_code": "spa", "language_name": "西班牙語" },
      "features": [
        { "code": "feminine", "name": "陰性", "dimension_code": "gender" },
        { "code": "plural", "name": "複數", "dimension_code": "number" }
      ]
    }
  ],
  "as_lemma": [
    {
      "edge_id": "…",
      "form": { "id": "…", "text": "gatas", "lang_code": "spa", "language_name": "西班牙語" },
      "features": []
    }
  ]
}
```

排序：`as_form` 依 `lemma.id ASC`。`as_lemma` 先取該邊特徵集合中最小的 `(dimension.sort_order, feature.sort_order)` 作為邊鍵，無特徵的邊排在有特徵的後面，再依 `form.id ASC`。`limit` 對 `as_form` 與 `as_lemma` 各自截斷；任一方被截斷則該方 `truncated=true`，並回該方 `omitted_count`。語言名與特徵名批次解析。

`GET /expressions/:id` 本規格不嵌入形態邊，詳情頁並行請求本端點。

### 8.4 搜尋

`GET /expressions/search` 仍按字面 `text LIKE` 命中，不改寫成原形，不把原形對譯假裝成命中。每個 hit 可附：

```json
{
  "form_of": [
    {
      "lemma": { "id": "…", "text": "gato", "lang_code": "spa" },
      "features": [{ "code": "plural", "name": "複數" }]
    }
  ]
}
```

對當頁全部 hit 一次批次查 `expression_form_edges`，不得逐列查詢。每個 hit 最多附 3 個 lemma（依 `lemma_id ASC`）；沒有形態邊則 `form_of` 為 `[]`。

### 8.5 錯誤碼

| 碼 | 時機 |
|---|---|
| `EXPRESSION_NOT_FOUND` | 變化形或原形不存在 |
| `FORM_EDGE_CROSS_LANGUAGE` | 兩端 `lang_code` 不同 |
| `FORM_EDGE_SELF` | `form_id = lemma_id` |
| `FORM_EDGE_MUTUAL` | 已存在反向邊 |
| `FORM_FEATURE_UNKNOWN` | 特徵碼不在登錄表 |
| `VALIDATION_FAILED` | 缺欄、空 id、非陣列 features |

資料庫 constraint 不直接暴露。

### 8.6 Split

既有 split 契約不變。步驟清單不增加形態邊搬移。測試須斷言：split 後舊 `form_id`／`lemma_id` 仍指向未搬的 expression。

## 9. 前端

沿用 `atlas.css` tokens、陶土色、`lucide-vue-next`。行動觸控目標至少 44px。圖譜與形態區尊重 `prefers-reduced-motion`。

### 9.1 搜尋

`Search.vue`／`ExpressionRow`：字面命中下方顯示一行形態摘要，例如「複數 ← gato」。多個原形以穩定順序並列。無 `form_of` 不顯示該行。摘要有 accessible name，不能只靠顏色。

### 9.2 Mapping Detail

`/mapping/:id` 維持語義圖譜不變。另加兩塊，放在圖譜／層級列表之外，不進入環狀圖：

1. **詞形變化**  
   - 只有單詞（expression `text` 無空白）才顯示本模組；句子、短語與介面字串不顯示。
   - `as_form`：列出原形與已解析特徵。  
   - `as_lemma`：按維度 `sort_order` 排成表或分組列表；空格不畫假格子。  
   - 同一節點兩種角色都有則兩塊都顯示（`found`）。
2. **原形的對照**  
   對最多 3 個原形，前端各打既有 `GET /expressions/:lemmaId/mappings?hops=1`。結果分組掛在各原形下，標題明確寫「原形的對照」，不得併入當前詞的圖譜節點。超過 3 個原形只展示前 3 個（與搜尋同一排序），其餘可連到該原形的 mapping 頁。

單詞頁固定顯示「新增詞形關聯」按鈕，不預先擋登入；未登入時點擊即導向 `/auth`（與 contribute 按鈕一致）。登入後展開「標為變化形」表單：搜尋同語言既有 expression 作為 lemma，核取登錄表特徵（依維度分組），提交 `POST /expressions/:id/form-edges`。不得一次提交多個 lemma。

複雜視覺（範式表）必須同時有列表替代。

### 9.3 不做的畫面

不改 Contribute 批次頁，避免與語義完全圖混淆。不在圖譜上畫第二種邊色表示形態。

## 10. 錯誤處理與上限

- 形態讀取失敗不得讓 mapping 頁整頁失敗；形態區顯示錯誤，圖譜仍可用。
- 原形對照的 1-hop 請求使用 request token／`AbortSignal`，locale 切換時舊回應不得覆蓋。
- 單頁形態鄰居上限 50；搜尋每 hit 的 `form_of` 上限 3；詳情展開原形對照上限 3。
- 一個名稱 expression 解析失敗只回退該列，不阻斷同批其他列。

## 11. 驗證

### 11.1 後端

- schema：四張表、FK、`(form_id, lemma_id)` 與 `(pair_low, pair_high)` 唯一、特徵聯集表。
- 寫入：同語言成功；跨語言、自連、互指拒絕；find-or-create；特徵聯集；未知特徵整筆拒絕；空特徵允許；一 form 多 lemma；同一節點可兼 form／lemma。
- 讀取：`as_form`／`as_lemma`、穩定排序、limit。
- 名稱：`plural` 在 `cmn-Hans-CN` 為 `复数`、`cmn-Hant-TW` 為 `複數`、`jpn-Jpan-JP` 為 `複数`、`spa-Latn-ES` 為 `plural`；缺譯回退英文。
- 隔離：建立形態邊後，同一 root 的 mapping graph 節點與邊集合不變。
- 搜尋仍字面命中；有邊才帶非空 `form_of`。
- split 後形態邊仍指舊 id。

### 11.2 前端

- `cd web && npm run build`。
- 詳情兩層不相混：`gatos` 圖譜不含 `gato`／`cat`；原形對照條含 `cat`。
- 搜尋 `gatos` 命中 `gatos` 並顯示指向 `gato` 的摘要。
- 特徵選擇器選項來自 `GET /morphological-features`，核取框可鍵盤操作、有可見 focus 與 accessible name。
- 桌面與行動 viewport：形態區可讀，觸控目標 ≥ 44px。

### 11.3 全流程

以手動或整合測試走通：建立 `gato` 與 `gatas` → 連 `{feminine, plural}` → 搜尋 `gatas` 見摘要 → mapping 頁見形態區與原形對照 → `gato` 的語義鄰居不出現在 `gatas` 圖譜。

跨前後端完成後執行相關後端測試與 `./build.sh`。

## 12. 交付條件

- 形態關係只存在於 `expression_form_edges`，語義圖行為與本規格前一致。
- 登錄表含 §6 全部維度與特徵，名稱可按 §7 四語五 locale 解析。
- 社區可對已存在的同語言詞句提交星型形態邊並後補特徵。
- 搜尋與詳情能從變化形走到原形對照，且兩層視覺與資料都不合併。
- schema、migration、seed、API 型別、composable、測試一致。
- 不修改 `apple/`，不改 `POST /contributions/batch`。
