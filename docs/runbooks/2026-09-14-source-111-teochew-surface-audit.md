# Source 111 潮州詞典表面修復紀錄

## 範圍

- source：`publication / org.hokkien-writing.teochew`（production `source_id = 111`）
- artifact：`/Volumes/DATA/langmap-teochew-import-20260906/jsonl/org.hokkien-writing.teochew.jsonl`
- artifact header：`entry_count = 22`；輸入 CSV SHA-256 `a08848740c950eaf3f92dff367ff9874fa07019cad73d348b06d3da76bb75840`
- 修正：CJK 可選括號形式不再被當作前導標點 quarantine；`(心胸)寬廣`、`(心胸)狹隘` 分別展開為兩個可用詞句

## 本地品質閘

- source claims：60 → 62
- 語言：`cmn` 22；`nan` 40
- edge claims：44
- readings：0（來源沒有 reading）
- surface errors：0/62（100%）
- nan-Latn 詞句同步採用首字母大寫；CJK 表面保留原字形

## Production 發布

- natural-key delta：`scripts/db/state/backup/delta/111-teochew-optional-surface.split.sql`
- delta SHA-256：`0bc869164f2730c49de5b402e9df29fc9aca26ed8b9349b553d96d509fa578d8`
- delta bytes：30,800；14 個受管 batch
- plan / operation：`33188a3211a24e47aea9b15a36b50107`
- production bookmark：`00000268-00000000-000050e5-75ebee88ccd1da51eb8b88e5bf7d9741`
- statistics refresh：已完成；references：明確 skip（data-only release）
- managed apply 與 inventory verify：通過

## Production source-scoped 驗證

- claims：62；distinct expressions：62
- 語言：`cmn` 22；`nan` 40
- edge-source rows：44；readings：0
- 舊表面 `(心胸)寬廣`、`(心胸)狹隘` 均已移除
- 新表面已存在：`寬廣`、`心胸寬廣`、`狹隘`、`心胸狹隘`

