# 語言身份以 ISO 639-3 為核心，地域形式與詞句身份分離

> **狀態：已接受。** 本 ADR 取代 [ADR 0003](./0003-language-identity-uses-glottolog-and-bcp47-content-tags.md)。

## 背景

ADR 0003 把 Glottolog languoid identity 與 BCP 47 content tag 分成兩層。實作後出現三個根本問題：

1. Expression 綁定 content tag，使同一詞句在不同書寫系統或地區 profile 下成為不同節點，mapping 圖因此斷裂。
2. BCP 47 region 通常只能表達國家或地區，無法承載陸豐甲子等實際需要的次級地點。
3. Glottolog 的實體邊界不等於 LangMap 希望呈現的比較邊界；例如潮州話與其他閩南語形式需要在同一語言代碼下，以地域差異並排比較。

LangMap 的第一性資料是詞句與 mapping 圖，不是全球方言分類。語言身份必須穩定且簡單；書寫系統、地點、當地自稱與讀音則應按證據逐步追加。

## 決定

### 1. 語言身份

- `lang_code` 嚴格使用小寫的 ISO 639-3 個體語言代碼，例如 `nan`、`cmn`、`yue`、`jpn`、`eng`。
- 不使用 macrolanguage 覆寫、Glottocode、BCP 47 private-use 或 LangMap 自造代碼作為語言身份。
- 每個 `lang_code` 只有一個英文 exonym。地域形式的當地自稱不放在語言層。
- 潮州話沒有獨立 ISO 639-3 代碼，在本模型中使用 `nan`；`teo` 是 Teso，不是 Teochew。

### 2. 地域形式代碼

Language Locale 描述一個語言在特定書寫系統與地點出現的地域形式，其代碼 grammar 為：

```text
language_locale_code = lang "-" script "-" country ("_" place_segment)*
```

- `lang`：ISO 639-3 個體語言代碼。
- `script`：ISO 15924 四字母代碼，使用標準大小寫；不接受自訂 script。
- `country`：ISO 3166-1 alpha-2 國家或地區代碼。
- `place_segment`：可選、可變深度、由使用者自訂，且必須符合 `^[A-Z][A-Za-z]*$`；段內大寫可表示多字地名，例如 `NewYork`。
- `-` 分隔語言、書寫系統與地點三種頂層欄位；`_` 分隔地點路徑內由大至小的層級。
- 國家或地區必填，其他地點層級均可省略；不以 `NULL`、`Unknown` 或空白段補齊。
- 每個 Language Locale 保存一個當地自稱 endonym。
- 這套代碼不是 BCP 47，不得直接宣稱為 HTML、HTTP 或 i18n library 的標準 locale tag。

例如：

```text
nan-Hant-CN
nan-Hant-CN_Quanzhou_Nanan
nan-Latn-TW_Tainan
eng-Latn-US_NewYork
```

Script 只描述書寫系統。Pinyin、Wade–Giles、POJ、Tâi-lô、Jyutping、IPA 或 phonics 等讀音記法不進入 Language Locale code。

### 3. Expression 身份與同形拆分

- 預設一個 `(lang_code, text)` 對應一個 Expression，概念 ID 為 `{lang}:{text}`。
- 意義由 mapping 圖承載，不新增 `sense_gloss` 或預先建立 sense 實體。
- 當 mapping 鄰域已出現需要分離的不同語義時，維護者可手動建立 `{lang}:{text}.2`、`.3` 等 Expression，並把相關 mappings 搬到新節點。
- 數字後綴是不透明識別標籤，不表達詞義或重要順序。
- 系統不自動偵測、提示或拆分同形詞；也不能永久取消手動拆分能力。

這接受未拆分同形詞會暫時污染間接 mapping 的代價，換取預設身份簡單、按真實問題拆分的模型。

### 4. 地域佐證與讀音標記

- 貢獻 Expression 時，`language_locale_code` 選填。
- 未提供 locale 時只建立 Expression，不建立 `NULL` 或未知地域記錄，也不作地域斷言。
- 提供 locale 時建立一筆有來源的地域佐證。佐證可隨新證據追加，只表示「曾在此地域形式出現」，不宣稱完整分布。
- 一筆讀音標記必須同時指向 Expression 與 Language Locale，因此也構成地域佐證。

文字讀音採單表模型，概念欄位為：

```text
expression_readings(
  id,
  expression_id,
  language_locale_code,
  scheme,
  value,
  source_type,
  source_ref,
  created_by,
  created_at
)
```

- `scheme` 是穩定短代碼，不另建讀音系統註冊表。
- 同一 Expression、Language Locale 與 scheme 可保存多筆不同來源記錄；同值但來源不同仍是不同佐證。
- 不選出全站唯一或標準讀音，不在資料庫解析或驗證讀音字串，不在地域之間自動繼承。
- `phonics` 必須指明具體方法或教材，不能用一個未具名代碼假設所有自然拼讀方案相同。
- 音檔不與文字讀音混表，也不在本次決策範圍。

### 5. UI Locale 與使用者語言偏好

- UI Locale 保存在 project-scoped 的獨立資料表，但每筆必須關聯一個 Language Locale。
- UI Locale 的翻譯狀態與 fallback 不代表 Language Locale 的地域、讀音或繼承關係。
- 新 UI Locale 預設為 `draft`。自身有效翻譯覆蓋率達 60% 時自動轉為 `active`；有權限的維護者也能在未達門檻時手動啟用。
- 啟用後即使覆蓋率下降也不自動停用；只有管理員能將它封存。
- 覆蓋率分母是 active UI 詞句，分子是該 Language Locale 自身具有效直接 mapping、合法 placeholder 與地域佐證的詞句。Fallback 譯文不計入覆蓋率，且分母為零時不得以 100% 啟用。
- 使用者選擇第一 Language Locale 與可選的第二 Language Locale。每條 UI 詞句依「第一語言 → 第二語言 → 英語原文」解析，不整頁切換到 fallback。
- 第一與第二 Language Locale 即使尚無 active UI Locale 仍可作為使用者的內容語言偏好；一般介面只讀取 active UI Locale，draft 只供翻譯工作台預覽。
- UI Locale 不保存固定的語言 fallback；第二語言屬於使用者偏好，英語是固定最後保底。

### 6. Greenfield 重建

現有 D1 資料可丟棄，因此新模型不承擔 ADR 0003 的資料相容性：

- 刪除並重建 D1，將 migration 歷史重整為新的 baseline。
- 不建立舊 code migration manifest、runtime alias 或舊 Expression ID 對照。
- 不搬移舊 mappings、handbooks、votes、帳號或其他資料。
- 不以「先建立舊模型、再立即拆除」的增量 migration 延續舊 schema。
- 依 ADR 0003 與舊 Language Profile 模型撰寫的 specs／plans 只保留為歷史實作記錄，不再作為新 baseline 的施工依據。

新 baseline、完整 schema、API 契約與重建操作必須在後續 spec 與 plan 中定義；本 ADR 不直接規定實作步驟。

## 後果與取捨

正面後果：

- 同一語言與文字預設只有一個 Expression 節點，不再因 script／region profile 切斷 mapping。
- 地點可按證據細化到國家以下，且不要求預先建立全球完整地理分類。
- 語言、書寫系統、地域、讀音記法與 UI 翻譯各有單一責任。
- 地域與讀音資料可以單調追加，缺少資料不需要假的全域值或未知值。
- UI 翻譯直接建立在 Language Locale 與 mapping 圖上，同時有明確啟用門檻及逐詞句 fallback。

代價：

- 放棄 Glottolog identity 與分類後，LangMap 不再提供細緻、外部可互通的全球方言本體。
- ISO 639-3 沒有獨立代碼的方言會共用同一 `lang_code`，差異只能由 locale、讀音與 mapping 呈現。
- 使用者自訂地點段可能出現異拼、重複或同名；本 ADR 不引入地點 registry 解決它們。
- 未拆分同形詞會污染間接 mapping，且後期人工搬移成本隨 mappings 增長。
- 無讀音 scheme registry 容許代碼異拼；先以簡單資料形狀換取低建立成本。
- 60% 即啟用會產生混合語言介面；第二語言與英語逐詞句 fallback 是刻意採用的緩解方式。
- UI Locale 啟用後不自動降級，可能在覆蓋率低於門檻時仍然可選。
- Greenfield 重建會永久捨棄現有資料；這是已明確接受的破壞性決定。

## 考慮過但否決

- **延續 ADR 0003 的 Glottolog + BCP 47 雙軌模型**：無法解決 Expression 分裂、次級地點與比較邊界問題。
- **Macrolanguage 覆寫或自訂語言代碼**：會讓 `lang_code` 失去可預期的 ISO 639-3 語義。
- **固定地點層級、ISO 3166-2、GeoNames 或全域受控地點 registry**：不是所有國家共享同一行政深度，且現階段不需要承擔外部地理本體生命週期。
- **貢獻 Expression 時強制 locale**：會迫使缺乏地域證據的資料建立假值。
- **無地域或全語言通用的讀音**：會把缺少證據誤寫成 coverage claim。
- **獨立讀音系統 registry**：目前只需用短代碼區分記法，額外表與管理流程尚無必要。
- **永不拆分同形詞**：會讓 mapping 圖的語義誤連永久不可修正。
- **自動多義偵測或審查佇列**：早期誤報與維護成本高於手動拆分的收益。
- **UI Locale 與 Language Locale 共用一張表**：兩者的 scope、狀態與約束不同，會把翻譯生命週期誤當地域語義。
- **UI Locale 與 Language Locale 完全無關**：無法讓 UI 詞句覆蓋率自然驅動地域形式成為介面語言。
- **保留舊資料並逐筆遷移**：資料可丟棄，遷移 manifest、alias 與去重只會延續已否決模型的複雜度。

## 參考標準

- [ISO 639-3:2007](https://www.iso.org/standard/39534.html)
- [ISO 15924 Registration Authority](https://www.unicode.org/iso15924/)
- [ISO 3166 country codes](https://committee.iso.org/iso-3166-country-codes.html)
