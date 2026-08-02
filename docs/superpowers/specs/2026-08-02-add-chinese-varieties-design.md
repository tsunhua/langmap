# 補齊漢語變體語言登記（設計）

> 日期：2026-08-02
> 狀態：已設計、待實作

## Goal

在語言 registry 中補齊尚未登記的漢語變體，使 `/languages` 能完整涵蓋漢語各方言群。本次範圍為先前盤點中缺漏的五個變體：晋语、赣语、平话（桂北/桂南）、闽中语、莆仙话。

**非目標：**
- 不新增任何詞句內容（新語言以 0 expressions 呈現）。
- 不新增 UI locale。
- 不新增 legacy code mappings（見下方「設計決策」）。
- 不撰寫 D1 migration（方案 B，見下）。
- 不處理 production 部署帶入方式（另行討論）。

## 現況（已驗證）

- 已登記的漢語變體：`cmn-Hans/Hant`（官话）、`wuu-*`（吴语）、`hsn-*`（湘语）、`cdo-*`（闽东）、`mnp-*`（闽北）、`nan-*`（闽南，含潮州話、POJ、Tâi-lô）、`yue-*`（粤语）、`hak-*`（客语）。
- 缺漏：晋语（`cjy`）、赣语（`gan`）、闽中（`czo`）、莆仙（`cpx`）、平话（`cnp` 桂北 + `csp` 桂南）。
- Glottolog 中「平话」為家族節點（`ping1245`），語言級節點為桂北平话（`nort3268`）與桂南平话（`sout3250`）。
- `cjy/gan/cnp/csp/czo/cpx` 六個 subtag 皆為 IANA 合法、未廢除之語言 subtag（已對照 `language-subtag-registry.txt`）。
- seed 目前 65 筆語言、57 個代表城市；sync 支援 `--offline`（raw 快取存在）。

## 設計決策

1. **範圍**：一次補齊五個變體（晋、赣、平话×2、闽中、莆仙），共 6 個 Glottolog 語言節點 × 2 script = 12 筆 language entry。
2. **平话拆兩筆**：`cnp`（桂北平话）與 `csp`（桂南平话）。不登記家族節點 `ping1245`——規格要求所有 languoid 來自 Glottolog 且以語言級節點登記；桂北/桂南各自有合法 IANA subtag，拆分可精確標記。
3. **命名**：沿用既有慣例。晋/赣/闽中用「语」（同吴语、湘语、闽东语），莆仙用「话」（同客家话），平话自然用「话」。Hans/Hant 字形對應簡繁。
4. **不加 legacy mappings**：這 6 個 code 過去不在 registry，無歷史 observed codes 需要 canonicalize；sync 產 artifacts 不會以 observed codes 強制檢查，`validate_manifest` 在無 observed codes 時不報 unmapped。對齊「最小變更」原則。
5. **方案 B（不寫 migration）**：只改 seed 並重產 artifacts，靠 `dev.sh` rebuild 帶入本地。不產生 `backend/migrations/` 新檔案；production 與其他環境的帶入方式不在本次範圍。

## 資料

### Languages（12 筆，皆 `origin: seed`、`reason: major-east-asia-language`）

| code | name | name_en | glottocode |
|---|---|---|---|
| `cjy-Hans` | 晋语 | Jin Chinese (Simplified) | `jiny1235` |
| `cjy-Hant` | 晉語 | Jin Chinese (Traditional) | `jiny1235` |
| `gan-Hans` | 赣语 | Gan Chinese (Simplified) | `ganc1239` |
| `gan-Hant` | 贛語 | Gan Chinese (Traditional) | `ganc1239` |
| `czo-Hans` | 闽中语 | Min Zhong Chinese (Simplified) | `minz1235` |
| `czo-Hant` | 閩中語 | Min Zhong Chinese (Traditional) | `minz1235` |
| `cpx-Hans` | 莆仙话 | Pu-Xian Chinese (Simplified) | `puxi1243` |
| `cpx-Hant` | 莆仙話 | Pu-Xian Chinese (Traditional) | `puxi1243` |
| `cnp-Hans` | 桂北平话 | Northern Pinghua (Simplified) | `nort3268` |
| `cnp-Hant` | 桂北平話 | Northern Pinghua (Traditional) | `nort3268` |
| `csp-Hans` | 桂南平话 | Southern Pinghua (Simplified) | `sout3250` |
| `csp-Hant` | 桂南平話 | Southern Pinghua (Traditional) | `sout3250` |

### Locations（6 筆，皆 `territory_code: CN`、`script_code: Hans`）

座標取城市中心；`reference` 沿用 `https://glottolog.org/resource/languoid/id/<glottocode>`。

| variety_key | city_name | city_name_en | latitude | longitude |
|---|---|---|---|---|
| `glotto:jiny1235` | Taiyuan | Taiyuan | 37.8706 | 112.5489 |
| `glotto:ganc1239` | Nanchang | Nanchang | 28.6820 | 115.8579 |
| `glotto:minz1235` | Sanming | Sanming | 26.2634 | 117.6394 |
| `glotto:puxi1243` | Putian | Putian | 25.4540 | 119.0078 |
| `glotto:nort3268` | Guilin | Guilin | 25.2742 | 110.2900 |
| `glotto:sout3250` | Nanning | Nanning | 22.8170 | 108.3665 |

城市選定理由：
- 晋语 → 太原（晋语核心區）。
- 赣语 → 南昌（赣语核心區）。
- 闽中语 → 三明（闽中语分布區）。
- 莆仙话 → 莆田（莆仙语故地）。
- 桂北平话 → 桂林（桂北平话分布於桂林周邊，以桂林為代表點）。
- 桂南平话 → 南宁（桂南平话分布核心）。

### Seed version

`language_seed_profiles.json` 的 `version` 由 3 升至 4。

## 管線（方案 B）

1. 修改 `scripts/v2/language_seed_profiles.json`：新增 12 筆 languages、6 筆 locations，`version` → 4。不加 mappings。
2. offline 重跑 sync：`sync_language_registry.py --offline`，產製 `scripts/v2/artifacts/language-registry-5.3/` 下 artifacts（`languages.csv`、`languoids.csv`、`language-locations.csv`、`language-registry.sql`、`manifest.json`、`online-code-migrations.json`）。預期 `manifest.json` 的 `language_tag_count` 65 → 77、`language_location_count` 57 → 63。
3. 手術式套用本地 DB：將產出的 `language-registry.sql` 對既有 DB 執行。此 SQL 為純 upsert（languoids/languages/language_subtags/language_locations），不觸及 `expressions` 與 FTS，不需 drop-FTS。
4. 測試與驗證：
   - `cd scripts/v2 && python3 -m unittest test_language_data`（實 seed 測試若被影響則更新）。
   - `manage.sh local verify`：預期僅剩既有的「測試殘留 languages count 與 orphan languages」mismatch。
   - `./build.sh` 或 `cd web && npm run build`（前端無改動，視需要）。
   - headless Chrome 抽查 `/languages`：出現「晋语／晉語」「赣语／贛語」「闽中语／閩中語」「莆仙话／莆仙話」「桂北平话／桂南平话」等條目。

## 驗收標準

- seed `languages` 65 → 77、`locations` 57 → 63。
- `/languages` 列出 12 個新條目（6 語言 × Hans/Hant），各自 0 expressions。
- 新語言的 `/language/<code>` 頁面可開啟，代表城市正確。
- `manage.sh local verify` 無新增 mismatch（僅保留既有測試殘留項）。
- 不新增 migration 檔案、不改動 `backend/` 與 `web/src/` 邏輯。
