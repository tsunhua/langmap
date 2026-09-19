# scripts inventory

本次 PostgreSQL／canonical CSV 重構的取捨如下。表中的「保留」代表仍是現行可重跑入口；「移除」代表已由新入口取代，或只服務已停用的 D1／SQLite／JSONL 流程。

| 路徑 | 責任 | 決定 | 替代／備註 |
| --- | --- | --- | --- |
| `scripts/postgres/` | PostgreSQL baseline、migration | 保留 | `DATABASE_URL`，不依賴 `psql`／Homebrew |
| `backend/schema.sql`、`backend/migrations/` | 舊 SQLite/D1 schema 與 migrations | 已移除 | 以 `backend/postgres/schema.sql`、`backend/postgres/migrations/` 與 `scripts/postgres/` 取代 |
| `scripts/dictionary/import_mapping_csv_pg.py` | canonical CSV → PostgreSQL | 保留 | `--check`／`--apply`，來源 snapshot scoped |
| `scripts/language-reference/` | language／script／region registry seed | 保留 | 產物供 PG baseline／seed 使用 |
| `scripts/morphology/` | morphology registry seed | 保留 | 產物供 PG seed 使用 |
| `scripts/i18n/` | UI locale 寬表 CSV 與 manifest | 保留 | `ui-locales.csv` 同時供 Web 與 PG importer；manifest 僅保存 metadata |
| `scripts/wikivoyage/` | 舊 SQLite/D1 Wikivoyage pipeline | 已移除 | parser／catalog 已搬到 dictionary `src/dictionary_export/wikivoyage/`；PG handbook builder 位於 `scripts/postgres/` |
| `scripts/db/` | D1 manager、SQLite mirror、delta、v1 migration | 已移除 | 目前只保留被 `.gitignore` 隔離的舊本機 state，不再有可執行入口 |
| `scripts/dictionary/langmap_dictionary/` | JSONL／SQLite staging、reconciliation、D1 publisher | 已移除 | dictionary repo source adapter + LangMap PG importer 取代 |
| `scripts/dictionary/*jsonl*`、`*incremental*`、`*release*`、`*repair*` | 舊 JSONL／D1 bridge | 已移除 | 現行入口只有 canonical CSV → PostgreSQL |
| `scripts/v2/` | 舊 v2 SQLite／SQL dump | 未追蹤產物，未納入新入口 | 不再由任何現行流程引用；不主動刪除使用者未追蹤資料 |
| `scripts/init-db.sql` | 舊 Wrangler D1 bootstrap | 已移除 | `backend/postgres/schema.sql` + `scripts/postgres/manage.py init` |

歷史 runbook／spec 可以保留作為不可執行的紀錄；現行 README、dev script 與 runbook 不再指向已移除入口。
