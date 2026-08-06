# 語言變體與內容 Profile 分層模型實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把單一 `languages` 表拆成 `language_varieties`（使用者認知的語言／方言）與 `language_profiles`（精確 BCP 47 content tag）兩層，讓語言列表、詳情、搜尋與統計以 variety 聚合，詞句與 UI locale 仍綁定精確 profile。

**Architecture:** 資料源 `language_seed_profiles.json` 重寫成兩層 → `sync_language_registry.py` 改產兩表 CSV／SQL → `schema.sql` 換成兩表模型並重命名 `expressions.language_code`→`language_profile_code` → 新增 forward-only migration 0016 在既有 DB 上重建受影響表 → 後端 routes/services/types 改以 variety 為公開資源、profile 為精確查詢 → 前端 picker 改兩階段、列表／詳情改 variety 聚合 → 標記被取代的舊規格。

**Tech Stack:** SQLite/D1（schema + migration）、Python 3（registry sync／測試）、Hono + TypeScript（後端）、Vue 3 + Pinia + vue-i18n + Vitest（前端）。

**Spec:** `docs/superpowers/specs/2026-08-03-language-variety-profile-model-design.md`

## Global Constraints

來自 spec 的全專案限制，每個 task 隱含遵守：

- 專案尚未正式上線：**不**建立 alias、redirect、雙寫或長期 API 相容層（spec §4、§12）。
- variety 公開 code 優先使用精確 IANA language subtag（如 `cmn`、`yue`）；無專用 subtag 的具體變體用**不含 script** 的 private-use code（如 `nan-x-chao1238`）；code 不從 profile 即時截取、不含純書寫差異（spec §5.1）。
- `language_profiles.code` 是 canonical BCP 47 tag，原樣搬自舊 `languages.code`，建立後不可改（spec §5.2、§12.1.4）。
- variety 內部 ID 是 ULID 字串；外鍵用 ID，一般 API 與 URL 用 code（spec §5.1、§7.1、§9.1）。
- 每個 variety 至少一個 profile；建立 variety 與首個 profile 必須同一 transaction（spec §7.2、§8.2）。
- 回應格式維持 `{ success, data?, error?, message? }`；mutation 欄位 `language_code` 一律改為 `language_profile_code`（spec §9.3）。
- 不自動合併或轉換簡繁 expressions、不改變既有 mappings、不更動 `variation_status` 語義（spec §4、§11）。
- 新增中文文件與介面文案用傳承體中文；編輯既有內容沿用原語體（AGENTS.md）。
- 註釋只解釋 WHY，不重述程式碼（AGENTS.md）。

## 前置事實（已驗證，勿再假設）

- 本地 D1 狀態目錄：`backend/.wrangler/state`。重建走 `./dev.sh --rebuild`（執行 `schema.sql` → `language-registry.sql` → `system-ui.sql`，見 `scripts/db/lib/local.py:58-62`）。
- 指令：後端測試 `cd backend && npm test`（需先啟動 Worker 在 127.0.0.1:8788）；前端 build `cd web && npm run build`；registry sync `cd scripts/v2` 用 `--offline`。
- 現有 seed `scripts/v2/language_seed_profiles.json` 有 65 個 `languages` 條目、57 個 `locations`；`languages.code` 已是 canonical（0012/0015 已修正）。
- `expressions.id` 由 `expressionId(languageCode, text)` 雜湊決定（`backend/src/utils/ids.ts`）；profile code 值不變故 expression ID 不變，migration 不需重算 ID。
- `language_stats` 表**未被任何 route 讀取**（routes 都用 `SELECT COUNT(*) FROM expressions` 子查詢），可安全移除（spec §7.3）。
- `expression_versions`、`votes`、`expression_edges`、`handbooks*`、`ui_messages` 表**無** `language_code` 欄，不需改。
- `ui_locales.code` 保留（locale 自身 code），只改其 FK 目標到 `language_profiles.code`（spec §7.3）。
- `language_locations` 靠 `variety_key` 軟關聯；需重建為 `language_variety_id` FK（spec §7.3）。
- 既有可重用 migration 範本：`0010_rebuild_language_registry.sql`（重建 + rename 模式）、`0015_migrate_mandarin_content_tags.sql`（temp 對應表 + defer FK 模式）。
- 全 50 個 distinct 舊 `variety_key` 對應 49 個新 variety（`system:mn-Mong` 與 `system:mn-Cyrl` 合併為 variety `mn`）。

---

## Task 1: 新增 ULID 工具（後端）

variety 內部 ID 需為 ULID 字串（spec §7.1）。Workers 環境無 ULID library，寫一個純函式產生器，seed 與社群建立都會用到。

**Files:**
- Create: `backend/src/utils/ulid.ts`
- Test: `backend/src/utils/ulid.test.ts`

**Interfaces:**
- Produces: `ulid(timestampMs?: number): string`（26 字 Crockford base32）；`isUlid(value: string): boolean`；`seedVarietyId(varietyCode: string): string`（deterministic，固定 timestamp + sha256 衍生亂數，供 seed 產物可重現）。

- [ ] **Step 1: 寫失敗測試**

`backend/src/utils/ulid.test.ts`：

```ts
import { describe, expect, it } from 'vitest';
import { ulid, isUlid, seedVarietyId } from './ulid';

describe('ulid', () => {
  it('produces 26-char crockford-base32 strings', () => {
    const id = ulid(0);
    expect(id).toMatch(/^[0-9A-HJKMNP-TV-Z]{26}$/);
    expect(isUlid(id)).toBe(true);
  });

  it('is monotonically ordered by timestamp', () => {
    expect(ulid(1_700_000_000_000) < ulid(1_700_000_001_000)).toBe(true);
  });

  it('seedVarietyId is deterministic and distinct per code', () => {
    expect(seedVarietyId('cmn')).toBe(seedVarietyId('cmn'));
    expect(seedVarietyId('cmn')).not.toBe(seedVarietyId('yue'));
    expect(isUlid(seedVarietyId('cmn'))).toBe(true);
  });

  it('isUlid rejects malformed input', () => {
    expect(isUlid('not-a-ulid')).toBe(false);
    expect(isUlid('')).toBe(false);
  });
});
```

- [ ] **Step 2: 執行測試確認失敗**

Run: `cd backend && npx vitest run src/utils/ulid.test.ts`
Expected: FAIL（模組不存在）。

- [ ] **Step 3: 實作**

`backend/src/utils/ulid.ts`：ULID = 48-bit ms timestamp（10 chars）+ 80-bit randomness（16 chars），Crockford base32。`seedVarietyId` 用固定 epoch `1_753_987_200_000`（2026-08-01T00:00:00Z）+ `sha256("langmap-seed-variety:<code>")[:10]` 當 randomness，確保跨次產生一致。實作包含一個最小同步 SHA-256（`crypto.subtle.digest` 是 async，seed 生成路徑要同步可重現）。

API：

```ts
export function isUlid(value: string): boolean
export function ulid(timestampMs?: number): string  // crypto.getRandomValues for randomness
export function seedVarietyId(varietyCode: string): string
```

實作要點：
- `ENCODE = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'`（無 I/L/O/U）。
- `encodeTime(ts)`：10 chars，由低位往高位填，最後反轉。
- `encodeRandom(bytes: Uint8Array)`：把 10 bytes 當 80-bit big-endian bigint，每次取 `& 31` 得 5 bits，反轉成 16 chars。
- `sha256Sync`：FIPS 180-4，純 TS，回傳 32 bytes；`seedVarietyId` 只取前 10 bytes。

> 實作者請照上述 API 與要點寫出完整檔案；測試（Step 1）是驗收。同步 SHA-256 約 60 行，可參考任意標準實作，但需自包含（不引入新依賴）。

- [ ] **Step 4: 執行測試確認通過**

Run: `cd backend && npx vitest run src/utils/ulid.test.ts`
Expected: PASS（4 tests）。

- [ ] **Step 5: Commit**

```bash
git add backend/src/utils/ulid.ts backend/src/utils/ulid.test.ts
git commit -m "feat(backend): add ULID generator for variety IDs"
```

---

## Task 2: seed JSON 重寫成兩層 varieties + profiles

把 `language_seed_profiles.json` 從扁平 `languages[]` 改成 spec §8.1 的 `varieties[]`（每個 variety 攜帶 nested `profiles[]`、explicit `id` 與 `code`）。用一次性 generator（含完整 variety code 與名稱 curate 對應表）產生並 commit；generator 保留以便稽核。

**Files:**
- Modify: `scripts/v2/language_seed_profiles.json`（由 generator 重寫）
- Create: `scripts/v2/migrate_seed_to_varieties.py`（一次性產生器，含完整對應表）
- Test: `scripts/v2/test_language_data.py`

**Interfaces:**
- 產出 JSON shape（spec §8.1）：
  - `version: 5`
  - `varieties[]`：`{ id(ULID), code, name, name_en, glottocode|null, origin, reason, description, alternate_names[], profiles[] }`
  - 每個 `profiles[]` 元素：`{ code, name, name_en }`（name 是 script label 如「傳承體」，非 variety 名）
  - `locations[]`：`{ variety_code, city_name, city_name_en, territory_code, script_code, latitude, longitude, reference }`（`variety_key` 改 `variety_code`）
  - `online_code_migrations`：原樣保留（仍以 canonical profile code 為鍵）

- [ ] **Step 1: 寫 generator**

`scripts/v2/migrate_seed_to_varieties.py`：完整對應表如下（鍵為舊 variety_key，值為 `(new variety code, variety name, variety name_en)`）。`system:mn-Mong` 與 `system:mn-Cyrl` 兩鍵都指向 `mn`，合併成一個 variety。

```python
VARIETY_MAP = {
    "system:und": ("und", "Undetermined", "Undetermined"),
    "system:x-emoji": ("x-emoji", "Emoji 表情", "Emoji"),
    "system:x-image": ("x-image", "圖片", "Image"),
    "system:fa": ("fa", "فارسی", "Persian"),
    "system:mn-Mong": ("mn", "蒙古語", "Mongolian"),
    "system:mn-Cyrl": ("mn", "蒙古語", "Mongolian"),
    "system:za-Latn": ("za", "壯語", "Zhuang"),
    "glotto:stan1293": ("en", "English", "English"),
    "glotto:swah1253": ("swh", "Swahili", "Swahili"),
    "glotto:ralt1242": ("ral", "Raltic", "Raltic"),
    "glotto:yang1286": ("zyg", "Yangzhuang", "Yangzhuang"),
    "glotto:ouji1238": ("wuu-x-ouji1238", "溫州話", "Wenzhou (Oujiang)"),
    "glotto:taiz1238": ("wuu-x-taiz1238", "台州話", "Taizhou"),
    "glotto:chao1238": ("nan-x-chao1238", "潮州話", "Chaozhou (Teochew)"),
    "glotto:minn1241": ("nan", "閩南語", "Min Nan"),
    "glotto:mand1415": ("cmn", "華語", "Mandarin Chinese"),
    "glotto:stan1318": ("ar", "العربية", "Arabic"),
    "glotto:beng1280": ("bn", "বাংলা", "Bengali"),
    "glotto:stan1295": ("de", "Deutsch", "German"),
    "glotto:stan1288": ("es", "Español", "Spanish"),
    "glotto:stan1290": ("fr", "Français", "French"),
    "glotto:hind1269": ("hi", "हिन्दी", "Hindi"),
    "glotto:indo1316": ("id", "Bahasa Indonesia", "Indonesian"),
    "glotto:ital1282": ("it", "Italiano", "Italian"),
    "glotto:nucl1643": ("ja", "日本語", "Japanese"),
    "glotto:kore1280": ("ko", "한국어", "Korean"),
    "glotto:mara1378": ("mr", "मराठी", "Marathi"),
    "glotto:panj1256": ("pa", "ਪੰਜਾਬੀ", "Punjabi"),
    "glotto:port1283": ("pt", "Português", "Portuguese"),
    "glotto:russ1263": ("ru", "Русский", "Russian"),
    "glotto:thai1261": ("th", "ไทย", "Thai"),
    "glotto:nucl1301": ("tr", "Türkçe", "Turkish"),
    "glotto:urdu1245": ("ur", "اردو", "Urdu"),
    "glotto:viet1252": ("vi", "Tiếng Việt", "Vietnamese"),
    "glotto:wuch1236": ("wuu", "吳語", "Wu Chinese"),
    "glotto:yuec1235": ("yue", "粵語", "Cantonese"),
    "glotto:xian1251": ("hsn", "湘語", "Xiang Chinese"),
    "glotto:hakk1236": ("hak", "客家話", "Hakka"),
    "glotto:mind1253": ("cdo", "閩東語", "Min Dong"),
    "glotto:minb1236": ("mnp", "閩北語", "Min Bei"),
    "glotto:tibe1272": ("bo", "བོད་སྐད་", "Tibetan"),
    "glotto:uigh1240": ("ug", "ئۇيغۇرچە", "Uyghur"),
    "glotto:kaza1248": ("kk", "قازاق تىلى", "Kazakh"),
    "glotto:kirg1245": ("ky", "قىرعىز تىلى", "Kyrgyz"),
    "glotto:jiny1235": ("cjy", "晉語", "Jin Chinese"),
    "glotto:ganc1239": ("gan", "贛語", "Gan Chinese"),
    "glotto:minz1235": ("czo", "閩中語", "Min Zhong"),
    "glotto:puxi1243": ("cpx", "莆仙話", "Pu-Xian"),
    "glotto:nort3268": ("cnp", "桂北平話", "Northern Pinghua"),
    "glotto:sout3250": ("csp", "桂南平話", "Southern Pinghua"),
}
```

generator 邏輯：
1. 讀現有 JSON 的 `languages[]`，用 `old_variety_key(entry) = f"glotto:{gc}" if gc else f"system:{entry['code']}"` 分組。
2. 對 `VARIETY_MAP` 中每個 **distinct new variety code**（49 個）建一個 variety：把所有「`VARIETY_MAP[k][0] == vcode`」的舊分組的 profiles 聯集，依 `code` 排序。
3. variety 欄位：`id = seed_variety_id(vcode)`（Python 版，演算法與 Task 1 `seedVarietyId` 完全相同：固定 epoch + `sha256("langmap-seed-variety:"+code)[:10]`，Crockford base32）；`name/name_en` 取自 map；`glottocode` 取該 variety 任意一個 profile 的；`origin/reason` 取第一個；`alternate_names` 取聯集；`description=""`。
4. profile 欄位：`code` 原樣；`name/name_en` 用 `profile_label(code, fallback_name, fallback_name_en)`：
   - script 在 `{Hans:("簡體","Simplified"), Hant:("傳承體","Traditional"), Latn:("拉丁","Latin"), Cyrl:("西里爾","Cyrillic"), Arab:("阿拉伯文","Arabic"), Mong:("傳統蒙古文","Traditional Script"), Tibt:("藏文","Tibetan"), Guru:("古木奇文","Gurmukhi")}` 中 → 取對應；
   - 含 `Latn` 且不在上表（如 tailo/pehoeji）→ 用原 profile `name`／`name_en`；
   - 其他 → `("標準", name_en or "Default")`。
5. `locations`：每筆加 `variety_code = VARIETY_MAP[loc["variety_key"]][0]`，移除 `variety_key`。
6. `online_code_migrations`：原樣保留。
7. 輸出 `{version:5, varieties, locations, online_code_migrations}`，寫回 `language_seed_profiles.json`。
8. `__main__` 加斷言：`len(varieties)==49`、variety code 唯一、每個 variety 有 profiles。

Python `seed_variety_id` 需與 Task 1 TS 版 byte-for-byte 一致（固定 epoch + 同樣 sha256 prefix + 同樣 Crockford 編碼）。兩邊各跑 `seedVarietyId("cmn")`／`seed_variety_id("cmn")` 必須相等——在 Task 1 的測試裡可加一條固定快照斷言（見 Step 4）。

- [ ] **Step 2: 執行 generator 重寫 seed**

Run: `cd scripts/v2 && python3 migrate_seed_to_varieties.py`
Expected: `wrote 49 varieties, 57 locations`。

- [ ] **Step 3: 驗證新 JSON 結構**

Run:

```bash
python3 -c "
import json
d=json.load(open('scripts/v2/language_seed_profiles.json'))
assert d['version']==5
v={x['code']:x for x in d['varieties']}
assert len(v)==49
assert {p['code'] for p in v['cmn']['profiles']}=={'cmn-Hans','cmn-Hant'}
assert v['cmn']['name']=='華語'
assert all(len(p['id'])==26 for p in d['varieties'])
assert v['nan-x-chao1238']['glottocode']=='chao1238'
assert {p['code'] for p in v['mn']['profiles']}=={'mn-Mong','mn-Cyrl'}
assert 'variety_key' not in d['locations'][0]
assert all(l['variety_code'] in v for l in d['locations'])
print('seed OK')
"
```

Expected: `seed OK`。

- [ ] **Step 4: 在 Task 1 的 ulid 測試加快照**

`backend/src/utils/ulid.test.ts` 加一條，固定 `seedVarietyId('cmn')` 的期望值。先執行 `cd scripts/v2 && python3 -c "from migrate_seed_to_varieties import seed_variety_id; print(seed_variety_id('cmn'))"` 取得值，填入：

```ts
  it('seedVarietyId matches the Python seed generator snapshot', () => {
    expect(seedVarietyId('cmn')).toBe('<填入上一步 Python 輸出>');
  });
```

這確保後端 community ULID 演算法與 seed 已存在的 ID 使用同一編碼（社群建立用 `ulid()` 隨機，但編碼格式須一致；此快照驗證格式與 seed 對齊）。

- [ ] **Step 5: 改 test_language_data.py 對應新 shape**

`scripts/v2/test_language_data.py`：

1. 刪除 `test_language_schema_is_single_profile_table`（第 337-343 行）——schema 檢查改由 backend 整合測試接手。
2. `test_seed_profiles_do_not_use_regions_as_language_geography`（第 392 行）與 `test_seed_profiles_include_common_and_reviewed_variant_layers`（第 411 行）：把 `profiles["languages"]` 的 code 集合來源改為 `{p["code"] for v in profiles["varieties"] for p in v["profiles"]}`，斷言內容不變。
3. 新增 `test_seed_varieties_are_two_layer_and_profile_codes_unique`：斷言 variety code/id 唯一、每個 variety 有 profiles、variety name 不含 "Simplified"/"Traditional"、profile code 全站唯一、`cmn` 的 profiles 恰為 `{cmn-Hans, cmn-Hant}`。
4. `test_locations_are_validated_and_stably_sorted`（第 355 行）：location input 由 `{"variety_key":"glotto:yue", ...}` 改為 `{"variety_code":"yue", ...}`；`seed_location_rows` 第二參數由 `{"glotto:yue"}` 改為 `{"yue"}`（signature 將在 Task 3 改）。

- [ ] **Step 6: 執行 v2 測試（sync 未改，預期多個 FAIL）**

Run: `cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -15`
Expected：與 `seed_language_rows`／`seed_location_rows`／`render_registry_sql` 相關測試 FAIL（Task 3 修），其餘 PASS。

- [ ] **Step 7: Commit**

```bash
git add scripts/v2/language_seed_profiles.json scripts/v2/migrate_seed_to_varieties.py scripts/v2/test_language_data.py backend/src/utils/ulid.test.ts
git commit -m "refactor(seed): split language seed into varieties + profiles

65 flat language entries collapse to 49 varieties; system:mn-Mong and
system:mn-Cyrl merge into variety mn. Locations now reference variety_code.
The sync generator is updated in the next commit."
```

---

## Task 3: sync 腳本與 schema.sql 改兩表模型

改 `sync_language_registry.py` 讀新 JSON、產 `language-varieties.csv`／`language-profiles.csv` 與兩表 upsert SQL；改 `backend/schema.sql` 成兩表模型。

**Files:**
- Modify: `scripts/v2/sync_language_registry.py`
- Modify: `backend/schema.sql`
- Test: `scripts/v2/test_language_data.py`

**Interfaces:**
- `seed_language_rows` → 拆為 `seed_variety_rows(profiles, subtags, languoids_by_code)` 回傳 variety rows（含 `id`），與 `seed_profile_rows(profiles, subtags)` 回傳 profile rows（含 `language_variety_id`）。
- `seed_location_rows(profiles, variety_code_to_id, subtags)`：第二參數改為 variety code→id 映射。
- `render_registry_sql(languoids, subtags, varieties, profiles, locations)` 額外接受 varieties／profiles list。
- 新增 `write_varieties`／`write_profiles` 取代 `write_languages`；新增 `render_variety_insert`／`render_profile_insert` 取代 `render_language_insert`。
- `LOCATION_FIELDS` 把 `variety_key` 換成 `language_variety_id`；location CSV 欄改用 `language_variety_id`。

- [ ] **Step 1: 改 schema.sql 為兩表模型**

`backend/schema.sql`：

1. **清理區段（第 9-32 行）**：把 `DROP TABLE IF EXISTS language_stats;` 與 `DROP TABLE IF EXISTS languages;` 兩行，換成 `DROP TABLE IF EXISTS language_profiles;`、`DROP TABLE IF EXISTS language_varieties;`。`language_stats` 自 DROP 清單移除（spec §7.3 不再保留）。

2. **`languages` 表（第 69-98 行）整段**取代為 spec §7.1 + §7.2 兩表（逐字）：

```sql
CREATE TABLE language_varieties (
    id TEXT PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    description TEXT NOT NULL DEFAULT '',
    glottocode TEXT,
    origin TEXT NOT NULL
      CHECK (origin IN ('seed', 'glottolog', 'community', 'system')),
    community_reason TEXT,
    alternate_names_json TEXT NOT NULL DEFAULT '[]',
    references_json TEXT NOT NULL DEFAULT '[]',
    parent_languoid_id TEXT,
    created_by TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (glottocode) REFERENCES languoids(glottocode),
    FOREIGN KEY (parent_languoid_id) REFERENCES languoids(id)
);
CREATE INDEX idx_language_varieties_name ON language_varieties(name);
CREATE INDEX idx_language_varieties_glottocode ON language_varieties(glottocode);

CREATE TABLE language_profiles (
    code TEXT PRIMARY KEY NOT NULL,
    language_variety_id TEXT NOT NULL,
    name TEXT NOT NULL,
    name_en TEXT,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl')),
    base_language TEXT NOT NULL,
    script_code TEXT,
    region_code TEXT,
    variants_json TEXT NOT NULL DEFAULT '[]',
    private_use_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
CREATE INDEX idx_language_profiles_variety
  ON language_profiles(language_variety_id);
CREATE INDEX idx_language_profiles_base_script_region
  ON language_profiles(base_language, script_code, region_code);
```

3. **`language_locations`（第 100-114 行）**：欄位 `variety_key` 改 `language_variety_id TEXT NOT NULL`，PK 改 `(language_variety_id, city_name, territory_code, script_code)`，加 `FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)`；index `idx_language_locations_variety` 改 `ON language_locations(language_variety_id)`。

4. **`expressions`（第 116-144 行）**：欄位 `language_code TEXT NOT NULL` 改 `language_profile_code TEXT NOT NULL`；FK 改 `FOREIGN KEY (language_profile_code) REFERENCES language_profiles(code)`；index `idx_expressions_language_code` 改名 `idx_expressions_language_profile` 且 `ON expressions(language_profile_code)`；`idx_expressions_lang_text` 改 `ON expressions(language_profile_code, text)`。

5. **刪除 `language_stats`（第 185-188 行整段）**。

6. **`ui_locales`（第 285 行）**：`FOREIGN KEY (code) REFERENCES languages(code)` 改 `FOREIGN KEY (code) REFERENCES language_profiles(code)`。

7. FTS triggers（第 318-329 行）不變。

- [ ] **Step 2: 改 sync_language_registry.py 讀新 JSON、產兩表**

`scripts/v2/sync_language_registry.py`：

1. 刪除 `seed_language_rows`、`LANGUAGE_FIELDS`、`write_languages`、`render_language_insert`（第 274-513 行間相關定義）。
2. 新增 `VARIETY_FIELDS = ("id","code","name","name_en","description","glottocode","origin","community_reason","alternate_names_json","references_json","parent_languoid_id")` 與 `PROFILE_FIELDS = ("code","language_variety_id","name","name_en","direction","base_language","script_code","region_code","variants_json","private_use_json")`。
3. 新增 `seed_variety_rows(profiles, subtags, languoids_by_code)`：遍歷 `profiles["varieties"]`（依 code 排序），對每個 variety 驗證 code 唯一、glottocode（若有）存在於 languoids，yield 一個 dict（id 取自 seed、parent_languoid_id 取自 languoid）。
4. 新增 `seed_profile_rows(profiles, subtags)`：對每個 variety 的每個 profile（依 code 排序），用既有 `canonical_seed_code` 驗證、`split_canonical_seed_code` 解析，yield dict 含 `language_variety_id=variety["id"]`、`direction=direction_for_script(parts["script"])`、`base_language=parts["language"]` 等。
5. `LOCATION_FIELDS` 改 `("language_variety_id","city_name","city_name_en","territory_code","script_code","latitude","longitude","reference")`；`seed_location_rows(profiles, variety_code_to_id, subtags)` 用 `variety_code` 查 `variety_code_to_id[code]` 得 variety id（未知則 `raise ValueError("unknown variety_code")`），其餘領土／script／座標驗證邏輯不變。
6. 新增 `write_varieties(path, rows)`／`write_profiles(path, rows)`（依 code casefold 排序，CSV），與 `render_variety_insert`／`render_profile_insert`（兩者皆 `ON CONFLICT(code) DO UPDATE SET ...` upsert，variety conflict 更新 name/name_en/description/glottocode/origin/community_reason/alternate_names_json/references_json/parent_languoid_id；profile conflict 更新 language_variety_id/name/name_en/direction/base_language/script_code/region_code/variants_json/private_use_json）。
7. `render_location_insert`：改 `ON CONFLICT(language_variety_id, city_name, territory_code, script_code) DO UPDATE SET ...`。
8. `render_registry_sql(languoids, subtags, varieties, profiles, locations)`：依序 render languoid、subtag、variety、profile、location insert。
9. `main`（第 583-642 行）改：產 `variety_rows`／`profile_rows`／`location_rows`，`write_varieties(output/"language-varieties.csv")`、`write_profiles(output/"language-profiles.csv")`，manifest 改 `variety_count`／`profile_count`／`language_location_count`（移除 `language_tag_count`／`max_tags` 截斷邏輯；保留 `--max-tags` argparse 但不再用於截斷）。

- [ ] **Step 3: 執行 v2 測試確認通過**

Run: `cd scripts/v2 && python3 -m unittest test_language_data 2>&1 | tail -10`
Expected: 全部 PASS。

- [ ] **Step 4: 重產 registry artifacts（offline）**

Run: `cd scripts/v2 && python3 sync_language_registry.py --output artifacts/language-registry-5.3 --offline`
Expected: manifest JSON 含 `variety_count: 49`、`profile_count: 65`、`language_location_count: 57`。

- [ ] **Step 5: 驗證產出 SQL／CSV**

Run:

```bash
python3 -c "
import csv
s=open('scripts/v2/artifacts/language-registry-5.3/language-registry.sql').read()
assert 'INSERT INTO language_varieties' in s and 'INSERT INTO language_profiles' in s
assert 'INSERT INTO languages ' not in s
var=list(csv.DictReader(open('scripts/v2/artifacts/language-registry-5.3/language-varieties.csv')))
prof=list(csv.DictReader(open('scripts/v2/artifacts/language-registry-5.3/language-profiles.csv')))
assert len(var)==49 and len(prof)==65
vids={v['id'] for v in var}
assert all(p['language_variety_id'] in vids for p in prof)
print('registry artifacts OK')
"
```

Expected: `registry artifacts OK`。

- [ ] **Step 6: Commit**

```bash
git add scripts/v2/sync_language_registry.py scripts/v2/artifacts/language-registry-5.3 backend/schema.sql
git commit -m "feat(schema): two-layer language_varieties + language_profiles

schema.sql replaces languages with variety + profile tables; renames
expressions.language_code -> language_profile_code; language_locations FKs by
variety id; drops unused language_stats; ui_locales FK -> profiles. sync now
emits two CSVs and two-table SQL from the new varieties[] seed shape."
```

---

## Task 4: forward-only migration 0016

在既有本地 DB 上把單表模型搬到兩表模型。forward-only、可重入安全、以 temp 對應表承載 variety_key→variety mapping（含社群 fallback）。用 SQLite 表重建（無法 ALTER FK 目標）處理 expressions／language_locations／ui_locales；`language_stats` 與舊 `languages` 於依賴搬完後 drop。

**Files:**
- Create: `backend/migrations/0016_variety_profile_split.sql`
- Create: `backend/migrations/0016_variety_profile_split.meta.json`
- Modify: `scripts/db/migration-lock.json`

**Interfaces:** 命名受影響：`expressions.language_code`→`language_profile_code`；`language_locations.variety_key`→`language_variety_id`；`language_stats` 刪除；`languages` 表刪除。保留所有 expression／edge／ui_locale／location row count 不變（spec §14.1）。

- [ ] **Step 1: 取出 variety_id mapping 供 migration 使用**

Run:

```bash
cd scripts/v2 && python3 -c "
import json
d=json.load(open('language_seed_profiles.json'))
v={x['code']:x for x in d['varieties']}
# build (old_key -> (variety_id, variety_code)) using the same old_key derivation as sync
import re
m={}
for x in d['varieties']:
    gc=x.get('glottocode')
    if gc:
        m[f'glotto:{gc}']=(x['id'],x['code'])
# system keys: derive from first profile's old system:<code> form
sys_special={'und':'system:und','x-emoji':'system:x-emoji','x-image':'system:x-image','fa':'system:fa','za':'system:za-Latn'}
for code,(vid,vc) in [(v[c]['id'],c) for c in v if not v[c].get('glottocode')]:
    pass
for c,x in v.items():
    if x.get('glottocode'): continue
    # special/system: old key was system:<original-first-profile-code-or-base>
    # und/x-emoji/x-image/fa map directly; mn had two old keys mn-Mong, mn-Cyrl; za was za-Latn
print('-- copy these VALUES into _variety_map in 0016:')
for gc_code in sorted(v,key=lambda c:v[c]['code']):
    x=v[gc_code]
    if x.get('glottocode'):
        print(f\"  ('glotto:{x['glottocode']}', '{x['id']}', '{x['code']}'),\")
# print system mappings explicitly (curated, since old key shape varies)
print('-- system keys (hand-map per Task 2 VARIETY_MAP inverse):')
for vc in ['und','x-emoji','x-image','fa','za','mn']:
    print(f\"  variety {vc} -> id {v[vc]['id']}; old keys: see Task 2 VARIETY_MAP\")
"
```

把輸出的 43 條 `('glotto:...', '<id>', '<code>')` 直接用。system 7 條依 Task 2 的 `VARIETY_MAP` 反查：`system:und→und`、`system:x-emoji→x-emoji`、`system:x-image→x-image`、`system:fa→fa`、`system:za-Latn→za`、`system:mn-Mong→mn`、`system:mn-Cyrl→mn`（mn 兩鍵同一 id／code）。

- [ ] **Step 2: 寫 migration 0016**

`backend/migrations/0016_variety_profile_split.sql` 結構（以 Step 1 實際 ULID 填入 `_variety_map` VALUES；下方為完整 SQL，`<...>` 處填實際值）：

```sql
-- 0016: Split single-table languages into language_varieties + language_profiles.
-- Forward-only, rerunnable. spec §12.2.3, §12.3. Backout = restore pre-migration backup.
PRAGMA defer_foreign_keys = ON;

-- 1. old variety_key -> (variety_id, variety_code). Seed IDs are version-controlled.
CREATE TEMP TABLE IF NOT EXISTS _variety_map (
  old_key TEXT PRIMARY KEY,
  variety_id TEXT NOT NULL,
  variety_code TEXT NOT NULL
);
INSERT OR IGNORE INTO _variety_map (old_key, variety_id, variety_code) VALUES
  ('system:und',      '<und_id>',  'und'),
  ('system:x-emoji',  '<emo_id>',  'x-emoji'),
  ('system:x-image',  '<img_id>',  'x-image'),
  ('system:fa',       '<fa_id>',   'fa'),
  ('system:za-Latn',  '<za_id>',   'za'),
  ('system:mn-Mong',  '<mn_id>',   'mn'),
  ('system:mn-Cyrl',  '<mn_id>',   'mn'),
  ('glotto:stan1293', '<en_id>',   'en'),
  ('glotto:swah1253', '<swh_id>',  'swh'),
  ('glotto:ralt1242', '<ral_id>',  'ral'),
  ('glotto:yang1286', '<zyg_id>',  'zyg'),
  ('glotto:ouji1238', '<wuuouji_id>', 'wuu-x-ouji1238'),
  ('glotto:taiz1238', '<wuutaiz_id>', 'wuu-x-taiz1238'),
  ('glotto:chao1238', '<nanchao_id>', 'nan-x-chao1238'),
  ('glotto:minn1241', '<nan_id>',  'nan'),
  ('glotto:mand1415', '<cmn_id>',  'cmn'),
  ('glotto:stan1318', '<ar_id>',   'ar'),
  ('glotto:beng1280', '<bn_id>',   'bn'),
  ('glotto:stan1295', '<de_id>',   'de'),
  ('glotto:stan1288', '<es_id>',   'es'),
  ('glotto:stan1290', '<fr_id>',   'fr'),
  ('glotto:hind1269', '<hi_id>',   'hi'),
  ('glotto:indo1316', '<id_id>',   'id'),
  ('glotto:ital1282', '<it_id>',   'it'),
  ('glotto:nucl1643', '<ja_id>',   'ja'),
  ('glotto:kore1280', '<ko_id>',   'ko'),
  ('glotto:mara1378', '<mr_id>',   'mr'),
  ('glotto:panj1256', '<pa_id>',   'pa'),
  ('glotto:port1283', '<pt_id>',   'pt'),
  ('glotto:russ1263', '<ru_id>',   'ru'),
  ('glotto:thai1261', '<th_id>',   'th'),
  ('glotto:nucl1301', '<tr_id>',   'tr'),
  ('glotto:urdu1245', '<ur_id>',   'ur'),
  ('glotto:viet1252', '<vi_id>',   'vi'),
  ('glotto:wuch1236', '<wuu_id>',  'wuu'),
  ('glotto:yuec1235', '<yue_id>',  'yue'),
  ('glotto:xian1251', '<hsn_id>',  'hsn'),
  ('glotto:hakk1236', '<hak_id>',  'hak'),
  ('glotto:mind1253', '<cdo_id>',  'cdo'),
  ('glotto:minb1236', '<mnp_id>',  'mnp'),
  ('glotto:tibe1272', '<bo_id>',   'bo'),
  ('glotto:uigh1240', '<ug_id>',   'ug'),
  ('glotto:kaza1248', '<kk_id>',   'kk'),
  ('glotto:kirg1245', '<ky_id>',   'ky'),
  ('glotto:jiny1235', '<cjy_id>',  'cjy'),
  ('glotto:ganc1239', '<gan_id>',  'gan'),
  ('glotto:minz1235', '<czo_id>',  'czo'),
  ('glotto:puxi1243', '<cpx_id>',  'cpx'),
  ('glotto:nort3268', '<cnp_id>',  'cnp'),
  ('glotto:sout3250', '<csp_id>',  'csp');

-- 2. Create new tables (verbatim from schema.sql Task 3 Step 1.2/1.3).
CREATE TABLE IF NOT EXISTS language_varieties ( /* full DDL from schema.sql */ );
CREATE TABLE IF NOT EXISTS language_profiles  ( /* full DDL from schema.sql */ );
CREATE INDEX IF NOT EXISTS idx_language_varieties_name ON language_varieties(name);
CREATE INDEX IF NOT EXISTS idx_language_varieties_glottocode ON language_varieties(glottocode);
CREATE INDEX IF NOT EXISTS idx_language_profiles_variety ON language_profiles(language_variety_id);
CREATE INDEX IF NOT EXISTS idx_language_profiles_base_script_region ON language_profiles(base_language, script_code, region_code);

-- 3. Seed varieties: one per distinct old_key in _variety_map; COALESCE metadata
--    from the first languages row carrying that old variety_key.
INSERT OR IGNORE INTO language_varieties
  (id, code, name, name_en, description, glottocode, origin, community_reason,
   alternate_names_json, references_json, parent_languoid_id, created_at, updated_at)
SELECT m.variety_id, m.variety_code,
  COALESCE((SELECT name FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1), m.variety_code),
  (SELECT name_en FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1),
  COALESCE((SELECT description FROM languages WHERE variety_key=m.old_key LIMIT 1), ''),
  (SELECT glottocode FROM languages WHERE variety_key=m.old_key AND glottocode IS NOT NULL AND glottocode!='' LIMIT 1),
  COALESCE((SELECT origin FROM languages WHERE variety_key=m.old_key LIMIT 1), 'seed'),
  COALESCE((SELECT community_reason FROM languages WHERE variety_key=m.old_key LIMIT 1), ''),
  COALESCE((SELECT alternate_names_json FROM languages WHERE variety_key=m.old_key ORDER BY code LIMIT 1), '[]'),
  COALESCE((SELECT references_json FROM languages WHERE variety_key=m.old_key LIMIT 1), '[]'),
  (SELECT parent_languoid_id FROM languages WHERE variety_key=m.old_key AND parent_languoid_id IS NOT NULL LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM _variety_map m
WHERE NOT EXISTS (SELECT 1 FROM language_varieties v WHERE v.id=m.variety_id);

-- 4. Fallback: old variety_keys not in _variety_map (community/test). Each gets
--    its own variety with a placeholder id 'comm-<old_key>'; registry rebuild
--    (re-sync) later replaces seed varieties cleanly. spec §12.1.3.
INSERT OR IGNORE INTO language_varieties
  (id, code, name, name_en, description, glottocode, origin, community_reason,
   alternate_names_json, references_json, parent_languoid_id, created_at, updated_at)
SELECT 'comm-' || l.variety_key,
  CASE WHEN instr(l.variety_key,':')>0 THEN substr(l.variety_key, instr(l.variety_key,':')+1)
       ELSE 'x-' || lower(hex(randomblob(4))) END,
  (SELECT name FROM languages WHERE variety_key=l.variety_key ORDER BY code LIMIT 1),
  (SELECT name_en FROM languages WHERE variety_key=l.variety_key LIMIT 1),
  COALESCE((SELECT description FROM languages WHERE variety_key=l.variety_key LIMIT 1),''),
  (SELECT glottocode FROM languages WHERE variety_key=l.variety_key AND glottocode IS NOT NULL LIMIT 1),
  'community',
  COALESCE((SELECT community_reason FROM languages WHERE variety_key=l.variety_key LIMIT 1),''),
  COALESCE((SELECT alternate_names_json FROM languages WHERE variety_key=l.variety_key LIMIT 1),'[]'),
  '[]',
  (SELECT parent_languoid_id FROM languages WHERE variety_key=l.variety_key LIMIT 1),
  CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM (SELECT DISTINCT variety_key FROM languages) l
WHERE NOT EXISTS (SELECT 1 FROM _variety_map m WHERE m.old_key=l.variety_key)
  AND NOT EXISTS (SELECT 1 FROM language_varieties v WHERE v.id='comm-'||l.variety_key);

-- 5. Profiles: one per old languages row, code unchanged (spec §12.1.4). Profile
--    name derived from script; name_en carried from old row.
INSERT OR IGNORE INTO language_profiles
  (code, language_variety_id, name, name_en, direction, base_language, script_code,
   region_code, variants_json, private_use_json, created_at, updated_at)
SELECT l.code,
  COALESCE((SELECT m.variety_id FROM _variety_map m WHERE m.old_key=l.variety_key), 'comm-'||l.variety_key),
  CASE l.script_code
    WHEN 'Hans' THEN '簡體' WHEN 'Hant' THEN '傳承體' WHEN 'Latn' THEN '拉丁'
    WHEN 'Cyrl' THEN '西里爾' WHEN 'Arab' THEN '阿拉伯文' WHEN 'Mong' THEN '傳統蒙古文'
    WHEN 'Tibt' THEN '藏文' WHEN 'Guru' THEN '古木奇文' ELSE '標準' END,
  l.name_en,
  COALESCE(l.direction,'ltr'),
  COALESCE(l.base_language, substr(l.code, 1, instr(l.code||'-','-')-1)),
  l.script_code, l.region_code,
  COALESCE(l.variants_json,'[]'), COALESCE(l.private_use_json,'[]'),
  COALESCE(l.created_at, CURRENT_TIMESTAMP), COALESCE(l.updated_at, CURRENT_TIMESTAMP)
FROM languages l
WHERE NOT EXISTS (SELECT 1 FROM language_profiles p WHERE p.code=l.code);

-- 6. Rebuild expressions with renamed FK column. Drop FTS triggers first; they
--    reference expressions by name and must be recreated on the rebuilt table.
DROP TRIGGER IF EXISTS expressions_ai;
DROP TRIGGER IF EXISTS expressions_ad;
DROP TRIGGER IF EXISTS expressions_au;

CREATE TABLE IF NOT EXISTS expressions_new (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_profile_code TEXT NOT NULL,
    region_code TEXT, region_name TEXT, region_latitude REAL, region_longitude REAL,
    tags TEXT, source_type TEXT DEFAULT 'user', source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    variation_status TEXT NOT NULL DEFAULT 'unclassified'
      CHECK (variation_status IN ('unclassified','shared','variant')),
    meaning_id INTEGER, created_by TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT, updated_at TEXT DEFAULT CURRENT_TIMESTAMP, desc TEXT DEFAULT NULL,
    FOREIGN KEY (language_profile_code) REFERENCES language_profiles(code)
);

INSERT OR IGNORE INTO expressions_new
  (id, text, audio_url, language_profile_code, region_code, region_name,
   region_latitude, region_longitude, tags, source_type, source_ref,
   review_status, variation_status, meaning_id, created_by, created_at,
   updated_by, updated_at, desc)
SELECT id, text, audio_url, language_code, region_code, region_name,
       region_latitude, region_longitude, tags, source_type, source_ref,
       review_status, variation_status, meaning_id, created_by, created_at,
       updated_by, updated_at, desc
FROM expressions;

DROP TABLE expressions;
ALTER TABLE expressions_new RENAME TO expressions;
CREATE INDEX IF NOT EXISTS idx_expressions_text ON expressions(text);
CREATE INDEX IF NOT EXISTS idx_expressions_language_profile ON expressions(language_profile_code);
CREATE INDEX IF NOT EXISTS idx_expressions_tags ON expressions(tags);
CREATE INDEX IF NOT EXISTS idx_expressions_created_by ON expressions(created_by);
CREATE INDEX IF NOT EXISTS idx_expressions_lang_text ON expressions(language_profile_code, text);
CREATE INDEX IF NOT EXISTS idx_expressions_meaning_id ON expressions(meaning_id);

-- 7. Rebuild language_locations with variety id FK.
CREATE TABLE IF NOT EXISTS language_locations_new (
    language_variety_id TEXT NOT NULL,
    city_name TEXT NOT NULL, city_name_en TEXT,
    territory_code TEXT NOT NULL, script_code TEXT NOT NULL DEFAULT '',
    latitude REAL NOT NULL, longitude REAL NOT NULL, reference TEXT NOT NULL,
    PRIMARY KEY (language_variety_id, city_name, territory_code, script_code),
    FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)
);
INSERT OR IGNORE INTO language_locations_new
  (language_variety_id, city_name, city_name_en, territory_code, script_code, latitude, longitude, reference)
SELECT COALESCE((SELECT m.variety_id FROM _variety_map m WHERE m.old_key=ll.variety_key), 'comm-'||ll.variety_key),
       city_name, city_name_en, territory_code, script_code, latitude, longitude, reference
FROM language_locations ll;
DROP TABLE language_locations;
ALTER TABLE language_locations_new RENAME TO language_locations;
CREATE INDEX IF NOT EXISTS idx_language_locations_variety ON language_locations(language_variety_id);
CREATE INDEX IF NOT EXISTS idx_language_locations_city ON language_locations(city_name, territory_code);

-- 8. Rebuild ui_locales FK target -> language_profiles(code).
CREATE TABLE IF NOT EXISTS ui_locales_new (
    project_id TEXT NOT NULL, code TEXT NOT NULL,
    native_name TEXT NOT NULL,
    direction TEXT NOT NULL DEFAULT 'ltr' CHECK (direction IN ('ltr','rtl')),
    fallback_code TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','draft','archived')),
    mapping_revision INTEGER NOT NULL DEFAULT 0,
    created_by TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT, updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, code),
    FOREIGN KEY (code) REFERENCES language_profiles(code),
    FOREIGN KEY (project_id, fallback_code) REFERENCES ui_locales(project_id, code)
);
INSERT OR IGNORE INTO ui_locales_new
  (project_id, code, native_name, direction, fallback_code, status, mapping_revision,
   created_by, created_at, updated_by, updated_at)
SELECT project_id, code, native_name, direction, fallback_code, status,
       mapping_revision, created_by, created_at, updated_by, updated_at
FROM ui_locales;
DROP TABLE ui_locales;
ALTER TABLE ui_locales_new RENAME TO ui_locales;
CREATE INDEX IF NOT EXISTS idx_ui_locales_code ON ui_locales(code);

-- 9. Drop obsolete tables.
DROP TABLE IF EXISTS language_stats;
DROP TABLE languages;

-- 10. Recreate FTS triggers on the rebuilt expressions table.
CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(
    text, content='expressions', content_rowid='id', tokenize='unicode61'
);
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

-- 11. Verify: no orphan references survive (spec §14.1). Aborts via 1/0 on failure.
CREATE TEMP TABLE IF NOT EXISTS _check (ok INTEGER NOT NULL CHECK (ok = 1));
INSERT INTO _check (ok)
SELECT CASE WHEN
  NOT EXISTS (SELECT 1 FROM expressions e WHERE NOT EXISTS
      (SELECT 1 FROM language_profiles p WHERE p.code=e.language_profile_code))
  AND NOT EXISTS (SELECT 1 FROM ui_locales u WHERE NOT EXISTS
      (SELECT 1 FROM language_profiles p WHERE p.code=u.code))
  AND NOT EXISTS (SELECT 1 FROM language_profiles p WHERE NOT EXISTS
      (SELECT 1 FROM language_varieties v WHERE v.id=p.language_variety_id))
  AND NOT EXISTS (SELECT 1 FROM language_locations ll WHERE NOT EXISTS
      (SELECT 1 FROM language_varieties v WHERE v.id=ll.language_variety_id))
  AND NOT EXISTS (SELECT 1 FROM sqlite_master WHERE type='table' AND name IN ('languages','language_stats'))
  AND (SELECT COUNT(*) FROM language_varieties) > 0
THEN 1 ELSE 0 END;
DROP TABLE _check;
DROP TABLE _variety_map;
```

> 實作時把 `/* full DDL from schema.sql */` 與 `<..._id>` 占位以 Step 1 實際值取代；其餘逐字。`mn` 兩條 old_key 共用同一 `<mn_id>`。

- [ ] **Step 3: 寫 meta.json**

`backend/migrations/0016_variety_profile_split.meta.json`：

```json
{
  "description": "Split single-table languages into language_varieties + language_profiles; rename expressions.language_code -> language_profile_code; language_locations FK by variety id; drop language_stats and languages.",
  "spec": "docs/superpowers/specs/2026-08-03-language-variety-profile-model-design.md",
  "forward_only": true,
  "backout": "Restore the pre-migration local D1 backup; do not run a synthetic down migration."
}
```

- [ ] **Step 4: 更新 migration-lock.json**

`scripts/db/migration-lock.json`：在 0015 物件（第 84-89 行）之後加 0016 條目。sequence=16，filename=`0016_variety_profile_split.sql`，size 與 sha256 由實作填：

```bash
python3 -c "import hashlib,os; p='backend/migrations/0016_variety_profile_split.sql'; print(json.dumps({'sequence':16,'filename':os.path.basename(p),'size':os.path.getsize(p),'sha256':hashlib.sha256(open(p,'rb').read()).hexdigest()}))" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin),indent=2))"
```

把輸出作為新元素插入 `migration-lock.json` 的 `migrations` 陣列尾端。

- [ ] **Step 5: 備份本地 D1，套用 migration，驗證**

```bash
cp -R backend/.wrangler/state backend/.wrangler/state.pre0016.bak
cd backend && npx wrangler d1 migrations apply langmap-v2 --local --persist-to "$PWD/.wrangler/state"
```

驗證（migration 前後 expression/locale/location row count 應一致；新增 varieties/profiles；無 orphan；舊表已除）：

```bash
DB=$(ls backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite | head -1)
sqlite3 "$DB" "SELECT 'varieties', COUNT(*) FROM language_varieties
UNION ALL SELECT 'profiles', COUNT(*) FROM language_profiles
UNION ALL SELECT 'expressions', COUNT(*) FROM expressions
UNION ALL SELECT 'ui_locales', COUNT(*) FROM ui_locales
UNION ALL SELECT 'locations', COUNT(*) FROM language_locations;
SELECT 'orphans', COUNT(*) FROM expressions e WHERE NOT EXISTS (SELECT 1 FROM language_profiles p WHERE p.code=e.language_profile_code);
SELECT 'old_languages_table', COUNT(*) FROM sqlite_master WHERE name='languages';"
```

Expected：`varieties 49`（+ 任何 community/test）、`profiles 65`、`expressions`／`ui_locales`／`locations` 與備份前相同、`orphans 0`、`old_languages_table 0`。

- [ ] **Step 6: Commit**

```bash
git add backend/migrations/0016_variety_profile_split.sql backend/migrations/0016_variety_profile_split.meta.json scripts/db/migration-lock.json
git commit -m "feat(migration): 0016 split languages into varieties + profiles

Forward-only D1 migration implementing spec §12. Carries the explicit seed
variety_id mapping (49 varieties) so migrated rows align with regenerated
registry SQL. expressions.language_code renamed via table rebuild (SQLite
cannot alter FK target otherwise); language_stats and the old languages table
are dropped after dependents move."
```

---

## Task 5: 後端 types + services 改兩表

`types/language.ts` 拆 `VarietyRow`／`ProfileRow`；`languageRegistry` 改 `requireVariety`（by code）與 `requireRegisteredLanguage`（回傳 `ProfileRow`）；`languageCreation` 改為 `previewVariety`／`createVariety`（atomic 建立 variety+首 profile）與 `createProfile`（在既有 variety 下加 profile），並拒絕 script-name 誤用（spec §8.2）。

**Files:**
- Modify: `backend/src/types/language.ts`
- Modify: `backend/src/services/languageRegistry.ts`
- Modify: `backend/src/services/languageCreation.ts`

**Interfaces:**
- `LanguageRow` → `VarietyRow`（id, code, name, name_en, description, glottocode, origin, community_reason, alternate_names, references, parent_languoid_id）+ `ProfileRow`（code, language_variety_id, language_variety_code, name, name_en, direction, base_language, script_code, region_code, variants, private_use）。
- `requireRegisteredLanguage(db, code)` → `ProfileRow | null`（join variety 取 `language_variety_code`）。
- 新增 `requireVariety(db, code)` → `VarietyRow | null`。
- `previewLanguage/createLanguage` → `previewVariety/createVariety`（回 `{variety, profile}`）；新增 `createProfile(db, varietyCode, body)`。
- `PreviewRequestSchema/CreateRequestSchema` → `PreviewVarietySchema/CreateVarietySchema`（payload 加 `variety` + `profile` 兩個 metadata block）；新增 `CreateProfileSchema`。

- [ ] **Step 1: types/language.ts 整檔重寫**

`backend/src/types/language.ts`：保留 `LanguageSubtags`／`CanonicalLanguageTag` 不變；移除 `LanguageRow`／`LanguagePreview`；新增 `VarietyOrigin`、`VarietyRow`、`ProfileRow`、`VarietyPreview`（欄位如 Interfaces 所列；`VarietyPreview` 取代 `LanguagePreview`，含 `canonical_profile_code`、`existing_variety`、`existing_profile`、`profiles_of_variety`、`similar_varieties`、`required_metadata`）。

- [ ] **Step 2: services/languageRegistry.ts 整檔重寫**

保留 `validateLanguageTag` 邏輯逐字（RTL script 集合、subtag 查驗、variant prefix 檢查不變）。改動：
- 移除 `requireRegisteredLanguage` 舊實作（讀 `languages`）。
- 新增 `rowToVariety(row)`／`rowToProfile(row)`（如 Interfaces 欄位；`language_variety_code` 由 join 帶出）。
- 新增 `requireVariety(db, code)`：`SELECT * FROM language_varieties WHERE code = ?` → `VarietyRow | null`。
- 新增 `requireRegisteredLanguage(db, code)`：`SELECT p.*, v.code AS language_variety_code FROM language_profiles p JOIN language_varieties v ON v.id = p.language_variety_id WHERE p.code = ?` → `ProfileRow | null`。helper name 保留（expressions/contributions/localization 既有呼叫端不改名），但其回傳型別從 `LanguageRow` 改為 `ProfileRow`。

- [ ] **Step 3: services/languageCreation.ts 整檔重寫**

- `SubtagsSchema` 不變。`LanguageMetadataSchema` 改名 `VarietyMetadataSchema`（欄位同：name/name_en/description/reason/alternate_names/references/parent_languoid_id；移除 latitude/longitude——location 已移到 `language_locations` 不在 variety/profile 表）。
- 新增 `ProfileMetadataSchema`（name 預設「標準」、name_en 預設 null）。
- `PreviewRequestSchema`/`CreateRequestSchema` → `PreviewVarietySchema`/`CreateVarietySchema`：`{ subtags, glottocode, variety: VarietyMetadataSchema, profile: ProfileMetadataSchema.default({}) }`。
- 新增 `CreateProfileSchema = z.object({ subtags: SubtagsSchema, profile: ProfileMetadataSchema.default({}) })`。
- `deriveVarietyKey` 移除；新增 `deriveVarietyCode(tag)`：`tag.private_use.length>0 ? `${tag.language}-x-${tag.private_use[0]}` : tag.language`（spec §5.1：無專用 subtag 的變體用不含 script 的 private-use code）。
- `previewVariety(db, body)`：canonicalize tag → profile code；derive variety code；查 `existing_profile`（by profile code）與其 `existing_variety`；查該 variety 既有 profiles；查相似 varieties（variety name LIKE）；回 `VarietyPreview`。critical warning 時丟 `INVALID_LANGUAGE_SUBTAG`。
- `createVariety(db, userId, body)`：驗證 → 拒絕 profile/variety code 重複（`LANGUAGE_PROFILE_CODE_EXISTS`／`LANGUAGE_CODE_EXISTS`）→ 查 24h 內建立數（`language_varieties` 而非舊 `languages`），超限丟 `RATE_LIMITED`→ `db.batch([insert variety, insert first profile])`（atomic，spec §7.2）→ 回 `{variety, profile}`。`community_reason` 存 `meta.reason`。
- `createProfile(db, varietyCode, body)`：驗證 → 查 variety（不存在丟 `LANGUAGE_NOT_FOUND`）→ 拒絕 profile code 重複（`LANGUAGE_PROFILE_CODE_EXISTS`）→ 拒絕 script/region 名誤用（`/^(hans|hant|latn|cyrl|arab|mong|tibt|guru|tradition|simplified|傳承體|简体|简|繁)$/i` 命中 → `LANGUAGE_PROFILE_MISMATCH`，spec §8.2）→ insert profile。
- `LanguageCreationError` 保留。
- 常數 `MAX_*`、`DAILY_LIMIT=10` 不變。

> 實作者依上述逐項寫完整檔案。`previewVariety` 的 variety/profile 查詢與現有 `previewLanguage` 結構對齊（只是表名與回傳 shape 變）；`createVariety` 的 rate-limit 子查詢改成 `FROM language_varieties WHERE created_by = ?`。

- [ ] **Step 4: 暫不執行測試**

routes（Task 6/7）與既有測試仍引用舊符號，此時 build/test 有型別錯誤屬預期；Task 8/9 修齊後再整體跑。

- [ ] **Step 5: Commit**

```bash
git add backend/src/types/language.ts backend/src/services/languageRegistry.ts backend/src/services/languageCreation.ts
git commit -m "refactor(backend): split language types/services into variety + profile"
```

---

## Task 6: 後端 routes/languages + languoids 改 variety 聚合

`GET /languages`、`/:code`、`/:code/expressions` 改以 variety 為資源、聚合 profile 詞句數（spec §9.1）；`languoids` 的 profiles 改 join 新表。

**Files:**
- Modify: `backend/src/routes/languages.ts`
- Modify: `backend/src/routes/languoids.ts`

**Interfaces:**
- `GET /languages`：variety items，每個含 `expression_count`（所有 profiles 合計）、`profile_count`、`profiles[]`（各 profile 含 `expression_count`）。分頁／搜尋／排序在 SQL 層以 variety 為單位。
- `GET /languages/:code`：以 variety code 查；回 variety 摘要 + 全部 profiles + `representative_cities`（用 variety id）+ `mapped_expression_count`。
- `GET /languages/:code/expressions`：預設全部 profiles，`profile_code`／`script` query 篩選；每筆回傳 `language_profile_code` 與 `language_profile_name`。

- [ ] **Step 1: routes/languages.ts 整檔重寫**

POST `/preview` 與 POST `/` 改呼叫 `previewVariety`／`createVariety`（自 `../services/languageCreation` import）；POST `/` 回 `created(c, { variety, profile })`，409/429 mapping 增加 `LANGUAGE_PROFILE_CODE_EXISTS → conflict`。

GET `/`（variety 聚合列表）：
```sql
SELECT v.id, v.code, v.name, v.name_en, v.glottocode, v.origin,
  (SELECT COUNT(*) FROM expressions e
     JOIN language_profiles p ON p.code = e.language_profile_code
     WHERE p.language_variety_id = v.id) AS expression_count,
  (SELECT COUNT(*) FROM language_profiles p WHERE p.language_variety_id = v.id) AS profile_count
FROM language_varieties v
LEFT JOIN languoids g ON g.glottocode = v.glottocode
```
搜尋 WHERE 涵蓋：`v.name/name_en/code/glottocode`、`g.preferred_name/iso639_3`、`v.alternate_names_json`，以及 `EXISTS (SELECT 1 FROM language_profiles p WHERE p.language_variety_id=v.id AND p.code LIKE ?)`（讓搜 `cmn-Hant` 命中華語）。`script` query → `EXISTS (... p.script_code = ?)`。ORDER BY 用 `count: 'expression_count DESC, v.name ASC, v.code ASC'`、`alpha: 'v.name ASC, v.code ASC'`。結果再以一次 IN-query 拉 profiles（`p.code, p.name, p.script_code, expression_count`）組進每個 variety item 的 `profiles[]`。回 `{ items, limit, offset, has_more }`。

GET `/:code`：`SELECT v.* FROM language_varieties v WHERE v.code = ?`（找不到 → `notFound('Language')`）；用 `v.id` 拉 profiles（含 per-profile expression_count）、`mapped_expression_count`（join `language_profiles` 限定該 variety）、`representative_cities`（`FROM language_locations WHERE language_variety_id = ?`）。`expression_count` = profile expression_count 之和。

GET `/:code/expressions`：先 `SELECT id FROM language_varieties WHERE code = ?`；profile 篩選 `WHERE p.language_variety_id = ?` 加選用的 `p.code = ?`／`p.script_code = ?`；JOIN `language_profiles p ON p.code = e.language_profile_code`；SELECT 加 `p.code AS language_profile_code, p.name AS language_profile_name`。排序維持 new/alpha/hot。

> 實作者依上述逐項寫完整檔。注意 Hono 路由註冊順序：GET `/`、POST `/preview`、POST `/`、GET `/:code`、（Task 7 加的）POST `/:code/profiles/preview`、POST `/:code/profiles`、GET `/:code/expressions`。

- [ ] **Step 2: routes/languoids.ts 的 profiles join 改新表**

`backend/src/routes/languoids.ts`：
- 第 114-127 行 `langQuery`／`countQuery` 中 `LEFT JOIN languages c ON c.glottocode = l.glottocode` 改為兩段 join：
  ```sql
  LEFT JOIN language_varieties cv ON cv.glottocode = l.glottocode
  LEFT JOIN language_profiles c ON c.language_variety_id = cv.id
  ```
  `if (script)` 中的 `c.script_code` 不變（仍指 profile）。`clause`／`params`／`orderParams` 邏輯不變。
- 第 133-153 行 profiles 查詢改：
  ```sql
  SELECT p.code, p.name, p.script_code, p.region_code, v.glottocode AS glottocode
  FROM language_profiles p
  JOIN language_varieties v ON v.id = p.language_variety_id
  WHERE v.glottocode IN (...)
  ORDER BY p.name ASC, p.code ASC
  ```
  後續 `profilesByGc` 分組邏輯不變。

- [ ] **Step 3: 暫不 commit（與 Task 7/8 一併）**

---

## Task 7: 新增 profile API route

新增 `routes/languageProfiles.ts`（spec §9.2）提供 profile list／detail；`POST /languages/:code/profiles[/preview]` 委派 `services/languageCreation`；掛到 `routes/index.ts`。

**Files:**
- Create: `backend/src/routes/languageProfiles.ts`
- Modify: `backend/src/routes/languages.ts`（加 `/:code/profiles/preview` 與 `/:code/profiles`）
- Modify: `backend/src/routes/index.ts`

**Interfaces:**
- `GET /language-profiles?q=&variety_code=&script=&limit=&offset=` → `{ items, limit, offset, has_more }`，item 含 joined `variety_code/variety_name/variety_name_en`。
- `GET /language-profiles/:code` → 單一 profile + 其 variety summary。

- [ ] **Step 1: routes/languageProfiles.ts**

```ts
import { Hono } from 'hono';
import { success, notFound } from '../utils/response';
import type { Bindings } from '../types';

const languageProfiles = new Hono<{ Bindings: Bindings }>();

languageProfiles.get('/', async (c) => {
  const q = c.req.query('q') || '';
  const varietyCode = c.req.query('variety_code') || '';
  const script = c.req.query('script') || '';
  const limit = Math.min(Math.max(Number(c.req.query('limit') || 50) || 50, 1), 100);
  const offset = Math.max(Number(c.req.query('offset') || 0) || 0, 0);
  const filters: string[] = [];
  const params: (string | number)[] = [];
  if (q) {
    const esc = q.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
    filters.push("(p.code LIKE ? ESCAPE '\\' OR p.name LIKE ? ESCAPE '\\')");
    params.push(`%${esc}%`, `%${esc}%`);
  }
  if (varietyCode) { filters.push('v.code = ?'); params.push(varietyCode); }
  if (script) { filters.push('p.script_code = ?'); params.push(script); }
  const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
  const { results } = await c.env.DB.prepare(
    `SELECT p.code, p.name, p.name_en, p.script_code, p.region_code, p.direction,
       v.code AS variety_code, v.name AS variety_name, v.name_en AS variety_name_en
     FROM language_profiles p
     JOIN language_varieties v ON v.id = p.language_variety_id
     ${where}
     ORDER BY v.name ASC, v.code ASC, p.code ASC
     LIMIT ? OFFSET ?`
  ).bind(...params, limit, offset).all();
  return success(c, { items: results, limit, offset, has_more: results.length === limit });
});

languageProfiles.get('/:code', async (c) => {
  const code = c.req.param('code');
  const row = await c.env.DB.prepare(
    `SELECT p.code, p.name, p.name_en, p.direction, p.base_language,
       p.script_code, p.region_code, p.variants_json, p.private_use_json,
       v.code AS variety_code, v.name AS variety_name, v.name_en AS variety_name_en,
       v.glottocode AS variety_glottocode
     FROM language_profiles p
     JOIN language_varieties v ON v.id = p.language_variety_id
     WHERE p.code = ?`
  ).bind(code).first();
  if (!row) return notFound(c, 'Language profile');
  return success(c, row);
});

export default languageProfiles;
```

- [ ] **Step 2: routes/languages.ts 加 profile 建立路由**

在 `GET /:code` 之後、`GET /:code/expressions` 之前加：

```ts
languages.post('/:code/profiles/preview', requireAuth, async (c) => {
  const varietyCode = c.req.param('code');
  const exists = await c.env.DB.prepare('SELECT 1 FROM language_varieties WHERE code = ?')
    .bind(varietyCode).first();
  if (!exists) return notFound(c, 'Language');
  try {
    const body = await c.req.json();
    const { previewVariety, LanguageCreationError } = await import('../services/languageCreation');
    return success(c, await previewVariety(c.env.DB, body));
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) return badRequest(c, err.code, err.message);
    if (err instanceof Error && err.name === 'ZodError') return badRequest(c, 'VALIDATION_FAILED', err.message);
    throw err;
  }
});

languages.post('/:code/profiles', requireAuth, async (c) => {
  const user = c.get('user');
  if (!user) return;
  const varietyCode = c.req.param('code');
  try {
    const body = await c.req.json();
    const { createProfile, LanguageCreationError } = await import('../services/languageCreation');
    return created(c, { profile: await createProfile(c.env.DB, varietyCode, body) });
  } catch (err: unknown) {
    if (err instanceof LanguageCreationError) {
      if (err.code === 'LANGUAGE_PROFILE_CODE_EXISTS') return conflict(c, err.code, err.message);
      if (err.code === 'LANGUAGE_NOT_FOUND') return notFound(c, 'Language');
      return badRequest(c, err.code, err.message);
    }
    if (err instanceof Error && err.name === 'ZodError') return badRequest(c, 'VALIDATION_FAILED', err.message);
    throw err;
  }
});
```

- [ ] **Step 3: routes/index.ts 掛載**

`backend/src/routes/index.ts`：在 `import languageRegistry from './languageRegistry';` 後加 `import languageProfiles from './languageProfiles';`；在 `api.route('/languages', languages);` 後加 `api.route('/language-profiles', languageProfiles);`。

- [ ] **Step 4: Commit（含 Task 6）**

```bash
git add backend/src/routes/languages.ts backend/src/routes/languoids.ts backend/src/routes/languageProfiles.ts backend/src/routes/index.ts
git commit -m "feat(api): variety-aggregated /languages + new /language-profiles route"
```

---

## Task 8: 後端全面改名 language_code → language_profile_code

把所有仍引用舊 `expressions.language_code` 欄位的 route／util／型別改成 `language_profile_code`（spec §9.3）；graph SQL 與 expression/handbook 顯示名改 join profiles→varieties 取 variety name 為 `language_name`。contribution batch body 欄位 `lang` 改 `language_profile_code`（spec §9.3 精神：不再以 language 指稱 profile）。

**Files:**
- Modify: `backend/src/types.ts`、`backend/src/utils/mappingGraph.ts`
- Modify: `backend/src/routes/expressions.ts`、`contributions.ts`、`search.ts`、`feed.ts`、`handbooks.ts`、`localization.ts`、`mappings.ts`

**Interfaces:**
- `MappingGraphNode.language_code` → `language_profile_code`；graph／expression detail 的 `language_name` 來源改為 variety name（經 profiles→varieties join）。
- contribution batch body：`{ lang, text, tags }` → `{ language_profile_code, text, tags }`。
- 回應中保留的 alias（`a_lang`／`b_lang`／`left_lang`／`locale_code`）不強制改名——它們是回應欄位名稱，spec §9.3 規範的是 mutation 請求欄位與 `language_code` 欄位本身；為縮小 blast radius，這些 alias 維持，底層 SELECT 改讀新欄。

- [ ] **Step 1: types.ts graph node**

`backend/src/types.ts` 第 14 行 `language_code: string;` → `language_profile_code: string;`。

- [ ] **Step 2: utils/mappingGraph.ts**

- 第 17 行 `ExpressionRow.language_code` → `language_profile_code`。
- 第 53 行 `language_code: rootRow?.language_code ?? '',` → `language_profile_code: rootRow?.language_profile_code ?? '',`。
- 第 95 行 `language_code: row.language_code,` → `language_profile_code: row.language_profile_code,`。

- [ ] **Step 3: routes/expressions.ts**

- `/search`（第 12-34 行）：`SELECT id, text, language_code` → `language_profile_code`；`AND language_code = ?` → `AND language_profile_code = ?`。
- `POST /`（第 36-113 行）：body 型別 `language_code?: string` → `language_profile_code?: string`（第 41 行）；`body.language_code` → `body.language_profile_code`（第 48 行）；錯誤訊息 `'text and language_code are required'` → `'text and language_profile_code are required'`；`requireRegisteredLanguage` 仍回傳 `ProfileRow`，錯誤訊息 `'language_code must reference...'` → `'language_profile_code must reference a registered language profile'`；`WHERE text=? AND language_code=?` → `AND language_profile_code=?`；INSERT 欄位 `language_code` → `language_profile_code`。變數 `languageCode`（其值為 profile code）保留。
- `GET /:id`（第 116-125 行）：`FROM expressions e LEFT JOIN languages l ON e.language_code = l.code` 改為：
  ```sql
  FROM expressions e
  LEFT JOIN language_profiles p ON p.code = e.language_profile_code
  LEFT JOIN language_varieties l ON l.id = p.language_variety_id
  ```
  SELECT 加 `e.language_profile_code`，保留 `l.name AS language_name`。
- `GET /:id/mappings` 的 `loadExpressions`（第 160-175 行）：SQL 改
  ```sql
  SELECT e.id as expression_id, e.text, e.language_profile_code, v.name as language_name
  FROM expressions e
  LEFT JOIN language_profiles p ON p.code = e.language_profile_code
  LEFT JOIN language_varieties v ON v.id = p.language_variety_id
  WHERE e.id IN (...)
  ORDER BY e.id ASC
  ```

- [ ] **Step 4: routes/contributions.ts**

- 第 24-26 行 body 型別 `{ lang: string; text: string; tags?: string }[]` → `{ language_profile_code: string; text: string; tags?: string }[]`。
- 第 31 行 `e.lang?.trim()` → `e.language_profile_code?.trim()`。
- 第 38 行錯誤訊息 `'language_code must reference...'` → `'language_profile_code must reference a registered language profile'`。
- 第 48 行 `e.lang?.trim()` → `e.language_profile_code?.trim()`。
- 第 62 行 `WHERE text=? AND language_code=?` → `AND language_profile_code=?`。
- 第 72 行 INSERT 欄位 `language_code` → `language_profile_code`（bind 仍 `lang` 變數）。

- [ ] **Step 5: routes/search.ts**

第 29 行 `AND e.language_code IN (...)` → `AND e.language_profile_code IN (...)`；第 45 行第二處相同。`lang` query param 保留（值為 profile code list）。

- [ ] **Step 6: routes/feed.ts**

把 `a.language_code`／`b.language_code`／`e.language_code`（第 11、12、30、31、43 行共 5 處底層欄位引用）改 `X.language_profile_code`；alias `a_lang`／`b_lang`／`left_lang` 不變。

- [ ] **Step 7: routes/handbooks.ts**

第 75-78 行改：
```sql
SELECT hsi.*, e.text, e.language_profile_code, v.name as language_name
FROM handbook_section_items hsi
JOIN expressions e ON e.id = hsi.expression_id
LEFT JOIN language_profiles p ON p.code = e.language_profile_code
LEFT JOIN language_varieties v ON v.id = p.language_variety_id
```

- [ ] **Step 8: routes/localization.ts**

第 130、143、148、190、197、219 行的 `language_code` 改 `language_profile_code`；`te.language_code AS locale_code` 改 `te.language_profile_code AS locale_code`（alias 保留）。第 251 行錯誤訊息 `'language_code must reference...'` → `'language_profile_code must reference a registered language profile'`。

- [ ] **Step 9: routes/mappings.ts**

第 44 行 `SELECT m.project_id, te.language_code` → `te.language_profile_code`。

- [ ] **Step 10: grep 確認無 SQL/TS 殘留**

Run: `rg -n "language_code" backend/src`
Expected：只剩註解或錯誤訊息字串中提及；無實際 SQL 欄位或 TS 屬性。逐一檢視輸出，有殘留則修正。

- [ ] **Step 11: Commit**

```bash
git add backend/src
git commit -m "refactor(backend): rename language_code -> language_profile_code everywhere

Aligns mutation fields and graph/expression detail joins with the two-layer
model (spec §9.3). language_name now resolves via profile -> variety join.
Contribution batch body field renamed lang -> language_profile_code."
```

---

## Task 9: 後端整合測試更新

更新後端測試對應新 API 合約與新欄位；先重建本地 D1（新 schema + registry），再跑全套測試。

**Files:**
- Modify: `backend/tests/languages.integration.test.ts`
- Modify: `backend/tests/languageCode.test.ts`
- Modify: `backend/tests/languageRegistry.test.ts`
- Modify: `backend/tests/mappingGraph.test.ts`
- Modify: `backend/tests/expressions-mappings.test.ts`

- [ ] **Step 1: 重建本地 D1（新 schema + registry）**

```bash
./dev.sh --rebuild
```

確認 Worker 在 127.0.0.1:8788（`dev.sh` 會重建並啟動；另開 shell 跑測試）。

- [ ] **Step 2: languages.integration.test.ts**

`backend/tests/languages.integration.test.ts`：
- 「previews and creates an unmatched community variety」（第 34-69 行）：payload 改新 schema：
  ```ts
  const payload = {
    subtags: { language: 'yue', script: 'Hant', region: 'CN', variants: [], private_use: [`hegu${Date.now().toString(36).slice(-4)}`] },
    glottocode: null,
    variety: { name: '河谷新村話', name_en: null, description: '由當地社群使用的粵語變種。',
      reason: 'missing_from_glottolog', alternate_names: [], references: [], parent_languoid_id: null },
    profile: { name: '傳承體', name_en: 'Traditional' },
  };
  ```
  preview 斷言讀 `data.existing_variety`／`data.existing_profile`／`data.canonical_profile_code`；created 斷言讀 `data.variety.origin==='community'` 與 `data.variety.glottocode===null`。
- 「returns 409 for duplicate language code」（第 113-129 行）：重複建立時斷言錯誤碼可為 `LANGUAGE_CODE_EXISTS` 或 `LANGUAGE_PROFILE_CODE_EXISTS`（依第二次撞 variety code 或 profile code；此測試同 payload 兩者皆撞，斷言 `['LANGUAGE_CODE_EXISTS','LANGUAGE_PROFILE_CODE_EXISTS'].includes(body.error)`）。
- 「previews...」與其他 preview/create 測試的 payload 都加 `variety`／`profile` block（最小：`profile:{}`，`variety` 的 `reason` 已在）。
- 「rejects contribution batch...」／「rejects expression creation...」（第 174-198 行）：contribution batch 把 `{ lang: 'en-US', text }` → `{ language_profile_code: 'en-US', text }`；expression POST 把 body `language_code` → `language_profile_code`。錯誤碼 `INVALID_LANGUAGE_CODE` 保留（既有合約；service 層錯誤碼維持）。
- 「language-registry subtag API」與「languoids API」區段（第 200-273 行）：`languoids` 的 `profiles` 斷言不變（仍是陣列）。

- [ ] **Step 3: languageCode.test.ts**

`backend/tests/languageCode.test.ts`：此檔測 `languageCode.ts` 工具（`parseStoredLanguageCode`／`isLanguageCode`／`canonicalizeLanguageTag`）。這些工具**不變**（仍操作 BCP 47 tag 字串，與表無關）。確認測試仍 PASS；若有任何 fixture 用到 `languages` 表名則改正。若測試只是單元測工具，無需改。

- [ ] **Step 4: languageRegistry.test.ts**

`backend/tests/languageRegistry.test.ts`：若測試呼叫 `requireRegisteredLanguage` 並斷言 `LanguageRow` 欄位（`variety_key`／`script_code` 等），改斷言 `ProfileRow` 欄位（`language_variety_id`／`language_variety_code`／`script_code`）。若測 `validateLanguageTag`，不需改（邏輯不變）。

- [ ] **Step 5: mappingGraph.test.ts**

`backend/tests/mappingGraph.test.ts`：fixture node 欄位 `language_code` → `language_profile_code`（全檔）。`ExpressionRow`／`MappingGraphNode` 型別已於 Task 8 改，測試 fixture 對齊。

- [ ] **Step 6: expressions-mappings.test.ts**

`backend/tests/expressions-mappings.test.ts`：POST body 的 `language_code` → `language_profile_code`；任何讀回應 `language_code` 的斷言改 `language_profile_code`；`language_name` 仍應出現（variety name）。

- [ ] **Step 7: 跑全套後端測試**

```bash
cd backend && npm test
```

Expected：全 PASS。若失敗，依輸出修正殘留的舊欄位引用或 payload shape。

- [ ] **Step 8: Commit**

```bash
git add backend/tests
git commit -m "test(backend): update integration tests for variety+profile model"
```

---

## Task 10: Web API client + store + composables

更新 `api/languages.ts` 型別為 variety／profile 雙概念、新增 profile API、更新 store／composable 讀 variety 列表。

**Files:**
- Modify: `web/src/api/languages.ts`
- Modify: `web/src/stores/languages.ts`
- Modify: `web/src/composables/useLanguages.ts`
- Modify: `web/src/composables/useLanguageCreation.ts`

**Interfaces:**
- `RegistryLanguage` → `Variety`（含 `profiles: Profile[]`、`expression_count`、`profile_count`）+ `Profile`。
- `LanguagePreview` → `VarietyPreview`（含 `existing_variety`／`existing_profile`／`profiles_of_variety`／`similar_varieties`）。
- `CreateLanguagePayload` → `CreateVarietyPayload`（`{ subtags, glottocode, variety, profile }`）。
- 新增 `listLanguageProfiles(params)`／`getLanguageProfile(code)`（`/language-profiles`）。
- `listRegistryLanguages` 仍回 variety 列表（給 picker 搜尋）。

- [ ] **Step 1: api/languages.ts**

`backend/src/api/languages.ts` 整檔重寫（web 端）：
- 介面：`Variety { code, name, name_en, glottocode, origin, expression_count, profile_count, profiles: ProfileSummary[] }`；`ProfileSummary { code, name, script_code, expression_count }`；`Profile { code, name, name_en, script_code, region_code, direction, base_language, variety_code, variety_name, variety_name_en, variety_glottocode }`。
- `VarietyPreview`、`CreateVarietyPayload`（含 `variety` + `profile` block）、`CreatedVariety = { variety: Variety; profile: Profile }`。
- `listRegistryLanguages(search, signal)` → GET `/languages`，回 `Variety[]`。
- `getLanguage(code)` → GET `/languages/:code`（variety 詳情）。
- `listLanguageExpressions(code, { profile_code, script, sort, limit, offset })` → GET `/languages/:code/expressions`。
- `listLanguageProfiles({ q, variety_code, script, limit, offset }, signal)` → GET `/language-profiles`。
- `getLanguageProfile(code)` → GET `/language-profiles/:code`。
- `previewVariety(payload)` → POST `/languages/preview`；`createVariety(payload)` → POST `/languages`。
- `createProfile(varietyCode, payload)` → POST `/languages/:code/profiles`。
- `searchLanguoids`／`listLanguageSubtags` 不變。

- [ ] **Step 2: stores/languages.ts**

`web/src/stores/languages.ts`：`languages` ref 型別改 `Variety[]`；`upsertLanguage` 仍以 `code`（variety code）為鍵；`getName(code)` 改為先查 variety by code → name；新增 `getProfileName(profileCode)`：在 `languages[].profiles` 找 `p.code===profileCode` 回 `p.name`，找不到回 `profileCode`。`fetchLanguages` 呼叫 `listRegistryLanguages`（簽名不變）。

- [ ] **Step 3: composables/useLanguages.ts**

`web/src/composables/useLanguages.ts`：`list`／`detail`／`expressions` 三函式對應新 API；`expressions` 接受 `{ profile_code, script, sort, limit, offset }`。回傳 shape 由後端決定，不需在 composable 改名（`data.items` 等）。

- [ ] **Step 4: composables/useLanguageCreation.ts**

`web/src/composables/useLanguageCreation.ts`：
- `metadata` reactive 改為兩個 block：`variety`（name/name_en/description/reason/alternate_names/references/parent_languoid_id）+ `profile`（name/name_en）。
- `buildPayload` 回 `CreateVarietyPayload`（`{ subtags, glottocode, variety: {...}, profile: {...} }`）。
- `preview` ref 型別 `VarietyPreview | null`；`runPreview`／`submit` 呼叫 `apiPreviewVariety`／`apiCreateVariety`。
- `reset` 重設兩個 block。
- import 改新 API 名（`previewVariety as apiPreviewVariety` 等）。
- `useLanguageCreation.test.ts` 同步更新 fixture（見 Task 13）。

- [ ] **Step 5: Commit**

```bash
git add web/src/api/languages.ts web/src/stores/languages.ts web/src/composables/useLanguages.ts web/src/composables/useLanguageCreation.ts
git commit -m "refactor(web): api/store/composable for variety+profile model"
```

---

## Task 11: Web 列表／詳情／卡片改 variety 聚合

`LanguageList`／`LanguageDetail`／`LanguageCard` 改顯示 variety（合計詞句數、profile chips），詳情頁加 profile 篩選。URL 仍 `/language/:code`，但 `:code` 改為 variety code。

**Files:**
- Modify: `web/src/pages/LanguageList.vue`
- Modify: `web/src/pages/LanguageDetail.vue`
- Modify: `web/src/components/language/LanguageCard.vue`

- [ ] **Step 1: LanguageCard.vue 改顯示 variety**

`web/src/components/language/LanguageCard.vue`：
- props 改 `{ code, name, name_en?, expression_count, profile_count, profiles?: ProfileSummary[], direction? }`（移除單一 `script_code`）。
- 模板：標題列 `name` + variety code badge；副列 `name_en`；profile chips（`v-for p in profiles` 顯示 `p.name` 或 `p.script_code`，至少顯示前 4 個）；右側合計 `expression_count`。單 profile variety 可省略 chip。
- 連結 `:to="/language/${code}"`（variety code）不變。
- 行動版維持 ≥44px 觸控目標、`min-width:0` 防長名溢出。

- [ ] **Step 2: LanguageList.vue**

`web/src/pages/LanguageList.vue`：
- `languages` ref 型別 `Variety[]`；`filtered` 搜尋比對 `name`／`code`／`profiles[].code`／`name_en`／`glottocode`。
- `totalExpressions` 改為 variety `expression_count` 之和（已是合計，直接加）。
- `StatBox`「語言數」用 variety 數（`languages.length`）。
- `LanguageCard` 改傳新 props（含 `profiles`／`profile_count`）。
- 桌面表格欄位：`grid-template-columns: minmax(0,1fr) auto auto`（名稱／profile chips／計數）。行動版：名稱＋計數。

- [ ] **Step 3: LanguageDetail.vue 加 profile 篩選**

`web/src/pages/LanguageDetail.vue`：
- `route.params.code` 是 variety code；`detail(code)` 回 variety 詳情（含 `profiles` 陣列、`representative_cities`、合計 `expression_count`、`mapped_expression_count`）。
- 標題 `lang.name` + variety code badge；副列 `name_en · glottocode`（移除單一 `script_code`）。
- 新增 profile 篩選列：`全部` + 每個 profile 一個按鈕（顯示 `p.name`，如「傳承體」「簡體」）。`v-model` 一個 `selectedProfile` ref（空字串 = 全部）。單 profile variety 可隱藏篩選列但仍顯示 content tag。
- `changeSort`／load 用 `expressions(code, { profile_code: selectedProfile, sort, limit })`；切換 profile 時重新 load。
- ExpressionRow 在混合列表顯示 profile label（見 Task 13 改 ExpressionRow）。
- URL reload：從 `?profile=` query 初始化 `selectedProfile`（`router.replace` 同步）；避免刷新丟失篩選。
- 空狀態（該 profile 無詞句）顯示 `t('languageDetail.noResults')`。

- [ ] **Step 4: 桌面／行動 viewport 檢查**

```bash
cd web && npm run build
```

以 dev server 手動檢查 `/languages` 與 `/language/cmn`（含 profile 篩選）在 1280px 與 375px viewport：長名稱（如「布農語」混合）不溢出、profile chips 換行、篩選按鈕可鍵盤操作且 focus 可見。

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/LanguageList.vue web/src/pages/LanguageDetail.vue web/src/components/language/LanguageCard.vue
git commit -m "feat(web): variety-aggregated language list + profile filter on detail"
```

---

## Task 12: Web LanguagePicker 改兩階段選擇

`LanguagePicker` 改兩階段（spec §10.3）：搜尋 → 選 variety → 若 >1 profile 則選 profile → emit profile code。單 profile variety 自動選定並顯示 content tag。`LanguageCreateDialog` 改用新 composable。

**Files:**
- Modify: `web/src/components/language/LanguagePicker.vue`
- Modify: `web/src/components/language/LanguageCreateDialog.vue`
- Modify: `web/src/composables/useLanguageCreation.ts`（test 同步 Task 13）

**Interfaces:**
- `LanguagePicker` props 不變（`modelValue: string` 仍是 profile code）；emit `update:modelValue` 仍帶 profile code；新增 `emit('profile', profileCode)`。
- 內部狀態：`selectedVariety: Variety | null`、`selectedProfileCode: string`。選定後顯示 `variety.name` + profile label（如「華語（傳承體）」）+ profile code 次要資訊。

- [ ] **Step 1: LanguagePicker.vue 兩階段**

`web/src/components/language/LanguagePicker.vue`：
- 搜尋階段不變（debounce 呼叫 `listRegistryLanguages(query)`，回 variety 結果）。option 顯示 `variety.name` + variety code +（若 >1 profile）profile 數 chip。
- `selectLanguage(varietyCode)` 改為 `selectVariety(variety)`：
  - 若 `variety.profiles.length === 1` → 直接 `emit('update:modelValue', profiles[0].code)`，顯示選定摘要。
  - 若 >1 → 進入第二步：顯示 profile 選單（按鈕 list，每個 `p.name`／`p.code`），`@mousedown.prevent="selectProfile(p.code)"`。預設焦點在第一個 profile。
- `selectedLanguage`（variety）顯示：`name` + 當前 profile label + variety code。`clearSelection` 清兩階段。
- 鍵盤：第一步 ArrowDown/Up/Enter 如前；第二步 Enter 選焦點 profile；Escape 回第一步或關閉。
- `store.upsertLanguage(found)` 仍存 variety。
- 觸控目標 ≥44px、focus 可見、listbox/option 角色與 aria-label 維持。
- 多 profile 時根據上次選擇或 UI locale 建議預設（可選；MVP 先不建議，第一步焦點在第一個 profile 即可）。

- [ ] **Step 2: LanguageCreateDialog.vue 改新 composable**

`web/src/components/language/LanguageCreateDialog.vue`：
- 改用 `useLanguageCreation`（已於 Task 10 改回傳 variety+profile）；步驟流程調整為「subtag／glottolog → variety metadata（含 profile label name）→ preview → submit」。
- 完成後 emit `created` 帶 `{ code: profile.code, name: variety.name }`（picker 用 profile code）。
- 文案：標題改「新增語言或方言」；profile 欄位標籤「書寫形式名稱」。

- [ ] **Step 3: Commit**

```bash
git add web/src/components/language/LanguagePicker.vue web/src/components/language/LanguageCreateDialog.vue
git commit -m "feat(web): two-stage language picker (variety -> profile)"
```

---

## Task 13: Web components 全面改名 language_code → language_profile_code

把 mapping／expression／handbook 元件與測試中讀取 `language_code` 的位置改名，並讓 badge／顯示改用 profile code + variety name。

**Files:**
- Modify: `web/src/components/mapping/mappingGraphTypes.ts`、`MappingGraph.vue`、`GraphNode.vue`、`GraphInspector.vue`、`GraphMobileInspector.vue`、`MappingHierarchyList.vue`
- Modify: `web/src/components/expression/ExpressionRow.vue`、`ExpressionPicker.vue`
- Modify: `web/src/components/handbook/HandbookExpressionInspector.vue`、`HandbookRelationPreview.vue`、`SectionEditor.vue`
- Modify: `web/src/pages/MappingDetail.vue`、`MapLens.vue`、`HandbookView.vue`、`HandbookEdit.vue`、`Contribute.vue`
- Modify: 對應 `*.test.ts` 與 `useLanguageCreation.test.ts`、`LanguagePicker.test.ts`、`MappingDetail.language.test.ts`、`TranslateWorkbench.language.test.ts`

**Interfaces:**
- node/expression 型別 `language_code` → `language_profile_code`；`language_name` 仍是 variety name（後端已 join）。
- `GraphNode` props `languageCode` → `languageProfileCode`（或保留 alias 內部對應；為最小改動，prop 可改名並更新唯一呼叫端 `MappingGraph.vue`）。
- `Contribute.vue` 提交 `{ language_profile_code, text, tags }`（Task 8 後端已改）。

- [ ] **Step 1: mappingGraphTypes.ts 與 mapping 元件**

`web/src/components/mapping/mappingGraphTypes.ts` 第 4 行 `language_code: string` → `language_profile_code: string`。

下列元件的 node/expression fixture 與模板欄位 `language_code` → `language_profile_code`（保留 `language_name`）：
- `MappingGraph.vue`（第 278 行 `graph.nodes...?.language_code` → `language_profile_code`，傳給 GraphNode 的 prop）。
- `GraphNode.vue`（props `languageCode` → `languageProfileCode`；模板顯示處改）。
- `GraphInspector.vue`（第 75 行）、`GraphMobileInspector.vue`（第 107 行）、`MappingHierarchyList.vue`（第 49 行 `?.language_code` → `?.language_profile_code`）。
- 測試 fixture：`MappingGraph.test.ts`、`GraphInspector.test.ts`、`MappingHierarchyList.test.ts`、`mappingGraphLayout.test.ts`、`mappingGraphModel.test.ts` 全檔 `language_code` → `language_profile_code`。

- [ ] **Step 2: expression 元件**

- `ExpressionRow.vue`（第 5 行 props `language_code` → `language_profile_code`；第 16 行 badge 改顯示 profile code）。
- `ExpressionPicker.vue`（第 7 行 emit 型別、第 48 行顯示）。

- [ ] **Step 3: handbook 元件**

- `HandbookExpressionInspector.vue`（第 11、66、72 行）、`HandbookRelationPreview.vue`（第 50 行）、`SectionEditor.vue`（第 9、51 行）。

- [ ] **Step 4: 頁面**

- `MappingDetail.vue`：第 220 行 `language_code: languageCode` → `language_profile_code: languageCode`；第 291 行 `expr.language_code` → `expr.language_profile_code`；quick-add 改提交 `language_profile_code`。
- `MapLens.vue`：node 型別（第 35 行）與所有讀 `n.language_code`（第 50、57、80、107、121、210、224 行）改 `n.language_profile_code`。
- `HandbookView.vue`（第 21、74、118、195 行）、`HandbookEdit.vue`（第 24、45 行）。
- `Contribute.vue`：`Row.lang` → `Row.language_profile_code`；`newRow()` 初始 `language_profile_code: ''`；`submit` payload `{ language_profile_code: r.language_profile_code.trim(), text, tags }`；`LanguagePicker` v-model 改綁 `row.language_profile_code`（picker 仍 emit profile code）。

- [ ] **Step 5: 其餘測試 fixture**

- `useLanguageCreation.test.ts`：payload 加 `variety`/`profile` block；`variety_key` fixture（第 118 行）移除／改為新 shape。
- `LanguagePicker.test.ts`：fixture `variety_key`（第 27 行）移除；改用 `profiles: []` 的 variety。
- `MappingDetail.language.test.ts`：node `language_code` → `language_profile_code`（第 30、41、171 行）。
- `TranslateWorkbench.language.test.ts`：對應欄位改名。

- [ ] **Step 6: grep 確認無殘留**

Run: `rg -n "language_code" web/src`
Expected：無殘留（不含字串註解）。逐一檢視並修正。

- [ ] **Step 7: 前端 build + 跑測試**

```bash
cd web && npm run build && npm test
```

Expected：build 通過、測試全 PASS。

- [ ] **Step 8: Commit**

```bash
git add web/src
git commit -m "refactor(web): rename language_code -> language_profile_code in components"
```

---

## Task 14: 文件標記 superseded 與 domain glossary 更新

標記被取代的規格、更新 AGENTS.md domain glossary，確保後續實作者不採用衝突方案（spec §15.10）。

**Files:**
- Modify: `docs/superpowers/specs/2026-07-27-community-language-creation.md`
- Modify: `docs/superpowers/specs/2026-08-02-language-common-and-variant-profiles.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 標記 superseded specs**

`docs/superpowers/specs/2026-07-27-community-language-creation.md`：在檔首標題下加：

```markdown
> **狀態：部分已被取代。** 本規格的「一列 language 就是一個內容 profile」「不另建 `language_varieties` 表」「`variety_key` 非正式實體」等決策，已於 `2026-08-03-language-variety-profile-model-design.md` §6 正式取代。canonical BCP 47 驗證、Glottolog 對齊規則、社群變體建立能力仍保留。請優先遵循 2026-08-03 規格。
```

`docs/superpowers/specs/2026-08-02-language-common-and-variant-profiles.md`：在檔首加：

```markdown
> **狀態：部分已被取代。** 「`/languages` 繼續逐 profile 顯示」的決策已於 `2026-08-03-language-variety-profile-model-design.md` §6 取代（改以 variety 聚合）。base／region／private-use profile 的共通與變體內容分工仍保留。
```

- [ ] **Step 2: AGENTS.md domain glossary**

`AGENTS.md`「## Domain」區段：把 `expression`／`mapping`／`language` 條目更新為兩層語意：

```markdown
- `language`：使用者認知的語言或方言（language variety），是語言列表、詳情、搜尋與統計的聚合單位；以穩定的公開 `code`（如 `cmn`、`yue`）識別。
- `language profile`：某 variety 下可綁定詞句的精確 BCP 47 content tag（如 `cmn-Hant`），是 expression 與 UI locale 的引用鍵。
```

並在「## 程式規範」加一條：

```markdown
- `language` 在公開 API 指語言變體（variety）；精確內容 tag 用 `language_profile_code`，不要混用。
```

- [ ] **Step 3: git diff --check 並檢查連結**

```bash
git diff --check
rg -n "2026-07-27-community-language-creation|2026-08-02-language-common-and-variant-profiles" docs AGENTS.md README.md
```

Expected：無 whitespace 錯誤；引用這兩份規格之處仍指向正確路徑。

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs AGENTS.md
git commit -m "docs: mark variety/profile spec as superseding prior language model decisions"
```

---

## Task 15: 全流程驗證

確認乾淨 DB bootstrap 與既有 DB migration 得到相同最終 schema（spec §14.4），抽查華語／粵語／潮州話／蒙古語／哈薩克語不依賴漢語特例（spec §14.4），跑 `./build.sh`。

- [ ] **Step 1: 乾淨 bootstrap schema 比對**

```bash
# 重建乾淨本地 DB
./dev.sh --rebuild
DB_CLEAN=$(ls backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite | head -1)
sqlite3 "$DB_CLEAN" ".schema" > /tmp/schema_clean.txt
```

- [ ] **Step 2: 既有 DB（migration 路徑）schema 比對**

```bash
# 從 Task 4 備份還原 pre-0016 狀態，套用所有 migration（含 0016）
rm -rf backend/.wrangler/state && mv backend/.wrangler/state.pre0016.bak backend/.wrangler/state
cd backend && npx wrangler d1 migrations apply langmap-v2 --local --persist-to "$PWD/.wrangler/state"
DB_MIG=$(ls backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite | head -1)
sqlite3 "$DB_MIG" ".schema" > /tmp/schema_mig.txt
diff /tmp/schema_clean.txt /tmp/schema_mig.txt && echo "schema parity OK"
```

Expected：`schema parity OK`（兩路徑最終 schema 一致）。若有差異（如 index 名稱），以 `schema.sql` 為準修正 migration。

- [ ] **Step 3: 抽查不依賴漢語特例**

啟動 Worker（`./dev.sh`），對乾淨 DB 抽查：

```bash
B=http://127.0.0.1:8788/api/v2
# 華語 variety 只一個 entry，profiles 含 Hans/Hant
curl -s "$B/languages?q=cmn" | python3 -m json.tool | head -40
# 粵語
curl -s "$B/languages/yue" | python3 -m json.tool
# 潮州話 private-use variety code（不退化成 nan）
curl -s "$B/languages/nan-x-chao1238" | python3 -m json.tool
# 蒙古語兩 script profiles 同一 variety
curl -s "$B/languages/mn" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(sorted(p['code'] for p in d['profiles']))"
# 哈薩克語兩 script profiles 同一 variety
curl -s "$B/languages/kk" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(sorted(p['code'] for p in d['profiles']))"
```

Expected：
- `cmn` search 回單一華語 variety，`profiles` 含 `cmn-Hans`+`cmn-Hant`。
- `/languages/yue` 回粵語，profiles 含 `yue-Hans`+`yue-Hant`。
- `/languages/nan-x-chao1238` 回潮州話（非上層閩南 `nan`），profiles 含 3 個 chao1238 profile。
- `mn` profiles = `['mn-Cyrl','mn-Mong']`；`kk` profiles = `['kk-Arab','kk-Cyrl']`。

- [ ] **Step 4: 語言數不因 profile 增減膨脹**

```bash
# 計 varieties 總數 = 49（seed）+ 任何 community
curl -s "$B/languages?limit=100" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print('varieties',len(d['items']),'sum profiles',sum(v['profile_count'] for v in d['items']))"
```

Expected：`varieties 49`（乾淨 DB）、profile 總和 65。

- [ ] **Step 5: 後端 + 前端 + build.sh**

```bash
cd backend && npm test
cd ../web && npm run build && npm test
cd .. && ./build.sh
```

Expected：後端測試 PASS、前端 build + 測試 PASS、`./build.sh`（web build → backend/public）成功。

- [ ] **Step 6: 貢獻流程提交 profile code（端到端）**

以 `./dev.sh` 啟動的環境，登入後在 `/contribute` 提交一筆華語（傳承體）+ 一筆英文 expression：
- picker 第一步選「華語」、第二步選「傳承體」；確認提交 body 為 `{ language_profile_code: 'cmn-Hant', text, ... }`（瀏覽器 devtools network 驗證）。
- 單 profile variety（如 `und` 或單一 `ja`）picker 自動跳過第二步。

Expected：貢獻成功、`/language/cmn` 詳情頁 profile 篩選可見該筆、profile 篩選切換正確。

- [ ] **Step 7: 清理一次性中間產物**

```bash
rm -f backend/.wrangler/state.pre0016.bak  # 僅在驗證全通過後
```

> 保留 `scripts/v2/migrate_seed_to_varieties.py`（具稽核價值，記錄 variety 對應推導）。

- [ ] **Step 8: 總結 commit（若有殘留修正）**

若 Step 1-6 有修正，個別 commit；否則免。

---

## 驗收對照（spec §15）

| § | 驗收標準 | 對應 task |
|---|---|---|
| 1 | `language_varieties` + `language_profiles` 責任不重疊 | 3 |
| 2 | variety 有 ULID + 公開 code；外鍵用 ID，API/URL 用 code | 1, 5 |
| 3 | expression／ui_locales 引用 profile；location 引用 variety | 3, 8 |
| 4 | `/languages` 以 variety 為資源 | 6 |
| 5 | 新增 profile 不增語言數；刪最後 profile 被拒 | 5, 6, 15 |
| 6 | API/TS/文案不再用 `language` 指稱 profile | 8, 13, 14 |
| 7 | 同 variety profiles 可合併瀏覽／分別篩選，tag 不丟 | 6, 11 |
| 8 | 不自動合併／轉換簡繁，不改 mappings | 全域約束（無 task 動作＝驗收） |
| 9 | artifacts／schema／migration schema／夾具一致 | 3, 4, 15 |
| 10 | 舊規格已標 superseded | 14 |

