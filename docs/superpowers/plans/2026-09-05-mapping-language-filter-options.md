# Mapping 語言過濾器可用選項 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 讓 Mapping 詳情頁的語言過濾器列出目前跳數未過濾圖譜中實際出現的語言，按詞句節點數降序顯示並保持選項穩定。

**Architecture:** `MappingDetail` 維護顯示圖譜與未過濾的選項來源圖譜；有過濾條件時兩者分開請求，無過濾條件時共用同一結果。純函式負責從圖譜產生穩定排序的語言選項，`LanguageSelect` 只負責本地搜尋、呈現與選取，不再對任意 registry 語言發起遠端搜尋。

**Tech Stack:** Vue 3 `<script setup lang="ts">`、Pinia、Vue I18n、Vitest、Vue Test Utils、TypeScript。

## Global Constraints

- 只修改前端，不改動 `target_language` API 契約或後端遍歷語義。
- 選項只統計 `depth >= 1` 且不超過目前跳數的唯一節點；根節點不計入。
- 排序為詞句數降序、顯示名稱升序、語言代碼升序。
- 保留目前 request sequence 防護，舊請求不得覆寫新 expression、跳數或篩選條件。
- 沿用 Atlas tokens、現有 focus／combobox／listbox accessibility 與至少 44px 觸控目標。
- 不修改 `apple/`、`web/dist/`、`backend/public/` 或 `.wrangler/`。

---

### Task 1: 建立圖譜語言選項純函式

**Files:**
- Create: `web/src/components/language/languageFilterOptions.ts`
- Test: `web/src/components/language/languageFilterOptions.test.ts`

**Interfaces:**
- Consumes: `MappingGraphResponse`、`getName(code: string): string`、最大深度數字。
- Produces: `LanguageFilterOption { code: string; name: string; count: number }` 與 `buildLanguageFilterOptions(graph, getName, maxDepth): LanguageFilterOption[]`。

- [ ] **Step 1: Write the failing tests**

```ts
import { describe, expect, it } from 'vitest'
import { buildLanguageFilterOptions } from './languageFilterOptions'

const graph = (nodes: Array<{ expression_id: string; lang_code: string; depth: number }>) => ({
  root_id: 'root', requested_hops: 3, resolved_hops: 3,
  nodes: nodes.map((node) => ({ ...node, text: node.expression_id, language_name: node.lang_code })),
  edges: [], layer_counts: { 0: 1, 1: 0, 2: 0, 3: 0 }, truncated: false, omitted_count: 0,
})

describe('buildLanguageFilterOptions', () => {
  it('counts only unique non-root nodes through the current hop and sorts deterministically', () => {
    const result = buildLanguageFilterOptions(graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'jpn', depth: 1 },
      { expression_id: 'b', lang_code: 'eng', depth: 1 },
      { expression_id: 'c', lang_code: 'jpn', depth: 2 },
      { expression_id: 'd', lang_code: 'cmn', depth: 3 },
      { expression_id: 'e', lang_code: 'nan', depth: 4 },
    ]), (code) => ({ eng: 'English', cmn: 'Mandarin', jpn: 'Japanese', nan: 'Taiwanese' }[code] ?? code), 3)

    expect(result).toEqual([
      { code: 'jpn', name: 'Japanese', count: 2 },
      { code: 'eng', name: 'English', count: 1 },
      { code: 'cmn', name: 'Mandarin', count: 1 },
    ])
  })

  it('uses code as the final stable tie breaker', () => {
    const result = buildLanguageFilterOptions(graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'zxx', depth: 1 },
      { expression_id: 'b', lang_code: 'abc', depth: 1 },
    ]), (code) => code === 'zxx' ? 'Same' : 'Same', 1)

    expect(result.map((option) => option.code)).toEqual(['abc', 'zxx'])
  })
})
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `cd web && npx vitest run src/components/language/languageFilterOptions.test.ts`

Expected: FAIL because `languageFilterOptions.ts` and `buildLanguageFilterOptions` do not exist.

- [ ] **Step 3: Implement the minimal pure function**

```ts
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

export interface LanguageFilterOption { code: string; name: string; count: number }

export function buildLanguageFilterOptions(
  graph: MappingGraphResponse | null,
  getName: (code: string) => string,
  maxDepth: number,
): LanguageFilterOption[] {
  if (!graph) return []
  const counts = new Map<string, number>()
  const seen = new Set<string>()
  for (const node of graph.nodes) {
    if (node.depth < 1 || node.depth > maxDepth) continue
    if (seen.has(node.expression_id)) continue
    seen.add(node.expression_id)
    counts.set(node.lang_code, (counts.get(node.lang_code) ?? 0) + 1)
  }
  return [...counts.entries()]
    .map(([code, count]) => ({ code, name: getName(code) || code, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name) || a.code.localeCompare(b.code))
}
```

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `cd web && npx vitest run src/components/language/languageFilterOptions.test.ts`

Expected: PASS.

- [ ] **Step 5: Commit the pure option builder**

```bash
git add web/src/components/language/languageFilterOptions.ts web/src/components/language/languageFilterOptions.test.ts
git commit -m "feat: build mapping language filter options"
```

### Task 2: 改造 LanguageSelect 為本地可用選項選擇器

**Files:**
- Modify: `web/src/components/language/LanguageSelect.vue`
- Create: `web/src/components/language/LanguageSelect.test.ts`
- Modify: `web/src/locales/en.ts` and the corresponding existing locale message files only if a new user-facing key is required.

**Interfaces:**
- Consumes: `LanguageFilterOption[]` from Task 1 and existing `modelValue: string[]`.
- Produces: same `update:modelValue` event; blank focus opens all supplied options, query filters locally by `name` or `code`, and each option displays `count`.

- [ ] **Step 1: Write failing component tests**

```ts
import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import LanguageSelect from './LanguageSelect.vue'

const options = [
  { code: 'jpn', name: 'Japanese', count: 4 },
  { code: 'eng', name: 'English', count: 2 },
]

describe('LanguageSelect', () => {
  it('shows all options when focused without a query and includes counts', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: [], options } })
    await wrapper.get('input').trigger('focus')
    expect(wrapper.findAll('[role="option"]').map((item) => item.text())).toEqual([
      'Japanesejpn4', 'Englisheng2',
    ])
  })

  it('filters locally by name and code and does not hide other options after selection', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: [], options } })
    await wrapper.get('input').trigger('focus')
    await wrapper.get('input').setValue('eng')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(1)
    await wrapper.get('[role="option"]').trigger('mousedown')
    await wrapper.setProps({ modelValue: ['eng'] })
    await wrapper.get('input').setValue('')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(1)
    expect(wrapper.text()).toContain('Japanese')
  })

  it('keeps a URL-selected option visible as a tag even when it is not available', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: ['cmn'], options } })
    expect(wrapper.find('.lang-tag').text()).toContain('cmn')
    await wrapper.get('input').trigger('focus')
    expect(wrapper.findAll('[role="option"]').map((item) => item.text())).toEqual([
      'Japanesejpn4', 'Englisheng2',
    ])
  })
})
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `cd web && npx vitest run src/components/language/LanguageSelect.test.ts`

Expected: FAIL because the component currently performs remote search and has no `options` prop or count rendering.

- [ ] **Step 3: Implement local option behavior**

Remove the component's `listLanguages` search/debounce/abort path. Add the required `options: LanguageFilterOption[]` prop, derive `filtered` from all `options` (without an arbitrary result cap) excluding selected codes and matching `query.trim().toLocaleLowerCase()` against name or code, and render the count in a right-aligned metadata span. Keep the existing click-outside, keyboard navigation, ARIA IDs, selected tag removal, and 44px option minimum height. Use the localized `option.name` supplied by the page, with the language code as its fallback.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `cd web && npx vitest run src/components/language/LanguageSelect.test.ts`

Expected: PASS.

- [ ] **Step 5: Commit the selector change**

```bash
git add web/src/components/language/LanguageSelect.vue web/src/components/language/LanguageSelect.test.ts web/src/locales/en.ts
git commit -m "feat: show counted mapping language options"
```

### Task 3: 將未過濾圖譜接入 MappingDetail

**Files:**
- Modify: `web/src/pages/MappingDetail.vue`
- Modify: `web/src/pages/MappingDetail.behavior.test.ts`
- Modify: `web/src/pages/MappingDetail.language.test.ts` only if the existing mount needs the new selector prop stub.

**Interfaces:**
- Consumes: `buildLanguageFilterOptions`, `LanguageFilterOption[]`, existing `mappingGraph` composable and `targetLanguageCodes` state.
- Produces: a current `languageFilterOptions` computed value passed as `:options` to `LanguageSelect`; selected graph requests keep existing `target_language` behavior.

- [ ] **Step 1: Add failing page tests for the option-source graph**

Extend the page test graph fixture with nodes at depths 1, 2, and 3 in multiple languages. Add a `LanguageSelectStub` to `mountPage` that exposes its `options` prop as JSON, then add tests that:

```ts
it('passes counted languages from the unfiltered graph to LanguageSelect', async () => {
  const wrapper = mountPage()
  await flushPromises()
  expect(wrapper.get('[data-testid="language-options"]').text()).toBe(JSON.stringify([
    { code: 'nan', name: 'Taiwanese', count: 2 },
    { code: 'eng', name: 'English', count: 1 },
  ]))
})

it('keeps the full option list when a filtered graph contains only the root', async () => {
  route.query = { target_language: 'eng' }
  // The first filtered result contains only the root, while the parallel unfiltered result contains eng and nan.
  const wrapper = mountPage()
  await flushPromises()
  expect(wrapper.get('[data-testid="language-options"]').text()).toContain('nan')
  expect(wrapper.get('[data-testid="language-options"]').text()).toContain('eng')
})
```

The stub's relevant shape is:

```ts
const LanguageSelectStub = {
  name: 'LanguageSelect',
  props: ['modelValue', 'options'],
  template: '<div data-testid="language-options">{{ JSON.stringify(options) }}</div>',
}
```

Use the existing `mappingGraph` mock and request-order helpers; assert calls include an unfiltered request (`undefined` target language) and a filtered request only after selection.

- [ ] **Step 2: Run the focused page tests and verify the new assertions fail**

Run: `cd web && npx vitest run src/pages/MappingDetail.behavior.test.ts src/pages/MappingDetail.language.test.ts`

Expected: FAIL because `MappingDetail` does not keep an option-source graph or pass options to `LanguageSelect`.

- [ ] **Step 3: Add option-source state and computed options**

Import `buildLanguageFilterOptions` and `useLanguagesStore`. Add:

```ts
const languageStore = useLanguagesStore()
const optionGraph = ref<MappingGraphResponse | null>(null)
const languageFilterOptions = computed(() =>
  buildLanguageFilterOptions(optionGraph.value, languageStore.getName, hops.value),
)
```

Ensure `LanguageSelect` receives `:options="languageFilterOptions"`.

- [ ] **Step 4: Update initial and hop request orchestration**

In `load`, request `mappingGraph(requestedId, requestedHops, hints, filteredCode)` for display and, when `targetLanguageCodes` is non-empty, request `mappingGraph(requestedId, requestedHops, hints)` in parallel for `optionGraph`; when no filter is selected, assign the display result to both `graph` and `optionGraph`. The option-source request is allowed to fail independently: keep the display graph, set `optionGraph` to `null`, and leave the selector with no unverified candidates.

In `changeHops`, use the same rule. When the last selected code is removed and `optionGraph` matches the current expression/hops, display it directly; otherwise retain the existing request path. Preserve `graphRequest` and `loadRequest` checks before assigning either result. Reset `optionGraph` on expression changes and locale changes through the existing `load` path.

- [ ] **Step 5: Re-run focused page tests and verify they pass**

Run: `cd web && npx vitest run src/pages/MappingDetail.behavior.test.ts src/pages/MappingDetail.language.test.ts`

Expected: PASS, including stale route/hop result tests and the new language option tests.

- [ ] **Step 6: Commit page integration**

```bash
git add web/src/pages/MappingDetail.vue web/src/pages/MappingDetail.behavior.test.ts web/src/pages/MappingDetail.language.test.ts
git commit -m "fix: scope mapping language filter to graph hops"
```

### Task 4: 完整驗證與交付

**Files:**
- Modify: no production files unless a test or type error exposes an issue in Tasks 1–3.

- [ ] **Step 1: Run all relevant frontend tests**

Run: `cd web && npm test -- --run src/components/language/languageFilterOptions.test.ts src/components/language/LanguageSelect.test.ts src/pages/MappingDetail.behavior.test.ts src/pages/MappingDetail.language.test.ts`

Expected: PASS.

- [ ] **Step 2: Build the frontend**

Run: `cd web && npm run build`

Expected: Vite production build succeeds without TypeScript or template errors.

- [ ] **Step 3: Check the diff and working tree**

Run: `git diff --check` and `git status --short`

Expected: no whitespace errors; only intended source, test, plan, and prior design commits are present.

- [ ] **Step 4: Report verification and remaining limitation**

Report that counts are based on the unfiltered graph nodes returned by the existing 200-node cap, and that issue #118's backend multi-hop traversal semantics remain outside this change.
