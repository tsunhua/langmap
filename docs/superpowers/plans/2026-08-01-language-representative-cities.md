# 語言代表性城市實作計畫

> 狀態：核心功能已實作；線上 code audit/migration 待取得 observed codes 後執行。
>
> 對應規格：`docs/superpowers/specs/2026-08-01-language-representative-cities-design.md`

## 1. 交付目標

以一張 `language_locations` 表和一份生成的 `language-locations.csv`，為語言
變體提供可追溯的代表性城市。城市只用於地圖標點與探索，不進入 BCP 47 code，
也不聲稱代表完整語言分布。

本計畫同時審核目前 seed code 中僅為表達使用地而加入的 region。code 收斂是
獨立、高風險步驟；必須先盤點引用、建立逐筆映射並驗證 many-to-one migration，
不得與 location 表的基礎建設混在同一個 commit。

## 2. 施工原則與前置狀態

- 保留目前工作樹中尚未提交的 `language_seed_profiles.json` 與生成 artifacts
  變更；它們是本功能的資料工作基線，不得覆蓋或丟棄。
- `languages.code` 仍是 canonical BCP 47 content tag。
- `variety_key` 是 location 關聯鍵；本階段不新增 `language_varieties`。
- `territory_code` 是 ISO 3166-1 territory code，不稱為 country code，也不表示
  主權或語言歸屬。
- 先測試後實作；每項 task 完成後保持測試綠燈再 commit。
- code migration 前先查線上 observed codes；未完成盤點不得套用遠端 migration。
- 不修改 `apple/`、不建立 GeoJSON、不增加社群編輯 UI。

## 3. 依賴順序

```text
Task 1 schema
  → Task 2 generator contract
    → Task 3 representative-city seed data
      → Task 4 code audit and migration
        → Task 5 API
          → Task 6 web UI
            → Task 7 full verification and docs
```

## 4. Tasks

### Task 1：新增最小 `language_locations` schema

**Files**

- Modify: `backend/schema.sql`
- Create: `backend/migrations/0011_add_language_locations.sql`
- Modify: `scripts/v2/test_language_data.py`

**Steps**

1. 在 `test_language_data.py` 新增 schema assertion，確認：
   - `language_locations` 存在；
   - 欄位與 composite primary key 符合 spec；
   - 只有 `variety_key` 與 city index，不出現 `places`、geometry 或 polygon 表。
2. 執行測試並確認新 assertion 先失敗：

   ```bash
   python3 scripts/v2/test_language_data.py
   ```

3. 在 `backend/schema.sql` 新增：
   - `language_locations`；
   - `idx_language_locations_variety`；
   - `idx_language_locations_city`。
4. 新增 idempotent migration `0011_add_language_locations.sql`，只建立新表與 index，
   不改動或刪除現有 language／expression 資料。
5. 以暫存 SQLite 同時驗證完整 schema 與 migration 可重跑：

   ```bash
   tmp_db=$(mktemp /tmp/langmap-locations-schema.XXXXXX.db)
   sqlite3 "$tmp_db" < backend/schema.sql
   sqlite3 "$tmp_db" < backend/migrations/0011_add_language_locations.sql
   sqlite3 "$tmp_db" < backend/migrations/0011_add_language_locations.sql
   sqlite3 "$tmp_db" ".schema language_locations"
   ```

6. 重跑 Python 測試與 whitespace 檢查。

**Commit**

```text
feat: add representative language city schema
```

### Task 2：擴充 pinned registry generator

**Files**

- Modify: `scripts/v2/sync_language_registry.py`
- Modify: `scripts/v2/test_language_data.py`
- Modify: `scripts/v2/README.md`

**Steps**

1. 先新增 generator tests，涵蓋：
   - 合法 location row 正規化與穩定排序；
   - 未知 `variety_key`；
   - 未登記 territory／script；
   - 空 city／reference；
   - 越界經緯度；
   - composite key 重複；
   - 無 `locations` 時生成空 CSV，不影響既有 profiles。
2. 先執行指定測試並確認失敗。
3. 在 `sync_language_registry.py` 增加小型、純函式邊界：
   - `seed_location_rows(...)`：驗證並產生 rows；
   - `write_locations(...)`：寫入固定欄位 CSV；
   - `render_location_insert(...)`：產生 idempotent SQL；
   - `render_registry_sql(...)` 接受 locations 並在 language rows 後寫入 location rows。
4. profile schema version 提升為 `3`，讀取頂層 `locations`；缺少時視為空陣列，
   讓 fixture 與舊 profile 可漸進更新。
5. 生成器使用 IANA snapshot 驗證 `territory_code` 與非空 `script_code`；使用
   已生成的 language rows 驗證 `variety_key`。
6. 寫入 `language-locations.csv` 時使用 temporary file；location 生成失敗時不得
   留下半成品或更新 manifest／SQL。
7. 在 manifest 的 `generation` 加入 `language_location_count`。
8. 更新 README 的 artifacts、offline regenerate 與欄位說明。
9. 驗證：

   ```bash
   python3 scripts/v2/test_language_data.py
   python3 scripts/v2/sync_language_registry.py \
     --output scripts/v2/artifacts/language-registry-5.3 \
     --offline
   git diff --check
   ```

**Commit**

```text
feat: generate representative language cities
```

### Task 3：策展代表性城市 seed data

**Files**

- Modify: `scripts/v2/language_seed_profiles.json`
- Generate: `scripts/v2/artifacts/language-registry-5.3/language-locations.csv`
- Generate: `scripts/v2/artifacts/language-registry-5.3/language-registry.sql`
- Generate: `scripts/v2/artifacts/language-registry-5.3/manifest.json`
- Modify: `scripts/v2/test_language_data.py`

**Steps**

1. 在 profiles 加入頂層 `locations`，每個非 system 的主要 seed variety 原則上
   至少一筆；舊有特殊方言若無可靠城市可留空。
2. 每筆資料按以下規則人工 review：
   - 全國廣泛使用：預設首都；
   - 區域性語言：核心城市；
   - 跨境且具有多個重要中心：每個重要中心一筆；
   - city name 使用當地常用名稱，`city_name_en` 提供英文 fallback；
   - script 只在該 city 與書寫 profile 有明確關係時填寫。
3. 使用 authoritative／可追溯來源核對城市選擇與座標。來源只支持語言 identity
   而不支持城市選擇時，不得作為唯一 `reference`。
4. 至少加入下列回歸案例：
   - Yue：廣州／香港／澳門；
   - Korean：首爾／平壤／延吉；
   - Mongolian：烏蘭巴托／呼和浩特；
   - Hakka、Min Nan：各自跨 territory 的代表城市；
   - 無 location 的 system profile 回傳空集合。
5. 新增 artifact-level tests：
   - CSV row count 與 manifest 一致；
   - 全域排序穩定；
   - CSV 中所有 `variety_key` 都可由 `languages.csv` 找到；
   - Arabic／Mongolian／Han script rows 不互相誤配。
6. offline regenerate 兩次，以 checksum 或 clean second diff 確認 deterministic。
7. 用暫存 SQLite 載入 `backend/schema.sql` 與完整 registry SQL，查詢代表城市：

   ```bash
   tmp_db=$(mktemp /tmp/langmap-locations-data.XXXXXX.db)
   sqlite3 "$tmp_db" < backend/schema.sql
   sqlite3 "$tmp_db" < scripts/v2/artifacts/language-registry-5.3/language-registry.sql
   sqlite3 "$tmp_db" \
     "SELECT variety_key, city_name, territory_code, script_code FROM language_locations ORDER BY 1,2;"
   ```

**Commit**

```text
data: seed representative language cities
```

### Task 4：審核並遷移不必要的 region code

**Files**

- Modify: `scripts/v2/language_seed_profiles.json`
- Modify: `scripts/v2/language_migration.py`
- Modify: `scripts/v2/test_language_data.py`
- Modify/Generate: `scripts/v2/artifacts/language-registry-5.3/online-code-migrations.json`
- Generate: `scripts/v2/artifacts/language-registry-5.3/languages.csv`
- Generate: `scripts/v2/artifacts/language-registry-5.3/language-registry.sql`
- Generate: `scripts/v2/artifacts/language-registry-5.3/manifest.json`
- Create: `backend/migrations/0012_canonicalize_language_content_profiles.sql`
- Modify: related backend migration tests or SQLite integration fixture

**Precondition**

先取得並保存以下 distinct code 清單：

- `languages.code`
- `expressions.language_code`
- `language_stats.language_code`
- `ui_locales.code`

若無法存取線上資料，僅完成 migration matrix 與本地測試，不執行遠端 migration。

**Steps**

1. 建立逐筆 migration matrix，將每個帶 region 的 seed 分為：
   - `keep`：region 代表真實 content／UI locale 慣例；
   - `collapse`：region 只代表使用地，改由 location row 表達；
   - `manual-review`：證據不足，不自動變更。
2. 明確保留第一方 UI locale 與確有內容差異的 profile。不得因本功能機械移除
   `en-US`、`zh-Hant-TW` 等 region。
3. 對可收斂案例建立顯式映射，例如候選：

   ```text
   yue-Hans-CN  → yue-Hans
   yue-Hant-HK  → yue-Hant
   yue-Hant-MO  → yue-Hant
   mn-Cyrl-MN   → mn-Cyrl
   mn-Mong-CN   → mn-Mong
   ```

   這些只代表待審核候選，不得在沒有內容慣例與線上引用證據時直接套用。
4. 調整 migration validator，允許明確且安全的 many-to-one canonical target；
   同時拒絕循環、target 不存在、未覆蓋 observed code 與 `manual-review` 自動套用。
5. 讓 generator 從已 review 的 profile migration 設定生成
   `online-code-migrations.json`，不再每次固定覆寫為空 object。
6. `0012` migration 必須依順序：
   - preflight 驗證所有 target language rows 已存在；
   - 更新 `expressions.language_code`；
   - 以 group／upsert 合併 `language_stats`，避免 unique collision；
   - 僅對 review 明確批准的 `ui_locales` 做更新，否則保留其 language profile；
   - 確認無 child references 後才刪除 obsolete language rows；
   - migration 結尾執行 orphan-count assertions 可查詢的等價檢查。
7. 測試至少覆蓋：
   - 兩個舊 code 合併到同一 target；
   - expression 全數保留；
   - stats 正確加總；
   - UI locale 未被誤合併；
   - migration 重跑不改變結果；
   - rollback 前後 row counts 有明確紀錄。
8. regenerate artifacts，驗證 `languages.csv` 不再用 region 表示純地理位置，
   location CSV 仍包含相關城市。

**Commit**

```text
refactor: separate language codes from representative cities
```

### Task 5：在語言詳情 API 回傳代表性城市

**Files**

- Modify: `backend/src/types/language.ts`
- Modify: `backend/src/routes/languages.ts`
- Modify: `backend/tests/languages.integration.test.ts`
- Optionally create: `backend/tests/languageLocations.test.ts` if pure query extraction is useful

**Steps**

1. 先新增 API integration tests：
   - 有 location 的 language detail 回傳 `representative_cities`；
   - script-specific profile 只回傳相同 script 與空 script rows；
   - 無 location 回傳 `[]`；
   - 排序固定為 territory、city、script；
   - 不將 city 寫回 `region_code`。
2. 新增 `RepresentativeCity` type：

   ```ts
   interface RepresentativeCity {
     name: string
     name_en: string | null
     territory_code: string
     script_code: string | null
     latitude: number
     longitude: number
     reference: string
   }
   ```
3. 在 `GET /api/v2/languages/:code` 取得 language 後，以 `variety_key` 查
   `language_locations`：
   - 當前 language 有 script 時，接受相同 script 或空 script；
   - 當前 language 無 script 時，回傳該 variety 全部城市；
   - 使用參數 binding，不拼接輸入值。
4. 保持既有回應 envelope，在 `data` 加入 `representative_cities`，不改動 list
   endpoint，避免每列 language 產生額外 join 與 payload。
5. 啟動本地 Worker 後執行相關 integration tests：

   ```bash
   cd backend
   npm test -- languages.integration.test.ts
   ```

**Commit**

```text
feat: expose representative language cities
```

### Task 6：在語言詳情頁呈現城市點與文字替代

**Files**

- Modify: `web/src/api/languages.ts`
- Modify: `web/src/composables/useLanguages.ts`
- Create: `web/src/components/language/RepresentativeCityMap.vue`
- Create: `web/src/components/language/RepresentativeCityMap.test.ts`
- Modify: `web/src/pages/LanguageDetail.vue`
- Create or modify: `web/src/pages/LanguageDetail.test.ts`
- Modify: `web/src/locales/en.ts`
- Modify: all locale files required by the existing i18n parity check

**Steps**

1. 先新增 component／page tests，涵蓋：
   - 標題固定使用「代表性城市」語意；
   - 每個 marker 都有相同內容的文字列表替代；
   - 城市名稱、territory code 與 script 可讀；
   - 空陣列不渲染 map；
   - API 錯誤仍沿用頁面現有錯誤處理。
2. 在 web API types 加入 `RepresentativeCity` 與明確的 language detail response，
   移除本次接觸範圍內的 `any`，不順手重構其他頁面。
3. `useLanguages.detail` 正規化既有 `{ language, mapped_expression_count,
   representative_cities }` envelope，讓 `LanguageDetail.vue` 接收單一 typed view model。
4. 建立 `RepresentativeCityMap.vue`：
   - 沿用現有 Leaflet dependency；
   - 只建立 markers，不畫 polygon 或 coverage circle；
   - 一個 marker 使用合理固定 zoom，多個 marker 使用 `fitBounds`；
   - popup 不注入未 escape HTML；優先用 DOM／Leaflet API 設定文字；
   - unmount 時清理 map；
   - 提供可鍵盤操作的文字列表作為完整替代。
5. 在 `LanguageDetail.vue` stats 與 expression toolbar 之間加入城市區塊；沿用
   `atlas.css` tokens、低圓角、可見 focus，行動版地圖高度獨立設定。
6. 補齊 i18n key，至少包含：代表性城市、無城市、script label 與地圖輔助文字。
7. 驗證：

   ```bash
   cd web
   npm test -- RepresentativeCityMap.test.ts LanguageDetail.test.ts
   npm run i18n:check
   npm run build
   ```

8. 人工檢查 desktop 與 mobile viewport；確認 UI 沒有「完整分布」、「主要領土」
   等誤導文字，且地圖之外有可讀列表。

**Commit**

```text
feat: show representative cities for languages
```

### Task 7：全流程驗證與文件收尾

**Files**

- Modify: `scripts/v2/README.md`
- Modify: `docs/superpowers/specs/2026-08-01-language-representative-cities-design.md`
- Modify: this plan status only after implementation completes

**Steps**

1. 更新 README，提供：
   - location seed 欄位與範例；
   - offline regenerate 指令；
   - SQL 載入順序；
   - 代表性城市限制；
   - code migration preflight／回退入口。
2. 將 spec 狀態改為「已實作」，只在所有驗收完成後執行。
3. 執行完整驗證：

   ```bash
   python3 scripts/v2/test_language_data.py
   python3 scripts/v2/sync_language_registry.py \
     --output scripts/v2/artifacts/language-registry-5.3 \
     --offline
   cd backend && npm test
   cd ../web && npm test
   npm run i18n:check
   npm run build
   cd .. && ./build.sh
   git diff --check
   ```

4. 再次 offline regenerate，確認沒有第二次 diff。
5. 用乾淨暫存 SQLite 依正式順序載入 schema、registry SQL、相關 migrations；
   驗證：
   - 無 orphan language references；
   - location count 與 manifest／CSV 一致；
   - many-to-one migration 保留 expression 數；
   - registry SQL 重跑結果一致。
6. 記錄無法執行的遠端驗證與剩餘風險；沒有授權時不操作 remote D1。

**Commit**

```text
docs: document representative language cities
```

## 5. 驗收清單

- [ ] `language_locations` 是唯一新增的地理資料表。
- [ ] `language-locations.csv` 可由 pinned raw artifacts 離線重現。
- [ ] 每個 location 有合法 variety、territory、script、座標與 reference。
- [ ] 城市不出現在 BCP 47 private-use 或其他 code 位置。
- [ ] 只有真實 content／UI locale 差異保留 region。
- [ ] code migration 有逐筆 matrix、preflight、many-to-one 測試與回退說明。
- [ ] API 回傳 script 適用且穩定排序的代表性城市。
- [ ] 前端只畫 marker，並提供可存取的文字列表。
- [ ] 沒有 location 的語言仍正常工作。
- [ ] Python、backend、web、build 與 `git diff --check` 全部通過。

## 6. 風險與控制

- **城市代表性帶有主觀性**：每筆要求 reference，證據不足即留空。
- **region code 收斂造成引用衝突**：與 location 基礎建設分 commit，先盤點再
  many-to-one migration，不處理 `manual-review`。
- **UI locale 與 content tag 共用 registry**：UI locale 逐筆 review，不能隨
  expression code 一起合併。
- **`variety_key` 無 foreign key**：生成時強驗證；社群寫入不在本期範圍。
- **地圖造成語言邊界誤解**：只畫點、不畫範圍，並固定使用「代表性城市」。
- **來源或城市名稱日後變更**：本期以版本控制 review 更新，不建立歷史表。

## 7. 回退順序

1. 前端停止呈現城市區塊。
2. API 停止查詢與回傳 `representative_cities`。
3. 停止載入 location rows；保留空表不影響既有功能。
4. 如需移除表，另建 forward-only migration，不修改已套用的 `0011`。
5. code migration 依 `0012` 隨附的逐筆反向映射與部署前備份處理；不得僅靠
   刪除 location 表回復舊 code。
