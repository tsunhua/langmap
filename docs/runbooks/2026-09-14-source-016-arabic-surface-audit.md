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
- local delta replay：source-scoped `--replace --reconcile-shared` SQL 的重播只在 release workspace 執行；完成後須記錄 foreign-key 與 expected-count 結果，不把大型 SQL 納入 repository。

## Delta

- SQL：release workspace 中產生的 `016-arabic-surface-20260914.split.sql`（不提交至 repository）
- manifest：`scripts/db/state/backup/delta/016-arabic-surface-20260914.manifest.json`
- delta SHA-256：`dab9c714d5647a42755206ede8dcfd02d35f1b1912aef843e7b3341ab9a4c6d2`
- delta bytes：`132,830,089`（source replace 先移除 source 16 assertion，再寫入自然鍵 rows）。
- expected counts：`expressions=372,686`、`expression_sources=372,809`、`expression_edges=373,431`、`expression_edge_sources=373,431`、`expression_locale_links=372,809`、`expression_readings=101,796`、`language_locales=2`。
- 生成選項：`--replace --reconcile-shared --remap-managed-handbook`；未匯出 production 全庫。
- 高成本 reconcile DELETE／UPDATE 與首個 expression insert 以 `-- langmap:batch` 隔離，避免 D1 CPU slice 把多個掃描操作合併到同一個 remote command。

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
  --rows-per-insert 1000 \
  --replace --reconcile-shared --remap-managed-handbook
```

127 MB 的 full-replace SQL 是一次性發布產物，不是可審查的程式碼；repository 只保留可重建所需的 manifest、命令與品質證據。先前未分隔的版本在 production apply 時觸發 D1 CPU limit 並被 reset，未完成任何 data batch；新版本已增加 batch marker，須以新 SHA 建立新的 managed plan。

## Production release

### 待執行

- 以 `manage.sh production plan --approved-data-migration ... --refresh-language-statistics` 建立受管 plan，再依 plan apply；apply 前建立 bookmark。
- apply 後只做 source-scoped postflight：source claims／edges／readings、`arb-Arab`／`eng-Latn-US` links、IPA scheme、surface error 定點抽查，以及 `language_statistics` refresh。
- plan／operation、bookmark、postflight counts 由發布後補記；若 production schema 不含 `annotations_json`，需按 managed tool 的相容分支記錄 annotation update skip。
