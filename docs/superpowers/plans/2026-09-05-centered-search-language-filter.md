# Centered Search Language Filter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one consistent expression-search control for the desktop header, mobile drawer, and `/search` page, with only languages whose `expression_count > 0`, the three most recently selected languages first, and the remaining languages sorted by localized name.

**Architecture:** Extend the existing search-language composable into the single data and persistence boundary, then add one presentation component that combines a single-language dropdown and query input. `TopNav` owns navigation and header layout; `Search` owns URL synchronization and result fetching. Existing general-purpose language selectors remain unchanged.

**Tech Stack:** Vue 3 `<script setup lang="ts">`, TypeScript, Vue Router, Pinia localization state, Vue I18n, Vitest, Vue Test Utils, lucide-vue-next, existing Atlas CSS tokens.

## Global Constraints

- Only modify `web/`, the canonical English message catalog, project translation JSON, and tests required by this feature; do not change `apple/`, backend schema, or backend API contracts.
- Reuse `GET /api/v2/languages`, the shared API client, `langmap.search.languages`, and URL parameters `q` and `lang`.
- The selectable language set is exactly the languages with `expression_count > 0`.
- Persist at most three unique recent language codes, newest first; all other languages sort by localized name and then canonical code.
- Use Atlas tokens, low radii, the warm paper surface, terracotta focus state, and lucide icons; do not add a color, shadow, or radius system.
- Desktop controls are 40px high; mobile controls and option rows are at least 44px high.
- Use visible focus, accessible names, combobox/listbox semantics, and Arrow keys, Enter, Escape, Tab, and `/` keyboard behavior.
- New Chinese interface copy uses 傳承體中文; existing Japanese, Spanish, Simplified Chinese, and English catalogs remain complete.
- Do not add `any`; preserve stable ordering and bounded pagination.

---

## File Structure

### Create

- `web/src/composables/useSearchLanguages.test.ts` — verifies content-language loading, filtering, grouping, recent-history persistence, and stale-record removal.
- `web/src/components/search/ExpressionSearchControls.vue` — shared joined language dropdown and expression query input.
- `web/src/components/search/ExpressionSearchControls.test.ts` — verifies rendering, selection, persistence, keyboard behavior, ARIA state, submission, and exposed focus methods.
- `web/src/components/nav/TopNav.test.ts` — verifies header search initialization, validation, and navigation.

### Modify

- `web/src/composables/useSearchLanguages.ts` — becomes the single source of searchable languages and recent-language ordering.
- `web/src/pages/Search.vue` — replaces `SearchBar`, `LanguageSelect`, and recent chips with the shared expression-search controls.
- `web/src/pages/Search.test.ts` — changes fixtures from the registry endpoint to the content-language endpoint and verifies valid/invalid URL languages.
- `web/src/components/nav/TopNav.vue` — adds the shared controls, language-aware navigation, and centered responsive layout.
- `web/src/locales/en.ts` — adds canonical messages for language choice, groups, loading failure, and result-count context.
- `scripts/i18n/cmn-Hant-TW.json` — adds 傳承體中文 translations.
- `scripts/i18n/cmn-Hans-CN.json` — adds Simplified Chinese translations.
- `scripts/i18n/jpn-Jpan-JP.json` — adds Japanese translations.
- `scripts/i18n/spa-Latn-ES.json` — adds Spanish translations.

No backend files are changed: `/languages` already supplies localized names, counts, total, and pagination.

---

### Task 1: Search-language data and recent ordering

**Files:**
- Create: `web/src/composables/useSearchLanguages.test.ts`
- Modify: `web/src/composables/useSearchLanguages.ts:1-44`

**Interfaces:**
- Consumes: `listContentLanguages(filters, signal?)`, `ContentLanguage`, and `LocaleHints` from `@/api/languageIdentity`.
- Produces: `SearchLanguageGroups`, `loadSearchLanguages(hints, options?)`, `resolveSearchLanguage(requested?)`, `isSearchLanguageAvailable(code)`, `rememberSearchLanguage(code)`, `resetRecentSearchLanguages(options?)`, and reactive `recent`, `languages`, `groups`, `loading`, `loadError` from `useSearchLanguages()`.

- [ ] **Step 1: Write failing tests for the three-item recent history**

Create `web/src/composables/useSearchLanguages.test.ts` with localStorage reset in `beforeEach`, then verify deduplication and the hard limit:

```ts
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { listContentLanguages } from '@/api/languageIdentity'
import {
  rememberSearchLanguage,
  resetRecentSearchLanguages,
  useSearchLanguages,
} from './useSearchLanguages'

vi.mock('@/api/languageIdentity', () => ({ listContentLanguages: vi.fn() }))

describe('useSearchLanguages', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    resetRecentSearchLanguages()
  })

  it('keeps three unique recent languages in newest-first order', () => {
    rememberSearchLanguage('eng')
    rememberSearchLanguage('spa')
    rememberSearchLanguage('jpn')
    rememberSearchLanguage('eng')
    rememberSearchLanguage('nan')

    expect(useSearchLanguages().recent.value).toEqual(['nan', 'eng', 'jpn'])
    expect(JSON.parse(localStorage.getItem('langmap.search.languages') ?? '[]'))
      .toEqual(['nan', 'eng', 'jpn'])
  })
})
```

- [ ] **Step 2: Run the recent-history test and verify the old six-item behavior fails**

Run:

```bash
cd web && npm test -- src/composables/useSearchLanguages.test.ts
```

Expected: FAIL because the current composable retains more than three codes.

- [ ] **Step 3: Add failing tests for pagination, count filtering, stale history, and stable grouping**

Add fixtures and assertions that force two API pages, include a zero-count language, and seed stale recent codes:

```ts
const language = (code: string, name: string, expression_count: number) => ({
  code,
  name,
  name_en: name,
  expression_count,
  locale_count: 1,
  active_ui_locale_count: 0,
})

it('loads every page, removes zero-count and stale languages, and groups recent first', async () => {
  localStorage.setItem('langmap.search.languages', JSON.stringify(['zzz', 'spa', 'eng', 'jpn']))
  resetRecentSearchLanguages({ reload: true })
  vi.mocked(listContentLanguages)
    .mockResolvedValueOnce({
      items: [language('eng', 'English', 8), language('zzz', 'Empty', 0)],
      total: 4,
      skip: 0,
      limit: 2,
      hasMore: true,
      has_more: true,
    })
    .mockResolvedValueOnce({
      items: [language('spa', 'Español', 5), language('jpn', '日本語', 3)],
      total: 4,
      skip: 2,
      limit: 2,
      hasMore: false,
      has_more: false,
    })

  const searchLanguages = useSearchLanguages()
  await searchLanguages.loadSearchLanguages({ ui_locale: 'cmn-Hant-TW' }, { pageSize: 2 })

  expect(searchLanguages.groups.value.recent.map(item => item.code)).toEqual(['spa', 'eng', 'jpn'])
  expect(searchLanguages.groups.value.alphabetical.map(item => item.code)).toEqual([])
  expect(searchLanguages.languages.value.some(item => item.code === 'zzz')).toBe(false)
  expect(searchLanguages.recent.value).toEqual(['spa', 'eng', 'jpn'])
})

it('sorts non-recent languages by display name and then code', async () => {
  vi.mocked(listContentLanguages).mockResolvedValue({
    items: [
      language('zho', '中文', 2),
      language('cmn', '中文', 4),
      language('eng', 'English', 8),
    ],
    total: 3,
    skip: 0,
    limit: 100,
    hasMore: false,
    has_more: false,
  })

  const searchLanguages = useSearchLanguages()
  await searchLanguages.loadSearchLanguages({ ui_locale: 'eng-Latn-US' })

  expect(searchLanguages.groups.value.alphabetical.map(item => item.code))
    .toEqual(['eng', 'cmn', 'zho'])
})
```

The production signature may expose the optional `{ pageSize }` only for deterministic tests; default it to `100` and do not expose unbounded page sizes to components.

- [ ] **Step 4: Implement the typed composable and preserve storage compatibility**

Replace the current module with these boundaries:

```ts
import { computed, readonly, ref } from 'vue'
import {
  listContentLanguages,
  type ContentLanguage,
  type LocaleHints,
} from '@/api/languageIdentity'

const STORAGE_KEY = 'langmap.search.languages'
const MAX_RECENT = 3
const DEFAULT_PAGE_SIZE = 100
const MAX_PAGES = 100

function readStoredRecent(): string[] {
  try {
    const parsed: unknown = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? '[]')
    return Array.isArray(parsed)
      ? [...new Set(parsed.filter((item): item is string => typeof item === 'string' && item.length > 0))].slice(0, MAX_RECENT)
      : []
  } catch {
    return []
  }
}

function persist(codes: string[]) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(codes))
  } catch {
    // Storage may be unavailable; reactive in-memory state remains usable.
  }
}

export interface SearchLanguageGroups {
  recent: ContentLanguage[]
  alphabetical: ContentLanguage[]
}

const recent = ref<string[]>(readStoredRecent())
const languages = ref<ContentLanguage[]>([])
const loading = ref(false)
const loadError = ref('')
let loadedFor = ''
let pending: Promise<void> | null = null
let pendingFor = ''

function localeKey(hints: LocaleHints): string {
  return `${hints.ui_locale ?? ''}|${hints.secondary_ui_locale ?? ''}`
}

function compareLanguages(a: ContentLanguage, b: ContentLanguage): number {
  return a.name.localeCompare(b.name) || a.code.localeCompare(b.code)
}

const groups = computed<SearchLanguageGroups>(() => {
  const byCode = new Map(languages.value.map(item => [item.code, item]))
  const recentItems = recent.value.flatMap(code => byCode.get(code) ? [byCode.get(code)!] : [])
  const recentCodes = new Set(recentItems.map(item => item.code))
  return {
    recent: recentItems,
    alphabetical: languages.value.filter(item => !recentCodes.has(item.code)).sort(compareLanguages),
  }
})
```

Implement `loadSearchLanguages` as a bounded pagination loop. Increment the offset by `page.items.length`, stop when `hasMore` is false, and also stop on an empty page. Filter `expression_count > 0`, deduplicate by code, validate stored recent codes against the resulting set, persist the cleaned three-item list, and cache by locale key. Share an in-flight Promise so TopNav and Search do not duplicate requests.

```ts
async function loadSearchLanguages(
  hints: LocaleHints = {},
  options: { pageSize?: number } = {},
): Promise<void> {
  const key = localeKey(hints)
  if (loadedFor === key) return
  if (pending && pendingFor === key) return pending
  const pageSize = options.pageSize ?? DEFAULT_PAGE_SIZE
  pendingFor = key
  pending = (async () => {
    loading.value = true
    loadError.value = ''
    try {
      const byCode = new Map<string, ContentLanguage>()
      let offset = 0
      for (let pageNumber = 0; pageNumber < MAX_PAGES; pageNumber += 1) {
        const page = await listContentLanguages({ ...hints, sort: 'alpha', limit: pageSize, offset })
        for (const item of page.items) {
          if (item.expression_count > 0) byCode.set(item.code, item)
        }
        if (page.items.length === 0 || !(page.hasMore ?? page.has_more)) break
        offset += page.items.length
      }
      languages.value = [...byCode.values()]
      const available = new Set(languages.value.map(item => item.code))
      recent.value = recent.value.filter(code => available.has(code)).slice(0, MAX_RECENT)
      persist(recent.value)
      loadedFor = key
    } catch {
      languages.value = []
      loadError.value = 'SEARCH_LANGUAGES_LOAD_FAILED'
      throw new Error(loadError.value)
    } finally {
      loading.value = false
    }
  })()
  try {
    await pending
  } finally {
    if (pendingFor === key) pending = null
  }
}
```

Implement the public helpers exactly as follows:

```ts
function isSearchLanguageAvailable(code: string): boolean {
  return languages.value.some(item => item.code === code)
}

function resolveSearchLanguage(requested = ''): string {
  if (requested && isSearchLanguageAvailable(requested)) return requested
  return recent.value.find(isSearchLanguageAvailable) ?? ''
}

export function rememberSearchLanguage(code: string) {
  if (!code) return
  recent.value = [code, ...recent.value.filter(item => item !== code)].slice(0, MAX_RECENT)
  persist(recent.value)
}

export function resetRecentSearchLanguages(options: { reload?: boolean } = {}) {
  recent.value = options.reload ? readStoredRecent() : []
  if (!options.reload) persist([])
}
```

Return readonly refs where consumers must not mutate them directly.

- [ ] **Step 5: Run the composable tests**

Run:

```bash
cd web && npm test -- src/composables/useSearchLanguages.test.ts
```

Expected: PASS, including the two-page call sequence with offsets `0` and `2`.

- [ ] **Step 6: Commit the data boundary**

```bash
git add web/src/composables/useSearchLanguages.ts web/src/composables/useSearchLanguages.test.ts
git commit -m "feat: centralize searchable language ordering"
```

---

### Task 2: Shared expression-search controls

**Files:**
- Create: `web/src/components/search/ExpressionSearchControls.vue`
- Create: `web/src/components/search/ExpressionSearchControls.test.ts`
- Modify: `web/src/locales/en.ts:11-31`
- Modify: `scripts/i18n/cmn-Hant-TW.json`
- Modify: `scripts/i18n/cmn-Hans-CN.json`
- Modify: `scripts/i18n/jpn-Jpan-JP.json`
- Modify: `scripts/i18n/spa-Latn-ES.json`

**Interfaces:**
- Consumes: `useSearchLanguages()` from Task 1 and `useLocaleParams()`.
- Produces: `ExpressionSearchControls` props `query`, `language`, `variant`, and `languageRequired`; emits `update:query`, `update:language`, and `submit`; exposes `focusSearch()` and `focusLanguage()`.

- [ ] **Step 1: Add canonical and translated messages**

Add these canonical keys under `search` in `web/src/locales/en.ts`:

```ts
chooseLanguage: 'Choose a language',
recentLanguages: 'Recent languages',
allLanguages: 'All languages',
languagesLoadFailed: 'Unable to load searchable languages',
expressionsAvailable: '{count} expressions',
```

Add the same flat keys to all four project JSON catalogs. Use these 傳承體中文 values in `cmn-Hant-TW.json`:

```json
"search.chooseLanguage": "選擇語言",
"search.recentLanguages": "最近使用",
"search.allLanguages": "所有語言",
"search.languagesLoadFailed": "無法載入可搜尋語言",
"search.expressionsAvailable": "{count} 個詞句"
```

Provide direct translations for Simplified Chinese, Japanese, and Spanish rather than leaving English fallbacks.

- [ ] **Step 2: Write the failing component test for grouped options and count visibility**

Mock `useSearchLanguages` with one recent and two alphabetical options, mount with `query="star"` and `language="eng"`, open the combobox, and assert the group headings, codes, counts, and absence of duplicates:

```ts
import { ref } from 'vue'
import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import ExpressionSearchControls from './ExpressionSearchControls.vue'

const rememberSearchLanguage = vi.fn()
const groups = ref({
  recent: [{ code: 'eng', name: 'English', name_en: 'English', expression_count: 8, locale_count: 1, active_ui_locale_count: 0 }],
  alphabetical: [
    { code: 'spa', name: 'Español', name_en: 'Spanish', expression_count: 5, locale_count: 1, active_ui_locale_count: 0 },
    { code: 'jpn', name: '日本語', name_en: 'Japanese', expression_count: 3, locale_count: 1, active_ui_locale_count: 0 },
  ],
})

vi.mock('@/composables/useSearchLanguages', () => ({
  rememberSearchLanguage,
  useSearchLanguages: () => ({
    groups,
    languages: ref([...groups.value.recent, ...groups.value.alphabetical]),
    loading: ref(false),
    loadError: ref(''),
    loadSearchLanguages: vi.fn().mockResolvedValue(undefined),
  }),
}))

function mountControls() {
  return mount(ExpressionSearchControls, {
    attachTo: document.body,
    props: { query: 'star', language: 'eng', variant: 'compact' },
  })
}

const wrapper = mount(ExpressionSearchControls, {
  props: { query: 'star', language: 'eng', variant: 'compact' },
})
await wrapper.get('[role="combobox"]').trigger('click')

expect(wrapper.text()).toContain('Recent languages')
expect(wrapper.text()).toContain('All languages')
expect(wrapper.findAll('[role="option"]')).toHaveLength(3)
expect(wrapper.get('[role="option"]').text()).toContain('English')
expect(wrapper.text()).toContain('8')
```

- [ ] **Step 3: Run the grouped-options test and verify it fails because the component is absent**

Run:

```bash
cd web && npm test -- src/components/search/ExpressionSearchControls.test.ts
```

Expected: FAIL because `ExpressionSearchControls.vue` does not exist.

- [ ] **Step 4: Add failing interaction, ARIA, and focus tests**

Cover these explicit behaviors:

```ts
it('remembers and emits a selected language', async () => {
  const wrapper = mountControls()
  await wrapper.get('[role="combobox"]').trigger('click')
  await wrapper.findAll('[role="option"]')[1].trigger('mousedown')
  expect(wrapper.emitted('update:language')?.at(-1)).toEqual(['spa'])
  expect(rememberSearchLanguage).toHaveBeenCalledWith('spa')
})

it('supports Arrow keys, Enter, and Escape with listbox ARIA state', async () => {
  const wrapper = mountControls()
  const combobox = wrapper.get('[role="combobox"]')
  await combobox.trigger('keydown', { key: 'ArrowDown' })
  expect(combobox.attributes('aria-expanded')).toBe('true')
  expect(combobox.attributes('aria-activedescendant')).toBeTruthy()
  await combobox.trigger('keydown', { key: 'Enter' })
  expect(wrapper.emitted('update:language')).toBeTruthy()
  await combobox.trigger('keydown', { key: 'Escape' })
  expect(combobox.attributes('aria-expanded')).toBe('false')
})

it('emits submit from the search input and exposes both focus targets', async () => {
  const wrapper = mountControls()
  await wrapper.get('input[type="search"]').trigger('keydown', { key: 'Enter' })
  expect(wrapper.emitted('submit')).toHaveLength(1)
  wrapper.vm.focusLanguage()
  expect(document.activeElement).toBe(wrapper.get('[role="combobox"]').element)
  wrapper.vm.focusSearch()
  expect(document.activeElement).toBe(wrapper.get('input[type="search"]').element)
})
```

- [ ] **Step 5: Implement the shared joined control**

Create a typed component contract:

```ts
const props = withDefaults(defineProps<{
  query: string
  language: string
  variant?: 'compact' | 'page'
  languageRequired?: boolean
}>(), { variant: 'compact', languageRequired: false })

const emit = defineEmits<{
  'update:query': [value: string]
  'update:language': [value: string]
  submit: []
}>()

defineExpose({
  focusSearch: () => searchInput.value?.focus(),
  focusLanguage: () => languageButton.value?.focus(),
})
```

Use a real `<button type="button" role="combobox">`, a conditional `<div role="listbox">`, non-selectable group labels, and `<button role="option">` rows. Wrap each section in `role="group"` with `aria-labelledby` pointing to its visible heading so screen readers receive the same recent/all grouping. Each row renders the localized name, canonical code, and formatted `expression_count`. The selected-language button uses the loaded name when available and falls back to the canonical code while data is loading.

Call `loadSearchLanguages(localeParams.value).catch(() => {})` on mount and when locale hints change so the composable's reactive error state is rendered without an unhandled rejection. Render `search.languagesLoadFailed` on failure, close on outside click or blur, and prevent option `mousedown` from stealing focus before selection.

Use `ChevronDown` and `Search` from `lucide-vue-next`. Do not draw icons manually.

- [ ] **Step 6: Implement compact and page styles with Atlas tokens**

Use one joined wrapper with a shared border and divider:

```css
.expression-search {
  display: grid;
  grid-template-columns: minmax(138px, 0.42fr) minmax(180px, 1fr);
  min-width: 0;
  height: 40px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.expression-search:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.expression-search-language {
  min-width: 0;
  border: 0;
  border-right: 1px solid var(--border);
  background: transparent;
}
.expression-search-input {
  min-width: 0;
  border: 0;
  outline: 0;
  background: transparent;
}
.expression-search.page { height: 48px; }
@media (max-width: 768px) {
  .expression-search {
    grid-template-columns: 1fr;
    height: auto;
    border: 0;
    background: transparent;
    gap: 8px;
  }
  .expression-search-language,
  .expression-search-query { min-height: 44px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); }
}
```

Ensure long names have `min-width: 0`, ellipsis, and a visible full accessible name. Keep dropdown option rows at least 44px high and cap dropdown height with scrolling.

- [ ] **Step 7: Run component and i18n checks**

Run:

```bash
cd web && npm test -- src/components/search/ExpressionSearchControls.test.ts
cd web && npm run i18n:check
```

Expected: both commands PASS with no missing or extra message keys.

- [ ] **Step 8: Commit the reusable control**

```bash
git add web/src/components/search/ExpressionSearchControls.vue web/src/components/search/ExpressionSearchControls.test.ts web/src/locales/en.ts scripts/i18n/cmn-Hant-TW.json scripts/i18n/cmn-Hans-CN.json scripts/i18n/jpn-Jpan-JP.json scripts/i18n/spa-Latn-ES.json
git commit -m "feat: add shared expression search controls"
```

---

### Task 3: Search page integration and URL validation

**Files:**
- Modify: `web/src/pages/Search.vue:1-245`
- Modify: `web/src/pages/Search.test.ts:1-180`

**Interfaces:**
- Consumes: `ExpressionSearchControls`, `loadSearchLanguages`, `resolveSearchLanguage`, and the existing `useSearch().search()` API.
- Produces: `/search` behavior driven by one `lang` string, with URL validation and immediate re-search after a language change.

- [ ] **Step 1: Update test fixtures to expose searchable content languages**

Replace `/language-registry/languages` fixtures with `/languages` fixtures that include `expression_count`. Add one helper:

```ts
function contentLanguage(code: string, name: string, expression_count = 1) {
  return { code, name, name_en: name, expression_count, locale_count: 1, active_ui_locale_count: 0 }
}

function mockLanguages(items: ReturnType<typeof contentLanguage>[]) {
  vi.mocked(api.get).mockImplementation((path: string) => {
    if (path === '/languages') return Promise.resolve(page(items))
    if (path === '/expressions/search') return Promise.resolve(page([expression('eng:star', 'star')]))
    throw new Error(`unexpected ${path}`)
  })
}
```

Make the common mock return `page([contentLanguage('eng', 'English', 8)])` for `/languages`, while leaving `/expressions/search` assertions unchanged.

- [ ] **Step 2: Add failing tests for URL precedence and invalid language rejection**

Add these cases:

```ts
it('prefers a valid URL language over recent history', async () => {
  rememberSearchLanguage('spa')
  mockLanguages([contentLanguage('eng', 'English', 8), contentLanguage('spa', 'Español', 5)])
  const wrapper = await mountPage('q=star&lang=eng')
  await flushPromises()
  expect(wrapper.get('[role="combobox"]').text()).toContain('English')
  expect(api.get).toHaveBeenLastCalledWith('/expressions/search', expect.objectContaining({
    params: expect.objectContaining({ lang_code: 'eng' }),
  }))
})

it('does not search with a URL language that has no expressions', async () => {
  mockLanguages([contentLanguage('eng', 'English', 8), contentLanguage('zzz', 'Empty', 0)])
  const wrapper = await mountPage('q=star&lang=zzz')
  await flushPromises()
  expect(wrapper.find('.se-lang-warn').exists()).toBe(true)
  expect(api.get).not.toHaveBeenCalledWith('/expressions/search', expect.anything())
})
```

Replace the recent-chip test with a dropdown-selection test. Open the combobox, choose Spanish, and assert that the next expression request uses `lang_code: 'spa'` and that the route query becomes `{ q: 'cat', lang: 'spa' }`.

- [ ] **Step 3: Run Search tests and verify they fail against the old controls**

Run:

```bash
cd web && npm test -- src/pages/Search.test.ts
```

Expected: FAIL because Search still mounts `LanguageSelect`, fetches registry languages, and renders recent chips.

- [ ] **Step 4: Replace page-specific controls with the shared component**

Use a single language ref:

```ts
const language = ref(typeof route.query.lang === 'string' ? route.query.lang : '')
const searchLanguages = useSearchLanguages()

function syncUrl() {
  const queryParams: Record<string, string> = {}
  const q = query.value.trim()
  if (q) queryParams.q = q
  if (language.value) queryParams.lang = language.value
  router.replace({ query: queryParams })
}
```

Initialize only after searchable languages are known:

```ts
onMounted(async () => {
  try {
    await searchLanguages.loadSearchLanguages(localeParams.value)
  } catch {
    languageMissing.value = Boolean(query.value.trim())
    return
  }
  const requested = typeof route.query.lang === 'string' ? route.query.lang : ''
  language.value = searchLanguages.resolveSearchLanguage(requested)
  if (query.value) await doSearch()
})
```

Update `doSearch()` to require `language.value`, pass it as `lang`, and stop remembering after a successful request because selection persistence now belongs to the shared control. Watch `language` instead of the old array. Validate external URL changes through `resolveSearchLanguage`; never issue an expression request for an unavailable code.

Replace the hero markup with:

```vue
<ExpressionSearchControls
  v-model:query="query"
  v-model:language="language"
  variant="page"
  :language-required="languageMissing"
  @submit="doSearch"
/>
```

Remove `SearchBar`, `LanguageSelect`, `.se-recents`, and `.se-recent`. Keep the existing warning, result count, loading, error, empty, list, and pagination behavior.

- [ ] **Step 5: Run Search page and composable regression tests**

Run:

```bash
cd web && npm test -- src/pages/Search.test.ts src/composables/useSearchLanguages.test.ts
```

Expected: PASS with no registry-language request from the Search page.

- [ ] **Step 6: Commit the Search page integration**

```bash
git add web/src/pages/Search.vue web/src/pages/Search.test.ts
git commit -m "feat: unify search page language controls"
```

---

### Task 4: Centered TopNav integration and responsive verification

**Files:**
- Create: `web/src/components/nav/TopNav.test.ts`
- Modify: `web/src/components/nav/TopNav.vue:1-310`

**Interfaces:**
- Consumes: `ExpressionSearchControls`, `loadSearchLanguages`, `resolveSearchLanguage`, Vue Router, and existing auth/localization stores.
- Produces: centered desktop search, stacked drawer search, and navigation to `/search?q=<query>&lang=<code>`.

- [ ] **Step 1: Write failing TopNav navigation and validation tests**

Mount TopNav with memory router and content-language API fixtures. Verify recent initialization, a valid submit, and missing-language focus:

```ts
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import TopNav from './TopNav.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

function contentLanguage(code: string, name: string, expression_count = 1) {
  return { code, name, name_en: name, expression_count, locale_count: 1, active_ui_locale_count: 0 }
}

async function mountNav(items: ReturnType<typeof contentLanguage>[]) {
  vi.mocked(api.get).mockImplementation((path: string) => {
    if (path === '/languages') {
      return Promise.resolve({ data: { data: { items, total: items.length, skip: 0, limit: 100, hasMore: false } } })
    }
    throw new Error(`unexpected ${path}`)
  })
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/mapping/:id', component: { template: '<p>Mapping</p>' } },
      { path: '/search', component: { template: '<p>Search</p>' } },
      { path: '/languages', component: { template: '<p>Languages</p>' } },
      { path: '/handbooks', component: { template: '<p>Handbooks</p>' } },
      { path: '/contribute', component: { template: '<p>Contribute</p>' } },
      { path: '/auth', component: { template: '<p>Auth</p>' } },
    ],
  })
  await router.push('/mapping/1')
  await router.isReady()
  return { wrapper: mount(TopNav, { attachTo: document.body, global: { plugins: [createPinia(), router] } }), router }
}

it('navigates with both query and the selected searchable language', async () => {
  const { wrapper, router } = await mountNav([contentLanguage('eng', 'English', 8)])
  await flushPromises()
  await wrapper.get('[role="combobox"]').trigger('click')
  await wrapper.get('[role="option"]').trigger('mousedown')
  await wrapper.get('input[type="search"]').setValue('star')
  await wrapper.get('form[role="search"]').trigger('submit')
  await flushPromises()
  expect(router.currentRoute.value.fullPath).toBe('/search?q=star&lang=eng')
})

it('keeps the user in place and focuses language when no language is available', async () => {
  const { wrapper, router } = await mountNav([])
  await flushPromises()
  await wrapper.get('input[type="search"]').setValue('star')
  await wrapper.get('form[role="search"]').trigger('submit')
  expect(router.currentRoute.value.path).toBe('/mapping/1')
  expect(document.activeElement).toBe(wrapper.get('[role="combobox"]').element)
  expect(wrapper.get('[role="status"]').text()).toContain('Choose a language')
})
```

Also retain a test that pressing `/` outside another input calls the shared control's `focusSearch()` and does not open the language dropdown.

- [ ] **Step 2: Run TopNav tests and verify language-aware navigation fails**

Run:

```bash
cd web && npm test -- src/components/nav/TopNav.test.ts
```

Expected: FAIL because TopNav currently has no language model or shared controls.

- [ ] **Step 3: Integrate the shared controls into desktop and drawer forms**

Add:

```ts
const searchLanguage = ref('')
const searchLanguageMissing = ref(false)
const searchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const searchLanguages = useSearchLanguages()
const localeParams = useLocaleParams()

async function initializeSearchLanguage() {
  try {
    await searchLanguages.loadSearchLanguages(localeParams.value)
    searchLanguage.value = searchLanguages.resolveSearchLanguage(searchLanguage.value)
  } catch {
    searchLanguage.value = ''
  }
}

function onSearch() {
  const q = searchQuery.value.trim()
  if (!q) return
  if (!searchLanguage.value) {
    searchLanguageMissing.value = true
    nextTick(() => searchControls.value?.focusLanguage())
    return
  }
  router.push({ path: '/search', query: { q, lang: searchLanguage.value } })
  menuOpen.value = false
}
```

Call `initializeSearchLanguage()` on mount and after locale hints change. Clear `searchLanguageMissing` when a language is selected. Replace both hand-built search inputs with `ExpressionSearchControls` and keep their surrounding forms, submit semantics, and route-based visibility.

Update `/` handling to call `searchControls.value?.focusSearch()` when the desktop controls are visible. Do not intercept `/` when focus is already in an input, textarea, select, button with `role="combobox"`, or contenteditable element.

- [ ] **Step 4: Restructure the header into left, center, and right regions**

Wrap brand and primary navigation in `.left-group`; put desktop search in `.search-center`; keep actions in `.right-group`.

Use a true-center layout when the viewport has enough space:

```css
.appbar {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(420px, 560px) minmax(0, 1fr);
  align-items: center;
}
.left-group { justify-self: start; min-width: 0; display: flex; align-items: center; gap: 12px; }
.search-center { grid-column: 2; width: 100%; min-width: 0; }
.right-group { grid-column: 3; justify-self: end; min-width: 0; }

@media (max-width: 1180px) {
  .appbar { grid-template-columns: auto minmax(320px, 1fr) auto; }
  .search-center { max-width: 440px; }
}

@media (max-width: 960px) {
  .appbar { display: flex; }
  .appnav, .search-center, .right-group { display: none; }
  .menu-toggle { display: inline-flex; width: 44px; height: 44px; }
}
```

Adjust the exact medium breakpoint only if browser verification shows overlap, and record the final numeric breakpoint in the code rather than relying on content overflow. Keep the mobile drawer controls stacked through the shared component's mobile styles.

- [ ] **Step 5: Run focused and full automated verification**

Run:

```bash
cd web && npm test -- src/components/nav/TopNav.test.ts src/components/search/ExpressionSearchControls.test.ts src/pages/Search.test.ts src/composables/useSearchLanguages.test.ts
cd web && npm run i18n:check
cd web && npm run build
```

Expected: all tests PASS, i18n catalogs are complete, and vue-tsc plus Vite build succeed.

- [ ] **Step 6: Verify desktop and mobile behavior in the browser**

With the local app running, inspect at least these widths on a mapping page and `/search`:

- `1440×900`: the joined toolbar is centered relative to the viewport; brand/nav and actions do not move or overlap.
- `1024×768`: the compact or mobile transition occurs before any overlap; both halves remain operable.
- `390×844`: drawer controls stack, every target is at least 44px, long names truncate without horizontal overflow, and the dropdown stays inside the viewport.

Exercise this flow:

1. Open the language list and confirm zero-count fixture/data languages are absent.
2. Select four different languages and confirm only the newest three remain in the recent group.
3. Submit from TopNav and confirm the URL contains both `q` and `lang`.
4. Change language on `/search` and confirm results refresh and the URL updates.
5. Reload and confirm the URL language wins over recent history.
6. Use Arrow keys, Enter, Escape, Tab, and `/`; confirm visible focus and correct listbox state.
7. Switch the interface locale and confirm names resort while the selected canonical code stays unchanged.

If a visible layout defect appears, change only `TopNav.vue` or `ExpressionSearchControls.vue`, repeat the affected viewport, then rerun the focused tests and build.

- [ ] **Step 7: Check the final diff and commit the navigation integration**

Run:

```bash
git diff --check
git status --short
```

Confirm only the files named by this plan are modified, then commit:

```bash
git add web/src/components/nav/TopNav.vue web/src/components/nav/TopNav.test.ts
git commit -m "feat: center language-aware header search"
```

---

## Final Acceptance

- All expression-search surfaces use `ExpressionSearchControls` and the same search-language composable.
- The dropdown contains every and only content language with `expression_count > 0`.
- Recent ordering is newest-first, unique, capped at three, shared across surfaces, and compatible with the old storage format.
- Remaining languages sort by localized display name, then canonical code, without duplicating recent entries.
- TopNav submits both `q` and `lang`; `/search` validates URL language before requesting results.
- Desktop is truly centered where space permits, the medium layout never overlaps, and mobile controls stack with 44px targets.
- Focus, accessible names, combobox/listbox semantics, keyboard interaction, localized errors, and loading/empty states work.
- Focused Vitest suites, `npm run i18n:check`, `npm run build`, viewport verification, and `git diff --check` all pass.
