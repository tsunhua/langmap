# Expression 邊界與詞句品質規格

## 狀態

已核准，第一階段已實作本地 surface parser、dictionary staging annotations、headword alternatives 與 mapping graph 的 annotation 讀取契約；canonical production migration 僅建立檔案，尚未 plan/apply。

## 問題

現有匯入流程把「可說出的詞句」、reading、定義／用法說明與來源殘留都當成同一個 text 值處理，因而出現：

- `Boa tarde (, /ˈbo.ɐ ˈtaɾ.dɨ/)` 的 reading 混進 expression
- `Hello!/i say!/hey!`、`你（們）好` 沒有拆成替代詞句
- `Hello ,`、尾端句號等解析殘留
- `Hello (only on the telephone)` 把使用限制存成 expression，而不是 mapping note
- `Hello! I say!` 在同一 expression 中跨越多個完整句子

## 定義

### Expression

單一語言中可實際說出或寫出的詞、短語或句子。Expression text 必須：

- 不包含 reading、definition、label、來源導航、解析殘留或說明括號
- 不跨越句末標點；句號、問號、感嘆號（含全形）後仍有文字時必須拆分
- 可保留句末 `?`、`!` 作為該 expression 的語義標點
- 頂層 `/` 替代形式拆成獨立 expression
- compact CJK optional form（例如 `你（們）好`）拆成 `你好`、`你們好`
- 全大寫縮寫（例如 `UFO`）保持原樣；其他拉丁 identity 沿用既有 sentence-case

### Reading

Reading 是 expression 的獨立資料。斜線 reading（如 `/ˈbo.ɐ ˈtaɾ.dɨ/`）或多個 reading 必須拆成多筆 reading，不能成為 expression 的文字。無法可靠判定 scheme 的 reading 進 quarantine。

### Mapping annotation

Mapping annotation 描述一條 mapping 在特定來源、端點或語境下的限制、語體、地區或解釋。它不是 expression，不參與 expression identity 或去重。`Hello (only on the telephone)` 的 expression 是 `Hello`，annotation 是 `only on the telephone`。

語法改寫提示也屬於 mapping annotation：詞典用 ⇒／→ 接在例句後時，只建立箭頭前的 expression；例如 She said, “I wish I had a car.”⇒She said she wished she had a car 的 annotation 為 rewrite: She said she wished she had a car。

## 正規化流程

1. Loader 保留 raw JSON／source field，不在輸入階段覆蓋原文。
2. `expression_surface` 在 adapter 前做保守 surface 分析：括號／方括號／reading slash 受保護；可靠的頂層 slash 與句末邊界才切分。
3. Adapter 為每個替代形式產生穩定 claim suffix；每個移出的 reading 寫入 `lexical_readings`，每個說明寫入 `lexical_annotations`。
4. malformed、未閉合括號、混雜 reading／說明或未知 reading scheme fail closed，寫入 `quarantine_items`，不得猜測或發布。
5. compiler 只消費沒有 normalization errors 的 occurrence／reading；annotation 先在 staging 保留原始值，匯入 canonical 時只寫入 edge 上的 bounded display payload。

## Canonical mapping annotation

mapping annotation 直接放在 `expression_edges.annotations_json`，不新增獨立關係表。它是 bounded JSON array；每個元素只保存可展示的 `text`、端點 `side`（`a|b|both`）、optional `source_id` 與 `source_marker`。canonical 不保存 `raw_text`、解析 metadata、author 或 timestamp；原始 annotation 只在本地 staging 的 `lexical_annotations` 供追溯與 quality gate 使用。寫入時去重、穩定排序並限制每 edge 20 筆，graph API 直接解析該欄位並保留同一上限。

## 驗收案例

| Input | Publishable expression(s) | Reading | Annotation |
| --- | --- | --- | --- |
| `Hello!/i say!/hey!` | `Hello!`, `i say!`, `hey!` | — | — |
| `Hello! I say!` | `Hello!`, `I say!` | — | — |
| `Boa tarde (, /ˈbo.ɐ ˈtaɾ.dɨ/)` | `Boa tarde` | `ˈbo.ɐ ˈtaɾ.dɨ` | — |
| `你（們）好` | `你好`, `你們好` | — | — |
| `Hello ,` | `Hello` | — | — |
| `Hello (only on the telephone)` | `Hello` | — | `only on the telephone` |
| `She said, “I wish I had a car.”⇒She said she wished she had a car` | `She said, “I wish I had a car.”` | — | `rewrite: She said she wished she had a car` |

## 非目標

- 本規格不授權 production D1 直接修復或全量下載；任何發布仍須依 dictionary publishing runbook 的 bookmark、plan/apply、source-scoped verify 流程。
- 不把任意括號都自動當成 annotation；無法判斷的輸入必須 quarantine。
- 不在前端以例外字串補資料品質；修復回到 exporter／adapter／staging gate。
