# Locale-specific Readings 呈現實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在詞句證據區以精確 language locale 分別呈現讀音／標音，讓同語言不同地區或書寫系統的 reading 不會被合併成一個未區分的項目。

**Architecture:** 保留 `ExpressionReading` API 型別和現有顯示名稱 helper；將 reading 合併鍵改為 locale、scheme 與正規化後的值，讓相同 locale 的格式差異仍可合併，不同 locale 即使值相同也各自呈列。

**Tech Stack:** Vue 3、TypeScript、Vitest、Vue Test Utils。

**Spec:** [首頁與詞句頁 Tab 重整規格](../specs/2026-09-30-home-and-mapping-tabs-redesign-design.md)

## Global Constraints

- 詞句頁的 reading 依精確 `language_locale_code` 分組或標示 locale；同一 language 的不同地區／書寫系統 profile 不得共用一個未標明的 reading。
- 每筆標音同時呈現其 reading scheme 與值；同一 locale 有多種 scheme 時保留各筆資料。
- 網站介面語言切換不改寫 reading 的 locale 身分，也不把網站語言選項當作詞句 locale 篩選器。
- 不更改 expression、mapping、locale 或 reading 的 schema，不新增 favorite／bookmark 能力。
- 使用 `web/src/assets/atlas.css` 現有 tokens、字級與間距慣例；不新增顏色、陰影或圓角系統。
- 不修改 `apple/` 客戶端，不引入新的設計 token、圖譜供應商或外部服務。

---

## File Structure

- Modify `web/src/utils/readingGroups.ts`: 在穩定排序下，以 locale + scheme + normalized value 作分組 identity。
- Modify `web/src/components/mapping/ExpressionEvidenceList.vue`: locale-specific row key、可檢查的 locale code 和既有標籤呈現。
- Modify `web/src/utils/readingGroups.test.ts`: 相同標音值在不同 locale 保持分組的 helper 測試。
- Modify `web/src/components/mapping/ExpressionEvidenceList.test.ts`: 對應每列 locale 標籤、scheme 和同 locale 空白正規化的呈現測試。
- Reuse `web/src/components/mapping/GraphInspector.vue` and `GraphMobileInspector.vue`: 兩個 inspector 已共用 `ExpressionEvidenceList`，不複製 reading 呈現邏輯。

## Task 1: 依 locale 分組與呈列 readings

**Files:**
- Modify: `web/src/utils/readingGroups.ts`
- Modify: `web/src/components/mapping/ExpressionEvidenceList.vue`
- Test: `web/src/utils/readingGroups.test.ts`
- Test: `web/src/components/mapping/ExpressionEvidenceList.test.ts`

**Interfaces:**
- Consumes: `ExpressionReading { language_locale_code, locale_display_name?, scheme, value }`。
- Produces: 每個 `ReadingGroup` 只包含同一 locale 與 scheme 的等價值 readings；Evidence list 每列可辨識 locale、scheme 和顯示值。

- [ ] **Step 1: 寫不同 locale 不合併的 helper 測試**

在 `readingGroups.test.ts` 匯入 `groupReadings`，新增：

```ts
it('keeps equal readings in different locales as separate groups', () => {
  const groups = groupReadings([
    { language_locale_code: 'eng-Latn-GB', locale_display_name: 'English (United Kingdom)', scheme: 'ipa', value: 'naɪt' },
    { language_locale_code: 'eng-Latn-US', locale_display_name: 'English (United States)', scheme: 'ipa', value: 'naɪt' },
  ])

  expect(groups.map((group) => group.readings.map((reading) => reading.language_locale_code)))
    .toEqual([['eng-Latn-GB'], ['eng-Latn-US']])
})
```

- [ ] **Step 2: 執行 helper 測試確認失敗**

Run: `cd web && npm test -- src/utils/readingGroups.test.ts`

Expected: 新測試目前失敗，因 `groupReadings` 的分組鍵未包含 locale；既有 locale label suffix 測試通過。

- [ ] **Step 3: 加入 locale 身分到分組鍵**

在 `groupReadings()` 保留目前的 locale／scheme／value 穩定排序、同 locale 去重和空白正規化，只把 `groupKey` 改為：

```ts
const groupKey = [
  reading.language_locale_code,
  reading.scheme,
  comparableReadingValue(reading.value),
].join('\u0000')
```

- [ ] **Step 4: 鎖定 component 每列顯示單一 locale**

調整 `ExpressionEvidenceList.vue` 的 reading row key，避免相同 scheme/value 在不同 locale key collision；加上 `data-locale-code`，其值由該 group 的 `readings` 取得，畫面仍使用 `readingLocalesLabel()` 顯示 locale 名稱。修改 component 測試，驗證相同值但 GB／US 不再合併：

```ts
expect(wrapper.findAll('.rx-item')).toHaveLength(2)
expect(wrapper.findAll('.rx-item').map((item) => item.attributes('data-locale-code')))
  .toEqual(['eng-Latn-GB', 'eng-Latn-US'])
expect(wrapper.findAll('.rx-item')[0].text()).toContain('naɪt')
expect(wrapper.findAll('.rx-item')[1].text()).toContain('naɪt')
```

同步將原本預期 CN／TW readings 合併為單列的測試改為兩列各自標明 locale；保留同 locale 下空白差異合併、reading scheme 標籤和穩定順序的既有驗收。

- [ ] **Step 5: 重跑 reading 測試**

Run: `cd web && npm test -- src/utils/readingGroups.test.ts src/components/mapping/ExpressionEvidenceList.test.ts`

Expected: 不同 locale 即使標音值相同也各自呈列；同 locale 正規化、scheme label、locale display label 和順序測試通過。

- [ ] **Step 6: 回讀桌面與行動版**

在 1487×1058 和 390×844 viewport 檢查有多個 locale reading 的詞句頁及兩種 inspector；確認每列 locale、scheme 和值清楚可辨，長名稱不造成水平溢出。

- [ ] **Step 7: 執行 Web build**

Run: `cd web && npm run build`

Expected: Vite production build 完成。

- [ ] **Step 8: Commit**

```bash
git add web/src/utils/readingGroups.ts web/src/components/mapping/ExpressionEvidenceList.vue web/src/utils/readingGroups.test.ts web/src/components/mapping/ExpressionEvidenceList.test.ts
git commit -m "fix: keep expression readings distinct by locale"
```
