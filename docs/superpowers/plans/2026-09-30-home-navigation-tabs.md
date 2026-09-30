# 首頁與全站導覽重整實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓首頁 Search／Translate 工作區和全站導覽各自清楚，避免同頁重複的主要搜尋表單，並維持原有導覽及網站介面語言功能。

**Architecture:** 保留 `HomeView.vue` 既有任務狀態與搜尋／翻譯元件，調整工作區層級和響應式呈現。`TopNav.vue` 繼續提供內容頁全站搜尋、目的地導覽與 `LangSwitcher`；`/search` 隱藏重複的頁首搜尋，由頁內表單承載搜尋。

**Tech Stack:** Vue 3、TypeScript、Vue Router、Vue I18n、Vitest、Vue Test Utils、`atlas.css` tokens。

**Spec:** [首頁與詞句頁 Tab 重整規格](../specs/2026-09-30-home-and-mapping-tabs-redesign-design.md)

## Global Constraints

- 使用 `web/src/assets/atlas.css` 現有 tokens、字級與間距慣例；不新增顏色、陰影或圓角系統。
- Search／Translate 表達「要做哪種任務」，Graph／List 表達「如何檢視目前關係」；兩組控制須有不同的區域標題或容器脈絡，避免看起來是同一層級的全站 Tab。
- 首屏優先呈現品牌導覽與單一首頁任務卡；活動動態、mapping 細節和次要操作保持清楚但不競爭主入口。
- 桌面可用較寬的工作區；行動版採單欄與明確分段，不將桌面多欄直接等比例縮小。
- 保留現有 Home、Languages、Handbooks 名稱、目的地和網站介面語言選項。網站介面語言只控制 UI 文案，不代表詞句的語言或 reading locale。
- Handbooks 在桌面和行動版都是通往 `/handbooks` 的單一導覽入口。行動版選單不展開或列舉 handbook 內容，讓內容規模增長時導覽仍精簡。
- Languages 沿用現有目的地與選取方式；Contribute、登入／帳戶入口及權限行為不變。
- 首頁以 Search／Translate 工作區作為搜尋與翻譯的主要入口。其他頁面沿用全站搜尋入口；`/search` 隱藏全站頁首搜尋，由頁面內表單承載主要搜尋，避免同頁出現第二份完整表單。行動版內容頁保留可直接找到的搜尋入口。
- 當前目的地在導覽中有明確 active state。選單可由鍵盤操作，開合狀態與控制項名稱可被輔助科技辨識。
- 動作按鈕、選單、Tab 與圖譜操作提供可見 focus、accessible name 和鍵盤操作；觸控目標至少 44px，並遵守 `prefers-reduced-motion`。
- 窄螢幕不得出現水平溢出；長詞句允許換行或在容器內處理，不得撐破頁面。
- 不修改搜尋或翻譯 API 契約、登入門檻、翻譯資料生命週期及既有頁面路由。
- 不修改 `apple/` 客戶端，不引入新的設計 token、圖譜供應商或外部服務。

---

## File Structure

- Modify `web/src/pages/HomeView.vue`: 首頁 Search／Translate 工作區的階層、面板標記與響應式樣式。
- Modify `web/src/components/nav/TopNav.vue`: 搜尋入口的路由呈現、導覽 active state 與窄版抽屜呈現；保留直接 Handbooks 導覽和 `LangSwitcher`。
- Modify `web/src/pages/HomeView.test.ts`: 驗證任務切換和動態位於主卡片下方。
- Modify `web/src/components/nav/TopNav.test.ts`: 搜尋入口、導覽 active state、Handbooks 和介面語言控制的位置。

## Task 1: 首頁任務工作區

**Files:**
- Modify: `web/src/pages/HomeView.vue`
- Test: `web/src/pages/HomeView.test.ts`

**Interfaces:**
- Consumes: `ExpressionSearchControls`, `HomeFeed`, `TranslationWorkbench`，以及現有 `/search?q=...&lang=...` 路徑。
- Produces: Search 為預設的首頁任務切換；當前任務只呈現自己的主要面板；Search 動態在任務卡下方，且只於 Search 模式顯示。

首頁目前已有 Search／Translate tab 與任務面板；把這些內容收進參考稿中的單一卡片，將動態移到卡片之外：

- [ ] **Step 1: 鎖定單一卡片與動態位置**

在 `mountHome()` fixture 中將 `HomeFeed` stub 為 `<section class="home-feed"></section>`，避免測試呼叫 feed API；再於 `describe('HomeView')` 新增：

```ts
it('keeps the task switch and active form in one card above the activity feed', async () => {
  const { wrapper } = await mountHome()

  const card = wrapper.get('.home-task-card')
  expect(card.findAll('[role="tab"]')).toHaveLength(2)
  expect(card.find('form[role="search"]').exists()).toBe(true)
  expect(wrapper.find('.home-task-card .home-feed').exists()).toBe(false)
  expect(wrapper.find('.home-feed').exists()).toBe(true)

  await wrapper.get('#home-translate-tab').trigger('click')
  expect(wrapper.get('.home-task-card .translation-workbench-stub').exists()).toBe(true)
  expect(wrapper.find('.home-feed').exists()).toBe(false)
})
```

- [ ] **Step 2: 執行首頁測試確認新卡片契約失敗**

Run: `cd web && npm test -- src/pages/HomeView.test.ts`

Expected: 新測試因目前沒有 `.home-task-card` 且 HomeFeed 仍在搜尋 panel 內而失敗；既有搜尋路由、語言必選和 Translate 留在首頁測試通過。

- [ ] **Step 3: 將工作區包入單一卡片**

在 `HomeView.vue` 以 `.home-task-card` 包住既有 tabs、Search panel 與 Translate panel；把 `HomeFeed v-if="mode === 'search'"` 移到卡片後方。保留 `mode`、鍵盤操作、搜尋語言和表單事件。桌面 Search 卡片寬度以 822px 參考，翻譯模式保留較寬的 1120px；卡片使用既有 surface、border 和 radius tokens。

```css
.home-layout { width: min(100%, 822px); min-width: 0; }
.home-layout-translate { width: min(100%, 1120px); max-width: 1120px; }
.home-task-card {
  min-width: 0;
  padding: var(--space-lg);
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
@media (max-width: 640px) {
  .home-page { padding-inline: 16px; }
  .home-task-card { padding: 16px; }
}
```

在 Search 模式下動態區位於卡片下方；Translate 模式不掛載動態。Search／Translate 保持同一卡片內、同一水平錨點。

- [ ] **Step 4: 重跑首頁測試**

Run: `cd web && npm test -- src/pages/HomeView.test.ts`

Expected: 卡片／動態位置新增測試及首頁既有搜尋、語言必選、搜尋路由與翻譯狀態測試全部通過。

- [ ] **Step 5: 回讀桌面和行動版**

以 1487×1058 和 390×844 viewport 檢查 Search、Translate 狀態；桌面卡片和動態維持參考稿的垂直層級，行動版單欄且沒有水平溢出。

- [ ] **Step 6: 執行 Web build**

Run: `cd web && npm run build`

Expected: Vite production build 完成。

- [ ] **Step 7: Commit**

```bash
git add web/src/pages/HomeView.vue web/src/pages/HomeView.test.ts
git commit -m "feat: refine home task workspace"
```

## Task 2: 全站搜尋與行動版導覽

**Files:**
- Modify: `web/src/components/nav/TopNav.vue`
- Test: `web/src/components/nav/TopNav.test.ts`

**Interfaces:**
- Consumes: Vue Router 現有路由、`ExpressionSearchControls`、`LangSwitcher` 與既有 `nav.*` 文案。
- Produces: 非首頁內容頁仍可使用全站搜尋；`/search` 隱藏重複的全站頁首表單；導覽目的地有可感知的目前狀態；手機 Handbooks 是直接入口。

- [ ] **Step 1: 鎖定搜尋與導覽契約**

在 `TopNav.test.ts` 將原本「Search 路由仍顯示頁首搜尋並同步 query／language」的測試改為下列路由呈現測試（移除原測試對頁首輸入值的斷言），保留 mapping 等內容頁的全站搜尋提交、記憶語言和鍵盤操作測試。新增 Languages 目前頁狀態測試，並擴充 Handbooks 測試：

```ts
it('hides the duplicate global search form on /search', async () => {
  const { wrapper, router } = await mountNav()
  await router.push({ path: '/search', query: { q: 'star', lang: 'spa' } })
  await flushPromises()

  expect(wrapper.find('.search-center').exists()).toBe(false)
  await wrapper.get('.menu-toggle').trigger('click')
  expect(wrapper.find('.drawer-search').exists()).toBe(false)
})

it('marks the active Languages destination in desktop and mobile navigation', async () => {
  const { wrapper, router } = await mountNav()
  await router.push('/languages')

  expect(wrapper.get('.appnav a[href="/languages"]').attributes('aria-current')).toBe('page')
  await wrapper.get('.menu-toggle').trigger('click')
  expect(wrapper.get('.drawer-nav a[href="/languages"]').attributes('aria-current')).toBe('page')
})

it('keeps Handbooks as a direct mobile link and retains the interface locale control', async () => {
  const { wrapper, router } = await mountNav()
  await router.push('/handbooks')

  expect(wrapper.get('.appnav a[href="/handbooks"]').attributes('aria-current')).toBe('page')
  expect(wrapper.get('.lang-inline').text()).toContain('Language')
  await wrapper.get('.menu-toggle').trigger('click')

  expect(wrapper.get('.drawer-nav a[href="/handbooks"]').text()).toContain('Handbooks')
  expect(wrapper.get('.drawer-nav a[href="/handbooks"]').attributes('aria-current')).toBe('page')
  expect(wrapper.find('.drawer-nav details').exists()).toBe(false)
  expect(wrapper.get('.drawer-foot').text()).toContain('Language')
})
```

- [ ] **Step 2: 執行導覽測試確認新契約失敗**

Run: `cd web && npm test -- src/components/nav/TopNav.test.ts`

Expected: 原本 `/search` 頁首搜尋可見的斷言與新隱藏契約衝突；mapping 等內容頁的 remembered-language、搜尋提交、直接 Handbooks 連結和 `LangSwitcher` mock fixture 可供回歸驗證。

- [ ] **Step 3: 調整頁首搜尋路由條件與導覽狀態**

將 `/search` 頁內搜尋定為唯一表單；其他非首頁頁面保留全站搜尋。桌面與抽屜都隱藏 `/search` 的重複全站搜尋，保留 Search.vue 對 query、language、URL 和結果的現有處理。刪除 TopNav 專為頁首表單同步 `/search` query 的 watcher/helper；保留其他路由的記憶語言、搜尋提交、快捷鍵和抽屜行為。桌面導覽與抽屜的 Languages、Handbooks active state 同時加上 `aria-current="page"`；Handbooks 仍為 `/handbooks` 單一 router-link，`LangSwitcher` 的選項和行為保持原樣。

```vue
<div v-if="route.path !== '/' && route.path !== '/search'" class="search-center">
```

抽屜的搜尋容器也使用相同的 `/search` 排除條件；不動 Search.vue 的頁內表單與 URL 同步。

在桌面和 drawer 導覽的 Languages、Handbooks `router-link` 上，依其既有 route predicate 綁定 `aria-current`；不更改目的地或標籤。Languages 的現有 route predicate 是 `route.path.startsWith('/language')`；Handbooks 的是 `route.path.startsWith('/handbook')`。

- [ ] **Step 4: 重跑導覽測試**

Run: `cd web && npm test -- src/components/nav/TopNav.test.ts`

Expected: `/search` 不再呈現頁首／抽屜第二份主要表單；其他頁面的搜尋提交、目前頁狀態、mobile Handbooks 直接連結和介面語言控制均通過。

- [ ] **Step 5: 執行 Web build**

Run: `cd web && npm run build`

Expected: Vite production build 完成。

- [ ] **Step 6: Commit**

```bash
git add web/src/components/nav/TopNav.vue web/src/components/nav/TopNav.test.ts
git commit -m "feat: clarify responsive site navigation"
```
