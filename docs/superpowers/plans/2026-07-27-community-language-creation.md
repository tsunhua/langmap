# Community Language Creation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓已驗證使用者按 BCP 47 規則建立 Glottolog 對齊或社群自定義的語言／方言 profile，並在所有詞句貢獻入口使用同一個可搜尋 picker。

**Architecture:** `languages.code` 繼續是 expression 與 UI locale 的穩定 canonical content tag；重建 `languages` 為單一 profile 主表，`languoids` 與 `language_subtags` 分別提供 pinned Glottolog 與 IANA 查詢。後端集中實作 registry validator、preview/create service 與已登記語言 guard；前端以共用 `LanguagePicker` 和四步 `LanguageCreateDialog` 接入各貢獻入口。

**Tech Stack:** Cloudflare Workers + Hono + D1 + TypeScript + Zod、Vue 3 `<script setup lang="ts">` + Pinia + vue-i18n + Vitest、Python 3 registry 生成工具。

## Global Constraints

- API prefix 固定為 `/api/v2`，回應格式使用 `{ success, data?, error?, message? }`。
- `languages.code` 建立後不可修改；既有 canonical code 原樣保留。
- public subtags 只接受 pinned IANA registry；Glottolog 只作可選對齊，不是建立門檻。
- `x-emoji`、`x-image` 是 system content，不得由建立器新增。
- 所有後端 mutation 必須確認 `languages.code` 真實存在，不能只靠 regex。
- 前端 API 一律經 `web/src/api/client.ts`；Vue 使用 `<script setup lang="ts">`，不得新增 `any`。
- 沿用 `web/src/assets/atlas.css` tokens、低圓角與現有圖示系統；觸控目標至少 44px。
- 複雜 picker 必須支援鍵盤、可見 focus、accessible name、錯誤關聯和焦點還原。
- 保留使用者既有未提交變更；不得修改 `apple/`、`web/dist/`、`backend/public/` 或 `.wrangler/`。
- 前端變更至少執行 `cd web && npm run test && npm run build`；後端整合測試前先啟動本地 Worker。
- 每個任務只提交本任務列出的檔案，commit 使用 Conventional Commit。

---

## File Map

### Registry and schema

- `scripts/v2/language_seed_profiles.json` — 明確列出最小 bootstrap language profiles；取代組合展開設定。
- `scripts/v2/sync_language_registry.py` — 下載／解析 pinned registries，生成 `languoids.csv`、`iana-subtags.json`、最小 `languages.csv` 和可執行的 `language-registry.sql`。
- `scripts/v2/test_language_data.py` — registry 生成、排序、seed validation 與 SQL import 測試。
- `scripts/v2/artifacts/language-registry-5.3/*` — 重新生成的 pinned artifacts。
- `backend/schema.sql` — 目標完整 schema。
- `backend/migrations/0010_rebuild_language_registry.sql` — 已有 D1 的單次重建 migration；只處理 schema 和明確 code mapping。
- `dev.sh`、`scripts/v2/migrate.sh`、`scripts/v2/README.md` — schema 後載入 pinned registry artifact。

### Backend

- `backend/src/types/language.ts` — language API/domain 型別。
- `backend/src/utils/languageCode.ts` — 純函式：結構化輸入正規化、private-use 驗證、tag 組裝。
- `backend/src/services/languageRegistry.ts` — IANA/Glottolog DB lookup、variant Prefix、direction、existing-language guard。
- `backend/src/services/languageCreation.ts` — preview、metadata validation、重複提示、rate limit 與 D1 batch create。
- `backend/src/routes/languageRegistry.ts` — IANA subtag lookup route。
- `backend/src/routes/languages.ts` — list/detail/preview/create。
- `backend/src/routes/languoids.ts` — 去重後的 Glottolog 搜尋。
- `backend/src/routes/expressions.ts`、`backend/src/routes/contributions.ts`、`backend/src/routes/localization.ts` — 共用 registered-language guard。
- `backend/tests/languageCode.test.ts`、`backend/tests/languageRegistry.test.ts` — 純規則測試。
- `backend/tests/languages.integration.test.ts` — HTTP preview/create/search/permission/race 測試。

### Frontend

- `web/src/api/languages.ts` — 完整 types 及 registry/preview/create API。
- `web/src/composables/useLanguageCreation.ts` — dialog state、cancelable search、preview/create。
- `web/src/components/language/LanguageSubtagSelect.vue` — ARIA combobox。
- `web/src/components/language/LanguageTagBuilder.vue` — BCP 47 分段組合。
- `web/src/components/language/GlottologMatchList.vue` — 明確 match/no-match 選擇。
- `web/src/components/language/LanguageMetadataForm.vue` — 名稱、說明、社群 metadata。
- `web/src/components/language/LanguageCreateDialog.vue` — 四步 dialog 與焦點管理。
- `web/src/components/language/LanguagePicker.vue` — searchable single-value picker 和建立入口。
- `web/src/components/language/LanguageSelect.vue` — 保留給 Search 的多選 filter，改用 typed server-side search；不提供建立入口。
- `web/src/components/language/*.test.ts` — builder、picker、dialog 行為測試。
- `web/src/pages/Contribute.vue`、`web/src/pages/MappingDetail.vue`、`web/src/pages/TranslateWorkbench.vue` — 接入共用 picker。
- `web/src/locales/en.ts` — 新增所有使用者文案。

---

### Task 1: Replace Registry Expansion with Explicit Seeds

**Files:**

- Create: `scripts/v2/language_seed_profiles.json`
- Modify: `scripts/v2/sync_language_registry.py`
- Modify: `scripts/v2/test_language_data.py`
- Delete: `scripts/v2/language_profiles.json`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/iana-subtags.json`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/languoids.csv`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/languages.csv`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/language-registry.sql`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/manifest.json`
- Regenerate: `scripts/v2/artifacts/language-registry-5.3/online-code-migrations.json`

**Interfaces:**

- Consumes: pinned Glottolog 5.3 CSV、IANA registry text、explicit seed JSON。
- Produces: `languages.csv` columns matching the new schema and an idempotent `language-registry.sql` that inserts `languoids`, `language_subtags`, and seed `languages`.

- [ ] **Step 1: Replace expansion tests with explicit-seed tests**

In `scripts/v2/test_language_data.py`, remove tests for `_profile_tags`, `major_regions`, Sinitic Cartesian expansion and generated IANA variants. Add tests with this contract:

```python
def test_seed_profiles_are_the_only_generated_languages(self):
    languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
    _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: nan
Description: Min Nan Chinese
Added: 2005-10-16
%%
Type: script
Subtag: Hant
Description: Han (Traditional variant)
Added: 2005-10-16
""")
    profiles = {
        "version": 2,
        "languages": [
            {
                "code": "nan-Hant-x-chao1238",
                "name": "潮州話",
                "name_en": "Chaozhou",
                "glottocode": "chao1238",
                "origin": "seed",
                "reason": "existing-online-code",
            },
            {
                "code": "x-emoji",
                "name": "Emoji 表情",
                "name_en": "Emoji",
                "glottocode": None,
                "origin": "system",
                "reason": "special-content",
            },
        ],
    }
    rows = list(seed_language_rows(
        profiles,
        subtags,
        {row.glottocode: row for row in languoids},
    ))
    self.assertEqual(
        [row["code"] for row in rows],
        ["nan-Hant-x-chao1238", "x-emoji"],
    )
    self.assertEqual(rows[0]["variety_key"], "glotto:chao1238")
    self.assertTrue(rows[1]["variety_key"].startswith("system:"))

def test_registry_sql_loads_into_canonical_schema(self):
    db = sqlite3.connect(":memory:")
    db.execute("PRAGMA foreign_keys=ON")
    db.executescript((ROOT.parent.parent / "backend/schema.sql").read_text())
    db.executescript(render_registry_sql(languoids, subtags, seed_rows))
    self.assertEqual(db.execute(
        "SELECT code FROM languages ORDER BY code"
    ).fetchall(), [("en-US",), ("x-emoji",)])
    self.assertGreater(db.execute(
        "SELECT COUNT(*) FROM language_subtags"
    ).fetchone()[0], 0)
```

- [ ] **Step 2: Run the script tests and confirm the old expansion contract fails**

Run:

```bash
cd scripts/v2
python3 -m unittest test_language_data.py
```

Expected: FAIL because `seed_language_rows` and `render_registry_sql` do not exist, and old `language_rows` behavior still expands profiles.

- [ ] **Step 3: Add the explicit seed manifest**

Create `scripts/v2/language_seed_profiles.json` with `version: 2` and an explicit `languages` array. Include every code in the current `required_online_codes`, plus `und`, `x-emoji`, `x-image`, and first-party `en-US`. Each entry must contain `code`, `name`, `name_en`, nullable `glottocode`, `origin`, and `reason`; do not include `major_regions`, `chinese_priority`, `variant_scripts`, or generated combinations.

Example entry:

```json
{
  "code": "nan-Latn-TW-tailo",
  "name": "臺灣台語（臺羅）",
  "name_en": "Taiwanese Hokkien (Tâi-lô)",
  "glottocode": "minn1241",
  "origin": "seed",
  "reason": "existing-online-code"
}
```

- [ ] **Step 4: Implement explicit seed parsing and structured BCP 47 extraction**

In `sync_language_registry.py`, replace `language_rows`, `_profile_tags`, `_special_content_rows`, and automatic variant generation with:

```python
LANGUAGE_FIELDS = (
    "code", "name", "name_en", "description", "direction",
    "base_language", "script_code", "region_code", "variants_json",
    "private_use_json", "variety_key", "glottocode", "origin",
    "community_reason", "alternate_names_json", "references_json",
    "parent_languoid_id", "latitude", "longitude",
)

def seed_language_rows(
    profiles: dict,
    subtags: list[Subtag],
    languoids_by_code: dict[str, Languoid],
) -> Iterator[dict[str, str]]:
    registered = {
        (row.type, row.value.lower()): row
        for row in subtags
        if not row.deprecated
    }
    seen: set[str] = set()
    for entry in sorted(profiles["languages"], key=lambda row: row["code"]):
        code = canonical_seed_code(entry["code"], registered)
        if code in seen:
            raise ValueError(f"duplicate seed code: {code}")
        seen.add(code)
        glottocode = entry.get("glottocode")
        languoid = languoids_by_code.get(glottocode) if glottocode else None
        if glottocode and languoid is None:
            raise ValueError(f"unknown Glottocode: {glottocode}")
        parts = split_canonical_seed_code(code)
        yield {
            "code": code,
            "name": entry["name"],
            "name_en": entry.get("name_en") or "",
            "description": entry.get("description") or "",
            "direction": direction_for_script(parts["script"]),
            "base_language": parts["language"],
            "script_code": parts["script"] or "",
            "region_code": parts["region"] or "",
            "variants_json": json.dumps(parts["variants"], separators=(",", ":")),
            "private_use_json": json.dumps(parts["private_use"], separators=(",", ":")),
            "variety_key": (
                f"glotto:{glottocode}" if glottocode else f"system:{code}"
            ),
            "glottocode": glottocode or "",
            "origin": entry["origin"],
            "community_reason": "",
            "alternate_names_json": "[]",
            "references_json": "[]",
            "parent_languoid_id": languoid.parent_id if languoid else "",
            "latitude": "" if not languoid or languoid.latitude is None else str(languoid.latitude),
            "longitude": "" if not languoid or languoid.longitude is None else str(languoid.longitude),
        }

def render_registry_sql(
    languoids: list[Languoid],
    subtags: list[Subtag],
    languages: list[dict[str, str]],
) -> str:
    statements = ["BEGIN;"]
    statements.extend(render_languoid_insert(row) for row in languoids)
    statements.extend(
        render_subtag_insert(row)
        for row in sorted(subtags, key=lambda row: (row.type, row.value.lower()))
    )
    statements.extend(
        render_language_insert(row)
        for row in sorted(languages, key=lambda row: row["code"])
    )
    statements.append("COMMIT;")
    return "\n".join(statements) + "\n"
```

`seed_language_rows` must:

- validate public subtags against IANA and Glottocode against `languoids_by_code`;
- preserve canonical casing and reject duplicate codes;
- derive `direction` from script;
- serialize arrays as compact JSON;
- set `variety_key = glotto:<code>` for aligned rows and `system:<code>` for special content.

`render_registry_sql` must emit parent-first languoids, sorted subtags, then sorted languages using `INSERT … ON CONFLICT DO UPDATE`; escape SQL quotes with a single shared `sql_literal` helper.

Implement these helpers in the same module so tests and generation share one path:

```python
def canonical_seed_code(
    value: str,
    registered: dict[tuple[str, str], Subtag],
) -> str

def split_canonical_seed_code(value: str) -> dict[str, object]

def direction_for_script(script: str | None) -> str

def sql_literal(value: object) -> str

def render_languoid_insert(row: Languoid) -> str

def render_subtag_insert(row: Subtag) -> str

def render_language_insert(row: dict[str, str]) -> str
```

`canonical_seed_code` accepts the supported public shape plus the two system codes, enforces IANA type/order/Prefix rules, and returns canonical casing. `split_canonical_seed_code` returns keys `language`, `script`, `region`, `variants`, and `private_use`; it never guesses a Glottolog link from private text.

- [ ] **Step 5: Regenerate artifacts and assert the registry is small**

Run:

```bash
cd scripts/v2
python3 sync_language_registry.py \
  --offline \
  --profiles language_seed_profiles.json \
  --output artifacts/language-registry-5.3
python3 -m unittest test_language_data.py
```

Expected: PASS; `manifest.json.generation.language_tag_count` equals the explicit seed count rather than approximately 22,000.

- [ ] **Step 6: Commit registry generation**

```bash
git add scripts/v2/language_seed_profiles.json \
  scripts/v2/sync_language_registry.py \
  scripts/v2/test_language_data.py \
  scripts/v2/artifacts/language-registry-5.3
git rm scripts/v2/language_profiles.json
git commit -m "refactor: generate explicit language registry seeds"
```

---

### Task 2: Rebuild the Language Schema and Loading Flow

**Files:**

- Modify: `backend/schema.sql`
- Create: `backend/migrations/0010_rebuild_language_registry.sql`
- Modify: `scripts/v2/language_migration.py`
- Modify: `scripts/v2/fixtures/language-migration.json`
- Modify: `scripts/v2/test_language_data.py`
- Modify: `dev.sh`
- Modify: `scripts/v2/migrate.sh`
- Modify: `scripts/v2/README.md`

**Interfaces:**

- Consumes: Task 1 `language-registry.sql` and explicit `online-code-migrations.json`.
- Produces: new `languages`/`language_subtags` schema, a fail-fast one-time migration, and a repeatable registry load command.

- [ ] **Step 1: Add schema contract and migration-manifest tests**

Extend `scripts/v2/test_language_data.py`:

```python
def test_language_schema_is_single_profile_table(self):
    schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
    self.assertIn("variety_key TEXT NOT NULL", schema)
    self.assertIn("CREATE TABLE language_subtags", schema)
    self.assertNotIn("language_varieties", schema)
    self.assertNotIn("languoid_id TEXT", schema)
    self.assertNotIn("is_active INTEGER", schema)

def test_language_migration_preserves_canonical_codes(self):
    manifest = {
        "mappings": {
            "en-US": {"action": "keep", "canonical": "en-US"},
            "nan-TW-Latn-tailo": {
                "action": "canonicalize",
                "canonical": "nan-Latn-TW-tailo",
            },
        }
    }
    self.assertEqual(validate_manifest(
        manifest, {"en-US", "nan-TW-Latn-tailo"}
    ), [])
```

- [ ] **Step 2: Run the tests and confirm the old schema fails**

Run:

```bash
cd scripts/v2
python3 -m unittest test_language_data.py
```

Expected: FAIL because `backend/schema.sql` still contains legacy language columns and lacks `language_subtags`.

- [ ] **Step 3: Replace the canonical `languages` definition**

Update `backend/schema.sql` to match spec §6 exactly. Create `language_subtags` after `languoids`, then create the single-profile `languages` table. Add indexes:

```sql
CREATE INDEX idx_languages_name ON languages(name);
CREATE INDEX idx_languages_variety_key ON languages(variety_key);
CREATE INDEX idx_languages_glottocode ON languages(glottocode);
CREATE INDEX idx_languages_base_script_region
  ON languages(base_language, script_code, region_code);
CREATE INDEX idx_language_subtags_search
  ON language_subtags(type, subtag);
```

Rebuild `expressions` in the canonical schema with:

```sql
FOREIGN KEY (language_code) REFERENCES languages(code)
```

Keep the existing `ui_locales(code) → languages(code)` foreign key.

- [ ] **Step 4: Write the one-time D1 migration**

Create `backend/migrations/0010_rebuild_language_registry.sql`. It must:

1. `PRAGMA foreign_keys = OFF`;
2. create `language_subtags` and `languages_new` without renaming the existing parent table;
3. copy every preflight-approved legacy row into `languages_new`, using `migration:<canonical-code>` when no Glottocode exists;
4. apply only the reviewed explicit canonical mappings while copying and while updating child tables;
5. explicitly update the two known noncanonical online tags:

```sql
UPDATE expressions
SET language_code = 'nan-Latn-TW-tailo'
WHERE language_code = 'nan-TW-Latn-tailo';

UPDATE expressions
SET language_code = 'nan-Latn-TW-pehoeji'
WHERE language_code = 'nan-TW-Latn-pehoeji';
```

Apply equivalent updates to `language_stats` and `ui_locales`. Do not guess any other mapping. Drop the old `languages`, rename `languages_new` to `languages`, recreate indexes, re-enable foreign keys, and finish with foreign-key and orphan checks that abort through a temporary `CHECK (ok = 1)` table when any referenced code is absent. Creating `languages_new` first keeps child foreign-key declarations pointing at the final table name instead of being rewritten to a temporary legacy name.

- [ ] **Step 5: Make migration manifest validation preserve case**

In `language_migration.py`, stop comparing duplicate targets with `.lower()` because BCP 47 canonical casing is meaningful to this migration report. Validate the supported shape through the same structural rules as `sync_language_registry.py`, while still allowing `x-emoji` and `x-image`.

- [ ] **Step 6: Load pinned registry after schema/migrations**

Update `dev.sh` so an empty DB runs `schema.sql` and then:

```bash
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$LOCAL_D1_STATE" \
  --file="$ROOT/scripts/v2/artifacts/language-registry-5.3/language-registry.sql"
```

For an existing local DB, run D1 migrations and then apply the idempotent registry SQL. Add the same registry load immediately after schema creation in `scripts/v2/migrate.sh` `setup`, `load_local`, and `load_remote`.

- [ ] **Step 7: Verify schema, migration, and loader**

Run:

```bash
language_schema_state="$(mktemp -d)"
cd scripts/v2
python3 -m unittest test_language_data.py
cd ../../backend
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$language_schema_state" \
  --file=./schema.sql
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$language_schema_state" \
  --file=../scripts/v2/artifacts/language-registry-5.3/language-registry.sql
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$language_schema_state" \
  --command="PRAGMA foreign_key_check; SELECT COUNT(*) AS subtags FROM language_subtags; SELECT COUNT(*) AS languages FROM languages;"
```

Expected: no foreign-key rows; subtag count is nonzero; language count equals the seed count.

- [ ] **Step 8: Commit schema and loading flow**

```bash
git add backend/schema.sql \
  backend/migrations/0010_rebuild_language_registry.sql \
  scripts/v2/language_migration.py \
  scripts/v2/fixtures/language-migration.json \
  scripts/v2/test_language_data.py \
  scripts/v2/README.md \
  scripts/v2/migrate.sh \
  dev.sh
git commit -m "feat: rebuild language registry schema"
```

---

### Task 3: Implement Canonical Tag and Registry Services

**Files:**

- Create: `backend/src/types/language.ts`
- Modify: `backend/src/utils/languageCode.ts`
- Create: `backend/src/services/languageRegistry.ts`
- Modify: `backend/tests/languageCode.test.ts`
- Create: `backend/tests/languageRegistry.test.ts`

**Interfaces:**

- Consumes: `language_subtags`, `languoids`, and `languages` from Task 2.
- Produces:
  - `canonicalizeLanguageTag(input: LanguageSubtags): CanonicalLanguageTag | null`
  - `validateLanguageTag(db, input): Promise<RegistryValidation>`
  - `requireRegisteredLanguage(db, code): Promise<LanguageRow | null>`
  - shared `LanguageSubtags`, `LanguageRow`, `LanguagePreview` types.

- [ ] **Step 1: Write failing canonicalization tests**

Replace the old “private use must be one Glottocode” contract in `backend/tests/languageCode.test.ts`:

```ts
expect(canonicalizeLanguageTag({
  language: 'YUE',
  script: 'hant',
  region: 'cn',
  variants: [],
  private_use: ['HeguSan'],
})).toEqual({
  code: 'yue-Hant-CN-x-hegusan',
  language: 'yue',
  script: 'Hant',
  region: 'CN',
  variants: [],
  private_use: ['hegusan'],
})

expect(canonicalizeLanguageTag({
  language: 'en',
  script: null,
  region: null,
  variants: [],
  private_use: ['too-long-raw'],
})).toBeNull()
```

Retain tests for system codes only in `parseStoredLanguageCode`; user creation must reject them.

- [ ] **Step 2: Write failing registry-service tests with a fake D1 adapter**

In `backend/tests/languageRegistry.test.ts`, use a minimal fake object implementing `prepare().bind().first()/all()` and assert:

- unknown language/script/region rejects with `INVALID_LANGUAGE_SUBTAG`;
- deprecated IANA value returns its preferred value warning;
- invalid variant Prefix returns `INVALID_VARIANT_PREFIX`;
- selected Glottocode must exist and be active;
- direction is `rtl` for `Arab`, otherwise `ltr`;
- `requireRegisteredLanguage` returns null for syntax-valid but unregistered code.

- [ ] **Step 3: Run unit tests and confirm missing interfaces**

```bash
cd backend
npm test -- tests/languageCode.test.ts tests/languageRegistry.test.ts
```

Expected: FAIL because the new types and functions are not implemented.

- [ ] **Step 4: Implement domain types and pure tag canonicalizer**

Create `backend/src/types/language.ts`:

```ts
export interface LanguageSubtags {
  language: string
  script: string | null
  region: string | null
  variants: string[]
  private_use: string[]
}

export interface CanonicalLanguageTag extends LanguageSubtags {
  code: string
}

export interface LanguageRow {
  code: string
  name: string
  name_en: string | null
  description: string
  direction: 'ltr' | 'rtl'
  base_language: string
  script_code: string | null
  region_code: string | null
  variants: string[]
  private_use: string[]
  variety_key: string
  glottocode: string | null
  origin: 'seed' | 'glottolog' | 'community' | 'system'
}

export interface LanguagePreview {
  canonical_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_language: LanguageRow | null
  profiles: LanguageRow[]
  similar: LanguageRow[]
  required_metadata: string[]
}
```

Refactor `languageCode.ts` into:

```ts
export function canonicalizeLanguageTag(
  input: LanguageSubtags,
): CanonicalLanguageTag | null

export function parseStoredLanguageCode(
  value: string,
): CanonicalLanguageTag | { code: 'x-emoji' | 'x-image' } | null
```

Do not infer Script/REGION from subtag length after parsing arbitrary order; construct only from typed input.

- [ ] **Step 5: Implement DB-backed registry validation**

Create `languageRegistry.ts` with parameterized queries and exported functions:

```ts
export async function validateLanguageTag(
  db: D1Database,
  input: LanguageSubtags,
): Promise<{
  tag: CanonicalLanguageTag
  warnings: string[]
  direction: 'ltr' | 'rtl'
}>

export async function requireRegisteredLanguage(
  db: D1Database,
  code: string,
): Promise<LanguageRow | null>
```

Validate each variant’s `prefixes_json` against the canonical public prefix (`language[-Script][-REGION][-prior variants]`). JSON parse failures are server data errors, not user validation errors.

- [ ] **Step 6: Run unit tests**

```bash
cd backend
npm test -- tests/languageCode.test.ts tests/languageRegistry.test.ts
```

Expected: PASS.

- [ ] **Step 7: Commit canonical language services**

```bash
git add backend/src/types/language.ts \
  backend/src/utils/languageCode.ts \
  backend/src/services/languageRegistry.ts \
  backend/tests/languageCode.test.ts \
  backend/tests/languageRegistry.test.ts
git commit -m "feat: validate canonical language tags"
```

---

### Task 4: Add Registry Lookup, Preview, and Create APIs

**Files:**

- Create: `backend/src/services/languageCreation.ts`
- Create: `backend/src/routes/languageRegistry.ts`
- Modify: `backend/src/routes/index.ts`
- Modify: `backend/src/routes/languages.ts`
- Modify: `backend/src/routes/languoids.ts`
- Modify: `backend/src/utils/response.ts`
- Create: `backend/tests/languages.integration.test.ts`

**Interfaces:**

- Consumes: Task 3 validator/types.
- Produces:
  - `GET /api/v2/language-registry/subtags`
  - corrected `GET /api/v2/languoids`
  - `POST /api/v2/languages/preview`
  - `POST /api/v2/languages`
  - searchable/list/detail language responses used by Task 6.

- [ ] **Step 1: Write HTTP integration tests**

Create `languages.integration.test.ts` using the existing `BASE_URL` pattern. Include:

```ts
it('previews and creates an unmatched community variety', async () => {
  const token = await register(`lang-${Date.now()}`)
  const payload = {
    subtags: {
      language: 'yue', script: 'Hant', region: 'CN',
      variants: [], private_use: [`hegu${Date.now().toString(36).slice(-4)}`],
    },
    glottocode: null,
    language: {
      name: '河谷新村話',
      name_en: null,
      description: '由當地社群使用的粵語變種。',
      reason: 'missing_from_glottolog',
      alternate_names: [],
      references: [],
      parent_languoid_id: null,
      latitude: null,
      longitude: null,
    },
  }
  const preview = await post('/api/v2/languages/preview', token, payload)
  expect(preview.status).toBe(200)
  expect((await preview.json()).data.existing_language).toBeNull()

  const created = await post('/api/v2/languages', token, payload)
  expect(created.status).toBe(201)
  expect((await created.json()).data.language).toMatchObject({
    origin: 'community',
    glottocode: null,
  })
})
```

Also cover unauthenticated `401`, exact duplicate `409`, missing metadata `400`, invalid IANA subtag, invalid Glottocode, daily limit `429`, explicit link/no-link semantics, and `/languoids` returning one row with `profiles[]` rather than duplicate rows.

- [ ] **Step 2: Start Worker and confirm new route tests fail**

Terminal 1:

```bash
./dev.sh
```

Terminal 2:

```bash
cd backend
npm run test:integration -- tests/languages.integration.test.ts
```

Expected: FAIL with 404 for registry/preview/create routes.

- [ ] **Step 3: Add `tooManyRequests` response helper**

In `response.ts`:

```ts
export const tooManyRequests = (
  c: Context,
  error = 'RATE_LIMITED',
  message?: string,
) => c.json<ErrorResponse>({ success: false, error, message }, 429)
```

- [ ] **Step 4: Implement subtag and languoid lookup routes**

Create `languageRegistry.ts`; reject missing/invalid `type`, clamp limit to 50, cap `q` at 80 code points, escape `%`, `_`, and `\`, and query with `LIKE ? ESCAPE '\'`.

Refactor `languoids.ts` to:

- require two characters for fuzzy `q`, while allowing exact 8-character Glottocode;
- query languoids first with stable ranking;
- load profiles in a second query keyed by returned Glottocodes;
- return each languoid once with `profiles: [{ code, name, script_code, region_code }]`.

- [ ] **Step 5: Implement preview/create service**

Create `languageCreation.ts`:

```ts
export async function previewLanguage(
  db: D1Database,
  body: unknown,
): Promise<LanguagePreview>

export async function createLanguage(
  db: D1Database,
  userId: number,
  body: unknown,
): Promise<LanguageRow>
```

Use Zod schemas with exact caps from the spec. `previewLanguage` must return `canonical_code`, `direction`, `warnings`, `existing_language`, same-variety `profiles`, `similar`, and `required_metadata`.

For Glottolog:

```ts
const varietyKey = glottocode
  ? `glotto:${glottocode}`
  : `community:${crypto.randomUUID()}`
```

For the daily limit, use the existing table:

```sql
SELECT COUNT(*) AS count
FROM languages
WHERE created_by = ?
  AND created_at >= datetime('now', '-1 day')
```

No rate-limit table is added. Make the final write race-safe with a conditional insert:

```sql
INSERT INTO languages (
  code, name, name_en, description, direction, base_language,
  script_code, region_code, variants_json, private_use_json,
  variety_key, glottocode, origin, community_reason,
  alternate_names_json, references_json, parent_languoid_id,
  latitude, longitude, created_by
)
SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
WHERE (
  SELECT COUNT(*) FROM languages
  WHERE created_by = ? AND created_at >= datetime('now', '-1 day')
) < 10
```

Check `meta.changes`: zero changes with no duplicate means `RATE_LIMITED`; a unique-code race means `LANGUAGE_CODE_EXISTS`.

- [ ] **Step 6: Enforce verified email at create time**

`POST /languages/preview` uses `requireAuth`. `POST /languages` uses `requireAuth`, then queries:

```sql
SELECT email_verified FROM users WHERE id = ?
```

Return `403 VERIFIED_EMAIL_REQUIRED` unless the value is `1`; do not rely on the current JWT, which does not carry email verification.

- [ ] **Step 7: Refactor language list/detail and register routes**

Register `api.route('/language-registry', languageRegistry)`. In `languages.ts`:

- define `/preview` before `/:code`;
- define `POST /` before detail routes;
- search code/name/name_en/glottocode and JSON aliases with escaped LIKE;
- map JSON text columns to arrays;
- return nested `language` without legacy `languoid_id`;
- use stable sort `expression_count DESC, name ASC, code ASC` or `name ASC, code ASC`.

- [ ] **Step 8: Run integration and unit tests**

```bash
cd backend
npm test
npm run test:integration -- tests/languages.integration.test.ts
```

Expected: all tests PASS.

- [ ] **Step 9: Commit language APIs**

```bash
git add backend/src/services/languageCreation.ts \
  backend/src/routes/languageRegistry.ts \
  backend/src/routes/index.ts \
  backend/src/routes/languages.ts \
  backend/src/routes/languoids.ts \
  backend/src/utils/response.ts \
  backend/tests/languages.integration.test.ts
git commit -m "feat: add community language creation API"
```

---

### Task 5: Enforce the Registered-Language Boundary Everywhere

**Files:**

- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/contributions.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/tests/expressions-mappings.test.ts`
- Modify: `backend/tests/localization.test.ts`
- Modify: `backend/tests/languages.integration.test.ts`

**Interfaces:**

- Consumes: `requireRegisteredLanguage(db, code)` from Task 3.
- Produces: every content mutation rejects canonical-looking but unregistered tags with `INVALID_LANGUAGE_CODE`.

- [ ] **Step 1: Add failing mutation-boundary tests**

Add HTTP cases:

```ts
const expressionResponse = await fetch(`${BASE_URL}/api/v2/expressions`, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    text: 'not allowed',
    language_code: 'en-x-unlisted',
  }),
})
expect(expressionResponse.status).toBe(400)
expect((await expressionResponse.json()).error).toBe('INVALID_LANGUAGE_CODE')

const contributionResponse = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    authorization: `Bearer ${token}`,
  },
  body: JSON.stringify({
    expressions: [
      { lang: 'en-US', text: 'known' },
      { lang: 'en-x-unlisted', text: 'unknown' },
    ],
  }),
})
expect(contributionResponse.status).toBe(400)
expect((await contributionResponse.json()).error).toBe('INVALID_LANGUAGE_CODE')
```

In localization tests, assert locale creation and translation target creation require a row in `languages`.

- [ ] **Step 2: Run integration tests and confirm leakage**

```bash
cd backend
npm run test:integration -- \
  tests/expressions-mappings.test.ts \
  tests/languages.integration.test.ts
```

Expected: at least contribution accepts or reaches insertion with an unregistered code because it lacks the common guard.

- [ ] **Step 3: Apply the guard before any expression ID or D1 batch work**

In `expressions.ts`, replace the syntax-only check with:

```ts
const language = await requireRegisteredLanguage(c.env.DB, languageCode)
if (!language) {
  return badRequest(
    c,
    'INVALID_LANGUAGE_CODE',
    'language_code must reference a registered language',
  )
}
```

In `contributions.ts`, deduplicate language codes, validate all of them before computing IDs/statements, and return one error containing `details: { codes: string[] }`.

In `localization.ts`, use the same guard for locale creation and mapping target locale; retain UI locale status checks after registry existence is confirmed.

- [ ] **Step 4: Run the complete backend suite**

```bash
cd backend
npm test
npm run test:integration
```

Expected: PASS with a running Worker and seeded local D1.

- [ ] **Step 5: Commit registered-language guards**

```bash
git add backend/src/routes/expressions.ts \
  backend/src/routes/contributions.ts \
  backend/src/routes/localization.ts \
  backend/tests/expressions-mappings.test.ts \
  backend/tests/localization.test.ts \
  backend/tests/languages.integration.test.ts
git commit -m "fix: require registered language codes"
```

---

### Task 6: Add Typed Frontend APIs and Creation State

**Files:**

- Modify: `web/src/api/languages.ts`
- Create: `web/src/composables/useLanguageCreation.ts`
- Create: `web/src/composables/useLanguageCreation.test.ts`
- Modify: `web/src/stores/languages.ts`

**Interfaces:**

- Consumes: Task 4 HTTP contracts.
- Produces:
  - `listRegistryLanguages(query, signal?)`
  - `listLanguageSubtags(type, query, prefix?, signal?)`
  - `searchLanguoids(query, signal?)`
  - `previewLanguage(payload)`
  - `createLanguage(payload)`
  - `useLanguageCreation()` state/actions used by Task 7.

- [ ] **Step 1: Write composable race/cancellation tests**

Mock `@/api/languages` and assert only the latest lookup wins:

```ts
function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

it('ignores a stale subtag response', async () => {
  const first = deferred<RegistrySubtag[]>()
  const second = deferred<RegistrySubtag[]>()
  vi.mocked(listLanguageSubtags)
    .mockReturnValueOnce(first.promise)
    .mockReturnValueOnce(second.promise)

  const state = useLanguageCreation()
  const a = state.searchSubtags('language', 'z')
  const b = state.searchSubtags('language', 'zh')
  second.resolve([{ type: 'language', subtag: 'zh', descriptions: ['Chinese'] }])
  first.resolve([{ type: 'language', subtag: 'za', descriptions: ['Zhuang'] }])
  await Promise.all([a, b])
  expect(state.subtagOptions.value[0].subtag).toBe('zh')
})
```

- [ ] **Step 2: Run the focused frontend test and confirm failure**

```bash
cd web
npm test -- src/composables/useLanguageCreation.test.ts
```

Expected: FAIL because API types/composable do not exist.

- [ ] **Step 3: Define exact frontend payload and response types**

In `api/languages.ts`, export these exact public types; keep field names identical to backend JSON and do not introduce camelCase adapters:

```ts
export interface LanguageSubtags {
  language: string
  script: string | null
  region: string | null
  variants: string[]
  private_use: string[]
}

export interface RegistrySubtag {
  type: 'language' | 'script' | 'region' | 'variant'
  subtag: string
  descriptions: string[]
  prefixes: string[]
  preferred_value: string | null
  suppress_script: string | null
  deprecated_at: string | null
}

export interface RegistryLanguage {
  code: string
  name: string
  name_en: string | null
  description: string
  direction: 'ltr' | 'rtl'
  base_language: string
  script_code: string | null
  region_code: string | null
  variants: string[]
  private_use: string[]
  variety_key: string
  glottocode: string | null
  origin: 'seed' | 'glottolog' | 'community' | 'system'
  expression_count?: number
}

export interface LanguoidCandidate {
  id: string
  glottocode: string
  preferred_name: string
  level: 'language' | 'dialect'
  iso639_3: string | null
  parent_id: string | null
  parent_name: string | null
  source_version: string
  profiles: RegistryLanguage[]
}

export interface LanguagePreview {
  canonical_code: string
  direction: 'ltr' | 'rtl'
  warnings: string[]
  existing_language: RegistryLanguage | null
  profiles: RegistryLanguage[]
  similar: RegistryLanguage[]
  required_metadata: string[]
}

export interface CreateLanguagePayload {
  subtags: LanguageSubtags
  glottocode: string | null
  language: {
    name: string
    name_en: string | null
    description: string
    reason: 'missing_from_glottolog' | 'community_specific' | 'emerging_variety' | 'other' | null
    alternate_names: string[]
    references: string[]
    parent_languoid_id: string | null
    latitude: number | null
    longitude: number | null
  }
}

export type CreatedLanguage = RegistryLanguage
```

Implement `listRegistryLanguages`, `listLanguageSubtags`, `searchLanguoids`, `previewLanguage`, and `createLanguage`. Use Axios cancellation through `{ signal }` and unwrap `data.data`.

Implement Axios cancellation through `{ signal }` and unwrap `data.data`.

- [ ] **Step 4: Implement creation composable**

`useLanguageCreation` owns:

- `step: Ref<1 | 2 | 3 | 4>`;
- structured `subtags`;
- `glottocode: Ref<string | null>`;
- metadata draft;
- subtag/languoid options;
- loading/error/preview;
- one `AbortController` per search family and monotonically increasing request IDs;
- `reset()`, `searchSubtags()`, `searchLanguoids()`, `runPreview()`, `submit()`.

It must not own dialog DOM/focus; that stays in `LanguageCreateDialog`.

- [ ] **Step 5: Fix language store response shape and cache insertion**

Current `web/src/stores/languages.ts` assigns `data.data` although the API returns `{ items }`. Change it to use `listRegistryLanguages` and add:

```ts
function upsertLanguage(language: RegistryLanguage) {
  const index = languages.value.findIndex(item => item.code === language.code)
  if (index >= 0) languages.value[index] = language
  else languages.value.push(language)
  languages.value.sort((a, b) => a.name.localeCompare(b.name) || a.code.localeCompare(b.code))
}
```

- [ ] **Step 6: Run focused and full frontend tests**

```bash
cd web
npm test -- src/composables/useLanguageCreation.test.ts
npm test
```

Expected: PASS.

- [ ] **Step 7: Commit frontend language client**

```bash
git add web/src/api/languages.ts \
  web/src/composables/useLanguageCreation.ts \
  web/src/composables/useLanguageCreation.test.ts \
  web/src/stores/languages.ts
git commit -m "feat: add language creation client"
```

---

### Task 7: Build the Accessible Language Picker and Creation Dialog

**Files:**

- Create: `web/src/components/language/LanguageSubtagSelect.vue`
- Create: `web/src/components/language/LanguageSubtagSelect.test.ts`
- Create: `web/src/components/language/LanguageTagBuilder.vue`
- Create: `web/src/components/language/LanguageTagBuilder.test.ts`
- Create: `web/src/components/language/GlottologMatchList.vue`
- Create: `web/src/components/language/LanguageMetadataForm.vue`
- Create: `web/src/components/language/LanguageCreateDialog.vue`
- Create: `web/src/components/language/LanguageCreateDialog.test.ts`
- Create: `web/src/components/language/LanguagePicker.vue`
- Create: `web/src/components/language/LanguagePicker.test.ts`
- Modify: `web/src/components/language/LanguageSelect.vue`
- Modify: `web/src/locales/en.ts`

**Interfaces:**

- Consumes: Task 6 types/composable/store.
- Produces:
  - `LanguagePicker` props `{ modelValue: string; label: string; allowCreate?: boolean }`
  - emits `update:modelValue` and `created`
  - `LanguageTagBuilder` props `{ modelValue: LanguageSubtags }`
  - tag builder emits `update:modelValue` and `validityChange(boolean)`
  - `LanguageCreateDialog` props `{ open: boolean; returnFocus?: HTMLElement | null }`
  - dialog emits `created(language: RegistryLanguage)` and `close`.

- [ ] **Step 1: Write component tests before markup**

Required tests:

```ts
it('supports keyboard selection in the subtag combobox', async () => {
  const wrapper = mount(LanguageSubtagSelect, {
    props: { label: 'Language', modelValue: '', options },
  })
  await wrapper.get('input[role="combobox"]').trigger('focus')
  await wrapper.get('input').trigger('keydown', { key: 'ArrowDown' })
  await wrapper.get('input').trigger('keydown', { key: 'Enter' })
  expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['zh'])
})

it('clears invalid variants when a prefix field changes', async () => {
  const wrapper = mount(LanguageTagBuilder, { props: { modelValue: withVariant } })
  await wrapper.get('[data-field="language"] input').setValue('en')
  expect(wrapper.emitted('update:modelValue')?.at(-1)?.[0].variants).toEqual([])
  expect(wrapper.get('[role="status"]').text()).toContain('removed')
})

it('requires an explicit Glottolog choice', async () => {
  const wrapper = mount(LanguageCreateDialog, {
    props: { open: true },
    global: {
      stubs: {
        LanguageTagBuilder: {
          emits: ['validityChange'],
          template: '<button data-test="valid-tag" @click="$emit(`validityChange`, true)">valid</button>',
        },
      },
    },
  })
  await wrapper.get('[data-test="valid-tag"]').trigger('click')
  await wrapper.get('[data-action="next"]').trigger('click')
  expect(wrapper.get('[data-action="next"]').attributes('disabled')).toBeDefined()
  await wrapper.get('[data-choice="no-match"]').trigger('click')
  expect(wrapper.get('[data-action="next"]').attributes('disabled')).toBeUndefined()
})

it('restores focus to the picker after closing', async () => {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const wrapper = mount(LanguagePicker, {
    attachTo: host,
    props: {
      modelValue: '',
      label: 'Language',
      allowCreate: true,
    },
    global: {
      stubs: {
        LanguageCreateDialog: {
          props: ['open'],
          emits: ['close'],
          template: '<button v-if="open" data-action="close-dialog" @click="$emit(`close`)">close</button>',
        },
      },
    },
  })
  await wrapper.get('[data-action="create-language"]').trigger('click')
  await wrapper.get('[data-action="close-dialog"]').trigger('click')
  expect(document.activeElement).toBe(wrapper.get('[role="combobox"]').element)
})
```

- [ ] **Step 2: Run component tests and confirm missing components**

```bash
cd web
npm test -- src/components/language
```

Expected: FAIL because the components do not exist.

- [ ] **Step 3: Implement the typed subtag combobox and tag builder**

`LanguageSubtagSelect` follows ARIA combobox/listbox:

- input has `role="combobox"`, `aria-expanded`, `aria-controls`, `aria-activedescendant`;
- list has `role="listbox"`, options have `role="option"`;
- ArrowUp/ArrowDown move active option, Enter selects, Escape closes;
- every interactive control is at least 44px.

`LanguageTagBuilder` renders fields in fixed BCP 47 order, calls the composable for options, and emits structured subtags only. It displays the client preview but labels it as provisional.

- [ ] **Step 4: Implement explicit Glottolog matching and metadata form**

`GlottologMatchList` renders candidate details and two radio-like choices: exact candidate or “Glottolog 沒有合適項目”. It never auto-selects the first result.

`LanguageMetadataForm` enforces visible labels and client caps but leaves authoritative validation to the backend. Community-only `reason` appears only when `glottocode === null`.

- [ ] **Step 5: Implement four-step dialog and focus lifecycle**

Use native `<dialog>` only if existing jsdom/browser behavior remains consistent; otherwise use `role="dialog" aria-modal="true"` with:

- focus trap across tabbable elements;
- Escape close;
- initial focus on first field;
- return focus supplied by parent;
- draft retained while parent page remains mounted;
- backend errors associated with the current field or an alert summary.

On success, emit the created language and reset only after the parent accepts it.

- [ ] **Step 6: Implement the reusable single-value picker**

`LanguagePicker` must:

- search server-side after 2 characters;
- show current selected name/code;
- allow clearing only when the parent permits an empty value;
- show “新增語言或方言” only when logged in and `allowCreate !== false`;
- open `LanguageCreateDialog`;
- insert the created language into the store, select its canonical code, and emit `created`.

- [ ] **Step 7: Preserve the Search page multi-select**

Refactor the existing `LanguageSelect.vue` to use `listRegistryLanguages(query, signal)` and the corrected typed store. Keep its existing `modelValue: string[]` contract for `Search.vue`, do not expose “新增語言或方言” from this read-only filter, and retain keyboard-accessible removal buttons.

- [ ] **Step 8: Add all UI copy to the English source catalog**

Add a `languageCreate` section to `web/src/locales/en.ts` covering step names, field labels, provisional preview, match/no-match, metadata, warnings, errors, next/back/create/close, existing-language action, and live-region variant removal. Do not hard-code user-visible English in components.

- [ ] **Step 9: Run component tests, i18n check, and build**

```bash
cd web
npm test -- src/components/language
npm run i18n:check
npm run build
```

Expected: PASS.

- [ ] **Step 10: Commit picker and dialog**

```bash
git add web/src/components/language \
  web/src/locales/en.ts
git commit -m "feat: build accessible language creation dialog"
```

---

### Task 8: Integrate the Picker into Every Creation Entry Point

**Files:**

- Modify: `web/src/pages/Contribute.vue`
- Modify: `web/src/pages/MappingDetail.vue`
- Modify: `web/src/pages/TranslateWorkbench.vue`
- Create: `web/src/pages/Contribute.test.ts`
- Create: `web/src/pages/MappingDetail.language.test.ts`
- Create: `web/src/pages/TranslateWorkbench.language.test.ts`
- Modify: `web/src/locales/en.ts`

**Interfaces:**

- Consumes: `LanguagePicker` from Task 7.
- Produces: no remaining free-text language code input in expression/mapping/localization creation.

- [ ] **Step 1: Write page integration tests**

For each page, stub `LanguagePicker` with a component that emits `update:modelValue` and `created`. Assert:

- Contribute keeps one code per row and submits canonical codes unchanged.
- MappingDetail quick-add sends the selected code and preserves text when the create dialog completes.
- TranslateWorkbench selects a newly created language, calls `addUiLocale(code)`, then navigates to `/translate/<encoded-code>`.

Example:

```ts
await picker.vm.$emit('update:modelValue', 'yue-Hant-CN-x-hegusan')
await wrapper.get('[data-action="submit-contribution"]').trigger('click')
expect(api.post).toHaveBeenCalledWith('/contributions/batch', {
  expressions: expect.arrayContaining([
    expect.objectContaining({ lang: 'yue-Hant-CN-x-hegusan' }),
  ]),
})
```

- [ ] **Step 2: Run the page tests and confirm free-text inputs fail the contract**

```bash
cd web
npm test -- \
  src/pages/Contribute.test.ts \
  src/pages/MappingDetail.language.test.ts \
  src/pages/TranslateWorkbench.language.test.ts
```

Expected: FAIL because the pages still render `<input>`/`<select>` instead of `LanguagePicker`.

- [ ] **Step 3: Replace Contribute row language inputs**

Render one `LanguagePicker` per row with `v-model="row.lang"`. Preserve row keys so opening/closing a dialog cannot move state to a different row. Update mobile CSS so the picker gets a full-width row below 760px and all controls retain 44px targets.

- [ ] **Step 4: Replace MappingDetail quick-add language input**

Use `LanguagePicker v-model="quickAddLang"`. Opening language creation must not clear `quickAddText` or `quickAddRegion`; after creation, the returned code becomes `quickAddLang`.

- [ ] **Step 5: Replace TranslateWorkbench target selector**

Use `LanguagePicker` for target locale selection. On a newly created language:

1. call `addUiLocale(code)`;
2. refresh locales;
3. navigate using `encodeURIComponent(code)`;
4. preserve the reference locale unless it equals the new target.

Keep reference-language selection restricted to existing UI locales; it does not need a creation button.

- [ ] **Step 6: Run page tests and full frontend verification**

```bash
cd web
npm test
npm run i18n:check
npm run build
```

Expected: PASS.

- [ ] **Step 7: Commit entry-point integration**

```bash
git add web/src/pages/Contribute.vue \
  web/src/pages/MappingDetail.vue \
  web/src/pages/TranslateWorkbench.vue \
  web/src/pages/Contribute.test.ts \
  web/src/pages/MappingDetail.language.test.ts \
  web/src/pages/TranslateWorkbench.language.test.ts \
  web/src/locales/en.ts
git commit -m "feat: use language picker in contribution flows"
```

---

### Task 9: End-to-End Verification and Documentation

**Files:**

- Modify: `scripts/v2/README.md`
- Modify: `docs/superpowers/specs/2026-07-27-community-language-creation.md` only if verification reveals a contract correction

**Interfaces:**

- Consumes: Tasks 1–8.
- Produces: reproducible setup instructions and evidence that schema, API, desktop/mobile UI, and legacy codes work together.

- [ ] **Step 1: Run registry and schema verification from a clean local D1**

Use a dedicated temporary Wrangler persistence directory rather than deleting the user’s existing `.wrangler` state:

```bash
registry_state="$(mktemp -d)"
cd backend
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$registry_state" \
  --file=./schema.sql
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$registry_state" \
  --file=../scripts/v2/artifacts/language-registry-5.3/language-registry.sql
npx wrangler d1 execute langmap-v2 --local \
  --persist-to "$registry_state" \
  --command="PRAGMA foreign_key_check; SELECT code FROM languages ORDER BY code;"
```

Expected: no foreign-key violations; output contains all explicit seeds and no expanded registry rows.

- [ ] **Step 2: Run every automated suite**

```bash
cd scripts/v2
python3 -m unittest test_language_data.py
npm test

cd ../../backend
npm test

cd ../web
npm test
npm run i18n:check
npm run build

cd ..
./build.sh
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 3: Run backend integration tests against seeded local D1**

Terminal 1:

```bash
./dev.sh
```

Terminal 2:

```bash
cd backend
npm run test:integration
```

Expected: all integration tests PASS, including community creation and registered-language rejection.

- [ ] **Step 4: Perform browser verification at required viewports**

Check at desktop `1440×900` and mobile `390×844`:

1. Contribute → language search → no result → create community variant → selected code remains in row.
2. Mapping detail quick add → create Glottolog-aligned profile → text and region remain populated.
3. Translation workbench → create language → add as UI locale → route changes correctly.
4. Keyboard-only flow completes all four dialog steps.
5. Escape closes dialog, focus returns to picker, focus ring is visible.
6. Long language names/private tags wrap without horizontal page overflow.
7. At 200% zoom, dialog actions and errors remain reachable.

Record any defect as a failing component/page test before fixing it.

- [ ] **Step 5: Update setup documentation**

Document:

- how to regenerate pinned registry artifacts offline;
- that schema/migrations must be followed by `language-registry.sql`;
- how explicit seeds replace combination expansion;
- how to run focused backend/frontend tests;
- that existing canonical codes remain unchanged.

- [ ] **Step 6: Final verification after documentation**

```bash
git diff --check
git status --short
```

Expected: only the planned files are modified; no generated `web/dist/`, `backend/public/`, `.wrangler/`, credentials, or `node_modules/` are staged.

- [ ] **Step 7: Commit verification documentation**

```bash
git add scripts/v2/README.md \
  docs/superpowers/specs/2026-07-27-community-language-creation.md
git commit -m "docs: document community language registry workflow"
```
