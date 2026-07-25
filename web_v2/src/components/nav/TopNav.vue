<script setup lang="ts">
import { ref, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Search, Menu, X, Plus } from 'lucide-vue-next'
import LangSwitcher from './LangSwitcher.vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const searchQuery = ref('')
const menuOpen = ref(false)
const drawerEl = ref<HTMLElement | null>(null)
const toggleEl = ref<HTMLElement | null>(null)
const searchInput = ref<HTMLInputElement | null>(null)

function onSearch() {
  const q = searchQuery.value.trim()
  if (!q) return
  router.push({ path: '/search', query: { q } })
  menuOpen.value = false
}

function firstFocusable(): HTMLElement | null {
  return drawerEl.value?.querySelector<HTMLElement>('a[href], button:not([disabled]), input') || null
}
function lastFocusable(): HTMLElement | null {
  if (!drawerEl.value) return null
  const f = [...drawerEl.value.querySelectorAll<HTMLElement>('a[href], button:not([disabled]), input')]
  return f[f.length - 1] || null
}

function openMenu() {
  menuOpen.value = true
  nextTick(() => firstFocusable()?.focus())
}
function closeMenu() {
  menuOpen.value = false
  toggleEl.value?.focus()
}
function toggleMenu() {
  menuOpen.value ? closeMenu() : openMenu()
}

function isTyping() {
  const el = document.activeElement as HTMLElement | null
  return !!el && /input|textarea|select/i.test(el.tagName)
}

function onKeydown(e: KeyboardEvent) {
  // "/" focuses desktop search when not already typing elsewhere
  if (e.key === '/' && !isTyping() && searchInput.value) {
    e.preventDefault()
    searchInput.value.focus()
    return
  }
  if (!menuOpen.value) return
  if (e.key === 'Escape') { e.preventDefault(); closeMenu(); return }
  if (e.key === 'Tab' && drawerEl.value) {
    const first = firstFocusable(), last = lastFocusable()
    if (!first || !last) return
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus() }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus() }
  }
}

onMounted(() => document.addEventListener('keydown', onKeydown))
onUnmounted(() => document.removeEventListener('keydown', onKeydown))

// Close the mobile drawer whenever the route changes.
watch(() => route.path, () => { menuOpen.value = false })
</script>

<template>
  <header class="appbar">
    <router-link to="/" class="brand" aria-label="LangMap 首頁">
      Lang<span class="em">Map</span>
    </router-link>

    <nav class="appnav" aria-label="主要導覽">
      <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">語言</router-link>
      <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">手冊</router-link>
    </nav>

    <form class="top-search" role="search" @submit.prevent="onSearch">
      <Search :size="14" aria-hidden="true" />
      <kbd>/</kbd>
      <input
        ref="searchInput"
        v-model="searchQuery"
        type="search"
        placeholder="搜尋詞句…"
        aria-label="搜尋詞句"
      />
      <button type="submit" class="sr-submit" aria-label="送出搜尋">搜尋</button>
    </form>

    <span class="lang-inline"><LangSwitcher /></span>

    <router-link to="/contribute" class="btn btn-primary btn-sm contrib-btn">
      <Plus :size="14" aria-hidden="true" /> 貢獻
    </router-link>

    <template v-if="auth.user">
      <span class="user-badge auth-inline">{{ auth.user.username }}</span>
      <button class="btn btn-ghost btn-sm auth-inline" @click="auth.logout()">登出</button>
    </template>
    <router-link v-else to="/auth" class="btn btn-ghost btn-sm auth-inline">登入</router-link>

    <button
      ref="toggleEl"
      class="menu-toggle"
      :class="{ on: menuOpen }"
      :aria-label="menuOpen ? '關閉選單' : '開啟選單'"
      :aria-expanded="menuOpen"
      @click="toggleMenu"
    >
      <X v-if="menuOpen" :size="20" aria-hidden="true" />
      <Menu v-else :size="20" aria-hidden="true" />
    </button>

    <transition name="drawer">
      <div v-if="menuOpen" ref="drawerEl" class="drawer" role="dialog" aria-label="選單">
        <form class="drawer-search" role="search" @submit.prevent="onSearch">
          <Search :size="16" aria-hidden="true" />
          <input
            v-model="searchQuery"
            type="search"
            placeholder="搜尋詞句…"
            aria-label="搜尋詞句"
          />
          <button type="submit" class="sr-submit" aria-label="送出搜尋">搜尋</button>
        </form>
        <nav class="drawer-nav" aria-label="主要導覽">
          <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">語言</router-link>
          <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">手冊</router-link>
        </nav>
        <div class="drawer-foot">
          <router-link to="/contribute" class="btn btn-primary">
            <Plus :size="14" aria-hidden="true" /> 貢獻
          </router-link>
          <LangSwitcher />
          <template v-if="auth.user">
            <span class="user-badge">{{ auth.user.username }}</span>
            <button class="btn btn-ghost" @click="auth.logout()">登出</button>
          </template>
          <router-link v-else to="/auth" class="btn btn-ghost">登入</router-link>
        </div>
      </div>
    </transition>
  </header>
</template>

<style scoped>
.brand {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 0;
  font-weight: 700;
  font-size: 15px;
  letter-spacing: -0.03em;
  color: var(--fg);
  text-decoration: none;
}
.brand .em {
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 700;
  color: #fff;
  padding: 2px 4px;
  border-radius: 2px;
  background: var(--accent);
  margin: 0;
  vertical-align: baseline;
}
.brand:hover {
  border-color: var(--muted);
}
.appnav { display: flex; gap: 2px; margin-left: 8px; }
.appnav a {
  font-family: var(--mono);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--muted);
  text-decoration: none;
  height: 28px;
  display: flex; align-items: center;
  padding: 0 12px;
  border-radius: var(--r);
}
.appnav a:hover, .appnav a.on { color: var(--fg); background: var(--bg); }

.top-search {
  margin-left: auto;
  display: flex; align-items: center; gap: 6px;
  position: relative;
  color: var(--muted);
}
.top-search input {
  width: 220px;
  height: 30px;
  padding: 0 30px 0 28px;
  font-size: 13px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--fg);
}
.top-search input:focus { outline: none; border-color: var(--accent); }
.top-search :deep(svg) { position: absolute; left: 8px; }
.top-search kbd {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  font-family: var(--mono); font-size: 10px;
  border: 1px solid var(--border); border-radius: 2px;
  padding: 1px 5px; color: var(--muted); background: var(--surface);
  pointer-events: none;
}

.user-badge {
  font-family: var(--mono); font-size: 11px;
  color: var(--muted);
}

/* Visually-hidden but a11y-reachable submit */
.sr-submit {
  position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px;
  overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0;
}

/* Hamburger button — hidden on desktop */
.menu-toggle {
  display: none;
  flex-direction: column; justify-content: center; align-items: center;
  width: 40px; height: 40px;
  margin-left: auto;
  padding: 0; border: 1px solid var(--border); border-radius: var(--r);
  background: transparent; cursor: pointer; color: var(--fg);
}

/* Mobile drawer */
.drawer {
  position: absolute;
  top: 100%; left: 0; right: 0;
  padding: 12px 20px 16px;
  background: color-mix(in oklch, var(--bg) 98%, transparent);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
  box-shadow: 0 8px 20px oklch(0 0 0 / 0.08);
}
.drawer-search {
  display: flex; align-items: center; gap: 8px; position: relative;
  color: var(--muted); margin-bottom: 12px;
}
.drawer-search input {
  flex: 1; height: 44px; padding: 0 12px 0 36px;
  font-size: 16px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface);
}
.drawer-search :deep(svg) { position: absolute; left: 10px; }
.drawer-nav { display: flex; flex-direction: column; }
.drawer-nav a {
  padding: 12px 4px; min-height: 44px; display: flex; align-items: center;
  font-family: var(--mono);
  font-size: 13px; text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--muted); text-decoration: none;
  border-bottom: 1px solid var(--border);
}
.drawer-nav a:last-child { border-bottom: none; }
.drawer-nav a:hover, .drawer-nav a.on { color: var(--fg); font-weight: 600; }
.drawer-foot {
  display: flex; flex-wrap: wrap; align-items: center; gap: 8px;
  margin-top: 12px;
}
.drawer-foot .btn { flex: 1; justify-content: center; min-height: 44px; }
.drawer-foot .user-badge { flex: 0 0 auto; }

.drawer-enter-active, .drawer-leave-active { transition: opacity 0.18s, transform 0.18s; }
.drawer-enter-from, .drawer-leave-to { opacity: 0; transform: translateY(-8px); }

@media (max-width: 768px) {
  .appnav,
  .top-search,
  .contrib-btn,
  .auth-inline,
  .lang-inline {
    display: none;
  }
  .menu-toggle { display: inline-flex; width: 44px; height: 44px; }
}
</style>
