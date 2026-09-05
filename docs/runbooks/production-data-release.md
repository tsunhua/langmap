# Production Data Release Runbook

## 前置條件

- reviewed Git commit、clean migration lock、production identity 與 approved baseline。
- local tests、local rebuild/verify、bundle checksum 均通過。
- operator 已審核 inventory 與 plan；本 runbook 不自動 deploy。
- 固定使用 repository 內的 Wrangler：
  `LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler`，不要以 `npx` 臨時解析版本。

## 詞典 mirror 與差分基線

incremental importer 在 quality gate 通過後、第一次修改 mirror 前，會用 SQLite backup API
建立一致的 before snapshot。預設放在 state 檔旁的 `snapshots/`；正式發布應明確指定持久目錄：

```bash
python3 scripts/dictionary/incremental_import.py \
  --input-dir /Volumes/DATA/langmap-structured-jsonl \
  --d1-database scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --state scripts/db/state/backup/import-state/<release>.json \
  --staging-root /tmp/langmap-dictionary-staging \
  --snapshot-root scripts/db/state/backup/snapshots \
  --stop-on-error
```

state 的成功紀錄包含 `before_snapshot_path`、`before_snapshot_sha256` 與
`snapshot_run_key`。產生 delta 時必須使用該 snapshot，不自行反推基線：

```bash
python3 scripts/db/export_dictionary_delta.py \
  --before <state.before_snapshot_path> \
  --after scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --output scripts/db/state/backup/delta/<NNN>-<topic>.sql
```

delta exporter 以 SQLite `ATTACH`／primary-key anti-join 串流輸出；記憶體只保留一個
`--rows-per-insert` batch。

## Plan / Apply / Verify

```bash
LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler \
  ./scripts/db/manage.sh production inventory
LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler \
  ./scripts/db/manage.sh production plan \
  --approved-data-migration scripts/db/state/backup/delta/<NNN>-<topic>.sql \
  --refresh-language-statistics
LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler \
  ./scripts/db/manage.sh production apply \
  --plan scripts/db/state/production/plans/<operation-id>.json \
  --database-name <完整資料庫名稱> \
  --confirm-production <完整資料庫名稱>
```

apply 先取得並 journal bookmark，再按固定順序執行；成功訊息只表示資料變更已驗證，
仍須另行執行 deploy 流程。指定 `--refresh-language-statistics` 後，統計刷新會在同一
operation 的 data stage 後執行。純 approved-data release 且 plan 確認 reference diff 無變更時，
`reference_artifacts.action` 為 `skip`，不重播 language registry／system UI。

## 失敗處理

讀取 `scripts/db/state/production/operations.jsonl` 與 plan report。bookmark 取得失敗、
identity mismatch、plan commit 改變、ownership 不明或 verify 失敗時停止。若資料、migration
或 reference stage 已 journal 完成，修復暫時性問題後以**同一份 plan**重跑 apply；流程會沿用
原 bookmark 並跳過已完成 stage。不得另產 plan 或手動重播已完成 delta。

## 禁止事項

- 不繞過 plan、confirmation 或 bookmark gate。
- 不在 apply 腳本中呼叫 deploy。
- 不在沒有 postflight verify 的情況下宣告 release 成功。
