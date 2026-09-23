# Dictionary mapping importer

將 dictionary repo 的 canonical CSV snapshot 同步到 PostgreSQL。一般 locale 欄位會建立 expression 並參與 mapping；欄位名稱本身決定 language／locale registry，不再經本地 SQLite 或 D1 staging。

## Canonical CSV snapshot

`dictionary` repo 直接提交：

```text
csv/<source-key>/data.csv
csv/<source-key>/manifest.json
```

表頭固定為 `ENTRY_ID,NOTE,LOCALE_<locale-code>...`，locale 欄位按 UTF-8 bytewise 排序；其後可接
`READING_<locale>_<scheme>` 欄位，所有欄位均 deterministic。每格多個詞面或 reading 以 `|`
分隔；`ENTRY_ID` 每列應唯一，manifest 鎖定 CSV SHA-256、entry／reading count 與 locale 清單。
source-specific 的 parsing／reading 規則留在 dictionary repo，不在本 importer 寫例外。

## 驗證與套用

`--check` 只需要 Python；`--apply` 需要 `psycopg`、`DATABASE_URL` 與 `pg_dump`（除非明確關閉 backup）。不依賴 Homebrew、`psql`、D1 或 SQLite：

```bash
python3 -m pip install -r scripts/dictionary/requirements-pg.txt
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/<source-key>/manifest.json --check
DATABASE_URL='postgresql://...' \
  LANGMAP_PRE_RELEASE_BACKUP_DIR=/srv/langmap/backups \
  python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/<source-key>/manifest.json --apply
```

也可以把 release 目錄交給 importer：

```bash
DATABASE_URL='postgresql://...' \
LANGMAP_PRE_RELEASE_BACKUP_DIR=/srv/langmap/backups \
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --input-dir /srv/langmap/releases/dictionary-2026-09-23 --apply
```

`--check` 不寫資料庫，會遞迴尋找 `manifest.json` 並串流驗證格式、checksum、manifest 計數與每列資料；為避免把大型 CSV 寫入 SQLite，JSON 中的 `expressions`、`edges` 會是 `null`，並以 `distinct_counts: "deferred_to_postgresql"` 標記。`expression_claims`、`edge_claims` 仍是串流計數。全域 distinct expression／edge、以及重複 `ENTRY_ID` 會在 `--apply` 的 PostgreSQL staging 中以 SQL／主鍵驗證，並在 source commit 前檢查。

`--apply` 預設先建立一次 custom-format `pg_dump`；可用 `--backup-dir PATH` 指定位置，也可用 `LANGMAP_PRE_RELEASE_BACKUP_DIR` 設定位置。只有在已有其他已驗證 recovery point 時，才使用 `--no-pre-release-backup` 關閉，並會顯示警告。

每個 source 使用獨立 transaction，成功的 source 會立即提交；失敗的 source 只回滾自己，之前已提交的 source 不會被撤銷，後續 source 會停止處理。結果 JSON 會列出 `committed`、`failed`、`not_attempted` 與 `cleanup`，部分成功仍以非零 exit code 結束，方便修正後重跑失敗 source。

每個 source 的匯入流程：

1. 依每個 `LOCALE_<locale-code>` 欄位建立或解析 language、script、region、language_locale。
2. 以 PostgreSQL `COPY FROM STDIN` 將 normalized cells、notes 與 readings 串流到 connection-scoped temporary staging tables。
3. 以 `(language, text)` 合併 expression，保留 `source_marker=ENTRY_ID`。
4. 對同一列所有不同詞面建立 pairwise mapping；同語言不同詞面也會互連，不建立 self-edge。
5. 將 `READING_*` 寫入 `expression_readings` metadata，不把 reading 當 mapping endpoint；若 reading profile 沒有對應的 `LOCALE_*` 欄位，按同列同語言 expression 掛載，並保留 reading profile 的 `locale_id`。
6. 只刪除／重建本 source 的 claims、annotations 與 readings，保留其他 source 的 expressions、edges 與 markers。
7. 用 set-based SQL 驗證 source counts 後提交；所有 source 完成後才清理仍無 claim 的 orphan。

checksum、表頭、ENTRY_ID、locale metadata 或 PostgreSQL constraint 失敗會 rollback 當前 source；重跑同一 manifest 應得到相同 source summary。`--rebuild-secondary-indexes` 是 apply-only 的明確 opt-in，會在每個 source transaction 內重建 allowlisted secondary indexes；多 source release 可能重複重建，因此小型或部分重跑通常不要加這個旗標。
