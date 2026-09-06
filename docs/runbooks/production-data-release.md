# Production Data Release Runbook

## 前置條件

- reviewed Git commit、clean migration lock 與 production identity。
- local tests、local rebuild/verify、bundle checksum 均通過。
- operator 已審核 inventory 與 plan；本 runbook 不自動 deploy。
- 固定使用 repository 內的 Wrangler：
  `LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler`，不要以 `npx` 臨時解析版本。
- 先定稿 schema、registry、adapter 與 exporter；migration lock 只在最後一次定稿後同步。

## 一次性發布原則

每個 release 必須固定一組 `commit + source artifact + delta + plan`。
完成 plan 後不得修改 migration、registry、來源 artifact、delta 或 commit；任何變更都要
建立新的 plan。不要把服務重啟、本地 D1 rebuild、staging 匯入與 production
apply 混在同一個反覆嘗試循環裡。

## 詞典 staging 與無全庫基線發布

production 詞典發布不要求 production 全庫 export、持久 mirror 或全庫 count 基線。
本地 SQLite 只負責 staging、品質檢查及產生可審核 delta，不是 production 的副本，
也不以 staging 與 production 全庫 counts 相等作為發布條件。

舊的固定 ID delta 可使用 `release_dictionary.py` 準備；before snapshot 只用來計算本次
本地匯入差異，不代表 production 基線：

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

不要從 production 全量 export 只為了讓本地 counts 對齊。staging 被其他嘗試污染時，
丟棄或重建 staging 即可；不得把它當成 production 現況的證明。

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
`--rows-per-insert` batch。正式發布優先使用 `export_dictionary_source_delta.py`，按 source
與自然鍵產生可重跑 SQL，不攜帶 staging 的 production identity：

```bash
python3 scripts/db/export_dictionary_source_delta.py \
  --staging <staging.sqlite> \
  --source-type publication \
  --source-name <source-key> \
  --locale-code <locale-code> \
  --output scripts/db/state/backup/delta/<NNN>-<topic>.sql \
  --manifest scripts/db/state/backup/delta/<NNN>-<topic>.source.json
```

來源 artifact 修正後重發布（如 packed gloss 拆分改變了 expression identity）時加 `--replace`：
delta 會先以自然鍵刪除該 source 擁有的全部 rows 再重插，被取代的舊 rows 不會殘留。
`--replace` 在 staging 顯示其他 source 也使用該 source 擁有的 expression 時會拒絕產生，
避免刪除傷及他人；目標尚無此 source 時 delete 段為 no-op，首次發布同樣可用。

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

不再將 staging 的全庫 before／after counts 傳入 production plan。apply 後按 source key
驗證 expressions、edges、readings、locale links 與 `language_statistics`；bookmark 是回退點，
不是資料基線。

每次 apply 成功後，立即在 `TODO.md` 記一條發布紀錄（source key、delta 路徑與 sha256、
operation ID、bookmark、日期與 source-scoped counts）。這份 ledger 是接力 session 判斷
「某 source 是否已上 production」的唯一入口，不得只靠翻 transcript 或 plan 檔推斷。

## 失敗處理

讀取 `scripts/db/state/production/operations.jsonl` 與 plan report。bookmark 取得失敗、
identity mismatch、plan commit 改變、ownership 不明或 verify 失敗時停止。若資料、migration
或 reference stage 已 journal 完成，修復暫時性問題後以**同一份 plan**重跑 apply；流程會沿用
原 bookmark 並跳過已完成 stage。不得另產 plan 或手動重播已完成 delta。

## 禁止事項

- 不繞過 plan、confirmation 或 bookmark gate。
- 不在 apply 腳本中呼叫 deploy。
- 不在沒有來源範圍 postflight verify 的情況下宣告 release 成功。

## 單一 staging 入口

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

這個命令會依序執行 staging、quality gate、snapshot、import、delta 與 production plan，
但不再以 staging manifest 的全庫 counts 阻擋發布。production export 只用於事故調查、
restore 後需要本地副本，或明確要求製作離線副本，不是每部詞典的發布前置條件。

需要在線上執行受管 D1 apply 時，額外加入 `--apply`、`--database-name <完整資料庫名稱>`
與 `--confirm-production <完整資料庫名稱>`；兩個名稱必須完全相同。大型 delta 可加
`--split`。此入口不執行 Web deploy。
