# Source 16 阿拉伯語—英語詞句表面修復紀錄

## 範圍

- source：`publication / com.apple.dictionary.ar-en.oup`（production `source_id = 16`）
- artifact：`/Volumes/DATA/langmap-structured-jsonl/Arabic - English.jsonl`
- entry count：`54,384`
- artifact SHA-256：`7c17e04e6d33a129c04ccfcf9c9c6c1f8ab282bde9a02600d88e13f837a346ac`
- 原 artifact 備份：`/Volumes/DATA/langmap-structured-jsonl/Arabic - English.jsonl.pre-source16-surface-20260914`

## 問題與規則修正

- 阿拉伯語／英語例句的直引號、彎引號、反向引號與方括號是排版標記，先拆對話 turn，再移除外層標記。
- 例句中的句號、問號、感嘆號與對話 dash 作為切分邊界；不把同一段對話殘留成帶前置標點的 expression。
- 只把真正的 reading shell（例如 `(/ipa/)`）轉成 reading；`(of them/you/…)`、`(campaign/case/operation)` 等詞義斜線不再誤判為 reading。
- 前置語法／使用標籤（例如 `(public) health service`）進入 mapping annotation；definition content 保留其原有前置括號。
- abbreviation（`a.m.`、`p.m.`）、hashtag（`#MeToo`）、contraction（`'ll`、`'d`）不再被判為前置標點錯誤。
- source adapter 對 4 個原先被誤判的 `unknown` example reading（`o'clock`、`you`、`case`）不再產生 reading；合法 IPA 仍保留。

## 本地品質閘

- raw artifact bounded sample：120 entries／400 values，`stats={}`，sample accuracy `100%`。
- canonical staging：`input_records=54,384`、`normalized_entries=54,384`、`clusters=344,637`。
- staging occurrences：`344,635`，`errors_json <> '[]' = 0`。
- staging readings：`76,919`，`errors_json <> '[]' = 0`；source readings scheme 為 `ipa`。
- staging annotations：`440`，annotation errors `0`。
- source mirror distinct expressions：`372,686`；source claims：`372,809`；surface revalidation errors `0`。
- source mirror source-owned readings：`101,796`；source edge claims：`373,431`。
- local delta replay：source-scoped additive SQL 的重播只在 release workspace 執行；完成後須記錄 foreign-key 與 expected-count 結果，不把大型 SQL 納入 repository。

## Delta

- SQL：release workspace 中產生的 `016-arabic-surface-20260914.split.sql`（不提交至 repository）
- manifest：`scripts/db/state/backup/delta/016-arabic-surface-20260914.manifest.json`
- delta SHA-256：`ba41360a6353cdbcb62b00a9df75e062b15f4a13f336b8c1d4d113f7d03944bf`
- delta bytes：`134,380,456`（additive natural-key rows；不再執行 source-wide DELETE）。
- expected counts：`expressions=372,686`、`expression_sources=372,809`、`expression_edges=373,431`、`expression_edge_sources=373,431`、`expression_locale_links=372,809`、`expression_readings=101,796`、`language_locales=2`。
- 生成選項：`--rows-per-insert 500 --edge-rows-per-insert 350 --remap-managed-handbook`；未匯出 production 全庫。
- 產物共 2,695 個受 64 KiB 上限約束的 managed batches；additive release 讓已完成的 source assertions 以 `INSERT OR IGNORE` 冪等補回，不重掃整個 expressions/edges 表。

SQL 由下列命令在發布工作區重建；發布前以 manifest 中的 SHA-256 驗證，不依賴 git checkout 中的資料副本：

```bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=scripts/dictionary python3 \
  scripts/db/export_dictionary_source_delta.py \
  --staging <source-16-mirror.sqlite> \
  --source-type publication \
  --source-name com.apple.dictionary.ar-en.oup \
  --locale-code arb-Arab \
  --locale-code eng-Latn-US \
  --output <release-workspace>/016-arabic-surface-20260914.split.sql \
  --manifest <release-workspace>/016-arabic-surface-20260914.manifest.json \
  --rows-per-insert 500 \
  --edge-rows-per-insert 350 \
  --remap-managed-handbook
```

131 MB 的 additive SQL 是一次性發布產物，不是可審查的程式碼；repository 只保留可重建所需的 manifest、命令與品質證據。先前 full-replace plan 先後在 D1 CPU/storage limit（code 7429）停止；第二次 operation 已完成 4 個 source-cleanup batches，之後改用本 additive artifact 完成恢復，必須以新 SHA 建立 managed plan。

## Production release

### 已完成（2026-09-15）

- production identity：`langmap-v2 / 75c7dea7-f453-4ada-8527-d5ff481b54f3`；schema preflight `44` objects／`45` migrations，所有 plan 均為 `--skip-reference-artifacts`。線上既有 UI reference 差異（managed UI edges `1387` vs bundle `1366`）未被此資料發布碰觸。
- 不把 134 MB SQL 提交到 repository。原始 additive artifact 的 SHA-256／bytes 仍為 `ba41360a6353cdbcb62b00a9df75e062b15f4a13f336b8c1d4d113f7d03944bf`／`134,380,456`；為避開 D1 import gateway／CPU timeout，僅在 ignored release workspace 以語句邊界切成 8–16 MiB 檔案，再由同一份 checksum-locked source rows 逐批受管發布。
- 成功的資料批次 operation：

  | artifact batch | operation | bookmark（前綴） |
  | --- | --- | --- |
  | `chunk-001` | `6afcd65cc0e84eada85abf0301cac055` | `000002a6-00000000-...` |
  | `part-002-003` | `7ff4b39c4dcf4f44b90a268aec889f11` | `000002a7-00000000-...` |
  | `part-004-005` | `eda758d59fe54dfdb6405b2bbf1ed914` | `000002a7-000003cf-...` |
  | `part-006-007` | `e061e5bf999b4c5b8d7867431b0f0277` | `000002a7-0000094f-...` |
  | `part-008-009` | `16af66f1fd5f4eb7a865653008cd439d` | `000002a7-00000ded-...` |
  | `part-010-011` | `4d139a86cfd54722af07cd8e7e264bd7` | `000002a7-000012b1-...` |
  | `part-012-013` | `5402eee713fe4a6693644c00e18e775a` | `000002a7-00001a66-...` |
  | `part-014-015` | `7daddd152321485f926d827b83593fcf` | `000002a7-00001dba-...` |
  | `edge-001` | `31c863a230f24ea78ac538abe38725b0` | `000002ac-00000000-...` |
  | `edge-002-003` | `f8c47c841d5d4fbe98831bb9ce24cd1f` | `000002ac-0000002c-...` |
  | `edge-004-005` | `a7ee0d4d54944d5fbf26509b27de1998` | `000002ac-00000080-...` |
  | `edge-006-source` | `65f57c00784f4384a764b90270e77bee` | `000002ae-00000000-...` |
  | `edge-007-source` | `4942775fdbb6461b91126b4e7de87e21` | `000002ae-0000002c-...` |

- 受管統計刷新與 verify operation：`f7b0a6aefa424e4e8e7c9a7618f5b20e`，bookmark `000002b0-00000000-...`，status `succeeded`／`verified=true`。
- source-scoped postflight：`source_id=16`、`expression_sources=372,809`、distinct source expressions `372,686`、`expression_edge_sources=373,431`。`expression_readings.source_id=16` 為 `84,697`；低於 staging `101,796` 是 canonical reading primary key 去重後與其他來源共享 reading identity 的結果，不是整庫缺失。locale link 以 expression identity 去重後覆蓋 `372,686` 個 source expressions。
- handbook remap：`expressions.source_id=16` 的 handbook rows 僅 `36` 筆；逐筆核對後 `35` 筆的最高 source16 English target 就是原 expression ID，`1` 筆沒有 source16 target，故 DELETE／UPDATE remap 是 no-op，沒有再執行會掃描大型 edge 表的 correlated SQL。以 `expression_sources` join 計算的 `572` 筆包含共享 expression，不屬於此 remap 條件。
- 期間的整檔 file-mode／remap 嘗試（`09ebc150e3a44ca29e23a50f20cdb141`、`3a90dd291b494d7992cd88458e530f78`、`488a1e4b55b24502a576b1d9d2c430e4`、`aff144f560c248e3816ef56febd76cfe`）均在 Cloudflare code `7009` timeout 後回滾；後續均改用更小的受管檔案，未留下半批寫入。
