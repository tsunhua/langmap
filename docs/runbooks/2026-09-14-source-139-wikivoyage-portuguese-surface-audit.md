> Historical record: this runbook predates the PostgreSQL/canonical CSV cutover and is not an executable current procedure.

# Source 139 英文 Wikivoyage 葡萄牙語詞句邊界修復紀錄

## 範圍

- source：`url / https://en.wikivoyage.org/wiki/Portuguese_phrasebook`（production `source_id = 139`）
- pinned page：`pageid = 28280`，revision `5295166`
- 原始頁面：`/Volumes/DATA/langmap-wikivoyage/pages/28280-5295166.wikitext`
- 原始頁面 SHA-256：`15689b9e5a4b21f9c4946a5e41bf20a39ceb2516eec1f1ab968b049efd22925c`

本輪針對 source 139 的高頻問題重建單頁 artifact，沒有下載或匯出 production 全庫。問題包括葡萄牙語性別標記混入詞句、`/` 並列值未拆分、句號／感嘆號後仍黏著下一句、句尾 IPA 缺少一側斜線，以及 `...`／破折號等版面標記混入 expression。

## 修復規則

- `(masc.)`、`(fem.)` 只保留在語法意義，不進 expression；同列以空白斜線分隔的男女形式各自成為詞句
- `(Só) falo inglês` 展開為 `Falo inglês` 與 `Só falo inglês`
- 葡萄牙語列的頂層 `/` 變體及 `Pára! Ladrão!` 這類句子邊界拆成獨立 expression
- IPA `/.../` 或缺一側的 IPA 尾段放入 `ipa` reading，不保留在 headword；尾端說明仍由 mapping annotation 處理
- 移除 leading `...`、對話破折號及句尾 layout period；保留詞句內有語義的 `?`／`!`
- `expression_surface` 將 leading `(fresh)`、`(getting ...)` 等說明視為 mapping annotation，不建立污染節點

## 本地驗證

- 更新 artifact：`/Volumes/DATA/langmap-wikivoyage-jsonl/28280.jsonl`
- 舊 artifact 備份：`/Volumes/DATA/langmap-wikivoyage-jsonl/28280.jsonl.pre-source139-surface-20260914`
- 更新後 entry count：`400`（source page header 與 JSONL 行數一致）
- 更新後 artifact SHA-256：`4475d4456884e2a78b58aa91c29531ff87bdf4261dfd82a862bdb765c1c5e2a8`
- source-scoped surface audit（`sample_entries=1000`，實際全量 400）：`stats = {}`，沒有 surface error、embedded reading、leading punctuation、slash alternative 或 terminal annotation
- local staging release：`release-796c095db3295e3e53c38f2d52bda921`
- local quality gate：`input_records=400`、`publishable_occurrences=800`、`quarantined=0`
- source-only SQLite delta fixture：`expression_sources=802`、`expression_edge_sources=402`、`expression_readings=737`、`por expressions=400`、`foreign_key_check=0`
- 相關 parser／surface／adapter／local-import tests：`93 passed`

## Production delta

- natural-key delta：`scripts/db/state/backup/delta/139-wikivoyage-portuguese-surface-20260914.split.sql`
- delta SHA-256：`385509d50bba988c05358c05c6bbfda8cfe4126875bbd6bf29c669c39736fc5a`
- manifest：`scripts/db/state/backup/delta/139-wikivoyage-portuguese-surface-20260914.manifest.json`
- 主 delta expected source-scoped counts：expressions `777`、expression claims `798`、edges `400`、edge claims `400`、locale links `398`、readings `725`
- 產生選項：`--replace --reconcile-shared --remap-managed-handbook`；apply 後同一 operation 刷新 `language_statistics`

## Production postflight

第一個 source-only apply 使用上方主 delta：

- operation：`27c7cce1440c43369481cd9bdfe2c0a1`
- bookmark：`00000279-00000000-000050e5-29b127d5228067767b36de44c86af00f`

bounded postflight 發現一條葡萄牙語 expression 仍保留空白斜線：`Compreendo. / percebo. / entendo`。這不是 production 大量資料問題，而是 IPA 判定在 lexical ` / ` 前過度配對；已加入 whitespace guard、重匯 pinned page，並由 follow-up source delta 修正。

follow-up delta：

- `scripts/db/state/backup/delta/139-wikivoyage-portuguese-surface-followup-20260914.split.sql`
- SHA-256：`7488555c82a0d34850371a34db98cc8d5212be2be2e33bb360adbb5a80ca71e3`
- follow-up expected source-scoped counts：expressions `779`、expression claims `802`、edges `402`、edge claims `402`、locale links `400`、readings `737`
- operation：`8bcc9adb374b4a78976e6aeb6ef39674`
- bookmark：`0000027b-00000000-000050e5-2f28455909b4a0cabb1c1df86d7ba9d6`

最終 source-scoped postflight：claims `eng=402 / por=400`、edge claims `402`、reading claims `737`；por locale links 的 canonical unique rows 為 `394`（400 source claims 中含 6 組重複 expression identity）。leading ellipsis、禁止 leading punctuation、gender note、slash surface 均為 `0`。`Compreendo`、`Percebo`、`Entendo` 已各自建立 source marker `basics/43`、`basics/44`、`basics/45` 及 mapping edge；三筆 annotations 均為 `[]`。`language_statistics` 已在 follow-up operation 內刷新，por 為 `394 expressions / 1 locale`。

apply 只使用兩個 source-scoped delta，沒有拉取 production 全庫。
