# LangMap 術語表

LangMap 是以詞句與直接語義關係為核心的多語對照平台。本檔案只定義目前資料模型仍使用的專案術語；表結構以 `backend/schema.sql` 為準。

## 身份與 locale

**語言（Language）**：ISO 639-3 語言 registry 的一列。公開 API 使用 `code`，資料庫內部關聯使用整數 `languages.id`。`name_en` 是英文回退名稱；`name_expression_id` 指向名稱圖的 canonical English expression。

**語言 locale（Language Locale）**：語言在特定書寫系統、正字法、地區與可選地點路徑下的 profile。代碼格式為 `{lang}-{script}(_{orthography})?-{region}(_{place_segment})*`，例如 `nan-Hant-CN_Chaozhou`。`language_locales.id` 是所有 locale 關聯的整數鍵；locale 的自稱存於 `name`。

**介面 locale（UI Locale）**：某一 `language_locale` 被啟用為介面翻譯的狀態，保存在 `ui_locales`。使用者可選 primary 與 secondary UI locale；缺少譯文時依序回退另一個 UI locale 與英文原文。

**名稱圖（Localized Name Graph）**：語言、locale、script 與 region 的名稱一律是 ordinary expression。registry 列只指向 canonical English expression；譯名必須與它有 direct `expression_edge`，且目標 expression 具有請求完整 locale 的 `expression_locale_link`。這避免在 registry 複製逐語系名稱欄位。

## 詞句與關係

**詞句（Expression）**：單一語言中的詞、短語或句子。`expressions.id` 是整數；同一 `language_id + text + homograph_index` 唯一。詞句可有零至多個 locale link、讀音及直接語義 edge。

**同形拆分（Homograph Split）**：同一文字需要分離不同語義時，建立較大的 `homograph_index` 並以 `expression_splits` 記錄可追溯的 edge 搬移。系統不依文字自動推斷詞義。

**映射／語義 edge（Expression Edge）**：兩個 expression 的直接語義關係。端點以遞增整數 ID 儲存，避免同一對詞句重複；`relation_mask` 表示關係種類，`score` 由 `edge_votes` 聚合。詞句頁的 mapping graph 是以某個 expression 為中心的關係圖，不是獨立的 mapping 實體。

**詞形 edge（Expression Form Edge）**：變化形指向辭書形的有向關係，與語義 edge 分開。`expression_form_edge_features` 掛載形態特徵；特徵與維度名稱也以 expression 做國際化。

**讀音（Expression Reading）**：某 expression 在一個 language locale 下，使用一個 scheme 記錄的文字讀音。它的複合主鍵為 expression、locale、scheme、value。

## 社群內容

**手冊（Handbook）**：使用者建立的學習手冊，由有序的 section 與 expression item 組成；手冊可公開或私人，並可由 `handbook_votes` 評分。

**來源（Source）**：可選的 provenance 列。expression 與 reading 只保留 `source_id` 整數引用；不為每一筆輸入複製來源文字。

## 資料生命週期

**canonical schema**：`backend/schema.sql` 描述乾淨重建時的資料庫。變更 schema 時，必須新增順序 migration、同步 schema 與 migration lock。

**language reference registry**：`scripts/language-reference/` 的固定輸入與 generator 產生的 seed。它建立 ISO registry、reference locale，以及名稱圖的 canonical expression、翻譯 edge 與 locale link。

**v2 canonical import**：`scripts/db/import_v2_canonical.py` 從匯出的舊 v2 SQLite 產生可重跑 SQL，將適用資料寫入現行整數 schema。local rebuild 會清除結果，因此匯入必須保持可重跑。
