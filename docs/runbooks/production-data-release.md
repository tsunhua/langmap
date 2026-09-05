# Production Data Release Runbook

## 前置條件

- reviewed Git commit、clean migration lock、production identity 與 approved baseline。
- local tests、local rebuild/verify、bundle checksum 均通過。
- operator 已審核 inventory 與 plan；本 runbook 不自動 deploy。
- 固定使用 repository 內的 Wrangler：
  `LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler`，不要以 `npx` 臨時解析版本。
- 先定稿 schema、registry、adapter 與 exporter；migration lock 只在最後一次定稿後同步。

## 一次性發布原則

每個 release 必須固定一組 `commit + state + before snapshot + delta + manifest + plan`。
完成 plan 後不得修改 migration、registry、來源 artifact、delta 或 commit；任何變更都要
建立新的 release state 與 plan。不要把服務重啟、本地 D1 rebuild、mirror 匯入與 production
apply 混在同一個反覆嘗試循環裡。

## 詞典 mirror 與差分基線

正式發布只使用 `release_dictionary.py` 這個單一準備入口。它在第一次修改 mirror 前，
以 SQLite backup API 建立與 state 綁定的一致 before snapshot；正式發布應明確指定持久目錄：

```bash
python3 scripts/dictionary/release_dictionary.py \
  --input-dir /Volumes/DATA/langmap-structured-jsonl \
  --d1-database scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --state scripts/db/state/backup/import-state/<release>.json \
  --staging-root /tmp/langmap-dictionary-staging \
  --snapshot-root scripts/db/state/backup/snapshots \
  --release-name <NNN>-<topic> \
  --stop-on-error
```

不要先用沒有 `--snapshot-root`／release state 的手動 incremental import 修改 mirror。
若 mirror 已被未綁定 state 的嘗試修改，停止發布，從 production 對齊的 export／snapshot
重建 mirror；不要用舊 snapshot 加其他 delta 人工拼湊基線。

state 的成功紀錄包含 `before_snapshot_path`、`before_snapshot_sha256` 與
`snapshot_run_key`。產生 delta 時必須使用該 snapshot，不自行反推基線：

```bash
python3 scripts/db/export_dictionary_delta.py \
  --before <state.before_snapshot_path> \
  --after scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --output scripts/db/state/backup/delta/<NNN>-<topic>.sql \
  --manifest scripts/db/state/backup/delta/<NNN>-<topic>.manifest.json
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
  --dictionary-postflight-manifest scripts/db/state/backup/delta/<NNN>-<topic>.manifest.json \
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
- 不在沒有 mirror replay 與 postflight verify 的情況下宣告 release 成功。

## 單一準備入口（推薦）

上述步驟也可由一個可重跑命令完成 import、delta／manifest 產出與 production plan：

```bash
python3 scripts/dictionary/release_dictionary.py \
  --input-dir /Volumes/DATA/langmap-structured-jsonl \
  --d1-database scripts/db/state/backup/publish-mirror.incremental.sqlite \
  --state scripts/db/state/backup/import-state/<release>.json \
  --staging-root /tmp/langmap-dictionary-staging \
  --snapshot-root scripts/db/state/backup/snapshots \
  --release-name <NNN>-<topic> \
  --refresh-language-statistics
```

這個命令會依序執行 staging、quality gate、mirror snapshot、import、delta、manifest 與
production plan。若 preflight 顯示 production 與 mirror counts 不一致，流程必須停止並
重新同步 mirror；不得以 bookmark 取代 baseline，也不得直接對 production 執行 importer。

需要在線上執行受管 D1 apply 時，額外加入 `--apply`、`--database-name <完整資料庫名稱>`
與 `--confirm-production <完整資料庫名稱>`；兩個名稱必須完全相同。大型 delta 可加
`--split`。apply 成功後會 replay 同一份 delta 回 mirror 並檢查外鍵；此入口不執行 Web deploy。
