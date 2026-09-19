# Wikivoyage CSV 來源搬遷設計

## 狀態與目標

本設計把 `langmap/scripts/wikivoyage` 的來源端責任移到獨立
`dictionary` repo，讓 Wikivoyage 固定 revision 直接產生可審核的 canonical CSV；
LangMap 不再為 Wikivoyage 建立 SQLite／D1 staging，也不再接受 JSONL 中間物。

完成後：

1. `dictionary` 負責下載快照、套用 page／section catalog、解析 wikitext、品質檢查，
   並保存每頁的 `data.csv`、`readings.csv` 與 `manifest.json`。
2. LangMap 的 `import_mapping_csv_pg.py` 以同一 transaction 將兩份 CSV 同步到
   PostgreSQL，建立 expression、mapping、reading、source marker 與 locale registry。
3. Wikivoyage managed handbook 若仍需重建，改由 LangMap 的 PG-only command 讀取
   `expression_edge_sources.source_marker`；它不再屬於來源 exporter，也不接觸 SQLite／D1。

## 非目標

- 不重新下載或重發布既有 production 資料；本工作只改來源產物與匯入入口。
- 不把 handbook SQL／資料庫邏輯放回 `dictionary` repo。
- 不保留 JSONL、SQLite mirror、D1 local import、incremental state 或 D1 release
  pipeline 作為相容入口。
- 不改變既有 parser 的語言判斷、reading scheme、slash alternative、section alias
  與 quarantine 規則；若規則有問題，仍在 Wikivoyage adapter 修正。

## 專案邊界

### `dictionary` repo：Wikivoyage source adapter

新增 `src/dictionary_export/wikivoyage/` package，集中以下不依賴 LangMap DB 的模組：

- `download.py`：MediaWiki discovery、continuation/retry、revision snapshot、checksum
  manifest。
- `catalog.py`：page／section profile 與 registry-independent validation。
- `parser.py`：固定 wikitext 的 phrase row、target locale、reading、section marker
  正規化。
- `export.py`：把 parser record 轉為共用 CSV model，寫入逐頁 archive。
- `quality.py`：驗證 snapshot、CSV、readings、manifest、page accounting 與 quarantine
  統計；不得連線 PostgreSQL。
- `data/page-catalog.json`、`data/section-catalog.json` 與小型 fixture：隨 adapter
  版本控制，不帶入 LangMap runtime。

公開入口為 `dictionary-wikivoyage-export`，支援既有 snapshot-only 與 optional
`--download` 流程；輸出目錄可由參數指定，預設不覆寫既有 archive。

### LangMap repo：PG import 與 handbook rebuild

- `scripts/dictionary/import_mapping_csv_pg.py` 擴充為可選讀 `readings.csv`，並依
  manifest 的 `source_type`／`source_name` 建立或解析 source。
- 新增 `scripts/postgres/build_wikivoyage_handbook.py`，將現有 handbook rebuild
  SQL 改為 psycopg／PostgreSQL；section catalog 從 dictionary archive 或明確參數
  讀取。這是發布後的 PG 維護工具，不是來源 exporter。
- `scripts/wikivoyage/` 的全部檔案、SQLite/D1 pipeline、舊測試與舊 runbook 命令
  在新入口驗收後刪除或改為歷史指引。

## Canonical archive contract

每個 Wikivoyage page 是一個 source snapshot：

```text
csv/wikivoyage/<pageid>/
  data.csv
  readings.csv
  manifest.json
```

### `data.csv`

共用表頭固定為：

```text
ENTRY_ID,NOTE,LOCALE_<target-locale>,LOCALE_eng-Latn-US
```

實際 locale columns 仍按 UTF-8 bytewise ascending 排列。每個 parser entry 產生一列：

- `ENTRY_ID`：`oldid:<revision>#<section-key>/<row-number>`，保留 revision、section 與
  原始 row provenance；同一 archive 內唯一。
- `NOTE`：保留 parser 判定的 target annotation；section 與 revision 不另猜測，
  以 `ENTRY_ID`／manifest 為準。
- target locale cell：`canonical_headword`。
- `eng-Latn-US` cell：該 entry 的 English equivalent；同列多個等價物以 `|` 分隔。

CSV writer 統一執行 NFC、trim、固定去重、穩定 entry ordering 與 RFC 4180 quoting。
source adapter 不得自行寫 header 或跳過 shared contract。

### `readings.csv`

readings 不塞入 `NOTE` 或 `data.csv` 的 expression cell，另以固定表頭保存：

```text
ENTRY_ID,LOCALE,SCHEME,READING
```

每列對應一個 `data.csv` entry、reading locale、scheme 與 normalized value；同一
`(ENTRY_ID, LOCALE, SCHEME, READING)` 不可重複。CSV 內不允許 `|`，避免與 expression
cell 的多值語義混淆。

### `manifest.json`

除既有 canonical CSV checksum 欄位外，Wikivoyage manifest 必須包含：

```json
{
  "manifest_version": 2,
  "source_key": "enwikivoyage:16153",
  "source_type": "url",
  "source_name": "https://en.wikivoyage.org/wiki/Japanese_phrasebook",
  "license": "CC BY-SA 4.0",
  "pageid": 16153,
  "revision": 5332510,
  "csv": "data.csv",
  "csv_sha256": "...",
  "readings_csv": "readings.csv",
  "readings_sha256": "...",
  "entry_count": 0,
  "reading_count": 0,
  "locale_metadata": {}
}
```

`source_key` 是 archive／annotation identity；`source_type`／`source_name` 是
PostgreSQL `sources` 自然鍵。manifest 的 checksum 不匹配、source identity 不完整、
page／revision 缺漏或未知 locale 時，`--check` 與 `--apply` 都 fail closed。

## Import 行為

`--check` 驗證 data/readings 兩份 CSV、checksum、entry／reading count、ENTRY_ID 對應、
locale metadata 與預計 expression／edge／reading 數量，不寫資料庫。

`--apply` 在一個 PostgreSQL transaction 中：

1. 建立或檢查 manifest 指定的 language、script、region、language_locale、source。
2. 以 `(language_id, text, homograph_index=1)` 合併 expression，建立 expression locale
   link 與 source marker。
3. 每列所有不同 expression 建立 pairwise edge；相同 language 的不同詞面也建立 edge，
   完全相同 expression 不建立 self-edge。
4. 依 `readings.csv` 的 ENTRY_ID／locale 將 readings 寫入 `expression_readings`，
   並以 source_id 讓重跑或刪列可 source-scoped 清理。
5. 只移除該 source 的 expression／edge claims、annotations 與 readings；保留其他
   source 的共用資料，最後清理沒有任何 ownership 或使用者引用的孤兒。

同一 archive 重跑必須冪等；刪除一列後重跑只能撤回該 source 曾聲明的資料。

## Handbook rebuild

PG handbook command 維持既有 managed key `enwikivoyage-phrasebooks`、section ordering、
casefold 去重與 sentence-case preference。它從 PG 的 source marker 解析 section／row，
不讀 raw snapshot，也不依賴 `dictionary` 的 Python package；section catalog 僅作
排序與標題來源。若 source marker 缺失或 section 未列入 catalog，command 產生明確
validation error，不靜默建立錯誤 section。

## 清理與文件

- `scripts/wikivoyage/`、`scripts/dictionary` 中舊 Wikivoyage adapter／SQLite staging
  bridge、`--d1-database`／`--state`／`--staging-root` 參數與其測試全部移除。
- root runbook 改為 dictionary export → `--check` → PG `--apply` → optional handbook
  rebuild；歷史 audit 只保留為歷史記錄，不再提供可執行舊命令。
- dictionary README 說明 Wikivoyage source adapter、固定 snapshot、CSV archive、
  readings sidecar、CC BY-SA attribution 與不覆寫規則。

## 驗收

1. dictionary parser 原有 fixture 測試全數保留，新增 golden `data.csv`、`readings.csv`
   與 manifest checksum 測試。
2. `dictionary-wikivoyage-export` 對 Japanese／Cantonese／Chinese split locale fixture
   產出正確 locale、source marker、reading scheme 與無 JSONL 產物。
3. LangMap importer 測試涵蓋 sidecar readings、source metadata、同語言 pair、重跑、
   刪列與跨 source 保留。
4. PG handbook rebuild 測試覆蓋 idempotence、section ordering、casefold 去重與未知
   marker fail-closed。
5. `scripts/wikivoyage` 不再存在 SQLite/D1 import；dictionary 與 LangMap 的完整測試、
   `git diff --check`、`./build.sh` 通過。

## 風險與回退

來源 archive 由 dictionary Git commit 與 manifest checksum 重建；不存在 D1／SQLite
回退通道。CSV schema／reading sidecar 改變時，必須先更新 dictionary exporter、LangMap
importer 與 fixture，再重新匯出並抽查 entry count、readings 與 source marker。
