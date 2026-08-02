# 補齊漢語變體語言登記實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在語言 registry 補齊五個缺漏的漢語變體（晋语、赣语、平话×2、闽中语、莆仙话），共 6 個 Glottolog 語言節點 × Hans/Hant = 12 筆 language entry，以及 6 筆代表城市。

**Architecture:** 只改 seed profiles（方案 B）→ offline 重跑 sync 產製 artifacts → 手術式套用 `language-registry.sql`（純 upsert，不寫 migration）→ 驗證。不新增任何詞句、不新增 UI locale、不新增 legacy mappings。

**Tech Stack:** Python 3（sync/測試）、SQLite/D1（miniflare）。

**Spec:** `docs/superpowers/specs/2026-08-02-add-chinese-varieties-design.md`

## 前置事實（已驗證，勿再假設）

- 本地 D1 路徑：`./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite`。以下用 `$DB` 代稱，每個 task 需自行 export。
- 遷移前基準（已查詢）：`languages` 65 列、`language_locations` 57 列、`expressions` 1308 列；`languoids` 表**已含** `jiny1235`/`ganc1239`/`minz1235`/`puxi1243`/`nort3268`/`sout3250` 六個節點（Glottolog 全量 dump 的一部分），只缺 `languages` 與 `language_locations` 的對應列。
- 六個 IANA subtag `cjy`/`gan`/`cnp`/`csp`/`czo`/`cpx` 皆為合法、未廢除（已對照 `language-subtag-registry.txt`）；`Hans`/`Hant`/`CN` 亦已註冊。
- 六個 glottocode 在 raw `glottolog-languoids.csv` 皆為 `language` 級節點：`jiny1235`(cjy)、`ganc1239`(gan)、`minz1235`(czo)、`puxi1243`(cpx)、`nort3268`(cnp)、`sout3250`(csp)。
- seed 檔目前 `version: 3`、`languages` 65、`locations` 57。
- 檔案 `scripts/v2/language_seed_profiles.json` 的 arrays 使用「末筆無尾逗號、後續每筆前綴 `,`」的 JSON 風格，新筆追加時沿用。
- 代表城市 API（`backend/src/routes/languages.ts:124`）以 `variety_key + (script_code = 語言 script 或 '')` 過濾。新語言全數只有 `Hans` 城市，故 `*-Hant` 詳情頁無城市——與既有 `wuu-Hant`、`hsn-Hant`、`cdo-Hant`、`mnp-Hant` 行為一致，不需改後端。
- registry SQL 是純 upsert（languoids/language_subtags/languages/language_locations），**不會刪除**任何列，亦不觸及 `expressions` 與 FTS，不需 drop-FTS。
- 既有測試 31 筆全綠（`Ran 31 tests`、`OK`）。`test_local_rebuild.py`、`verify.py` 的計數都讀自 `manifest.json`，無硬編碼 65/57。

---

## Task 1: 寫失敗測試（TDD red）

**Files:**
- Test: `scripts/v2/test_language_data.py`

- [ ] **Step 1: 新增兩筆測試**

在 `scripts/v2/test_language_data.py` 的 `test_chaozhou_profiles_use_exact_glottocode_for_each_script` 方法結束（第 434 行）之後、`test_expression_schema_tracks_common_variant_classification`（第 436 行）之前，插入下列兩個方法：

```python
    def test_seed_profiles_register_all_chinese_varieties(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        self.assertEqual(profiles["version"], 4)
        by_code = {profile["code"]: profile for profile in profiles["languages"]}
        expected = {
            "cjy-Hans": ("晋语", "Jin Chinese (Simplified)", "jiny1235"),
            "cjy-Hant": ("晉語", "Jin Chinese (Traditional)", "jiny1235"),
            "gan-Hans": ("赣语", "Gan Chinese (Simplified)", "ganc1239"),
            "gan-Hant": ("贛語", "Gan Chinese (Traditional)", "ganc1239"),
            "czo-Hans": ("闽中语", "Min Zhong Chinese (Simplified)", "minz1235"),
            "czo-Hant": ("閩中語", "Min Zhong Chinese (Traditional)", "minz1235"),
            "cpx-Hans": ("莆仙话", "Pu-Xian Chinese (Simplified)", "puxi1243"),
            "cpx-Hant": ("莆仙話", "Pu-Xian Chinese (Traditional)", "puxi1243"),
            "cnp-Hans": ("桂北平话", "Northern Pinghua (Simplified)", "nort3268"),
            "cnp-Hant": ("桂北平話", "Northern Pinghua (Traditional)", "nort3268"),
            "csp-Hans": ("桂南平话", "Southern Pinghua (Simplified)", "sout3250"),
            "csp-Hant": ("桂南平話", "Southern Pinghua (Traditional)", "sout3250"),
        }
        for code, (name, name_en, glottocode) in expected.items():
            entry = by_code[code]
            self.assertEqual(entry["name"], name)
            self.assertEqual(entry["name_en"], name_en)
            self.assertEqual(entry["glottocode"], glottocode)
            self.assertEqual(entry["origin"], "seed")
            self.assertEqual(entry["reason"], "major-east-asia-language")

    def test_seed_profiles_carry_chinese_variety_representative_cities(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        locations = {
            (loc["variety_key"], loc["city_name"]): loc
            for loc in profiles["locations"]
        }
        expected = {
            ("glotto:jiny1235", "Taiyuan"): ("CN", "Hans", 37.8706, 112.5489),
            ("glotto:ganc1239", "Nanchang"): ("CN", "Hans", 28.6820, 115.8579),
            ("glotto:minz1235", "Sanming"): ("CN", "Hans", 26.2634, 117.6394),
            ("glotto:puxi1243", "Putian"): ("CN", "Hans", 25.4540, 119.0078),
            ("glotto:nort3268", "Guilin"): ("CN", "Hans", 25.2742, 110.2900),
            ("glotto:sout3250", "Nanning"): ("CN", "Hans", 22.8170, 108.3665),
        }
        for key, (territory, script, lat, lon) in expected.items():
            loc = locations[key]
            self.assertEqual(loc["territory_code"], territory)
            self.assertEqual(loc["script_code"], script)
            self.assertEqual(loc["latitude"], lat)
            self.assertEqual(loc["longitude"], lon)
```

- [ ] **Step 2: 執行測試確認失敗**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -20
```

預期：兩個新測試 FAIL。`test_seed_profiles_register_all_chinese_varieties` 在 `by_code["cjy-Hans"]` 拋 `KeyError`；`test_seed_profiles_carry_chinese_variety_representative_cities` 在 `locations[key]` 拋 `KeyError`。既有 31 筆維持 PASS。

---

## Task 2: 修改 seed profiles（green）

**Files:**
- Modify: `scripts/v2/language_seed_profiles.json`
- Test: `scripts/v2/test_language_data.py`

- [ ] **Step 1: 版本升到 4**

第 2 行 `"version": 3,` 改為 `"version": 4,`。

- [ ] **Step 2: 新增 12 筆 languages**

在第 68 行 `za-Latn` 那筆（以 `,` 開頭、無尾逗號）與第 69 行 `  ],` 之間插入，沿用前綴 `,` 風格：

```json
    ,{"code": "cjy-Hans", "name": "晋语", "name_en": "Jin Chinese (Simplified)", "glottocode": "jiny1235", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "cjy-Hant", "name": "晉語", "name_en": "Jin Chinese (Traditional)", "glottocode": "jiny1235", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "gan-Hans", "name": "赣语", "name_en": "Gan Chinese (Simplified)", "glottocode": "ganc1239", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "gan-Hant", "name": "贛語", "name_en": "Gan Chinese (Traditional)", "glottocode": "ganc1239", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "czo-Hans", "name": "闽中语", "name_en": "Min Zhong Chinese (Simplified)", "glottocode": "minz1235", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "czo-Hant", "name": "閩中語", "name_en": "Min Zhong Chinese (Traditional)", "glottocode": "minz1235", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "cpx-Hans", "name": "莆仙话", "name_en": "Pu-Xian Chinese (Simplified)", "glottocode": "puxi1243", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "cpx-Hant", "name": "莆仙話", "name_en": "Pu-Xian Chinese (Traditional)", "glottocode": "puxi1243", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "cnp-Hans", "name": "桂北平话", "name_en": "Northern Pinghua (Simplified)", "glottocode": "nort3268", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "cnp-Hant", "name": "桂北平話", "name_en": "Northern Pinghua (Traditional)", "glottocode": "nort3268", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "csp-Hans", "name": "桂南平话", "name_en": "Southern Pinghua (Simplified)", "glottocode": "sout3250", "origin": "seed", "reason": "major-east-asia-language"}
    ,{"code": "csp-Hant", "name": "桂南平話", "name_en": "Southern Pinghua (Traditional)", "glottocode": "sout3250", "origin": "seed", "reason": "major-east-asia-language"}
```

- [ ] **Step 3: 新增 6 筆 locations**

在第 195 行 `system:za-Latn` Nanning 那筆與第 196 行 `  ]` 之間插入：

```json
    ,{"variety_key":"glotto:jiny1235","city_name":"Taiyuan","city_name_en":"Taiyuan","territory_code":"CN","script_code":"Hans","latitude":37.8706,"longitude":112.5489,"reference":"https://glottolog.org/resource/languoid/id/jiny1235"}
    ,{"variety_key":"glotto:ganc1239","city_name":"Nanchang","city_name_en":"Nanchang","territory_code":"CN","script_code":"Hans","latitude":28.6820,"longitude":115.8579,"reference":"https://glottolog.org/resource/languoid/id/ganc1239"}
    ,{"variety_key":"glotto:minz1235","city_name":"Sanming","city_name_en":"Sanming","territory_code":"CN","script_code":"Hans","latitude":26.2634,"longitude":117.6394,"reference":"https://glottolog.org/resource/languoid/id/minz1235"}
    ,{"variety_key":"glotto:puxi1243","city_name":"Putian","city_name_en":"Putian","territory_code":"CN","script_code":"Hans","latitude":25.4540,"longitude":119.0078,"reference":"https://glottolog.org/resource/languoid/id/puxi1243"}
    ,{"variety_key":"glotto:nort3268","city_name":"Guilin","city_name_en":"Guilin","territory_code":"CN","script_code":"Hans","latitude":25.2742,"longitude":110.2900,"reference":"https://glottolog.org/resource/languoid/id/nort3268"}
    ,{"variety_key":"glotto:sout3250","city_name":"Nanning","city_name_en":"Nanning","territory_code":"CN","script_code":"Hans","latitude":22.8170,"longitude":108.3665,"reference":"https://glottolog.org/resource/languoid/id/sout3250"}
```

- [ ] **Step 4: 執行測試確認通過**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -5
```

預期：`Ran 33 tests`、`OK`。

- [ ] **Step 5: 確認 JSON 合法且計數正確**

```bash
python3 -c "
import json
d=json.load(open('scripts/v2/language_seed_profiles.json'))
assert d['version']==4, d['version']
codes={l['code'] for l in d['languages']}
assert len(d['languages'])==77, len(d['languages'])
assert len(d['locations'])==63, len(d['locations'])
assert {'cjy-Hans','cjy-Hant','gan-Hans','gan-Hant','czo-Hans','czo-Hant','cpx-Hans','cpx-Hant','cnp-Hans','cnp-Hant','csp-Hans','csp-Hant'}.issubset(codes)
print('languages',len(d['languages']),'locations',len(d['locations']),'version',d['version'])
"
```

預期：`languages 77 locations 63 version 4`。

- [ ] **Step 6: Commit**

```bash
git add scripts/v2/language_seed_profiles.json scripts/v2/test_language_data.py
git commit -m "feat: register the remaining Chinese variety languages

Adds Jin, Gan, Min Zhong, Pu-Xian and the two Pinghua lects to the seed.
They were the Chinese varieties still missing from the registry, so the
language list now covers every major Mandarin sibling dialect group."
```

---

## Task 3: 重新產製 registry artifacts

**Files:**
- Modify: `scripts/v2/artifacts/language-registry-5.3/languages.csv`
- Modify: `scripts/v2/artifacts/language-registry-5.3/language-locations.csv`
- Modify: `scripts/v2/artifacts/language-registry-5.3/language-registry.sql`
- Modify: `scripts/v2/artifacts/language-registry-5.3/manifest.json`
- Modify: `scripts/v2/artifacts/language-registry-5.3/online-code-migrations.json`（內容不變，sync 重寫）

- [ ] **Step 1: 重跑 sync**

```bash
cd scripts/v2 && python3 sync_language_registry.py --offline \
  --output artifacts/language-registry-5.3 \
  --profiles language_seed_profiles.json 2>&1 | tail -8
```

預期：`generation` 顯示 `"profile_version": 4`、`"language_tag_count": 77`、`"language_location_count": 63`。

- [ ] **Step 2: 驗證產出內容**

```bash
grep -n "^cjy-\|^gan-\|^czo-\|^cpx-\|^cnp-\|^csp-" scripts/v2/artifacts/language-registry-5.3/languages.csv
grep -n "jiny1235\|ganc1239\|minz1235\|puxi1243\|nort3268\|sout3250" scripts/v2/artifacts/language-registry-5.3/language-locations.csv
```

預期：`languages.csv` 有 12 列新 code（各含正確的 `name`、`name_en`、`glottocode`）；`language-locations.csv` 有 6 列新城市（Taiyuan、Nanchang、Sanming、Putian、Guilin、Nanning，皆 `CN`/`Hans`）。

- [ ] **Step 3: 確認測試仍通過**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -5
```

預期：`Ran 33 tests`、`OK`。

- [ ] **Step 4: Commit**

```bash
git add scripts/v2/artifacts/language-registry-5.3/
git commit -m "chore: regenerate language registry artifacts with Chinese varieties"
```

---

## Task 4: 手術式套用本地 D1

**Files:** 無檔案變更（僅本地狀態）

本任務只改本地 D1 狀態，不產生 commit。`.wrangler/` 是本地狀態，不進版控。

- [ ] **Step 1: 套用 registry SQL**

`language-registry.sql` 是純 upsert（languoids/language_subtags/languages/language_locations），不觸及 `expressions` 與 FTS，不需 drop-FTS。Worker 正在 `127.0.0.1:8788` 執行也無妨（SQLite WAL 允許外部寫入）。

```bash
export DB="./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite"
sqlite3 "$DB" < scripts/v2/artifacts/language-registry-5.3/language-registry.sql
echo "exit=$?"
```

預期：`exit=0`，無錯誤輸出。

- [ ] **Step 2: 驗證 DB 狀態**

```bash
export DB="./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite"
sqlite3 "$DB" "SELECT COUNT(*) FROM languages; SELECT COUNT(*) FROM language_locations;"
sqlite3 "$DB" "SELECT code, name, name_en, glottocode FROM languages WHERE code LIKE 'cjy%' OR code LIKE 'gan%' OR code LIKE 'czo%' OR code LIKE 'cpx%' OR code LIKE 'cnp%' OR code LIKE 'csp%' ORDER BY code;"
sqlite3 "$DB" "SELECT variety_key, city_name, territory_code, script_code FROM language_locations WHERE variety_key IN ('glotto:jiny1235','glotto:ganc1239','glotto:minz1235','glotto:puxi1243','glotto:nort3268','glotto:sout3250') ORDER BY variety_key;"
sqlite3 "$DB" "PRAGMA foreign_key_check;"
```

驗收條件：

- `languages` 77、`language_locations` 63
- 12 列新語言 code 存在且名稱正確
- 6 列新城市存在，皆 `CN`/`Hans`
- `foreign_key_check` 無輸出

- [ ] **Step 3: 執行 local verify（選用）**

```bash
cd scripts/db && python3 manage.py local verify 2>&1 | tail -15
```

當前 DB 已是乾淨 seed 狀態（62 seed + 3 system = 65，無測試殘留），套用後預期 `languages`（77）與 `language_locations`（63）兩項對齊。若仍出現既有測試殘留 mismatch，屬已知現象，不要為通過而改動被測邏輯。

> 注意：本步依賴 wrangler 本地 D1 可被管理腳本定位；若因環境問題無法執行，跳過並說明，不阻塞本計畫其餘驗證。

---

## Task 5: API 與瀏覽器驗證

**Files:** 無檔案變更

Worker 需在 `127.0.0.1:8788` 執行（`./dev.sh` 或既有 session）。

- [ ] **Step 1: 驗證 API 回應**

```bash
for code in cjy-Hans cjy-Hant gan-Hans gan-Hant czo-Hans czo-Hant cpx-Hans cpx-Hant cnp-Hans cnp-Hant csp-Hans csp-Hant; do
  curl -s "http://127.0.0.1:8788/api/v2/languages/$code" | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
print(d['code'], d['name'], 'ex:', d['expression_count'], 'cities:', [(c['city_name'],c['territory_code']) for c in d['representative_cities']])
"
done
```

預期：

- 12 筆全回 200，`expression_count` 為 0
- Hans 各筆顯示對應代表城市：`cjy-Hans`→Taiyuan、`gan-Hans`→Nanchang、`czo-Hans`→Sanming、`cpx-Hans`→Putian、`cnp-Hans`→Guilin、`csp-Hans`→Nanning
- Hant 各筆 `representative_cities` 為空（與既有 `wuu-Hant` 等行為一致）

- [ ] **Step 2: 瀏覽器版面抽查**

用 headless Chrome + CDP 取 `/languages` 頁面文字，確認 12 個新條目出現：

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --remote-debugging-port=9224 about:blank &
```

用 Node 22 內建全域 `WebSocket`（不要 import "ws"，未安裝）連 CDP，`Runtime.evaluate` 讀 `/languages` 的 `document.body.innerText`，確認出現「晋语／晉語」「赣语／贛語」「闽中语／閩中語」「莆仙话／莆仙話」「桂北平话／桂南平话」等條目。

驗證後務必清理：

```bash
pkill -f "remote-debugging-port=9224"
```

- [ ] **Step 3: 執行前端建置（視需要）**

前端無改動，僅確認既有建置不受影響：

```bash
cd web && npm run build 2>&1 | tail -5
```

---

## Task 6: 更新設計文件狀態

**Files:**
- Modify: `docs/superpowers/specs/2026-08-02-add-chinese-varieties-design.md:4`

- [ ] **Step 1: 更新狀態列**

第 4 行 `> 狀態：已設計、待實作` 改為 `> 狀態：已實作`。

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-08-02-add-chinese-varieties-design.md
git commit -m "docs: mark the Chinese varieties design as implemented"
```

---

## 完成後檢查

- `language_seed_profiles.json`：`version` 4、`languages` 77、`locations` 63
- `manifest.json`：`language_tag_count` 77、`language_location_count` 63、`profile_version` 4
- `/languages` 列出 12 個新條目，各自 0 expressions
- `/language/<code>` 詳情可開，Hans 各筆代表城市正確，Hant 各筆無城市（符合既有模式）
- `languages` / `language_locations` 表計數與 manifest 一致，`foreign_key_check` 無輸出
- 未新增 migration 檔案、未改動 `backend/` 與 `web/src/` 邏輯
