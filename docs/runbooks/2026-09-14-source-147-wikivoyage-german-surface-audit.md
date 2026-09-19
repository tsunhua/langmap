> Historical record: this runbook predates the PostgreSQL/canonical CSV cutover and is not an executable current procedure.

# Source 147 英文 Wikivoyage 德語詞句邊界修復紀錄

## 範圍

- source：`url / https://en.wikivoyage.org/wiki/German_phrasebook`（production `source_id = 147`）
- pinned page：`pageid = 12641`，revision `5316784`
- 原始 wikitext SHA-256：`072eb7167fa5c0a32490246f635cce7b75e46ee6ca5470cbaaa9763ad96f54dd`
- 問題：反向德語／英文列方向判斷錯誤、德語詞句夾帶發音與說明括號、可選形式未拆分、reading 斜線未拆分，以及時間列的 `<nowiki>:</nowiki>` 被誤當雙語分隔符。

## 本地驗證

- parser 以 pinned wikitext 重匯出 `792` 筆，diagnostics 為空。
- artifact：`/Volumes/DATA/langmap-wikivoyage-jsonl/12641.jsonl`
- artifact SHA-256：`0f6b35e23873c7ede18a6e6c7b41e871f6acfc33179efe8f01737ef4eca13c38`
- 全量 surface audit（792/792，非 production 抽樣）`stats={}`。
- staging quality gate：`quarantined=0`、`publishable_occurrences=1585`。
- source-only D1：`deu expressions=792`、`eng expressions=793`、`edge claims=793`、`readings=923`、`deu-Latn-DE links=792`、reading slash=0、德語 surface punctuation／bracket=0、`foreign_key_check=0`。
- 本地 fixture replay：delta 可完整回放，`foreign_key_check=0`；`Flugzeug ↔ Airplane`、`Stimmt so! ↔ Keep the change`、`Drei ↔ 3` 等定點條目方向正確。

## 變更規則

- 反向 `German : English` 列以德語詞彙提示與 compound 形態辨識，不再把英文說明當德語 headword。
- German target 的發音括號、`[optional]`／`(optional)` 形式與句內 slash alternatives 分離；reading slash 轉為獨立 reading，不建立額外詞句。
- `lit. ...`、`sounds ...`、`rhymes ...`、`Note:`、`better:` 等說明不進 expression surface；時間 `01:00` 保留為英文詞句內容。
- 純發音 layout row（例如 `...Bars?: (''bahrss?'')`）直接丟棄，不產生 quarantine。

## Delta

- SQL：`scripts/db/state/backup/delta/147-wikivoyage-german-surface-20260914.split.sql`
- manifest：`scripts/db/state/backup/delta/147-wikivoyage-german-surface-20260914.manifest.json`
- delta SHA-256：`8f1f53f4143b5c5eb8c709065adcdaf353fb0bdde52ea94a85468fffd0a8e21c`
- `production.py` 的 managed split 上限已收緊至 64 KiB；本次 delta 分成 23 個 remote data batches，避開 D1 API `SQLITE_TOOBIG: statement too long`。
- expected counts：`expressions=1182`、`expression_sources=1585`、`expression_edges=789`、`expression_edge_sources=793`、`expression_locale_links=792`、`expression_readings=923`、`language_locales=1`。
- 使用 `--replace --reconcile-shared --remap-managed-handbook`；未導出 production 全庫。

## Production release

### 已完成（2026-09-14）

- plan/apply operation：`6c1bc69554ea46ea999708ecda93f63c`
- bookmark：`00000282-00000000-000050e5-3a78c518b9eb107da2236ad1349b6085`
- data／statistics／references／verify 均成功；reference artifacts 依 data-only plan 跳過。
- source-scoped postflight：claims `deu=792`、`eng=793`；edge claims `793`；`deu-Latn-DE` locale links `792`；source readings `922`。staging 的 923 筆中，`Can you make it "light", please?` → `butter` 與 source 139 已共享 production 唯一 reading，因此 `INSERT OR IGNORE` 保留既有 row，沒有重複建立。
- reading slash、德語 target 的 `/[]()` 與 leading punctuation 均為 `0`；定點 mapping `Flugzeug ↔ Airplane`、`Stimmt so! ↔ Keep the change`、`Drei ↔ 3` 正確；`language_statistics` 的 `deu`／`eng` 已刷新。
- 第一次 operation `8f99c3c176e44ee882bbd941554cf949` 因 512 KiB remote command 觸發 `SQLITE_TOOBIG`，未留下 source-scoped 部分寫入；改用 64 KiB batches 後成功。
