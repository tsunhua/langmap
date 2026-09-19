# PostgreSQL data release runbook

D1、SQLite mirror 與舊 delta manager 已退役。本文件只描述目前的 CSV→PostgreSQL
發布入口；舊操作紀錄保留在 Git history，不可照舊命令執行。

## 詞典或 UI locale

1. 在 dictionary repo 從 `raw/<source-key>/` 產生 canonical CSV；Wikivoyage 每個英語到
   目標 locale 的方向各自產生一張寬表 CSV。
2. 在隔離 PostgreSQL 先檢查 manifest 與 checksum：

   ```bash
   python3 scripts/dictionary/import_mapping_csv_pg.py \
     --manifest /path/to/dictionary/csv/<source-key>/manifest.json --check
   ```

3. 由審核者確認 headword、direction、equivalents、readings、例句 pairing 及來源授權後，
   在目標 `DATABASE_URL` 執行同一 manifest 的 `--apply`。importer 會在單一 transaction
   內按 source snapshot 同步 claims，保留其他 source 的 expressions、edges 與 markers。
4. 套用後按 source key 查核 expressions、edges、readings、locale links 與統計；失敗時回到
   CSV adapter 修正並以新 checksum 重跑，不手改資料庫。

## Schema 與 registry

```bash
python3 scripts/postgres/manage.py init
python3 scripts/postgres/manage.py migrate
```

registry 產物由 `scripts/language-reference/`、`scripts/morphology/` 產生，UI locale
使用 `scripts/i18n/ui-locales.csv` 加 manifest；不再產生 SQL／JSONL 詞句 artifact。

## 安全界線

- `DATABASE_URL` 必須明確指向隔離或已核准的 PostgreSQL；不把 secret 提交或寫入 log。
- 不使用 `wrangler d1`、SQLite mirror、舊 `scripts/db/` 命令或未審核的 source archive。
- `manifest.json` 可作為發布 metadata；詞句內容只接受 canonical CSV。
