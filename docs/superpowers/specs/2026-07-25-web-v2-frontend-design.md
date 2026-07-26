# LangMap v2 Frontend Design Spec

**Date:** 2026-07-25
**Status:** Approved
**Goal:** Build a complete Vue 3 SPA frontend for the v2 backend API, implementing all 11 prototype pages with the Atlas paper design aesthetic.

---

## 1. Tech Stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Framework | Vue 3 + Composition API + `<script setup>` | Same as v1, familiar |
| Build | Vite | Fast, standard |
| Routing | Vue Router | Same as v1 |
| State | Pinia (2 stores only) | auth + languages cache |
| Styling | Tailwind CSS + Atlas tokens | Prototype design system |
| HTTP | Axios | Interceptors for JWT |
| Icons | Lucide (or similar lightweight) | Prototype uses emoji/SVG |

**Not using:** Nuxt (SSR unnecessary), component library (prototype has custom design), i18n library (v2 is Chinese-first, i18n later).

---

## 2. Project Structure

```
web/
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── postcss.config.js
├── src/
│   ├── main.ts
│   ├── App.vue
│   ├── router.ts
│   ├── api/
│   │   └── client.ts
│   ├── composables/
│   │   ├── useExpressions.ts
│   │   ├── useHandbooks.ts
│   │   ├── useLanguages.ts
│   │   ├── useFeed.ts
│   │   └── useSearch.ts
│   ├── stores/
│   │   ├── auth.ts
│   │   └── languages.ts
│   ├── pages/
│   │   ├── HomeFeed.vue
│   │   ├── MappingDetail.vue
│   │   ├── Contribute.vue
│   │   ├── HandbookList.vue
│   │   ├── HandbookView.vue
│   │   ├── HandbookEdit.vue
│   │   ├── MapLens.vue
│   │   ├── LanguageList.vue
│   │   ├── LanguageDetail.vue
│   │   ├── Search.vue
│   │   └── Auth.vue
│   ├── components/
│   │   ├── nav/
│   │   │   ├── TopNav.vue
│   │   │   └── LangSwitcher.vue
│   │   ├── feed/
│   │   │   ├── MappingCard.vue
│   │   │   └── NewContribution.vue
│   │   ├── mapping/
│   │   │   ├── MappingGraph.vue
│   │   │   ├── MappingList.vue
│   │   │   └── VoteButton.vue
│   │   ├── expression/
│   │   │   ├── ExpressionPicker.vue
│   │   │   └── ExpressionTag.vue
│   │   ├── handbook/
│   │   │   ├── HandbookCard.vue
│   │   │   ├── SectionEditor.vue
│   │   │   └── ExpressionList.vue
│   │   ├── language/
│   │   │   └── LanguageCard.vue
│   │   └── ui/
│   │       ├── Pagination.vue
│   │       ├── SearchBar.vue
│   │       └── LoadingSpinner.vue
│   └── assets/
│       └── atlas.css
```

---

## 3. Design System (Tailwind + Atlas Tokens)

### 3.1 Color Palette

From `docs/prototype/v2/atlas2.css`:

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{vue,ts}'],
  theme: {
    extend: {
      colors: {
        parchment:  '#F5F0E8',
        'parchment-dark': '#EDE5D8',
        ink:        '#1A1A1A',
        'ink-light': '#4A4A4A',
        accent:     '#8B4513',
        'accent-light': '#A0522D',
        muted:      '#6B7280',
        highlight:  '#D4A574',
        'highlight-light': '#E8C9A0',
        success:    '#2D5016',
        error:      '#8B0000',
      },
      fontFamily: {
        serif: ['"Noto Serif"', 'Georgia', 'serif'],
        sans:  ['"Inter"', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        atlas:    '0 1px 3px rgba(0,0,0,0.08)',
        'atlas-lg': '0 4px 12px rgba(0,0,0,0.1)',
      },
      borderRadius: {
        atlas: '6px',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
    },
  },
  plugins: [],
} satisfies Config
```

### 3.2 Typography

- **Headings:** `"Noto Serif"`, font-weight 700
- **Body:** `"Inter"`, font-weight 400, line-height 1.6
- **Monospace/code:** `"JetBrains Mono"` (for expression text if needed)
- Load via Google Fonts in `index.html`

### 3.3 Base Styles

```css
/* atlas.css — global base styles */
body {
  @apply bg-parchment text-ink font-sans;
}

h1, h2, h3 {
  @apply font-serif font-bold;
}

a {
  @apply text-accent hover:text-accent-light transition-colors;
}
```

### 3.4 Component Patterns

From prototype analysis, recurring UI patterns:

- **Cards:** `bg-white rounded-atlas shadow-atlas p-4` — used for mapping cards, handbook cards, language cards
- **Pill tags:** `bg-parchment-dark rounded-full px-3 py-1 text-sm` — language tags, score badges
- **Buttons:** Primary `bg-accent text-white`, Secondary `border border-accent text-accent`
- **Input fields:** `border border-parchment-dark rounded-atlas px-3 py-2 focus:ring-2 focus:ring-highlight`
- **Vote controls:** Vertical button group with up/down arrows + score number

---

## 4. API Layer

### 4.1 Axios Client (`api/client.ts`)

```ts
import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v2',
  headers: { 'Content-Type': 'application/json' },
})

// Inject JWT token on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// Handle 401 globally
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/auth'
    }
    return Promise.reject(err)
  }
)

export default api
```

### 4.2 Composables

Each composable wraps one API resource. Pattern:

```ts
// composables/useExpressions.ts
import api from '../api/client'
import { ref } from 'vue'

export function useExpressions() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function detail(id: number) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/expressions/${id}`)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function mappingGraph(id: number, hops: 1 | 2 | 3 = 1) { ... }  // returns MappingGraphResponse
  async function search(q: string, lang?: string, limit = 10) { ... }

  return { loading, error, detail, mappingGraph, search }
}
```

### 4.3 API Endpoints Reference

| Composable | Method | Endpoint | Params |
|------------|--------|----------|--------|
| useFeed | GET | /feed/hot | limit |
| useFeed | GET | /feed/new | limit |
| useExpressions | GET | /expressions/:id | — |
| useExpressions | GET | /expressions/:id/mappings | hops | returns MappingGraphResponse
| useExpressions | GET | /expressions/search | q, lang, limit |
| useLanguages | GET | /languages | search, sort |
| useLanguages | GET | /languages/:code | — |
| useLanguages | GET | /languages/:code/expressions | sort, limit, offset |
| useHandbooks | GET | /handbooks | sort, search, limit, offset |
| useHandbooks | GET | /handbooks/:id | — |
| useHandbooks | POST | /handbooks | title, visibility, sections |
| useHandbooks | PUT | /handbooks/:id | title, visibility, sections |
| useHandbooks | DELETE | /handbooks/:id | — |
| useSearch | GET | /search/expressions | q, lang, sort, limit, offset |
| — | POST | /mappings/:id/vote | direction |
| — | POST | /contributions/batch | expressions[] |
| — | POST | /handbooks/:id/vote | direction |

---

## 5. State Management (Pinia)

Only 2 stores — everything else stays in composables.

### 5.1 Auth Store (`stores/auth.ts`)

```ts
interface AuthState {
  user: { id: number; username: string; role: string } | null
  token: string | null
}

// Actions: login(username, password), register(...), logout()
// Persisted to localStorage
```

Auth uses **v1 backend** endpoints (`/api/v1/auth/login`, `/api/v1/auth/register`) since v2 doesn't have auth endpoints yet. JWT token works for both v1 and v2 (same SECRET_KEY).

### 5.2 Languages Store (`stores/languages.ts`)

```ts
interface LanguagesState {
  languages: Array<{ code: string; name: string; expression_count: number }>
  loaded: boolean
}

// Action: fetchLanguages() — calls GET /languages, caches result
// Used by: LanguageSwitcher, expression language filters
```

---

## 6. Routing

```ts
// router.ts
const routes = [
  { path: '/',                component: () => import('./pages/HomeFeed.vue') },
  { path: '/mapping/:id',     component: () => import('./pages/MappingDetail.vue') },
  { path: '/contribute',      component: () => import('./pages/Contribute.vue') },
  { path: '/handbooks',       component: () => import('./pages/HandbookList.vue') },
  { path: '/handbook/:id',    component: () => import('./pages/HandbookView.vue') },
  { path: '/handbook/:id/edit', component: () => import('./pages/HandbookEdit.vue') },
  { path: '/map',             component: () => import('./pages/MapLens.vue') },
  { path: '/languages',       component: () => import('./pages/LanguageList.vue') },
  { path: '/language/:code',  component: () => import('./pages/LanguageDetail.vue') },
  { path: '/search',          component: () => import('./pages/Search.vue') },
  { path: '/auth',            component: () => import('./pages/Auth.vue') },
]
```

All lazy-loaded. `App.vue` provides the layout shell (TopNav + `<router-view>`).

---

## 7. Page Specifications

### 7.1 HomeFeed (`/`)

**Prototype reference:** `docs/prototype/v2/home.html`

**Layout:** Two-column. Left: hot mappings feed (larger). Right: newest contributions sidebar.

**Components:**
- `MappingCard` — displays a mapping pair (expression A ↔ expression B) with score, language tags, vote controls
- `NewContribution` — compact card showing latest batch contributions

**API calls:**
- `GET /feed/hot?limit=20` → hot mappings
- `GET /feed/new?limit=20` → newest contributions

**Interactions:**
- Click mapping card → navigate to `/mapping/:id`
- Vote on mapping → POST /mappings/:id/vote

### 7.2 MappingDetail (`/mapping/:id`)

**Prototype reference:** `docs/prototype/v2/detail.html`

**Layout:** Max-width 1280px. Desktop: two-column grid (graph + 280px inspector sidebar). Mobile (<768px): graph/list segmented toggle with bottom sheet inspector.

**Components:**
- `MappingGraph` — d3-zoom + d3-drag powered radial hierarchy graph; semantic zoom (compact/medium/full), pan, fit, node selection
- `GraphNode` — individual node with semantic zoom levels, collapse toggle, drag support
- `GraphEdges` — SVG tree edges (parent→child) and cross edges (multi-path); score-based stroke width
- `GraphToolbar` — zoom controls, hops segmented control (1/2/3), mobile more-menu for 100%/reset/expand-all/collapse-to-1
- `GraphInspector` — desktop sidebar: path from root, primary edge score, VotePill, cross-edge count, collapse/navigate actions
- `GraphMobileInspector` — mobile bottom sheet (`role="dialog"`, focus management, Escape dismiss)
- `MappingHierarchyList` — tree-structured list with depth indentation, collapse/expand, selection sync with graph
- `MappingGraphSkeleton` — loading skeleton with pulse animation

**API calls:**
- `GET /expressions/:id` → center expression detail
- `GET /expressions/:id/mappings?hops=N` → returns `MappingGraphResponse` object (nodes, edges, layer_counts, truncated)

**Response shape (graph):**
```ts
interface MappingGraphResponse {
  root_id: number
  requested_hops: 1 | 2 | 3
  resolved_hops: 0 | 1 | 2 | 3
  nodes: Array<{ expression_id: number; text: string; language_code: string; language_name: string | null; depth: number }>
  edges: Array<{ edge_id: string; source_id: number; target_id: number; score: number; depth: number }>
  layer_counts: Record<number, number>
  truncated: boolean
  omitted_count: number
}
```

**Interactions:**
- Single-click node → select (path highlight + inspector). Double-click → navigate to `/mapping/:id`
- Node drag (≥4px threshold) → position override. Reset → clear overrides + re-fit
- Graph/list bidirectional sync: list selection calls `centerOnNode` on graph; graph selection scrolls list into view
- URL state: `?hops=N&node=ID` persisted via `router.replace`; invalid node cleared
- Mobile: bottom sheet on node selection; graph/list mode toggle; 44px touch targets

### 7.3 Contribute (`/contribute`)

**Prototype reference:** `docs/prototype/v2/contribute.html`

**Layout:** Two-step wizard. Step 1: expression picker (search + add). Step 2: review clique preview + submit.

**Components:**
- `ExpressionPicker` — search box + dropdown results, "add" button
- `ExpressionTag` — removable tag for each selected expression
- Clique preview: shows N(N-1)/2 edges that will be created

**API calls:**
- `GET /expressions/search?q=...&lang=...` → picker results
- `POST /contributions/batch` → submit

**Interactions:**
- Search expressions by text + language filter
- Add/remove expressions from selection
- Live clique preview updates as expressions are added
- Submit requires ≥2 expressions + auth

### 7.4 HandbookList (`/handbooks`)

**Prototype reference:** `docs/prototype/v2/handbooks.html`

**Layout:** Grid of handbook cards.

**Components:**
- `HandbookCard` — title, author, section count, expression count, score

**API calls:**
- `GET /handbooks?sort=hot` → list

**Interactions:**
- Click card → navigate to `/handbook/:id`
- Sort toggle (hot/new)
- "Create new" button → navigate to `/handbook/new/edit`

### 7.5 HandbookView (`/handbook/:id`)

**Prototype reference:** `docs/prototype/v2/handbook-view.html`

**Layout:** Reading view. Title at top, sections in order, each section shows its expressions.

**Components:**
- `ExpressionList` — ordered list of expressions in a section

**API calls:**
- `GET /handbooks/:id` → handbook + sections + items

**Interactions:**
- Click expression → navigate to `/mapping/:id`
- Vote on handbook → POST /handbooks/:id/vote
- Edit button → navigate to `/handbook/:id/edit`

### 7.6 HandbookEdit (`/handbook/:id/edit`)

**Prototype reference:** `docs/prototype/v2/handbook-edit.html`

**Layout:** Editor with section list, drag-to-reorder, add/remove sections and expressions.

**Components:**
- `SectionEditor` — editable section title + expression picker
- `ExpressionPicker` — reuse from Contribute page

**API calls:**
- `GET /handbooks/:id` → load existing (if editing)
- `PUT /handbooks/:id` → save changes
- `POST /handbooks` → create new

**Interactions:**
- Add/remove sections
- Reorder sections (drag or up/down buttons)
- Add expressions to each section via picker
- Save → PUT/POST, redirect to view

### 7.7 MapLens (`/map`)

**Prototype reference:** `docs/prototype/v2/map-lens.html`

**Layout:** Full-screen map with pins for each language's geographic region.

**Components:**
- Map canvas (simple SVG or canvas-based, no heavy library)
- Language pins with expression counts

**API calls:**
- `GET /languages` → languages with lat/lng coordinates

**Interactions:**
- Click pin → navigate to `/language/:code`
- Hover → tooltip with language name + count

**Note:** Keep simple — SVG-based map, no Leaflet/Mapbox dependency. Prototype uses a stylized illustrated map, not a real geographic map.

### 7.8 LanguageList (`/languages`)

**Prototype reference:** `docs/prototype/v2/languages.html`

**Layout:** Grid of language cards, grouped by region.

**Components:**
- `LanguageCard` — language name, code, expression count, mapped count

**API calls:**
- `GET /languages?sort=count` → all languages

**Interactions:**
- Click card → navigate to `/language/:code`
- Search filter
- Sort toggle (count/alpha)

### 7.9 LanguageDetail (`/language/:code`)

**Prototype reference:** `docs/prototype/v2/language-detail.html`

**Layout:** Language header + expression list with mapping counts.

**Components:**
- Expression table with sort (new/alpha/hot)

**API calls:**
- `GET /languages/:code` → language detail
- `GET /languages/:code/expressions?sort=hot&limit=50` → expressions

**Interactions:**
- Sort expressions
- Click expression → navigate to `/mapping/:id`
- Infinite scroll or "load more" pagination

### 7.10 Search (`/search`)

**Prototype reference:** `docs/prototype/v2/search.html`

**Layout:** Full-width search bar at top, results grid below, language filter sidebar.

**Components:**
- `SearchBar` — large input with real-time search
- Result cards (reuse `MappingCard` style)

**API calls:**
- `GET /search/expressions?q=...&lang=...&sort=hot` → paginated results

**Interactions:**
- Real-time search (debounced 300ms)
- Language filter (multi-select)
- Sort toggle (new/alpha/hot)
- Click result → navigate to `/mapping/:id`

### 7.11 Auth (`/auth`)

**Layout:** Simple centered form. Login and register tabs.

**API calls:**
- Uses **v1** endpoints: `POST /api/v1/auth/login`, `POST /api/v1/auth/register`

**Interactions:**
- Toggle between login/register
- Store JWT token in localStorage
- Redirect to `/` on success

---

## 8. App Shell (`App.vue`)

```
┌─────────────────────────────────────────┐
│  TopNav (logo, search, auth, nav links) │
├─────────────────────────────────────────┤
│                                         │
│           <router-view />               │
│                                         │
└─────────────────────────────────────────┘
```

**TopNav links:** Home, Languages, Handbooks, Contribute, Map, Search
**TopNav right:** Auth button (login/user menu)

---

## 9. Error Handling

- **API errors:** Composables set `error` ref, pages display error message
- **401:** Axios interceptor clears token, redirects to `/auth`
- **Loading states:** Each composable exposes `loading` ref, pages show `LoadingSpinner`
- **Empty states:** Pages show "No results" / "No data" messages
- **Optimistic UI:** Vote buttons update immediately, rollback on error

---

## 10. Development Setup

```bash
cd web
npm install
npm run dev    # Vite dev server on :5173
```

Vite proxy config for API:
```ts
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': 'http://localhost:8789',  // v2 backend
    },
  },
})
```

For auth (v1), proxy also needs:
```ts
'/api/v1': 'http://localhost:8787',  // v1 backend
```

---

## 11. Build Order

Implementation will follow vertical slices — one page at a time, each page bringing its components + composables:

1. **Project scaffolding** — Vite, Tailwind, router, App shell, API client
2. **Auth** — login/register (connects to v1 backend)
3. **LanguageList + LanguageDetail** — simple CRUD pages, tests API layer
4. **HomeFeed** — core experience, MappingCard + VoteButton components
5. **MappingDetail** — MappingGraph (d3 radial hierarchy), 1-3 hops with semantic zoom and hierarchy list
6. **Search** — global search with filters
7. **Contribute** — ExpressionPicker, batch submission
8. **HandbookList + HandbookView** — handbook reading
9. **HandbookEdit** — editor with section management
10. **MapLens** — SVG map (lowest priority, can be simplified)
