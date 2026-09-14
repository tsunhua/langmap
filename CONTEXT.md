# LangMap 術語表

LangMap 是以詞句與直接對照關係為核心的多語對照平台。本檔案只定義目前資料模型仍使用的專案術語；表結構以 `backend/schema.sql` 為準。

## 身份與 locale

**語言（Language）**：ISO 639-3 語言 registry 的一列。公開 API 使用 `code`，資料庫內部關聯使用整數 `languages.id`。`name_en` 是英文回退名稱；`name_expression_id` 指向名稱圖的 canonical English expression。

**語言 locale（Language Locale）**：語言在特定書寫系統、正字法、地區與可選地點路徑下的 profile。代碼格式為 `{lang}-{script}(_{orthography})?-{region}(_{place_segment})*`，例如 `nan-Hant-CN_Chaozhou`。`language_locales.id` 是所有 locale 關聯的整數鍵；locale 的自稱存於 `name`。

**介面 locale（UI Locale）**：某一 `language_locale` 被啟用為介面翻譯的狀態，保存在 `ui_locales`。使用者可選 primary 與 secondary UI locale；缺少譯文時依序回退另一個 UI locale 與英文原文。

**名稱圖（Localized Name Graph）**：語言、locale、script 與 region 的名稱一律是 ordinary expression。registry 列只指向 canonical English expression；譯名必須與它有 direct `expression_edge`，且目標 expression 具有請求完整 locale 的 `expression_locale_link`。這避免在 registry 複製逐語系名稱欄位。

## 詞句與關係

**詞句（Expression）**：單一語言中可由使用者實際說出或寫出的詞、短語或句子。Expression text 只保存語言內容，不保存讀音、定義、語體／用法說明、來源導航文字、欄位標籤或解析殘留的首尾標點；內部具有語義的標點仍可保留。替代形式（例如 `你（們）好` 中的兩個形式）必須拆成各自的 expression，不把替代括號留在文字中。`expressions.id` 是整數；同一 `language_id + text + homograph_index` 唯一。詞句可有零至多個 locale link、讀音及直接 mapping edge；詞句本身不分主詞頭與例句層級，句子也是獨立詞句。詞典匯入時，同一 `(language_id, text)` 的條目一律合併為 `homograph_index = 1` 的單一列，不再依來源詞典增量配號。原始欄位與被移出的說明必須留在 staging／provenance，不能以清理後文字取代可追溯性。

**同形拆分（Homograph Split）**：管理員以 `expression_splits` 記錄可追溯的 edge 搬移，將同一文字分離成較大的 `homograph_index`。這是人為校正動作；系統（含詞典匯入）不依文字自動推斷或拆分詞義。

**來源標記（Source Marker）**：來源詞典自身對同一詞形的 homograph 編號（如 NOAD 的 `cod 1/2/3`、繁中英的 `1/2/3`）。匯入時以 `(source_id, source_marker)` 保留：`expression_sources` 記錄合併後詞句的來源與編號，`expression_edge_sources` 記錄每條 edge 的來源與編號。**同一來源詞典內不同的編號代表不同的含義；跨來源詞典的編號不互相宣稱相同**，亦不作為全域語義身分。

**映射（Expression Edge）**：兩個 expression 之間的直接對照關係；兩端可以是詞、短語或句子。詞典例句的原句與譯句各自建立為獨立 expression，只在兩者之間建立普通 mapping，不建立主詞頭與例句的關聯。端點以遞增整數 ID 儲存，避免同一對詞句重複；`relation_mask` 是內部相容欄位，不應被解讀為額外的產品內容層級，`score` 由 `edge_votes` 聚合。一條 edge 同一對端點可匯聚多個來源標記（以 `expression_edge_sources` 記錄）；來源標記只掛在 edge 與 expression 上，不建立 sense 實體。詞句頁的 mapping graph 是以某個 expression 為中心的關係圖，不是獨立的 mapping 實體。

**映射註釋（Mapping Annotation）**：只描述一條 mapping 在某個來源、某一端或某個語境下的限制、用法、語體、地區或解釋的文字，例如 `Hello (only on the telephone)` 中的 `only on the telephone`。它不是 expression，不參與 expression identity 或文字去重；同一 mapping 可有多筆、不同來源的註釋。staging／provenance 保留原文，canonical `expression_edges.annotations_json` 只保留可展示的文字、端點與來源標記。若括號內容只是替代形式，應依 Expression 規則拆成多個 expression，而不是建立註釋。

**詞形 edge（Expression Form Edge）**：變化形指向辭書形的有向關係，與 mapping edge 分開。`expression_form_edge_features` 掛載形態特徵；特徵與維度名稱也以 expression 做國際化。

**讀音（Expression Reading）**：某 expression 在一個 language locale 下，使用一個 scheme 記錄的文字讀音。讀音永遠不嵌入 expression text；同一來源標示的多個讀音是多筆 reading，不是含斜線的單一文字。它的複合主鍵為 expression、locale、scheme、value。

## 社群內容

**手冊（Handbook）**：使用者建立的學習手冊，由有序的 section 與 expression item 組成；手冊可公開或私人，並可由 `handbook_votes` 評分。

**來源（Source）**：可選的 provenance 列。expression 與 reading 只保留 `source_id` 整數引用；不為每一筆輸入複製來源文字。

## 生成式翻譯

**翻譯請求（Translation Request）**：登入使用者為取得目標 language locale 譯文而送出的暫態輸入，包含來源詞句、自動偵測或由使用者搜尋選定的來源語言，以及指定的目標 language locale。它不是詞句貢獻，也不因此建立 expression。
_避免使用_：翻譯詞句、翻譯貢獻

**翻譯結果（Translation Result）**：系統針對一筆翻譯請求生成的暫態譯文，可附帶 LangMap 檢索證據；沒有證據時須標明僅由模型生成。它不是 canonical expression 或 mapping；只有使用者明確提交後，才可另行進入既有社群貢獻流程。
_避免使用_：正式譯文、AI mapping

**檢索證據（Retrieval Evidence）**：從 LangMap canonical expression graph 讀取、用來輔助生成翻譯結果的直接對照，或只經一個核准中介語言得到的兩跳對照資料。檢索證據不因被模型採用而建立新 expression、mapping 或來源。
_避免使用_：AI 來源、生成式 mapping

**核准中介語言（Approved Pivot Language）**：英語（`eng`）、普通話（`cmn`）、日語（`jpn`）、西班牙語（`spa`）、法語（`fra`）、德語（`deu`）、葡萄牙語（`por`）、韓語（`kor`）、俄語（`rus`）或現代標準阿拉伯語（`arb`）。只有這十種語言可在來源詞句與目標 language locale 之間作為兩跳檢索的中介；此限制不適用於來源語言或目標 language locale。
_避免使用_：高資源語言、橋接語言

**AI 輔助貢獻（AI-assisted Contribution）**：使用者從翻譯結果發起、經人工檢查與明確確認後送入既有社群貢獻流程的內容。確認畫面須說明譯文由 AI 輔助產生；提交後仍視為使用者貢獻，不永久保存 AI 輔助標示，也不得冒充詞典或其他權威來源。
_避免使用_：AI mapping、自動貢獻

## 資料生命週期

**canonical schema**：`backend/schema.sql` 描述乾淨重建時的資料庫。變更 schema 時，必須新增順序 migration、同步 schema 與 migration lock。

**language reference registry**：`scripts/language-reference/` 的固定輸入與 generator 產生的 seed。它建立 ISO registry、reference locale，以及名稱圖的 canonical expression、翻譯 edge 與 locale link。

**v2 canonical import**：`scripts/db/import_v2_canonical.py` 從匯出的舊 v2 SQLite 產生可重跑 SQL，將適用資料寫入現行整數 schema。local rebuild 會清除結果，因此匯入必須保持可重跑。
