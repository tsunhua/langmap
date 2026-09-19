# Wikivoyage 詞典發布 Runbook

本流程把固定 revision 的英文 Wikivoyage phrasebook 轉成 dictionary repo 的寬表 CSV，
再以 LangMap PostgreSQL importer 匯入。每個英語→一個目標 locale 是一個 archive；同一頁
的簡體與繁體中文必須分開。流程不使用 SQLite、D1 staging 或 JSONL。

## 1. 下載與產生 dictionary archive

來源端在 dictionary repo 執行：

```bash
uv run python -m dictionary_export.wikivoyage.download \
  --output-dir /Volumes/DATA/langmap-wikivoyage

uv run dictionary-wikivoyage-export \
  --snapshot-dir /Volumes/DATA/langmap-wikivoyage \
  --output-dir csv/wikivoyage

uv run python -m dictionary_export.wikivoyage.quality csv/wikivoyage
```

輸出結構為：

```text
csv/wikivoyage/<pageid>-<target-locale>/data.csv
csv/wikivoyage/<pageid>-<target-locale>/manifest.json
```

`data.csv` 的欄位為 `ENTRY_ID,NOTE,LOCALE_*` 及可選的
`READING_<locale>_<scheme>`。manifest 鎖定 CSV checksum、page revision、target locale、
source URL 與 CC BY-SA 4.0 attribution。exporter 不覆寫已存在的 archive；變更後以新的
輸出目錄重跑並抽查 headword、英文 equivalent、direction、reading、marker 與 entry count。

## 2. LangMap `--check` 與 `--apply`

先在 LangMap repo 對每個方向做 fail-closed 檢查，再使用隔離 PostgreSQL 套用：

```bash
python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/wikivoyage/16153-jpn-Jpan-JP/manifest.json \
  --check

DATABASE_URL='postgresql://...' \
  python3 scripts/dictionary/import_mapping_csv_pg.py \
  --manifest /path/to/dictionary/csv/wikivoyage/16153-jpn-Jpan-JP/manifest.json \
  --apply
```

`--apply` 在一個 transaction 內建立或解析 locale registry、expression、pairwise mapping、
source marker 與 reading。重跑只清理該 manifest source 的 claims、annotations、readings；
共享 expression、edge 與其他 source 的 marker 保留。reading 是 `expression_readings` metadata，
不會成為 mapping endpoint。

## 3. PG handbook rebuild（可選）

匯入所有需要的方向後，使用 dictionary repo 搬入的 section catalog 重建 managed handbook：

```bash
DATABASE_URL='postgresql://...' \
  python3 scripts/postgres/build_wikivoyage_handbook.py \
  --section-catalog /path/to/dictionary/src/dictionary_export/wikivoyage/data/section-catalog.json
```

command 只使用 PostgreSQL，依 source marker 的 section／row 排序，維持
`enwikivoyage-phrasebooks` managed key、casefold 去重與 sentence-case preference。未知或
格式錯誤的 marker 會 fail closed；不會自行建立臨時 section。

## 4. 驗收與留存

- 保留 snapshot manifest、每個 archive 的 manifest、quality report、審核結論與 dictionary
  commit；不要提交 snapshot、secret、`.wrangler/` 或暫存資料。
- 驗證每個 archive 的 checksum、entry／reading count、source marker、target locale、
  reading scheme；確認沒有 `*.jsonl` 產物。
- API smoke test 使用現行 `dev.sh` 與 PostgreSQL；不要重新建立或清除本地資料庫。
- 若資料問題來自頁面解析，回 dictionary adapter／catalog 修正後重新產出 CSV；不要在
  importer 或前端寫例外。

Wikivoyage 內容依 Wikimedia CC BY-SA 4.0 使用；發布與 UI attribution 保留 canonical URL
及 revision。
