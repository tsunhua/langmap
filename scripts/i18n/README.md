# UI 翻譯 bundle

受管理的 system UI 翻譯由版本控制的 source 生成單一 bundle。source catalog 是
`web/src/locales/en.ts`（bundle code：`eng-Latn-US`），first-party locale JSON 目前包含：

- `cmn-Hans-CN.json`（bundle code：`cmn-Hans-CN`）
- `cmn-Hant-TW.json`（bundle code：`cmn-Hant-TW`）
- `spa-Latn-ES.json`（bundle code：`spa-Latn-ES`）
- `jpn-Jpan-JP.json`（bundle code：`jpn-Jpan-JP`）

翻譯鍵需對應 `web/src/locales/en.ts` 的巢狀路徑。

## 生成 bundle

產物固定寫到 `scripts/i18n/artifacts/system-ui/`：

- `system-ui.sql`
- `manifest.json`

```bash
python3 scripts/i18n/generate-bundle.py
```

如需指定測試輸入或輸出目錄：

```bash
python3 scripts/i18n/generate-bundle.py \
  --source-catalog /tmp/en.ts \
  --locale cmn-Hant-TW=/tmp/cmn-Hant-TW.json \
  --locale cmn-Hans-CN=/tmp/cmn-Hans-CN.json \
  --locale spa-Latn-ES=/tmp/spa-Latn-ES.json \
  --locale jpn-Jpan-JP=/tmp/jpn-Jpan-JP.json \
  --output-dir /tmp/system-ui-bundle
```

manifest 會記錄 schema version、project/scope、source checksums、locale/message/
translation counts，以及輸出 SQL 的 SHA-256。生成失敗時不會替換既有 artifact。

## Local compatibility wrapper

本地匯入改為先重建 bundle，再一次載入單一 SQL：

```bash
scripts/i18n/import-all.sh --local
```

`--remote` 已停用。production 寫入改由 production data manager 接手；此 wrapper
不再直接對 remote D1 執行匯入。

production 只可先執行 `./scripts/db/manage.sh production inventory|plan`，經人工審核
後再依 [production data release runbook](../../docs/runbooks/production-data-release.md)
執行受保護的 apply。

## 單語系 SQL

若只需檢查單一 locale 的 SQL，既有 generator 仍可用：

```json
{
  "nav.home": "首頁",
  "common.search": "搜尋"
}
```

```bash
python3 scripts/i18n/generate-i18n-sql.py \
  cmn-Hant-TW scripts/i18n/cmn-Hant-TW.json \
  > /tmp/langmap-cmn-Hant-TW-import.sql
```

此 generator 會保留既有 deterministic `expression_id` / `stable_edge_id` 與
SQL insert semantics，但未知 source key 會直接 fail，不再 warning/skip。
