# V1 → V2 生產環境資料遷移與部署計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在已新建的 production V2 D1 上重建 v2 資料表，將 v1 的使用者、手冊與用戶創建詞句遷移過去，並部署新的 backend Worker 上線。

**Architecture:** 遷移採用「新 D1 + 切換」策略（方案 B）：保留舊 V1 D1 不動作為回退點，在新建的 `langmap-v2` D1 上重建 v2 schema，以 Python 遷移腳本將 v1 快照資料轉換後寫入，最後將 `wrangler.jsonc` 指向新 DB（已指向 `69a50b71-8cff-4e50-9e73-1e9020d34bd3`）並部署 Worker。遷移腳本以 `scripts/db` 現有工具鏈為骨架，新增 v1→v2 轉換層，並以本地 D1 全流程演練後才對 production 執行。

**Tech Stack:** Python 3（遷移腳本）、Cloudflare Wrangler v4（D1 CLI）、D1 SQLite、TypeScript（backend auth 相容層）、Vitest（backend 測試）。

## Global Constraints

- **Grammar 擴充（已確認）**：v2 locale code grammar 擴充為 `lang "-" script ("_" orthography)? "-" region ("_" place_segment)*`，其中 `orthography` 格式同 `place_segment`（`[A-Z][A-Za-z]*`），語義為書寫方案/正字法。範例：`nan-Latn_Pehoeji-TW`（閩南語、拉丁字母+白話字、台灣）。此變更影響 ADR 0004、spec 2026-08-11 §7.1、backend `languageIdentity.ts`、前端 preview helper、所有 seed/migration。
- Migration 資料來源：舊 production V1 D1 — `database_name=langmap`、`database_id=f21a787e-769f-45b3-bd1a-59d41b35ff12`（已確認）。優先以 `wrangler d1 export langmap --remote --output v1-full-dump.sql` 匯出後解析；若記憶體/工具不順，回退用 repo 內 `scripts/v2/remote-*.sql` 快照（但需先與舊庫 row count 對齊確認未過期）。
- 遷移範圍（已確認）：
  - 遷移 users（保持 v1 整數 id、password_hash 原樣）。
  - 遷移 handbooks + handbook_pages（解析 content → v2 sections/items）。
  - 遷移 user-created expressions（`created_by` 為真實用戶 ID 者；不遷移 `system` / `langmap` / `ai` / `opus` 等系統、UI 翻譯、匯入詞句）。
  - 不遷移：mappings、meanings、votes、collections、contributions、expression_versions、expression_meaning、language_stats、ui_locales、remote-meanings。
  - `email_verification_tokens`：**不遷移**（已確認）。遷移後用戶重新走驗證流程。
  - `image` / `emoji` 非語言 expressions：**遷移（已確認）**，`lang_code` 使用 `x-image` / `x-emoji`（非 ISO 自訂 code，明示違反 pinned ISO registry 不變量、以 migration report 記錄）；**不建立 language_locales**、不建立 locale attestations（v2 spec §8.4 允許 Expression 不帶 locale），`language_locales` 表不新增 `x-image-*` / `x-emoji-*` 條目。
  - `image` / `emoji` 的多語言名稱：v1 `languages` 表有 `name`（📸 (Image)、😀 (Emoji)）與各語 name，v2 `languages` 只有 `name_en` → 以 `('x-image', 'Image')`、`('x-emoji', 'Emoji')` 寫入 `languages`；其他語名不遷移（v2 模型不支援，寫入 migration report）。
- 密碼相容（已確認）：v1 使用 bcrypt `$2b$10$...`，v2 目前自訂 `salt:sha256` 格式。**必改** backend `verifyPassword` 支援 bcrypt 驗證，否則遷移用戶無法登入（Task 3）。
- 語言映射（已確認，最終版）：
  | v1 `language_code` | v2 `lang_code` | v2 `language_locale_code` |
  |---|---|---|
  | `zh-TW` | `cmn` | `cmn-Hant-TW` |
  | `zh-CN` | `cmn` | `cmn-Hans-CN` |
  | `en-US` | `eng` | `eng-Latn-US` |
  | `en-GB` | `eng` | `eng-Latn-GB` |
  | `ja-JP` | `jpn` | `jpn-Jpan-JP` |
  | `es-ES` | `spa` | `spa-Latn-ES` |
  | `yue-HK` | `yue` | `yue-Hant-HK`（新增 language + locale） |
  | `nan-TW` | `nan` | `nan-Hant-TW` |
  | `nan-x-cha` | `nan` | `nan-Hant-CN_Chaozhou` |
  | `nan-x-cha-jiazi` | `nan` | `nan-Hant-CN_LufengJiazi` |
| `nan-TW-POJ` | `nan` | `nan-Latn_Pehoeji-TW`（grammar 擴充後） |
| `nan-TW-TL` | `nan` | `nan-Latn_Tailo-TW`（grammar 擴充後） |
  | `cieh-tc` | `wuu` | `wuu-Hant-CN_Taizhou`（新增 language + locale） |
  | `wuu-sh` | `wuu` | `wuu-Hans-CN_Wenzhou`（新增 locale） |
  | `zyg-jx` | `zha` | `zha-Latn-CN_Jingxi`（新增 language + locale；script/region 依使用者原始意圖） |
  | `ral` | `ral` | `ral-Latn-IN`（新增 locale） |
  | `swh` | `swh` | `swh-Latn-TZ`（新增 locale） |
  | `image` / `emoji` | `x-image` / `x-emoji` | 無（不建 locale；Expression 以 lang_code 直接遷移） |
- 上述 locale 的 `name`/`name_en` 等欄位：遷移時以 v1 `languages.name` 填入 `name`（若含括號去除括號部分作為主要名稱）、`name_en` 以英文 exonym（無對應時用原 name）。座標沿用 v1 `region_latitude`/`region_longitude`（若存在）。`image`/`emoji` 例外（見上方規則）。
- v2 expression ID 規則（與 `backend/src/services/expressionIdentity.ts` 一致）：`text_hash = base32(sha256(text_nfc_trim)[0:16])` 轉 26 字元小寫；`id = {lang_code}:{text_hash}`；同語言同文字同 hash 重複時依序配置 `homograph_index` 為 2, 3, …（id 形如 `{lang}:{hash}.{n}`）。
- v1 expression 的 `desc` 轉 v2 `description`；`tags`（JSON 字串）轉 v2 `tags_json`；`review_status`、`created_by`、`created_at`、`updated_at` 原樣保留；`source_ref` 保留字串；`source_id` 以 system 來源（`(type='system', name='LangMap V1 migration')`）建立並指向之。
- 丟棄 v1 欄位：`meaning_id`、`audio_url`、`region_code`、`region_name`、`region_latitude`、`region_longitude`、`updated_by`（遷移後統一把 `updated_at` 設為 `created_at`）。
- Handbook 解析規則（預設，需確認）：以 `##` 標題建立 `handbook_sections`；同一 section 內出現的 `{{...}}` expression 引用建立 `handbook_section_items`；標題之下的自由文字段落在 v2 模型中無法表示，**捨棄**並寫入 migration report 的 `dropped_free_text` 計數。無法解析為 v2 expression 的 item（例如引用未遷移的系統詞句）**跳過不建立 item**，計入 migration report 的 `skipped_unmapped_items`。v1 `description` 沒有 v2 對應欄位，寫入 report 不寫入 DB。`is_public` 映射為 `visibility`（1→public, 0→private）；`status` 一律 `published`；`score` 沿用 v1 `score`（v1 無 score 時為 0）。v2 handbook `id` 重新以 `ulid()` 生成；v1 id 記錄於 migration report（`v1_handbook_id`）以備查核。
- v1 handbook content 中 `{{text:翁|mid:379213814}}` 或 `{{expression_id}}` 兩類標記都要解析：前者依 v1 expression 表中 id 對應關係反查 expression id（若 v1 expression 存在且屬遷移範圍），後者直接以 id 對應；找不到時跳過該 item（見上方規則）。
- `language_locales` 新增前，對應 `languages` 必須先存在（FK）。
- `scripts/db/manage.py` 的 `production.py INVENTORY_COUNTS_SQL` 仍引用 v1 時代的表（`languoids`、`language_locations`、`variety_key`、`glottocode`）——**必須先修正**，否則 inventory/verify 對新 v2 DB 會失敗（Task 1）。
- `scripts/db/migration-lock.json` 缺 `0022_script_region_name_expression_id.sql`——**執行 production 前必須以 `sync_migration_lock(update=True)` 重新鎖定**，否則 plan 會判定為 unlock 且阻塞（Task 1）。

---

### Task 0: 擴充 v2 grammar 支援 orthography 段（前置架構變更）

**Files:**
- Modify: `docs/adr/0004-language-codes-redesigned-around-iso639-3.md`（§2 grammar 定義）
- Modify: `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md`（§7.1 grammar）
- Modify: `backend/src/services/languageIdentity.ts`（`buildLanguageLocaleCode`、`parseLanguageLocaleCode`）
- Modify: `backend/src/types/language.ts`（`LanguageLocaleParts` 加入 `orthography?: string`）
- Modify: `web/src/` 前端 preview helper（需先定位）
- Modify: `backend/schema.sql`（更新 seed locale codes）
- Modify: `backend/migrations/`（更新 seed locale codes）
- Test: `backend/src/services/languageIdentity.test.ts`（新增 orthography 測試向量）

**Interfaces:**
- Consumes: 現有 v2 grammar 定義與實作。
- Produces: 支援 `lang-script_orthography-region(_place)*` 格式的 grammar。

**Grammar 定義：**

```text
language_locale_code = lang "-" script ("_" orthography)? "-" region ("_" place_segment)*
lang                 = [a-z]{3}
script               = [A-Z][a-z]{3}
orthography          = [A-Z][A-Za-z]*  (格式同 place_segment，語義為書寫方案/正字法)
region               = [A-Z]{2}
place_segment        = [A-Z][A-Za-z]*
```

**範例：**

- `nan-Latn-TW` — 閩南語，拉丁，台灣
- `nan-Latn_Pehoeji-TW` — 閩南語，拉丁+白話字，台灣
- `nan-Latn_Tailo-TW` — 閩南語，拉丁+臺羅，台灣
- `cmn-Hant-TW` — 華語，繁體，台灣
- `wuu-Hans-CN_Wenzhou` — 吳語，簡體，溫州

- [x] **Step 1: 更新 ADR 0004 §2 grammar 定義**

在 `docs/adr/0004-language-codes-redesigned-around-iso639-3.md` 的 grammar 段落加入 `orthography` 段說明：

```markdown
- `orthography`：可選，格式同 `place_segment`（`[A-Z][A-Za-z]*`），語義為書寫方案/正字法（如 `Pehoeji`、`Tailo`）。位於 script 之後、region 之前。
```

- [x] **Step 2: 更新 spec 2026-08-11 §7.1 grammar**

同步更新 `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md` §7.1。

- [x] **Step 3: 更新 backend `languageIdentity.ts`**

修改 `buildLanguageLocaleCode` 和 `parseLanguageLocaleCode`：

```typescript
// types/language.ts
export interface LanguageLocaleParts {
  lang_code: string;
  script_code: string;
  orthography?: string;  // 新增
  region_code: string;
  place_segments: string[];
}

// languageIdentity.ts
const ORTHOGRAPHY_RE = /^[A-Z][A-Za-z]*$/;

export function buildLanguageLocaleCode(input: {
  lang_code: string;
  script_code: string;
  orthography?: string;  // 新增
  region_code: string;
  place_segments?: string[];
}): string {
  const lang = input.lang_code.toLowerCase();
  const script = input.script_code;
  const orthography = input.orthography;
  const region = input.region_code;
  const segments = input.place_segments ?? [];
  
  if (!LANG_CODE_RE.test(lang)) throw new LanguageLocaleError('INVALID_LANG_CODE');
  if (!SCRIPT_CODE_RE.test(script)) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  if (orthography && !ORTHOGRAPHY_RE.test(orthography)) throw new LanguageLocaleError('INVALID_ORTHOGRAPHY');
  if (!REGION_CODE_RE.test(region)) throw new LanguageLocaleError('INVALID_REGION_CODE');
  for (const segment of segments) {
    if (!PLACE_SEGMENT_RE.test(segment)) throw new LanguageLocaleError('INVALID_PLACE_SEGMENT');
  }
  
  const orthographyPart = orthography ? `_${orthography}` : '';
  const placePath = segments.join('_');
  return `${lang}-${script}${orthographyPart}-${region}${placePath ? `_${placePath}` : ''}`;
}

export function parseLanguageLocaleCode(code: string): LanguageLocaleParts | null {
  if (!code) return null;
  const [head, ...segments] = code.split('_');
  // 新格式：lang-script_orthography-region 或 lang-script-region
  const match = /^([a-z]{3})-([A-Z][a-z]{3})(?:_([A-Z][A-Za-z]*))?-(?:[A-Z]{2})$/.exec(head ?? '');
  if (!match) return null;
  
  const [_, lang, script, orthography] = match;
  const regionMatch = /^([a-z]{3})-([A-Z][a-z]{3})(?:_[A-Z][A-Za-z]*)?-([A-Z]{2})$/.exec(head ?? '');
  if (!regionMatch) return null;
  
  const region = regionMatch[3];
  
  if (segments.some((segment) => segment === '' || !PLACE_SEGMENT_RE.test(segment))) return null;
  
  return {
    lang_code: lang,
    script_code: script,
    orthography: orthography || undefined,
    region_code: region,
    place_segments: segments,
  };
}
```

- [x] **Step 4: 更新前端 preview helper**

定位前端 locale code preview helper（可能在 `web/src/` 某處），同步更新 grammar。

- [x] **Step 5: 更新 seed locale codes**

在 `backend/schema.sql` 和 `backend/migrations/` 中，將 `nan-Latn-TW-Pehoeji` 改為 `nan-Latn_Pehoeji-TW`，`nan-Latn-TW-Tailo` 改為 `nan-Latn_Tailo-TW`。

- [x] **Step 6: 新增測試向量**

在 `backend/src/services/languageIdentity.test.ts` 新增：

```typescript
it('builds locale code with orthography', () => {
  expect(buildLanguageLocaleCode({
    lang_code: 'nan',
    script_code: 'Latn',
    orthography: 'Pehoeji',
    region_code: 'TW',
  })).toBe('nan-Latn_Pehoeji-TW');
});

it('parses locale code with orthography', () => {
  const parts = parseLanguageLocaleCode('nan-Latn_Pehoeji-TW');
  expect(parts).toEqual({
    lang_code: 'nan',
    script_code: 'Latn',
    orthography: 'Pehoeji',
    region_code: 'TW',
    place_segments: [],
  });
});
```

- [x] **Step 7: 執行測試確認無回歸**

```bash
cd backend && npm test
cd web && npm test
```

- [x] **Step 8: Commit**

```bash
git add docs/adr docs/superpowers/specs backend/src web/src backend/schema.sql backend/migrations
git commit -m "feat(locale): expand grammar to support orthography segment between script and region"
```

---

### Task 1: 修正 production 管理工具以相容 v2 schema + 鎖定最新 migration

**Files:**
- Modify: `scripts/db/lib/production.py`（`INVENTORY_COUNTS_SQL`）
- Modify: `scripts/db/migration-lock.json`（重新鎖定 0022）
- Modify: `scripts/db/tests/test_production_inventory.py`（更新預期 counts）
- Test: `scripts/db/tests/test_production_inventory.py`

**Interfaces:**
- Consumes: 現有 `ProjectPaths`、`ProductionExecutor`、`inventory_production`、`sync_migration_lock`。
- Produces: 修正後的 `INVENTORY_COUNTS_SQL`、更新後的 `migration-lock.json`。

- [ ] **Step 1: 更新 INVENTORY_COUNTS_SQL 移除 v1 殘留表引用**

`scripts/db/lib/production.py` 第 622–642 行的 `INVENTORY_COUNTS_SQL` 目前查詢 `languoids`、`language_locations`，且 `orphan_languages` 用 `variety_key`/`glottocode`。v2 schema 無此三表且 `languages` 只有 `code`/`name_en`/`name_expression_id`。改為：

```python
INVENTORY_COUNTS_SQL = """
SELECT 'languages' AS metric, COUNT(*) AS count FROM languages;
SELECT 'language_locales' AS metric, COUNT(*) AS count FROM language_locales;
SELECT 'expressions' AS metric, COUNT(*) AS count FROM expressions;
SELECT 'expression_edges' AS metric, COUNT(*) AS count FROM expression_edges;
SELECT 'users' AS metric, COUNT(*) AS count FROM users;
SELECT 'email_verification_tokens' AS metric, COUNT(*) AS count FROM email_verification_tokens;
SELECT 'handbooks' AS metric, COUNT(*) AS count FROM handbooks;
SELECT 'handbook_sections' AS metric, COUNT(*) AS count FROM handbook_sections;
SELECT 'handbook_section_items' AS metric, COUNT(*) AS count FROM handbook_section_items;
SELECT 'votes' AS metric, COUNT(*) AS count FROM votes;
SELECT 'ui_locales' AS metric, COUNT(*) AS count FROM ui_locales;
SELECT 'ui_messages' AS metric, COUNT(*) AS count FROM ui_messages;
SELECT 'managed_ui_messages' AS metric, COUNT(*) FROM ui_messages WHERE project_id = 'langmap-web';
SELECT 'managed_ui_edges' AS metric, COUNT(*) FROM expression_edges WHERE source = 'ui_i18n';
SELECT 'ui_key' AS kind, key, source_hash FROM ui_messages WHERE project_id = 'langmap-web' ORDER BY key;
SELECT 'orphan_ui_messages' AS metric, COUNT(*) FROM ui_messages m LEFT JOIN expressions e ON e.id = m.source_expression_id WHERE e.id IS NULL;
SELECT 'orphan_expression_edges' AS metric, COUNT(*) FROM expression_edges x LEFT JOIN expressions a ON a.id = x.expression_a_id LEFT JOIN expressions b ON b.id = x.expression_b_id WHERE a.id IS NULL OR b.id IS NULL;
SELECT 'orphan_handbook_items' AS metric, COUNT(*) FROM handbook_section_items i LEFT JOIN expressions e ON e.id = i.expression_id WHERE e.id IS NULL;
""".strip()
```

- [ ] **Step 2: 更新測試預期**

`scripts/db/tests/test_production_inventory.py` 中 `test_inventory_is_read_only_and_writes_redacted_report` 預期 `counts["languages"] == 62`。numeric fake wrangler fixture 的回傳（`scripts/db/tests/fixtures/`）若不匹配新 SQL 查詢表名，需要同步更新 fixture 檔內容，使 tests 通過。

- [ ] **Step 3: 重新鎖定 migration-lock.json**

在 repo root 執行（由 Python 調用，非手改 JSON）：

```bash
python3 - <<'PY'
import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path("scripts/db").resolve()))
from lib.paths import ProjectPaths
from lib.migrations import sync_migration_lock
paths = ProjectPaths.discover()
result = sync_migration_lock(
    paths.migrations_dir,
    paths.migration_lock_path,
    update=True,
    baseline_created_at="2026-08-11T00:00:00Z",
    git_commit="dc36eb69",
)
print(json.dumps({"count": len(result["migrations"])}))
PY
```

預期輸出含 22 個 migration，且 lock 檔新增 `0022_script_region_name_expression_id.sql` 條目。

- [ ] **Step 4: 執行單元測試驗證**

```bash
python3 -m unittest discover scripts/db/tests -v
```

預期全部通過（至少 `test_production_inventory.py`、`test_manage.py`、`test_production_inventory.py` 相關案例）。

- [ ] **Step 5: Commit**

```bash
git add scripts/db/lib/production.py scripts/db/migration-lock.json scripts/db/tests
git commit -m "fix(db): align production inventory SQL with v2 schema and lock migration 0022"
```

### Task 2: 新增 v2 languages/locales seed（yue、wuu、zha、ral、swh 之所需 locale）

**Files:**
- Create: `scripts/db/migrations/0023_v2_migration_languages.sql`（並登記至 migration-lock）
- Modify: `backend/schema.sql`（同步完整 schema seeds，保持等價）
- Test: 視需要在 `scripts/db/tests/test_migrations.py` 增加案例

**Interfaces:**
- Consumes: v2 `languages`、`language_locales`、`sources` 表；`system-seed` source。
- Produces: 新增的 language + locale rows，供後續 expressions/handbooks FK 引用。

- [ ] **Step 1: 決定 image/emoji 處理（決策點 D1，需用戶確認）**

預設方案：`image` / `emoji` 是 v1 用於非語言內容的佔位 code，v2 無對應 ISO 639-3 代碼，且 v2 `languages` 是 pinned ISO registry（ADR 0004），**建議不遷移**。若需遷移，折衷方案是把它們寫成 `languages` 自訂列（`code='und'` 用於 image、`emoji` 直接作 code），並建立對應 locale。此舉違反 pinned registry 不變量，需要用戶明示接受。兩個選項皆會產生 migration report 記錄。**若用戶未回覆，預設不遷移。**

- [ ] **Step 2: 撰寫 0023 migration**

```sql
-- 2026-08-19: V1→V2 遷移所需之 language/locale seeds (user-confirmed mapping).
-- yue、wuu、zha、ral 不在 v1→v2 既有 seed 中；swh 亦需 locale seed。

INSERT OR IGNORE INTO languages (code, name_en) VALUES
  ('yue', 'Yue Chinese'),
  ('wuu', 'Wu Chinese'),
  ('zha', 'Zhuang (individual)'),
  ('ral', 'Ralte'),
  ('swh', 'Swahili (individual language)');

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('yue-Hant-HK', 'yue', 'Hant', 'HK', '', '廣東話', 'Yue (Hong Kong)', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('wuu-Hant-CN_Taizhou', 'wuu', 'Hant', 'CN', 'Taizhou', '台州話', 'Taizhou Wu', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('wuu-Hans-CN_Wenzhou', 'wuu', 'Hans', 'CN', 'Wenzhou', '温州话', 'Wenzhou Wu', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('zha-Latn-CN_Jingxi', 'zha', 'Latn', 'CN', 'Jingxi', '靖西壮语', 'Jingxi Zhuang', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('ral-Latn-IN', 'ral', 'Latn', 'IN', '', 'Ralte', 'Ralte', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('swh-Latn-TZ', 'swh', 'Latn', 'TZ', '', 'Kiswahili', 'Swahili', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('cmn-Hans-CN', 'cmn', 'Hans', 'CN', '', '普通话', 'Simplified Chinese', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('eng-Latn-GB', 'eng', 'Latn', 'GB', '', 'English (GB)', 'English (GB)', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Latn_Pehoeji-TW', 'nan', 'Latn', 'TW', '', 'Pe̍h-ōe-jī', 'POJ romanization', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Latn_Tailo-TW', 'nan', 'Latn', 'TW', '', 'Tâi-lô', 'Tâi-lô romanization', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Hant-CN_Chaozhou', 'nan', 'Hant', 'CN', 'Chaozhou', '潮州話', 'Chaozhou Min Nan', 'system-seed', 'seed:v1-migration:2026-08-19'),
  ('nan-Hant-CN_LufengJiazi', 'nan', 'Hant', 'CN', 'LufengJiazi', '甲子話', 'Jiazi (Lufeng) Hokkien', 'system-seed', 'seed:v1-migration:2026-08-19');
```

> 注意：`cmn-Hans-CN` 與 `eng-Latn-GB` 是否已在既有 migration 中，以實際檢查為準；`INSERT OR IGNORE` 確保冪等。上方僅為示範，實際撰寫前逐一核對 `schema.sql` 與既有 migrations 的 locale 清單避免重複或衝突。

> **Grammar 擴充後**：`nan-Latn_Pehoeji-TW` 和 `nan-Latn_Tailo-TW` 使用新的 orthography 段（script 之後、region 之前），需先完成 Task 0 的 grammar 擴充。

- [ ] **Step 3: 同步更新 backend/schema.sql**

在 `schema.sql` 的 seed 區段加入相同 `INSERT OR IGNORE`（新增 languages 與 language_locales 對應），保持「schema.sql == migrations 依序套用」等價。

- [ ] **Step 4: 重新鎖定 migration-lock.json（含 0023）**

同 Task 1 Step 3 方式，`update=True` 重新鎖定。

- [ ] **Step 5: 本地重建驗證 schema 等價**

```bash
python3 scripts/db/manage.py local rebuild
python3 scripts/db/manage.py local verify
```

預期 fingerprint 改變觸發 rebuild，verify 顯示無 orphan、語言筆數符合 manifest（含新增）。

- [ ] **Step 6: Commit**

```bash
git add backend/schema.sql backend/migrations/0023_v2_migration_languages.sql scripts/db/migration-lock.json
git commit -m "feat(db): seed v2 languages/locales for v1 migration"
```

### Task 3: backend auth 相容 bcrypt（v1 password_hash 可登入）

**Files:**
- Modify: `backend/src/routes/auth.ts`（`verifyPassword`、`hashPassword`）
- Test: `backend/src/routes/auth.test.ts`（新建）

**Interfaces:**
- Consumes: 現有 `auth.ts` login/register flow。
- Produces: `verifyPassword(password, storedHash)` 可驗證三種格式：bcrypt `$2b$10$...`、新登入產生的 `salt:hex`、以及舊 v2 自訂格式（已存在之 dev 帳號）。

- [x] **Step 1: 寫 failing test（bcrypt 驗證）**

```typescript
// backend/src/routes/auth.test.ts
import { describe, it, expect } from 'vitest';
import { verifyPassword, hashPassword } from './auth';

describe('password compatibility', () => {
  it('verifies a v1 bcrypt hash', async () => {
    const bcryptHash = '$2b$10$kXtDI6whXq.5zwJcBt6ZHeIVO5dnpY4yNBCmSg4mjZgKOL6BvDt5u';
    const ok = await verifyPassword('password', bcryptHash, { bcrypt: () => Promise.resolve(true) });
    expect(ok).toBe(true);
  });
  it('rejects a wrong bcrypt password', async () => {
    const bcryptHash = '$2b$10$kXtDI6whXq.5zwJcBt6ZHeIVO5dnpY4yNBCmSg4mjZgKOL6BvDt5u';
    const ok = await verifyPassword('wrong', bcryptHash, { bcrypt: () => Promise.resolve(false) });
    expect(ok).toBe(false);
  });
  it('still verifies v2 salt:hex hashes', async () => {
    const hash = await hashPassword('secret');
    const ok = await verifyPassword('secret', hash);
    expect(ok).toBe(true);
  });
});
```

- [x] **Step 2: 確認測試失敗**

```bash
cd backend && npx vitest run src/routes/auth.test.ts
```

預期 `verifyPassword` 因簽名不符或 bcrypt 分支缺失而 FAIL。

- [x] **Step 3: 實作 bcrypt 相容層**

選項 A（推薦）：引進輕量 bcrypt 依賴 `bcryptjs`：

```bash
cd backend && npm install bcryptjs
```

修改 `backend/src/routes/auth.ts`：

```typescript
import bcrypt from 'bcryptjs';

function isBcryptHash(storedHash: string): boolean {
  return /^\$2[aby]\$\d{2}\$/.test(storedHash);
}

async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  if (!storedHash) return false;
  if (isBcryptHash(storedHash)) {
    return await bcrypt.compare(password, storedHash);
  }
  // Legacy v2 custom format: salt:hex
  if (!storedHash.includes(':')) return false;
  const [salt, expectedHash] = storedHash.split(':');
  const input = new TextEncoder().encode(`${salt}:${password}`);
  const digest = await crypto.subtle.digest('SHA-256', input);
  const actualHash = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
  return actualHash === expectedHash;
}
```

> 若不想新增依賴，可用 Workers 平台提供的 `crypto.subtle` 手寫 bcrypt（不建議，極易出錯）。改用授權聲明 `bcryptjs` 為例外即可。

注意：test 中為了不打真實 bcrypt，可注入 fake；實作中用 `bcrypt.compare`。若 test 的注入介面與 `verifyPassword` 簽名不一致，調整 test 使其直接測真實 bcryptjs（單元層級可接受，幾毫秒）。

- [x] **Step 4: 確認測試通過**

```bash
cd backend && npx vitest run src/routes/auth.test.ts
```

- [ ] **Step 5: 執行既有 backend 測試確認無回歸**

```bash
cd backend && npm test
```

- [x] **Step 6: Commit**

```bash
git add backend/src/routes/auth.ts backend/src/routes/auth.test.ts backend/package.json backend/package-lock.json
git commit -m "feat(auth): verify legacy bcrypt password hashes from v1 migration"
```

### Task 4: 建立 v1→v2 遷移腳本骨架 + users 遷移

**Files:**
- Create: `scripts/db/migrate_v1/__init__.py`
- Create: `scripts/db/migrate_v1/parse_sql.py`（解析 `scripts/v2/remote-*.sql` INSERT 語句為 row dicts）
- Create: `scripts/db/migrate_v1/mapping.py`（language_code 映射表 + locale helpers）
- Create: `scripts/db/migrate_v1/identity.py`（Python 版 `computeTextHash`/`buildExpressionId`，與 `expressionIdentity.ts` 實作完全一致）
- Create: `scripts/db/migrate_v1/users.py`
- Test: `scripts/db/tests/test_migrate_v1.py`（新建）

**Interfaces:**
- Consumes: `scripts/v2/remote-*.sql` 快照、`ProjectPaths`。
- Produces: `load_table(paths, 'users') -> list[dict]`、`migrate_users(rows) -> list[sql_insert_payload]`、`compute_text_hash(text) -> str`、`build_expression_id(lang, hash, idx) -> str`、`map_language_code(v1_code) -> v2_locale`。

- [x] **Step 1: 實作 SQL 快照 parser**

`remote-*.sql` 是 `INSERT INTO "table" (cols) VALUES(...);` 語句（部分含 `replace(...)`/`char(10)`，需對 `.sql` 檔案以簡易 SQL 求值器處理，或直接對 clamp 的 INSERT VALUES 做字串剖析）。設計成將每個表格的 rows 讀為 list[dict]：

```python
# parse_sql.py (key detail)
import re

INSERT_RE = re.compile(
    r'INSERT(?: OR IGNORE)? INTO "?(?P<table>[A-Za-z_]+)"? '
    r'\((?P<cols>.*?)\) VALUES(?P<rows>.*?);',
    re.S | re.I,
)

def load_table(contents: str, table: str) -> list[dict]:
    rows: list[dict] = []
    for match in INSERT_RE.finditer(contents):
        if match.group("table") != table:
            continue
        cols = [c.strip().strip('"') for c in match.group("cols").split(",")]
        for row in parse_row_tuples(match.group("rows")):
            if len(row) != len(cols):
                raise ValueError(f"column/row length mismatch in {table}")
            rows.append(dict(zip(cols, row)))
    return rows
```

`parse_row_tuples` 需處理字串中的逗號與括號、`replace('x','y')`、`char(10)`。**若快照格式過於多變（例如 `replace` 巢狀），就以 SQLite 匯入中間庫再 `SELECT` 取代手寫 parser**：`sqlite3 :memory: < remote-*.sql` 後直接讀表。

- [x] **Step 2: 實作 identity.py（與 backend 一致）**

```python
import hashlib

BASE32_ALPHABET = "abcdefghijklmnopqrstuvwxyz234567"

def canonicalize_text(text: str) -> str:
    import unicodedata
    return unicodedata.normalize("NFC", text.strip())

def compute_text_hash(canonical_text: str) -> str:
    digest = hashlib.sha256(canonical_text.encode("utf-8")).digest()
    bits = "".join(f"{b:08b}" for b in digest[:16])
    out = ""
    for i in range(0, len(bits), 5):
        chunk = bits[i : i + 5].ljust(5, "0")
        out += BASE32_ALPHABET[int(chunk, 2)]
    return out

def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    return f"{lang_code}:{text_hash}" if homograph_index == 1 else f"{lang_code}:{text_hash}.{homograph_index}"
```

加上對照測試：用 spec 的 `hello` 向量 `ftze3os7wcrq4jxihmvmlopcty` 驗證與 backend 一致（可執行 backend `computeTextHash` 交叉驗證）。

- [x] **Step 3: 實作 mapping.py**

寫出 Global Constraints 中之 v1→v2 映射表為 dict；提供 `map_language_code(code) -> str (v2 lang_code)`、`map_expression_locale(code) -> str (v2 locale_code) | None`。對映射不到的 code 回傳 `None`（該 row 不遷移並記錄）。

- [x] **Step 4: users 遷移**

```python
def migrate_users(rows: list[dict]) -> list[dict]:
    out = []
    for row in rows:
        out.append({
            "id": row["id"],
            "username": row["username"],
            "email": row["email"],
            "password_hash": row["password_hash"],  # bcrypt 原樣保留
            "role": row["role"] if row["role"] in ("admin", "user") else "user",
            "email_verified": int(row["email_verified"] or 0),
            "created_at": row["created_at"] or "CURRENT_TIMESTAMP",
            "updated_at": row["updated_at"] or row["created_at"] or "CURRENT_TIMESTAMP",
        })
    return out
```

- [x] **Step 5: 寫測試**

以 `scripts/v2/remote-users.sql` 內容建 fixture 解析，驗證 12 位使用者轉換後 password_hash 不變、role 映射、email_verified 數值化。

- [x] **Step 6: 執行測試**

```bash
python3 -m unittest scripts.db.tests.test_migrate_v1 -v
```

- [x] **Step 7: Commit**

```bash
git add scripts/db/migrate_v1 scripts/db/tests/test_migrate_v1.py
git commit -m "feat(db): add v1 migration skeleton, sql parser, identity helpers, users migration"
```

### Task 5: expressions 遷移（含 homograph、locale、reading 處理）

**Files:**
- Create: `scripts/db/migrate_v1/expressions.py`
- Modify: `scripts/db/migrate_v1/__init__.py`（掛上 `load_expressions`、`migrate_expressions`）
- Test: `scripts/db/tests/test_migrate_v1.py`

**Interfaces:**
- Consumes: `parse_sql.load_table`、`mapping.map_language_code`、`identity.compute_text_hash`。
- Produces: `migrate_expressions(rows, user_ids) -> {expressions: [...], locales_seed: [...], report: {...}}`。

- [x] **Step 1: 定義遷移過濾規則**

```python
RUNTIME_OWNERS = {"system", "langmap", "ai", "opus"}

def is_user_expression(row: dict, users_by_name: dict[str, int]) -> bool:
    owner = row.get("created_by")
    if owner in RUNTIME_OWNERS:
        return False
    if isinstance(owner, int) or (isinstance(owner, str) and owner.isdigit()):
        return int(owner) in set(users_by_name.values())
    # v1 created_by 也以 username 字串出現（如 'tsunhua'、'benojan'）
    return owner in users_by_name
```

`users_by_name` 由 Task 4 的 migrated users 建立（username→id 映射），確保只有真實 user 建立的 expressions 進入遷移。

- [x] **Step 2: 實作轉換**

```python
def migrate_expressions(rows, user_ids):
    used_ids: set[str] = set()
    expressions = []
    skipped, dropped_unmapped, dropped_owner = 0, 0, 0
    for row in rows:
        if not is_user_expression(row, user_ids):
            dropped_owner += 1
            continue
        v2_lang = map_language_code(row["language_code"])
        if v2_lang is None:
            dropped_unmapped += 1
            continue
        text = canonicalize_text(row["text"])
        if not text:
            skipped += 1
            continue
        h = compute_text_hash(text)
        idx = 1
        candidate = build_expression_id(v2_lang, h, idx)
        while candidate in used_ids:
            idx += 1
            candidate = build_expression_id(v2_lang, h, idx)
        used_ids.add(candidate)
        expressions.append({
            "id": candidate,
            "lang_code": v2_lang,
            "text": text,
            "text_hash": h,
            "homograph_index": idx,
            "description": row.get("desc") or "",
            "tags_json": row.get("tags") if row.get("tags") else "[]",
            "review_status": row.get("review_status") or "pending",
            "created_by": int(row["created_by"]) if str(row["created_by"]).isdigit() else user_ids.get(row["created_by"]),
            "created_at": row.get("created_at") or "CURRENT_TIMESTAMP",
            "updated_at": row.get("updated_at") or row.get("created_at") or "CURRENT_TIMESTAMP",
            # 指向 v1 migration system source（Task 階段建立 sources row）
            "source_id": None,
            "source_ref": f"v1:{row['id']}",
        })
    return {"expressions": expressions, "skipped": skipped, "dropped_owner": dropped_owner, "dropped_unmapped": dropped_unmapped}
```

- [x] **Step 3: 產生 expression locale attestations 與 readings（針對 POJ/Tailo 等）**

對 `nan-TW-POJ` / `nan-TW-TL` 來源的 expressions，額外建立 `expression_readings`：

```python
def reading_for(v1_code: str, expression_id: str) -> dict | None:
    if v1_code == "nan-TW-POJ":
        return {"expression_id": expression_id, "language_locale_code": "nan-Latn_Pehoeji-TW", "scheme": "poj", "value": None}
    if v1_code == "nan-TW-TL":
        return {"expression_id": expression_id, "language_locale_code": "nan-Latn_Tailo-TW", "scheme": "tailo", "value": None}
    return None
```

> `value` 無法由 v1 自動推得（v1 text 本身即是羅馬字，可選用 `text` 為 reading value；此為決策點 D2，預設使用 text 作為 value）。

- [x] **Step 4: 測試** — 用 `remote-expressions.sql` 抽出 user 建立的樣本驗證 ID 生成、homograph 遞增、locale 映射、系統詞句被排除。

- [x] **Step 5: Commit**

```bash
git add scripts/db/migrate_v1/expressions.py scripts/db/tests/test_migrate_v1.py
git commit -m "feat(db): migrate v1 user expressions to v2 with hash ids"
```

### Task 6: handbooks 遷移（content 解析 → sections/items）

**Files:**
- Create: `scripts/db/migrate_v1/handbooks.py`
- Modify: `scripts/db/migrate_v1/__init__.py`
- Test: `scripts/db/tests/test_migrate_v1.py`

**Interfaces:**
- Consumes: `remote-handbooks.sql`、`remote-handbook_pages.sql`、migrated expressions ID 對照（v1 expression_id → v2 expression_id）。
- Produces: `migrate_handbooks(handbook_rows, page_rows, expr_map) -> {handbooks, sections, items, report}`。

- [x] **Step 1: 實作 markdown content 解析器**

```python
import re

EXPR_TAG_RE = re.compile(r"\{\{(?:text:[^}|]+(?:\|[^}]*)?|(?P<bare>\d+))\}\}")

def parse_sections(content: str):
    """Split markdown on ## headings; collect expression refs per section."""
    sections = []
    current_title = None
    current_refs = []
    for line in content.splitlines():
        m = re.match(r"^##\s+(.+)$", line)
        if m:
            if current_refs or current_title is not None:
                sections.append((current_title, current_refs))
            current_title = m.group(1).strip()
            current_refs = []
        else:
            for tag in EXPR_TAG_RE.finditer(line):
                ref = tag.group("bare") or tag.group(0)
                current_refs.append(ref)
    if current_title is not None or current_refs:
        sections.append((current_title, current_refs))
    return sections
```

- [x] **Step 2: 解析 `{{text:X|mid:N}}` 與 bare id 標記到 v1 expression id**

從 `remote-expressions.sql` 建立 `v1_text_to_id`（text+language_code → v1 expression id）與 `v1_id` 集合；對 bare id 直接查 v1 expression 是否存在。`mid` 欄位僅供參考，實際以 expression id 對應。

- [x] **Step 3: 實作 handbook 轉換**

```python
def migrate_handbooks(handbook_rows, page_rows, expr_map, users_by_id):
    from ..utils import ulid  # 或自行產生 26 字元 ULID

    handbooks, sections, items = [], [], []
    report = {"dropped_free_text": 0, "skipped_unmapped_items": 0}
    for hb in handbook_rows:
        hb_id = ulid()
        handbooks.append({
            "id": hb_id,
            "user_id": int(hb["user_id"]),
            "title": hb["title"],
            "visibility": "public" if hb.get("is_public") in (1, "1", True) else "private",
            "status": hb.get("status") or "published",
            "score": int(hb.get("score") or 0),
            "created_at": hb.get("created_at") or "CURRENT_TIMESTAMP",
            "updated_at": hb.get("updated_at") or hb.get("created_at") or "CURRENT_TIMESTAMP",
        })
        # 合併 pages（依 sort_order）解析 sections
        content_chunks = [p["content"] for p in sorted(page_rows, key=lambda p: p["sort_order"])] if page_rows else [hb.get("content") or ""]
        for chunk in content_chunks:
            for title, refs in parse_sections(chunk):
                sid = ulid()
                sections.append({"id": sid, "handbook_id": hb_id, "title": title, "position": len(sections)})
                for pos, ref in enumerate(refs):
                    v2_id = expr_map.get(ref)
                    if v2_id is None:
                        report["skipped_unmapped_items"] += 1
                        continue
                    items.append({"section_id": sid, "expression_id": v2_id, "position": pos})
    return {"handbooks": handbooks, "sections": sections, "items": items, "report": report}
```

- [x] **Step 4: 測試** — 用 `remote-handbooks.sql` 範例（含 `{{text:翁|mid:...}}`、bare id 標記、多 page handbook）驗證 sections/items 數量、unmapped 計數。

- [x] **Step 5: Commit**

```bash
git add scripts/db/migrate_v1/handbooks.py scripts/db/tests/test_migrate_v1.py
git commit -m "feat(db): migrate v1 handbooks to v2 sections and items"
```

### Task 7: 組裝端到端遷移腳本 + 本地全流程演練

**Files:**
- Create: `scripts/db/migrate_v1/run.py`（CLI：`--source fixtures|remote`、`--output-dir`、`--apply-local`、`--apply-remote`）
- Create: `scripts/db/migrate_v1/generate_sql.py`（把遷移結果輸出為 SQL 檔）
- Test: `scripts/db/tests/test_migrate_v1.py`（端到端 fixture 測試）

**Interfaces:**
- Consumes: Task 4–6 的所有函式。
- Produces: 可執行 CLI + 一組可套用的 SQL（或直接以 D1 execute 寫入 local/remote DB）。

- [ ] **Step 1: 實作 CLI 流程**

```bash
python3 scripts/db/migrate_v1/run.py --source fixtures --output-dir /tmp/langmap-migrate
# 產生 users.sql, languages_seed.sql, expressions.sql, readings.sql, handbooks.sql, sections.sql, items.sql, report.json
```

流程：載入 users → migrate；建 `sources` row（`('system', 'LangMap V1 migration')`）→ 載入 expressions → 建 locales seed SQL（Task 2 語句合一）→ 建 readings → 建 handbooks/sections/items → 輸出 SQL。

- [ ] **Step 2: 本地 D1 演練**

先用 `python3 scripts/db/manage.py local rebuild` 建立空 v2 local D1 → 套用產生的 SQL（`wrangler d1 execute langmap-v2 --local --file ...` 依序 users → expressions → handbooks）→ 啟動 Worker 並以 API smoke test 驗證：

```bash
# 啟動 local
./dev.sh
curl http://127.0.0.1:8788/api/v2/auth/login -X POST -H 'content-type: application/json' -d '{"email":"tsunhua的email","password":"<已知密碼或重置為已知>"}'
curl http://127.0.0.1:8788/api/v2/handbooks
curl 'http://127.0.0.1:8788/api/v2/expressions/search?q=食'
```

> 登入測試需要知道 v1 用戶密碼。若無已知密碼，改測 auth 登入流程對 bcrypt hash 的驗證（直接以遷移後的 password_hash 呼叫 `verifyPassword` 單元層級），並在 production 驗證時由 owner 操作。

- [ ] **Step 3: 驗證 invariants** — 檢查 users 數、expressions 數、handbooks/sections/items 數、無 orphan、homograph 無衝突、report 中 dropped/skipped 計數合理。

- [ ] **Step 4: Commit**

```bash
git add scripts/db/migrate_v1
git commit -m "feat(db): assemble end-to-end v1 migration runner with local rehearsal"
```

### Task 8: 清理並重建 production V2 D1

**Files:**
- Modify: `scripts/db/manage.py`（如需要，新增 `production reset` 子命令；或由操作手冊以 wrangler CLI 一級一級執行）

**Interfaces:**
- Consumes: `wrangler d1` CLI、`ProjectPaths`。
- Produces: 空的 v2 schema + migration history + reference data。

- [ ] **Step 1: 取得操作前 inventory 與 bookmark（如選用 bookmarks）**

用戶已決定「不用 bookmark，因為是新的 DB」，但為了可稽核仍先在 `scripts/db/state/production/` 寫一份 pre-migration inventory。若舊 V1 DB 仍在線，另以 `wrangler d1 export <old_db> --remote --output v1-full-dump.sql` 建立完整備份（**此為唯一舊資料來源，須確認已成功**）。

- [ ] **Step 2: 清理 V2 DB**

```bash
cd backend
# 列出現有表
wrangler d1 execute langmap-v2 --remote --command "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT IN ('d1_migrations')"
# 依序刪除（或直接重建 schema）：執行 schema.sql 重建（其 DROP TABLE 已涵蓋）＋ migration baseline
wrangler d1 execute langmap-v2 --remote --file ../backend/schema.sql
```

> 因 schema.sql 含 `DROP TABLE IF EXISTS` 會清空全部 v1 殘留表再建 v2 schema。接著本地用 `manage.py production plan/apply` 或手動 `wrangler d1 migrations apply langmap-v2 --remote` 建立 baseline（0022 為止，0023 暫不套到 production，因為 0023 的 locale 由遷移腳本 seed SQL 合併處理）。此步驟細節依 `manage.py` 現有能力調整。

- [ ] **Step 3: 載入 pinned reference bundles**

```bash
wrangler d1 execute langmap-v2 --remote --file scripts/language-reference/artifacts/language-reference.sql
wrangler d1 execute langmap-v2 --remote --file scripts/i18n/artifacts/system-ui/system-ui.sql
```

（若 migration 已覆蓋，跳過重複 INSERT 風險依 OR IGNORE 保證。）

- [ ] **Step 4: 執行 production inventory 確認空庫狀態**

```bash
python3 scripts/db/manage.py production inventory
```

預期：users=0、expressions=0、handbooks=0、languages/locales 符合 reference bundle。

- [ ] **Step 5: Commit（如有工具變更）** — 資料操作本身無 commit。

### Task 9: 套用 v1→v2 遷移資料到 production

**Files:**
- 由 Task 7 產生的 SQL 檔（`users.sql`、`expressions.sql`、`handbooks.sql` 等）置於 repo 或受控路徑（不 commit 含真實資料之匯出檔，僅 commit 腳本）。

**Interfaces:**
- Consumes: Task 8 建好的空 v2 DB、Task 7 的 SQL 輸出。
- Produces: v2 DB 內含 migrated users/expressions/handbooks。

- [ ] **Step 1: 依序套用 SQL（此為 operator 手動執行）**

```bash
# 先在 local 已演練同序
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/languages_seed.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/users.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/expressions.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/readings.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/handbooks.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/sections.sql
wrangler d1 execute langmap-v2 --remote --file /tmp/langmap-migrate/items.sql
```

- [ ] **Step 2: 套用後 production inventory + verify**

```bash
python3 scripts/db/manage.py production inventory
python3 scripts/db/manage.py production verify
```

預期：users=12、expressions/handbooks 數與本地演練一致、orphan 計數為 0（含 `orphan_handbook_items`）。

- [ ] **Step 3: 記錄操作 journal**（`scripts/db/state/production/operations.jsonl` 手動或工具自動）。

### Task 10: 建置 frontend、部署 Worker、線上驗證

**Files:**
- 無新檔案（如 frontend 有隨遷移需要之文字調整，依 AGENTS.md 改動並確保 build）。

**Interfaces:**
- Consumes: 已就緒的 v2 DB、backend 已含 bcrypt 相容層。
- Produces: 上線的 production Worker。

- [ ] **Step 1: 前端建置（如需要）**

```bash
./build.sh   # web → backend/public
```

- [ ] **Step 2: 部署前檢查**

```bash
cd backend && wrangler types --check
npx wrangler deploy --dry-run
```

- [ ] **Step 3: 部署**

```bash
cd backend && npx wrangler deploy
```

- [ ] **Step 4: 線上 smoke test**

```bash
curl https://<worker-host>/api/v2/auth/health
curl https://<worker-host>/api/v2/handbooks
curl 'https://<worker-host>/api/v2/expressions/search?q=食'
# 登入測試：owner 用 v1 密碼登入任一 migrated 帳號
```

- [ ] **Step 5: 驗證報告**（寫入 `scripts/db/state/production/` 供留存）。

---

## Self-Review

**Spec coverage：**
- [x] grammar 擴充支援 orthography 段（Task 0）
- [x] 重建 v2 表（Task 8）
- [x] 遷移 users（Task 4）
- [x] 遷移 handbooks（Task 6）
- [x] 遷移 user-created expressions（Task 5）
- [x] 不遷移系統/AI/OPUS/UI 詞句（Task 5 過濾）
- [x] 語言映射（Task 2 + Global Constraints）
- [x] 密碼格式相容（Task 3）
- [x] 方案 B 新 DB 切換（Task 8–10）
- [x] 不要 bookmark（Global Constraints + Task 8 說明）
- [x] 本地測試驗證（Task 7）

**Placeholder scan：**
- 除明列之決策點（D1、D2、v1 DB identity）外，無 TBD/TODO。
- `{{...}}` 解析器、identity hash、mapping 表皆含具體實作。

**Type consistency：**
- `compute_text_hash` / `build_expression_id` 簽名與 `expressionIdentity.ts` 對應。
- `migrate_users` / `migrate_expressions` / `migrate_handbooks` 輸出欄位名對應 v2 schema 欄位。
- `ulid()` 以 `scripts/db` 現有 `lib` 能力（或 `utils/ulid` 之 26 字元 ULID）產生。

## 執行前需用戶確認之決策點

1. **v1 production DB identity（已確認）**：`database_name=langmap`、`database_id=f21a787e-769f-45b3-bd1a-59d41b35ff12`。
2. **image/emoji 處理（已確認）**：遷移，使用 `x-image` / `x-emoji` 作為 `lang_code`，不建立 language_locales。
3. **Handbooks 自由文字捨棄（已確認）**：接受預設「捨棄自由文字、跳過 unmapped items」。
4. **email_verification_tokens 不遷移（已確認）**：接受。
5. **Grammar 擴充（已確認）**：支援 `nan-Latn_Pehoeji-TW` 格式，orthography 段位於 script 之後、region 之前。
6. **密碼**：是否提供一組測試帳號密碼供本地登入 smoke test？沒有則以單元測試取代。
