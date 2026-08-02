# 華語內容標籤遷移實作計畫（zh-* → cmn-*）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把華語內容標籤從 macrolanguage `zh-*` 遷移到精確的 `cmn-*`，並修正代表城市與顯示名稱。

**Architecture:** 資料源改 `language_seed_profiles.json` → 重跑 sync 產製 artifacts → 新增 D1 migration 搬遷 523 條 expressions 與 ui_locales → 前端加入 `zh-*` 入站別名層維持瀏覽器語系協商 → i18n 資源檔更名。

**Tech Stack:** Python 3（sync/測試）、SQLite/D1、Hono + TypeScript、Vue 3 + vue-i18n、Vitest。

**Spec:** `docs/superpowers/specs/2026-08-02-mandarin-cmn-migration-design.md`

## 前置事實（已驗證，勿再假設）

- 本地 D1 路徑：`./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite`。以下用 `$DB` 代稱，每個 task 需自行 export。
- `sqlite3` 可直接用。sync 指令需 `--offline`（raw 快取已存在，無需連網）。
- 遷移前基準：`expressions` 有 `zh-Hans` 262 條、`zh-Hant` 261 條；`languages` 有 `zh-Hans`/`zh-Hant` 兩列；`ui_locales` 有 `zh-Hans`/`zh-Hant` 兩列；`language_locations` 的 `glotto:mand1415` 有 Beijing(Hans)、Hong Kong(Hant)、Taipei(Hant)。
- `language_locations` 無 `language_code` 欄，靠 `variety_key` + `script_code` 軟關聯，不需在 SQL migration 處理。
- `ui_locales.code REFERENCES languages(code)`，故刪 `languages` 舊列前必須先搬 `ui_locales`。
- `backend/migrations/0012_canonicalize_language_content_profiles.sql` 是同型遷移的可用範本。
- registry SQL 是純 upsert，**不會刪除** seed 中已移除的條目。

---

## Task 1: seed profiles 改用 cmn-* 並修正城市

**Files:**
- Modify: `scripts/v2/language_seed_profiles.json`
- Test: `scripts/v2/test_language_data.py`

- [ ] **Step 1: 更新測試預期的 code 集合**

`scripts/v2/test_language_data.py` 第 338 行，把 `"zh-Hans", "zh-Hant",` 改為 `"cmn-Hans", "cmn-Hant",`。

第 346 行的 `isdisjoint` 斷言維持不動（`zh-Hans-CN`、`zh-Hant-TW` 等帶 region 的舊 code 本就該不存在）。

- [ ] **Step 2: 執行測試確認失敗**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -20
```

預期：`test_seed_profiles_do_not_use_regions_as_language_geography` FAIL，因為 seed 還是 `zh-*`。

- [ ] **Step 3: 改 seed 的 languages 兩列**

`scripts/v2/language_seed_profiles.json` 第 22-23 行，整行替換為：

```json
    {"code": "cmn-Hans", "name": "华语", "name_en": "Mandarin Chinese (Simplified)", "glottocode": "mand1415", "origin": "seed", "reason": "major-east-asia-language", "alternate_names": ["普通话", "国语", "汉语"]},
    {"code": "cmn-Hant", "name": "華語", "name_en": "Mandarin Chinese (Traditional)", "glottocode": "mand1415", "origin": "seed", "reason": "major-east-asia-language", "alternate_names": ["國語", "漢語"]},
```

`cmn-Hans` 主名用「华语」而非「普通话」，因為它同時涵蓋中國大陸與新加坡；「普通话」專指大陸標準語，會對新加坡使用者貼錯標籤。

- [ ] **Step 4: 改 mappings**

同檔 `online_code_migrations.mappings` 中，第 85-88 行四筆的 canonical 改指 `cmn-*`，並新增 `zh-Hans`/`zh-Hant` 兩筆。整段替換為：

```json
      "zh-Hans": {"action": "canonicalize", "canonical": "cmn-Hans"},
      "zh-Hant": {"action": "canonicalize", "canonical": "cmn-Hant"},
      "zh-Hans-CN": {"action": "canonicalize", "canonical": "cmn-Hans"},
      "zh-Hant-TW": {"action": "canonicalize", "canonical": "cmn-Hant"},
      "zh-Hant-HK": {"action": "canonicalize", "canonical": "cmn-Hant"},
      "zh-Hant-MO": {"action": "canonicalize", "canonical": "cmn-Hant"},
```

舊 code 必須留在 mappings，否則 `language_migration.validate_manifest` 會報 unmapped observed codes。多筆指向同一 canonical 時，全部都要是 `canonicalize` action 才合法。

- [ ] **Step 5: 改 locations**

同檔 `locations` 陣列中 `glotto:mand1415` 的三列，替換為：

```json
    {"variety_key":"glotto:mand1415","city_name":"Beijing","city_name_en":"Beijing","territory_code":"CN","script_code":"Hans","latitude":39.9042,"longitude":116.4074,"reference":"https://glottolog.org/resource/languoid/id/mand1415"},
    {"variety_key":"glotto:mand1415","city_name":"Singapore","city_name_en":"Singapore","territory_code":"SG","script_code":"Hans","latitude":1.3521,"longitude":103.8198,"reference":"https://glottolog.org/resource/languoid/id/mand1415"},
    {"variety_key":"glotto:mand1415","city_name":"Taipei","city_name_en":"Taipei","territory_code":"TW","script_code":"Hant","latitude":25.0330,"longitude":121.5654,"reference":"https://glottolog.org/resource/languoid/id/mand1415"},
```

即：新增 Singapore（簡體圈第二個探索點），移除 Hong Kong（原有的錯誤 —— 香港口語是粵語，`glotto:yuec1235` 已正確持有 Hong Kong 與 Macau）。

- [ ] **Step 6: 執行測試確認通過**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -5
```

預期：`Ran 29 tests`、`OK`。

- [ ] **Step 7: 確認 JSON 合法且計數正確**

```bash
python3 -c "
import json
d=json.load(open('scripts/v2/language_seed_profiles.json'))
codes={l['code'] for l in d['languages']}
assert 'cmn-Hans' in codes and 'cmn-Hant' in codes, 'cmn missing'
assert not {c for c in codes if c.startswith('zh')}, 'zh remains'
locs=[l for l in d['locations'] if l['variety_key']=='glotto:mand1415']
assert {l['city_name'] for l in locs}=={'Beijing','Singapore','Taipei'}, locs
print('languages',len(d['languages']),'locations',len(d['locations']))
"
```

預期：`languages 65 locations 57`（語言數不變，城市 +1 −1 = 57）。

- [ ] **Step 8: Commit**

```bash
git add scripts/v2/language_seed_profiles.json scripts/v2/test_language_data.py
git commit -m "refactor: use cmn instead of the zh macrolanguage for Mandarin

zh is a macrolanguage covering Yue, Min, Hakka and Wu, so tagging Mandarin
content with it is imprecise. The registry already pointed both entries at
glotto:mand1415, and the language-codes spec asked for cmn all along.

Naming follows self-reference, which tracks polity rather than script: both
entries read 華語/华语 because cmn-Hans covers Singapore as well as the
mainland, where 普通话 would mislabel Singaporean users. Hong Kong moves out
of Mandarin's exploration points since the city speaks Cantonese, which
glotto:yuec1235 already covers."
```

---

## Task 2: sync 腳本支援 alternate_names

**Files:**
- Modify: `scripts/v2/sync_language_registry.py:313`
- Test: `scripts/v2/test_language_data.py`

- [ ] **Step 1: 寫失敗測試**

在 `scripts/v2/test_language_data.py` 的 `LanguageDataTests` 類別中新增下列測試。它沿用該檔既有的 fixture 模式（參考 `test_seed_profiles_are_the_only_generated_languages`，第 142-187 行），用自建 profiles 而非讀真實 seed，以隔離測試對象：

```python
    def test_seed_alternate_names_reach_the_registry_rows(self):
        languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: cmn
Description: Mandarin Chinese
Added: 2005-10-16
%%
Type: language
Subtag: ja
Description: Japanese
Added: 2005-10-16
%%
Type: script
Subtag: Hans
Description: Han (Simplified variant)
Added: 2005-10-16
""")
        profiles = {
            "version": 3,
            "languages": [
                {
                    "code": "cmn-Hans",
                    "name": "华语",
                    "name_en": "Mandarin Chinese (Simplified)",
                    "glottocode": "mand1415",
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                    "alternate_names": ["普通话", "国语", "汉语"],
                },
                {
                    "code": "ja",
                    "name": "日本語",
                    "name_en": "Japanese",
                    "glottocode": None,
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                },
            ],
        }
        rows = {
            row["code"]: row
            for row in seed_language_rows(
                profiles, subtags, {row.glottocode: row for row in languoids}
            )
        }

        self.assertEqual(
            json.loads(rows["cmn-Hans"]["alternate_names_json"]),
            ["普通话", "国语", "汉语"],
        )
        self.assertEqual(json.loads(rows["ja"]["alternate_names_json"]), [])

    def test_real_seed_carries_mandarin_alternate_names(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        by_code = {profile["code"]: profile for profile in profiles["languages"]}

        self.assertIn("普通话", by_code["cmn-Hans"]["alternate_names"])
        self.assertIn("國語", by_code["cmn-Hant"]["alternate_names"])
```

`seed_language_rows(profiles, subtags, languoids_by_code)` 需要三個實參，`subtags` 必須包含用到的 language 與 script subtag，否則 `canonical_seed_code` 會拒絕該 code。`mand1415` 存在於 `fixtures/glottolog-mini.csv`。

- [ ] **Step 2: 執行測試確認失敗**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -20
```

預期：FAIL，`cmn-Hans` 的 `alternate_names_json` 為 `[]` 而非預期陣列（第 313 行硬編碼）。

- [ ] **Step 3: 改 sync 腳本讀取 seed 欄位**

`scripts/v2/sync_language_registry.py` 第 313 行：

```python
            "alternate_names_json": "[]",
```

改為：

```python
            "alternate_names_json": json.dumps(
                entry.get("alternate_names") or [], ensure_ascii=False, separators=(",", ":")
            ),
```

`ensure_ascii=False` 是必要的，否則中文會被轉成 `\uXXXX` 逸出序列，寫進 CSV 與 SQL 後難以閱讀與比對。

- [ ] **Step 4: 執行測試確認通過**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -5
```

預期：`Ran 31 tests`、`OK`（Task 2 新增兩項測試）。

- [ ] **Step 5: Commit**

```bash
git add scripts/v2/sync_language_registry.py scripts/v2/test_language_data.py
git commit -m "feat: carry seed alternate names into the language registry

The registry hardcoded an empty array, so alternate names had nowhere to
live. Mandarin needs it: picking a polity-neutral display name would
otherwise discard 普通话 and 國語, which are the names most speakers use."
```

---

## Task 3: 重新產製 registry artifacts

**Files:**
- Modify: `scripts/v2/artifacts/language-registry-5.3/languages.csv`
- Modify: `scripts/v2/artifacts/language-registry-5.3/language-locations.csv`
- Modify: `scripts/v2/artifacts/language-registry-5.3/language-registry.sql`
- Modify: `scripts/v2/artifacts/language-registry-5.3/manifest.json`
- Modify: `scripts/v2/artifacts/language-registry-5.3/online-code-migrations.json`

- [ ] **Step 1: 重跑 sync**

```bash
cd scripts/v2 && python3 sync_language_registry.py --offline \
  --output artifacts/language-registry-5.3 \
  --profiles language_seed_profiles.json 2>&1 | tail -8
```

預期尾段 `generation` 顯示 `"language_tag_count": 65`、`"language_location_count": 57`。

`--offline` 使用既有 raw 快取（glottolog zip 與 IANA txt），不需連網。

- [ ] **Step 2: 驗證產出內容**

```bash
grep -n "^cmn-" scripts/v2/artifacts/language-registry-5.3/languages.csv
grep -c "^zh-" scripts/v2/artifacts/language-registry-5.3/languages.csv || true
grep -n "mand1415" scripts/v2/artifacts/language-registry-5.3/language-locations.csv
```

預期：`cmn-Hans`、`cmn-Hant` 兩列存在且含中文別名；無 `zh-` 開頭列（`grep -c` 回 0）；locations 三列為 Beijing、Singapore、Taipei，無 Hong Kong。

- [ ] **Step 3: 確認測試仍通過**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -5
```

預期：`OK`。

- [ ] **Step 4: Commit**

```bash
git add scripts/v2/artifacts/language-registry-5.3/
git commit -m "chore: regenerate language registry artifacts for cmn migration"
```

---

## Task 4: 撰寫 D1 migration

**Files:**
- Create: `backend/migrations/0015_migrate_mandarin_content_tags.sql`
- Create: `backend/migrations/0015_migrate_mandarin_content_tags.meta.json`
- Reference: `backend/migrations/0012_canonicalize_language_content_profiles.sql`

**SQL 由你自行撰寫**，以 `0012_canonicalize_language_content_profiles.sql` 為結構範本。該檔已完成同型遷移（region 後綴清除），把它讀完再動手；本任務的差異只在映射內容是 `zh-Hans` → `cmn-Hans`、`zh-Hant` → `cmn-Hant` 兩筆。

- [ ] **Step 1: 讀範本並記錄基準狀態**

```bash
sed -n '1,60p' backend/migrations/0012_canonicalize_language_content_profiles.sql
export DB="./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite"
sqlite3 "$DB" "SELECT language_code, COUNT(*) FROM expressions WHERE language_code LIKE 'zh%' GROUP BY 1;"
sqlite3 "$DB" "SELECT code, native_name FROM ui_locales WHERE code LIKE 'zh%';"
```

預期基準：`zh-Hans|262`、`zh-Hant|261`；`ui_locales` 有 `zh-Hans|简体中文`、`zh-Hant|繁體中文`。

- [ ] **Step 2: 撰寫 migration SQL**

必須涵蓋的操作，順序不可調換（FK 約束所致）：

1. `PRAGMA defer_foreign_keys = ON`
2. temp table 記錄兩筆映射（含 `base_language='cmn'`、`script_code`、`region_code=''`）
3. `INSERT OR IGNORE INTO languages` 建立 `cmn-*` 目標列，**在搬動任何 FK 引用之前**
4. 合併 `ui_locales`（`INSERT ... ON CONFLICT(project_id, code) DO UPDATE`），並更新指向舊 code 的 `fallback_code`，然後刪除舊 locale 列
5. `UPDATE expressions SET language_code`
6. 重算 `language_stats`
7. `DELETE FROM languages` 舊 code
8. temp table + `CHECK (ok = 1)` 收尾驗證：`expressions`、`ui_locales`、`language_stats` 皆無殘留 `zh-*`，且 `pragma_foreign_key_check` 為空
9. `DROP` 所有 temp table

額外要求（`0012` 沒有、本任務需自行加入）：

- `ui_locales.native_name` 需更新為 `cmn-Hans` → `华语`、`cmn-Hant` → `華語`（現值為「简体中文」「繁體中文」）。`languages` 的 `name` 由後續 registry SQL upsert 覆蓋，但 `ui_locales.native_name` 不在 registry 範圍內，必須在此處理。
- migration 必須可重複執行（rerunnable）。舊 code 已不存在時所有語句應為 no-op，不得報錯。

- [ ] **Step 3: 撰寫 meta.json**

比照 `0012_canonicalize_language_content_profiles.meta.json` 的欄位結構（`preflight`、`postflight`、`reversible`）。內容需反映本次遷移的檢查點：preflight 確認舊 code 覆蓋於 mappings、postflight 確認無孤兒引用且 canonical 目標存在。`reversible` 為 `true`（一對一映射，反向無資料損失）。

- [ ] **Step 4: 在 DB 副本上試跑**

不要直接動主 DB。先複製再套用，確認無誤後才在 Task 5 正式套用：

```bash
cp "$DB" /tmp/langmap-migration-test.sqlite
sqlite3 /tmp/langmap-migration-test.sqlite < backend/migrations/0015_migrate_mandarin_content_tags.sql
echo "exit=$?"
```

預期：`exit=0`，無錯誤輸出。若 `CHECK (ok = 1)` 觸發，會出現 constraint failed，表示驗證條件未滿足。

- [ ] **Step 5: 驗證副本結果**

```bash
sqlite3 /tmp/langmap-migration-test.sqlite "SELECT language_code, COUNT(*) FROM expressions WHERE language_code LIKE 'cmn%' OR language_code LIKE 'zh%' GROUP BY 1;"
sqlite3 /tmp/langmap-migration-test.sqlite "SELECT code, native_name FROM ui_locales ORDER BY code;"
sqlite3 /tmp/langmap-migration-test.sqlite "SELECT code, name FROM languages WHERE code LIKE 'cmn%' OR code LIKE 'zh%';"
sqlite3 /tmp/langmap-migration-test.sqlite "PRAGMA foreign_key_check;"
```

驗收條件（全部必須成立）：

- `expressions` 僅 `cmn-Hans|262`、`cmn-Hant|261`，無 `zh-*`
- `ui_locales` 含 `cmn-Hans|华语`、`cmn-Hant|華語`，無 `zh-*`
- `languages` 含 `cmn-Hans`、`cmn-Hant`，無 `zh-*`
- `PRAGMA foreign_key_check` 無輸出

- [ ] **Step 6: 驗證可重複執行**

```bash
sqlite3 /tmp/langmap-migration-test.sqlite < backend/migrations/0015_migrate_mandarin_content_tags.sql
echo "rerun-exit=$?"
sqlite3 /tmp/langmap-migration-test.sqlite "SELECT language_code, COUNT(*) FROM expressions WHERE language_code LIKE 'cmn%' GROUP BY 1;"
```

預期：`rerun-exit=0`，且計數仍為 `cmn-Hans|262`、`cmn-Hant|261`（未重複計算或遺失）。

- [ ] **Step 7: 清除暫存檔**

```bash
rm -f /tmp/langmap-migration-test.sqlite
```

- [ ] **Step 8: Commit**

```bash
git add backend/migrations/0015_migrate_mandarin_content_tags.sql backend/migrations/0015_migrate_mandarin_content_tags.meta.json
git commit -m "feat: migrate stored Mandarin content tags from zh to cmn

Moves the 523 stored expressions, UI locale rows and statistics onto the
precise cmn tags. UI locale native names move with them so the language
picker stops showing 简体中文/繁體中文 for what is really Mandarin."
```

---

## Task 5: 套用到本地 D1

**Files:** 無檔案變更（僅本地狀態）

本任務只改本地 D1 狀態，不產生 commit。`.wrangler/` 是本地狀態，不進版控。

- [x] **Step 1: 套用 migration**

**先備份，再用 drop-FTS 手術式套用（`sqlite3` 直載）**。本檔原註記「`wrangler d1 migrations apply` 走 D1 引擎，不受 FTS 阻擋」是**錯的**：wrangler **本地** miniflare D1 也擋 FTS 虛擬表寫入（`SQLITE_AUTH`，trusted_schema 限制），`0015` 的 `UPDATE expressions` 經 `expressions_au` 觸發器寫入 `expressions_fts` 會失敗。`--remote` 才不受限，所以此流程只影響本地。

```bash
export DB="./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite"
cp "$DB" /tmp/langmap-pre-0015-backup.sqlite
sqlite3 "$DB" "DROP TRIGGER IF EXISTS expressions_ai; DROP TRIGGER IF EXISTS expressions_ad; DROP TRIGGER IF EXISTS expressions_au; DROP TABLE IF EXISTS expressions_fts;"
sqlite3 "$DB" < backend/migrations/0015_migrate_mandarin_content_tags.sql   # exit=0
sqlite3 "$DB" "CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(text, content='expressions', content_rowid='id', tokenize='unicode61');
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); END;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
INSERT INTO expressions_fts(rowid, text) SELECT id, text FROM expressions;"
sqlite3 "$DB" "INSERT INTO d1_migrations (name) VALUES ('0015_migrate_mandarin_content_tags.sql');"
```

此模式與 `scripts/v2/migrate.sh` 的 `drop_fts`/`rebuild_fts` 一致（該腳本第 145-158 行）。`0015` 只改 `language_code`，FTS 只存 `text`，故 drop 期間的更新不影響索引內容；重建時重新 populate。

**不要走 `manage.sh local rebuild`**：重建流程（`scripts/db/lib/local.py:59-62`）只載入 schema + registry + system-ui，**會清空全部 expressions**（1319 列），且 `scripts/v2/v2-data.sql` 內是未正規化的 `zh-TW`/`zh-CN` 舊碼，無法還原當前正規化狀態。

`manage.sh local verify` 的 languages 計數 mismatch（65 vs 77）與孤兒語言為 **0015 前即存在**（v2-data.sql 遺留的 `en-x-*`、`fa`、`mn-*`、`und` 等），與本次遷移無關；translation mappings 與 active locale mismatch 則在 Task 7 重新產製 system-ui artifacts 後清除。

- [ ] **Step 2: 套用 registry SQL**

registry SQL 是純 upsert，負責寫入 `cmn-*` 的 curated 名稱、`alternate_names_json` 與城市列。

```bash
export DB="./backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/bd307851d5b3a26cc62a7676aaddf233be3dd42df75be4ee22cccb6a574322c2.sqlite"
sqlite3 "$DB" < scripts/v2/artifacts/language-registry-5.3/language-registry.sql
echo "exit=$?"
```

- [ ] **Step 3: 手動清除已移除的城市**

registry SQL 是純 upsert，**不會刪除** seed 中已移除的條目。Hong Kong 需手動清除：

```bash
sqlite3 "$DB" "DELETE FROM language_locations WHERE variety_key='glotto:mand1415' AND territory_code='HK';"
sqlite3 "$DB" "SELECT city_name, territory_code, script_code FROM language_locations WHERE variety_key='glotto:mand1415' ORDER BY script_code, city_name;"
```

預期：`Beijing|CN|Hans`、`Singapore|SG|Hans`、`Taipei|TW|Hant`。

- [ ] **Step 4: 全面驗證 DB 狀態**

```bash
sqlite3 "$DB" "SELECT code, name, alternate_names_json FROM languages WHERE code LIKE 'cmn%';"
sqlite3 "$DB" "SELECT COUNT(*) FROM languages WHERE code LIKE 'zh%';"
sqlite3 "$DB" "SELECT language_code, COUNT(*) FROM expressions WHERE language_code LIKE 'cmn%' GROUP BY 1;"
sqlite3 "$DB" "PRAGMA foreign_key_check;"
```

驗收條件：

- `cmn-Hans|华语|["普通话","国语","汉语"]`、`cmn-Hant|華語|["國語","漢語"]`
- `zh%` 計數為 `0`
- `cmn-Hans|262`、`cmn-Hant|261`
- `foreign_key_check` 無輸出

- [ ] **Step 5: 驗證 API 回應**

Worker 需在 `127.0.0.1:8788` 執行（`./dev.sh` 或既有 session）。

```bash
curl -s "http://127.0.0.1:8788/api/v2/languages/cmn-Hant" | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
print(d['code'], d['name'], d['expression_count'])
print([(c['city_name'],c['territory_code']) for c in d['representative_cities']])
"
curl -s "http://127.0.0.1:8788/api/v2/languages/cmn-Hans" | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
print(d['code'], d['name'], d['expression_count'])
print([(c['city_name'],c['territory_code']) for c in d['representative_cities']])
"
curl -s -o /dev/null -w "zh-Hant status: %{http_code}\n" "http://127.0.0.1:8788/api/v2/languages/zh-Hant"
```

驗收條件：

- `cmn-Hant 華語 261`，城市 `[('Taipei','TW')]`
- `cmn-Hans 华语 262`，城市 `[('Beijing','CN'), ('Singapore','SG')]`
- 舊 `zh-Hant` 回 404

---

## Task 6: 前端 UI locale 別名層

**Files:**
- Modify: `web/src/locales/index.ts`
- Test: `web/src/locales/index.test.ts`

瀏覽器的 `Accept-Language` 與 `navigator.language` 只會送出 `zh-TW`、`zh-Hant`、`zh-CN` 等，**永不送 `cmn-*`**。若 `available` 僅剩 `cmn-*`，`resolveLocale` 的 fallback chain 無法命中，中文使用者會全部落到 `en`。此別名層是維持語系協商的必要條件。

- [ ] **Step 1: 寫失敗測試**

`web/src/locales/index.test.ts` 中，把既有的 `zh-hant-tw` 案例（第 10 行）改掉並新增別名案例。整個 `it` 區塊替換為：

```typescript
  it('canonicalizes tags and prefers an available exact casing', () => {
    expect(resolveLocale('cmn-hant', ['en-US', 'cmn-Hant'])).toBe('cmn-Hant')
    expect(resolveLocale('not a locale', ['en'])).toBe('en')
  })

  it('maps legacy zh macrolanguage tags onto the precise cmn locales', () => {
    const available = ['en', 'cmn-Hans', 'cmn-Hant']
    expect(resolveLocale('zh-Hant', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-hant-tw', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-TW', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-HK', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-MO', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-Hans', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh-CN', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh-SG', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh', available)).toBe('cmn-Hans')
  })

  it('leaves the zh alias inert when no cmn locale is available', () => {
    expect(resolveLocale('zh-Hant', ['en'])).toBe('en')
  })
```

- [ ] **Step 2: 執行測試確認失敗**

```bash
cd web && npx vitest run src/locales/index.test.ts 2>&1 | tail -25
```

預期：別名案例 FAIL（回傳 `zh-Hant` 而非 `cmn-Hant`）。

- [ ] **Step 3: 實作別名解析**

`web/src/locales/index.ts` 中，在 `resolveLocale` 之前新增別名表與解析函式：

```typescript
/**
 * Browsers only ever send the zh macrolanguage, never cmn, so inbound tags need
 * mapping onto the precise Mandarin locales or Chinese users fall back to English.
 */
const LEGACY_MANDARIN_ALIASES: Record<string, string> = {
  'zh': 'cmn-Hans',
  'zh-hans': 'cmn-Hans',
  'zh-cn': 'cmn-Hans',
  'zh-sg': 'cmn-Hans',
  'zh-my': 'cmn-Hans',
  'zh-hant': 'cmn-Hant',
  'zh-tw': 'cmn-Hant',
  'zh-hk': 'cmn-Hant',
  'zh-mo': 'cmn-Hant',
}

function mandarinAlias(locale: string): string | null {
  const lower = locale.toLowerCase()
  if (!lower.startsWith('zh')) return null
  for (const candidate of localeFallbackChain(lower)) {
    const alias = LEGACY_MANDARIN_ALIASES[candidate]
    if (alias) return alias
  }
  return null
}
```

然後在 `resolveLocale` 的 exact match 之後、fallback chain 之前插入別名查找。`resolveLocale` 的 `try` 區塊改為：

```typescript
  try {
    const canonical = Intl.getCanonicalLocales(value)[0]
    const alias = mandarinAlias(canonical)
    if (alias) {
      const aliased = available.find(code => code.toLowerCase() === alias.toLowerCase())
      if (aliased) return aliased
    }
    for (const candidate of localeFallbackChain(canonical)) {
      const availableCode = available.find(code => code.toLowerCase() === candidate.toLowerCase())
      if (availableCode) return availableCode
    }
    return canonical
  } catch {
    return DEFAULT_LOCALE
  }
```

別名只作用於入站解析，不進入 `available`；`localization` store 儲存與 `document.documentElement.lang` 一律為 canonical `cmn-*`，無需改動。`localeFallbackChain` 已能把 `zh-hant-tw` 降解為 `zh-hant`，故別名表不需列出帶 region 的每個組合。

- [ ] **Step 4: 執行測試確認通過**

```bash
cd web && npx vitest run src/locales/index.test.ts 2>&1 | tail -10
```

預期：全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add web/src/locales/index.ts web/src/locales/index.test.ts
git commit -m "feat: resolve legacy zh browser locales onto cmn

Browsers only send the zh macrolanguage, so dropping zh from the registry
would strand every Chinese visitor on English. Inbound zh tags now alias to
the matching cmn locale while stored state stays canonical."
```

---

## Task 7: i18n 資源檔更名

**Files:**
- Rename: `scripts/i18n/zh-Hans-CN.json` → `scripts/i18n/cmn-Hans.json`
- Rename: `scripts/i18n/zh-Hant-TW.json` → `scripts/i18n/cmn-Hant.json`
- Modify: `scripts/i18n/generate-bundle.py:21-22,26`
- Modify: `scripts/i18n/generate-i18n-sql.py:7,271`
- Modify: `scripts/i18n/README.md`
- Test: `scripts/i18n/test_generate_bundle.py`

舊檔名帶 region（`-CN`/`-TW`），bundle code 卻是 `zh-Hans`/`zh-Hant`，本來就不一致。改名時一併去掉 region，讓檔名等於 bundle code。

- [ ] **Step 1: 更新測試夾具**

`scripts/i18n/test_generate_bundle.py` 共 8 處引用需改（第 64、69、107、182-183、216、367、373、381、384 行）：

- 所有 `"zh-Hans"` → `"cmn-Hans"`、`"zh-Hant"` → `"cmn-Hant"`
- 第 182-183 行的 native_name 斷言改為 `("cmn-Hans", "华语", "ltr")`、`("cmn-Hant", "華語", "ltr")`
- 第 216 行的排序後清單改為 `["cmn-Hans", "cmn-Hant", "en", "es", "ja"]`（注意字母序：`cmn` 在 `en` 之前，與原本 `zh` 在最後相反）

- [ ] **Step 2: 執行測試確認失敗**

```bash
cd scripts/i18n && python3 -m unittest test_generate_bundle 2>&1 | tail -20
```

預期：FAIL，因腳本仍使用 `zh-*` code。

- [ ] **Step 3: 更名檔案**

```bash
git mv scripts/i18n/zh-Hans-CN.json scripts/i18n/cmn-Hans.json
git mv scripts/i18n/zh-Hant-TW.json scripts/i18n/cmn-Hant.json
```

- [ ] **Step 4: 更新腳本引用**

`scripts/i18n/generate-bundle.py` 第 21-22 行的 `DEFAULT_LOCALE_PATHS` 兩筆改為：

```python
    'cmn-Hans': PROJECT_ROOT / 'scripts/i18n/cmn-Hans.json',
    'cmn-Hant': PROJECT_ROOT / 'scripts/i18n/cmn-Hant.json',
```

第 26 行 `REQUIRED_LOCALE_CODES` 改為（保持字母序）：

```python
REQUIRED_LOCALE_CODES = ('cmn-Hans', 'cmn-Hant', 'es', 'ja')
```

`scripts/i18n/generate-i18n-sql.py` 第 7 行與第 271 行的 usage 範例路徑，`zh-Hant scripts/i18n/zh-Hant-TW.json` 改為 `cmn-Hant scripts/i18n/cmn-Hant.json`。

`scripts/i18n/README.md` 第 6-7、29-30、67 行的檔名與 code 一併更新。

- [ ] **Step 5: 執行測試確認通過**

```bash
cd scripts/i18n && python3 -m unittest test_generate_bundle 2>&1 | tail -5
```

預期：`OK`。

- [ ] **Step 6: 重新產製 i18n artifacts**

```bash
cd scripts/i18n && python3 generate-bundle.py 2>&1 | tail -10
grep -c "cmn-Han" artifacts/system-ui/system-ui.sql
grep -c "zh-Han" artifacts/system-ui/system-ui.sql || true
```

預期：`cmn-Han` 有多筆命中；`zh-Han` 命中數為 0。若 `generate-bundle.py` 需要參數，先跑 `python3 generate-bundle.py --help` 確認。

- [ ] **Step 7: Commit**

```bash
git add scripts/i18n/
git commit -m "refactor: rename UI translation catalogs from zh to cmn

The catalog filenames carried regions the bundle codes never used. Renaming
them alongside the cmn migration makes filename and bundle code agree."
```

---

## Task 8: 後端測試夾具

**Files:**
- Modify: `backend/tests/languageCode.test.ts:8-9`
- Modify: `backend/tests/localization.test.ts:7,30-38`

這兩處只是把示例標籤換成遷移後的形式，驗證的是 BCP 47 解析與 locale 回退邏輯本身，不是 `zh` 這個特定值。

- [ ] **Step 1: 改 languageCode.test.ts**

第 8-9 行替換為：

```typescript
    const cmnHant = parseStoredLanguageCode('cmn-Hant-TW');
    expect(cmnHant).toEqual({ code: 'cmn-Hant-TW', language: 'cmn', script: 'Hant', region: 'TW', variants: [], private_use: [] });
```

- [ ] **Step 2: 改 localization.test.ts**

第 7 行替換為：

```typescript
    expect(parentLocaleCodes('cmn-Hant-TW')).toEqual(['cmn-Hant', 'cmn']);
```

第 30-38 行的 `locale_code` 夾具，把 `zh-Hant` 改為 `cmn-Hant`、裸 `zh` 改為 `cmn`，並同步第 34 行與第 38 行的 `selectLocalizedRows` 呼叫參數：

```typescript
      { key: 'greeting', locale_code: 'cmn-Hant', text: '較早', score: 1, edge_created_at: '2026-01-01', target_id: 9 },
      { key: 'greeting', locale_code: 'cmn-Hant', text: '較高分', score: 5, edge_created_at: '2026-01-02', target_id: 8 },
      { key: 'farewell', locale_code: 'cmn', text: '再見', score: 0, edge_created_at: '2026-01-01', target_id: 7 },
```

第 34 行的期望呼叫改為 `selectLocalizedRows(rows, ["cmn-Hant", "cmn", "en"])`，第 36-38 行的 `zh-Hant` 同樣改 `cmn-Hant`、`["zh-Hant"]` 改 `["cmn-Hant"]`。斷言結果（`較高分`、`再見`、`先建`）維持不變。

- [ ] **Step 3: 執行後端測試**

後端整合測試依賴 `127.0.0.1:8788` 與本地 D1，執行前確認 Worker 已啟動。

```bash
cd backend && npm test 2>&1 | tail -25
```

預期：全部 PASS。若整合測試因 Worker 未啟動而失敗，先跑 `./dev.sh` 再重試；不要為了讓測試通過而改動被測邏輯。

- [ ] **Step 4: Commit**

```bash
git add backend/tests/languageCode.test.ts backend/tests/localization.test.ts
git commit -m "test: use cmn tags in language code and locale fixtures"
```

---

## Task 9: 前端其餘夾具與建置驗證

**Files:**
- Modify: `web/src/stores/localization.test.ts:11,13,33,38-40,47,49`
- Modify: `web/src/pages/Contribute.test.ts:60,63,72,83`
- Modify: `web/src/pages/TranslateWorkbench.language.test.ts:108,111`
- Modify: `web/src/locales/en.ts:173`

- [ ] **Step 1: 改 store 測試**

`web/src/stores/localization.test.ts` 中所有 `zh-Hans` 改為 `cmn-Hans`。第 11 行的 fixture 同時更新顯示名：

```typescript
    { code: 'cmn-Hans', name: 'Mandarin Chinese (Simplified)', native_name: '华语', status: 'active' },
```

- [ ] **Step 2: 改頁面測試**

`web/src/pages/Contribute.test.ts` 第 60、63、72、83 行的 `zh-Hans` 改 `cmn-Hans`。

`web/src/pages/TranslateWorkbench.language.test.ts` 第 108、111 行的 `zh-Hans-SG` 改 `cmn-Hans-SG`，對應路由斷言改 `/translate/cmn-Hans-SG`。

- [ ] **Step 3: 改 UI 提示文案**

`web/src/locales/en.ts` 第 173 行 `languageCodePlaceholder` 的 `e.g. en / zh-Hant` 改為 `e.g. en / cmn-Hant`。

對應的 `scripts/i18n/cmn-Hans.json`、`cmn-Hant.json`、`es-ES.json`、`ja-JP.json` 若含此 key 的翻譯且提到 `zh-Hant`，一併更新。先用 `grep -rn "zh-Hant" scripts/i18n/*.json` 確認。

- [ ] **Step 4: 執行前端測試與建置**

```bash
cd web && npx vitest run 2>&1 | tail -20
cd web && npm run build 2>&1 | tail -10
```

預期：測試全 PASS；建置成功無型別錯誤。

- [ ] **Step 5: Commit**

```bash
git add web/src
git commit -m "test: use cmn tags in web fixtures and code hint"
```

---

## Task 10: 規格修訂與全流程驗證

**Files:**
- Modify: `docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md:159`

- [ ] **Step 1: 修訂舊規格 L159**

該行原文規定 UI locale 沿用 `zh-Hant-TW` 生態系慣例，與本次廢除 `zh-*` 直接衝突。替換為：

```markdown
UI locale 與 expression content tag 都使用精確標籤，例如 `cmn-Hant`、`yue-Hant`。兩者都由同一 `languages` registry 驗證，但不要求 UI locale 與某段 expression 使用相同粒度。瀏覽器只會送出 `zh` macrolanguage 標籤，因此入站語系協商在 `web/src/locales/index.ts` 將 `zh-*` 別名解析到對應的 `cmn-*`；別名不進入 registry，也不作為可選語系對外顯示。
```

同時檢查 L75 與 L860 是否仍以 `zh-Hant-TW` 為例，若是則改為 `cmn-Hant`。用 `grep -n "zh-Hant-TW\|zh-Hans-CN" docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md` 定位。

L152 的範例表已經是 `cmn-Hant-TW`，無需改動 —— 本次遷移正是讓實作追上該行。

- [ ] **Step 2: 全量測試**

```bash
cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -3
cd scripts/i18n && python3 -m unittest test_generate_bundle 2>&1 | tail -3
cd backend && npm test 2>&1 | tail -10
cd web && npx vitest run 2>&1 | tail -5
```

預期：四項全部 `OK` / PASS。

- [ ] **Step 3: 全流程建置**

```bash
./build.sh 2>&1 | tail -15
```

預期：建置成功，web 產物寫入 `backend/public`。

- [ ] **Step 4: 殘留檢查**

```bash
grep -rn "zh-Hans\|zh-Hant" web/src backend/src backend/tests scripts/v2/language_seed_profiles.json scripts/i18n/*.py scripts/i18n/*.json 2>/dev/null
```

驗收條件：唯一允許的命中是 `web/src/locales/index.ts` 的 `LEGACY_MANDARIN_ALIASES` 別名表與 `index.test.ts` 的別名測試。其他任何命中都要處理。

歷史 migration `0007`、`0008`、`0012` 的 `zh-*` 引用**刻意保留**，不在檢查範圍 —— 它們記錄的是當時的狀態，改動會使既有部署的 migration 校驗不一致。

- [ ] **Step 5: 瀏覽器版面驗證**

因無法讀圖，用 headless Chrome + CDP 取數值。啟動：

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --remote-debugging-port=9223 about:blank &
```

用 Node 22 內建全域 `WebSocket`（**不要 import "ws"，未安裝**）連 CDP，`Runtime.evaluate` 讀取 `/languages` 與 `/language/cmn-Hant` 的 `document.body.innerText`，確認：

- `/languages` 出現「華語」「华语」，不出現「简体中文」「繁體中文」
- `/language/cmn-Hant` 標題為「華語」，代表城市僅 Taipei
- `/language/cmn-Hans` 代表城市為 Beijing 與 Singapore

驗證後務必清理：

```bash
pkill -f "remote-debugging-port=9223"
```

- [ ] **Step 6: Commit**

```bash
git add docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md
git commit -m "docs: align the language code spec with the cmn migration

The spec asked for cmn content tags but told UI locales to keep the zh
ecosystem convention. Since zh is now gone from the registry, the UI locale
rule moves to the inbound alias layer instead."
```

---

## 完成後檢查

- `languages` 表無任何 `zh%` code
- `expressions` 的 523 條華語詞句全在 `cmn-Hans` / `cmn-Hant`
- 瀏覽器送 `zh-TW` 仍能協商到 `cmn-Hant`
- `cmn-Hans` 代表城市含 Singapore，不含 Hong Kong
- `alternate_names_json` 保留「普通话」「國語」等各政體自稱
