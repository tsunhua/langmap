# Task 3 Report — UI translation reference bundle

日期：2026-08-01

## 實作摘要

- 新增 `scripts/i18n/generate-bundle.py`，從 `web/src/locales/en.ts` 與四個 first-party JSON 生成單一 managed system UI bundle。
- 保留既有 `generate-i18n-sql.py` 的 deterministic `expression_id`、`stable_edge_id` 與既有 SQL insert semantics；同時抽出可 import 的純函式供 bundle generator 重用。
- unknown source key 改為直接 fail，不再 warning/skip。
- 新增 collision 檢查：若 deterministic `expression_id` / `edge_id` 指向不同 payload，生成立即失敗。
- 產出版本控制 artifact：
  - `scripts/i18n/artifacts/system-ui/system-ui.sql`
  - `scripts/i18n/artifacts/system-ui/manifest.json`
- `manifest.json` 記錄：
  - `schema_version = 1`
  - `project_id = "langmap-web"`
  - `ownership_scope = "managed-system-ui"`
  - source checksums
  - locale/message/translation counts
  - output SQL SHA-256
- `scripts/i18n/import-all.sh` 改為 compatibility wrapper：
  - `--local`：先重建 bundle，再一次匯入單一 SQL
  - `--remote`：顯示 deprecation 並拒絕直接寫 production
- 更新 `scripts/i18n/test-import-all.sh` 與 `scripts/i18n/README.md`。

## Commit hash

實作 commit：

```text
04187096a1879314316bae73ae725be5b34fb3a5
```

Commit message：

```text
feat: generate pinned system ui translation bundle
```

## TDD — RED

### Command 1

```bash
python3 scripts/i18n/test_generate_bundle.py
```

Result:

```text
FFF  ⚠  Skipping "missing.key": source text not found in en.ts
F

======================================================================
FAIL: test_cli_fails_on_unknown_source_key_and_keeps_existing_artifacts
AssertionError: False is not true : generate-bundle.py should exist

FAIL: test_cli_generates_manifest_sql_and_idempotent_bundle
AssertionError: False is not true : generate-bundle.py should exist

FAIL: test_detects_deterministic_id_collisions_for_different_text
AssertionError: False is not true : generate-bundle.py should exist

FAIL: test_generate_i18n_sql_rejects_unknown_keys_instead_of_skipping
AssertionError: ValueError not raised

FAILED (failures=4)
```

RED interpretation：

- `generate-bundle.py` 尚不存在。
- `generate-i18n-sql.py` 對 unknown key 仍是 skip，而不是 fail。

### Command 2

```bash
bash scripts/i18n/test-import-all.sh
```

Result:

```text
(exit 1)
```

RED interpretation：

- 既有 wrapper 仍是逐 locale 匯入，與 bundle compatibility wrapper 規格不符。

## TDD — GREEN

### Command 1

```bash
python3 scripts/i18n/test_generate_bundle.py
```

Result:

```text
....
----------------------------------------------------------------------
Ran 4 tests in 0.167s

OK
```

### Command 2

```bash
bash scripts/i18n/test-import-all.sh
```

Result:

```text
PASS: import-all bundle wrapper behavior
```

## 生成 determinism / idempotency 證據

### 真實輸入生成結果

```bash
python3 scripts/i18n/generate-bundle.py
```

Result:

```json
{
  "schema_version": 1,
  "project_id": "langmap-web",
  "ownership_scope": "managed-system-ui",
  "locale_codes": [
    "es-ES",
    "ja-JP",
    "zh-Hans-CN",
    "zh-Hant-TW"
  ],
  "counts": {
    "locale_count": 4,
    "message_count": 312,
    "translation_count": 1228
  },
  "inputs": {
    "source_catalog": {
      "path": "/Users/lim/Documents/Code/tsunhua/langmap/web/src/locales/en.ts",
      "sha256": "23ee2bf5ed32a022db249e49f75c9804bf1866024affaab10e8eaba5ee300d50"
    },
    "locales": {
      "es-ES": {
        "path": "/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/es-ES.json",
        "sha256": "98da85086beceefe9981912918ee193c86dd7e342f4c206d420951e9fa84368a"
      },
      "ja-JP": {
        "path": "/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/ja-JP.json",
        "sha256": "9ea6a6275bd41051f3abab66b247abccfe093113051601667aa85bb616c7040c"
      },
      "zh-Hans-CN": {
        "path": "/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/zh-Hans-CN.json",
        "sha256": "1ec4df8768aba2579c36913f045b3785b1400c520240e9b604fbf7ab2ba59966"
      },
      "zh-Hant-TW": {
        "path": "/Users/lim/Documents/Code/tsunhua/langmap/scripts/i18n/zh-Hant-TW.json",
        "sha256": "0c554163e4082aad1ababec82c4c4a983fe63e7687f446209725914780c56b5c"
      }
    }
  },
  "artifacts": {
    "system_ui_sql": {
      "path": "system-ui.sql",
      "sha256": "5415772e6438b05c5d08aac345e551e87da265558d960465b3c5e152936742c0"
    }
  }
}
```

### 連續兩次 checksum 比對

Command:

```bash
shasum -a 256 scripts/i18n/artifacts/system-ui/system-ui.sql scripts/i18n/artifacts/system-ui/manifest.json
```

First run:

```text
5415772e6438b05c5d08aac345e551e87da265558d960465b3c5e152936742c0  scripts/i18n/artifacts/system-ui/system-ui.sql
13331cde7246b80d7d821ffee5286f039e9a9abb2f0b57b39f0afc094d7b01fe  scripts/i18n/artifacts/system-ui/manifest.json
```

Second run after regenerating:

```text
5415772e6438b05c5d08aac345e551e87da265558d960465b3c5e152936742c0  scripts/i18n/artifacts/system-ui/system-ui.sql
13331cde7246b80d7d821ffee5286f039e9a9abb2f0b57b39f0afc094d7b01fe  scripts/i18n/artifacts/system-ui/manifest.json
```

Conclusion：

- `system-ui.sql` checksum identical across both runs.
- `manifest.json` checksum identical across both runs.

### Second-run diff check

```bash
git diff -- scripts/i18n/artifacts/system-ui/system-ui.sql scripts/i18n/artifacts/system-ui/manifest.json
```

Result:

```text
(no output)
```

Conclusion：

- 第二次生成沒有引入新的 working tree diff。

### Temporary SQLite double-load idempotency

Command:

```bash
python3 - <<'PY'
import json
import sqlite3
from pathlib import Path

sql_text = Path('scripts/i18n/artifacts/system-ui/system-ui.sql').read_text(encoding='utf-8')
db = sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE languages (code TEXT PRIMARY KEY, name TEXT NOT NULL, direction TEXT NOT NULL);
CREATE TABLE expressions (id INTEGER PRIMARY KEY, text TEXT NOT NULL, language_code TEXT NOT NULL, source_type TEXT, source_ref TEXT, review_status TEXT);
CREATE TABLE ui_locales (project_id TEXT NOT NULL, code TEXT NOT NULL, native_name TEXT NOT NULL, direction TEXT NOT NULL, status TEXT NOT NULL, PRIMARY KEY (project_id, code));
CREATE TABLE ui_messages (project_id TEXT NOT NULL, key TEXT NOT NULL, source_expression_id INTEGER NOT NULL, placeholders_json TEXT, source_hash TEXT NOT NULL, status TEXT NOT NULL, PRIMARY KEY (project_id, key));
CREATE TABLE expression_edges (id TEXT PRIMARY KEY, expression_a_id INTEGER NOT NULL, expression_b_id INTEGER NOT NULL, score INTEGER NOT NULL, source TEXT NOT NULL);
''')
db.executemany(
    'INSERT INTO languages (code, name, direction) VALUES (?, ?, ?)',
    [
        ('zh-Hans-CN', '简体中文（中国）', 'ltr'),
        ('zh-Hant-TW', '繁體中文（台灣）', 'ltr'),
        ('es-ES', 'Español (España)', 'ltr'),
        ('ja-JP', '日本語（日本）', 'ltr'),
    ],
)
def counts():
    return {
        table: db.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
        for table in ('ui_locales', 'ui_messages', 'expressions', 'expression_edges')
    }
db.executescript(sql_text)
first = counts()
db.executescript(sql_text)
second = counts()
print(json.dumps({'first': first, 'second': second}, ensure_ascii=False))
PY
```

Result:

```json
{"first": {"ui_locales": 4, "ui_messages": 312, "expressions": 1308, "expression_edges": 1058}, "second": {"ui_locales": 4, "ui_messages": 312, "expressions": 1308, "expression_edges": 1058}}
```

Conclusion：

- 同一份 bundle 連續載入兩次後，row counts 完全不變，符合 idempotent 要求。

## 未解決疑慮

1. 四個 first-party locale JSON 目前都只有 307 keys，而 source catalog 有 312 keys。
   每個 locale 都缺同一組 5 keys：
   - `languageCreate.optional`
   - `languageCreate.requiredHint`
   - `languageDetail.representativeCities`
   - `languageDetail.representativeCitiesNote`
   - `languagesPage.addLanguage`

2. 目前 bundle 允許 partial translation coverage，會完整寫入 312 個 source messages，
   但 translation rows 只寫入現有 JSON 提供的 1228 筆。這不阻塞 Task 3 的 bundle
   生成與 determinism / idempotency 目標，但若 Task 4 期待 full first-party coverage，
   需要先補齊上述 5 keys。

3. artifact replacement 已做 staging + rollback 保護，能避免生成或驗證失敗時覆蓋既有
   結果；但檔案系統層級仍不是單一目錄 swap transaction。以目前需求來說已足夠隔離
   失敗結果，但若未來 artifact 數量增加，可能值得升級為版本化目錄 + pointer 切換。

## Reviewer fixes appended on 2026-08-01

### Fix commit

```text
ddd7749cf0a81026fd4a043b24699620c1a71571
```

Commit message：

```text
fix: harden system ui bundle provenance
```

### Reviewer finding 1 — single snapshot provenance

- `generate-bundle.py` 現在會對 source catalog 與四個 pinned locale 各讀取一次 bytes。
- SQL generation、manifest checksum、解析結果都共用同一份 in-memory snapshot。
- `generate-i18n-sql.py` 補上 `parse_en_ts_bytes` / `load_translations_bytes`，避免 bundle generator
  為了重用既有邏輯而重新讀檔。

新增 TDD coverage：

- `test_generate_bundle_uses_single_read_snapshot_for_manifest_and_sql`

這個測試透過 `read_bytes_fn` hook 強制任何 path 只允許讀一次；若 generator 在 manifest
階段重讀檔案，測試會直接失敗。

### Reviewer finding 2 — pinned locale fail-closed

- bundle 現在只接受且必須剛好包含：
  - `es-ES`
  - `ja-JP`
  - `zh-Hans-CN`
  - `zh-Hant-TW`
- locale 順序固定為上述穩定排序。
- 缺少 locale、額外 locale、重複 locale override 都會 fail fast。

新增 TDD coverage：

- `test_cli_rejects_missing_or_extra_locale_set`

### Reviewer finding 3 — atomic rollback regression test

- `replace_artifacts()` 現在抽出可測的 `replace_fn` / `rollback_replace_fn` 注入點。
- 新增中途 replace 失敗的回歸測試，驗證既有 `system-ui.sql` 與 `manifest.json`
  bytes 會被 rollback 保留。

新增 TDD coverage：

- `test_replace_artifacts_rolls_back_if_replace_fails_midway`

### Reviewer-fix RED

Command:

```bash
python3 scripts/i18n/test_generate_bundle.py
```

Result:

```text
..F.E.E

FAIL: test_cli_rejects_missing_or_extra_locale_set
AssertionError: 0 == 0

ERROR: test_generate_bundle_uses_single_read_snapshot_for_manifest_and_sql
TypeError: generate_bundle() got an unexpected keyword argument 'read_bytes_fn'

ERROR: test_replace_artifacts_rolls_back_if_replace_fails_midway
TypeError: replace_artifacts() got an unexpected keyword argument 'replace_fn'
```

Interpretation：

- 現有實作尚未提供 snapshot hook。
- locale set 尚未 fail-closed。
- atomic writer 尚未暴露可測 failure injection。

### Reviewer-fix GREEN

Command:

```bash
python3 scripts/i18n/test_generate_bundle.py
```

Result:

```text
.......
----------------------------------------------------------------------
Ran 7 tests in 0.304s

OK
```

### Reviewer-fix verification

Commands:

```bash
bash scripts/i18n/test-import-all.sh
git diff --check
python3 scripts/i18n/generate-bundle.py
shasum -a 256 scripts/i18n/artifacts/system-ui/system-ui.sql scripts/i18n/artifacts/system-ui/manifest.json
python3 scripts/i18n/generate-bundle.py
shasum -a 256 scripts/i18n/artifacts/system-ui/system-ui.sql scripts/i18n/artifacts/system-ui/manifest.json
```

Observed:

- `bash scripts/i18n/test-import-all.sh` → `PASS: import-all bundle wrapper behavior`
- `git diff --check` → no output
- bundle regenerate before/after fix validation:
  - `system-ui.sql`: `5415772e6438b05c5d08aac345e551e87da265558d960465b3c5e152936742c0`
  - `manifest.json`: `13331cde7246b80d7d821ffee5286f039e9a9abb2f0b57b39f0afc094d7b01fe`

Additional idempotency check stayed unchanged:

```json
{"first": {"ui_locales": 4, "ui_messages": 312, "expressions": 1308, "expression_edges": 1058}, "second": {"ui_locales": 4, "ui_messages": 312, "expressions": 1308, "expression_edges": 1058}}
```

## Scoped re-review append on 2026-08-01

Reviewer follow-up identified one remaining coverage gap: duplicate locale override rejection was implemented in `parse_locale_args()`, but not covered by a CLI regression test.

### Coverage update

- 新增 `test_cli_rejects_duplicate_locale_override`
- 驗證 duplicate `--locale es-ES=...` 會讓 CLI fail fast，且 stderr 包含 `duplicate locale override: es-ES`

### TDD note

這次 scoped fix 是 coverage-only。實作行為在前一個 fix commit 已存在，因此新增 regression test 後立即通過；沒有額外 production code 變更需求。

Command:

```bash
python3 scripts/i18n/test_generate_bundle.py
```

Result:

```text
........
----------------------------------------------------------------------
Ran 8 tests in 0.383s

OK
```

Additional verification:

```text
bash scripts/i18n/test-import-all.sh -> PASS: import-all bundle wrapper behavior
git diff --check -> no output
```
