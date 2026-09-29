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

## V1 應用資料遷移（換新庫）

舊庫在匯入全程只讀，新庫於隔離連接完成後由營運自行切換 `DATABASE_URL`。順序如下：

1. baseline、seed 與 migrations：

   ```bash
   python3 scripts/postgres/manage.py init
   python3 scripts/postgres/manage.py migrate
   ```

2. 依 registry 順序匯入參考資料與 333 來源（language／reference seed、dictionary CSV）。
   Jiazi handbook 的陸豐甲子話詞彙不在現時 dictionary sources 中，由 V1 recovery source
   恢復，`--scope-locales` 需涵蓋其 nan profiles：

   ```bash
   python3 scripts/postgres/import_v1_system_graph.py \
     --legacy-database-url "$LEGACY_DB" --database-url "$NEW_DB" \
     --scope-locales "cmn-Hant-TW,eng-Latn-US,eng-Latn-GB,nan-Hant-CN_LufengJiazi,nan-Latn-CN_LufengJiazi,nan-Hant-TW,nan-Hant-CN" \
     --check   # 再以 --apply 寫入
   ```

3. 匯入 V1 應用表（users、user_preferences、handbooks、handbook_sections 與非 managed items）：

   ```bash
   python3 scripts/postgres/import_v1_app_tables.py \
     --legacy-database-url "$LEGACY_DB" --database-url "$NEW_DB" --check   # 再以 --apply 寫入
   ```

4. 重建 managed Wikivoyage handbook（reuse 既有 handbook id、刪除並重建其 sections）：

   ```bash
   python3 scripts/postgres/build_wikivoyage_handbook.py \
     --database-url "$NEW_DB" \
     --section-catalog "$DICTIONARY/src/dictionary_export/wikivoyage/data/section-catalog.json"
   ```

5. 最後重算衍生統計：

   ```bash
   python3 scripts/postgres/recompute_language_statistics.py --database-url "$NEW_DB"
   ```

驗收查核（FK orphan 與重複應為 0；計數與 legacy 對帳）：
- handbook 表、expression、edge、locale link、reading 的 FK orphans；
- `(section_id, language_locale_id, text)` 無重複；
- 非 managed items 可解析率（例如 Jiazi 1,691/1,691）；Jiazi（LufengJiazi）locale link 數與 legacy 一致；
- users、handbooks、sections、items 計數；users 等序列已前進調整。

managed handbook 由目前 dictionary catalog 重建，section／item 數與 legacy 不同是預期行為。
`build_wikivoyage_handbook.py` 的 marker regex 支援 `oldid:<revision>#<section>/<row>`
與含變體鍵的 `.../<row>/<variant-key>` 兩種 ENTRY_ID。

## 生產切換與部署

新 code 必須同時部署：`handbook_section_items` 已改為 `(language_locale_id, text)`，舊 Worker
SQL 查新表會直接失敗，因此「只換資料庫名稱」不足以完成切換。wrangler 認證請用有效
`CLOUDFLARE_API_TOKEN`；切換前先備份兩庫。兩種可行方式：

- **A（推薦，可回退）**：用 `wrangler hyperdrive create langmap-fresh-pg --service-id
  <tunnel-service-id> --database langmap_fresh --user langmap_app --scheme postgresql`
  建立新 config，把 `backend/wrangler.jsonc` 的 `hyperdrive[0].id` 換成新 id，`./build.sh`
  後 `npx wrangler deploy`；驗證通過後再 `wrangler hyperdrive delete` 舊 config。
- **B（DB 改名）**：先 deploy 新 code，再終止兩庫連線並依序改名
  `langmap → langmap_legacy_prod`、`langmap_fresh → langmap`；本地 `backend/.dev.vars`
  的 `DATABASE_URL` 同步改回 `langmap`。改名後 Hyperdrive schema cache 可能短暫傳回舊列
  資訊，最多約 1 分鐘內 5xx 屬預期。

驗證：`curl https://langmap.io/api/v2/handbooks` 英文 phrasebook 應為 14 sections／約 6.7k
items（非舊的 12／1,829）；`/handbooks/<id>` 的 Jiazi 手冊與 sections 可取；DB 對帳
expressions、handbook_section_items 計數。

## 安全界線

- `DATABASE_URL` 必須明確指向隔離或已核准的 PostgreSQL；不把 secret 提交或寫入 log。
- 不使用 `wrangler d1`、SQLite mirror、舊 `scripts/db/` 命令或未審核的 source archive。
- `manifest.json` 可作為發布 metadata；詞句內容只接受 canonical CSV。
