> Historical record: this runbook predates the PostgreSQL/canonical CSV cutover and is not an executable current procedure.

# Source 146 英文 Wikivoyage 粵語 reading 修復紀錄

## 範圍

- source：`url / https://en.wikivoyage.org/wiki/Cantonese_phrasebook`（production `source_id = 146`）
- pinned page：`pageid = 5837`，revision `5229367`
- 問題：`过咗_____ Gwojó _____`、`边度有好多_____呀？ Bīndouh yáuh hóudō _____ a?` 的粵語 Jyutping 被錯放在 headword；同 source 仍有 inline reading、slash reading 及句尾說明混入 headword 的同類資料

## 修復與驗證

- parser 已將兩筆資料輸出為獨立 headword 與 `pronunciations`；placeholder 仍保留在 reading 中以維持位置對應
- 同一規則也將 `咖啡 Bī / gafē` 拆為兩個 readings、`(新鮮) 菜 Choi` 保留詞句並拆出 `sānsīn`／`choi`，以及把句尾說明移到 mapping edge annotation
- 以 pinned 原文重新產出單頁 artifact，entry count 為 `692`（一筆只剩標記的 malformed surface 被移除）
- artifact：`/Volumes/DATA/langmap-wikivoyage-jsonl/5837.jsonl`
- 更新後 SHA-256：`4c85f6fff6d57ed2909251748031c379665f7999cfba5bab73cfc34c3400dd30`
- 原 artifact 備份：`/Volumes/DATA/langmap-wikivoyage-jsonl/5837.jsonl.pre-source146-surface-20260914`
- 本地 source-only staging：`875` expressions、`659` edge claims、`811` readings；100 筆均勻抽樣無阻塞性詞句／reading 問題
- parser、adapter 及 local import 測試共 `87 passed`

## Production source-scoped 驗證

兩筆原始問題已由既有受管 delta `091-wikivoyage-cantonese-inline-readings-20260913` 修復；本次 source 146 follow-up delta 另外重建該 source 的 assertions，並保留 shared rows，不拉取 production 全庫：

- expression `6679603`：`边度有好多_____呀？`；reading `jyutping: Bīndouh yáuh hóudō _____ a?`；locale `yue-Hant-HK`
- expression `6679604`：`过咗_____`；reading `jyutping: gwojó _____`；locale `yue-Hant-HK`
- 兩筆均保留原 source marker `oldid:5229367#directions/342`、`oldid:5229367#directions/360`

本次 follow-up delta：

- `scripts/db/state/backup/delta/146-wikivoyage-cantonese-reading-surface-20260914.split.sql`
- SHA-256：`52e44b04f96d3c3c7e629f36c0ef25728a0acea7d1f78239a8dba5586b3e1058`
- 採 `--replace --reconcile-shared`，並在 apply 後刷新 `language_statistics`

## URL 相容性修復

`--replace` 會為只被該 source 擁有、且沒有其他引用的 expression 重新配置自增 ID。這次 postflight 發現兩個使用者既有 URL（`6679603`、`6679604`）屬於這種情況，因此沒有保留新建的臨時 ID。已用受管 compatibility delta 將兩個 canonical expression、reading、locale、mapping edge 與 source marker 恢復到原 ID；本地 SQLite fixture 驗證可重跑且不產生重複：

- delta：`scripts/db/state/backup/delta/146-wikivoyage-cantonese-url-compat-20260914.split.sql`
- SHA-256：`7b36a4ef05b6414c1f84133a55a5566fc2515893d231f26914ea71c49594410f`
- main operation：`4a06d4ccb4ad450491aa62d0ac1ecfcc`，bookmark `0000026d-00000000-000050e5-98d93080efd7d0ffc5baa188b45b715b`
- compatibility operation：`341c1b358654416189325c248fbd1337`，bookmark `00000272-00000000-000050e5-c3ea5f25d45b578598ef9bd4db6b643a`
- postflight：兩個 ID 均為 `yue`、locale `yue-Hant-HK`，各有一個 `jyutping` reading 與 source marker；mapping edge 仍分別連到原英文 expression，臨時 ID `8176886`、`8176887` 已移除
