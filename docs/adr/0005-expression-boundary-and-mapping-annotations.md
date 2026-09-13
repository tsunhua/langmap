# Expression 邊界與 mapping 註釋分離

> 狀態：已接受。

詞典匯入中的 `Expression` 只代表使用者實際可以說出或寫出的單一語言內容；讀音、定義、語體／用法說明、來源欄位與解析殘留的首尾標點不屬於 expression text。替代形式應拆成多個 expression，讀音應拆成獨立的 reading。來源中的關係限制或使用說明（例如 `only on the telephone`）則屬於 mapping annotation，按來源與關係保存，不得藉由把說明拼進 expression 來表達。

選擇這個邊界，是為了讓 expression identity、去重、locale／reading 驗證與 mapping 顯示各自穩定。代價是 parser 必須保留原始欄位與 provenance，並在 staging 中明確判斷「替代形式」與「解釋說明」；無法判定時要 quarantine，而不是猜測或直接發布。

## 判定例

- `Boa tarde (, /ˈbo.ɐ ˈtaɾ.dɨ/)`：expression 為 `Boa tarde`，IPA 為 reading。
- `goodafternoonのあいさつ`：若來源沒有分離欄位，視為解析錯誤並 quarantine；不得把混合說明直接當 expression。
- `你（們）好`：拆為 `你好` 與 `你們好`。
- `Hello ,`：清除來源造成的首尾空白／孤立標點；expression 為 `Hello`。
- `Hello (only on the telephone)`：expression 為 `Hello`；`only on the telephone` 為 mapping annotation。

## 後果

語法改寫提示也遵循相同邊界：She said, “I wish I had a car.”⇒She said she wished she had a car 的 expression 只保留箭頭前的例句；箭頭後的文字保存為 mapping annotation。

- canonicalizer 不得以「把所有文字 trim 後直接入庫」作為完整驗證。
- quality gate 必須能阻擋 reading 混入 expression、替代形式未拆、說明文字未分離及錯誤末尾標點。
- mapping annotation 是關係層資料；staging 保留原始值，canonical 只在 `expression_edges.annotations_json` 保存可展示的 bounded payload，不能偷偷寫進 expression。
- 這項決策不要求所有語言採用同一套 script 規則；語言／locale profile 應提供可驗證的來源特定規則，對不確定的 code-mix fail closed。
