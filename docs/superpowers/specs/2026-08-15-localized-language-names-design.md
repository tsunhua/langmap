# 全站語言與 Locale 名稱本地化設計

日期：2026-08-15

狀態：已核准設計，尚未實作

## 1. 背景

LangMap 的介面語系可以切換至 `cmn-Hans-CN`、`cmn-Hant-TW` 等 Language Locale，但目前多數 API 直接以 `languages.name_en` 回傳語言名稱。結果是使用者切換至 `cmn-Hans-CN` 後，Mapping Detail 仍顯示 `jpn Japanese`，而非 `jpn 日语`。站內另有多處直接顯示 `jpn-Jpan-JP` 等 locale code，雖然精確，卻不適合作為一般使用者首先閱讀的標籤。

LangMap 已使用 expression、`expression_edges`、locale attestation 與 vote score 維護 UI 文案翻譯。語言與 locale 名稱應沿用同一套詞句 mapping，而不是在前端硬編碼名稱，或為每個 UI locale 增加欄位。

## 2. 目標

- 語言名稱隨目前 primary／secondary UI locale 在全站一致改變。
- `jpn` 在 `cmn-Hans-CN` 下顯示 `日语`；沒有合格譯名時安全回退至 `Japanese`。
- locale 在一般介面以目前 UI locale 可讀的名稱為主，例如 `jpn-Jpan-JP` 在 `cmn-Hans-CN` 下顯示 `日语（日本）`；缺少譯名時回退自稱 `日本語`。
- 語言與 locale 名稱的跨語言關係由既有 expression mapping、locale attestation 與 vote score 維護。
- Mapping Detail、圖譜、語言列表、搜尋、手冊及其他顯示語言身份的介面共用同一解析規則。
- locale code 仍作為精確、可複製的次要識別資訊；語系切換器始終以 locale 自稱為主要標籤。
- 查詢與排序穩定，避免逐筆查詢及 locale 切換後的舊資料覆蓋。

## 3. 非目標

- 不建立 `name_cmn_hans`、`name_cmn_hant` 等逐語系欄位。
- 不把全部語言或 locale 名稱加入 `langmap-web` 的 UI message bundle。
- 不依 language locale 的自稱 `language_locales.name` 推測其他 UI locale 應顯示的譯名。
- 不在這次變更中重新設計 expression、edge、vote 或 locale attestation 模型。
- 不要求所有語言在所有 UI locale 都已有名稱 mapping。

## 4. 資料模型

### 4.1 Canonical 名稱 expression

`languages` 與 `language_locales` 各新增 nullable 欄位：

```sql
languages.name_expression_id TEXT REFERENCES expressions(id)
language_locales.name_expression_id TEXT REFERENCES expressions(id)
```

此欄位指向該語言英文名稱的 canonical expression。例如：

```text
languages.code = jpn
languages.name_en = Japanese
languages.name_expression_id = <eng language expression for "Japanese">
```

兩張表的 `name_en` 暫時保留，作為既有 API 相容欄位、seed 可讀資料及 canonical 英文來源文字。`language_locales.name` 保留 locale 自稱。兩張表的 `name_expression_id` 才是進入多語 mapping 的穩定入口。

Canonical 名稱 expression 必須：

- `lang_code = 'eng'`；
- `text` 等於該列的 `name_en`；
- 使用既有 expression identity／重用規則，不能為相同英文名稱無限制建立重複 expression；
- 由系統 seed 或受控同步流程建立並綁定。

名稱譯文不直接存入 `languages`。例如 `Japanese → 日语` 以直接 `expression_edge` 表示，`日语` expression 另有 `cmn-Hans-CN` locale attestation。

Locale 名稱採相同模型。例如 `jpn-Jpan-JP` 的 `name_expression_id` 指向英文 canonical expression `Japanese (Japan)`；其簡體中文 mapping target 是 `日语（日本）`。`language_locales.name = 日本語` 仍保存該 locale 的自稱，不被 UI 翻譯覆寫。

### 4.2 遷移與相容

新增一個增量 migration，並同步更新 `backend/schema.sql`。遷移需為現有 language 與 language locale rows 建立或重用 canonical 英文名稱 expression，再回填 `name_expression_id`。

遷移完成後允許極少數未能回填的 legacy row 暫時保留 `NULL`；language 解析器直接回退 `name_en`，locale 解析器直接回退自稱 `name`。新建或由正式 seed／同步流程管理的 language／locale row 必須填入 `name_expression_id`。

更新語言 registry 的 seed、同步與驗證流程，確保未來新增語言時名稱 expression 與引用同步建立。歷史 migration 不回寫。

## 5. 共用名稱解析器

後端新增一個批次解析服務，以一組 language 或 language locale identity、primary locale 與可選 secondary locale 為輸入，輸出 `code → localized name`。所有 consumer 必須使用此服務或使用已由它解析的 API 欄位，不在 route 或前端重複 SQL／回退邏輯。

### 5.1 合格候選

對每個 `languages.name_expression_id` 或 `language_locales.name_expression_id`，候選名稱必須同時符合：

1. target expression 與 source name expression 有直接 `expression_edge`；
2. target expression 的 `lang_code` 等於請求 locale 在 `language_locales` 中對應的 `lang_code`；
3. target expression 有該完整 `language_locale_code` 的 locale attestation；
4. edge score 大於或等於 `0`。

只接受直接 edge，避免語義圖遍歷把相關但不等價的詞當成名稱。完整 locale attestation 可區分 `cmn-Hans-CN`、`cmn-Hant-TW` 等實際名稱形式。

### 5.2 穩定選擇

同一 locale 有多個合格候選時，依下列順序選第一筆：

```text
edge.score DESC
edge.created_at ASC
target_expression.id ASC
```

這與 UI localization 的可信候選精神一致，且在同分時產生可重複結果。

### 5.3 回退順序

Language 名稱逐項套用：

1. primary locale 的最高順位合格候選；
2. secondary locale 的最高順位合格候選；
3. `languages.name_en`；
4. `languages.code`。

Locale 名稱逐項套用：

1. primary locale 的最高順位合格候選；
2. secondary locale 的最高順位合格候選；
3. `language_locales.name` 自稱；
4. `language_locales.name_en`；
5. `language_locales.code`。

primary 與 secondary 相同時只解析一次。這兩個參數在本功能涵蓋的公開讀取 API 中都只是顯示偏好；未知、archived 或格式無效的值一律忽略，並繼續 secondary 或英文回退，不得造成 400 或 500。既有 localization mutation 的嚴格 locale 驗證不受影響。

### 5.4 批次與效能

圖譜與列表必須批次解析該回應內 distinct language／locale codes，不得對每個節點或列執行獨立查詢。解析查詢需有明確數量上限，沿用呼叫端既有 page／node limit，並以穩定排序取得候選。

若 query plan 顯示既有 `expression_edges`、`expression_locale_attestations` 索引不足，才新增針對實際查詢的索引；索引同樣需要 migration 與 `schema.sql` 同步。

## 6. API 與前端資料流

### 6.1 API 契約

所有回傳語言或 locale 顯示名稱的公開 API 接受目前 primary UI locale；支援 secondary locale 的 consumer 同時傳入 secondary。參數命名在全站統一為：

```text
ui_locale=<primary language locale code>
secondary_ui_locale=<optional secondary language locale code>
```

既有 `language_name`、language summary 的 `name` 與 locale summary 的 `display_name` 使用解析後名稱；`name` 自稱及 `name_en` 英文原值仍保留在 locale summary。language／locale code 與 expression identity 不受名稱本地化影響。

至少涵蓋：

- Mapping graph／Mapping Detail；
- 語言列表與語言詳情；
- 搜尋結果與 feed 中顯示的語言名稱；
- Handbook expression 資料；
- Map Lens、Inspector、文字替代列表及其他共用語言標籤。
- Language Locale picker、Contribution、Translate Workbench、Language Detail 篩選器與 expression evidence／reading 顯示。

API 型別、composable、store 與測試需同步更新。若某 consumer 目前只顯示 code，毋須為了本功能強制新增名稱；一旦顯示名稱，就必須使用共用解析結果。

### 6.2 Locale 切換

前端從 localization store 取得 primary／secondary locale。切換偏好後：

- 依賴伺服器本地化名稱的頁面重新載入相關資料；
- graph、列表等請求需帶 `AbortSignal` 或 request token，舊 locale 的慢回應不得覆蓋新 locale；
- 共用展示元件只接收 `language_name`，不自行查詢或推測翻譯；
- loading 過程保留既有內容或既有 loading pattern，避免短暫顯示錯誤語系名稱。

前端不建立獨立的 language／locale-name 翻譯表，避免與 mapping 資料分叉。

### 6.3 Locale 顯示層級

一般使用者介面不得只以 raw locale code 作主要標籤：

- 選擇器、篩選器、列表與摘要：以 `display_name` 為主，自稱與完整 code 作次要資訊；空間不足時可省略自稱，但 code 應可經 tooltip、詳情或 accessible description 取得。
- expression locale attestation、reading evidence、管理及除錯介面：顯示 `display_name`，並同時保留完整 code，因為 script、region 與 place path 是資料判讀的一部分。
- 狹窄 badge：優先 `display_name`；名稱缺失才直接顯示 code，且不能只靠 tooltip 傳達完成任務所需資訊。
- 語系切換器：始終以 `language_locales.name` 自稱為主要標籤，讓使用者在看不懂目前 UI locale 時仍能找到自己的語言；可用 script／region 名稱及 code 作輔助，但不以目前 UI locale 的譯名取代自稱。

例如在 `cmn-Hans-CN` 介面中，一般 locale picker 可呈現：

```text
日语（日本）
日本語 · jpn-Jpan-JP
```

同一項在語系切換器則以 `日本語` 為主要文字。

## 7. 寫入與 revision

新增、刪除或投票改變語言或 locale 名稱相關 edge 時，名稱解析應在下一次請求反映最新 score。若未來為讀取結果加入 cache，cache key 至少包含 identity code、primary locale、secondary locale 與受影響 locale 的 mapping revision。

本次可以先採每次請求解析，不預先建立另一套 revision table。不得因效能推測提前複製名稱譯文。

## 8. 錯誤處理

- `name_expression_id` 缺失或引用資料不可用：language 回退 `name_en`；locale 回退自稱 `name`，再回退 `name_en`；記錄可觀測錯誤，不使整個頁面失敗。
- locale 不存在、未啟用或格式無效：公開讀取 API 忽略該顯示偏好並回退，不執行模糊 prefix 猜測。
- mapping 無候選、只有負分候選或 attestation 不符：視為沒有譯名並進入下一層回退。
- 一個 language 的資料異常不得阻止同批其他 language 名稱解析。
- API 仍使用 `{ success, data?, error?, message? }` envelope。

## 9. 驗證與測試

### 9.1 後端

- `jpn` 的 canonical `Japanese` expression 經 mapping 在 `cmn-Hans-CN` 解析為 `日语`。
- `jpn-Jpan-JP` 的 canonical `Japanese (Japan)` expression 在 `cmn-Hans-CN` 解析為 `日语（日本）`。
- 切至 `cmn-Hant-TW` 可選取具有該 locale attestation 的名稱，不誤用簡體候選。
- primary 無候選時使用 secondary；兩者都無候選時，language 回退 `name_en`，locale 優先回退自稱。
- 負分 edge 不採用。
- 同分候選依 `created_at`、target ID 穩定選擇。
- 一次批次解析多個重複 language code，只回傳每個 distinct code 的結果。
- 缺少 `name_expression_id`、未知 code 與不完整 legacy data 均安全回退。
- Mapping graph、language list、handbook 等相關 route 正確傳遞 locale 並回傳本地化名稱。

### 9.2 前端

- localization store 的 primary／secondary locale 正確傳入相關 API。
- 從 `eng-Latn-US` 切到 `cmn-Hans-CN` 後，`jpn Japanese` 更新為 `jpn 日语`。
- 一般 locale picker 在 `cmn-Hans-CN` 下以 `日语（日本）` 為主，並保留 `日本語 · jpn-Jpan-JP` 的識別資訊。
- 語系切換器在任何 UI locale 下都以 `日本語` 等自稱為主，不因介面語言切換而失去可辨識性。
- 快速切換 locale 時，舊請求不得覆蓋新名稱。
- 圖譜節點、Inspector、文字替代列表與頁面標題使用同一 `language_name`。
- 英文回退及只顯示 code 的狀態不產生空白 accessible name。

### 9.3 全流程

至少驗證 Mapping Detail 範例：

```text
/mapping/cmn:uatw46tkfaeq2igc7xhtci62km?node=cmn:fg6livf5llbcxn66umfdpwnrnq
```

在 `cmn-Hans-CN` 下，所有 `jpn` 節點及相關 Inspector／列表一致顯示 `jpn 日语`。再切回英文時恢復 `jpn Japanese`。

前端變更執行 `cd web && npm run build` 並檢查桌面與行動 viewport；後端變更執行相關測試。跨前後端完成後執行 `./build.sh` 與完整流程驗證。

## 10. 交付條件

- 語言與 locale 名稱的翻譯只由 canonical name expression、direct mapping、locale attestation 與 score 決定。
- 全站所有已顯示語言或 locale 名稱的 consumer 使用同一解析規則與顯示層級。
- locale 切換能更新現有頁面的名稱，且沒有競態回歸。
- schema、migration、seed／同步流程、API 型別、前端 consumer 與測試一致。
- 缺少翻譯或 legacy 資料時有明確英文／code 回退，不造成頁面失敗。
