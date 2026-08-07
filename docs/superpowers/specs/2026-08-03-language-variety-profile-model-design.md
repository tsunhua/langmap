# 語言變體與內容 Profile 分層設計

> 日期：2026-08-03
>
> 狀態：已確認，待實作
>
> 範圍：language domain、D1 schema、registry 與匯入腳本、`/api/v2/languages`、Web 語言瀏覽與貢獻流程

## 1. 摘要

LangMap 採「底層精確、上層合併」的兩層語言模型：

- **語言變體（language variety）**是使用者瀏覽、搜尋、統計與貢獻時認知的語言或方言，例如華語、粵語、潮州話；它另有可讀、穩定的公開 code。
- **內容 profile（language profile）**是該語言變體下精確的 canonical BCP 47 content tag，例如 `cmn-Hant`、`cmn-Hans`、`nan-Latn-tailo`。

詞句繼續綁定精確 profile，以保存書寫系統、地區與 variant 資訊；語言列表、語言詳情與「語言數」則以 variety 為主要單位。新增 script profile 不再造成使用者看到的語言數增加，也不再把同一社群切成多個互不相干的入口。

本專案尚未正式上線，因此本次直接修正 schema、API 與型別命名，不保留舊模型的長期雙寫或公開 API 相容層。

## 2. 背景與問題

現行模型把一列 `languages` 定義為一個內容 profile，並以 `variety_key` 將同一語言或方言的多個 profile 隱式歸組。例如：

| 現行 code | 現行 variety_key | 使用者認知 |
|---|---|---|
| `cmn-Hans` | `glotto:mand1415` | 華語（簡體） |
| `cmn-Hant` | `glotto:mand1415` | 華語（傳承體） |
| `nan-Hant-x-chao1238` | `glotto:chao1238` | 潮州話（傳承體） |
| `nan-Latn-pehoeji-x-chao1238` | `glotto:chao1238` | 潮州話（拉丁字） |

這個底層精度本身有價值，但目前 API 與 UI 又把每個 profile 當成一種獨立「語言」，造成：

1. 語言數隨 script、region 或 variant profile 增加而膨脹。
2. 同一語言社群在列表、詳情、搜尋與統計中被分隔。
3. 使用者必須先理解 BCP 47 code，才能選擇想貢獻的語言。
4. `language` 一詞同時指語言本體和內容 profile，API 與程式型別語義含混。
5. 未來若增加蒙古語、哈薩克語等多書寫系統，問題會跨出漢語範圍持續擴大。

現有 `variety_key` 已證明專案需要 variety 層，但它目前不是正式資料實體、不是公開識別碼，也無法獨立承載名稱、描述、別名、來源與管理資訊。

## 3. 目標

1. 正式區分語言變體與內容 profile，不再以一張表承擔兩種概念。
2. 保留精確 BCP 47 content tag，不犧牲資料品質與匯入可追溯性。
3. 語言列表、詳情、搜尋與統計預設以 variety 聚合。
4. 詞句、UI locale 與內容匯入仍能精確指定 profile。
5. 讓貢獻流程先選語言或方言，再選適用的內容 profile。
6. 建立適用於所有多書寫系統語言的通用模型，不對漢語寫死例外。
7. 趁尚未正式上線，一次修正容易造成長期混淆的 schema、API 與型別命名。

## 4. 非目標

- 不自動判定簡體與傳承體詞句等價。
- 不以 OpenCC 或其他字形轉換結果自動合併、建立 mapping 或覆寫原文。
- 不在本次新增「同一詞句的多書寫形式」專用關係模型。
- 不把 script、region 或 UI locale 視為語言變體。
- 不改變 Glottolog 是優先對齊、而非社群語言准入條件的既有原則。
- 不改變 mapping 仍是 expression 對 expression 的語義關係。
- 不在本次重新設計 `variation_status`；它仍描述共通內容與地方變體，不描述字體轉換關係。
- 不維持舊 `/language/:profileCode` 將 profile 當成語言頁的路由語義，也不維持舊 `language_code` 欄位的長期公開相容性。

## 5. 術語與不變量

### 5.1 語言變體（language variety）

語言變體是使用者認知中可承載詞句的語言或方言。它可以對齊一個 Glottolog languoid，也可以是尚未被 Glottolog 收錄的社群變體。

不變量：

- 每個 variety 有一個不可變、與外部 registry 無關的內部 ID，以及一個唯一、穩定、可讀的公開 code。
- 一個 variety 有一至多個 profile。
- Glottocode、ISO 639-3 與 BCP 47 base language 都是對齊或編碼資料，不是 variety 主鍵。
- Glottolog 對齊可以後補或修正，不改變 variety ID。
- 公開 code 優先使用能精確代表該 variety 的 IANA language subtag，例如華語 `cmn`、粵語 `yue`；沒有專用 subtag 的具體變體使用不含 script 的 private-use code，例如潮州話 `nan-x-chao1238`。
- 公開 code 不從任一 profile 即時截取，也不包含純書寫差異；`cmn-Hans` 與 `cmn-Hant` 的 variety code 都是 `cmn`。
- variety 名稱不帶「Simplified」「Traditional」等 profile 層資訊。

### 5.2 內容 profile（language profile）

內容 profile 是一個 variety 下可綁定詞句的精確內容標籤，其 `code` 是 canonical BCP 47 tag。

不變量：

- 每個 profile 只屬於一個 variety。
- `code` 全站唯一，建立後不可修改；需要改 code 時建立新 profile 並遷移引用。
- script、region、variant 與 private-use 由 code 解析並由 registry 驗證。
- profile 名稱用於區分書寫或地區形式，不充當 variety 的主要名稱。
- expression 與 UI locale 都引用 profile，但兩者的使用目的不同。

### 5.3 詞句（expression）

詞句仍是一段具體文字，必須引用一個 profile。兩個 profile 下文字相同，不代表是同一筆 expression；兩筆文字可互相轉換，也不代表語義必然相同。

## 6. 取代的既有決策

本規格確認後，取代以下既有決策：

1. `2026-07-27-community-language-creation.md` 的「一列 language 就是一個內容 profile」及「不另建 `language_varieties` 表」。
2. `2026-08-02-language-common-and-variant-profiles.md` 的「`/languages` 繼續逐 profile 顯示」。
3. 任何把 `languages.code` 同時描述為公開語言識別碼與 expression content tag 的文件段落。

仍保留的決策包括：

- canonical BCP 47 驗證與 casing 規則。
- Glottolog 對齊規則與社群變體建立能力。
- base／region／private-use profile 的共通與變體內容分工。
- UI locale 使用精確 profile，並對瀏覽器 `zh-*` 入站值做 locale alias negotiation。
- 歷史 migration 不回寫；新 migration 或未上線環境的重建流程承接最終模型。

## 7. 資料模型

### 7.1 `language_varieties`

```sql
CREATE TABLE language_varieties (
    id TEXT PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT NOT NULL DEFAULT '',
    glottocode TEXT,
    origin TEXT NOT NULL
      CHECK (origin IN ('seed', 'glottolog', 'community', 'system')),
    community_reason TEXT,
    alternate_names_json TEXT NOT NULL DEFAULT '[]',
    references_json TEXT NOT NULL DEFAULT '[]',
    parent_languoid_id TEXT,
    created_by TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (glottocode) REFERENCES languoids(glottocode),
    FOREIGN KEY (parent_languoid_id) REFERENCES languoids(id)
);

CREATE INDEX idx_language_varieties_name
  ON language_varieties(name);
CREATE INDEX idx_language_varieties_glottocode
  ON language_varieties(glottocode);
```

設計決策：

- `id` 使用應用程式生成的 ULID 字串，與既有 community identity 方向一致；只作內部主鍵與外鍵，不進入一般 URL 或公開 API。
- `code` 是 variety 的公開識別碼及 URL key。它遵循 canonical BCP 47 排序與 casing，但表示 variety 身份而非一段內容的完整 profile。
- `code` 建立後視為穩定。正式上線前的修正可經 migration 完成；正式上線後若需修改，必須另行設計 alias／redirect，不能直接破壞既有 URL。
- `glottocode` 不設 UNIQUE。資料清理應避免重複對齊，但不以資料庫約束假設 Glottolog 節點永遠等同 LangMap 的社群邊界。
- `origin` 表示 variety 最初如何進入 registry；日後補上 Glottolog 對齊不改寫 origin。
- `direction`、script、region、variant 與 private-use 不屬於 variety，全部留在 profile。
- 原本 profile rows 重複保存的 description、別名、references、建立者及上層 languoid 資訊，提升到 variety；只有確實屬於單一 profile 的顯示資料才留在 profile。

### 7.2 `language_profiles`

```sql
CREATE TABLE language_profiles (
    code TEXT PRIMARY KEY NOT NULL,
    language_variety_id TEXT NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    base_language TEXT NOT NULL,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT NOT NULL DEFAULT '[]',
    private_use_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);

CREATE INDEX idx_language_profiles_variety
  ON language_profiles(language_variety_id);
CREATE INDEX idx_language_profiles_base_script_region
  ON language_profiles(base_language, script_code, region_code);
```

設計決策：

- `code` 是 canonical BCP 47 content tag，也是 profile 的公開識別碼。
- `name`／`name_en` 是 profile label，例如「傳承體」「Traditional」；API 可以結合 variety name 顯示「華語（傳承體）」。seed 不再為每個 profile 重複維護一份完整語言名稱。
- 每個 variety 必須至少有一個 profile。建立 variety 與首個 profile 必須在同一 transaction 完成。
- 同一 variety 不得出現完全相同的 canonical code；全站主鍵已保證此條件。
- profile 不保存 `glottocode`、alternate names、references 或 community reason，避免與 variety 產生兩套可能衝突的身份資料。

### 7.3 既有表引用

```text
expressions.language_code
  → expressions.language_profile_code
  → language_profiles.code

ui_locales.code
  → language_profiles.code

language_locations.variety_key
  → language_locations.language_variety_id
  → language_varieties.id
```

- `expressions.language_profile_code` 必填。
- `ui_locales.code` 保留，因為它描述的是 locale 自身的 code，而非一個名為 language 的模糊外鍵；其 foreign key 改為引用 `language_profiles.code`。`fallback_code` 仍引用同 project 的另一個 UI locale。
- `language_locations.script_code` 保留。空字串表示適用整個 variety；非空值表示該代表地點只適用指定 script。
- 若 `language_stats` 保留，必須明確拆成 variety 與 profile 統計或移除。禁止一張表以模糊的 `language_code` 同時服務兩種粒度。

## 8. Registry 與建立流程

### 8.1 Registry manifest

`language_seed_profiles.json` 拆為清楚的兩層資料；實際可維持單檔，但資料 shape 必須分離：

```json
{
  "varieties": [
    {
      "id": "01K...",
      "code": "cmn",
      "name": "華語（普通話、國語）",
      "name_en": "Mandarin Chinese",
      "glottocode": "mand1415",
      "profiles": [
        { "code": "cmn-Hant", "name": "傳承體", "name_en": "Traditional" },
        { "code": "cmn-Hans", "name": "簡體", "name_en": "Simplified" }
      ]
    }
  ]
}
```

- seed variety ID 由版本控制內明確保存，不在每次產物生成時重新產生；它只用於資料庫關聯。
- seed variety code 也由版本控制明確保存，必須唯一並通過 canonicalization。一般 API、URL 與匯入參數使用 code，不使用內部 ID。
- 社群建立 variety 時生成新 ULID；新增既有 variety 的 profile 時沿用其 ID。
- registry 驗證需確認 variety code 唯一、每個 profile 的 canonical code、profile 唯一歸屬、至少一個 profile，以及 location 引用存在。

### 8.2 社群建立流程

建立入口分為兩種明確操作：

1. **建立語言或方言**：建立 variety 與第一個 profile。
2. **新增書寫或地區形式**：在既有 variety 下建立 profile。

預覽 API 必須搜尋相似 variety 與現有 profiles，避免使用者因只找不到 `Hans`／`Hant` 組合而重複建立整個語言。

服務層需拒絕：

- 沒有 profile 的新 variety。
- 指向不存在 variety 的 profile。
- 已存在或 canonicalization 後碰撞的 profile code。
- profile code 與選定 variety 明顯不一致且無 private-use 說明的請求。
- 把 script 或 region 名稱提交為 variety 名稱的明顯誤用。

## 9. API 契約

### 9.1 Variety API

```text
GET  /api/v2/languages
GET  /api/v2/languages/:code
GET  /api/v2/languages/:code/expressions
POST /api/v2/languages/preview
POST /api/v2/languages
```

`language` 在公開 API 中固定表示 variety。列表回應示例：

```json
{
  "code": "cmn",
  "name": "華語（普通話、國語）",
  "name_en": "Mandarin Chinese",
  "glottocode": "mand1415",
  "expression_count": 523,
  "profile_count": 2,
  "profiles": [
    {
      "code": "cmn-Hant",
      "name": "傳承體",
      "script_code": "Hant",
      "expression_count": 261
    },
    {
      "code": "cmn-Hans",
      "name": "簡體",
      "script_code": "Hans",
      "expression_count": 262
    }
  ]
}
```

規則：

- `expression_count` 是該 variety 所有 profiles 的 expression 總數。
- variety 的內部 ULID 不屬於一般公開契約；consumer 以穩定的 `code` 建立連結及查詢。
- `GET /languages` 的分頁、搜尋與排序都以 variety 為單位，在 SQL 聚合後套用，不能先對 profiles 分頁再於應用層合併。
- 搜尋 variety name、英文名、別名、Glottocode、ISO 639-3 或任一 profile code，都回到同一 variety 結果。
- `GET /languages/:code/expressions` 預設回傳全部 profiles，可用 `profile_code` 或 `script` 篩選。
- expression 結果必須保留 `language_profile_code` 與 profile label。

### 9.2 Profile API

```text
GET  /api/v2/language-profiles?q=&variety_code=&script=&limit=&cursor=
GET  /api/v2/language-profiles/:code
POST /api/v2/languages/:code/profiles/preview
POST /api/v2/languages/:code/profiles
```

Profile API 服務 language picker 第二步、維護工具、匯入與精確內容查詢；它不是一般語言瀏覽的主要入口。

### 9.3 Expression 與其他 API

- 所有 mutation request／response 的 `language_code` 改為 `language_profile_code`。
- 需要顯示語言身份時回傳 nested `language` variety summary 與 `language_profile` summary。
- graph node、feed、handbook、contribution、localization 與搜尋結果同步改名，避免部分 API 繼續把 profile 稱為 language。
- 不提供 `group_by=variety` 過渡參數，也不長期同時回傳新舊欄位。
- 一般 API 回應格式維持 `{ success, data?, error?, message? }`。

## 10. Web 體驗

### 10.1 語言列表

- 每個 variety 一列或一卡，不逐 profile 重複顯示。
- 「語言」統計使用 variety 數；另有需要時才顯示「內容 profiles」數。
- 卡片顯示合計詞句數與可用 profile chips，例如「傳承體」「簡體」。
- profile code 是次要技術資訊，不與語言名稱競爭視覺層級。
- 搜尋 `華語`、`华语`、`Mandarin`、`cmn-Hant` 或 `mand1415` 都命中華語同一入口。

### 10.2 語言詳情

- URL 使用 variety 的公開 code，例如華語 `/language/cmn`、潮州話 `/language/nan-x-chao1238`；不得暴露內部 ULID。
- 標題、描述、代表城市與總統計屬於 variety。
- 詞句預設顯示全部 profiles；提供「全部／傳承體／簡體」等可鍵盤操作的篩選。
- 每條詞句在混合列表中顯示 profile label；只顯示單一 profile 時可省略重複徽章。
- 地圖與圖譜以 variety 聚合時仍可展開檢視精確 profile，不丟失原始內容標籤。

### 10.3 貢獻與選擇器

語言選擇採兩階段：

1. 選擇 variety，例如華語。
2. 選擇 profile，例如傳承體或簡體。

- 只有一個 profile 時可自動選定，但仍顯示最終 content tag。
- 多個 profile 時根據使用者上次選擇或 UI locale 建議預設，不得靜默提交未展示的 profile。
- 新增語言與新增 profile 是兩個不同動作及文案。
- 所有互動維持至少 44px 觸控目標、可見 focus 與 accessible name。

## 11. 簡繁與跨 Profile 關係

同屬一個 variety 只表示共同語言身份，不表示兩個 expressions 自動相同。以下案例必須保持可區分：

- `後` 與 `后` 可能是字形對應，也可能在特定語境具有不同意義。
- `髮` 與 `发` 的簡化關係不是一對一可逆。
- 繁簡使用者可能採用不同地區詞彙，而非只有字形差異。
- 同一潮州話可用漢字、白話字或其他拉丁化方案書寫，轉寫不等同翻譯，也不保證無歧義。

因此：

- 不因 profile 同屬一個 variety 而自動建立 expression_edges。
- 不以轉換後文字相同作為去重鍵。
- 搜尋可以提供「同語言其他書寫形式」擴展結果，但必須標明來源 profile，不能假裝是同一筆資料。
- 未來若需要 orthographic-equivalence，應另行設計可審核、有來源、可表示一對多的關係，不塞入 mapping 或 `variation_status`。

## 12. 遷移策略

專案尚未正式上線，採一次性 schema 重建與明確資料遷移，不建立永久 alias 或雙寫。

### 12.1 對應產生

1. 盤點所有 `languages` rows、distinct `variety_key` 及其引用。
2. 對每個合法 `variety_key` 建立一個 variety ID 與公開 code；seed manifest 明確保存兩者。能由精確 IANA language subtag 表示者使用該 subtag，較細且無專用 subtag 者使用不含 script 的 canonical private-use code。
3. 同一 `variety_key` 的 profile metadata 若衝突，產出 report 並由維護者決定 variety 層名稱與描述，不以任意一列覆蓋。
4. 將現有 `languages.code` 原樣搬入 `language_profiles.code`，保留 canonical tag。
5. 將 expression、UI locale、location、統計及所有其他外鍵引用改到新欄位。

### 12.2 執行順序

1. 更新 registry manifest 與產物生成器，使新 schema 可由乾淨資料庫直接建立。
2. 更新 `backend/schema.sql`。
3. 新增 forward-only migration：建立新表、寫入 varieties、搬 profiles、重建引用表與 index。
4. 更新後端 services、routes、型別及測試。
5. 更新 Web API client、store／composable、型別、頁面與選擇器。
6. 更新 scripts、測試夾具、文件與驗證工具。
7. 在本地資料庫副本執行 migration，核對 row counts、orphan references 與聚合結果。

歷史 migrations 不回寫。若開發資料可安全重建，仍需保留一條可驗證的 migration 路徑，避免 schema 與 migration 最終狀態分歧。

### 12.3 回退

實作前備份本地 D1。migration 本身 forward-only；回退方式是還原備份與前一版程式，而不是在已搬移資料上執行猜測式 down migration。由於尚未上線，不設計線上雙讀、雙寫或逐批切流。

## 13. 錯誤處理

新增或沿用下列明確錯誤：

- `LANGUAGE_NOT_FOUND`：variety 不存在。
- `LANGUAGE_CODE_EXISTS`：variety 的公開 code 已存在。
- `LANGUAGE_PROFILE_NOT_FOUND`：profile 不存在。
- `LANGUAGE_PROFILE_CODE_EXISTS`：canonical profile code 已存在。
- `LANGUAGE_PROFILE_MISMATCH`：profile 與選定 variety 的 registry 對齊明顯不一致。
- `LANGUAGE_REQUIRES_PROFILE`：建立 variety 時未提供首個 profile。
- `LANGUAGE_PROFILE_IN_USE`：嘗試刪除仍被 expression 或 UI locale 引用的 profile。

API 不應把 profile 錯誤降級為通用 `INVALID_LANGUAGE_CODE`，以便前端提供可操作的修正提示。

## 14. 測試與驗證

### 14.1 Registry 與 migration

- 每個 variety 至少有一個 profile。
- 每個 variety 的公開 code 唯一且 canonical，內部 ID 不出現在一般 API 與 URL。
- 每個 profile 只屬於一個 variety，code 全站唯一且 canonical。
- 所有 expression 與 UI locale profile references 均存在。
- 所有 location variety references 均存在。
- migration 前後 profile 數、expression 數、mapping 數與 UI locale 數不變。
- migration 後不存在 orphan foreign keys 或舊 `languages` table 引用。
- 同一舊 `variety_key` 的 profiles 必須落到同一 variety ID。

### 14.2 後端

- `/languages` 對 `cmn-Hans`／`cmn-Hant` 只回傳一個華語 variety。
- `/languages/cmn` 回傳華語，且 `/language/cmn` 是其 Web 入口。
- `/languages/nan-x-chao1238` 可定位潮州話，不會錯誤退化成上層閩南語 `nan`。
- variety `expression_count` 等於所有 profiles 數量總和。
- 分頁以 varieties 為單位，頁面之間不重複、不漏項。
- 搜尋 variety 名稱、別名與任一 profile code 得到同一 variety。
- profile 篩選只回傳指定 profile 的詞句；未篩選時回傳全部。
- 建立 variety 與首個 profile 具 transaction 原子性。
- 建立第二個 profile 不增加 variety 數。
- 所有列表與圖遍歷維持穩定排序及數量上限。

### 14.3 Web

- 語言列表中華語、粵語、吳語等各只顯示一次。
- 「語言數」不因新增 `Hans`／`Hant` profile 改變。
- 詳情頁 profile 篩選、URL reload、空狀態與錯誤狀態正確。
- 貢獻流程提交 picker 選定的 `language_profile_code`。
- 搜尋 `華語`、`华语` 與 `cmn-Hant` 均能找到華語。
- 桌面與行動 viewport 無長名稱溢出；鍵盤、focus 與 screen reader label 可用。
- `cd web && npm run build` 通過。

### 14.4 全流程

- `cd backend && npm test` 在已啟動本地 Worker 與 D1 的條件下通過。
- `./build.sh` 通過。
- 乾淨 DB bootstrap 與既有本地 DB migration 得到相同最終 schema。
- 抽查華語、粵語、潮州話、蒙古語與哈薩克語，確認模型不依賴漢語特例。

## 15. 驗收標準

1. schema 中有獨立的 `language_varieties` 與 `language_profiles`，且責任不重疊。
2. variety 同時具有內部 ULID 與唯一公開 code；外鍵使用 ID，一般 API 與 URL 使用 code。
3. expression 與 UI locale 引用精確 profile；location 引用 variety。
4. 公開 `/languages` 以 variety 為資源，不逐 profile 製造重複語言。
5. 新增 profile 不增加語言數，刪除最後一個 profile 被拒絕。
6. API、TypeScript 型別與使用者文案不再用 `language` 指稱 profile。
7. 同一 variety 的 profiles 可被合併瀏覽與分別篩選，且原始 BCP 47 tag 不丟失。
8. 不自動合併或轉換簡繁 expressions，不改變既有 mappings。
9. registry artifacts、乾淨 schema、migration 後 schema 與測試夾具一致。
10. 舊規格中被本規格取代的決策已標示 superseded，避免後續實作者採用衝突方案。

## 16. 後續工作（不屬於本規格）

- 經審核的跨 profile 書寫形式等價關係。
- 自動轉寫建議及其來源、信心與人工確認流程。
- variety 合併、拆分與歷史 redirect 機制。
- 正式上線後的 API versioning 與相容政策。
