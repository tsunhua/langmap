# Prototype v2 Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the Vue web_v2 implementation with the prototype/v2 design across all pages, plus switch MapLens to Leaflet.

**Architecture:** Frontend CSS/template changes for visual alignment, schema migrations for missing fields, API changes to return new data, and Leaflet integration for MapLens.

**Tech Stack:** Vue 3, Hono, D1, Leaflet, Vite

---

## Task 1: Add `name_en` column to languages table

**Files:**
- Modify: `backend_v2/schema.sql`
- Create: `backend_v2/migrations/0002_add_name_en.sql`

- [ ] **Step 1: Create migration file**

```sql
-- backend_v2/migrations/0002_add_name_en.sql
ALTER TABLE languages ADD COLUMN name_en TEXT DEFAULT NULL;
```

- [ ] **Step 2: Update schema.sql to include name_en**

In `backend_v2/schema.sql`, add `name_en TEXT DEFAULT NULL` after the `name` column in the `languages` table definition.

- [ ] **Step 3: Apply migration locally**

Run: `cd backend_v2 && npx wrangler d1 execute langmap-v2 --local --file=./migrations/0002_add_name_en.sql`

- [ ] **Step 4: Commit**

```bash
git add backend_v2/schema.sql backend_v2/migrations/0002_add_name_en.sql
git commit -m "feat: add name_en column to languages table"
```

---

## Task 2: Update languages API to return `name_en`

**Files:**
- Modify: `backend_v2/src/routes/languages.ts`

- [ ] **Step 1: Update GET /api/v2/languages query**

In `languages.ts`, the SELECT already uses `l.*`, so `name_en` will be returned automatically once the column exists. No code change needed for the list endpoint.

Verify by reading the query at lines 8-29 to confirm `l.*` is used.

- [ ] **Step 2: Update LanguageList.vue to display name_en**

In `web_v2/src/components/language/LanguageCard.vue`, add a second line showing the English name:

```html
<span class="nm">{{ name }}</span>
<span class="en" v-if="name_en">{{ name_en }}</span>
```

Add the `name_en` prop and the `.en` CSS:

```css
.lg-name .en { font-size: 11px; color: var(--muted); }
```

- [ ] **Step 3: Verify locally**

Run `npm run dev` in web_v2, navigate to languages page, confirm English names appear.

- [ ] **Step 4: Commit**

```bash
git add backend_v2/src/routes/languages.ts web_v2/src/components/language/LanguageCard.vue
git commit -m "feat: display English name in language cards"
```

---

## Task 3: Add `family` and `status_text` to languages schema

**Files:**
- Modify: `backend_v2/schema.sql`
- Create: `backend_v2/migrations/0003_add_lang_family_status.sql`

- [ ] **Step 1: Create migration**

```sql
-- backend_v2/migrations/0003_add_lang_family_status.sql
ALTER TABLE languages ADD COLUMN family TEXT DEFAULT NULL;
ALTER TABLE languages ADD COLUMN status_text TEXT DEFAULT NULL;
```

- [ ] **Step 2: Update schema.sql**

Add `family TEXT DEFAULT NULL` and `status_text TEXT DEFAULT NULL` to the languages table definition.

- [ ] **Step 3: Apply migration locally**

Run: `cd backend_v2 && npx wrangler d1 execute langmap-v2 --local --file=./migrations/0003_add_lang_family_status.sql`

- [ ] **Step 4: Commit**

```bash
git add backend_v2/schema.sql backend_v2/migrations/0003_add_lang_family_status.sql
git commit -m "feat: add family and status_text columns to languages"
```

---

## Task 4: Update LanguageDetail to show subtitle

**Files:**
- Modify: `web_v2/src/pages/LanguageDetail.vue`

- [ ] **Step 1: Add subtitle template**

After the `<h1>` in LanguageDetail.vue, add:

```html
<p class="ld-sub" v-if="subtitle">{{ subtitle }}</p>
```

- [ ] **Step 2: Add computed subtitle**

```ts
const subtitle = computed(() => {
  const parts = []
  if (lang.value?.family) parts.push(lang.value.family)
  if (lang.value?.status_text) parts.push(lang.value.status_text)
  if (lang.value?.region_name) parts.push(lang.value.region_name)
  return parts.join(' · ')
})
```

- [ ] **Step 3: Add CSS**

```css
.ld-sub { font-size: 13px; color: var(--muted); margin-top: 4px; }
```

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/pages/LanguageDetail.vue
git commit -m "feat: add language subtitle with family/status/region"
```

---

## Task 5: Update feed API to return `type` field

**Files:**
- Modify: `backend_v2/src/routes/feed.ts`

- [ ] **Step 1: Check feed/new endpoint**

Read `backend_v2/src/routes/feed.ts` lines 23-36. The endpoint already returns `type: 'mapping'` in the SELECT. Verify this is correct.

- [ ] **Step 2: Verify NewContribution.vue uses type prop**

Read `web_v2/src/components/feed/NewContribution.vue`. Currently it always shows "映射". Need to add a `type` prop and conditionally render "詞句" with `.expr` class.

- [ ] **Step 3: Update NewContribution.vue**

Add `type` prop:

```ts
defineProps<{
  id: string
  type?: string
  left_text: string
  left_lang: string
  right_text?: string
  right_lang?: string
  author?: string
  created_at?: string
}>()
```

Update template:

```html
<span :class="['new-kind', { expr: type === 'expression' }]">
  {{ type === 'expression' ? '詞句' : '映射' }}
</span>
```

- [ ] **Step 4: Add CSS for .expr variant**

In NewContribution.vue scoped styles:

```css
.new-kind.expr { color: var(--edge); border-color: color-mix(in oklch, var(--edge) 35%, var(--border)); background: color-mix(in oklch, var(--edge) 8%, var(--surface)); }
```

- [ ] **Step 5: Commit**

```bash
git add backend_v2/src/routes/feed.ts web_v2/src/components/feed/NewContribution.vue
git commit -m "feat: support expression type in feed with .expr badge"
```

---

## Task 6: Revert HomeFeed CSS to prototype

**Files:**
- Modify: `web_v2/src/pages/HomeFeed.vue`

- [ ] **Step 1: Add page padding**

Change `.feed-page` from:

```css
.feed-page { max-width: 760px; margin: 0 auto; }
```

To:

```css
.feed-page { max-width: 760px; margin: 0 auto; padding: 30px 28px 100px; }
```

- [ ] **Step 2: Revert .new-body and .new-pair**

Change `.new-body` from `flex-wrap: nowrap; overflow: hidden` back to `flex-wrap: wrap`.

Change `.new-pair` from `flex: 1 1 0; min-width: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis` back to just `font-size: 14px`.

- [ ] **Step 3: Remove sticky SearchBar**

Remove the `.home-search` section from the template (lines 43-45) and its CSS (lines 101-110).

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/pages/HomeFeed.vue
git commit -m "feat: align HomeFeed with prototype (padding, revert new-body, remove SearchBar)"
```

---

## Task 7: Add page padding to all pages

**Files:**
- Modify: `web_v2/src/pages/Search.vue`
- Modify: `web_v2/src/pages/LanguageList.vue`
- Modify: `web_v2/src/pages/LanguageDetail.vue`
- Modify: `web_v2/src/pages/HandbookList.vue`
- Modify: `web_v2/src/pages/HandbookView.vue`
- Modify: `web_v2/src/pages/HandbookEdit.vue`
- Modify: `web_v2/src/pages/Contribute.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`

- [ ] **Step 1: Add padding to each page**

For each page, find the main container CSS rule and add `padding: 30px 28px 100px`. Example for Search.vue:

```css
.se-page { max-width: 920px; margin: 0 auto; padding: 30px 28px 100px; }
```

Do the same for all pages, adjusting the class name to match each page's root element.

- [ ] **Step 2: Commit**

```bash
git add web_v2/src/pages/
git commit -m "feat: add consistent page padding across all pages"
```

---

## Task 8: Unify sort buttons to pill border style

**Files:**
- Modify: `web_v2/src/pages/Search.vue`
- Modify: `web_v2/src/pages/LanguageList.vue`
- Modify: `web_v2/src/pages/LanguageDetail.vue`

- [ ] **Step 1: Update Search.vue sort buttons**

Replace the `.btn.btn-sm` sort buttons with pill border style:

```html
<div class="se-sort">
  <button :class="{ on: sort === 'new' }" @click="sort = 'new'">最新</button>
  <button :class="{ on: sort === 'alpha' }" @click="sort = 'alpha'">字母</button>
  <button :class="{ on: sort === 'hot' }" @click="sort = 'hot'">熱門</button>
</div>
```

CSS:

```css
.se-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.se-sort button {
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase;
  border: none; background: var(--surface); color: var(--muted); cursor: pointer;
  height: 30px; padding: 0 16px; transition: background 0.15s, color 0.15s;
}
.se-sort button:hover { color: var(--fg); }
.se-sort button.on { background: var(--fg); color: var(--surface); }
```

- [ ] **Step 2: Update LanguageList.vue sort buttons**

Same pill style as above, adapt class names to `.lg-sort`.

- [ ] **Step 3: Update LanguageDetail.vue sort buttons**

Same pill style, adapt class names to `.ld-sort`.

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/pages/Search.vue web_v2/src/pages/LanguageList.vue web_v2/src/pages/LanguageDetail.vue
git commit -m "feat: unify sort buttons to pill border style across pages"
```

---

## Task 9: Update Search page title and hint

**Files:**
- Modify: `web_v2/src/pages/Search.vue`

- [ ] **Step 1: Change title**

Find the `<h1>` in Search.vue and change "搜尋" to "搜索詞句".

- [ ] **Step 2: Change hint text**

Find the hint text and change "輸入關鍵字開始搜尋" to "提示:搜索目前比對詞句文字。依翻譯(語義)搜索之後補上。"

- [ ] **Step 3: Commit**

```bash
git add web_v2/src/pages/Search.vue
git commit -m "feat: update Search page title and hint to match prototype"
```

---

## Task 10: HandbookEdit - Add expression reorder

**Files:**
- Modify: `web_v2/src/components/handbook/SectionEditor.vue`

- [ ] **Step 1: Add ▲/▼ buttons to expression rows**

In SectionEditor.vue, add up/down buttons to each expression row:

```html
<button class="he-up" @click="$emit('move-up', item.id)" title="上移">▲</button>
<button class="he-down" @click="$emit('move-down', item.id)" title="下移">▼</button>
```

Update the grid to accommodate:

```css
.he-expr { grid-template-columns: 26px 1fr auto auto auto auto; }
```

- [ ] **Step 2: Add move-up/move-down emits**

```ts
const emit = defineEmits<{
  'remove': [id: number]
  'move-up': [id: number]
  'move-down': [id: number]
}>()
```

- [ ] **Step 3: Handle reorder in HandbookEdit.vue**

In HandbookEdit.vue, add methods:

```ts
function moveExpression(sectionId: number, itemId: number, direction: 'up' | 'down') {
  const section = sections.value.find(s => s.id === sectionId)
  if (!section) return
  const idx = section.items.findIndex(i => i.id === itemId)
  if (idx < 0) return
  const newIdx = direction === 'up' ? idx - 1 : idx + 1
  if (newIdx < 0 || newIdx >= section.items.length) return
  const temp = section.items[idx]
  section.items[idx] = section.items[newIdx]
  section.items[newIdx] = temp
}
```

Wire up the events:

```html
<SectionEditor
  ...
  @move-up="(id) => moveExpression(sec.id, id, 'up')"
  @move-down="(id) => moveExpression(sec.id, id, 'down')"
/>
```

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/components/handbook/SectionEditor.vue web_v2/src/pages/HandbookEdit.vue
git commit -m "feat: add expression reorder with up/down buttons"
```

---

## Task 11: HandbookEdit - Split save into draft/publish

**Files:**
- Modify: `web_v2/src/pages/HandbookEdit.vue`
- Modify: `backend_v2/src/routes/handbooks.ts`

- [ ] **Step 1: Add `status` column to handbooks**

Create migration `backend_v2/migrations/0004_add_handbook_status.sql`:

```sql
ALTER TABLE handbooks ADD COLUMN status TEXT NOT NULL DEFAULT 'published';
```

Update schema.sql accordingly.

- [ ] **Step 2: Update backend PUT handler**

In `handbooks.ts` PUT handler (lines 146-216), read `status` from request body and include it in the UPDATE:

```ts
const { title, visibility, sections, status } = await req.json()
// ... in the UPDATE query:
await c.env.DB.prepare('UPDATE handbooks SET title = ?, visibility = ?, status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?')
  .bind(title, visibility, status || 'published', id).run()
```

- [ ] **Step 3: Update frontend save buttons**

Replace single save button with two:

```html
<div class="he-actions">
  <button class="btn" @click="save('draft')" :disabled="saving">儲存草稿</button>
  <button class="btn btn-primary" @click="save('published')" :disabled="saving">發布</button>
</div>
```

Update save function:

```ts
async function save(status: string) {
  saving.value = true
  try {
    await api.put(`/handbooks/${id}`, { ...payload, status })
    router.push(`/handbooks/${id}`)
  } finally {
    saving.value = false
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add backend_v2/migrations/0004_add_handbook_status.sql backend_v2/schema.sql backend_v2/src/routes/handbooks.ts web_v2/src/pages/HandbookEdit.vue
git commit -m "feat: split handbook save into draft and publish"
```

---

## Task 12: HandbookView - Add TOC numbering

**Files:**
- Modify: `web_v2/src/pages/HandbookView.vue`

- [ ] **Step 1: Add numbering to TOC template**

Find the TOC list and add index-based numbering:

```html
<li v-for="(sec, i) in sections" :key="sec.id">
  <a :href="'#sec-' + sec.id">
    {{ i + 1 }} · {{ sec.title }}
  </a>
</li>
```

- [ ] **Step 2: Commit**

```bash
git add web_v2/src/pages/HandbookView.vue
git commit -m "feat: add numbering to handbook TOC"
```

---

## Task 13: HandbookView - Add vote prompt text

**Files:**
- Modify: `web_v2/src/pages/HandbookView.vue`

- [ ] **Step 1: Add prompt text above VotePill**

```html
<div class="hv-vote-row">
  <span>這份手冊對你有幫助嗎？</span>
  <VotePill :id="id" target="handbook" :score="score" />
</div>
```

- [ ] **Step 2: Add CSS**

```css
.hv-vote-row { display: flex; align-items: center; gap: 10px; margin-bottom: 20px; font-size: 13px; }
```

- [ ] **Step 3: Commit**

```bash
git add web_v2/src/pages/HandbookView.vue
git commit -m "feat: add vote prompt text in handbook view"
```

---

## Task 14: Install Leaflet and create MapLens component

**Files:**
- Modify: `web_v2/package.json`
- Modify: `web_v2/src/pages/MapLens.vue`

- [ ] **Step 1: Install leaflet**

Run: `cd web_v2 && npm install leaflet && npm install -D @types/leaflet`

- [ ] **Step 2: Replace MapLens.vue with Leaflet implementation**

Replace the custom CSS map with a Leaflet map. The key changes:

```vue
<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const mapEl = ref<HTMLElement>()
let map: L.Map | null = null

const props = defineProps<{
  expressionId: string
}>()

onMounted(() => {
  if (!mapEl.value) return
  map = L.map(mapEl.value).setView([0, 0], 2)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(map)
  // Load pins from API and add markers
})

onUnmounted(() => {
  map?.remove()
})
</script>

<template>
  <div class="map-page">
    <div ref="mapEl" class="leaflet-map"></div>
  </div>
</template>

<style scoped>
.map-page { max-width: 920px; margin: 0 auto; padding: 30px 28px 100px; }
.leaflet-map { width: 100%; height: 500px; border: 1px solid var(--border); border-radius: var(--r); }
</style>
```

- [ ] **Step 3: Add markers from API data**

After loading mapping data, add markers:

```ts
function addMarkers(pins: Array<{ lat: number; lng: number; text: string; lang: string; score: number }>) {
  pins.forEach(pin => {
    const icon = L.divIcon({
      className: 'pin-marker',
      html: `<div class="pin-dot ${pin.score >= 10 ? 'high' : pin.score >= 5 ? 'mid' : 'low'}"></div>`,
      iconSize: [24, 24]
    })
    L.marker([pin.lat, pin.lng], { icon })
      .bindPopup(`<b>${pin.text}</b><br/>${pin.lang}`)
      .addTo(map!)
  })
}
```

- [ ] **Step 4: Add region count to MapLens meta**

The meta should show `{{ pins.length + 1 }} 種語言 · {{ regionCount }} 地區`. Load region count from API.

- [ ] **Step 5: Commit**

```bash
git add web_v2/package.json web_v2/package-lock.json web_v2/src/pages/MapLens.vue
git commit -m "feat: replace custom map with Leaflet in MapLens"
```

---

## Task 15: Update feed API to return region count

**Files:**
- Modify: `backend_v2/src/routes/feed.ts`

- [ ] **Step 1: Add region count to feed/hot query**

In the feed/hot query, add a subquery or JOIN to count distinct regions:

```sql
SELECT e.*, ...,
  (SELECT COUNT(DISTINCT region_code) FROM expressions WHERE id IN (e.expression_a_id, e.expression_b_id) AND region_code IS NOT NULL) as region_count
FROM expression_edges e ...
```

- [ ] **Step 2: Add region count to feed/new query**

Same approach for the feed/new endpoint.

- [ ] **Step 3: Commit**

```bash
git add backend_v2/src/routes/feed.ts
git commit -m "feat: add region count to feed endpoints"
```

---

## Execution Order

**Parallelizable:**
- Tasks 1-4 (schema + language pages) — independent
- Tasks 6-9 (CSS/template alignment) — independent
- Tasks 12-13 (HandbookView) — independent

**Sequential dependencies:**
- Task 5 depends on Task 1 (type field needs schema)
- Task 10 depends on nothing
- Task 11 depends on Task 1 (handbook status migration)
- Task 14 depends on nothing (can start immediately)
- Task 15 depends on Tasks 1-3 (schema must be in place)

**Recommended execution order:**
1. Tasks 1, 3, 14 in parallel (schema migrations + Leaflet install)
2. Tasks 2, 4, 5, 6, 7, 8, 9, 10, 12, 13 in parallel (all independent frontend/API work)
3. Tasks 11, 15 last (depend on schema)
