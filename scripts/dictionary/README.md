# Dictionary mapping importer

將 dictionary repo 的 canonical CSV snapshot 同步到 PostgreSQL。一般 locale 欄位會建立 expression 並參與 mapping；欄位名稱本身決定 language／locale registry，不再經本地 SQLite 或 D1 staging。

## Canonical CSV snapshot

`dictionary` repo 直接提交：

```text
csv/<source-key>/data.csv
csv/<source-key>/manifest.json
```

表頭固定為 `ENTRY_ID,NOTE,LOCALE_<locale-code>...`，locale 欄位按 UTF-8 bytewise 排序；一格內多個詞面以 `|` 分隔。`ENTRY_ID` 每列唯一，manifest 鎖定 CSV SHA-256、entry count 與 locale 清單。source-specific 的 parsing／reading 規則留在 dictionary repo，不在本 importer 寫例外。

## 驗證與套用

跨 OS，只需要 Python、`psycopg` 與 `DATABASE_URL`；不依賴 Homebrew、`psql`、D1 或 SQLite：

```bash
python3 -m pip install -r scripts/dictionary/requirements-pg.txt
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/<source-key>/manifest.json --check
DATABASE_URL='postgresql://...' python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/<source-key>/manifest.json --apply
```

`--check` 不寫資料庫。`--apply` 在單一 transaction 中：

1. 依每個 `LOCALE_<locale-code>` 欄位建立或解析 language、script、region、language_locale。
2. 以 `(language, text)` 合併 expression，保留 `source_marker=ENTRY_ID`。
3. 對同一列所有不同詞面建立 pairwise mapping；同語言不同詞面也會互連，不建立 self-edge。
4. 只刪除／重建本 source 的 claims，保留其他 source 的 expressions、edges 與 markers。

checksum、表頭、ENTRY_ID、locale metadata 或 PostgreSQL constraint 失敗會 rollback；重跑同一 manifest 應得到相同 summary。
