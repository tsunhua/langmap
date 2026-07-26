# 全站語言代碼與本站社群介面翻譯規格

**日期：** 2026-07-26

**狀態：** Proposed

**範圍：** 全站 `language` domain、`expressions.language_code`、匯入腳本、`web_v2`、`backend_v2`、D1 schema、本站介面翻譯

**不涉及：** `web/`、`backend/`、`apple/`、外部網站翻譯平台

## 1. 摘要

本計畫包含兩個相連但可分階段交付的工作：

- 將全站詞句綁定的語言代碼正規化為「Glottolog languoid identity + canonical BCP 47 content tag」。
- 以 Glottolog 5.3 作為語言／方言唯一 registry；LangMap 不建立自己的語言 identity。
- 將 `web_v2` 的固定介面文案改為 key-based i18n。
- 任何已登入使用者都可以為已登記的 Glottolog/BCP 47 語系提交譯文。
- 譯文直接成為 expression mapping，正式網站按社群分數選出最佳候選。
- 語言切換器可搜尋並處理上百種介面語系。
- 缺少譯文或 API 故障時，穩定回退到內建英文。

介面來源文案與譯文使用既有 `expression` 保存，來源與譯文之間建立 `expression_edge`。站點只另外保存 message key、context 及來源 expression，不建立翻譯審核或發佈資料。

未來若要讓其他網站使用 LangMap 詞句作為頁面翻譯，可以在 message tables 增加 project 維度並開放相同 bundle 契約；本階段不實作多 project、外部 token、SDK 或第三方管理介面。

## 2. 現況

- `web_v2/src/components/nav/LangSwitcher.vue` 目前只顯示固定的 `ZH-TW`。
- 前端沒有 i18n library，文案直接寫在 Vue template 或 TypeScript。
- `backend_v2/schema.sql` 已有 `ui_locales(language_code, locale_json, ...)`，但沒有 route。
- 現有 `ui_locales.locale_json` 與 expression mapping 重複，且無法按詞句分數選譯。
- `languages`、`expressions`、`expression_edges` 已提供詞句及語義關係模型。

## 3. 目標與非目標

### 3.1 目標

1. 全站 expression 只綁定已登記的 canonical BCP 47 content tag。
2. 語言與方言 identity 優先使用 Glottocode，盡量停止自造代碼。
3. script、region、方言 identity 及顯示名稱分開保存。
4. 舊 code 可安全遷移，不改變 expression id。
5. Glottolog 分類及名稱保存 release version，更新時整批同步。
6. 本站所有固定介面文案可翻譯。
7. 已登入使用者可為已登記介面語系提交譯文。
8. bundle 依 mapping 分數及穩定 tie-break 選擇譯文。
9. 來源文案變更後可辨識過期譯文。
10. 來源及譯文重用既有 expression。
11. 語系切換器在 100 至 500 個語系時仍可搜尋及操作。
12. 支援 LTR、RTL、命名插值、複數、日期與數字格式。
13. 非來源語系按需載入，不預先下載所有語系。
14. API 或網路故障時仍能使用完整英文介面。

### 3.2 非目標

本階段不包含：

- 外部網站建立自己的翻譯 project。
- 第三方 API token、SDK、私有 catalog 或用量計費。
- 通用翻譯管理 SaaS。
- 翻譯 expression、handbook 等使用者內容。
- 讓使用者任意建立 message key。
- 自動建立或加分機器翻譯。
- 依 locale 改變路由，例如 `/en/...`。
- 建立另一套 UI 翻譯審核與發佈狀態。
- 本階段建立完整的語言分類關係編輯 UI。

## 4. Domain 邊界

本站 i18n 涉及三個不同概念：

| 概念 | 例子 | 責任 |
|---|---|---|
| content language | `yue` | 既有詞句所屬語言 |
| UI locale | `en-US`、`zh-Hant-TW`、`zh-Hans-CN` | 本站介面採用的語系 |
| message key | `nav.contribute` | 程式碼引用的穩定介面位置 |

### 4.1 與 expression 模型的關係

- 每段來源文案是一筆 `expression`。
- 每段候選譯文也是一筆 `expression`。
- 提交譯文時立即建立或重用 `expression_edge`。
- bundle 直接從 source expression 的 mappings 選擇 target expression。
- message key 不屬於自然語言，不建立為 expression。
- UI 譯文沒有額外審核狀態；品質完全沿用 mapping votes。

這個模型同時保留：

- 詞句可跨頁面重用。
- 翻譯關係可沉澱到 LangMap 詞句圖。
- 每個 message key 使用獨立的 contextual source expression，使 mapping 分數不被同字異義的其他 UI context 混用。

### 4.2 全站語言代碼決策

本節不只適用於 UI locale，也適用於：

- `expressions.language_code`
- `languages.code`
- 搜尋及貢獻 API 的語言參數
- handbook、mapping graph、language filter 及地圖
- CSV/SQL 匯入腳本
- `ui_locales.code`
- HTML `lang` 與對外 API

採用三層模型：

```text
實體識別       glotto:chao1238
內容交換標籤   nan-Hant-x-chao1238
顯示名稱       潮州話 / 潮語 / Teochew / Chiuchow
```

各層責任：

- **Languoid ID** 識別語言、方言或其他語言實體；優先使用 Glottocode。
- **BCP 47 content tag** 描述一段實際內容使用的語言、script、必要 region 及更細 languoid。
- **Display names** 使用 `languoids.preferred_name` 與既有 `languages.name/name_en`，不參與 identity。

不再把單一 `languages.code` 同時當作模糊的語言名稱、地區、方言 ID 與 UI locale。

### 4.3 Languoid ID

所有 languoid 都必須來自 Glottolog，ID 為 `glotto:<glottocode>`，例如 `glotto:chao1238`。

Glottocode 格式為 8 個字元，前 4 個為小寫英數字，後 4 個為數字。資料庫仍需依匯入版本驗證它是否真實存在，不能只驗證 regex。

若 Glottolog 尚未收錄，LangMap 不建立任何本地替代 ID。使用者應向 Glottolog 提交新增或修正，等待正式 release 後由 LangMap 更新 pinned dataset；在此之前不能新增該語言、方言或綁定 expression。後端不提供建立或編輯 languoid 的 API。

### 4.4 BCP 47 content tag

`languages.code` 及 `expressions.language_code` 保存 canonical BCP 47 content tag：

```text
language[-Script][-REGION][-variant...][-x-private...]
```

生成順序：

1. 使用 IANA Language Subtag Registry 中最精確且適用的 language subtag。
2. Glottolog dialect 沒有獨立 subtag 時，使用最近且有證據的上層 language/macrolanguage subtag。
3. 無可辯護的 base 時使用 `und`，不得任選一個看似相近的語言。
4. 已知書寫系統且會影響內容配對時加入 ISO 15924 script，例如 `Hant`、`Hans`、`Latn`。
5. region 只表示內容的地區化慣例，不用來假裝方言 identity。
6. 有正式 IANA variant 時優先使用正式 variant。
7. BCP 47 部分仍不能唯一識別 languoid 時，在尾端加入 `x-<glottocode>`。

範例：

| 情況 | Canonical content tag | Languoid |
|---|---|---|
| 一般英文 | `en` | 對應的 English languoid |
| 臺灣華語繁體字內容 | `cmn-Hant-TW` | `glotto:mand1415` |
| 潮州話繁體字 | `nan-Hant-x-chao1238` | `glotto:chao1238` |
| 潮州話拉丁字 | `nan-Latn-x-chao1238` | `glotto:chao1238` |
| 尚無合適 base 的 Glottolog 方言 | `und-x-abcd1234` | `glotto:abcd1234` |

若正式 BCP 47 部分已能唯一表示相同 languoid，不重複附加 Glottocode。例如 `yue-Hant` 不應機械式變成 `yue-Hant-x-yue...`。

UI locale 是介面協商標籤，可以沿用生態系慣例的 `zh-Hant-TW`；expression content tag 則應盡可能使用精確的 `cmn-Hant-TW`、`yue-Hant` 等。兩者都由同一 `languages` registry 驗證，但不要求 UI locale 與某段 expression 使用相同粒度。

`x-` 後是 private-use convention，不是 IANA 對 Glottocode 的正式承認。LangMap 約定：

- `x-<glottocode>`：更細實體由 Glottolog 識別。
- private-use 必須放在 tag 尾端。
- 每個 private subtag 只含英數字且不超過 8 字元。
- API 仍另外回傳 namespaced `languoid_id`，不可要求外部系統理解 `x-` 語義。

canonical casing：

- language、variant、private use：小寫。
- Script：Title Case。
- REGION：大寫。

只靠 `Intl.getCanonicalLocales()` 不足以確認 subtag 是否真的登記或 Glottocode 是否存在。後端 validator 應同時使用：

- BCP 47 parser/canonicalizer。
- 固定版本的 IANA Language Subtag Registry snapshot。
- 本地 `languoids` registry。

`languages` content tags 由版本控制內的資料 manifest 產生，必須同時通過 IANA 與 Glottolog validation。前端與公開 API 都不提供自由建立 language tag 的入口；需要新的 script/region 組合時走 repository 資料變更，而不是由使用者任意輸入。

### 4.5 資料模型

新增 `languoids`，把實體 identity 從 content tag 分離：

```sql
CREATE TABLE languoids (
    id TEXT PRIMARY KEY,
    glottocode TEXT UNIQUE NOT NULL,
    preferred_name TEXT NOT NULL,
    level TEXT NOT NULL
      CHECK (level IN ('family', 'language', 'dialect')),
    iso639_3 TEXT,
    parent_id TEXT,
    latitude REAL,
    longitude REAL,
    status TEXT NOT NULL DEFAULT 'active'
      CHECK (status IN ('active', 'retired')),
    source_version TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES languoids(id)
);
CREATE INDEX idx_languoids_glottocode ON languoids(glottocode);
CREATE INDEX idx_languoids_iso639_3 ON languoids(iso639_3);
```

現有 `languages` 保留為全站 content tag registry，避免全面重寫 API：

```sql
ALTER TABLE languages ADD COLUMN languoid_id TEXT;
ALTER TABLE languages ADD COLUMN base_language TEXT;
ALTER TABLE languages ADD COLUMN script_code TEXT;
ALTER TABLE languages ADD COLUMN source_version TEXT;
```

欄位語意：

- `languages.code`：唯一且建立後不可修改的 canonical BCP 47 content tag。
- `languoid_id`：指向 `languoids.id`。
- `base_language`：已登記的 primary language subtag，例如 `nan`。
- `script_code`：ISO 15924，例如 `Hant`。
- 既有 `region_code`：BCP 47 region；不是 dialect identity。
- `direction`：該 script/profile 的顯示方向。
- `is_active`：是否供一般詞句貢獻選擇。
- `source_version`：產生該 tag 時採用的 Glottolog release。

family-level languoid 只供分類與瀏覽，不能建立可綁定 expression 的 `languages` row。expression 只能指向 Glottolog `language` 或 `dialect`。

實作 migration 時重建 `languages` table 以加入：

```sql
FOREIGN KEY (languoid_id) REFERENCES languoids(id)
```

`expressions.language_code` 繼續保存 content tag，並補上對 `languages(code)` 的 foreign key。這是刻意保留的相容設計：現有 route、filter、graph response 和前端型別不需同時改成另一種 ID。

`ui_locales.code` 也引用 `languages(code)`；只有適合介面且經啟用的 content tag 才成為 UI locale。

### 4.6 Glottolog 分類

現階段完全採用 pinned Glottolog release 的 classification，不建立另一套分類關係或多來源圖譜。`languoids.parent_id` 直接保存該 release 的 parent；子節點由反向查詢取得。

LangMap 不提供修改 parent 的 API。分類修正應提交 Glottolog，待新 release 後整批同步。`source_version` 讓每筆資料可追溯到使用的 release。

### 4.7 Glottolog 匯入

使用 released Glottolog dataset，不抓取網頁：

- 本規格基準版本：`Glottolog 5.3`。
- 優先資料格式：官方 CLDF release。
- 最少匯入：Glottocode、preferred name、level、ISO 639-3、parent/classification 及 coordinates。
- 保存 `source_version = '5.3'`。
- 保留 CC BY 4.0 attribution、release version 及 Zenodo DOI。
- import script 必須可重跑、固定排序並輸出新增、更新、retired、衝突統計。
- 更新 Glottolog 版本時先產生 diff；已不存在的項目標記 `retired`，不得靜默重新指向另一個 languoid。

不把所有 Glottolog families 自動放進語言選擇器。`languoids` 可保存完整骨架，但只有建立了 `languages` content tag 且 `is_active = 1` 的項目可綁定 expression。

### 4.8 舊碼一次性遷移

不建立 runtime alias table。舊碼轉換只存在於一次性的、版本控制內的 migration manifest。

migration 完成後：

- API 只接受 canonical code。
- 舊 code 不再解析或 redirect。
- 前端不提供自由輸入 code，改用可搜尋 languoid/content tag picker。

資料 migration：

1. 盤點 `languages.code`、`expressions.language_code` 及 scripts 中的所有 distinct codes。
2. 對每個 code 建立 `keep`、`canonicalize`、`map-to-glottolog` 或 `manual-review` 清單。
3. 先匯入 languoids 並建立 canonical content tags。
4. 在單一 migration 中更新 expressions、language stats 及所有引用。
5. 不重新計算 expression id；既有 expression URL 保持不變。
6. 更新匯入腳本、fixtures、測試和文件中的舊 code。
7. 最後才啟用 foreign key 及嚴格 validator。

不得以 regex 大批猜測 script、region 或 Glottocode。例如舊 `nan-x-cha` 可以列為潮州話候選，但需人工確認資料集後才映射；若確認為潮州話且文字 script 可判定，分別遷移到 `nan-Hant-x-chao1238`、`nan-Hans-x-chao1238` 或 `nan-Latn-x-chao1238`，不能全部盲目改成同一 tag。

任何無法映射到 Glottolog 的舊 code 都會阻擋 migration，不建立臨時 identity。migration manifest 完成後不部署到 runtime，也不保留 alias 查詢。

### 4.9 全站 API 契約

所有回傳 expression 或 language 的 API 逐步統一提供：

```json
{
  "language": {
    "code": "nan-Hant-x-chao1238",
    "languoid_id": "glotto:chao1238",
    "glottocode": "chao1238",
    "name": "潮州話",
    "script": "Hant",
    "region": null,
    "direction": "ltr"
  }
}
```

為避免一次破壞全部前端，既有扁平 `language_code`、`language_name` 在 v2 遷移期保留；新增 nested `language`，待所有 consumer 完成後再另案移除扁平欄位。

新增 lookup：

- `GET /api/v2/languages?q=&level=&script=&limit=&cursor=`
- `GET /api/v2/languages/:code`
- `GET /api/v2/languoids/:id`

語言 picker 搜尋 `preferred_name`、`languages.name/name_en`、BCP 47 code、Glottocode 及 ISO 639-3。現階段不另建通用名稱／別名表。結果固定排序，需分頁並限制數量，不能一次把完整 Glottolog 骨架送到瀏覽器。

## 5. 來源 catalog

### 5.1 來源語系

`en-US` 是唯一來源語系，完整 catalog 隨前端程式部署：

```text
web_v2/src/locales/
├── en.ts
└── types.ts
```

```ts
export default {
  'nav.home': 'Home',
  'nav.contribute': 'Contribute',
  'mapping.quickAdd.submit': 'Add mapping',
  'search.resultCount': '{count} result | {count} results',
} as const
```

來源 catalog 不依賴 API。D1、網路或非來源 bundle 故障時，網站仍可完整顯示英文。

### 5.2 Key 規則

- 使用語意 key，例如 `mapping.quickAdd.submit`。
- key 發佈後保持穩定；修改來源文案不更名。
- 頁面、component、composable 不再直接放固定使用者文案。
- API `error` 使用穩定機器碼，前端以 `errors.<code>` 翻譯。
- 動態 key 必須來自明確 allowlist。
- 社群翻譯者不能新增 key；key 只由 repository catalog sync 建立。

每個 key 保存：

- `description`：使用情境。
- `scope`：例如 `nav`、`mapping`、`auth`。
- `message_format`：`text` 或 `plural`。
- `placeholders_json`：允許的命名參數。
- `source_hash`：來源 message pattern、placeholder schema 及 format 的雜湊。
- `status`：`active` 或 `deprecated`。

## 6. 資料模型

本站 i18n 只使用兩張表：locale 與 message；譯文直接使用既有 expressions、expression edges 及 votes。兩張表都帶 `project_id`，但現階段只有固定值 `langmap-web`，不建立 projects table 或管理功能。

實作時新增 migration，並同步更新 `backend_v2/schema.sql`。現有 `ui_locales.locale_json` 不沿用；若已有資料，先轉換成 `langmap-web` mappings 後再移除。

### 6.1 `ui_locales`

```sql
CREATE TABLE ui_locales (
    project_id TEXT NOT NULL,
    code TEXT NOT NULL,
    native_name TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    fallback_code TEXT,
    status TEXT NOT NULL DEFAULT 'draft'
      CHECK (status IN ('draft', 'active', 'archived')),
    mapping_revision INTEGER NOT NULL DEFAULT 0,
    created_by INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, code),
    FOREIGN KEY (project_id, fallback_code)
      REFERENCES ui_locales(project_id, code),
    FOREIGN KEY (code) REFERENCES languages(code),
    FOREIGN KEY (created_by) REFERENCES users(id)
);
```

規則：

- 現階段 `project_id` 固定為 `langmap-web`。
- `langmap-web` 的 `en` 是系統 seed，永遠為 `active`。
- 新 locale 預設為 `draft`。
- 達到設定的 coverage 門檻後可自動啟用；不逐筆審核譯文。
- fallback 只能指向 active locale，且不得形成循環。
- 任何符合 UI message/locale 的 mapping 新增或 vote 都增加對應 `(project_id, locale_code)` 的 `mapping_revision`；MVP 不先比較第一名是否真的改變。
- archived locale 不出現在一般切換器。

### 6.2 `ui_messages`

```sql
CREATE TABLE ui_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id TEXT NOT NULL,
    key TEXT NOT NULL,
    description TEXT,
    scope TEXT NOT NULL,
    message_format TEXT NOT NULL DEFAULT 'text'
      CHECK (message_format IN ('text', 'plural')),
    source_expression_id INTEGER NOT NULL,
    placeholders_json TEXT NOT NULL DEFAULT '{}',
    source_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active'
      CHECK (status IN ('active', 'deprecated')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, key),
    FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);
CREATE INDEX idx_ui_messages_scope_status
  ON ui_messages(project_id, scope, status, key);
```

每個 key 建立獨立的 contextual source expression：

- `source_type = 'ui_i18n'`
- `source_ref = <project-id>:<message-key>`
- 即使另一個 key 的英文文字相同，也不自動合併 source expression。
- target expression 仍可跨 key 重用。
- UI 工作台新建的 source/target template expressions 都使用 `source_type = 'ui_i18n'`，預設不出現在一般 feed 或 expression 搜尋；只有明確要求 UI translation context 時才回傳。重用既有自然詞句時保留原 `source_type`。

`text` message 的 expression 是一般含 placeholder 的文字。`plural` message 的 expression 保存完整、可驗證的 vue-i18n message pattern；它是一個完整翻譯單位，不再拆成 variants tables。

### 6.3 譯文就是 mapping

不建立 `ui_translations`。提交 UI 譯文時：

1. 以 exact locale + normalized text 重用 target expression，否則建立新 expression。
2. 驗證 placeholder 及完整 plural message pattern。
3. 建立或重用 contextual source expression 與 target expression 的 `expression_edge`。
4. 新 edge 初始分數為 `0`。
5. 增加目標 locale 的 `mapping_revision`。

之後所有讚踩都沿用既有 `/votes` 與 `expression_edges.score`，沒有另一套 UI translation votes。

這是刻意的產品決策：LangMap 已以 mapping 分數表達社群共識，再增加 reviewer approval 只會形成兩套互相競爭的品質權威。

bundle 對每個 message 只查直接 mappings，候選必須：

- 另一端 expression 的 `language_code` 精確等於請求 locale。
- message format 可編譯。
- placeholder 集合與 `ui_messages.placeholders_json` 完全一致。

候選固定排序：

1. `expression_edges.score DESC`
2. `expression_edges.created_at ASC`
3. `target_expression.id ASC`

第一名規則：

- 最高分 `>= 0`：直接使用。
- 最高分 `< 0`：視為沒有可信候選，進入 locale fallback。
- 沒有候選：進入 locale fallback。
- 新增符合條件的 mapping 或投票時，依 edge 端點反查 `ui_messages.source_expression_id`，增加所有受影響 `(project_id, locale_code)` 的 `mapping_revision`，讓 ETag 失效。

同分時舊 mapping 優先，避免 bundle 在沒有新社群訊號時抖動；target expression ID 是最後的確定性 tie-break。

來源 catalog 改變時建立新的 contextual source expression 並更新 `ui_messages.source_expression_id`，不把舊 mappings 自動套到新語意。舊 source expression 及 edges 保留為歷史詞句關係。

## 7. 翻譯格式與安全

### 7.1 純文字

- 預設只允許純文字。
- 不允許任意 HTML，不使用 `v-html`。
- 需要連結或 component 的句子，以受控 i18n component slot 組合。
- 單一 message 上限 4,000 Unicode code points。
- 拒絕不允許的控制字元。

### 7.2 Placeholder

只允許 metadata 宣告的命名 placeholder：

```text
source: {count} result | {count} results
allowed: { "count": "number" }
```

提交時：

- 不得遺失必要 placeholder。
- 不得加入未知 placeholder。
- 同一 placeholder 可以重複。
- 不允許動態 property path 或可執行內容。

不要以多個 key 拼接句子，避免不同語言無法調整語序。

### 7.3 複數

- source 與 target expression 都保存完整 vue-i18n plural message pattern。
- 提交時使用目標 locale 的 plural rules 編譯及驗證完整 pattern。
- target pattern 必須保留 `{count}` 及其他已宣告 placeholders。
- bundle 回傳獲勝 target expression 的 message pattern 字串。
- 日後若開放外部網站，再另案定義 framework-neutral format；MVP 不為此拆 variants tables。

### 7.4 日期與數字

- 使用 `Intl.DateTimeFormat`、`Intl.NumberFormat`、`Intl.RelativeTimeFormat`。
- 格式 preset 由程式碼定義。
- 社群不提交任意日期或數字格式程式碼。

## 8. API

所有 route 使用 `/api/v2/localization/projects/:projectId`，沿用 `{ success, data?, error?, message? }`。現階段只有 `langmap-web`；其他 project ID 回傳 `404 PROJECT_NOT_FOUND`。

### 8.1 公開 API

#### `GET /localization/projects/:projectId/locales`

回傳 active locales：

```json
{
  "success": true,
  "data": {
    "project_id": "langmap-web",
    "source_locale": "en",
    "locales": [
      {
        "code": "zh-Hant-TW",
        "native_name": "繁體中文",
        "direction": "ltr",
        "revision": 12,
        "translated": 438,
        "total": 500,
        "coverage": 0.876
      }
    ]
  }
}
```

來源語系優先，其餘依 `native_name`、`code` 穩定排序。

#### `GET /localization/projects/:projectId/locales/:code/messages`

```json
{
  "success": true,
  "data": {
    "project_id": "langmap-web",
    "locale": "zh-Hant-TW",
    "direction": "ltr",
    "revision": 12,
    "fallback_chain": ["zh-Hant-TW", "en"],
    "messages": {
      "nav.home": "首頁",
      "search.resultCount": "找到 {count} 筆結果"
    }
  }
}
```

規則：

- 對每個 active message 按第 6.3 節規則選出最高分 target expression。
- response value 直接使用獲勝 expression 的 `text`。
- 來源語系已內建，不需重複下載完整 bundle。
- 回傳 `ETag: "loc-langmap-web-zh-Hant-TW-r12"`，revision 來自該 project/locale 的 `mapping_revision`。
- 使用 `Cache-Control: public, max-age=300, stale-while-revalidate=86400`。
- 相同 `If-None-Match` 回傳 `304`。
- bundle 先不按 scope 拆分；gzip 超過 100 KB 或 active keys 超過 2,000 才加入 scope 載入。

### 8.2 協作 API

| Method | Route | 權限 | 用途 |
|---|---|---|---|
| `GET` | `/workbench/:code` | 登入 | 查看來源、所有 mapping 候選、分數及目前第一名 |
| `POST` | `/mappings` | 登入 | 以既有 expression 或文字直接建立 UI mapping |
| `POST` | `/mappings/batch` | 登入 | 小批建立 UI mappings |
| `POST` | `/locales/:code/archive` | admin | 封存 locale |

所有表格 route 均相對於 `/api/v2/localization/projects/:projectId`。批次上限 100 keys 或 256 KB。mapping 投票直接使用既有 vote API。

### 8.3 權限

MVP 沿用現有角色：

- 訪客：讀取 active locale 及 bundle。
- `user`：為既有 UI locale 建立 mapping、對 mapping 讚踩。
- `admin`：封存錯誤 locale，並沿用既有管理權限處理濫用內容。

不建立 reviewer、翻譯審核佇列或 project membership。所有 mutation 需有 JWT auth、rate limit 及 actor 紀錄。

### 8.4 Project scope 規則

- route、service 及 repository method 都必須顯式接收 `projectId`，不得在 SQL 中省略 project filter。
- project ID 使用穩定 slug，最長 64 字元；現階段唯一合法值為 `langmap-web`。
- response、ETag、cache key、source expression `source_ref` 都包含 project ID。
- 不提供 project list、create、update 或 delete API。
- 前端以單一常數 `LOCALIZATION_PROJECT_ID = 'langmap-web'` 呼叫 API，不顯示 project selector。

## 9. 前端 runtime

### 9.1 模組

```text
web_v2/src/
├── i18n/
│   ├── index.ts
│   ├── localeResolver.ts
│   ├── localeLoader.ts
│   └── types.ts
├── locales/
│   └── en.ts
├── stores/
│   └── uiLocale.ts
└── pages/
    └── TranslationWorkbench.vue
```

使用 `vue-i18n`。`main.ts` 先以內建來源語系 mount，再非阻塞載入使用者偏好 bundle；載入成功後一次切換。

### 9.2 初始語系

選擇順序：

1. `localStorage['langmap.uiLocale']` 中仍為 active 的 locale。
2. `navigator.languages` 的第一個精確或父級匹配。
3. `en`。

比對前 canonicalize：

```text
de-DE
→ de-DE
→ de
→ en
```

不能用 `startsWith('zh')` 模糊匹配。

### 9.3 Fallback

順序：

1. 請求 locale。
2. 明確設定的 `fallback_code`。
3. active 的 BCP 47 父級。
4. `en`。

最大深度 5，重複 code 立即停止。由最遠 fallback 向目前 locale 合併。

來源 catalog 改變時，message 會指向新的 contextual source expression；舊 mappings 自然不再參與選譯，不需要額外 stale translation 狀態。

### 9.4 Cache

- 記憶體中去重相同 locale/revision 的並行請求。
- HTTP 使用 ETag。
- localStorage 最多保存最近 3 個非來源 bundle。
- 先讀 cache，再背景 revalidate。
- 新 bundle 完整驗證後才原子替換。
- 解析失敗時清除該 cache 並回退，不部分套用。

切換成功後同步：

```ts
document.documentElement.lang = locale
document.documentElement.dir = direction
```

RTL 逐步改用 CSS logical properties。地圖和圖譜座標本身不鏡像。

## 10. 上百語系的 LangSwitcher

### 10.1 入口與面板

TopNav 按鈕顯示 Globe icon、目前語系短名稱及展開 icon。按下後：

- 桌面使用 popover。
- 行動版使用 bottom sheet。
- 搜尋欄固定在頂部。
- 依序顯示最近使用、瀏覽器建議、所有語系及「協助翻譯」。

每列顯示：

- native name。
- 目前介面語系中的顯示名稱；優先用 `Intl.DisplayNames`。
- canonical code。
- 可選的完成度。

不用國旗代表語言。

### 10.2 搜尋與效能

搜尋索引包含：

- locale code。
- native name。
- English name。
- 目前介面語系的顯示名稱。

預設不一次渲染所有 rows：

- 空白搜尋先顯示 40 個。
- 接近底部再增加 40 個。
- active locales 超過 500 且實測有問題後，才引入虛擬列表 dependency。
- 不預先下載任何非目前 locale 的 message bundle。

### 10.3 Accessibility

- 觸發按鈕使用 `aria-haspopup="dialog"` 及正確 `aria-expanded`。
- 開啟後焦點進入搜尋欄。
- 上下鍵移動選項，Enter 選取，Escape 關閉。
- 關閉後焦點回到觸發按鈕。
- 使用 combobox/listbox pattern。
- 觸控目標至少 44px。
- 載入、錯誤及空結果有 status/alert。

## 11. 翻譯工作台

### 11.1 路由

- `/translate`：介面語系總覽。
- `/translate/:code`：逐 key 翻譯。

未登入使用者可查看候選與分數，建立 mapping 或投票時要求登入。

### 11.2 語系總覽

顯示：

- native name、顯示名稱及 code。
- coverage。
- 有候選但最高分為負數的 key 數。
- mapping 候選總數。
- 最近 mapping/vote 活動。

UI locale 清單由匯入／部署設定產生，不提供「新建語言」表單。工作台只能從既有 active/draft UI locales 中選擇。

### 11.3 翻譯編輯器

每個 key 顯示：

- key、description 及 scope。
- 來源文案。
- 目前第一名、分數及 tie-break 資訊。
- 其餘 expression/mapping 候選及分數。
- 譯文輸入欄及 placeholder chips。
- 建立 mapping、讚及踩操作。

可篩選無候選、有可用候選、最高分為負數及 scope。前端即時驗證，後端重複驗證。

### 11.4 選譯預覽

工作台使用與公開 bundle 完全相同的 selector，顯示：

- 目前會進入 bundle 的 expression。
- 為何勝出，包括 score 及 tie-break。
- 投票後第一名是否改變。
- placeholder/plural validation。
- 常見 UI context 預覽。

## 12. Catalog 同步

新增 scripts：

```bash
cd web_v2 && npm run i18n:check
cd backend_v2 && npm run i18n:sync -- --dry-run
```

`i18n:check` 驗證：

- 使用的 key 存在。
- 無重複或空字串。
- placeholder schema 一致。
- plural variants 合法。
- 動態 key 在 allowlist。

`i18n:sync`：

1. 顯式指定 `project_id = 'langmap-web'`，為每個新 key 建立獨立 contextual source expression。
2. 新增 message 並保存 `source_expression_id`。
3. 來源變更時建立新 source expression，更新 message 和 `source_hash`。
4. 移除的 key 標記 deprecated，不刪除歷史 expressions 或 edges。
5. 輸出變更摘要，避免意外大量廢棄。

sync 只允許部署或 admin 執行，不提供一般使用者 API。

## 13. 故障、安全與品質

### 13.1 故障處理

| 情況 | 行為 |
|---|---|
| locale list 失敗 | 保留來源語系，切換器提供重試 |
| bundle 失敗 | 保留目前語系；首次載入則回退來源 |
| bundle 無效 | 丟棄該 cache，不部分套用 |
| 缺少 key | 依 fallback chain 回退 |
| fallback 循環 | 後端拒絕；前端仍去重及限制深度 |
| locale 被封存 | revalidate 後回退來源並更新偏好 |
| 來源新增 key | 顯示來源文案，完成度下降 |
| placeholder schema 改變 | 建立新 source expression，舊 mappings 不再參與 |
| 所有候選均為負分 | 按 fallback chain 取譯文 |

### 13.2 安全

- 每帳號及 IP rate limit。
- request size、批次數及文字長度限制。
- 純文字輸出。
- 後端驗證 placeholder、plural、locale 及 expression language。
- mapping 建立及投票沿用既有防重、rate limit 與 actor 紀錄。
- 一般 request log 不記錄完整譯文。

### 13.3 完成度

```text
coverage = 最高 mapping 分數 >= 0 的 active message 數 / active message 總數
```

另顯示無候選、負分候選及 mapping 總數。語系不要求 100% 才啟用；建議 coverage 達 60% 後自動啟用，admin 只處理錯誤或濫用 locale。

## 14. 測試

### 14.1 後端

- BCP 47 parsing、canonicalization、IANA registry validation 及 private-use 限制。
- Glottocode regex 與本地 registry existence validation。
- BCP 47 tag 與 languoid/script/region 欄位一致性。
- `nan-Hant-x-chao1238` 及 `und-x-abcd1234` round trip。
- 非 canonical、未知 Glottocode 及未登記 language tag 寫入錯誤。
- 一次性 migration manifest 完整覆蓋所有舊 code，runtime 沒有 alias。
- Glottolog import 重跑、版本 diff、retired/replaced 處理及固定排序。
- 舊 expression code migration 不改變 expression id。
- 語言 picker lookup 的分頁、上限、別名搜尋及穩定排序。
- fallback cycle 及 archived locale。
- unknown project 回傳 `PROJECT_NOT_FOUND`。
- locale/message/bundle queries 必須以 project scope 隔離。
- response、ETag、cache key 及 `source_ref` 均包含 project ID。
- mapping 建立 auth、expression 精確重用及 target language 驗證。
- 相同英文文字但不同 key 建立不同 contextual source expressions。
- `ui_i18n` template expressions 預設不出現在一般 feed/search。
- eligible mapping/vote 與 `mapping_revision` 原子更新。
- placeholder 及 plural validation。
- bundle 的 score、負分、無候選、同分及 ID tie-break。
- ETag、304、固定選譯及批次上限。
- 來源變更建立新 contextual source expression，舊 mappings 不再參與。

### 14.2 前端

- 初始 locale 決策及父級匹配。
- bundle 失敗仍顯示完整來源介面。
- fallback 合併順序。
- 更新 `html.lang`、`html.dir` 及 localStorage。
- 並行載入去重。
- 100、500 個 locale 的搜尋及分批渲染。
- LangSwitcher 鍵盤、焦點及 accessible name。
- 翻譯表單 validation 及離頁提醒。

### 14.3 視覺驗收

至少測試：

- `en`：來源及基本 LTR。
- `zh-Hant-TW`：本站主要目標語系。
- `de`：長字串。
- `ar`：RTL 及複數。
- `ja`：無空格文字。
- 測試環境 pseudo-locale `en-XA`：文字擴張及 missing key。

桌面與 390px viewport 都要檢查 TopNav、drawer、表單、錯誤狀態及翻譯工作台。長文案不可撐破容器，觸控目標至少 44px。

## 15. 分階段實作

### Phase 0：全站語言代碼基礎

- 固定 IANA registry 與 Glottolog 5.3 source snapshot。
- 新增 `languoids.parent_id`，不新增 relations 或 aliases tables。
- 擴充 `languages` 為 canonical content tag registry。
- 建立共用 parser、canonicalizer、validator 與 language picker API。
- 盤點所有現有 codes，產生人工可審的 migration manifest。
- 遷移 expressions、stats、scripts、tests 及 UI filters。
- 最後加入 foreign keys 並禁止任意 code 寫入。

完成條件：所有新 expression 只能綁定已登記的 canonical content tag；舊資料一次性完成轉換且 expression id 不變，runtime 不接受舊 code。

### Phase 1：本站 i18n runtime

- 安裝及初始化 `vue-i18n`。
- 建立完整 `en` catalog。
- 建立 locale resolver、loader、cache 及 store。
- 改造 LangSwitcher。
- 先遷移 TopNav、Auth、NotFound 及共用狀態。

完成條件：API 離線時來源語系完整可用，一個測試 locale 可動態切換。

### Phase 2：資料與 bundle

- 新增 D1 migration 及 schema。
- 建立帶 `project_id` 的 `ui_locales`、expression-backed `ui_messages`，不新增 translation/project table。
- 建立 locale list、bundle、revision 及 ETag。
- 建立共用 mapping score selector，供 bundle 與工作台共用。
- 建立 i18n check/sync scripts。

完成條件：bundle 直接由最高分 mappings 產生，無候選及負分時正確 fallback，後端測試通過。

### Phase 3：社群翻譯

- 建立 `/translate` 及 workbench。
- 實作 mapping 建立、候選排序、讚踩及即時第一名預覽。
- 顯示 coverage、無候選及負分候選。
- 加入 rate limit 及 audit fields。

完成條件：登入使用者可直接貢獻 mapping；相關 mapping 或投票後 revision 增加並可取得更新 bundle。

### Phase 4：全站遷移及 RTL

- 依共用 component、高流量頁、其餘頁面的順序移除硬編碼文案。
- 統一 API error code。
- 修正方向敏感 CSS。
- 加入 pseudo-locale 及 missing-key CI。
- 確認所有 expression、mapping、handbook、地圖與搜尋畫面顯示 canonical code 及 languoid name。

完成條件：`web_v2` 沒有未列入例外的固定使用者文案，RTL 與長文案不阻塞主要流程。

## 16. 未來擴展縫

本階段只保留以下低成本擴展性，不實作外部網站功能：

1. message 與 mapping selector service 集中，不散落在 Vue components。
2. bundle 契約保持簡單的 key/message map。
3. message key、revision、ETag 及 locale API 契約保持穩定。
4. 所有文案引用 expressions，使未來能共用詞句圖。
5. query/service 層集中封裝本站 catalog scope，不讓前端直接依賴「全域只有一份 catalog」的 SQL 細節。

若未來確定開放外部網站，再另寫 spec，評估：

- 增加以現有 text `project_id` 為主鍵的 `localization_projects`。
- 允許 `langmap-web` 以外的 project IDs；message/mapping 仍重用全域 expression graph。
- project membership、API token 及私有 catalog。
- 外部 catalog sync、SDK、配額及濫用防護。

這些都不是目前 migration、API 或 UI 的驗收內容。

## 17. 驗收標準

- 所有 expression 的 `language_code` 都是已登記的 canonical BCP 47 content tag。
- 方言優先以 Glottocode 識別，不再新增 `nan-x-cha` 或名稱拼寫式自造代碼。
- BCP 47 不足以識別方言時使用 `x-<glottocode>`，API 同時回傳 namespaced languoid ID。
- 找不到 Glottolog 項目時不能在 LangMap 建立語言；必須等待 Glottolog 正式 release。
- 舊 code 透過一次性 migration 轉換，不保留 runtime alias，且不改變 expression id。
- Glottolog classification、`preferred_name` 與 release version 原樣同步，LangMap 不提供本地修改入口。
- LangMap 本站可切換已啟用的介面語系。
- locale/message API、cache 及 source expressions 都以 `project_id = 'langmap-web'` 明確隔離。
- 已登入使用者可為既有 UI locale 提交譯文，但不能建立 languoid。
- 提交譯文時直接建立或重用 expression edge，不存在第二套審核狀態。
- bundle 對每個 key/locale 使用最高分非負 mapping，並有固定 tie-break。
- 所有候選為負分或沒有候選時進入 locale fallback。
- 相關 mapping 或 vote 發生時 ETag revision 失效。
- message context 與 expression 語言資產責任清楚，不重複保存譯文文字。
- 上百個 active locales 不會造成不可控 DOM 或預載大量 bundles。
- 缺 key、API 故障、負分候選、非法 placeholder 及 fallback cycle 都有安全回退。
- `en` 永遠內建且完整。
- 本階段沒有第三方 project、token、SDK 或外站管理功能。

## 18. 參考資料

- [RFC 5646：Tags for Identifying Languages](https://www.rfc-editor.org/info/rfc5646/)
- [IANA Language Subtag Registry](https://www.iana.org/assignments/language-subtags-tags-extensions/language-subtags-tags-extensions.xhtml)
- [Glottolog 5.3 information](https://glottolog.org/glottolog/glottologinformation)
- [Glottolog downloads and archived releases](https://glottolog.org/meta/downloads)
- [Glottolog 5.3 Chaozhou `chao1238`](https://glottolog.org/resource/languoid/id/chao1238)
- [Glottolog data repository and CLDF guidance](https://github.com/glottolog/glottolog)
