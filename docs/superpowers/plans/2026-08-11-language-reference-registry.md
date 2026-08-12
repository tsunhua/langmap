# ISO 639-3 Language Reference Registry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 greenfield 資料庫 baseline 與 ISO 639-3／ISO 15924／ISO 3166-1 reference registry,並提供唯讀查詢 API,為後續語言代碼重建奠定地基。

**Architecture:** 先清空舊的 language-identity 資料層(舊 migration、Glottolog／BCP 47 路由與服務、`scripts/v2/`),建立只含 `users` + 三張 registry 表的 `0001_initial_schema.sql`;新增離線、可重現的 Python registry 生成器讀取 pinned raw 資料與 curated overlay,輸出 deterministic seed SQL;最後以 Hono route 暴露三個 `GET /language-registry/*` endpoint。後端整合測試沿用既有「先啟 Worker 再跑 Vitest」模式。

**Tech Stack:** Hono 4、Cloudflare Workers + D1(binding `DB`)、Vitest 4、Zod 4、Python 3(生成器與 `scripts/db/` 工具)、`unittest`(scripts 測試)。

## Global Constraints

- API prefix 固定 `/api/v2`;所有回應為 `{ success, data?, error?, message? }`,list 用 `paginated(c, items, total, skip, limit)`。
- D1 binding 名 `DB`、database 名 `langmap-v2`(見 `backend/wrangler.jsonc`);不可改 binding 名。
- Registry 表欄位(逐字抄自 spec §6.1):
  - `languages(code TEXT PRIMARY KEY, name_en TEXT NOT NULL)`
  - `scripts(code TEXT PRIMARY KEY, name_en TEXT NOT NULL, direction TEXT NOT NULL CHECK (direction IN ('ltr','rtl')))`
  - `regions(code TEXT PRIMARY KEY, name_en TEXT NOT NULL, latitude REAL, longitude REAL, CHECK ((latitude IS NULL) = (longitude IS NULL)))`
- 領域／schema／API／UI 一律稱 region,不稱 country(spec §6.1)。
- 生成器:輸出固定排序、可重跑、不可依賴 runtime network;manifest 記錄標準名、來源 URL、下載日期、checksum、產物筆數(spec §6.2)。
- Script direction 來自版本控制、逐 code 可審核的 pinned overlay;未覆蓋的 script 不可由名稱猜測方向,生成器必須報錯(spec §6.2)。
- Region 座標為選填 curated overlay,並記錄來源與授權;ISO registry 本身不是座標來源(spec §6.2)。
- Runtime 不提供建立或修改 registry row 的 API(spec §6.2);只有 `GET`。
- Greenfield:現有 D1 資料全部可丟棄,不提供舊資料遷移、runtime alias 或 `language_profile_code` 相容層(spec §1、§16)。
- 新 schema 不可含 `languoids`、`language_subtags`、`language_varieties`、`language_profiles`、`language_locations`(spec §17.3)。
- 整合測試依賴 `127.0.0.1:8788` 與本地 D1;`fileParallelism: false`;測試隔離靠 `Date.now()`／`Math.random()` uniqueness,不 truncate、無 `beforeEach`(見 `backend/vitest.config.ts` 與既有測試)。
- 註釋只解釋 WHY,不重述程式碼;Vue/TS 不新增 `any`(本 plan 無前端)。
- Commit 用簡潔 Conventional Commit。

---

## File Structure

**建立:**
- `backend/migrations/0001_initial_schema.sql` — greenfield 初始 schema(users + 三張 registry 表)。
- `backend/tests/schemaContract.test.ts` — schema 契約測試(新表存在、舊表缺席)。
- `backend/tests/registryIntegration.test.ts` — registry API 整合測試。
- `backend/src/services/languageIdentity.ts` — registry 查詢 service(parse query + D1 查詢)。
- `scripts/language-reference/generate.py` — 離線 deterministic 生成器。
- `scripts/language-reference/fetch.py` — 一次性 pinned 下載器(手動執行)。
- `scripts/language-reference/test_generate.py` — 生成器 unittest。
- `scripts/language-reference/raw/iso639-3.tab` — pinned ISO 639-3(commit)。
- `scripts/language-reference/raw/iso15924.txt` — pinned ISO 15924(commit)。
- `scripts/language-reference/raw/iso3166-1.tsv` — curated ISO 3166-1 alpha-2(commit)。
- `scripts/language-reference/raw/provenance.json` — 下載來源紀錄。
- `scripts/language-reference/overlays/script-directions.json` — 逐 script 的 ltr／rtl。
- `scripts/language-reference/overlays/region-coordinates.tsv` — 選填座標 overlay。
- `scripts/language-reference/artifacts/language-reference.sql` — 生成器輸出(commit)。
- `scripts/language-reference/artifacts/manifest.json` — 生成器 manifest(commit,含 `manifest_version`)。

**改寫:**
- `backend/schema.sql` — 重寫,與 `0001` 等價。
- `backend/src/routes/index.ts` — 只留 `auth` 與新 `languageRegistry`。
- `backend/src/types.ts` — 移除 `MappingGraph*` 介面。
- `scripts/db/lib/paths.py` — `language_manifest_path`／`language_registry_sql_path` 指向新路徑。
- `scripts/db/lib/local.py` — 移除 `system_ui_sql` 載入。
- `scripts/db/migration-lock.json` — 重生成為單一 `0001` entry。
- `scripts/language-reference/artifacts/*` — 每次重跑生成器覆寫。

**刪除:**
- `backend/migrations/0002_*` 至 `0025_*`(含 `.meta.json`)。
- `backend/src/routes/{languages,languoids,languageProfiles,languageRegistry,expressions,mappings,contributions,handbooks,search,localization,feed}.ts`(舊版)。
- `backend/src/services/{languageCreation,languageRegistry}.ts`。
- `backend/src/utils/{languageCode,mappingGraph}.ts`。
- `backend/src/types/language.ts`。
- `backend/tests/{expressions-mappings,languageCode,languageRegistry,languages.integration,localization,mappingGraph}.test.ts`。
- `scripts/v2/`(整個目錄,33 個 tracked 檔)。
- `scripts/db/production-baseline.json`(已過時,部署時再重建)。

**保留不動:** `backend/src/routes/auth.ts`、`backend/src/middleware/auth.ts`、`backend/src/utils/{response,ids,ulid}.ts`、`backend/src/utils/ulid.test.ts`、`backend/tests/auth.test.ts`、`scripts/i18n/`(Plan 6 才改)。

---

## Task 1: 移除舊 language-identity 資料層(路由／服務／工具／測試)

Greenfield 重置第一步:移除所有引用即將消失的舊表的路由與測試,確保 `npm test` 只跑存活測試且 Worker 能開機。此任務只刪不改邏輯。

**Files:**
- Delete: 上述「刪除」清單中的 backend 路由／服務／工具／型別／測試。
- Modify: `backend/src/routes/index.ts`、`backend/src/types.ts`。

**Interfaces:**
- Consumes: 無。
- Produces: 一個只有 `auth` 路由可用的最小後端(`routes/index.ts` 只註冊 `auth`);`Bindings`／`Variables` 型別保留。

- [ ] **Step 1: 刪除舊路由、服務、工具、型別、測試檔**

```bash
cd backend
git rm src/routes/languages.ts src/routes/languoids.ts src/routes/languageProfiles.ts \
       src/routes/languageRegistry.ts src/routes/expressions.ts src/routes/mappings.ts \
       src/routes/contributions.ts src/routes/handbooks.ts src/routes/search.ts \
       src/routes/localization.ts src/routes/feed.ts \
       src/services/languageCreation.ts src/services/languageRegistry.ts \
       src/utils/languageCode.ts src/utils/mappingGraph.ts \
       src/types/language.ts \
       tests/expressions-mappings.test.ts tests/languageCode.test.ts \
       tests/languageRegistry.test.ts tests/languages.integration.test.ts \
       tests/localization.test.ts tests/mappingGraph.test.ts
```

- [ ] **Step 2: 改寫 `backend/src/routes/index.ts`,只保留 auth**

完整新內容:

```ts
import { Hono } from 'hono';
import auth from './auth';

const api = new Hono();
api.route('/auth', auth);

export default api;
```

- [ ] **Step 3: 精簡 `backend/src/types.ts`,移除 `MappingGraph*` 介面**

完整新內容:

```ts
export interface Bindings {
  DB: D1Database;
  ASSETS: { fetch: typeof fetch };
  SECRET_KEY: string;
}

export interface Variables {
  user?: { id: number; username: string; role: string };
}
```

- [ ] **Step 4: 驗證 Worker 能開機、存活測試通過**

先在另一個終端機啟動 Worker:`./dev.sh`(此時 schema 尚未改,舊表仍在,auth 可用)。
然後:

```bash
cd backend && npx wrangler deploy --dry-run 2>&1 | head -20
```

Expected: 無 TypeScript 錯誤(沒有 dangling import)。若報「Cannot find module」,表示有遺漏的 importer,回到 Step 1 補刪。

接著跑存活測試:

```bash
cd backend && npm test
```

Expected: 只剩 `auth.test.ts` 與 `ulid.test.ts` 執行,全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor(api): remove obsolete language-identity routes and tests for greenfield reset"
```

---

## Task 2: Greenfield schema baseline(`0001` + `schema.sql`)

建立只含 `users` + 三張 registry 表的初始 schema,刪除舊 migration,並加 schema 契約測試。

**Files:**
- Create: `backend/migrations/0001_initial_schema.sql`
- Modify(重寫): `backend/schema.sql`
- Delete: `backend/migrations/0002_*` … `0025_*`(含 `.meta.json`)
- Create: `backend/tests/schemaContract.test.ts`

**Interfaces:**
- Consumes: 無。
- Produces: 三張 registry 表(`languages`／`scripts`／`regions`)與 `users` 表存在於 schema;後續 task 的 service／生成器 SQL 依此欄位。

- [ ] **Step 1: 寫 schema 契約測試(先失敗)**

建立 `backend/tests/schemaContract.test.ts`:

```ts
import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

describe('greenfield schema contract', () => {
  it('defines the reference registry tables with the spec columns', () => {
    expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?name_en TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE scripts[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?direction TEXT NOT NULL CHECK \(direction IN \('ltr', 'rtl'\)\)/s);
    expect(schema).toMatch(/CREATE TABLE regions[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?CHECK \(\(latitude IS NULL\) = \(longitude IS NULL\)\)/s);
  });

  it('keeps the users table for auth', () => {
    expect(schema).toMatch(/CREATE TABLE users/);
  });

  it('does not contain obsolete identity tables', () => {
    for (const table of ['languoids', 'language_subtags', 'language_varieties', 'language_profiles', 'language_locations']) {
      expect(schema).not.toMatch(new RegExp(`CREATE TABLE ${table}`));
    }
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts
```

Expected: FAIL(目前 `schema.sql` 還是舊版,含 `languoids` 等,缺 `scripts`／`regions`)。

- [ ] **Step 3: 建立 `backend/migrations/0001_initial_schema.sql`**

```sql
-- Greenfield baseline for the ISO 639-3 language code redesign (spec §6, §16).
-- Replaces all former language-profile era migrations.

CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Reference registries (spec §6.1). Read-only at runtime (spec §6.2).

CREATE TABLE IF NOT EXISTS languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS scripts (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE IF NOT EXISTS regions (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX IF NOT EXISTS idx_languages_code ON languages(code);
CREATE INDEX IF NOT EXISTS idx_scripts_code ON scripts(code);
CREATE INDEX IF NOT EXISTS idx_regions_code ON regions(code);
```

- [ ] **Step 4: 重寫 `backend/schema.sql`,內容與 `0001` 等價但含 DROP 清理標頭**

完整新內容:

```sql
-- ⚠ Local dev only: managed by scripts/db (manage.py local rebuild).
-- Must stay equivalent to backend/migrations/ applied in order (AGENTS.md).

DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS language_locations;
DROP TABLE IF EXISTS language_profiles;
DROP TABLE IF EXISTS language_varieties;
DROP TABLE IF EXISTS language_subtags;
DROP TABLE IF EXISTS languoids;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS scripts;
DROP TABLE IF EXISTS languages;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL
);

CREATE TABLE scripts (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE regions (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_scripts_code ON scripts(code);
CREATE INDEX idx_regions_code ON regions(code);
```

- [ ] **Step 5: 刪除舊 migration**

```bash
cd backend && git rm migrations/0002_*.sql migrations/0003_*.sql migrations/0004_*.sql migrations/0005_*.sql \
  migrations/0006_*.sql migrations/0007_*.sql migrations/0008_*.sql migrations/0009_*.sql \
  migrations/0010_*.sql migrations/0011_*.sql migrations/0012_*.sql migrations/0012_*.meta.json \
  migrations/0013_*.sql migrations/0014_*.sql migrations/0015_*.sql migrations/0015_*.meta.json \
  migrations/0016_*.sql migrations/0016_*.meta.json migrations/0017_*.sql migrations/0018_*.sql \
  migrations/0019_*.sql migrations/0020_*.sql migrations/0021_*.sql migrations/0022_*.sql \
  migrations/0023_*.sql migrations/0024_*.sql migrations/0025_*.sql
```

- [ ] **Step 6: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts
```

Expected: PASS(三項 `it` 全綠)。

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(db): greenfield 0001 schema with ISO reference registries"
```

---

## Task 3: Registry 生成器(`scripts/language-reference/`)

建立離線、可重現的生成器:讀取 pinned raw + curated overlay,輸出 deterministic seed SQL 與 manifest。manifest 必須含 `manifest_version`(fingerprint 依賴)。

**Files:**
- Create: `scripts/language-reference/generate.py`、`fetch.py`、`test_generate.py`、`raw/*`、`overlays/*`、`artifacts/*`

**Interfaces:**
- Consumes: 無(離線)。
- Produces: `artifacts/language-reference.sql`(被 `local.py` 載入)、`artifacts/manifest.json`(fingerprint 輸入,需含 `manifest_version` 欄位)。

- [ ] **Step 1: 一次性下載 pinned raw(SIL ISO 639-3 + Unicode ISO 15924)**

建立 `scripts/language-reference/fetch.py`:

```python
#!/usr/bin/env python3
"""One-shot fetcher for pinned ISO sources into raw/. Run manually to refresh pins.

Not run at build/test time. Records provenance into raw/provenance.json.
ISO 3166-1 alpha-2 is curated in-repo (no free ISO download).
"""
from __future__ import annotations

import hashlib
import io
import json
import sys
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

RAW = Path(__file__).resolve().parent / "raw"

SOURCES = [
    {
        "key": "iso639-3",
        "url": "https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso_639-3.zip",
        "member": "iso_639-3.tab",
        "out": "iso639-3.tab",
    },
    {
        "key": "iso15924",
        "url": "https://www.unicode.org/iso15924/iso15924.txt",
        "out": "iso15924.txt",
    },
]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    provenance = {
        "downloaded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": {},
    }
    for src in SOURCES:
        print(f"fetching {src['key']} from {src['url']}")
        with urllib.request.urlopen(src["url"], timeout=60) as resp:
            data = resp.read()
        archive_sha = sha256_bytes(data)
        if "member" in src:
            with zipfile.ZipFile(io.BytesIO(data)) as zf:
                member = zf.read(src["member"])
            (RAW / src["out"]).write_bytes(member)
            provenance["files"][src["key"]] = {
                "url": src["url"],
                "archive_sha256": archive_sha,
                "member": src["member"],
                "member_sha256": sha256_bytes(member),
                "out": src["out"],
            }
        else:
            (RAW / src["out"]).write_bytes(data)
            provenance["files"][src["key"]] = {
                "url": src["url"],
                "sha256": archive_sha,
                "out": src["out"],
            }
    (RAW / "provenance.json").write_text(
        json.dumps(provenance, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {RAW / 'provenance.json'}")
    print("NOTE: iso3166-1.tsv is curated in-repo; record its source/license in the manifest.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

執行(需要網路,僅這一次):

```bash
python3 scripts/language-reference/fetch.py
```

Expected: `raw/iso639-3.tab`、`raw/iso15924.txt`、`raw/provenance.json` 寫入。

- [ ] **Step 2: 建立 curated ISO 3166-1 alpha-2(`raw/iso3166-1.tsv`)**

建立 `scripts/language-reference/raw/iso3166-1.tsv`,tab 分隔,欄位 `code\tname_en`,約 249 行(Alpha-2 官方代碼)。前幾行範例:

```tsv
code	name_en
AD	Andorra
AE	United Arab Emirates
AF	Afghanistan
TW	Taiwan
US	United States
```

完整 249 個條目由 engineer 依 ISO 3166-1 alpha-2 curated 填入(這份檔案即為 pinned 來源)。

- [ ] **Step 3: 建立 script direction overlay(`overlays/script-directions.json`)**

建立 `scripts/language-reference/overlays/script-directions.json`,涵蓋生成器會輸出的**所有** ISO 15924 script(未覆蓋者生成器會報錯)。範例結構:

```json
{
  "Latn": "ltr",
  "Cyrl": "ltr",
  "Hant": "ltr",
  "Hans": "ltr",
  "Hira": "ltr",
  "Arab": "rtl",
  "Hebr": "rtl",
  "Syrc": "rtl",
  "Thaa": "rtl"
}
```

engineer 補齊其餘 script:預設 `ltr`,僅右起書寫系統(Arab、Hebr、Syrc、Thaa、Aran 等)標 `rtl`。生成器會逐一驗證覆蓋,缺漏即報錯,所以可漸進補齊直到生成器通過。

- [ ] **Step 4: 建立(選填)region 座標 overlay(`overlays/region-coordinates.tsv`)**

建立 `scripts/language-reference/overlays/region-coordinates.tsv`,tab 分隔,欄位 `code\tlatitude\tlongitude`。可先只放少數代表點(空檔案亦可,生成器會跳過):

```tsv
code	latitude	longitude
TW	23.7	121.0
US	39.8	-98.6
```

- [ ] **Step 5: 建立生成器 `generate.py`**

建立 `scripts/language-reference/generate.py`:

```python
#!/usr/bin/env python3
"""Generate the pinned ISO language-reference seed SQL + manifest.

Offline and deterministic: reads committed raw/ + overlays/, emits fixed-sorted
artifacts/language-reference.sql and artifacts/manifest.json. No network access.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OVERLAYS = ROOT / "overlays"
ARTIFACTS = ROOT / "artifacts"

MIN_LANGUAGES = 7000
MIN_SCRIPTS = 100
MIN_REGIONS = 200


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def read_languages() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    with (RAW / "iso639-3.tab").open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            if row.get("Scope") != "I":
                continue
            code = (row.get("Id") or "").strip().lower()
            name = (row.get("Ref_Name") or "").strip()
            if code and name:
                rows.append((code, name))
    rows.sort()
    return rows


def read_script_directions() -> dict[str, str]:
    data = json.loads((OVERLAYS / "script-directions.json").read_text(encoding="utf-8"))
    cleaned: dict[str, str] = {}
    for k, v in data.items():
        if v not in ("ltr", "rtl"):
            raise ValueError(f"invalid direction {v!r} for {k!r}")
        cleaned[k.strip()] = v
    return cleaned


def read_scripts(directions: dict[str, str]) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    with (RAW / "iso15924.txt").open(encoding="utf-8") as fh:
        for line in fh:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = [p.strip() for p in line.split(";")]
            if len(parts) < 2 or not parts[0] or not parts[1]:
                continue
            code, name = parts[0], parts[1]
            direction = directions.get(code)
            if direction is None:
                raise ValueError(f"script {code!r} missing curated direction overlay")
            rows.append((code, name, direction))
    rows.sort()
    return rows


def read_region_coords() -> dict[str, tuple[float | None, float | None]]:
    coords: dict[str, tuple[float | None, float | None]] = {}
    path = OVERLAYS / "region-coordinates.tsv"
    if not path.exists():
        return coords
    with path.open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            code = (row.get("code") or "").strip()
            if not code:
                continue
            lat = float(row["latitude"]) if row.get("latitude") else None
            lon = float(row["longitude"]) if row.get("longitude") else None
            if (lat is None) != (lon is None):
                raise ValueError(f"region {code!r} has unpaired coordinates")
            coords[code] = (lat, lon)
    return coords


def read_regions(coords: dict[str, tuple[float | None, float | None]]) -> list[tuple[str, str, float | None, float | None]]:
    rows: list[tuple[str, str, float | None, float | None]] = []
    with (RAW / "iso3166-1.tsv").open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            code = (row.get("code") or "").strip()
            name = (row.get("name_en") or "").strip()
            if not code or not name:
                continue
            lat, lon = coords.get(code, (None, None))
            rows.append((code, name, lat, lon))
    rows.sort()
    return rows


def emit_sql(
    languages: list[tuple[str, str]],
    scripts: list[tuple[str, str, str]],
    regions: list[tuple[str, str, float | None, float | None]],
) -> str:
    lines: list[str] = ["-- AUTO-GENERATED by scripts/language-reference/generate.py. Do not edit."]

    lines.append("INSERT OR IGNORE INTO languages (code, name_en) VALUES")
    lines.append(",\n".join(f"  ({sql_str(c)}, {sql_str(n)})" for c, n in languages) + ";")

    lines.append("INSERT OR IGNORE INTO scripts (code, name_en, direction) VALUES")
    lines.append(",\n".join(f"  ({sql_str(c)}, {sql_str(n)}, {sql_str(d)})" for c, n, d in scripts) + ";")

    lines.append("INSERT OR IGNORE INTO regions (code, name_en, latitude, longitude) VALUES")
    region_vals: list[str] = []
    for c, n, lat, lon in regions:
        lat_s = "NULL" if lat is None else repr(lat)
        lon_s = "NULL" if lon is None else repr(lon)
        region_vals.append(f"  ({sql_str(c)}, {sql_str(n)}, {lat_s}, {lon_s})")
    lines.append(",\n".join(region_vals) + ";")
    return "\n".join(lines) + "\n"


def build_manifest(languages, scripts, regions, directions, region_coords, sql_text) -> dict:
    def src(name: str, path: Path, **extra) -> dict:
        payload = {
            "name": name,
            "path": str(path.relative_to(ROOT)),
            "sha256": sha256_file(path),
            "size": path.stat().st_size,
        }
        payload.update(extra)
        return payload

    return {
        "manifest_version": 1,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "sources": {
            "iso639-3": src("ISO 639-3 (individual scope)", RAW / "iso639-3.tab"),
            "iso15924": src("ISO 15924", RAW / "iso15924.txt"),
            "iso3166-1": src("ISO 3166-1 alpha-2 (curated)", RAW / "iso3166-1.tsv", curated_by="LangMap", license="CC0"),
        },
        "overlays": {
            "script_directions": {"path": "overlays/script-directions.json", "covered_scripts": len(directions)},
            "region_coordinates": {"path": "overlays/region-coordinates.tsv", "covered_regions": len(region_coords)},
        },
        "counts": {
            "languages": len(languages),
            "scripts": len(scripts),
            "regions": len(regions),
        },
        "artifacts": {
            "language_reference_sql": {
                "path": "language-reference.sql",
                "sha256": hashlib.sha256(sql_text.encode("utf-8")).hexdigest(),
            }
        },
    }


def main() -> int:
    directions = read_script_directions()
    region_coords = read_region_coords()
    languages = read_languages()
    scripts = read_scripts(directions)
    regions = read_regions(region_coords)

    if len(languages) < MIN_LANGUAGES:
        raise SystemExit(f"languages count {len(languages)} < {MIN_LANGUAGES}")
    if len(scripts) < MIN_SCRIPTS:
        raise SystemExit(f"scripts count {len(scripts)} < {MIN_SCRIPTS}")
    if len(regions) < MIN_REGIONS:
        raise SystemExit(f"regions count {len(regions)} < {MIN_REGIONS}")

    sql_text = emit_sql(languages, scripts, regions)
    manifest = build_manifest(languages, scripts, regions, directions, region_coords, sql_text)

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    (ARTIFACTS / "language-reference.sql").write_text(sql_text, encoding="utf-8")
    (ARTIFACTS / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {ARTIFACTS / 'language-reference.sql'} ({len(languages)} languages, {len(scripts)} scripts, {len(regions)} regions)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 6: 跑生成器,補齊 overlay 直到通過**

```bash
python3 scripts/language-reference/generate.py
```

若報 `script 'X' missing curated direction overlay`,把該 script 加進 `overlays/script-directions.json`(預設 `ltr`,右起書寫系統標 `rtl`),重跑直到成功。
Expected: 印出 `wrote .../language-reference.sql (N languages, M scripts, K regions)`,且 N ≥ 7000、M ≥ 100、K ≥ 200。

- [ ] **Step 7: 寫生成器測試 `test_generate.py`**

建立 `scripts/language-reference/test_generate.py`:

```python
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ARTIFACTS = ROOT / "artifacts"


class TestGenerator(unittest.TestCase):
    def test_artifacts_exist(self):
        self.assertTrue((ARTIFACTS / "language-reference.sql").exists())
        self.assertTrue((ARTIFACTS / "manifest.json").exists())

    def test_sql_is_deterministic(self):
        before = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        rc = subprocess.run([sys.executable, str(ROOT / "generate.py")], capture_output=True)
        self.assertEqual(rc.returncode, 0, rc.stderr.decode())
        after = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        self.assertEqual(before, after, "generator output must be byte-stable")

    def test_manifest_counts_match_sql_and_mins(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        sql = (ARTIFACTS / "language-reference.sql").read_text(encoding="utf-8")
        for table, key in [("languages", "languages"), ("scripts", "scripts"), ("regions", "regions")]:
            block = sql.split(f"INSERT OR IGNORE INTO {table}")[1].split(";")[0]
            row_count = block.count("\n  (")
            self.assertEqual(row_count, manifest["counts"][key], f"{table} count mismatch")
        self.assertGreaterEqual(manifest["counts"]["languages"], 7000)
        self.assertGreaterEqual(manifest["counts"]["scripts"], 100)
        self.assertGreaterEqual(manifest["counts"]["regions"], 200)

    def test_manifest_has_version_and_checksum(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        self.assertIn("manifest_version", manifest)
        actual = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        self.assertEqual(actual, manifest["artifacts"]["language_reference_sql"]["sha256"])

    def test_manifest_records_source_provenance(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        for key in ("iso639-3", "iso15924", "iso3166-1"):
            self.assertIn(key, manifest["sources"])
            self.assertTrue(manifest["sources"][key]["sha256"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 8: 跑生成器測試**

```bash
python3 -m unittest discover -s scripts/language-reference -v
```

Expected: 5 項 PASS。

- [ ] **Step 9: Commit(含生成的 artifacts 與 pinned raw)**

```bash
git add scripts/language-reference && git commit -m "feat(scripts): pinned ISO language-reference generator with curated overlays"
```

---

## Task 4: 刪除 `scripts/v2/` 並重置 migration 工具

把生成器接到本地 rebuild 流程,移除舊 Glottolog／BCP 47 工具,重置 migration lock,驗證 fresh D1 rebuild 成功。

**Files:**
- Modify: `scripts/db/lib/paths.py`、`scripts/db/lib/local.py`
- Modify(重生成): `scripts/db/migration-lock.json`
- Delete: `scripts/v2/`(整個目錄)、`scripts/db/production-baseline.json`

**Interfaces:**
- Consumes: Task 2 的 `0001`／`schema.sql`、Task 3 的 `artifacts/language-reference.sql`／`manifest.json`。
- Produces: `./dev.sh` 能重建本地 D1 並啟動 Worker;`manage.py local status` 顯示 `rebuild_required: false`。

- [ ] **Step 1: 更新 `scripts/db/lib/paths.py` 的兩個路徑**

把 `language_manifest_path`(第 34-36 行)改為:

```python
        language_manifest_path = (
            root / "scripts" / "language-reference" / "artifacts" / "manifest.json"
        )
```

把 `language_registry_sql_path` property(第 108-117 行)整段改為:

```python
    @property
    def language_registry_sql_path(self) -> Path:
        return (
            self.repo_root
            / "scripts"
            / "language-reference"
            / "artifacts"
            / "language-reference.sql"
        )
```

`ui_bundle_manifest_path`、`system_ui_sql_path` 不動(i18n 仍在,只是本 plan 不載入 SQL)。

- [ ] **Step 2: 移除 `local.py` 的 system-ui SQL 載入**

在 `scripts/db/lib/local.py` 第 58-62 行的 `try` 區塊,把這三行:

```python
        executor.execute_file(temp_state_dir, paths.schema_path)
        executor.execute_file(temp_state_dir, paths.language_registry_sql_path)
        executor.execute_file(temp_state_dir, paths.system_ui_sql_path)
```

改為兩行(移除 system-ui 載入,因新 schema 暫無 ui 表;Plan 6 會重新接上):

```python
        executor.execute_file(temp_state_dir, paths.schema_path)
        executor.execute_file(temp_state_dir, paths.language_registry_sql_path)
```

- [ ] **Step 3: 重生成 `scripts/db/migration-lock.json` 為單一 `0001` entry**

先計算 0001 的 sha256 與 size:

```bash
shasum -a 256 backend/migrations/0001_initial_schema.sql
wc -c < backend/migrations/0001_initial_schema.sql
```

把 `scripts/db/migration-lock.json` 整檔覆寫為(填入上面兩個指令的輸出;`baseline_git_commit` 用目前 HEAD):

```json
{
  "baseline_created_at": "2026-08-11T00:00:00Z",
  "baseline_git_commit": "<CURRENT_HEAD_SHORT_SHA>",
  "migrations": [
    {
      "sequence": 1,
      "filename": "0001_initial_schema.sql",
      "size": <SIZE_FROM_WC>,
      "sha256": "<SHA256_FROM_SHASUM>"
    }
  ]
}
```

- [ ] **Step 4: 刪除 `scripts/v2/` 與過時的 production baseline**

```bash
git rm -r scripts/v2
git rm scripts/db/production-baseline.json
```

(`production-baseline.json` 之後部署時用 `python3 scripts/db/manage.py production inventory` 重新生成。)

- [ ] **Step 5: 驗證 fresh D1 rebuild 成功**

確保 Worker 已停(`pkill -f "wrangler dev"` 或關閉 `./dev.sh` 終端),然後:

```bash
python3 scripts/db/manage.py local rebuild
```

Expected: 輸出含 `"status": "rebuilt"`,無錯誤。這代表 schema → registry SQL 載入 → baseline 寫入 → 驗證全過。

接著確認 fingerprint 穩定:

```bash
python3 scripts/db/manage.py local status
```

Expected: JSON 中 `"rebuild_required": false`。

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore(db): rewire local rebuild to language-reference generator and reset migration lock"
```

---

## Task 5: Registry 查詢 service 與型別

建立 `languageIdentity.ts`,封裝 query 解析(裁剪 limit／offset／q)與三張 registry 表的查詢,沿用既有的 `escapeLike` + 穩定排序 + `COUNT`／`SELECT` 共用 where 慣例。單元測試用 fake D1。

**Files:**
- Create: `backend/src/services/languageIdentity.ts`
- Create: `backend/tests/languageIdentity.test.ts`

**Interfaces:**
- Consumes: `D1Database`(來自 `c.env.DB`)。
- Produces:
  - `parseReferenceQuery(params: { q?, limit?, offset? }): ReferenceQuery`
  - `queryReferenceTable(db: D1Database, table: ReferenceTable, query: ReferenceQuery): Promise<ReferenceListResult>`,其中 `ReferenceTable = 'languages' | 'scripts' | 'regions'`,`ReferenceListResult = { items: Record<string, unknown>[]; total: number }`。

- [ ] **Step 1: 寫單元測試(先失敗)**

建立 `backend/tests/languageIdentity.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { parseReferenceQuery, queryReferenceTable, escapeLike } from '../src/services/languageIdentity';

describe('parseReferenceQuery', () => {
  it('clamps limit into [1,50] and offsets to >=0', () => {
    expect(parseReferenceQuery({ limit: '999' }).limit).toBe(50);
    expect(parseReferenceQuery({ limit: '0' }).limit).toBe(1);
    expect(parseReferenceQuery({ limit: 'abc' }).limit).toBe(20);
    expect(parseReferenceQuery({ offset: '-5' }).offset).toBe(0);
  });

  it('truncates q to 80 chars', () => {
    expect(parseReferenceQuery({ q: 'x'.repeat(200) }).q).toHaveLength(80);
    expect(parseReferenceQuery({}).q).toBe('');
  });
});

describe('escapeLike', () => {
  it('escapes backslash, percent and underscore', () => {
    expect(escapeLike('a\\b%c_d')).toBe('a\\\\b\\%c\\_d');
  });
});

describe('queryReferenceTable', () => {
  function fakeD1(rows: Record<string, unknown>[], total: number) {
    const prepare = (sql: string) => ({
      bind(..._args: unknown[]) {
        return {
          async first<T>() {
            return { total } as unknown as T;
          },
          async all<T>() {
            return { results: rows as unknown as T[] };
          },
        };
      },
    });
    return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
  }

  it('returns items and total from D1', async () => {
    const db = fakeD1([{ code: 'eng', name_en: 'English' }], 1);
    const result = await queryReferenceTable(db, 'languages', { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items[0]).toEqual({ code: 'eng', name_en: 'English' });
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/languageIdentity.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/languageIdentity'`)。

- [ ] **Step 3: 實作 `backend/src/services/languageIdentity.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';

export type ReferenceTable = 'languages' | 'scripts' | 'regions';

export interface ReferenceQuery {
  q: string;
  limit: number;
  offset: number;
}

export interface ReferenceListResult {
  items: Record<string, unknown>[];
  total: number;
}

const COLUMNS: Record<ReferenceTable, readonly string[]> = {
  languages: ['code', 'name_en'],
  scripts: ['code', 'name_en', 'direction'],
  regions: ['code', 'name_en', 'latitude', 'longitude'],
};

const MAX_LIMIT = 50;
const MAX_Q = 80;

export function parseReferenceQuery(params: {
  q?: string;
  limit?: string;
  offset?: string;
}): ReferenceQuery {
  const limitRaw = Number(params.limit ?? '20');
  const limit = Math.min(
    Math.max(Number.isFinite(limitRaw) ? limitRaw : 20, 1),
    MAX_LIMIT,
  );
  const offset = Math.max(parseInt(params.offset ?? '0') || 0, 0);
  const q = (params.q ?? '').slice(0, MAX_Q);
  return { q, limit, offset };
}

export function escapeLike(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
}

export async function queryReferenceTable(
  db: D1Database,
  table: ReferenceTable,
  query: ReferenceQuery,
): Promise<ReferenceListResult> {
  const cols = COLUMNS[table].join(', ');
  const escapedQ = escapeLike(query.q);
  const where = escapedQ
    ? `WHERE code LIKE ? ESCAPE '\\' OR name_en LIKE ? ESCAPE '\\'`
    : '';
  const baseParams: (string | number)[] = escapedQ
    ? [`%${escapedQ}%`, `%${escapedQ}%`]
    : [];

  const countRow = await db
    .prepare(`SELECT COUNT(*) as total FROM ${table} ${where}`)
    .bind(...baseParams)
    .first<{ total: number }>();
  const total = countRow?.total ?? 0;

  const order = escapedQ
    ? `ORDER BY CASE WHEN code = ? COLLATE NOCASE THEN 0 WHEN code LIKE ? ESCAPE '\\' THEN 1 ELSE 2 END, code ASC LIMIT ? OFFSET ?`
    : `ORDER BY code ASC LIMIT ? OFFSET ?`;

  const selectParams = [...baseParams];
  if (escapedQ) selectParams.push(query.q, `${escapedQ}%`);
  selectParams.push(query.limit, query.offset);

  const { results } = await db
    .prepare(`SELECT ${cols} FROM ${table} ${where} ${order}`)
    .bind(...selectParams)
    .all();
  return { items: results as Record<string, unknown>[], total };
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/languageIdentity.test.ts
```

Expected: PASS(5 項)。

- [ ] **Step 5: Commit**

```bash
git add backend/src/services/languageIdentity.ts backend/tests/languageIdentity.test.ts
git commit -m "feat(api): add language reference query service"
```

---

## Task 6: Registry API 路由與整合測試

掛上三個 `GET /language-registry/{languages,scripts,regions}` endpoint,用 `paginated` 回應,並加整合測試(需先以 `./dev.sh` 重建並啟動 Worker)。

**Files:**
- Create: `backend/src/routes/languageRegistry.ts`(新版)
- Modify: `backend/src/routes/index.ts`(註冊新 route)
- Create: `backend/tests/registryIntegration.test.ts`

**Interfaces:**
- Consumes: Task 5 的 `parseReferenceQuery`／`queryReferenceTable`;`paginated` from `utils/response`;`Bindings` from `types`。
- Produces: 三個公開 endpoint,回應 `{ success, data: { items, total, skip, limit, hasMore } }`。

- [ ] **Step 1: 寫整合測試(先失敗)**

建立 `backend/tests/registryIntegration.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

function get(path: string): Promise<Response> {
  return fetch(`${BASE_URL}${path}`);
}

describe('language registry API', () => {
  it('lists languages paginated', async () => {
    const res = await get('/api/v2/language-registry/languages?limit=5');
    expect(res.status).toBe(200);
    const body = await res.json() as {
      success: boolean;
      data: { items: Array<{ code: string }>; total: number; limit: number; skip: number; hasMore: boolean };
    };
    expect(body.success).toBe(true);
    expect(body.data.items.length).toBeLessThanOrEqual(5);
    expect(body.data.total).toBeGreaterThan(1000);
    expect(body.data.limit).toBe(5);
  });

  it('ranks an exact language code match first', async () => {
    const res = await get('/api/v2/language-registry/languages?q=eng');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string }> } };
    expect(body.data.items[0]?.code).toBe('eng');
  });

  it('returns scripts with direction and ranks exact code', async () => {
    const res = await get('/api/v2/language-registry/scripts?q=Latn');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; direction: string }> } };
    expect(body.data.items[0]?.code).toBe('Latn');
    expect(body.data.items[0]?.direction).toBe('ltr');
  });

  it('marks Arab script as rtl', async () => {
    const res = await get('/api/v2/language-registry/scripts?q=Arab');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; direction: string }> } };
    const arab = body.data.items.find((s) => s.code === 'Arab');
    expect(arab?.direction).toBe('rtl');
  });

  it('lists regions and ranks exact code', async () => {
    const res = await get('/api/v2/language-registry/regions?q=TW');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string }> } };
    expect(body.data.items[0]?.code).toBe('TW');
  });

  it('clamps limit to max 50', async () => {
    const res = await get('/api/v2/language-registry/languages?limit=999');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { limit: number } };
    expect(body.data.limit).toBe(50);
  });

  it('paginates by skip', async () => {
    const a = await get('/api/v2/language-registry/languages?limit=5&skip=0');
    const b = await get('/api/v2/language-registry/languages?limit=5&skip=5');
    const ja = await a.json() as { data: { items: Array<{ code: string }> } };
    const jb = await b.json() as { data: { items: Array<{ code: string }> } };
    expect(ja.data.items[0]?.code).not.toBe(jb.data.items[0]?.code);
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

先確定 Worker 在 8788(Task 4 已 rebuild 過;若沒啟動,開另一終端跑 `./dev.sh`)。然後:

```bash
cd backend && npx vitest run tests/registryIntegration.test.ts
```

Expected: FAIL(404,route 尚未掛上)。

- [ ] **Step 3: 建立路由 `backend/src/routes/languageRegistry.ts`**

完整內容(三個 inline handler,`c` 由 Hono app 泛型推導,直接用 `paginated(c, ...)`):

```ts
import { Hono } from 'hono';
import { paginated } from '../utils/response';
import { parseReferenceQuery, queryReferenceTable, type ReferenceTable } from '../services/languageIdentity';
import type { Bindings } from '../types';

const languageRegistry = new Hono<{ Bindings: Bindings }>();

function parseQs(c: { req: { query: (k: string) => string | undefined } }) {
  return {
    q: c.req.query('q'),
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  };
}

async function respond(c: Parameters<Parameters<typeof languageRegistry.get>[1]>[0], table: ReferenceTable) {
  const query = parseReferenceQuery(parseQs(c));
  const { items, total } = await queryReferenceTable(c.env.DB, table, query);
  return paginated(c, items, total, query.offset, query.limit);
}

languageRegistry.get('/languages', (c) => respond(c, 'languages'));
languageRegistry.get('/scripts', (c) => respond(c, 'scripts'));
languageRegistry.get('/regions', (c) => respond(c, 'regions'));

export default languageRegistry;
```

`respond` 的第一個參數型別用 `Parameters<Parameters<typeof languageRegistry.get>[1]>[0]` 直接抓 Hono 推導出的 context 型別,省去手標泛型。`parseQs` 同時接受 `skip` 與 `offset` query(回應欄位 `paginated` 命名為 `skip`,測試用 `skip`)。

- [ ] **Step 4: 在 `backend/src/routes/index.ts` 註冊新 route**

完整新內容:

```ts
import { Hono } from 'hono';
import auth from './auth';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);

export default api;
```

- [ ] **Step 5: 跑整合測試確認通過**

確定 Worker 在 8788(schema 已含 registry 資料):

```bash
cd backend && npx vitest run tests/registryIntegration.test.ts
```

Expected: 7 項 PASS。

- [ ] **Step 6: 跑全部測試確認無回歸**

```bash
cd backend && npm test
```

Expected: `auth`、`ulid`、`schemaContract`、`languageIdentity`、`registryIntegration` 全 PASS。

- [ ] **Step 7: 跑 scripts 測試**

```bash
python3 -m unittest discover scripts
```

Expected: 含 `language-reference/test_generate.py` 與既有 `scripts/db/tests/*` 全 PASS。

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(api): expose read-only ISO reference registry endpoints"
```

---

## Self-Review

**1. Spec coverage(spec §6、§13.1、§16、§17.3 對照):**
- §6.1 三張 registry 表欄位 → Task 2 schema(逐字抄)。
- §6.2 pinned 來源 + manifest + 不依賴 runtime network + script direction overlay + region 座標 overlay + runtime 唯讀 → Task 3 生成器 + Task 6 GET-only。
- §13.1 三個 `GET /language-registry/*` → Task 6。
- §16.1 刪舊 migration 建 0001 → Task 2。§16.2 重寫 schema.sql 等價 → Task 2。§16.3 重置 lock／baseline／fixture → Task 4。§16.4 刪 scripts/v2 → Task 4。§16.5 新增 scripts/language-reference → Task 3。§16.6 i18n locale 改動 → **延後至 Plan 2/6**(依賴 language_locales,本 plan 範圍外,已在 Task 4 Step 2 暫時卸除 system-ui 載入)。§16.7 舊 DB 刪除重建 → greenfield 性質,Task 4 rebuild 體現。
- §17.3 registry generator 可重現／排序／checksum／筆數下限 → Task 3 測試;fresh D1 rebuild → Task 4;schema.sql／migration／fingerprint 一致 → Task 2 + Task 4;新 schema 不含五張舊表 → Task 2 契約測試。
- 缺口:無未覆蓋的 in-scope 項目。

**2. Placeholder scan:** 無 TBD／TODO;ISO 3166-1 的 249 行條目與 script overlay 由 engineer 依指示填入並由生成器驗證報錯(非 placeholder,是可執行的 curator 步驟)。

**3. Type consistency:** `ReferenceTable`／`ReferenceQuery`／`ReferenceListResult` 在 Task 5 定義並被 Task 6 引用;`parseReferenceQuery`／`queryReferenceTable`／`escapeLike` 名稱一致;`paginated(c, items, total, skip, limit)` 簽名與 `utils/response.ts` 一致;route 同時接受 `skip` 與 `offset` query(測試用 `skip`,與 `paginated` 回應欄位名對齊)。
