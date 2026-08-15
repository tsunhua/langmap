# Plan: Localized Language Names — Seed / Sync Data

- **Date**: 2026-08-15
- **Status**: Draft
- **Spec**: `docs/superpowers/specs/2026-08-15-localized-language-names-design.md`
- **Plan family**: 此為三份計畫的第二份，依賴第一份（後端）的 migration 0019 欄位。依序：後端 → seed → 前端，全部完成後才整體驗收。

## Goal

第一份後端計畫把 `name_expression_id` 欄位接上解析服務，但種子資料尚未落地（所有值皆 NULL，回退鏈仍安全）。本計畫補上資料層：

1. 用 Python 重現決定性 expression ID 演算法（與 `backend/src/services/expressionIdentity.ts` 一致，已交叉驗證 24 個 known-answer 值），並以單元測試固定。
2. 擴充 `scripts/language-reference/generate.py`：輸出 canonical 英文名稱 expression（每個 ISO language + 9 個系統 locale）、`cmn` 譯名 target expression、translation `expression_edges`、locale attestation，以及 `languages`／`language_locales` 的 `name_expression_id` 回填。
3. 新增兩個 committed overlay 輸入（canonical 名稱文字、譯名清單），產物與 `manifest.json` 一併更新。
4. 本機 rebuild 後，以整合測試驗證解析後名稱（language summary 的 `name`、locale 的 `display_name`）在 `cmn-Hans-CN`／`cmn-Hant-TW`／`eng-Latn-US` 下的結果（依後端計畫 T4／T5 的欄位契約）。
5. 提供 production 落地步驟（migration 0019 已套用後執行 `production plan`／`apply`，需明確批准）。

不新增 migration：欄位已在後端計畫 0019；種子資料全部經 `language-reference.sql` 產物進入，`INSERT OR IGNORE`＋決定性 id 保證重跑冪等。

## Architecture

```
overlays/name-canonical-texts.json    overlays/name-translations.json   raw/iso639-3.tab …
        └──────────┬──────────────────────────────┘            │
                   ▼                                             ▼
        scripts/language-reference/generate.py  (extended: hash port + emit)
                   │  deterministic ids (eng:<hash>, cmn:<hash>, name-edge/name-att)
                   ▼
        artifacts/language-reference.sql  ──>  artifact SHA + manifest.json (fingerprint)
                   │
        ┌──────────┴───────────────┐
        │  local: manage.py local  │  production: manage.py production plan/apply
        │  rebuild（schema→LR→UI）  │  （migrations → LR → system-ui，INSERT OR IGNORE）
        ▼                          ▼
   languages/locales.name_expression_id 回填 → 後端 resolver（後端計畫 T2–T5）消費
```

資料模型（spec §5、§6）：

- canonical 英文名稱 expression：`lang_code='eng'`，`text` 等於對應 language 的 `name_en` 或 locale 的 `name_en`，id = `eng:<base32(sha256(text)[:16])>`。
- `languages.name_expression_id`／`language_locales.name_expression_id` 指向上述 canonical expression（spec：locale 的 canonical 是其英文名稱，如 `jpn-Jpan-JP` → `Japanese (Japan)`）。
- 譯名 target：`lang_code = target locale 的 lang_code`（本計畫為 `cmn`），id = `cmn:<base32(sha256(text)[:16])>`。
- translation edge：`expression_edges(a, b, score=0, source='translation')`，`a < b`（CHECK 約束），id = `name-edge:<a>:<b>`。
- attestation：target expression 在 target locale code 的 `expression_locale_attestations`，id = `name-att:<expression_id>:<locale>`。
- binding 回填：以「canonical text 對上 DB 目前 `name_en`」的 set-based `UPDATE`，避免把已 baked 的 id 寫死（DB `name_en` 變動時安全落空為 NULL，不誤綁）。

## Tech Stack

- 既有 Python（generate.py、pytest 9.1.0、unittest 樣板沿用 `scripts/db/tests`）。
- 種子資料沿用 `artifacts/language-reference.sql`（本地 rebuild 與 production apply 都會執行，`INSERT OR IGNORE` 冪等）。
- 整合測試沿用 Vitest＋真實 D1（`languagesIntegration.test.ts`，`127.0.0.1:8788`）。

## Risks and Uncertainties

| Risk | Impact | Mitigation |
|---|---|---|
| Python hash 實作與 TS 不一致 | 種子 id 錯、binding 落空 | 交叉驗證 24 個已知值＋`test_generate.py` known-answer 測試（T1） |
| DB `name_en` 與 ISO 文字不一致（如 `nan` 被 0018 改成 `Min Nan Chinese (Hokkien)`） | binding 找不到 canonical | `language_canonical_overrides` overlay 提供覆寫文字；binding 用「目前 `name_en` 文字比對」而非 baked id |
| 兩語言共用相同 `name_en` | canonical expression 重複 | `UNIQUE(lang_code, text)`＋`INSERT OR IGNORE` 去重，共用同一 expression（語意正確） |
| 與 runtime 產生的 expression／edge 撞 id | 重複或約束衝突 | id 決定性且依文字；`INSERT OR IGNORE` 對任何 UNIQUE 衝突皆忽略，重跑冪等 |
| `UPDATE ... SET = (correlated subquery)` 在 D1 不支援 | 回填失敗 | SQLite 3.33+ 支援；rebuild 驗證失敗則退為逐列 `UPDATE ... WHERE code = ?` |
| canonical 尚未 emit 就被 translation 引用 | FK 失敗 | generator 先收集完整 canonical 集合，emit 後才 emit translation；缺失引用直接 raise |
| 上線順序：production 尚未套 0019 | seed UPDATE 碰到不存在欄位 | production 流程先 apply migration（0019），再 apply registry SQL；文件寫明順序 |
| 整合測試需後端 T4/T5 欄位才跑 | 計畫間耦合 | 本計畫驗收排在後端計畫完成後；測試僅新增 `name`／`display_name` 斷言，不改既有斷言 |

## Task List

### T1: Python 版決定性 ID 演算法 + known-answer 測試

成功標準：`python3 -m pytest scripts/language-reference/test_generate.py` 全綠，且 24 個值與 TS 實作一致。

在 `generate.py` 新增（與 `expressionIdentity.ts` 同義）：

```python
BASE32_ALPHABET = "abcdefghijklmnopqrstuvwxyz234567"


def expression_text_hash(text: str) -> str:
    normalized = text.strip().normalize("NFC")
    digest = hashlib.sha256(normalized.encode("utf-8")).digest()[:16]
    bits = "".join(f"{b:08b}" for b in digest)
    out: list[str] = []
    for i in range(0, len(bits), 5):
        out.append(BASE32_ALPHABET[int(bits[i : i + 5].ljust(5, "0"), 2)])
    return "".join(out)


def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    return f"{lang_code}:{text_hash}" if homograph_index == 1 else f"{lang_code}:{text_hash}.{homograph_index}"
```

新增 `scripts/language-reference/test_generate.py`（pytest 樣式，僅測 hash／id 純函式，不碰檔案）：

```python
from generate import build_expression_id, expression_text_hash

KNOWN = {
    "English": "xiiyx574tqno3qpnwkfavkdobm",
    "Japanese": "xzhosbwt57wpynfjjjwng6ddhi",
    "Mandarin Chinese": "wahosxiiyppkc7vkgn2foa4zda",
    "Min Nan Chinese (Hokkien)": "cvv4hpw64s3dtefqqwzcbxhr2y",
    "Japanese (Japan)": "gu52ixjn6apik3jjkpzi5bj4oq",
    "普通话": "6q2zdme4dnc4v7u2tg6jzfu4rq",
    "華語": "ourhuuu2u4tghx6o6m7won2u6m",
    "日语": "hkke3wzynd2lehwvcuqfvvvh4a",
    "日語": "yigtj7ofv3bw4svpyfze3x4adq",
    "日语（日本）": "auelzis6d2oav6qw4gfizxoipq",
    "日語（日本）": "fey3ky7n7du23uvlvnc6yqv3xi",
    "英语": "2fsixlf4cyykmdv4aci7u6smw4",
    "英語": "k64pyj2pcbv4msv2jspahel7ue",
    "西班牙语": "nsds2j7ygwo4pjnluarq3hn3xy",
    "西班牙語": "5vowucfjacuokpyxngunzsmowq",
    "闽南语": "dtd7wb44qk6zm2g2h667asgcbq",
    "閩南語": "gslrtrbgubtqpzrokd3o47oymu",
}


def test_expression_text_hash_known_answers():
    for text, expected in KNOWN.items():
        assert expression_text_hash(text) == expected, text


def test_build_expression_id():
    assert build_expression_id("cmn", KNOWN["普通话"]) == "cmn:6q2zdme4dnc4v7u2tg6jzfu4rq"
    assert build_expression_id("cmn", "hash", 2) == "cmn:hash.2"
```

### T2: committed overlays

新增兩個 overlay 檔（`.json`，UTF-8，含 `ensure_ascii=False` 風格；沿用 `script-directions.json` 的「程式碼驗證、缺則 raise」慣例）。

`overlays/name-canonical-texts.json`（canonical 名稱文字：覆寫 ISO 的 language 名稱 + 9 個系統 locale 的英文名稱；文字必須等於 DB 目前 `name_en`，見 `schema.sql` 132–143 行與 migration 0018）：

```json
{
  "language_canonical_overrides": {
    "nan": "Min Nan Chinese (Hokkien)"
  },
  "locale_canonical_texts": {
    "eng-Latn-US": "English (US)",
    "cmn-Hant-TW": "Taiwan Mandarin",
    "cmn-Hans-CN": "Simplified Chinese",
    "nan-Hant-CN": "Min Nan Chinese (Hokkien)",
    "nan-Hans-CN": "Min Nan Chinese (Hokkien)",
    "nan-Hant-TW": "Taiwanese Hokkien",
    "nan-Hant-MY_Penang": "Penang Hokkien",
    "spa-Latn-ES": "Spanish (Spain)",
    "jpn-Jpan-JP": "Japanese (Japan)"
  }
}
```

`overlays/name-translations.json`（canonical 文字 → target locale → 譯名；每個 `(canonical_text, target_locale)` 只能有一個 text，generator 驗證；target lang 由 locale code 前段 `cmn` 得出）：

```json
{
  "translations": [
    { "canonical_text": "Japanese", "target_locale": "cmn-Hans-CN", "text": "日语" },
    { "canonical_text": "Japanese", "target_locale": "cmn-Hant-TW", "text": "日語" },
    { "canonical_text": "English", "target_locale": "cmn-Hans-CN", "text": "英语" },
    { "canonical_text": "English", "target_locale": "cmn-Hant-TW", "text": "英語" },
    { "canonical_text": "Spanish", "target_locale": "cmn-Hans-CN", "text": "西班牙语" },
    { "canonical_text": "Spanish", "target_locale": "cmn-Hant-TW", "text": "西班牙語" },
    { "canonical_text": "Mandarin Chinese", "target_locale": "cmn-Hans-CN", "text": "普通话" },
    { "canonical_text": "Mandarin Chinese", "target_locale": "cmn-Hant-TW", "text": "華語" },
    { "canonical_text": "Min Nan Chinese (Hokkien)", "target_locale": "cmn-Hans-CN", "text": "闽南语" },
    { "canonical_text": "Min Nan Chinese (Hokkien)", "target_locale": "cmn-Hant-TW", "text": "閩南語" },
    { "canonical_text": "Japanese (Japan)", "target_locale": "cmn-Hans-CN", "text": "日语（日本）" },
    { "canonical_text": "Japanese (Japan)", "target_locale": "cmn-Hant-TW", "text": "日語（日本）" }
  ]
}
```

> 文字一律 NFC（overlay 以 UTF-8 儲存，`json.loads` 後 generator 再 `normalize("NFC")` 保險）。

### T3: generate.py 擴充（emit canonical + translations + bindings）

成功標準：`python3 scripts/language-reference/generate.py` 產生含 name 種子的 `language-reference.sql`，`artifact 內 id 與 T1 已知值一致`。

新增讀取函式與 emit 函式：

```python
def read_name_canonical_texts() -> tuple[dict[str, str], dict[str, str]]:
    data = json.loads((OVERLAYS / "name-canonical-texts.json").read_text(encoding="utf-8"))
    overrides = {k.strip(): v.strip() for k, v in data.get("language_canonical_overrides", {}).items() if v}
    locales = {k.strip(): v.strip() for k, v in data.get("locale_canonical_texts", {}).items() if v}
    for code, text in locales.items():
        lang = code.split("-", 1)[0]
        if len(lang) != 3:
            raise ValueError(f"locale {code!r} has invalid lang prefix {lang!r}")
        if not text:
            raise ValueError(f"locale {code!r} missing canonical text")
    return overrides, locales


def read_name_translations() -> list[dict[str, str]]:
    data = json.loads((OVERLAYS / "name-translations.json").read_text(encoding="utf-8"))
    rows: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for t in data.get("translations", []):
        canonical = (t.get("canonical_text") or "").strip()
        locale = (t.get("target_locale") or "").strip()
        text = (t.get("text") or "").strip()
        if not canonical or not locale or not text:
            raise ValueError(f"incomplete translation row {t!r}")
        if (canonical, locale) in seen:
            raise ValueError(f"duplicate translation for {canonical!r} in {locale!r}")
        seen.add((canonical, locale))
        rows.append({"canonical_text": canonical, "target_locale": locale, "text": text})
    rows.sort(key=lambda r: (r["canonical_text"], r["target_locale"]))
    return rows
```

canonical 集合與 emit：

```python
def collect_canonical_name_texts(
    languages: list[tuple[str, str]],
    overrides: dict[str, str],
    locale_texts: dict[str, str],
) -> list[str]:
    texts = {override for override in overrides.values()}
    for code, name_en in languages:
        texts.add(overrides.get(code, name_en))
    texts.update(locale_texts.values())
    return sorted(texts)


def emit_name_seed_sql(
    canonical_texts: list[str],
    locale_texts: dict[str, str],
    translations: list[dict[str, str]],
) -> tuple[list[str], dict[str, int]]:
    lines = ["-- NAME LOCALIZATION SEED (spec 2026-08-15-localized-language-names-design.md)"]
    lines.append("INSERT OR IGNORE INTO sources (id, type, name) VALUES ('system-names', 'system', 'LangMap canonical names seed');")

    expr_rows: list[str] = []
    expr_id_by_text: dict[str, str] = {}
    for text in canonical_texts:
        h = expression_text_hash(text)
        eid = build_expression_id("eng", h)
        expr_id_by_text[text] = eid
        expr_rows.append(f"  ({sql_str(eid)}, 'eng', {sql_str(text)}, {sql_str(h)}, 'system-names')")
    lines += _insert_blocks("expressions", ["id", "lang_code", "text", "text_hash", "source_id"], expr_rows)

    edge_rows: list[str] = []
    att_rows: list[str] = []
    target_rows: list[str] = []
    for t in translations:
        src = expr_id_by_text.get(t["canonical_text"])
        if src is None:
            raise ValueError(f"translation references unknown canonical text {t['canonical_text']!r}")
        lang = t["target_locale"].split("-", 1)[0]
        h = expression_text_hash(t["text"])
        tgt = build_expression_id(lang, h)
        target_rows.append(f"  ({sql_str(tgt)}, {sql_str(lang)}, {sql_str(t['text'])}, {sql_str(h)}, 'system-names')")
        a, b = sorted((src, tgt))
        edge_rows.append(f"  ({sql_str(f'name-edge:{a}:{b}')}, {sql_str(a)}, {sql_str(b)}, 0, 'translation')")
        att_rows.append(f"  ({sql_str(f'name-att:{tgt}:{t['target_locale']}')}, {sql_str(tgt)}, {sql_str(t['target_locale'])}, 'system-names')")

    if target_rows:
        lines += _insert_blocks("expressions", ["id", "lang_code", "text", "text_hash", "source_id"], target_rows)
    if edge_rows:
        lines += _insert_blocks("expression_edges", ["id", "expression_a_id", "expression_b_id", "score", "source"], edge_rows)
    if att_rows:
        lines += _insert_blocks("expression_locale_attestations", ["id", "expression_id", "language_locale_code", "source_id"], att_rows)

    bindings = [
        "-- Bind each language / locale to its canonical (eng) name expression by current name_en text.",
        "-- Unmatched rows stay NULL (safe fallback to name_en / self-name / code).",
        "UPDATE languages AS l",
        "SET name_expression_id = (SELECT e.id FROM expressions e WHERE e.lang_code = 'eng' AND e.text = l.name_en LIMIT 1)",
        "WHERE EXISTS (SELECT 1 FROM expressions e WHERE e.lang_code = 'eng' AND e.text = l.name_en);",
        "",
        "UPDATE language_locales AS l",
        "SET name_expression_id = (SELECT e.id FROM expressions e WHERE e.lang_code = 'eng' AND e.text = l.name_en LIMIT 1)",
        "WHERE EXISTS (SELECT 1 FROM expressions e WHERE e.lang_code = 'eng' AND e.text = l.name_en);",
    ]
    lines.append("\n".join(bindings))

    counts = {
        "name_canonical_expressions": len(expr_rows),
        "name_target_expressions": len(target_rows),
        "name_edges": len(edge_rows),
        "name_attestations": len(att_rows),
        "name_locales_bound_target": len(locale_texts),
    }
    return lines, counts
```

在 `emit_sql` 結尾（regions 之後）附加 `emit_name_seed_sql` 的輸出；`build_manifest` 的 `overlays` 增列 `name_canonical_texts`／`name_translations`（path＋`locale_count`／`translation_count`），`counts` 增列上述五個計數；`main()` 讀取新 overlay 後代入。

> 產物排序：canonical expressions → target expressions → edges → attestations → bindings（全 `INSERT OR IGNORE`，可重跑）。`expression_edges` 的 `a < b` 由 `sorted((src, tgt))` 保證（`cmn:…` < `eng:…`）。

### T4: 重新生成產物 + manifest + 本機 rebuild

```bash
cd scripts/language-reference && python3 generate.py
cd ../db && ./manage.sh local rebuild && ./manage.sh local verify
```

驗證（SQL 抽查，bindings 已回填）：

```bash
cd ../db
python3 -c "
from lib import paths
p = paths.ProjectPaths.discover()
import subprocess, json
rows = subprocess.run(['npx','wrangler','d1','execute','langmap-v2','--local','--command',
  \"SELECT l.code, l.name_en, e.text FROM languages l LEFT JOIN expressions e ON e.id = l.name_expression_id ORDER BY l.code\"],
  capture_output=True, text=True, cwd=p.repo_root).stdout
print(rows)"
```

預期 5 個系統語言都有 `name_expression_id`，且 `eng`→`English`、`nan`→`Min Nan Chinese (Hokkien)` 等（`nan` 靠 overlay 覆寫綁到 `eng:cvv4hpw64s3dtefqqwzcbxhr2y`）。`git diff --stat` 應顯示 artifacts 與 manifest 更新。

### T5: 整合測試（依賴後端計畫 T4/T5 的 `name`／`display_name` 契約）

在 `backend/tests/languagesIntegration.test.ts` 新增（沿用既有 fetch 樣板；language summary 的 `name` 已改為解析後名稱）：

```ts
it('resolves localized language names from seed via name', async () => {
  const namesFor = async (uiLocale: string) => {
    const res = await fetch(`${API}?limit=300&ui_locale=${uiLocale}`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string }> } };
    return new Map(body.data.items.map((item) => [item.code, item.name]));
  };
  const hans = await namesFor('cmn-Hans-CN');
  expect(hans.get('jpn')).toBe('日语');
  expect(hans.get('spa')).toBe('西班牙语');
  expect(hans.get('nan')).toBe('闽南语');
  expect(hans.get('cmn')).toBe('普通话');
  const hant = await namesFor('cmn-Hant-TW');
  expect(hant.get('jpn')).toBe('日語');
  expect(hant.get('cmn')).toBe('華語');
  const neutral = await namesFor('eng-Latn-US');
  expect(neutral.get('jpn')).toBe('Japanese');
});

it('uses secondary locale when primary is invalid', async () => {
  const res = await fetch(`${API}?limit=300&ui_locale=zzz-Zzzz-ZZ&secondary_ui_locale=cmn-Hans-CN`);
  expect(res.status).toBe(200);
  const body = await res.json() as { data: { items: Array<{ code: string; name: string }> } };
  const map = new Map(body.data.items.map((item) => [item.code, item.name]));
  expect(map.get('jpn')).toBe('日语');
});

it('resolves locale display_name from seed while keeping self-name', async () => {
  const res = await fetch(`${BASE_URL}/api/v2/language-locales/jpn-Jpan-JP?ui_locale=cmn-Hans-CN`);
  expect(res.status).toBe(200);
  const body = await res.json() as { data: { code: string; display_name: string; name: string } };
  expect(body.data.display_name).toBe('日语（日本）');
  expect(body.data.name).toBe('日本語');
});
```

執行（先啟動 Worker）：`cd backend && npm test`。

> `name`／`display_name` 欄位與 `secondary_ui_locale` 參數是後端計畫的契約（spec §6.1），本計畫只提供資料與斷言。

### T6: production 落地（需明確批准）

順序（migration 0019 先於 seed SQL，因 binding 用到新欄位）：

```bash
cd scripts/db && ./manage.sh production plan   # 檢視 pending migrations + registry/system-ui 產物
./manage.sh production apply                   # 套用 0019 + 匯入新 language-reference.sql（INSERT OR IGNORE 冪等）
./manage.sh production verify
```

驗證：`SELECT code, name_expression_id FROM languages WHERE code IN ('cmn','eng','jpn','nan','spa');` 五列皆非 NULL；抽查 `jpn` 在 cmn-Hans-CN 的顯示名為 `日语`。重跑 apply 安全（決定性 id＋`INSERT OR IGNORE`）。

## Verification

1. `python3 -m pytest scripts/language-reference/test_generate.py`（T1 known-answer）。
2. `python3 scripts/language-reference/generate.py` 成功且 `git diff --stat` 僅動到 artifacts／manifest／overlays／generate.py／test。
3. `./manage.sh local rebuild && ./manage.sh local verify` 成功；bindings SQL 抽查通過。
4. `cd backend && npm test` 全綠（含 T5 新增三測；先啟動 Worker）。
5. 跨前後端 `./build.sh`（若前端計畫已合併）；`git diff --check`。

## Out of Scope

- 前端顯示（第三份計畫）。
- 新增非 `cmn` 的譯名、其它 locale 翻譯、canonical 名稱的 homograph 拆分（`.N` 後綴）。
- migration 或 schema 變更（欄位已在後端計畫 0019）。
- 修改 `system-ui.sql`／i18n bundle 流程。
