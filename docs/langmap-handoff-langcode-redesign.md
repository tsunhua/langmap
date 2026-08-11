# Handoff: LangMap 語言代碼模型重新設計

> 對話壓縮文件，供下個 agent 接手。

## 任務背景

`/home/ubuntu/floating-cloud/code/langmap/` 專案要**推翻 ADR 0003**，重新設計語言識別與 expression 資料模型。本對話以 `grill-with-docs` 進行結構化訪談，已收斂核心設計，尚有若干分支待決。

## 已達成共識的設計決策

採訪者與使用者已對以下 6 點達成共識：

1. **推翻 ADR 0003**——拋棄 Glottolog + BCP 47 content tag 的雙軌模型。這是 greenfield 重來，影響 `languoids` / `language_varieties` / `language_profiles` / `language_locations` 四張表與至少 9 個 route 檔。

2. **動機組合**——
   - Expression ID 設計不對（同詞在 `nan-Hant`/`nan-Hans` 被拆成兩個 expression，造成 mapping 斷裂）
   - 次級地點表達不出來（陸豐甲子這類鎮級地點，BCP 47 region 只到 `CN`）
   - 潮州話與閩南話被割裂——目前它們是不同 Glottocode，無法並排顯示共同/差異詞

3. **Lang code 嚴格遵循 ISO 639-3 個體 code**（`nan`、`cmn`、`yue`、`jpn`...），不引入 macrolanguage 覆寫。**關鍵事實**：ISO 639-3 沒有潮州話獨立 code（`teo` 是 Teso 不是 Teochew），所以潮州話只能用 `nan`，靠次級地點區分。

4. **Locale code 結構**：`{lang}-{script}-{place}`，例如 `nan-Hant-CN_Quanzhou_Nanan`。Locale code 承擔兩個用途：
   - 標記 Pronunciation Variant 出現的地域
   - 攜帶該地域形式的當地自稱（endonym）

5. **語言稱呼只有兩種視角**：
   - 每個 lang_code 一個 English name（exonym）
   - 每個 locale_code 一個當地自稱（endonym）
   - **不是** i18n 多視角在地化

6. **Pronunciation Variant 為第一類實體**，schema 概念：
   ```
   pronunciation_variants(expression_id, locale_code NULLable, system, value, source_type, source_ref, created_by)
   ```
   - **多系統並存**（IPA / POJ / Tâi-lô / Jyutping / Pinyin...），不選邊站
   - locale 可選：NULL = 整個 lang 通用；非 NULL = 方言特定
   - 一個 (expression, locale, system) 可有多筆，各帶 source
   - 用 `pronunciation_systems` 小表當註冊表
   - 不在 DB 層驗證字串
   - 音檔不在本次範圍（YAGNI）

7. **同形歧義的處理：意義由 mapping 圖承載，無 sense_gloss 欄位**——
   - 預設：一個 (lang, text) = 一個 expression，ID 為 `{lang}:{text}`
   - 多義時拆分：追加 `{lang}:{text}.{n}`（n 從 2 起）；後綴是 opaque 標籤，不攜帶語義
   - 拆分是**事後維護操作**：當 expression 鄰域出現多個語義不相交聚類時才拆
   - 拆分時把相關 mappings 從原 expression 搬到新 expression
   - 接受未拆分同形詞會對「間接 mapping」（傳遞閉包）造成噪音的代價

## 尚未決定的問題（下個 agent 接手的重點）

依優先級：

### P1：Locale code 格式細節

`nan-Hant-CN_Quanzhou_Nanan` 的格式規範尚未釐清：

- 為何 `_` 串接 place，`-` 串接其他？（視覺層級？還是隨意？）
- place 層級深度：固定 國家_城市_次級？或可變（只到國家、只到城市...）？
- 是否對齊外部標準？ISO 3166-2？GeoNames？還是自訂 slug？
- 同名地點歧義（多個「泉州」）如何處理？
- 非 CN 地點（台灣、東南亞閩南語社群）如何命名？

### P2：多義偵測的產品層級

上次推薦 (a)「不做自動偵測，只提供手動拆分後台工具」，使用者**尚未確認**。三選項：

- (a) 不做（YAGNI，推薦）
- (b) 被動提示（查看 expression 時顯示「可能多義」）
- (c) 主動建議（背景掃描 + 審查佇列）

### P3：貢獻流程與 locale_code 的關係

尚未討論：

- 貢獻新 expression 時，是否強制選 locale_code？推薦：**可選**
- 若無 pronunciation 又無 locale_code，如何標記「出處 locale」？
- locale_code 標記是否要窮盡？（上次澄清：**不窮盡，單調追加**——attestation 語義，非 coverage claim）

### P4：從 ADR 0003 schema 遷移

尚未討論：

- 25 個 migration 的資料如何遷到新模型？
- 是否需要一次性 migration manifest（ADR 0003 提過類似機制）？
- Runtime 是否保留 alias？
- 既有 expression IDs（基於 (text, language_profile_code)）如何過渡到新 ID（基於 (lang, text)）？
- 同 (lang, text) 會合併多個舊 expression，其 mappings 如何去重？

### P5：Locale code 與既有 `ui_locales` 表的關係

`backend/migrations/0006_project_scoped_localization.sql` 與 `0007_seed_first_party_ui_locales.sql` 已建立 `ui_locales` 機制。新設計的 locale code 與之是否同名概念？是否會混淆？需要命名區隔（例如 `dialect_code` vs `ui_locale`）？

### P6：Script code 標準

`Hant` / `Hans` / `Latn` / `Latn-tailo` 是否就用 ISO 15924？多個羅馬字方案（POJ、TL、Bàn-lâm-gú）在 script 層級還是 system 層級區分？傾向：script 用 ISO 15924，羅馬字方案歸 `pronunciation_systems` 註冊表。

## 下個 agent 的工作

1. **繼續 grill**：依上述 P1~P6 順序提問，每題給推薦答案，逐題收斂。
2. **更新 CONTEXT.md**：每個術語共識形成後立即寫入 `/home/ubuntu/floating-cloud/code/langmap/CONTEXT.md`（目前該檔仍是 ADR 0003 時代的詞彙表，需要重寫）。
3. **撰寫新 ADR**：設計完整收斂後，新 ADR `0004-language-codes-redesigned-around-iso639-3.md` 取代 0003。符合三條件：難以逆轉、未來讀者會困惑、有真實 trade-off。
4. **不撰寫 spec / migration plan**：等 ADR 通過後再寫（遵循 AGENTS.md「大型改造先更新 specs/；施工拆解放 plans/」）。

## 不應重複的內容（用路徑參考）

- 現有領域詞彙表：`/home/ubuntu/floating-cloud/code/langmap/CONTEXT.md`
- 現有 ADR（即將被取代）：`/home/ubuntu/floating-cloud/code/langmap/docs/adr/0003-language-identity-uses-glottolog-and-bcp47-content-tags.md`
- 專案規範：`/home/ubuntu/floating-cloud/code/langmap/AGENTS.md`
- 完整 schema：`/home/ubuntu/floating-cloud/code/langmap/backend/schema.sql`
- Migration 歷史：`/home/ubuntu/floating-cloud/code/langmap/backend/migrations/0005_add_languoid_registry.sql` 至 `0025_canonicalize_all_script_profiles.sql`

## Suggested skills

下個 agent 必須或強烈建議載入的 skills：

- **`grill-with-docs`**（延續當前對話模式）——逐題訪談、每題推薦答案、衝擊既有詞彙時即時更新 CONTEXT.md、嚴格按 ADR 三條件判斷是否立 ADR。
- **`using-superpowers`**——會話開始時的 skills 入口，按優先級判斷後續 skill 載入。
- **`writing-plans`**——P4（migration 策略）討論完成後，撰寫拆解施工計畫用。
- **`brainstorming`**——若使用者偏離當前設計、想引入新功能時觸發。
- **`knowledge-distiller`**——設計定案後，把「為何推翻 ADR 0003」的決策理由沈澱為 wiki 筆記。
- **`verify-before-completion`**——撰寫 ADR / CONTEXT.md 改動後，diff 檢查與連結驗證用。

## 重要陷阱（給下個 agent 的提醒）

1. **不要重複 ADR 0003 的內容**——讀 `docs/adr/0003-...md` 即可，引用決策時用條號。
2. **ISO 639-3 `teo` 是 Teso（烏干達／肯亞尼羅語），不是 Teochew**——這是本對話採訪者犯過的錯，別再犯。潮州話在 ISO 639-3 沒有獨立 code，只能用 `nan`。
3. **使用者偏好簡潔、自動成長、語義由圖承載的設計**——避免 upfront 欄位（如 sense_gloss）、避免一次性窮盡（如 locale_code 全列表）；偏好 attestation 語義、按需擴充。
4. **回覆用中文，傳承體**——見 AGENTS.md。
5. **CONTEXT.md 只是詞彙表**——不要塞實作細節、規格或筆記，遵循 `grill-with-docs` 的 CONTEXT-FORMAT.md。
