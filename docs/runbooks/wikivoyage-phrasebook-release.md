# Wikivoyage 會話手冊發布 Runbook

本流程把英文 Wikivoyage `Category:Phrasebooks` 轉成 LangMap 的一套英文 managed
handbook。它只發布英文詞句、目標語言詞句與目標 reading；未審閱的頁面保持
`blocked`，不以標題猜語言，也不以機器翻譯補列。所有命令先在外部 artifact 目錄與
local SQLite 執行；production D1 的 plan／apply 需要另外核准。

## 固定輸入與 artifact

每次 release 固定以下集合，完成後不得就地修改：

- downloader `manifest.json` 與 `pages/<pageid>-<revision>.wikitext`；
- `export-report.json`、`quality-report.json`、`source-catalog.json`；
- JSONL 的 checksum、staging release、before snapshot 與自然鍵 delta；
- 審核結論、Git commit 與本 runbook 的 operation 記錄。

快照預設放在 `/Volumes/DATA/langmap-wikivoyage/`，JSONL 預設放在
`/Volumes/DATA/langmap-wikivoyage-jsonl/`。不要把快照、`.wrangler/`、state 或 secret
加入 Git。

## 1. Download、catalog 與 quality gate

```bash
python3 scripts/wikivoyage/download.py \
  --output-dir /Volumes/DATA/langmap-wikivoyage

python3 -m scripts.wikivoyage.export_phrasebooks \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --output-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --page-catalog scripts/wikivoyage/page-catalog.json \
  --section-catalog scripts/wikivoyage/section-catalog.json \
  --report /Volumes/DATA/langmap-wikivoyage-jsonl/export-report.json

python3 -m scripts.wikivoyage.quality \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --export-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --report /Volumes/DATA/langmap-wikivoyage-jsonl/export-report.json \
  --output /Volumes/DATA/langmap-wikivoyage-jsonl/quality-report.json
```

Quality gate 必須通過以下條件：

- manifest 每個 pageid 恰好在 export report 出現一次，且 snapshot checksum 正確；
- `included` page 與數字 JSONL 一一對應，header `entry_count` 與實際 entry 相同；
- first／middle／last sample 都有英文 equivalent、目標 language／locale 與 provenance marker；
- `review/quarantine.jsonl`、`review/removals.jsonl` 的數量已被人工檢視；
- 無 `invalid_page_state`、`page_accounting_mismatch` 或 `jsonl_page_count_mismatch`。

`blocked` 不等於錯誤：它表示 page catalog 或 registry identity 尚未完成。要解鎖時先
更新 language reference／locale seed，重新跑 registry report，再重做該頁 JSONL；不要在
前端或 importer 寫例外。`quarantined`、reading script mismatch、反向列表方向或頁面
結構 drift 則先回源頁與 parser fixture 修正。

## 2. Staging 與 local mirror

Quality gate 通過後，依每批約 20–30 個 JSONL 執行既有 incremental importer。可用
`--only 16153.jsonl` 或 `--limit-files 25`，重跑時沿用同一 state；不要刪除 state 裏的
成功紀錄來強行重播。

```bash
python3 scripts/dictionary/incremental_import.py \
  --input-dir /Volumes/DATA/langmap-wikivoyage-jsonl \
  --d1-database <local-canonical.sqlite> \
  --state <state-dir>/wikivoyage-phrasebooks.json \
  --staging-root /tmp/langmap-wikivoyage-staging \
  --snapshot-root <state-dir>/snapshots \
  --batch-size 5000 --commit-every 50000 --stop-on-error
```

每個 staging release 必須通過既有 normalization、cluster、reading quality gate。抽查
至少包含日文 kana／romaji、中文簡繁／pinyin、粵語 jyutping，以及含括號、slash、placeholder
的 row。核對：reading 是 `expression_readings`，不是 expression；例句沒有被掛到主詞頭；
所有 edge 都是英文與目標詞句的 direct mapping。

## 3. 建立 managed handbook

確認 local mirror 具備 system user `langmap`、`eng-Latn-US`、所有待發布 language／locale，
並已套用 `backend/migrations/0044_wikivoyage_handbook.sql`。然後執行：

```bash
python3 -m scripts.wikivoyage.build_handbook \
  --database <local-canonical.sqlite> \
  --section-catalog scripts/wikivoyage/section-catalog.json
```

builder 以 `managed_key=enwikivoyage-phrasebooks` 重用同一 handbook row，只重建 sections
與 items；重跑必須保持 handbook ID、section order 與 item identity 穩定。`GET /api/v2/handbooks/:id`
應回傳 `managed=true`、`can_edit=false`；PUT／DELETE 應被 `403 MANAGED_HANDBOOK_READ_ONLY`
拒絕。翻譯頁面只能呼叫一次
`GET /api/v2/handbooks/:id/translations?target_locale=<exact-locale>`，不能逐 item 呼叫，
也不能在線上計算 locale coverage。

## 4. Production delta、plan／apply／verify

完成抽查後，使用既有 source-scoped natural-key delta 流程；不要把 staging 全庫 counts
當 production 基線，也不要直接執行 remote migration：

```bash
python3 scripts/db/export_dictionary_source_delta.py \
  --staging <staging.sqlite> \
  --source-type url \
  --source-name <page-url> \
  --locale-code <locale-code> \
  --output <delta.sql> \
  --manifest <delta.source.json>

LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler \
  ./scripts/db/manage.sh production inventory
LANGMAP_WRANGLER_BIN=./backend/node_modules/.bin/wrangler \
  ./scripts/db/manage.sh production plan \
  --approved-data-migration <delta.sql> \
  --refresh-language-statistics
```

由 operator 審核 plan、delta checksum、identity preflight、source scope 與 bookmark 後，
才依 `docs/runbooks/production-data-release.md` apply／verify。apply 後必須：

1. 以 source URL、page revision、section／row marker 驗證 expressions、locale links、readings、edges；
2. 重新執行 `build_handbook.py` 或受管發布 stage，驗證 handbook sections/items；
3. 執行 language statistics refresh，確認 `/languages` 的 counts 已更新；
4. 在 `TODO.md` 記錄 source key、delta sha256、operation ID、bookmark 與 source-scoped counts。

失敗時停止並保留 manifest、delta、plan、operations journal 與 bookmark；不要手動刪除共享
expression 或 reading，也不要以新 plan 重播已完成的 stage。

## 授權與 UI attribution

英文 Wikivoyage 內容依 Wikimedia CC BY-SA 4.0 使用。發布包與 managed handbook 必須保留
頁面 URL、revision、抓取時間與 attribution 入口；UI 僅顯示來源聲明，不把 Wikivoyage
reading 當作 LangMap 自己的發音保證。
