# 社群新增語言與自定義方言變種規格

**日期：** 2026-07-27

**狀態：** Proposed

**範圍：** `language` domain、語言建立 UI、`web`、`backend`、D1 schema、Glottolog／IANA registry 同步腳本

**前置文件：**

- `docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md`
- `scripts/v2/sync_language_registry.py`

## 1. 摘要

LangMap 不再批量建立所有語言、方言、書寫系統與地區組合。使用者在需要時建立語言：公開 BCP 47 subtags 從固定版本的 IANA registry 選擇；private-use 輸入會搜尋本地 Glottolog；找不到合適項目時，可保留使用者輸入並補充名稱與說明，建立社群方言變種。

本專案仍處於初期，因此採取一個直接、低負擔的模型：

```text
languages
  一列 = 一個可用於 expression 的 canonical BCP 47 content tag
  同時保存顯示名稱、Glottolog 對齊或社群 metadata

languoids
  Glottolog 的 pinned 搜尋與驗證快取；不是 LangMap 的建立門檻
```

`languages.code` 仍是全站穩定的內容語言代碼。既有 code 若符合新規則便原樣保留，因此 `expressions.language_code`、`ui_locales.code` 與既有 API 不需要重寫。只有少數不合法或非 canonical 的舊 code，才在單次 schema migration 中明確映射並更新其引用。

## 2. 目標與非目標

### 2.1 目標

1. 已登入使用者可從語言選擇器建立語言或方言。
2. 表單按 `language[-Script][-REGION][-variant...][-x-private...]` 分段組合 tag。
3. language、Script、REGION、variant 由 pinned IANA registry 搜尋式下拉提供。
4. private-use 可自由輸入；輸入時搜尋本地 Glottolog，使用者明確選擇是否對齊。
5. Glottolog 未收錄時，使用者可補充資料建立社群變種。
6. 建立成功後立即可用於 expression 貢獻。
7. 現有合法 canonical code 保持不變。
8. 同步腳本提供搜尋與驗證資料，不再展開所有可能的 content tags。

### 2.2 非目標

本階段不包含：

- 編輯 IANA 或 Glottolog 上游資料。
- 建立另一套完整語系分類、別名治理、人工審核或合併工作流。
- 自動判定兩個相似名稱必定是同一方言。
- BCP 47 extensions、grandfathered tags 或 private-use-only tags 的建立器支援。
- 對既有合法 code 建立 alias、雙寫欄位或長期 API 相容層。
- `apple/` 變更。

## 3. 核心決策

### 3.1 一列 language 就是一個內容 profile

`languages.code` 是 canonical BCP 47 content tag，也是 expression 與 UI locale 使用的鍵。表中的 `variety_key` 只用來將同一方言的多個 profile 歸在一起，不另建 `language_varieties` 表。

| code | name | variety_key | glottocode |
|---|---|---|---|
| `nan-Hant-x-chao1238` | 潮州話 | `glotto:chao1238` | `chao1238` |
| `nan-Latn-x-chao1238` | 潮州話 | `glotto:chao1238` | `chao1238` |
| `yue-Hant-CN-x-hegusan` | 河谷新村話 | `community:01K...` | `null` |

規則：

- Glottolog 對齊項目的 `variety_key` 固定為 `glotto:<glottocode>`。
- 社群變種建立時生成不可變 UUID/ULID，保存為 `community:<id>`。
- `variety_key` 不是公開 API 主鍵，也不供使用者編輯；它只支援搜尋、重複提示和日後把多種 script profile 歸類。
- 名稱、描述和位置可編輯；`code` 建立後不可修改。
- 有效 tag 組成需要改變時，建立新 language row。早期資料可在單次 migration 中直接更正，而不保留 alias 表。

### 3.2 Glottolog 是優先對齊，不是准入條件

- `languoids` 保存固定 Glottolog release 的搜尋資料。
- 使用者選中候選時，`glottocode` 必須存在於本地 `languoids`。
- 未選中候選時，建立當下保存 `glottocode = NULL` 的社群變種。
- private-use 文字看似 Glottocode 不代表已對齊；是否對齊只看 `glottocode` 欄位。
- 日後 Glottolog 收錄同一社群變種時，可直接補上 `glottocode`，原 code 和 `variety_key` 不變。

### 3.3 舊 code 相容策略

先盤點所有 distinct `languages.code`、`expressions.language_code` 與 `ui_locales.code`：

- 合法且已 canonical：原樣匯入新 `languages`。
- 合法但只需 casing 或 IANA preferred value 修正：建立明確 mapping，於重建時同步更新所有引用。
- 不合法或無法判定：列入 migration report；在資料仍很少的階段，由維護者修正或刪除對應測試／種子資料後再執行 migration。

不建立 runtime alias、redirect 或雙寫。migration 完成後，API 只接受新表中存在的 canonical code。

## 4. BCP 47 建立規則

### 4.1 支援形狀

```text
language[-Script][-REGION][-variant...][-x-private...]
```

| 段 | 數量 | 來源 | 表單 |
|---|---:|---|---|
| language | 1 | IANA `language` | 必選搜尋式下拉 |
| Script | 0..1 | IANA `script` | 可選搜尋式下拉 |
| REGION | 0..1 | IANA `region` | 可選搜尋式下拉 |
| variant | 0..n | IANA `variant` | 可排序多選 |
| private | 0..n | 使用者／Glottolog | 搜尋兼自由輸入 |

既有 `x-emoji`、`x-image` 是 system content，保留但不由此表單建立。

### 4.2 Canonicalization 與驗證

後端是唯一權威；前端只顯示預覽。

1. trim input 並拒絕控制字元。
2. 從 pinned IANA snapshot 驗證 public subtags 的 type、deprecated 狀態與 Preferred-Value。
3. 驗證 variant 的 Prefix 約束與重複。
4. 將 tag 組裝為 language、Script、REGION、variant、`x`、private 的正確次序。
5. language、variant、private 用小寫；Script 用 Title Case；REGION 用大寫。
6. 每個 private subtag 必須是 1 至 8 個 ASCII 英數字，canonical form 為小寫；完整 tag 最長 255 bytes。
7. canonical tag 必須尚未存在於 `languages.code`。

選擇 language 的 Suppress-Script 時，UI 顯示可省略提示；不自動刪除，因為 script 可能影響內容配對。

### 4.3 Private-use 與 Glottolog

private-use 欄位輸入至少 2 個字元後，debounce 250ms 查詢本地 `/languoids`。候選顯示名稱、Glottocode、level、ISO 639-3、parent 與 release version。

使用者必須明確選擇：

- 使用某個 Glottolog 項目：第一個 private subtag 使用其 Glottocode，並送出 `glottocode`；或
- Glottolog 沒有合適項目：保留使用者輸入的 private subtags，送出 `glottocode: null`。

若自由輸入等於現有 Glottocode，UI 必須要求使用者選擇「連結」或「不連結」，禁止隱式判定。

## 5. 使用者流程

### 5.1 入口

`LanguagePicker` 取代現有自由輸入與簡單下拉。搜尋無結果時，已登入使用者可選「新增語言或方言」。接入位置：新增 expression、mapping quick add、批量 contribution 與 UI 翻譯工作台。

### 5.2 建立對話框

1. **組合 tag**：選擇 language、Script、REGION、variants 和 private-use；即時顯示 canonical tag 預覽。
2. **比對 Glottolog**：選擇候選，或確認建立社群變種。
3. **補充資料**：填寫名稱與說明；自定義變種還需說明建立原因。
4. **確認**：顯示 tag、名稱、對齊來源、direction 和已存在的相似項目。

所有新 language 必填：

- `name`：1 至 120 Unicode code points；
- `description`：1 至 2,000 Unicode code points。

社群變種另必填：

- 至少一個 private subtag；
- `reason`：`missing_from_glottolog`、`community_specific`、`emerging_variety` 或 `other`。

可選資料：英文名稱、最多 20 個別名、parent Glottolog ID、使用地區、座標與最多 5 個 `https` reference URLs。

成功後 language picker 自動選中新 code；原 expression 表單內容保留。

## 6. 資料模型

language 相關 schema 可以直接重建。新 schema 不保留現有 `languages` 的 `family`、`group_name`、region name/coordinates、`status_text`、`languoid_id`、`source_version` 或 `is_active` 等歷史欄位。

### 6.1 `languages`

```sql
CREATE TABLE languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT NOT NULL DEFAULT '',
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    base_language TEXT NOT NULL,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT NOT NULL DEFAULT '[]',
    private_use_json TEXT NOT NULL DEFAULT '[]',
    variety_key TEXT NOT NULL,
    glottocode TEXT,
    origin TEXT NOT NULL CHECK (origin IN ('seed', 'glottolog', 'community', 'system')),
    community_reason TEXT,
    alternate_names_json TEXT NOT NULL DEFAULT '[]',
    references_json TEXT NOT NULL DEFAULT '[]',
    parent_languoid_id TEXT,
    latitude REAL,
    longitude REAL,
    created_by INTEGER,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (glottocode) REFERENCES languoids(glottocode),
    FOREIGN KEY (parent_languoid_id) REFERENCES languoids(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);
CREATE INDEX idx_languages_name ON languages(name);
CREATE INDEX idx_languages_variety_key ON languages(variety_key);
CREATE INDEX idx_languages_glottocode ON languages(glottocode);
CREATE INDEX idx_languages_base_script_region
  ON languages(base_language, script_code, region_code);
```

服務層規則：

- `origin = 'glottolog'` 時 `glottocode` 必填，`variety_key = 'glotto:' || glottocode`。
- `origin = 'community'` 表示建立來源；建立當下 `glottocode` 為 `NULL`，`variety_key` 必須以 `community:` 開頭，且 `community_reason` 必填。日後人工補上 Glottolog 對齊時保留 `origin` 與 `variety_key`。
- `origin = 'seed'` 可有或沒有 Glottocode；`origin = 'system'` 只供既有特殊內容。
- `variants_json`、`private_use_json`、`alternate_names_json`、`references_json` 的 shape、元素數量及長度由 service 驗證。
- `direction` 由 script 推導；沒有 script 時採 language seed/default。
- 不建立 review status、alias table 或 audit table。初期資料以正常內容管理方式處理。

### 6.2 `languoids` 與 IANA snapshot

保留 `languoids` 作 Glottolog 搜尋 cache。新增 `language_subtags`，讓 API 下拉與後端 validator 使用相同 pinned IANA snapshot：

```sql
CREATE TABLE language_subtags (
    type TEXT NOT NULL,
    subtag TEXT NOT NULL,
    descriptions_json TEXT NOT NULL,
    prefixes_json TEXT NOT NULL DEFAULT '[]',
    preferred_value TEXT,
    suppress_script TEXT,
    deprecated_at TEXT,
    registry_file_date TEXT NOT NULL,
    PRIMARY KEY (type, subtag)
);
```

## 7. API 契約

所有 route 使用 `/api/v2`，回應為 `{ success, data?, error?, message? }`。

### 7.1 Registry 查詢

#### `GET /language-registry/subtags`

Query：`type=language|script|region|variant`（必要）、`q`、`prefix`（variant 可選）、`limit`（預設 20、最大 50）、`cursor`。

排序：exact subtag、description prefix、description contains、`subtag ASC`。回傳 IANA file date。

#### `GET /languoids`

擴充既有 route：最少 2 字元才模糊搜尋；預設只回傳 `language`、`dialect`；支援 `level`、`parent_id`、`limit`、`cursor`。結果不得因 `languages` 的一對多關係重複。

### 7.2 預檢與建立

#### `POST /languages/preview`

需登入、不寫資料。Request：

```json
{
  "subtags": {
    "language": "nan",
    "script": "Hant",
    "region": null,
    "variants": [],
    "private_use": ["chao1238"]
  },
  "glottocode": "chao1238",
  "name": "潮州話"
}
```

回傳 canonical code、direction、warnings、exact existing language、同 `variety_key` 的 profiles、相似名稱與缺少欄位。

#### `POST /languages`

需登入且 email verified。Request：

```json
{
  "subtags": {
    "language": "yue",
    "script": "Hant",
    "region": "CN",
    "variants": [],
    "private_use": ["hegusan"]
  },
  "glottocode": null,
  "language": {
    "name": "河谷新村話",
    "name_en": null,
    "description": "由當地社群使用的粵語變種，自稱為河谷新村話。",
    "reason": "missing_from_glottolog",
    "alternate_names": [],
    "references": [],
    "parent_languoid_id": null,
    "latitude": null,
    "longitude": null
  }
}
```

後端重新驗證並在單一 transaction 建立一列 `languages`。成功回傳 `201` 與完整 language object。

錯誤：

| HTTP | error | 情況 |
|---:|---|---|
| 400 | `INVALID_LANGUAGE_SUBTAG` | public subtag 不存在或 type 錯誤 |
| 400 | `INVALID_VARIANT_PREFIX` | variant 不適用於 prefix |
| 400 | `INVALID_PRIVATE_USE` | private-use 格式錯誤 |
| 400 | `LANGUAGE_METADATA_REQUIRED` | 缺少名稱、說明或社群原因 |
| 401 | `AUTH_REQUIRED` | 未登入 |
| 403 | `VERIFIED_EMAIL_REQUIRED` | email 未驗證 |
| 409 | `LANGUAGE_CODE_EXISTS` | canonical tag 已存在 |
| 429 | `RATE_LIMITED` | 超出建立限制 |

### 7.3 現有 route 調整

- `GET /languages` 以 name、code、Glottocode、alternate names 搜尋，固定排序；不再依 `is_active` 過濾。
- `GET /languages/:code` 回傳完整 structured fields 與 `origin`、`variety_key`、`glottocode`。
- 所有 expression、contribution、mapping、localization mutation 都改為確認 `languages.code` 真實存在，不能只靠 regex 接受任意 tag。
- API 仍保留既有 `language_code`、`language_name`；新 consumer 使用 nested `language` object。

## 8. 前端設計

新增：

```text
web/src/components/language/
├── LanguagePicker.vue
├── LanguageCreateDialog.vue
├── LanguageTagBuilder.vue
├── LanguageSubtagSelect.vue
├── GlottologMatchList.vue
└── LanguageMetadataForm.vue

web/src/composables/
└── useLanguageCreation.ts
```

- 全部 API 經 `web/src/api/client.ts`。
- 搜尋可取消；過期 response 不得覆蓋新輸入。
- variant 因前段變更失效時清除並以 live region 告知。
- exact code 已存在時顯示「使用現有語言」，不送出 create。
- dialog 支援 focus trap、Escape、焦點還原、鍵盤 combobox 與 44px 觸控目標。
- 沿用 `atlas.css` 的 tokens；長名稱與 tag 容器設 `min-width: 0`；尊重 `prefers-reduced-motion`。

## 9. 同步腳本

`scripts/v2/sync_language_registry.py` 改為輸出：

- 完整 `languoids.csv`，作搜尋與 Glottocode 驗證；
- `iana-subtags.json`，作下拉與 canonicalization；
- `manifest.json`，保存 release、hash 與數量；
- 最小 `languages.csv` seed：現有合法 code、第一方 UI locale、`und`、`x-emoji`、`x-image` 和明確人工指定的 bootstrap languages。

不再：

- 對所有 Glottolog languoids 生成 base tag；
- 展開 major regions；
- 為所有 Sinitic descendants 乘上 script；
- 從 IANA variant prefixes 自動產生 `languages` rows。

每個 seed row 用同一組 IANA/Glottolog validation 驗證，輸出固定排序且可重跑。

## 10. 單次 migration

1. 建立新 `language_subtags` 並匯入 pinned IANA snapshot。
2. 建立新的 `languages` table。
3. 對舊 `languages` 逐列 parse 與 canonicalize：合格者保留 code；可安全修正者寫入 explicit mapping；無法判定者輸出 report。
4. 在同一 migration 更新 `expressions.language_code`、`ui_locales.code`、`language_stats.language_code` 及其他引用欄位的少數 mapped code。
5. 將保留／修正後的 rows 匯入新 `languages`，重建必要 index 與 foreign keys。
6. 移除舊 language 欄位與舊批量生成資料。

migration 前先檢查每個引用 code 最終都存在於新表；不符合時直接失敗，不留半完成狀態。因專案仍在早期，無法判定的資料可先由維護者修正或清理，再重跑完整 migration。

## 11. 安全與驗收

- 僅 email verified 使用者可建立 language；預設每帳號每日最多 10 個。
- 所有名稱與描述為純文字；reference URL 僅限 `https`。
- private-use 禁止 system reserved tokens；拒絕 bidi/invisible control characters。
- API 搜尋參數限制長度、escape SQL LIKE wildcard 並限制結果。

驗收：

1. 可建立 `yue-Hant-CN-x-hegusan` 類未收錄於 Glottolog 的社群變種。
2. 輸入 `chao1238` 可查到並明確選擇 Glottolog 候選；選中後保存 `glottocode` 和 `variety_key`。
3. 不選候選時，private-use 保留且建立 `community:` variety key。
4. public subtags 只能從 pinned IANA registry 選取，後端會再次驗證。
5. 可為同一 Glottocode 建立 Hant、Latn 等多個 profiles。
6. 現有合法 code 與相關 expressions/UI locales 不變；只有 explicit mapping 項目被更新。
7. 新建 language 可立即用於 expression 貢獻。
8. script 不再批量生成所有 language profile。
9. 前端 build、後端相關測試與 migration fixture 測試通過。

## 12. 與前置規格的關係

本文件取代 `2026-07-26-language-codes-and-community-ui-i18n.md` 中 Glottolog 必須作 identity、未收錄即不可新增、不得由前端建立 tag、全部 languoids 批量生成 tag，以及舊 code 一律阻擋 migration 的決策。

前置規格的 UI i18n、expression mapping、bundle、fallback、placeholder、plural 與 project scope 決策維持不變。
