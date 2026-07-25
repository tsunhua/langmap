# web_v2 Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete Vue 3 SPA frontend for the v2 backend API, implementing all 11 prototype pages with the Atlas paper design aesthetic.

**Architecture:** Vue 3 + Vite + Tailwind CSS + Vue Router + Pinia. Composables for API calls, 2 Pinia stores (auth + languages). Axios client with JWT interceptors. All 11 prototype pages as lazy-loaded routes.

**Tech Stack:** Vue 3, Vite, Tailwind CSS, Vue Router, Pinia, Axios, Google Fonts (Inter, Noto Serif, IBM Plex Mono).

**前置:** Plan B 完成——v2 backend API 已在 `localhost:8789` 可用。Prototype 在 `docs/prototype/v2/`。Design spec 在 `docs/superpowers/specs/2026-07-25-web-v2-frontend-design.md`。

**Design System Reference:** `docs/prototype/v2/atlas2.css` — 完整的 Atlas paper CSS tokens 和 utility classes。Plan 中的 Tailwind config 和元件樣式都基於這個檔案。

---

## File Structure

```
web_v2/
├── index.html                    # Google Fonts import + app mount
├── package.json
├── vite.config.ts                # Dev proxy to backend
├── tailwind.config.ts            # Atlas tokens as Tailwind theme
├── postcss.config.js
├── src/
│   ├── main.ts                   # createApp + mount
│   ├── App.vue                   # Layout shell: TopNav + <router-view>
│   ├── router.ts                 # 11 routes, all lazy-loaded
│   ├── api/
│   │   └── client.ts             # Axios instance + JWT interceptors
│   ├── composables/
│   │   ├── useExpressions.ts     # detail, mappings, search
│   │   ├── useHandbooks.ts       # list, detail, CRUD, vote
│   │   ├── useLanguages.ts       # list, detail, expressions
│   │   ├── useFeed.ts            # hot, new
│   │   └── useSearch.ts          # global search
│   ├── stores/
│   │   ├── auth.ts               # user + token (persisted to localStorage)
│   │   └── languages.ts          # cached language list
│   ├── pages/                    # 11 page components
│   ├── components/
│   │   ├── nav/TopNav.vue
│   │   ├── feed/MappingCard.vue, NewContribution.vue
│   │   ├── mapping/RadialGraph.vue, MappingList.vue, VotePill.vue
│   │   ├── expression/ExpressionPicker.vue, ExpressionRow.vue, LangBadge.vue
│   │   ├── handbook/HandbookCard.vue, SectionEditor.vue
│   │   ├── language/LanguageCard.vue, LanguageSelect.vue
│   │   └── ui/SearchBar.vue, Pagination.vue, LoadingSpinner.vue, EmptyState.vue, SegControl.vue, StatBox.vue
│   └── assets/
│       └── atlas.css             # Base styles from prototype
```

---

## Task 1: Project Scaffolding

**Files:**
- Create: `web_v2/package.json`
- Create: `web_v2/index.html`
- Create: `web_v2/vite.config.ts`
- Create: `web_v2/tailwind.config.ts`
- Create: `web_v2/postcss.config.js`
- Create: `web_v2/src/main.ts`
- Create: `web_v2/src/App.vue`
- Create: `web_v2/src/router.ts`
- Create: `web_v2/src/api/client.ts`
- Create: `web_v2/src/assets/atlas.css`

- [ ] **Step 1: Init project and install dependencies**

```bash
mkdir -p web_v2/src/{api,composables,stores,pages,components/{nav,feed,mapping,expression,handbook,language,ui},assets}
cd web_v2
npm init -y
npm install vue vue-router pinia axios
npm install -D vite @vitejs/plugin-vue typescript vue-tsc tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

- [ ] **Step 2: Create `package.json` scripts**

Write `web_v2/package.json`:
```json
{
  "name": "langmap-web-v2",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.5.0",
    "vue-router": "^4.5.0",
    "pinia": "^3.0.0",
    "axios": "^1.7.0"
  },
  "devDependencies": {
    "vite": "^6.0.0",
    "@vitejs/plugin-vue": "^5.2.0",
    "typescript": "^5.7.0",
    "vue-tsc": "^2.2.0",
    "tailwindcss": "^4.0.0",
    "postcss": "^8.5.0",
    "autoprefixer": "^10.4.0"
  }
}
```

- [ ] **Step 3: Create `index.html`**

Write `web_v2/index.html`:
```html
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>LangMap</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=Inter:wght@400;500;600;700&family=Noto+Serif:wght@400;700&display=swap" rel="stylesheet" />
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

- [ ] **Step 4: Create `vite.config.ts`**

Write `web_v2/vite.config.ts`:
```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      '/api/v2': 'http://localhost:8789',
      '/api/v1': 'http://localhost:8787',
    },
  },
})
```

- [ ] **Step 5: Create `tailwind.config.ts`**

Write `web_v2/tailwind.config.ts`:
```ts
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
        'accent-soft': '#F5E6D3',
        muted:      '#6B7280',
        highlight:  '#D4A574',
        'highlight-light': '#E8C9A0',
        edge:       '#4A6FA5',
        success:    '#2D5016',
        error:      '#8B0000',
        up:         '#2D7A3A',
        down:       '#A03030',
        fold:       '#B8A88A',
      },
      fontFamily: {
        serif: ['"Noto Serif"', 'Georgia', 'serif'],
        sans:  ['"Inter"', 'system-ui', 'sans-serif'],
        mono:  ['"IBM Plex Mono"', 'monospace'],
      },
      borderRadius: {
        atlas: '4px',
      },
      boxShadow: {
        atlas:    '0 1px 3px rgba(0,0,0,0.08)',
        'atlas-lg': '0 4px 12px rgba(0,0,0,0.1)',
        'glow':   '0 0 12px rgba(139,69,19,0.3)',
      },
      height: {
        'bar': '44px',
      },
    },
  },
  plugins: [],
} satisfies Config
```

- [ ] **Step 6: Create `src/assets/atlas.css`**

Copy the core base styles from `docs/prototype/v2/atlas2.css` into `web_v2/src/assets/atlas.css`. Keep only the base/reset styles, not the page-specific ones:

```css
/* Atlas paper base styles */
* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: "Inter", system-ui, sans-serif;
  color: oklch(0.20 0.015 55);
  background: oklch(0.975 0.008 85);
  background-image: radial-gradient(circle, oklch(0.86 0.010 88) 1px, transparent 1px);
  background-size: 22px 22px;
  line-height: 1.6;
}

a { color: oklch(0.64 0.16 35); text-decoration: none; }
a:hover { color: oklch(0.55 0.16 35); }

/* Appbar */
.appbar {
  position: sticky; top: 0; z-index: 100;
  display: flex; align-items: center; gap: 16px;
  height: 44px; padding: 0 20px;
  background: oklch(0.975 0.008 85 / 0.85);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid oklch(0.88 0.008 95);
}

/* Buttons */
.btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 6px 14px; border-radius: 4px; border: 1px solid transparent;
  font-family: "IBM Plex Mono", monospace; font-size: 13px; font-weight: 500;
  cursor: pointer; transition: all 0.15s;
}
.btn-primary { background: oklch(0.64 0.16 35); color: #fff; }
.btn-primary:hover { background: oklch(0.55 0.16 35); }
.btn-ghost { border-color: oklch(0.88 0.008 95); background: transparent; }
.btn-ghost:hover { background: oklch(0.96 0.010 85); }
.btn-sm { padding: 3px 8px; font-size: 12px; }
.btn-icon { padding: 4px; width: 28px; height: 28px; justify-content: center; }

/* Page shell */
.page { max-width: 920px; margin: 0 auto; padding: 28px 28px 120px; }

/* Cards */
.card {
  background: oklch(1 0 0); border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08); padding: 16px;
}

/* Vote pill */
.vote { display: inline-flex; align-items: center; gap: 4px; }
.vote button {
  width: 28px; height: 28px; border-radius: 4px; border: 1px solid oklch(0.88 0.008 95);
  background: transparent; cursor: pointer; font-size: 14px; transition: all 0.15s;
}
.vote button:hover { background: oklch(0.96 0.010 85); }
.vote button.on.up { color: oklch(0.60 0.14 155); border-color: oklch(0.60 0.14 155); }
.vote button.on.down { color: oklch(0.60 0.17 25); border-color: oklch(0.60 0.17 25); }
.vote .score {
  font-family: "IBM Plex Mono", monospace; font-size: 13px;
  min-width: 32px; text-align: center;
}

/* Language badge */
.lang-badge {
  display: inline-block; padding: 1px 6px; border-radius: 3px;
  font-family: "IBM Plex Mono", monospace; font-size: 11px;
  background: oklch(0.96 0.010 85); color: oklch(0.52 0.010 200);
}

/* Source tag */
.src-tag {
  display: inline-block; padding: 1px 5px; border-radius: 3px;
  font-size: 11px; background: oklch(0.96 0.010 85);
}
.src-tag.auth { background: oklch(0.96 0.04 35); color: oklch(0.64 0.16 35); }
.src-tag.ai { background: oklch(0.96 0.03 245); color: oklch(0.55 0.13 245); }

/* Section header */
.nb-head {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 0; border-bottom: 1px solid oklch(0.88 0.008 95);
  font-family: "IBM Plex Mono", monospace; font-size: 13px; font-weight: 500;
}

/* Input */
input, select {
  padding: 6px 10px; border: 1px solid oklch(0.88 0.008 95); border-radius: 4px;
  font-family: "Inter", sans-serif; font-size: 14px; background: #fff;
}
input:focus, select:focus {
  outline: none; border-color: oklch(0.64 0.16 35);
  box-shadow: 0 0 0 2px oklch(0.64 0.16 35 / 0.15);
}
```

- [ ] **Step 7: Create `src/main.ts`**

```ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/atlas.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
```

- [ ] **Step 8: Create `src/App.vue`**

```vue
<script setup lang="ts">
import TopNav from './components/nav/TopNav.vue'
</script>

<template>
  <TopNav />
  <main class="page">
    <router-view />
  </main>
</template>
```

- [ ] **Step 9: Create `src/router.ts`**

```ts
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/',                  component: () => import('./pages/HomeFeed.vue') },
    { path: '/mapping/:id',       component: () => import('./pages/MappingDetail.vue') },
    { path: '/contribute',        component: () => import('./pages/Contribute.vue') },
    { path: '/handbooks',         component: () => import('./pages/HandbookList.vue') },
    { path: '/handbook/:id',      component: () => import('./pages/HandbookView.vue') },
    { path: '/handbook/:id/edit', component: () => import('./pages/HandbookEdit.vue') },
    { path: '/map',               component: () => import('./pages/MapLens.vue') },
    { path: '/languages',         component: () => import('./pages/LanguageList.vue') },
    { path: '/language/:code',    component: () => import('./pages/LanguageDetail.vue') },
    { path: '/search',            component: () => import('./pages/Search.vue') },
    { path: '/auth',              component: () => import('./pages/Auth.vue') },
  ],
})

export default router
```

- [ ] **Step 10: Create `src/api/client.ts`**

```ts
import axios from 'axios'

const api = axios.create({
  baseURL: '/api/v2',
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

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

- [ ] **Step 11: Create placeholder pages**

Create minimal placeholder files for all 11 pages so the router works. Each page is just:
```vue
<template><div><h1>Page Name</h1></div></template>
```

Create these files in `src/pages/`: `HomeFeed.vue`, `MappingDetail.vue`, `Contribute.vue`, `HandbookList.vue`, `HandbookView.vue`, `HandbookEdit.vue`, `MapLens.vue`, `LanguageList.vue`, `LanguageDetail.vue`, `Search.vue`, `Auth.vue`

- [ ] **Step 12: Create `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "preserve",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "noEmit": true,
    "paths": { "@/*": ["./src/*"] },
    "baseUrl": "."
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

Create `tsconfig.node.json`:
```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
```

Create `src/env.d.ts`:
```ts
/// <reference types="vite/client" />
declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}
```

- [ ] **Step 13: Verify dev server runs**

```bash
cd web_v2
npm install
npm run dev
# Visit http://localhost:5173 — should see "HomeFeed" placeholder
# /languages should show "LanguageList" placeholder
```

- [ ] **Step 14: Commit**

```bash
git add web_v2/
git commit -m "feat(web-v2): project scaffolding — Vite, Tailwind, router, API client, atlas.css"
```

---

## Task 2: Shared UI Components + TopNav

**Files:**
- Create: `web_v2/src/components/nav/TopNav.vue`
- Create: `web_v2/src/components/ui/SearchBar.vue`
- Create: `web_v2/src/components/ui/LoadingSpinner.vue`
- Create: `web_v2/src/components/ui/EmptyState.vue`
- Create: `web_v2/src/components/ui/SegControl.vue`
- Create: `web_v2/src/components/ui/StatBox.vue`
- Create: `web_v2/src/components/ui/Pagination.vue`
- Create: `web_v2/src/components/expression/LangBadge.vue`
- Create: `web_v2/src/components/mapping/VotePill.vue`
- Modify: `web_v2/src/App.vue`

- [ ] **Step 1: Create `TopNav.vue`**

From prototype `.appbar` structure:
```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../../stores/auth'

const route = useRoute()
const auth = useAuthStore()
const searchQuery = ref('')

function onSearch() {
  if (searchQuery.value.trim()) {
    window.location.href = `/search?q=${encodeURIComponent(searchQuery.value)}`
  }
}
</script>

<template>
  <header class="appbar">
    <router-link to="/" class="brand">
      lang<span class="em">map</span>
    </router-link>

    <nav class="appnav">
      <router-link to="/" :class="{ on: route.path === '/' }">首頁</router-link>
      <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">語言</router-link>
      <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">手冊</router-link>
      <router-link to="/search" :class="{ on: route.path === '/search' }">搜尋</router-link>
    </nav>

    <div class="top-search">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="搜尋詞句…"
        @keydown.enter="onSearch"
      />
    </div>

    <router-link to="/contribute" class="btn btn-primary btn-sm">+ 新增映射</router-link>

    <template v-if="auth.user">
      <span class="lang-switch">{{ auth.user.username }}</span>
      <button class="btn btn-ghost btn-sm" @click="auth.logout()">登出</button>
    </template>
    <router-link v-else to="/auth" class="btn btn-ghost btn-sm">登入</router-link>
  </header>
</template>

<style scoped>
.brand {
  font-family: "Noto Serif", serif;
  font-weight: 700;
  font-size: 18px;
  color: oklch(0.20 0.015 55);
  text-decoration: none;
}
.brand .em {
  font-family: "IBM Plex Mono", monospace;
  font-size: 11px;
  background: oklch(0.64 0.16 35);
  color: #fff;
  padding: 1px 4px;
  border-radius: 3px;
  margin-left: 2px;
  vertical-align: super;
}
.appnav { display: flex; gap: 12px; margin-left: 16px; }
.appnav a {
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: oklch(0.52 0.010 200);
  text-decoration: none;
  padding: 4px 0;
}
.appnav a.on { color: oklch(0.20 0.015 55); font-weight: 600; }
.top-search {
  margin-left: auto;
  position: relative;
}
.top-search input {
  width: 180px;
  height: 30px;
  padding: 0 10px;
  font-size: 13px;
  border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px;
  background: oklch(1 0 0);
}
</style>
```

- [ ] **Step 2: Create `SearchBar.vue`**

```vue
<script setup lang="ts">
const props = defineProps<{
  modelValue: string
  placeholder?: string
  large?: boolean
}>()
const emit = defineEmits<{
  'update:modelValue': [value: string]
  search: []
}>()
</script>

<template>
  <input
    type="text"
    :value="modelValue"
    :placeholder="placeholder || '搜尋…'"
    :class="['search-input', { large }]"
    @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    @keydown.enter="emit('search')"
  />
</template>

<style scoped>
.search-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px;
  font-size: 14px;
  background: #fff;
}
.search-input.large {
  height: 44px;
  font-size: 16px;
}
</style>
```

- [ ] **Step 3: Create `LoadingSpinner.vue`**

```vue
<template>
  <div class="spinner-wrap">
    <div class="spinner"></div>
  </div>
</template>

<style scoped>
.spinner-wrap { display: flex; justify-content: center; padding: 40px; }
.spinner {
  width: 24px; height: 24px;
  border: 2px solid oklch(0.88 0.008 95);
  border-top-color: oklch(0.64 0.16 35);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
```

- [ ] **Step 4: Create `EmptyState.vue`**

```vue
<script setup lang="ts">
defineProps<{
  message?: string
  actionLabel?: string
}>()
defineEmits<{ action: [] }>()
</script>

<template>
  <div class="empty">
    <p>{{ message || '暫無資料' }}</p>
    <button v-if="actionLabel" class="btn btn-ghost btn-sm" @click="emit('action')">
      {{ actionLabel }}
    </button>
  </div>
</template>

<style scoped>
.empty {
  text-align: center;
  padding: 48px 20px;
  color: oklch(0.52 0.010 200);
}
</style>
```

- [ ] **Step 5: Create `SegControl.vue`**

```vue
<script setup lang="ts">
defineProps<{
  options: Array<{ value: string; label: string }>
  modelValue: string
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <div class="seg">
    <button
      v-for="opt in options"
      :key="opt.value"
      :class="['seg-btn', { on: modelValue === opt.value }]"
      @click="emit('update:modelValue', opt.value)"
    >
      {{ opt.label }}
    </button>
  </div>
</template>

<style scoped>
.seg {
  display: inline-flex;
  border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px;
  overflow: hidden;
}
.seg-btn {
  padding: 4px 12px;
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.seg-btn.on {
  background: oklch(0.20 0.015 55);
  color: #fff;
}
</style>
```

- [ ] **Step 6: Create `StatBox.vue`**

```vue
<script setup lang="ts">
defineProps<{
  label: string
  value: string | number
}>()
</script>

<template>
  <div class="stat-box">
    <div class="stat-val">{{ value }}</div>
    <div class="stat-lbl">{{ label }}</div>
  </div>
</template>

<style scoped>
.stat-box {
  padding: 12px 16px;
  background: oklch(1 0 0);
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-align: center;
}
.stat-val {
  font-family: "IBM Plex Mono", monospace;
  font-size: 20px;
  font-weight: 600;
  color: oklch(0.64 0.16 35);
}
.stat-lbl {
  font-size: 12px;
  color: oklch(0.52 0.010 200);
  margin-top: 2px;
}
</style>
```

- [ ] **Step 7: Create `Pagination.vue`**

```vue
<script setup lang="ts">
defineProps<{
  hasMore: boolean
}>()
defineEmits<{ loadMore: [] }>()
</script>

<template>
  <div v-if="hasMore" class="pag">
    <button class="btn btn-ghost" @click="emit('loadMore')">載入更多</button>
  </div>
</template>

<style scoped>
.pag { text-align: center; padding: 20px; }
</style>
```

- [ ] **Step 8: Create `LangBadge.vue`**

```vue
<script setup lang="ts">
defineProps<{
  code: string
  score?: number
}>()
</script>

<template>
  <span class="lang-badge">
    {{ code }}<template v-if="score !== undefined"> · {{ score }}</template>
  </span>
</template>
```

- [ ] **Step 9: Create `VotePill.vue`**

From prototype `.vote` structure:
```vue
<script setup lang="ts">
import { ref } from 'vue'
import api from '../../api/client'

const props = defineProps<{
  targetId: string
  targetType: 'mapping' | 'handbook'
  score: number
  userVote?: 1 | -1 | null
}>()

const emit = defineEmits<{ 'update:score': [score: number] }>()

const currentVote = ref(props.userVote ?? null)
const localScore = ref(props.score)

async function vote(direction: 'up' | 'down') {
  const prevVote = currentVote.value
  const prevScore = localScore.value

  // Optimistic update
  if (currentVote.value === (direction === 'up' ? 1 : -1)) {
    currentVote.value = null
    localScore.value -= direction === 'up' ? 1 : -1
  } else if (currentVote.value !== null) {
    currentVote.value = direction === 'up' ? 1 : -1
    localScore.value += direction === 'up' ? 2 : -2
  } else {
    currentVote.value = direction === 'up' ? 1 : -1
    localScore.value += direction === 'up' ? 1 : -1
  }

  try {
    const endpoint = props.targetType === 'mapping'
      ? `/mappings/${props.targetId}/vote`
      : `/handbooks/${props.targetId}/vote`
    const { data } = await api.post(endpoint, { direction })
    localScore.value = data.data.score
    emit('update:score', data.data.score)
  } catch {
    currentVote.value = prevVote
    localScore.value = prevScore
  }
}
</script>

<template>
  <div class="vote">
    <button
      :class="['up', { on: currentVote === 1 }]"
      @click="vote('up')"
    >▲</button>
    <span class="score">{{ localScore }}</span>
    <button
      :class="['down', { on: currentVote === -1 }]"
      @click="vote('down')"
    >▼</button>
  </div>
</template>
```

- [ ] **Step 10: Verify**

```bash
npm run dev
# Check TopNav renders with brand, nav links, search, auth button
# Check VotePill renders with ▲ score ▼
```

- [ ] **Step 11: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): shared UI components — TopNav, SearchBar, VotePill, LangBadge, etc."
```

---

## Task 3: Auth Store + Languages Store + Composables

**Files:**
- Create: `web_v2/src/stores/auth.ts`
- Create: `web_v2/src/stores/languages.ts`
- Create: `web_v2/src/composables/useExpressions.ts`
- Create: `web_v2/src/composables/useHandbooks.ts`
- Create: `web_v2/src/composables/useLanguages.ts`
- Create: `web_v2/src/composables/useFeed.ts`
- Create: `web_v2/src/composables/useSearch.ts`
- Create: `web_v2/src/pages/Auth.vue`

- [ ] **Step 1: Create `stores/auth.ts`**

```ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

interface User {
  id: number
  username: string
  role: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))

  const isLoggedIn = computed(() => !!token.value)

  // Restore user from token on load (decode JWT payload)
  if (token.value) {
    try {
      const payload = JSON.parse(atob(token.value.split('.')[1]))
      user.value = { id: payload.id, username: payload.username, role: payload.role }
    } catch {
      token.value = null
      localStorage.removeItem('token')
    }
  }

  async function login(username: string, password: string) {
    const { data } = await axios.post('/api/v1/auth/login', { username, password })
    token.value = data.data.token
    user.value = data.data.user
    localStorage.setItem('token', data.data.token)
  }

  async function register(username: string, email: string, password: string) {
    const { data } = await axios.post('/api/v1/auth/register', { username, email, password })
    token.value = data.data.token
    user.value = data.data.user
    localStorage.setItem('token', data.data.token)
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
  }

  return { user, token, isLoggedIn, login, register, logout }
})
```

- [ ] **Step 2: Create `stores/languages.ts`**

```ts
import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../api/client'

interface Language {
  code: string
  name: string
  expression_count: number
}

export const useLanguagesStore = defineStore('languages', () => {
  const languages = ref<Language[]>([])
  const loaded = ref(false)

  async function fetchLanguages() {
    if (loaded.value) return
    const { data } = await api.get('/languages')
    languages.value = data.data
    loaded.value = true
  }

  function getName(code: string): string {
    return languages.value.find(l => l.code === code)?.name || code
  }

  return { languages, loaded, fetchLanguages, getName }
})
```

- [ ] **Step 3: Create `composables/useExpressions.ts`**

```ts
import { ref } from 'vue'
import api from '../api/client'

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

  async function mappings(id: number, hops = 1) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/expressions/${id}/mappings`, { params: { hops } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function search(q: string, lang?: string, limit = 10) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/expressions/search', { params: { q, lang, limit } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, detail, mappings, search }
}
```

- [ ] **Step 4: Create `composables/useHandbooks.ts`**

```ts
import { ref } from 'vue'
import api from '../api/client'

export function useHandbooks() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { sort?: string; search?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/handbooks', { params })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function detail(id: number) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/handbooks/${id}`)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function create(payload: { title: string; visibility?: string; sections: any[] }) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.post('/handbooks', payload)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function update(id: number, payload: any) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.put(`/handbooks/${id}`, payload)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function remove(id: number) {
    loading.value = true
    error.value = null
    try {
      await api.delete(`/handbooks/${id}`)
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, list, detail, create, update, remove }
}
```

- [ ] **Step 5: Create `composables/useLanguages.ts`**

```ts
import { ref } from 'vue'
import api from '../api/client'

export function useLanguages() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: { search?: string; sort?: string } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/languages', { params })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function detail(code: string) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/languages/${code}`)
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function expressions(code: string, params: { sort?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get(`/languages/${code}/expressions`, { params })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, list, detail, expressions }
}
```

- [ ] **Step 6: Create `composables/useFeed.ts`**

```ts
import { ref } from 'vue'
import api from '../api/client'

export function useFeed() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function hot(limit = 20) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/feed/hot', { params: { limit } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function newest(limit = 20) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/feed/new', { params: { limit } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, hot, newest }
}
```

- [ ] **Step 7: Create `composables/useSearch.ts`**

```ts
import { ref } from 'vue'
import api from '../api/client'

export function useSearch() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function search(q: string, params: { lang?: string; sort?: string; limit?: number; offset?: number } = {}) {
    loading.value = true
    error.value = null
    try {
      const { data } = await api.get('/search/expressions', { params: { q, ...params } })
      return data.data
    } catch (e: any) {
      error.value = e.response?.data?.error || 'Request failed'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, search }
}
```

- [ ] **Step 8: Create `pages/Auth.vue`**

```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()

const mode = ref<'login' | 'register'>('login')
const username = ref('')
const email = ref('')
const password = ref('')
const errorMsg = ref('')
const submitting = ref(false)

async function submit() {
  errorMsg.value = ''
  submitting.value = true
  try {
    if (mode.value === 'login') {
      await auth.login(username.value, password.value)
    } else {
      await auth.register(username.value, email.value, password.value)
    }
    router.push('/')
  } catch (e: any) {
    errorMsg.value = e.response?.data?.message || '操作失敗'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <h1>{{ mode === 'login' ? '登入' : '註冊' }}</h1>

    <form class="auth-form" @submit.prevent="submit">
      <input v-model="username" type="text" placeholder="用戶名" required />
      <input v-if="mode === 'register'" v-model="email" type="email" placeholder="電郵" required />
      <input v-model="password" type="password" placeholder="密碼" required />

      <p v-if="errorMsg" class="error">{{ errorMsg }}</p>

      <button type="submit" class="btn btn-primary" :disabled="submitting">
        {{ submitting ? '處理中…' : (mode === 'login' ? '登入' : '註冊') }}
      </button>
    </form>

    <p class="toggle">
      {{ mode === 'login' ? '沒有帳號？' : '已有帳號？' }}
      <a href="#" @click.prevent="mode = mode === 'login' ? 'register' : 'login'">
        {{ mode === 'login' ? '註冊' : '登入' }}
      </a>
    </p>
  </div>
</template>

<style scoped>
.auth-page { max-width: 360px; margin: 60px auto; }
.auth-form { display: flex; flex-direction: column; gap: 12px; margin-top: 20px; }
.auth-form input { width: 100%; }
.error { color: oklch(0.60 0.17 25); font-size: 13px; }
.toggle { text-align: center; margin-top: 16px; font-size: 14px; color: oklch(0.52 0.010 200); }
</style>
```

- [ ] **Step 9: Verify**

```bash
npm run dev
# Visit /auth — login form renders
# Visit / — TopNav shows login button
```

- [ ] **Step 10: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): stores (auth, languages) + composables + Auth page"
```

---

## Task 4: LanguageList + LanguageDetail Pages

**Files:**
- Create: `web_v2/src/pages/LanguageList.vue`
- Create: `web_v2/src/pages/LanguageDetail.vue`
- Create: `web_v2/src/components/language/LanguageCard.vue`
- Create: `web_v2/src/components/expression/ExpressionRow.vue`

- [ ] **Step 1: Create `ExpressionRow.vue`**

Reusable row for expression lists (used in language-detail, search, handbook-view):
```vue
<script setup lang="ts">
defineProps<{
  id: number
  text: string
  languageCode: string
  regionName?: string
  mappingCount?: number
  sourceType?: string
}>()
</script>

<template>
  <router-link :to="`/mapping/${id}`" class="ex-row">
    <span class="ex-tx">{{ text }}</span>
    <span class="ex-lc"><span class="lang-badge">{{ languageCode }}</span></span>
    <span class="ex-region">{{ regionName || '—' }}</span>
    <span v-if="sourceType" class="ex-src">
      <span :class="['src-tag', sourceType]">{{ sourceType }}</span>
    </span>
    <span v-if="mappingCount !== undefined" class="ex-maps">{{ mappingCount }}</span>
  </router-link>
</template>

<style scoped>
.ex-row {
  display: grid;
  grid-template-columns: 1fr 70px 100px 60px 60px;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-bottom: 1px solid oklch(0.92 0.006 90);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.ex-row:hover { background: oklch(0.97 0.008 85); }
.ex-tx { font-size: 14px; }
.ex-maps { font-family: "IBM Plex Mono", monospace; color: oklch(0.64 0.16 35); font-size: 13px; }
</style>
```

- [ ] **Step 2: Create `LanguageCard.vue`**

```vue
<script setup lang="ts">
defineProps<{
  code: string
  name: string
  expressionCount: number
  regionName?: string
}>()
</script>

<template>
  <router-link :to="`/language/${code}`" class="lg-row">
    <div class="lg-name">
      <span class="nm">{{ name }}</span>
    </div>
    <span class="lg-code lang-badge">{{ code }}</span>
    <span class="lg-geo">{{ regionName || '—' }}</span>
    <span class="lg-count">{{ expressionCount }}</span>
  </router-link>
</template>

<style scoped>
.lg-row {
  display: grid;
  grid-template-columns: 1.8fr 56px 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-bottom: 1px solid oklch(0.92 0.006 90);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.lg-row:hover { background: oklch(0.97 0.008 85); }
.lg-name .nm { font-size: 15px; }
.lg-count {
  font-family: "IBM Plex Mono", monospace;
  font-size: 14px;
  color: oklch(0.64 0.16 35);
}
</style>
```

- [ ] **Step 3: Create `LanguageList.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useLanguages } from '../composables/useLanguages'
import LanguageCard from '../components/language/LanguageCard.vue'
import SearchBar from '../components/ui/SearchBar.vue'
import StatBox from '../components/ui/StatBox.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const { loading, list } = useLanguages()

const languages = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('count')

const filtered = computed(() => {
  let result = languages.value
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter((l: any) =>
      l.name.toLowerCase().includes(q) || l.code.toLowerCase().includes(q)
    )
  }
  if (sortBy.value === 'alpha') {
    result = [...result].sort((a: any, b: any) => a.name.localeCompare(b.name))
  } else {
    result = [...result].sort((a: any, b: any) => b.expression_count - a.expression_count)
  }
  return result
})

const totalExpressions = computed(() => languages.value.reduce((s: number, l: any) => s + l.expression_count, 0))

onMounted(async () => {
  languages.value = await list()
})
</script>

<template>
  <div class="lg-page">
    <h1>語言列表</h1>
    <p style="color: oklch(0.52 0.010 200); margin: 8px 0 20px;">探索所有語言的詞句與映射</p>

    <div class="lg-stats">
      <StatBox :label="'種語言'" :value="languages.length" />
      <StatBox :label="'詞句'" :value="totalExpressions.toLocaleString()" />
    </div>

    <div class="lg-toolbar">
      <SearchBar v-model="searchQuery" placeholder="搜尋語言…" style="flex: 1;" />
      <div class="lg-sort">
        <button :class="['btn btn-sm', sortBy === 'count' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'count'">數量</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'alpha'">A–Z</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <div v-else class="lg-list">
      <LanguageCard
        v-for="lang in filtered"
        :key="lang.code"
        v-bind="lang"
      />
    </div>
  </div>
</template>

<style scoped>
.lg-page { max-width: 900px; margin: 0 auto; }
.lg-stats { display: flex; gap: 12px; margin-bottom: 20px; }
.lg-toolbar { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.lg-sort { display: flex; gap: 4px; }
.lg-list { background: oklch(1 0 0); border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
</style>
```

- [ ] **Step 4: Create `LanguageDetail.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useLanguages } from '../composables/useLanguages'
import ExpressionRow from '../components/expression/ExpressionRow.vue'
import SearchBar from '../components/ui/SearchBar.vue'
import StatBox from '../components/ui/StatBox.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'
import EmptyState from '../components/ui/EmptyState.vue'

const route = useRoute()
const code = computed(() => route.params.code as string)

const { loading, detail, expressions } = useLanguages()

const lang = ref<any>(null)
const exprs = ref<any[]>([])
const total = ref(0)
const searchQuery = ref('')
const sortBy = ref('hot')

const filtered = computed(() => {
  if (!searchQuery.value) return exprs.value
  const q = searchQuery.value.toLowerCase()
  return exprs.value.filter((e: any) => e.text.toLowerCase().includes(q))
})

onMounted(async () => {
  lang.value = await detail(code.value)
  const data = await expressions(code.value, { sort: sortBy.value, limit: 100 })
  exprs.value = data.items
  total.value = data.total
})

async function changeSort(sort: string) {
  sortBy.value = sort
  const data = await expressions(code.value, { sort, limit: 100 })
  exprs.value = data.items
  total.value = data.total
}
</script>

<template>
  <LoadingSpinner v-if="loading && !lang" />

  <div v-else-if="lang" class="ld-page">
    <router-link to="/languages" class="ld-back">← 語言</router-link>

    <div class="ld-title">
      <h1>{{ lang.name }}</h1>
      <span class="lang-badge">{{ lang.code }}</span>
    </div>

    <div class="ld-stats">
      <StatBox :label="'詞句'" :value="lang.expression_count" />
      <StatBox :label="'已映射'" :value="lang.mapped_expression_count" />
    </div>

    <div class="ld-toolbar">
      <SearchBar v-model="searchQuery" placeholder="搜尋詞句…" style="flex: 1;" />
      <div class="ld-sort">
        <button :class="['btn btn-sm', sortBy === 'hot' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('hot')">熱門</button>
        <button :class="['btn btn-sm', sortBy === 'new' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('new')">最新</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="changeSort('alpha')">字母</button>
      </div>
    </div>

    <EmptyState v-if="filtered.length === 0" message="找不到詞句" />

    <div v-else class="ld-list">
      <ExpressionRow
        v-for="expr in filtered"
        :key="expr.id"
        v-bind="expr"
      />
    </div>
  </div>
</template>

<style scoped>
.ld-page { max-width: 900px; margin: 0 auto; }
.ld-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.ld-title { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
.ld-stats { display: flex; gap: 12px; margin-bottom: 20px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.ld-sort { display: flex; gap: 4px; }
.ld-list { background: oklch(1 0 0); border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
</style>
```

- [ ] **Step 5: Verify**

```bash
npm run dev
# /languages → shows 32 languages with counts
# /language/cmn → shows expressions with mapping counts
```

- [ ] **Step 6: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): LanguageList + LanguageDetail pages"
```

---

## Task 5: HomeFeed + MappingCard

**Files:**
- Create: `web_v2/src/pages/HomeFeed.vue`
- Create: `web_v2/src/components/feed/MappingCard.vue`
- Create: `web_v2/src/components/feed/NewContribution.vue`

- [ ] **Step 1: Create `MappingCard.vue`**

From prototype `.map-card` — 3-column grid:
```vue
<script setup lang="ts">
import VotePill from '../mapping/VotePill.vue'

defineProps<{
  id: string
  aText: string
  aLang: string
  bText: string
  bLang: string
  score: number
  source?: string
}>()

function scoreClass(score: number) {
  if (score >= 10) return 's4'
  if (score >= 5) return 's3'
  if (score >= 2) return 's2'
  return 's1'
}
</script>

<template>
  <router-link :to="`/mapping/${aId || id}`" class="map-card">
    <div class="mc-node">
      <div class="mc-tx">{{ aText }}</div>
      <span class="lang-badge">{{ aLang }}</span>
    </div>
    <div class="mc-edge">
      <div :class="['mc-line', scoreClass(score)]"></div>
      <span class="mc-score">{{ score }}</span>
      <div :class="['mc-line', scoreClass(score)]"></div>
    </div>
    <div class="mc-node r">
      <div class="mc-tx">{{ bText }}</div>
      <span class="lang-badge">{{ bLang }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.map-card {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 12px;
  align-items: center;
  padding: 14px 16px;
  background: oklch(1 0 0);
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.15s;
}
.map-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.mc-node { min-width: 0; }
.mc-node.r { text-align: right; }
.mc-tx {
  font-size: 15px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.mc-edge {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}
.mc-line {
  width: 24px;
  height: 2px;
  background: oklch(0.62 0.13 245);
  border-radius: 1px;
}
.mc-line.s3, .mc-line.s4 { height: 3px; width: 32px; }
.mc-line.s4 { width: 40px; }
.mc-score {
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  color: oklch(0.52 0.010 200);
}
</style>
```

- [ ] **Step 2: Create `NewContribution.vue`**

```vue
<script setup lang="ts">
defineProps<{
  aText: string
  aLang: string
  bText: string
  bLang: string
  author?: string
  createdAt?: string
}>()
</script>

<template>
  <div class="new-row">
    <span class="new-kind">映射</span>
    <div class="new-body">
      <span class="tx">{{ aText }}</span>
      <span class="lang-badge">{{ aLang }}</span>
      <span class="arrow">↔</span>
      <span class="tx">{{ bText }}</span>
      <span class="lang-badge">{{ bLang }}</span>
    </div>
    <div class="new-meta">
      <span v-if="author">{{ author }}</span>
    </div>
  </div>
</template>

<style scoped>
.new-row {
  display: grid;
  grid-template-columns: 60px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid oklch(0.92 0.006 90);
}
.new-kind {
  font-family: "IBM Plex Mono", monospace;
  font-size: 11px;
  color: oklch(0.52 0.010 200);
}
.new-body { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.tx { font-size: 14px; }
.arrow { color: oklch(0.62 0.13 245); font-size: 13px; }
.new-meta { font-size: 12px; color: oklch(0.52 0.010 200); }
</style>
```

- [ ] **Step 3: Create `HomeFeed.vue`**

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFeed } from '../composables/useFeed'
import MappingCard from '../components/feed/MappingCard.vue'
import NewContribution from '../components/feed/NewContribution.vue'
import SegControl from '../components/ui/SegControl.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const { loading, hot, newest } = useFeed()

const hotMappings = ref<any[]>([])
const newContribs = ref<any[]>([])
const segment = ref('all')

onMounted(async () => {
  const [h, n] = await Promise.all([hot(20), newest(20)])
  hotMappings.value = h
  newContribs.value = n
})
</script>

<template>
  <div class="feed-page">
    <div class="feed-hero">
      <h1>LangMap</h1>
      <p style="color: oklch(0.52 0.010 200); margin: 8px 0 16px;">
        探索世界各地的詞句對照
      </p>
      <SegControl
        v-model="segment"
        :options="[
          { value: 'all', label: '全部' },
          { value: 'hot', label: '熱門' },
          { value: 'new', label: '最新' },
        ]"
      />
    </div>

    <LoadingSpinner v-if="loading" />

    <template v-else>
      <section v-if="segment !== 'new'" class="feed-sec">
        <div class="feed-sec-head">
          <h2>熱門映射</h2>
          <span class="hint">評分最高</span>
        </div>
        <div class="map-list">
          <MappingCard
            v-for="m in hotMappings"
            :key="m.id"
            :id="m.id"
            :a-text="m.a_text"
            :a-lang="m.a_lang"
            :b-text="m.b_text"
            :b-lang="m.b_lang"
            :score="m.score"
            :source="m.source"
          />
        </div>
      </section>

      <section v-if="segment !== 'hot'" class="feed-sec">
        <div class="feed-sec-head">
          <h2>最新貢獻</h2>
        </div>
        <div class="new-list">
          <NewContribution
            v-for="c in newContribs"
            :key="c.id"
            :a-text="c.left_text"
            :a-lang="c.left_lang"
            :b-text="c.right_text"
            :b-lang="c.right_lang"
            :author="c.author"
          />
        </div>
      </section>

      <div class="feed-cta">
        <router-link to="/contribute" class="btn btn-primary">+ 新增映射</router-link>
      </div>
    </template>
  </div>
</template>

<style scoped>
.feed-page { max-width: 760px; margin: 0 auto; }
.feed-hero { margin-bottom: 24px; }
.feed-sec { margin-bottom: 32px; }
.feed-sec-head {
  display: flex; align-items: baseline; gap: 10px;
  padding: 10px 0; border-bottom: 1px solid oklch(0.88 0.008 95);
  margin-bottom: 12px;
}
.feed-sec-head h2 { font-family: "Noto Serif", serif; font-size: 18px; }
.hint { font-size: 12px; color: oklch(0.52 0.010 200); }
.map-list { display: flex; flex-direction: column; gap: 8px; }
.new-list { background: oklch(1 0 0); border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.feed-cta { text-align: center; padding: 24px; }
</style>
```

- [ ] **Step 4: Verify**

```bash
npm run dev
# / → shows hot mappings + newest contributions
# Mapping cards show expression pairs with scores
```

- [ ] **Step 5: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): HomeFeed page with MappingCard + NewContribution"
```

---

## Task 6: MappingDetail + RadialGraph

**Files:**
- Create: `web_v2/src/pages/MappingDetail.vue`
- Create: `web_v2/src/components/mapping/RadialGraph.vue`
- Create: `web_v2/src/components/mapping/MappingList.vue`

- [ ] **Step 1: Create `RadialGraph.vue`**

SVG radial layout from prototype detail.html:
```vue
<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  anchorId: number
  anchorText: string
  anchorLang: string
  mappings: Array<{
    expression_id: number
    text: string
    language_code: string
    score: number
    hops: number
    edge_id: string | null
  }>
}>()

const emit = defineEmits<{ select: [id: number] }>()

const nodes = computed(() => {
  const cx = 400, cy = 230, r = 180
  const items = props.mappings
  return items.map((m, i) => {
    const angle = (2 * Math.PI * i) / items.length - Math.PI / 2
    return {
      ...m,
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle),
      angle,
    }
  })
})

const anchorPos = { x: 400, y: 230 }
</script>

<template>
  <div class="vb-stage">
    <svg viewBox="0 0 800 460" class="vb-svg">
      <!-- 1-hop lines -->
      <line
        v-for="n in nodes.filter(n => n.hops === 1)"
        :key="'line-' + n.expression_id"
        :x1="anchorPos.x"
        :y1="anchorPos.y"
        :x2="n.x"
        :y2="n.y"
        stroke="oklch(0.62 0.13 245)"
        :stroke-width="Math.max(1, n.score / 3)"
        class="vb-edge"
      />
      <!-- 2-hop lines (dashed) -->
      <line
        v-for="n in nodes.filter(n => n.hops === 2)"
        :key="'line2-' + n.expression_id"
        :x1="anchorPos.x"
        :y1="anchorPos.y"
        :x2="n.x"
        :y2="n.y"
        stroke="oklch(0.62 0.13 245)"
        stroke-width="1"
        stroke-dasharray="4,4"
        opacity="0.5"
        class="vb-edge-indirect"
      />
    </svg>

    <!-- Anchor node -->
    <div class="vb-node anchor" :style="{ left: anchorPos.x + 'px', top: anchorPos.y + 'px' }">
      <div class="vb-lc">{{ anchorLang }}</div>
      <div class="vb-tx">{{ anchorText }}</div>
    </div>

    <!-- Mapping nodes -->
    <div
      v-for="n in nodes"
      :key="n.expression_id"
      :class="['vb-node', { indirect: n.hops === 2 }]"
      :style="{ left: n.x + 'px', top: n.y + 'px' }"
      @click.stop="emit('select', n.expression_id)"
    >
      <div class="vb-lc">{{ n.language_code }}</div>
      <div class="vb-tx">{{ n.text }}</div>
      <div class="vb-score">{{ n.score }}</div>
    </div>
  </div>
</template>

<style scoped>
.vb-stage {
  position: relative;
  height: 460px;
  background: oklch(1 0 0);
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  overflow: hidden;
}
.vb-svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.vb-node {
  position: absolute;
  transform: translate(-50%, -50%);
  background: oklch(1 0 0);
  border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 12px;
  cursor: pointer;
  transition: box-shadow 0.15s;
  white-space: nowrap;
  z-index: 1;
}
.vb-node:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.vb-node.anchor {
  background: oklch(0.64 0.16 35);
  color: #fff;
  border-color: oklch(0.64 0.16 35);
  box-shadow: 0 0 12px rgba(139,69,19,0.3);
  font-weight: 600;
  z-index: 2;
}
.vb-node.indirect {
  opacity: 0.6;
}
.vb-lc {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  opacity: 0.7;
}
.vb-tx { font-size: 13px; }
.vb-score {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  color: oklch(0.64 0.16 35);
}
</style>
```

- [ ] **Step 2: Create `MappingList.vue`**

```vue
<script setup lang="ts">
import VotePill from './VotePill.vue'

defineProps<{
  mappings: Array<{
    edge_id: string | null
    expression_id: number
    text: string
    language_code: string
    language_name: string
    score: number
    hops: number
  }>
}>()
</script>

<template>
  <div class="mapping-list">
    <div
      v-for="m in mappings"
      :key="m.expression_id"
      class="map-row"
    >
      <router-link :to="`/mapping/${m.expression_id}`" class="map-link">
        <span class="map-text">{{ m.text }}</span>
        <span class="lang-badge">{{ m.language_code }}</span>
        <span class="map-name">{{ m.language_name }}</span>
      </router-link>
      <span v-if="m.hops === 2" class="hop-tag">間接</span>
      <VotePill
        v-if="m.edge_id"
        :target-id="m.edge_id"
        target-type="mapping"
        :score="m.score"
      />
    </div>
  </div>
</template>

<style scoped>
.mapping-list { display: flex; flex-direction: column; }
.map-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-bottom: 1px solid oklch(0.92 0.006 90);
}
.map-link {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: inherit;
  flex: 1;
}
.map-text { font-size: 14px; }
.map-name { font-size: 12px; color: oklch(0.52 0.010 200); }
.hop-tag {
  font-size: 11px;
  padding: 1px 5px;
  border-radius: 3px;
  background: oklch(0.96 0.03 245);
  color: oklch(0.55 0.13 245);
}
</style>
```

- [ ] **Step 3: Create `MappingDetail.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '../composables/useExpressions'
import RadialGraph from '../components/mapping/RadialGraph.vue'
import MappingList from '../components/mapping/MappingList.vue'
import VotePill from '../components/mapping/VotePill.vue'
import LangBadge from '../components/expression/LangBadge.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { loading, detail, mappings } = useExpressions()

const expr = ref<any>(null)
const mappingData = ref<any[]>([])
const hops = ref(1)

onMounted(async () => {
  expr.value = await detail(id.value)
  mappingData.value = await mappings(id.value, hops.value)
})

async function changeHops(h: number) {
  hops.value = h
  mappingData.value = await mappings(id.value, h)
}

function selectNode(nodeId: number) {
  router.push(`/mapping/${nodeId}`)
}
</script>

<template>
  <LoadingSpinner v-if="loading && !expr" />

  <div v-else-if="expr" class="page">
    <div class="crumbs">
      <router-link to="/languages">語言</router-link> / {{ expr.language_name }}
    </div>

    <div class="anchor-title">
      <h1>{{ expr.text }}</h1>
      <LangBadge :code="expr.language_code" />
    </div>

    <div class="anchor-meta">
      <span v-if="expr.region_name">{{ expr.region_name }}</span>
      <span v-if="expr.source_type" :class="['src-tag', expr.source_type]">{{ expr.source_type }}</span>
    </div>

    <div class="nb-head">
      <span>對照集</span>
      <span class="hint">{{ mappingData.length }} 個映射</span>
    </div>

    <RadialGraph
      :anchor-id="expr.id"
      :anchor-text="expr.text"
      :anchor-lang="expr.language_code"
      :mappings="mappingData"
      @select="selectNode"
    />

    <div class="hop-controls">
      <button
        v-for="h in [1, 2]"
        :key="h"
        :class="['btn btn-sm', hops === h ? 'btn-primary' : 'btn-ghost']"
        @click="changeHops(h)"
      >
        {{ h }}-hop
      </button>
    </div>

    <MappingList :mappings="mappingData" />
  </div>
</template>

<style scoped>
.crumbs { font-size: 13px; color: oklch(0.52 0.010 200); margin-bottom: 8px; }
.anchor-title { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.anchor-meta { display: flex; gap: 8px; margin-bottom: 16px; font-size: 13px; color: oklch(0.52 0.010 200); }
.nb-head { display: flex; align-items: baseline; gap: 8px; padding: 10px 0; border-bottom: 1px solid oklch(0.88 0.008 95); margin: 16px 0; font-family: "IBM Plex Mono", monospace; font-size: 13px; font-weight: 500; }
.hint { font-size: 12px; color: oklch(0.52 0.010 200); font-weight: 400; }
.hop-controls { display: flex; gap: 6px; margin: 16px 0 8px; }
</style>
```

- [ ] **Step 4: Verify**

```bash
npm run dev
# /mapping/15529 → radial graph + mapping list
# Click node → navigates to new mapping detail
```

- [ ] **Step 5: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): MappingDetail page with RadialGraph + MappingList"
```

---

## Task 7: Search + LanguageSelect

**Files:**
- Create: `web_v2/src/pages/Search.vue`
- Create: `web_v2/src/components/language/LanguageSelect.vue`

- [ ] **Step 1: Create `LanguageSelect.vue`**

Multi-select combobox from prototype handbooks/search:
```vue
<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useLanguagesStore } from '../../stores/languages'

const props = defineProps<{
  modelValue: string[]
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()

const store = useLanguagesStore()
const open = ref(false)
const query = ref('')
const inputRef = ref<HTMLInputElement>()

const selected = computed(() => props.modelValue)

const filtered = computed(() => {
  const q = query.value.toLowerCase()
  return store.languages
    .filter(l => !selected.value.includes(l.code))
    .filter(l => !q || l.name.toLowerCase().includes(q) || l.code.toLowerCase().includes(q))
    .slice(0, 20)
})

function add(code: string) {
  emit('update:modelValue', [...selected.value, code])
  query.value = ''
}

function remove(code: string) {
  emit('update:modelValue', selected.value.filter(c => c !== code))
}

function handleClickOutside(e: MouseEvent) {
  if (!(e.target as HTMLElement).closest('.lang-select')) {
    open.value = false
  }
}

onMounted(() => {
  store.fetchLanguages()
  document.addEventListener('click', handleClickOutside)
})
onUnmounted(() => document.removeEventListener('click', handleClickOutside))
</script>

<template>
  <div class="lang-select">
    <div class="lang-select-tagwrap" @click="inputRef?.focus()">
      <span v-for="code in selected" :key="code" class="lang-tag">
        {{ code }}
        <button @click.stop="remove(code)">✕</button>
      </span>
      <input
        ref="inputRef"
        v-model="query"
        class="lang-select-input"
        placeholder="篩選語言…"
        @focus="open = true"
      />
    </div>
    <div v-if="open && filtered.length" class="lang-select-dropdown">
      <button
        v-for="l in filtered"
        :key="l.code"
        class="lang-opt"
        @click="add(l.code)"
      >
        {{ l.name }} ({{ l.code }})
      </button>
    </div>
  </div>
</template>

<style scoped>
.lang-select { position: relative; }
.lang-select-tagwrap {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 4px 8px; border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px; background: #fff; min-height: 32px; cursor: text;
}
.lang-tag {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 1px 6px; border-radius: 3px;
  background: oklch(0.96 0.04 35); font-size: 12px;
}
.lang-tag button { border: none; background: none; cursor: pointer; font-size: 10px; color: oklch(0.52 0.010 200); }
.lang-select-input { border: none; outline: none; font-size: 13px; flex: 1; min-width: 80px; }
.lang-select-dropdown {
  position: absolute; top: 100%; left: 0; right: 0;
  max-height: 200px; overflow-y: auto;
  background: #fff; border: 1px solid oklch(0.88 0.008 95);
  border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  z-index: 50;
}
.lang-opt {
  display: block; width: 100%; text-align: left;
  padding: 6px 10px; border: none; background: none;
  font-size: 13px; cursor: pointer;
}
.lang-opt:hover { background: oklch(0.96 0.010 85); }
</style>
```

- [ ] **Step 2: Create `Search.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useSearch } from '../composables/useSearch'
import ExpressionRow from '../components/expression/ExpressionRow.vue'
import SearchBar from '../components/ui/SearchBar.vue'
import LanguageSelect from '../components/language/LanguageSelect.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'
import EmptyState from '../components/ui/EmptyState.vue'

const route = useRoute()
const { loading, search } = useSearch()

const query = ref((route.query.q as string) || '')
const langs = ref<string[]>([])
const sortBy = ref('hot')
const results = ref<any[]>([])
const total = ref(0)

async function doSearch() {
  if (!query.value.trim()) {
    results.value = []
    return
  }
  const data = await search(query.value, {
    lang: langs.value.join(','),
    sort: sortBy.value,
    limit: 50,
  })
  results.value = data.items
  total.value = data.total
}

onMounted(() => {
  if (query.value) doSearch()
})
</script>

<template>
  <div class="se-page">
    <div class="se-hero">
      <h1>搜尋</h1>
      <div class="se-qrow">
        <SearchBar v-model="query" placeholder="搜尋詞句…" :large="true" @search="doSearch" />
        <LanguageSelect v-model="langs" />
      </div>
    </div>

    <div v-if="results.length || loading" class="se-meta">
      <span class="se-count">{{ total }} 個結果</span>
      <div class="se-sort">
        <button :class="['btn btn-sm', sortBy === 'hot' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'hot'; doSearch()">熱門</button>
        <button :class="['btn btn-sm', sortBy === 'new' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'new'; doSearch()">最新</button>
        <button :class="['btn btn-sm', sortBy === 'alpha' ? 'btn-primary' : 'btn-ghost']" @click="sortBy = 'alpha'; doSearch()">字母</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="results.length === 0 && query" message="找不到結果" />

    <div v-else class="se-list">
      <ExpressionRow
        v-for="r in results"
        :key="r.id"
        v-bind="r"
      />
    </div>

    <p v-if="!query" class="se-hint">輸入關鍵字開始搜尋</p>
  </div>
</template>

<style scoped>
.se-page { max-width: 900px; margin: 0 auto; }
.se-hero { margin-bottom: 20px; }
.se-hero h1 { margin-bottom: 16px; }
.se-qrow { display: flex; gap: 12px; }
.se-qrow > :first-child { flex: 1; }
.se-meta { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.se-count { font-size: 13px; color: oklch(0.52 0.010 200); }
.se-sort { display: flex; gap: 4px; }
.se-list { background: oklch(1 0 0); border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.se-hint { text-align: center; padding: 40px; color: oklch(0.52 0.010 200); }
</style>
```

- [ ] **Step 3: Verify**

```bash
npm run dev
# /search?q=hello → search results with expression rows
# Language filter works
```

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): Search page + LanguageSelect component"
```

---

## Task 8: Contribute + ExpressionPicker + CliquePreview

**Files:**
- Create: `web_v2/src/pages/Contribute.vue`
- Create: `web_v2/src/components/expression/ExpressionPicker.vue`
- Create: `web_v2/src/components/mapping/CliquePreview.vue`

- [ ] **Step 1: Create `ExpressionPicker.vue`**

Search + select expressions for batch contribution:
```vue
<script setup lang="ts">
import { ref } from 'vue'
import { useExpressions } from '../../composables/useExpressions'

const emit = defineEmits<{ select: [expr: { id: number; text: string; language_code: string }] }>()

const { search } = useExpressions()
const query = ref('')
const results = ref<any[]>([])
const loading = ref(false)

async function doSearch() {
  if (!query.value.trim()) { results.value = []; return }
  loading.value = true
  results.value = await search(query.value, undefined, 20)
  loading.value = false
}
</script>

<template>
  <div class="picker">
    <div class="picker-search">
      <input v-model="query" placeholder="搜尋詞句…" @keydown.enter="doSearch" />
      <button class="btn btn-sm btn-ghost" @click="doSearch">搜尋</button>
    </div>
    <div class="picker-results">
      <button
        v-for="r in results"
        :key="r.id"
        class="picker-item"
        @click="emit('select', r)"
      >
        {{ r.text }} <span class="lang-badge">{{ r.language_code }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.picker { border: 1px solid oklch(0.88 0.008 95); border-radius: 4px; overflow: hidden; }
.picker-search { display: flex; gap: 6px; padding: 8px; border-bottom: 1px solid oklch(0.88 0.008 95); }
.picker-search input { flex: 1; }
.picker-results { max-height: 200px; overflow-y: auto; }
.picker-item {
  display: flex; align-items: center; gap: 8px;
  width: 100%; text-align: left; padding: 6px 10px;
  border: none; background: none; cursor: pointer; font-size: 13px;
}
.picker-item:hover { background: oklch(0.96 0.010 85); }
</style>
```

- [ ] **Step 2: Create `CliquePreview.vue`**

SVG preview of complete graph:
```vue
<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  expressions: Array<{ id: number; text: string; language_code: string }>
}>()

const edges = computed(() => {
  const n = props.expressions.length
  return n * (n - 1) / 2
})

const nodes = computed(() => {
  const n = props.expressions.length
  const cx = 110, cy = 110, r = 80
  return props.expressions.map((e, i) => ({
    ...e,
    x: cx + r * Math.cos((2 * Math.PI * i) / n - Math.PI / 2),
    y: cy + r * Math.sin((2 * Math.PI * i) / n - Math.PI / 2),
  }))
})

const allEdges = computed(() => {
  const result: Array<{ x1: number; y1: number; x2: number; y2: number }> = []
  for (let i = 0; i < nodes.value.length; i++) {
    for (let j = i + 1; j < nodes.value.length; j++) {
      result.push({
        x1: nodes.value[i].x, y1: nodes.value[i].y,
        x2: nodes.value[j].x, y2: nodes.value[j].y,
      })
    }
  }
  return result
})
</script>

<template>
  <div class="clique-card">
    <h3>完全圖預覽</h3>
    <svg viewBox="0 0 220 220" class="clique-svg">
      <line v-for="(e, i) in allEdges" :key="'e'+i"
        :x1="e.x1" :y1="e.y1" :x2="e.x2" :y2="e.y2"
        stroke="oklch(0.62 0.13 245)" stroke-width="1" opacity="0.4" />
      <circle v-for="(n, i) in nodes" :key="'n'+i"
        :cx="n.x" :cy="n.y" r="5"
        fill="oklch(0.64 0.16 35)" />
    </svg>
    <div class="clique-meta">
      {{ expressions.length }} 個詞句 → {{ edges }} 條映射
    </div>
  </div>
</template>

<style scoped>
.clique-card {
  padding: 16px;
  background: oklch(0.96 0.010 85);
  border-radius: 4px;
}
.clique-card h3 { font-size: 14px; margin-bottom: 8px; }
.clique-svg { width: 100%; max-width: 220px; display: block; margin: 0 auto; }
.clique-meta { text-align: center; font-family: "IBM Plex Mono", monospace; font-size: 13px; margin-top: 8px; }
</style>
```

- [ ] **Step 3: Create `Contribute.vue`**

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/client'
import ExpressionPicker from '../components/expression/ExpressionPicker.vue'
import CliquePreview from '../components/mapping/CliquePreview.vue'

const router = useRouter()

interface Expr {
  id: number
  text: string
  language_code: string
  region?: string
}

const expressions = ref<Expr[]>([])
const submitting = ref(false)
const error = ref('')

const edgeCount = computed(() => {
  const n = expressions.value.length
  return n * (n - 1) / 2
})

function addExpression(expr: { id: number; text: string; language_code: string }) {
  if (!expressions.value.find(e => e.id === expr.id)) {
    expressions.value.push({ ...expr })
  }
}

function removeExpression(id: number) {
  expressions.value = expressions.value.filter(e => e.id !== id)
}

async function submit() {
  if (expressions.value.length < 2) return
  submitting.value = true
  error.value = ''
  try {
    await api.post('/contributions/batch', {
      expressions: expressions.value.map(e => ({
        lang: e.language_code,
        text: e.text,
        region: e.region,
      })),
    })
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.error || '提交失敗'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="contrib-page">
    <h1>批次貢獻</h1>
    <p class="lead">新增多個詞句，系統自動建立所有配對映射</p>

    <div class="contrib-grid">
      <div class="contrib-left">
        <ExpressionPicker @select="addExpression" />

        <div v-if="expressions.length" class="ex-table">
          <div v-for="(expr, i) in expressions" :key="expr.id" class="ex-row">
            <span class="ex-num">{{ i + 1 }}</span>
            <span class="ex-text">{{ expr.text }}</span>
            <span class="lang-badge">{{ expr.language_code }}</span>
            <button class="btn btn-icon btn-ghost" @click="removeExpression(expr.id)">✕</button>
          </div>
        </div>

        <div class="ex-counter">
          {{ expressions.length }} 個詞句 → {{ edgeCount }} 條直接映射 · 完全圖
        </div>

        <p v-if="error" class="error">{{ error }}</p>

        <div class="ex-actions">
          <button
            class="btn btn-primary"
            :disabled="expressions.length < 2 || submitting"
            @click="submit"
          >
            {{ submitting ? '提交中…' : '提交映射' }}
          </button>
        </div>
      </div>

      <div class="contrib-right">
        <CliquePreview :expressions="expressions" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.contrib-page { max-width: 900px; margin: 0 auto; }
.lead { color: oklch(0.52 0.010 200); margin: 8px 0 20px; }
.contrib-grid { display: grid; grid-template-columns: 1fr 260px; gap: 20px; }
.contrib-left { display: flex; flex-direction: column; gap: 16px; }
.contrib-right { position: sticky; top: 60px; align-self: start; }
.ex-table { background: oklch(1 0 0); border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.ex-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid oklch(0.92 0.006 90); }
.ex-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: oklch(0.52 0.010 200); width: 24px; }
.ex-text { flex: 1; font-size: 14px; }
.ex-counter { font-family: "IBM Plex Mono", monospace; font-size: 13px; color: oklch(0.52 0.010 200); }
.ex-actions { display: flex; gap: 8px; }
.error { color: oklch(0.60 0.17 25); font-size: 13px; }
</style>
```

- [ ] **Step 4: Verify**

```bash
npm run dev
# /contribute → search expressions, add 2+, see clique preview, submit
```

- [ ] **Step 5: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): Contribute page with ExpressionPicker + CliquePreview"
```

---

## Task 9: HandbookList + HandbookView

**Files:**
- Create: `web_v2/src/pages/HandbookList.vue`
- Create: `web_v2/src/pages/HandbookView.vue`
- Create: `web_v2/src/components/handbook/HandbookCard.vue`

- [ ] **Step 1: Create `HandbookCard.vue`**

```vue
<script setup lang="ts">
defineProps<{
  id: number
  title: string
  author?: string
  sectionCount: number
  expressionCount: number
  score: number
}>()
</script>

<template>
  <router-link :to="`/handbook/${id}`" class="hb-card">
    <h3>{{ title }}</h3>
    <div class="hb-card-meta">{{ sectionCount }} 章 · {{ expressionCount }} 詞句</div>
    <div class="hb-card-foot">
      <span v-if="author" class="hb-author">{{ author }}</span>
      <span class="hb-score">★ {{ score }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.hb-card {
  display: flex; flex-direction: column; gap: 8px;
  padding: 16px; background: oklch(1 0 0);
  border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-decoration: none; color: inherit; transition: box-shadow 0.15s;
}
.hb-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.hb-card h3 { font-size: 15px; font-family: "Noto Serif", serif; }
.hb-card-meta { font-size: 13px; color: oklch(0.52 0.010 200); }
.hb-card-foot { display: flex; justify-content: space-between; font-size: 12px; color: oklch(0.52 0.010 200); margin-top: auto; }
.hb-score { font-family: "IBM Plex Mono", monospace; color: oklch(0.64 0.16 35); }
</style>
```

- [ ] **Step 2: Create `HandbookList.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useHandbooks } from '../composables/useHandbooks'
import HandbookCard from '../components/handbook/HandbookCard.vue'
import SearchBar from '../components/ui/SearchBar.vue'
import SegControl from '../components/ui/SegControl.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const { loading, list } = useHandbooks()

const handbooks = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('new')

const filtered = computed(() => {
  if (!searchQuery.value) return handbooks.value
  const q = searchQuery.value.toLowerCase()
  return handbooks.value.filter((h: any) => h.title.toLowerCase().includes(q))
})

onMounted(async () => {
  const data = await list({ sort: sortBy.value, limit: 50 })
  handbooks.value = data.items
})

async function changeSort(sort: string) {
  sortBy.value = sort
  const data = await list({ sort, limit: 50 })
  handbooks.value = data.items
}
</script>

<template>
  <div class="hb-page">
    <div class="hb-head">
      <h1>手冊</h1>
      <router-link to="/handbook/new/edit" class="btn btn-primary btn-sm">新建手冊</router-link>
    </div>

    <div class="hb-toolbar">
      <SegControl
        v-model="sortBy"
        :options="[{ value: 'new', label: '最新' }, { value: 'hot', label: '熱門' }]"
        @update:model-value="changeSort"
      />
      <SearchBar v-model="searchQuery" placeholder="搜尋手冊…" style="max-width: 300px;" />
    </div>

    <LoadingSpinner v-if="loading" />

    <div v-else class="hb-grid">
      <HandbookCard
        v-for="hb in filtered"
        :key="hb.id"
        :id="hb.id"
        :title="hb.title"
        :author="hb.author_username"
        :section-count="hb.section_count"
        :expression-count="hb.expression_count"
        :score="hb.score"
      />
    </div>
  </div>
</template>

<style scoped>
.hb-page { max-width: 1000px; margin: 0 auto; }
.hb-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.hb-toolbar { display: flex; gap: 12px; align-items: center; margin-bottom: 20px; }
.hb-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(290px, 1fr)); gap: 12px; }
</style>
```

- [ ] **Step 3: Create `HandbookView.vue`**

```vue
<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { useHandbooks } from '../composables/useHandbooks'
import VotePill from '../components/mapping/VotePill.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const route = useRoute()
const id = computed(() => parseInt(route.params.id as string))

const { loading, detail } = useHandbooks()

const hb = ref<any>(null)

onMounted(async () => {
  hb.value = await detail(id.value)
})
</script>

<template>
  <LoadingSpinner v-if="loading && !hb" />

  <div v-else-if="hb" class="hv-layout">
    <aside class="hv-toc">
      <div class="hv-toc-label">目錄</div>
      <a v-for="(sec, i) in hb.sections" :key="sec.id" :href="`#sec-${i}`">
        {{ sec.title || `章節 ${i + 1}` }}
      </a>
    </aside>

    <main class="hv-content">
      <router-link to="/handbooks" class="hv-back">← 手冊列表</router-link>
      <h1>{{ hb.title }}</h1>
      <div class="hv-meta">
        <span v-if="hb.author_username">{{ hb.author_username }}</span>
        <span v-if="hb.visibility">{{ hb.visibility }}</span>
      </div>

      <div class="hv-vote-row">
        <VotePill :target-id="String(hb.id)" target-type="handbook" :score="hb.score" />
      </div>

      <section v-for="(sec, i) in hb.sections" :key="sec.id" :id="`sec-${i}`" class="hv-section">
        <div class="hv-sec-head">
          <span class="hv-sec-num">{{ i + 1 }}</span>
          <h2>{{ sec.title || `章節 ${i + 1}` }}</h2>
        </div>
        <ol v-if="sec.expressions?.length" class="hb-expr-list">
          <li v-for="(expr, j) in sec.expressions" :key="expr.expression_id">
            <router-link :to="`/mapping/${expr.expression_id}`" class="hb-expr">
              <span class="hb-num">{{ j + 1 }}</span>
              <span class="hb-tx">{{ expr.text }}</span>
              <span class="lang-badge">{{ expr.language_code }}</span>
              <span class="hb-go">→</span>
            </router-link>
          </li>
        </ol>
      </section>

      <router-link :to="`/handbook/${id}/edit`" class="btn btn-ghost" style="margin-top: 20px;">
        編輯手冊
      </router-link>
    </main>
  </div>
</template>

<style scoped>
.hv-layout { display: grid; grid-template-columns: 220px 1fr; gap: 24px; max-width: 1000px; margin: 0 auto; }
.hv-toc { position: sticky; top: 60px; align-self: start; }
.hv-toc-label { font-family: "IBM Plex Mono", monospace; font-size: 11px; text-transform: uppercase; color: oklch(0.52 0.010 200); margin-bottom: 8px; }
.hv-toc a { display: block; padding: 4px 0; font-size: 13px; color: oklch(0.52 0.010 200); text-decoration: none; }
.hv-toc a:hover { color: oklch(0.64 0.16 35); }
.hv-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.hv-meta { display: flex; gap: 10px; font-size: 13px; color: oklch(0.52 0.010 200); margin: 8px 0 16px; }
.hv-vote-row { margin-bottom: 20px; }
.hv-section { margin-bottom: 24px; }
.hv-sec-head { display: flex; align-items: center; gap: 8px; padding: 8px 0; border-bottom: 1px solid oklch(0.88 0.008 95); }
.hv-sec-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: oklch(0.52 0.010 200); }
.hb-expr-list { list-style: none; padding: 0; }
.hb-expr {
  display: grid; grid-template-columns: 26px 1fr 56px 16px;
  align-items: center; gap: 8px; padding: 6px 8px;
  text-decoration: none; color: inherit; border-bottom: 1px solid oklch(0.94 0.004 90);
}
.hb-expr:hover { background: oklch(0.97 0.008 85); }
.hb-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: oklch(0.52 0.010 200); }
.hb-go { color: oklch(0.64 0.16 35); }
</style>
```

- [ ] **Step 4: Verify**

```bash
npm run dev
# /handbooks → grid of handbook cards
# /handbook/1539253276 → TOC + sections + expressions
```

- [ ] **Step 5: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): HandbookList + HandbookView pages"
```

---

## Task 10: HandbookEdit

**Files:**
- Create: `web_v2/src/pages/HandbookEdit.vue`
- Create: `web_v2/src/components/handbook/SectionEditor.vue`

- [ ] **Step 1: Create `SectionEditor.vue`**

```vue
<script setup lang="ts">
import { ref } from 'vue'
import ExpressionPicker from '../expression/ExpressionPicker.vue'

const props = defineProps<{
  title: string
  expressions: Array<{ id: number; text: string; language_code: string; position: number }>
  index: number
}>()

const emit = defineEmits<{
  'update:title': [title: string]
  'remove': []
  'move-up': []
  'move-down': []
  'add-expression': [expr: any]
  'remove-expression': [id: number]
}>()

const showPicker = ref(false)
</script>

<template>
  <div class="he-section">
    <div class="he-sec-head">
      <span class="he-sec-num">§{{ index + 1 }}</span>
      <input
        :value="title"
        class="he-sec-title"
        placeholder="章節標題"
        @input="emit('update:title', ($event.target as HTMLInputElement).value)"
      />
      <div class="he-sec-actions">
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('move-up')" title="上移">▲</button>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('move-down')" title="下移">▼</button>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('remove')" title="刪除">✕</button>
      </div>
    </div>

    <div class="he-expr-list">
      <div v-for="(expr, j) in expressions" :key="expr.id" class="he-expr">
        <span class="he-expr-num">{{ String(j + 1).padStart(2, '0') }}</span>
        <span class="he-expr-tx">{{ expr.text }}</span>
        <span class="lang-badge">{{ expr.language_code }}</span>
        <button class="btn btn-icon btn-ghost btn-sm" @click="emit('remove-expression', expr.id)">✕</button>
      </div>
    </div>

    <button class="btn btn-ghost btn-sm" @click="showPicker = !showPicker">
      {{ showPicker ? '收起' : '+ 新增詞句' }}
    </button>

    <ExpressionPicker v-if="showPicker" @select="emit('add-expression', $event); showPicker = false" />
  </div>
</template>

<style scoped>
.he-section { border: 1px solid oklch(0.88 0.008 95); border-radius: 4px; padding: 12px; margin-bottom: 12px; }
.he-sec-head { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.he-sec-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: oklch(0.52 0.010 200); }
.he-sec-title { flex: 1; font-size: 15px; font-weight: 500; border: none; border-bottom: 1px solid oklch(0.88 0.008 95); padding: 4px 0; }
.he-sec-actions { display: flex; gap: 2px; }
.he-expr { display: flex; align-items: center; gap: 8px; padding: 4px 8px; font-size: 13px; }
.he-expr-num { font-family: "IBM Plex Mono", monospace; font-size: 11px; color: oklch(0.52 0.010 200); width: 24px; }
.he-expr-tx { flex: 1; }
</style>
```

- [ ] **Step 2: Create `HandbookEdit.vue`**

```vue
<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHandbooks } from '../composables/useHandbooks'
import SectionEditor from '../components/handbook/SectionEditor.vue'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const route = useRoute()
const router = useRouter()
const { loading, detail, create, update } = useHandbooks()

const isNew = computed(() => route.params.id === 'new')
const id = computed(() => parseInt(route.params.id as string))

const title = ref('')
const visibility = ref('public')
const sections = ref<Array<{
  title: string
  expressions: Array<{ id: number; text: string; language_code: string; position: number }>
}>>([])
const saving = ref(false)

onMounted(async () => {
  if (!isNew.value) {
    const hb = await detail(id.value)
    title.value = hb.title
    visibility.value = hb.visibility
    sections.value = hb.sections.map((s: any) => ({
      title: s.title || '',
      expressions: s.expressions || [],
    }))
  }
})

function addSection() {
  sections.value.push({ title: '', expressions: [] })
}

function removeSection(i: number) {
  sections.value.splice(i, 1)
}

function moveSection(i: number, dir: -1 | 1) {
  const j = i + dir
  if (j < 0 || j >= sections.value.length) return
  const temp = sections.value[i]
  sections.value[i] = sections.value[j]
  sections.value[j] = temp
}

function addExprToSection(i: number, expr: any) {
  if (!sections.value[i].expressions.find(e => e.id === expr.id)) {
    sections.value[i].expressions.push({ ...expr, position: sections.value[i].expressions.length })
  }
}

function removeExprFromSection(i: number, exprId: number) {
  sections.value[i].expressions = sections.value[i].expressions.filter(e => e.id !== exprId)
}

async function save() {
  saving.value = true
  try {
    const payload = {
      title: title.value,
      visibility: visibility.value,
      sections: sections.value.map(s => ({
        title: s.title,
        expressionIds: s.expressions.map(e => e.id),
      })),
    }
    if (isNew.value) {
      const result = await create(payload)
      router.push(`/handbook/${result.id}`)
    } else {
      await update(id.value, payload)
      router.push(`/handbook/${id.value}`)
    }
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <LoadingSpinner v-if="loading && !isNew" />

  <div v-else class="he-page">
    <router-link to="/handbooks" class="he-back">← 手冊列表</router-link>

    <div class="he-head">
      <input v-model="title" class="he-title" placeholder="手冊標題" />
      <select v-model="visibility" class="he-vis">
        <option value="public">公開</option>
        <option value="private">私有</option>
      </select>
    </div>

    <div class="he-actions">
      <button class="btn btn-primary" :disabled="saving || !title" @click="save">
        {{ saving ? '儲存中…' : '儲存' }}
      </button>
    </div>

    <SectionEditor
      v-for="(sec, i) in sections"
      :key="i"
      :title="sec.title"
      :expressions="sec.expressions"
      :index="i"
      @update:title="sec.title = $event"
      @remove="removeSection(i)"
      @move-up="moveSection(i, -1)"
      @move-down="moveSection(i, 1)"
      @add-expression="addExprToSection(i, $event)"
      @remove-expression="removeExprFromSection(i, $event)"
    />

    <button class="btn btn-ghost" @click="addSection">＋ 新增章節</button>
  </div>
</template>

<style scoped>
.he-page { max-width: 760px; margin: 0 auto; }
.he-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.he-head { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.he-title { flex: 1; font-size: 20px; font-family: "Noto Serif", serif; font-weight: 700; padding: 8px; border: 1px solid oklch(0.88 0.008 95); border-radius: 4px; }
.he-vis { padding: 8px; }
.he-actions { margin-bottom: 20px; }
</style>
```

- [ ] **Step 3: Verify**

```bash
npm run dev
# /handbook/new/edit → create new handbook
# /handbook/1539253276/edit → edit existing
```

- [ ] **Step 4: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): HandbookEdit page with SectionEditor"
```

---

## Task 11: MapLens

**Files:**
- Create: `web_v2/src/pages/MapLens.vue`

- [ ] **Step 1: Create `MapLens.vue`**

Simplified SVG map from prototype map-lens.html:
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useLanguages } from '../composables/useLanguages'
import LoadingSpinner from '../components/ui/LoadingSpinner.vue'

const { loading, list } = useLanguages()

const languages = ref<any[]>([])
const activePin = ref<string | null>(null)

onMounted(async () => {
  const all = await list()
  languages.value = all.filter((l: any) => l.region_latitude && l.region_longitude)
})

function latLngToXY(lat: number, lng: number) {
  const x = ((lng + 180) / 360) * 100
  const y = ((90 - lat) / 180) * 100
  return { x, y }
}
</script>

<template>
  <div class="lens-page">
    <LoadingSpinner v-if="loading" />

    <div v-else class="lens-layout">
      <div class="lens-map">
        <div class="map-art"></div>
        <div class="map-graticule"></div>
        <button
          v-for="lang in languages"
          :key="lang.code"
          :class="['pin', { active: activePin === lang.code }]"
          :style="{ left: latLngToXY(lang.region_latitude, lang.region_longitude).x + '%', top: latLngToXY(lang.region_latitude, lang.region_longitude).y + '%' }"
          @mouseenter="activePin = lang.code"
          @mouseleave="activePin = null"
        >
          <span class="pin-label">{{ lang.name }}</span>
        </button>
      </div>

      <aside class="lens-list">
        <div class="lens-list-head">語言列表</div>
        <router-link
          v-for="lang in languages"
          :key="lang.code"
          :to="`/language/${lang.code}`"
          :class="['lens-item', { active: activePin === lang.code }]"
          @mouseenter="activePin = lang.code"
          @mouseleave="activePin = null"
        >
          <span class="lens-item-name">{{ lang.name }}</span>
          <span class="lens-item-count">{{ lang.expression_count }}</span>
        </router-link>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.lens-page { max-width: 1100px; margin: 0 auto; }
.lens-layout { display: grid; grid-template-columns: 1fr 280px; gap: 20px; }
.lens-map {
  position: relative;
  height: 70vh;
  background: oklch(0.94 0.012 200);
  border-radius: 4px;
  overflow: hidden;
}
.map-art {
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 200px 150px at 25% 40%, oklch(0.88 0.015 120) 0%, transparent 100%),
    radial-gradient(ellipse 180px 120px at 65% 35%, oklch(0.88 0.015 120) 0%, transparent 100%),
    radial-gradient(ellipse 120px 100px at 45% 65%, oklch(0.88 0.015 120) 0%, transparent 100%),
    radial-gradient(ellipse 100px 80px at 80% 60%, oklch(0.88 0.015 120) 0%, transparent 100%);
}
.map-graticule {
  position: absolute; inset: 0;
  background-image:
    linear-gradient(oklch(0.82 0.008 200) 1px, transparent 1px),
    linear-gradient(90deg, oklch(0.82 0.008 200) 1px, transparent 1px);
  background-size: 10% 10%;
  opacity: 0.5;
}
.pin {
  position: absolute;
  width: 16px; height: 16px;
  border-radius: 50%;
  background: oklch(0.64 0.16 35);
  border: 2px solid #fff;
  box-shadow: 0 1px 4px rgba(0,0,0,0.3);
  cursor: pointer;
  transform: translate(-50%, -50%);
  transition: all 0.15s;
}
.pin.active { transform: translate(-50%, -50%) scale(1.3); box-shadow: 0 2px 8px rgba(0,0,0,0.4); }
.pin-label {
  display: none;
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  padding: 2px 6px;
  background: oklch(0.20 0.015 55);
  color: #fff;
  font-size: 11px;
  white-space: nowrap;
  border-radius: 3px;
  margin-bottom: 4px;
}
.pin.active .pin-label { display: block; }
.lens-list { overflow-y: auto; max-height: 70vh; }
.lens-list-head { font-family: "IBM Plex Mono", monospace; font-size: 11px; text-transform: uppercase; color: oklch(0.52 0.010 200); margin-bottom: 8px; }
.lens-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 6px 10px; text-decoration: none; color: inherit;
  border-radius: 4px; transition: background 0.1s;
}
.lens-item:hover, .lens-item.active { background: oklch(0.96 0.04 35); }
.lens-item-name { font-size: 13px; }
.lens-item-count { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: oklch(0.52 0.010 200); }
</style>
```

- [ ] **Step 2: Verify**

```bash
npm run dev
# /map → SVG map with language pins
# Hover pin → tooltip + list highlight
```

- [ ] **Step 3: Commit**

```bash
git add web_v2/src/
git commit -m "feat(web-v2): MapLens page with SVG map + pins"
```

---

## Task 12: Final Polish + Smoke Test

- [ ] **Step 1: Full smoke test**

```bash
cd web_v2
npm run dev

# Test all routes:
# / → feed with hot mappings + new contributions
# /mapping/15529 → radial graph + 3 direct mappings
# /contribute → expression picker + clique preview
# /handbooks → handbook cards
# /handbook/1539253276 → TOC + sections + expressions
# /handbook/new/edit → create new handbook
# /languages → 32 languages
# /language/cmn → expressions list
# /search?q=hello → search results
# /map → SVG map with pins
# /auth → login form
```

- [ ] **Step 2: Fix any issues found**

- [ ] **Step 3: Final commit**

```bash
git add -A web_v2/
git commit -m "feat(web-v2): complete frontend — all 11 pages operational"
```

---

## 備註

- **Auth**: 登入/註冊連接 v1 backend (`localhost:8787`)。JWT token 共用 v1 和 v2（相同 SECRET_KEY）。
- **Dev proxy**: Vite dev server proxy 將 `/api/v2` 轉發到 `localhost:8789`（v2 backend），`/api/v1` 轉發到 `localhost:8787`（v1 backend）。
- **Tailwind v4**: 使用 Tailwind CSS v4（`@import "tailwindcss"` 語法），config 用 `tailwind.config.ts`。
- **Atlas tokens**: 核心設計 token 從 `docs/prototype/v2/atlas2.css` 轉換。完整 CSS 變數在 `atlas.css` base styles 中。
- **RadialGraph**: 使用 SVG + positioned divs，不是 Canvas。原型的 radial-layout.js 邏輯轉換為 Vue computed properties。
