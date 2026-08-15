# Plan: Localized Language Names — Frontend

- **Date**: 2026-08-15
- **Status**: Draft
- **Spec**: `docs/superpowers/specs/2026-08-15-localized-language-names-design.md`
- **Plan family**: 此為三份計畫的第三份。依序執行第一份（後端）→ 第二份（seed）→ 本計畫；本計畫的型別與欄位契約以後端計畫落地為前提。

## Goal

前端完成「語言／locale 名稱本地化」的消費與切換：

1. API 層（`web/src/api/*`、composable）全站傳送 `ui_locale`（primary）與 `secondary_ui_locale`（secondary），來源為 `useLocalizationStore`。
2. 頁面與元件改用解析後名稱：語言列表／詳情、feed、mapping 圖譜、handbook、search、MapLens、語言選擇 picker、expression 證據清單。
3. 顯示層級依 spec §6.3：一般 UI 以解析後名稱為主、code 為次；語系切換器維持以 `language_locales.name` 自稱當主標籤；expression 證據清單顯示 `locale_display_name` 並保留完整 code。
4. locale 切換時既有頁面以 request token 重發並防舊回應覆蓋（spec §6.2）；不在前端另建名稱翻譯表。

前端不負責名稱解析：resolver、`name`／`display_name`／`language_name`／`locale_display_name` 欄位均由後端計畫提供。種子資料落地前回退鏈（name_en／自稱／code）由後端保證，前端僅需在欄位缺失時回退顯示 code。

## Architecture

```
  useLocalizationStore (primary / secondary)  ← 單一來源
         │  localeParams()                     ← 新增 helper（computed）
         ▼
  pages (LanguageList / LanguageDetail / HomeFeed / MappingDetail /
         HandbookView / Search / MapLens)
         │  watch(primary, secondary) → reload
         ▼
  composables (useLanguages / useExpressions / useFeed / useHandbooks / useSearch)
         │  useLatestRequest token（既有）
         ▼
  api/*（client.ts）→ GET /api/v2/...?ui_locale=&secondary_ui_locale=
         ▼
  後端（第一份計畫）：name / display_name / language_name / locale_display_name
```

顯示命名約定（spec §6.3）：
- 一般名稱顯示（卡片、列表、圖譜節點、feed）：`resolved name` 為主，code 為次（`<title>`／次要字樣）。
- 語系切換器（`LangSwitcher.vue`）：維持現狀——`groupLocalesByVariety` 以 `locale.name` 自稱當主標籤，**不**改用解析名。
- expression 證據清單：`locale_display_name` 為主，`language_locale_code` 完整保留。

## Tech Stack

- Vue 3 `<script setup>` + TypeScript + Pinia + vue-i18n（現有堆疊，無新依賴）。
- 驗證沿用 `cd web && npm run build`；跨前後端 `./build.sh`。

## Risks and Uncertainties

| Risk | Impact | Mitigation |
|---|---|---|
| 後端尚未落地即改前端型別／呼叫 | build 過但執行期缺欄位 | 依計畫順序執行；本計畫 T1 型別用選填欄位（`display_name?`／`locale_display_name?`／`language_name?`）並回退 code，後端落地後不受影響 |
| locale 切換後舊回應覆蓋新回應 | 顯示與偏好不符 | 既有 `useLatestRequest`／手動 `loadRequest` token；新增 watch 統一重發 |
| 長譯名（如「閩南語（馬來西亞檳城）＋script 標籤」）撐破狹窄 badge | 版面破損 | 名稱顯示於可換行容器，code 放入 `<title>`；badge 保留至少 `min-width: 0` |
| 語系切換器誤改用解析名 | 違反 spec §6.3 | `LangSwitcher` 維持 `locale.name` 自稱；不加解析呼叫 |
| feed／graph 的 `language_name` 依賴後端 T6／T3 | 前端無資料 | 欄位選填，缺省回退 `lang_code`；後端落地即自動生效 |

## Task List

### T1: API 型別與 locale 參數層

成功標準：所有公開 API 呼叫都帶 `ui_locale`＋`secondary_ui_locale`；型別含新欄位（選填、向後相容）；build 通過。

1. `web/src/api/languageIdentity.ts`：
   - `ContentLanguagePageQuery` 加 `secondary_ui_locale?: string`（`ui_locale` 已有）。
   - `LanguageExpressionPageQuery` 加 `secondary_ui_locale?: string`。
   - `LanguageLocaleSummary` 加 `display_name?: string`（後端 T4/T5 提供）。
   - `listLanguageLocales` 與 `getLanguageDetail` 增加 `ui_locale`／`secondary_ui_locale` 參數（現 `getLanguageDetail(code, signal)` → `(code, params?, signal?)`）。
2. `web/src/api/expressions.ts`：
   - `getMappingGraph(id, hops, params?, signal?)` 接受 `{ ui_locale?, secondary_ui_locale? }`。
   - `LocaleAttestation`／`ExpressionReading` 加 `locale_display_name?: string`（後端 T6 提供，供證據清單）。
   - `searchExpressions`（於 `useSearch.ts`／`useExpressions.ts` 的 `api.get('/expressions/search', { params })`）加 `ui_locale`／`secondary_ui_locale`。
3. 新增 `web/src/composables/useLocaleParams.ts`：

```ts
import { computed } from 'vue'
import { useLocalizationStore } from '@/stores/localization'

export function useLocaleParams() {
  const localization = useLocalizationStore()
  return computed(() => ({
    ui_locale: localization.locale,
    secondary_ui_locale: localization.secondary,
  }))
}
```

4. `useLanguages.ts`、`useExpressions.ts`、`useFeed.ts`、`useHandbooks.ts`、`useSearch.ts`：透傳 locale params（呼叫端頁面提供；feed／handbooks 現為 composable 內直接 `api.get`，改由頁面把 params 傳入）。

執行：`cd web && npm run build`

### T2: 語言列表與詳情

成功標準：LanguageList／LanguageDetail 以解析後名稱顯示、隨 locale 切換重發、無 seed 時回退不破版。

- `web/src/pages/LanguageList.vue`：`list()` 補 `secondary_ui_locale`（`ui_locale` 已有，line 52）。`LanguageCard` 已收 `name`／`name_en` props（後端 T4 後 `name` 即解析後名稱），無需改顯示；若 `name` 缺省，卡片顯示端補 `name || name_en || code`。
- `web/src/pages/LanguageDetail.vue`：
  - `title`（line 39）：`selectedLocale?.display_name ?? lang.name`；`subtitle`（line 40）：`selectedLocale?.name ?? lang.name_en`（自稱次顯示）。
  - `loadDetail()` 與 `loadExpressions()` 傳 `useLocaleParams()`；`getLanguageDetail`、`listLanguageExpressions` 帶 locale params。
  - `watch(() => localization.locale)` 與 `watch(() => localization.secondary)` → 以 `detailRequest`／`expressionsRequest` 新 token 重發（既有 useLatestRequest 即防競態）。
  - 變體雙下拉（`variantSelect`／`otherSelect`）維持自稱 `locale.name`，不改（屬 self-name 選項情境）。
- `web/src/stores/languages.ts`：`getName()` 改 `name || name_en || code`（現 `name_en || code`）；`fetchLanguages` 帶 locale params。

執行：`cd web && npm run build`

### T3: Feed + Mapping 圖譜

成功標準：HomeFeed 卡片顯示語言名稱；MappingDetail 圖譜節點名稱隨 locale 切換；anchor badge 有解析名；證據清單顯示 display_name＋code。

- `web/src/pages/HomeFeed.vue`：`useFeed` hot／new 傳 locale params；回傳 item 的 `a_language_name`／`b_language_name`（後端 T6）傳給 `MappingCard`。
- `web/src/components/feed/MappingCard.vue`：props 加 `a_lang_name?: string`／`b_lang_name?: string`；`mc-lc` 顯示 `a_lang_name || a_lang`（`<title>` 保留完整 code；需 `min-width: 0`）。
- `web/src/pages/MappingDetail.vue`：
  - `mappingGraph(id, hops)` 傳 locale params（圖譜節點 `language_name` 由後端 T3 解析）。
  - anchor `LangBadge`（line 333）改傳解析名：由圖譜 root node 取 `language_name`（`graph.nodes.find(n => n.expression_id === id)?.language_name`），`LangBadge` 加選填 `name?` prop，顯示 `name || code`（`<title>` 保留 code）。
  - `ExpressionEvidenceList`（line 438/464）收到含 `locale_display_name` 的 attestations／readings（後端 T6）。
- `GraphNode.vue`／`GraphInspector.vue`：已有 `languageName`／`language_name` prop 顯示，後端解析後自動生效，無程式變更。
- `web/src/components/mapping/ExpressionEvidenceList.vue`：顯示 `attestation.locale_display_name || attestation.language_locale_code`，並保留完整 code（`<title>` 與 `data-evidence-code` 不變）。

執行：`cd web && npm run build`

### T4: Handbook / Search / MapLens

成功標準：三頁面名稱隨 locale 切換、缺省回退 code。

- `web/src/pages/HandbookView.vue`：list／detail 傳 locale params；items 已 map `language_name`（line 80-81）與 detail 的 `language_name`（line 127-128）→ 傳入 `ExpressionRow`。
- `web/src/pages/Search.vue`：search 傳 locale params；結果 item 若有 `language_name` 傳 `ExpressionRow`。
- `web/src/components/expression/ExpressionRow.vue`：props 加 `language_name?: string`；badge 顯示 `language_name || language_profile_code || lang_code`（`<title>` 保留 code）。
- `web/src/pages/MapLens.vue`：`getExpressionDetail`／`mappingGraph(requestedId, 2)`／`getLanguageDetail(code)` 傳 locale params；`region`（line 61）改 `locale.display_name ?? locale.name`（後端 T4 detail locales 含 `display_name`）。

執行：`cd web && npm run build`

### T5: 語言選擇 picker 元件

成功標準：選取語言／locale 的輸入元件顯示解析後名稱；切換器維持自稱。

- `web/src/components/language/LanguageSelect.vue`：`l.name_en`（line 172）改 `l.name ?? l.name_en`；registry list 呼叫帶 locale params（後端 T5 registry `languages` 有 `name`）。
- `web/src/components/language/LanguagePicker.vue`：`selected?.name_en`（line 41）與 option `item.name_en`（line 48）改 `name ?? name_en`。
- `web/src/components/language/LanguageLocalePicker.vue`：option 主標籤 `locale.name || locale.name_en`（`<span class="option-name">`）改 `locale.display_name ?? locale.name`；次標籤 `name_en` 保留；`listLanguageLocales` 帶 locale params。
- `web/src/components/nav/LangSwitcher.vue`：**不變**（spec §6.3：切換器以 `language_locales.name` 自稱當主標籤，`groupLocalesByVariety` 現況已符合）。
- `web/src/components/nav/TopNav.vue`：無語言名稱顯示，不變。

執行：`cd web && npm run build`

### T6: 競態防護與全站驗證

成功標準：切換 primary／secondary 後各頁面重發且無舊回應覆蓋；`npm run build` 與 `./build.sh` 通過。

1. 頁面新增統一重發 hook（各頁面局部 watch，維持現有模式）：

```ts
watch(() => localization.locale, () => { void loadX() })
watch(() => localization.secondary, () => { void loadX() })
```

   套用於：LanguageList（已有 locale watch，補 secondary）、LanguageDetail、HomeFeed、MappingDetail、HandbookView、Search、MapLens（已有 `loadRequest` token，補 secondary watch）。
2. `cd web && npm run build`。
3. `./build.sh`。
4. `git diff --check`。
5. 依 `feat/20260725/langmap_v2` 分支，分 commit 提交（Surgical Changes）：

```
feat(web): pass ui_locale and secondary_ui_locale through api and composables
feat(web): show localized names in language list and detail
feat(web): show localized names in feed and mapping graph
feat(web): show localized names in handbook, search and map lens
feat(web): localize language pickers and expression evidence
```

## Repo Hygiene

- 只改 `web/`；不修改 `apple/`、`backend/`、`scripts/`。
- `web/dist/`、`backend/public/`、`.wrangler/` 為生成物，不手動改。
- 新增中文介面文案用傳承體中文（現有中文文案沿用原語體）。
- 不新增前端名稱翻譯表；名稱一律來自後端解析欄位。

## Final Integration

- 後端（第一份）＋seed（第二份）落地後，以 `dev.sh` 啟動，切換 primary locale 驗證：
  - `/languages`：cmn-Hans-CN 下 `jpn` 行顯示「日语」；切回 eng-Latn-US 顯示「Japanese」。
  - `/language/jpn`：標題與字幕顯示解析名＋自稱；`cmn-Hans-CN` 下 locale 選項顯示「日语（日本）」。
  - `/mapping/cmn:uatw46tkfaeq2igc7xhtci62km?node=cmn:fg6livf5llbcxn66umfdpwnrnq`：圖譜節點顯示「日语」／「Japanese」；證據清單顯示「日语（日本）」＋完整 code。
  - `/`（feed）、`/search`、`/handbooks`、`/map`：語言名稱隨 locale 切換且無舊回應閃覆。
  - `LangSwitcher`：仍以自稱（日本語／閩南語）為主標籤。
