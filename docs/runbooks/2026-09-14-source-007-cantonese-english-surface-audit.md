# Source 7 粵語—英語詞句表面修復紀錄

## 範圍

- source：`publication / com.apple.dictionary.yue-en.cp`（production `source_id = 7`）
- artifact：`/Volumes/DATA/langmap-structured-jsonl/Cantonese - English Colloquialisms.jsonl`
- artifact header：`entry_count = 2472`；輸入 CSV SHA-256 `0739e88ca3a0ae0249d503e283a20132a0a320a725ff5cc54119d78733b360f8`
- parser 修正：忽略等價列表的前導項目符號；只在 CJK 周邊可安全判定時展開括號異體；支援多個 CJK 可選括號的受限展開

## 本地品質閘

以 canonical staging import 後檢查 source-owned expression surfaces：

- 10,052 個 source claims
- `eng` 7,486；`yue` 2,566
- surface errors：0（100%）
- staging readings：2,486；staging edge-source rows：8,663
- parser 與 adapter 回歸測試：94 passed

## Production 發布

- natural-key delta：`scripts/db/state/backup/delta/007-cantonese-english-source-surface.split.sql`
- delta SHA-256：`b525856737feb932f9902ab1c4af955b7da14f71fc67a942de4b85ae1d64b30f`
- delta bytes：8,019,194；867 個受管 batch（100 rows 的 source diff 批次）
- plan / operation：`eae29457a646477ab74a29b1dd5a92f0`
- production bookmark：`00000263-00000000-000050e5-0eafd3d0329c834cc6e8f8ff4e795fe6`
- statistics refresh：已完成；references：明確 skip（data-only release）
- apply 曾有 1 次暫時性 data command failure；原 SQL 以 backend Wrangler 重試成功，之後由同一 plan resume，沒有重建或下載 production 全庫

## Production source-scoped 驗證

- claims：10,052；distinct expressions：10,052
- 語言：`eng` 7,486；`yue` 2,566
- edge-source rows：8,663
- source-owned readings：2,484（production 既有 reading unique key 與其他 source 共用時按 canonical schema 去重；mirror apply 後同樣為 2,484）
- readings scheme：`jyutping` 2,484
- 已知異常樣本 `Hello ,`、`Push []`、`Smoking []`、`Toilet [] / [] / []`、`A buddhist nun.` 均沒有 source 7 命中
- production managed inventory verify：通過

