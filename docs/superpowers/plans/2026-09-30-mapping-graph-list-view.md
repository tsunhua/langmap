# Mapping 圖譜與列表切換實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在桌面與行動版提供一致的 Graph／List 檢視切換，保留 mapping 的多跳關係、篩選與節點脈絡，並以 2 跳作為預設深度。

**Architecture:** 在 `MappingDetail.vue` 將目前僅供行動版的 `mobileMode` 提升為共用 `viewMode`，沿用 `MappingGraph`、`MappingHierarchyList` 和現有 GraphToolbar。深度與語言篩選仍使用原有 API 與 URL query，預設深度設為 2。

**Tech Stack:** Vue 3、TypeScript、Vue Router、Vitest、Vue Test Utils、現有 mapping graph API。

**Spec:** [首頁與詞句頁 Tab 重整規格](../specs/2026-09-30-home-and-mapping-tabs-redesign-design.md)

## Global Constraints

- Graph 是預設視圖；Graph／List 控制固定在 mapping 區域，並在桌面與行動版位置一致、可見且可操作。
- Graph 保留多跳探索、既有語言篩選、節點選取及資訊檢視能力。跳數選擇沿用 API 支援的 1、2、3 跳，預設為 2 跳；不要把間接節點壓平成根節點的一跳關係。
- 行動版節點詳情沿用共用資訊面板並放在圖譜下方，保持頁面正常捲動；不使用固定底部抽屜或覆蓋圖譜的彈出面板。
- Graph／List 切換不得重設詞句頁。圖譜跳數或語言篩選更新時，維持目前詞句為根節點並使用既有穩定排序、循環處理和數量上限。
- 使用 `web/src/assets/atlas.css` 現有 tokens、字級與間距慣例；不新增顏色、陰影或圓角系統。
- 動作按鈕、選單、Tab 與圖譜操作提供可見 focus、accessible name 和鍵盤操作；觸控目標至少 44px，並遵守 `prefers-reduced-motion`。
- 不修改 `apple/` 客戶端，不引入新的設計 token、圖譜供應商或外部服務。

---

## File Structure

- Modify `web/src/pages/MappingDetail.vue`: 跨 viewport 的 view state、圖／列表條件呈現、預設深度和 query 同步。
- Modify `web/src/pages/MappingDetail.behavior.test.ts`: view state、預設深度、URL deep-link 回復及已登入的 3-hop 回歸。
- Reuse `web/src/components/mapping/MappingGraph.vue` and `GraphInspector.vue`: 現有圖譜、hop toolbar、節點互動與桌面／行動共用詳情面板，不新增第二套圖譜元件。
- Reuse `web/src/components/mapping/MappingHierarchyList.vue`: 現有穩定排序階層列表作為文字替代。

## Task 1: 共用 Graph／List 切換與 2-hop 預設

**Files:**
- Modify: `web/src/pages/MappingDetail.vue`
- Test: `web/src/pages/MappingDetail.behavior.test.ts`

**Interfaces:**
- Consumes: `MappingGraph`, `MappingHierarchyList`, `mappingGraph(target, hops, localeHints, targetLanguage)`。
- Produces: `viewMode: 'graph' | 'list'`；新頁預設 Graph 和 2 hops；有效的 `?hops=1|2|3` 仍能載入對應深度，匿名最高深度仍為 2。

- [ ] **Step 1: 加入預設深度和檢視狀態測試**

在 `MappingDetail.behavior.test.ts` 的 `describe('MappingDetail page state')` 加入：

```ts
it('defaults to a two-hop graph and switches to a text list on desktop', async () => {
  route.params = { lang: 'eng', text: 'anchor' }
  route.query = {}
  detail.mockResolvedValue(expression('anchor', 'Anchor'))
  mappingGraph.mockResolvedValue(languageGraph('anchor', 2))

  const wrapper = mountPage()
  await flushPromises()

  expect(mappingGraph).toHaveBeenCalledWith(
    { lang_code: 'eng', text: 'anchor', homograph_index: 1 },
    2,
    expect.anything(),
    undefined,
  )
  expect(wrapper.find('.mapping-graph-stub').exists()).toBe(true)
  expect(wrapper.find('.md-list-section').exists()).toBe(false)
  expect(wrapper.get('[data-view="graph"]').attributes('aria-pressed')).toBe('true')

  await wrapper.get('[data-view="graph"]').trigger('click')
  expect(wrapper.find('.mapping-graph-stub').exists()).toBe(true)

  await wrapper.get('[data-view="list"]').trigger('click')
  expect(wrapper.find('.mapping-graph-stub').exists()).toBe(false)
  expect(wrapper.find('.md-list-section').exists()).toBe(true)
  expect(wrapper.get('[data-view="list"]').attributes('aria-pressed')).toBe('true')
})
```

- [ ] **Step 2: 執行 mapping 行為測試確認新契約失敗**

Run: `cd web && npm test -- src/pages/MappingDetail.behavior.test.ts`

Expected: 新增測試先因預設仍為 1 hop、desktop 沒有 view toggle 而失敗；既有 query language filter 和非同步 hop 更新測試仍能執行。

- [ ] **Step 3: 實作共用 view state 並保留 query 語意**

在 `MappingDetail.vue` 以 `viewMode` 取代僅限行動版的狀態，初始值設為 `graph`；初始 `hops` 設為 `2`。Graph/List 按鈕在桌面和行動版都出現，使用明確的 `setViewMode('graph' | 'list')`，點擊目前選項不得反向切換。Graph mode 顯示 `MappingGraph`，List mode 顯示 `MappingHierarchyList`；列表選取仍使用現有 `selectNodeFromList`。

```ts
const hops = ref<1 | 2 | 3>(2)
const viewMode = ref<'graph' | 'list'>('graph')

function setViewMode(next: 'graph' | 'list') {
  viewMode.value = next
}
```

讓 `syncUrl()` 對非預設深度保留 query：

```ts
if (hops.value !== 2) query.hops = String(hops.value)
```

`initFromUrl()` 仍先保留 2-hop 初始值，再套用明確的 query；省略 `hops` 表示預設 2，而 `1` 和 `3` 仍明確寫入 URL。同步更新 hop 請求失敗時恢復 `graph.value?.requested_hops ?? 2` 的 fallback 和錯誤分支 query 序列化。保持現有 `maxHops` 權限上限、hop 請求競態保護、language filter 和選取節點狀態。

- [ ] **Step 4: 更新既有 mobile control 與 mapping 測試**

將原本僅在 `isMobile` 下顯示的 `.md-mobile-bar` 改為共用控制列，按鈕分別設定 `data-view="graph"` 和 `data-view="list"`、選取狀態與 accessible name。更新既有以無 query 預期 1 hop 的斷言為 2 hop；保留 `?hops=1`、`?hops=3`、匿名上限和較晚回應不得覆蓋新結果的覆蓋。

- [ ] **Step 5: 重跑 mapping 行為測試**

Run: `cd web && npm test -- src/pages/MappingDetail.behavior.test.ts`

Expected: desktop/mobile view mode、2-hop 預設、URL query 和既有多跳／語言篩選行為全部通過。

- [ ] **Step 6: 回讀桌面與行動版**

在 1487×1058 和 390×844 viewport 檢查 Graph／List、hop controls 與文字替代；確認切換不重設詞句頁、行動版沒有水平溢出且主要控制可操作。

- [ ] **Step 7: 執行 Web build**

Run: `cd web && npm run build`

Expected: Vite production build 完成。

- [ ] **Step 8: Commit**

```bash
git add web/src/pages/MappingDetail.vue web/src/pages/MappingDetail.behavior.test.ts
git commit -m "feat: add responsive mapping view switch"
```
