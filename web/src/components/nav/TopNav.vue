<script setup lang="ts">
import { ref, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Menu, X, Plus } from 'lucide-vue-next'
import LangSwitcher from './LangSwitcher.vue'
import ExpressionSearchControls from '@/components/search/ExpressionSearchControls.vue'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useSearchLanguages } from '@/composables/useSearchLanguages'
import { useI18n } from 'vue-i18n'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const { t } = useI18n()

const searchQuery = ref('')
const searchLanguage = ref('')
const searchLanguageMissing = ref(false)
const menuOpen = ref(false)
const drawerEl = ref<HTMLElement | null>(null)
const toggleEl = ref<HTMLElement | null>(null)
const desktopSearchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const drawerSearchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const localeParams = useLocaleParams()
const searchLanguages = useSearchLanguages()

async function initializeSearchLanguage() {
  try {
    await searchLanguages.loadSearchLanguages(localeParams.value)
    searchLanguage.value = searchLanguages.resolveSearchLanguage(searchLanguage.value)
    if (searchLanguage.value) searchLanguageMissing.value = false
  } catch {
    searchLanguage.value = ''
  }
}

function onSearchLanguageUpdate(value: string) {
  searchLanguage.value = value
  searchLanguageMissing.value = false
}

function controlsHost(control: InstanceType<typeof ExpressionSearchControls>): HTMLElement | null {
  const root = control.$el as HTMLElement | null
  return root?.closest('.search-center, .drawer-search') as HTMLElement | null
}

function isControlsVisible(control: InstanceType<typeof ExpressionSearchControls>): boolean {
  const host = controlsHost(control)
  if (!host) return true
  const style = typeof window.getComputedStyle === 'function' ? window.getComputedStyle(host) : null
  if (style?.display === 'none' || style?.visibility === 'hidden') return false
  // jsdom does not calculate layout boxes. In a real browser, a mounted
  // control with no box is hidden; retain a permissive fallback for tests.
  if (host.getClientRects().length > 0 || host.offsetParent !== null) return true
  if (typeof window.matchMedia === 'function' && window.matchMedia('(max-width: 960px)').matches) return false
  return true
}

function visibleSearchControls() {
  if (menuOpen.value && drawerSearchControls.value && isControlsVisible(drawerSearchControls.value)) {
    return drawerSearchControls.value
  }
  if (desktopSearchControls.value && isControlsVisible(desktopSearchControls.value)) {
    return desktopSearchControls.value
  }
  if (drawerSearchControls.value && isControlsVisible(drawerSearchControls.value)) {
    return drawerSearchControls.value
  }
  return null
}

function onSearch() {
  const q = searchQuery.value.trim()
  if (!q) return
  if (!searchLanguage.value) {
    searchLanguageMissing.value = true
    nextTick(() => visibleSearchControls()?.focusLanguage())
    return
  }
  router.push({ path: '/search', query: { q, lang: searchLanguage.value } })
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
  if (!el) return false
  if (/input|textarea|select/i.test(el.tagName)) return true
  if (el.tagName.toLowerCase() === 'button' && el.getAttribute('role') === 'combobox') return true
  return el.isContentEditable || el.getAttribute('contenteditable') === '' || el.getAttribute('contenteditable') === 'true'
}

function onKeydown(e: KeyboardEvent) {
  // "/" focuses the visible search control when not already typing elsewhere.
  const controls = e.key === '/' && !isTyping() ? visibleSearchControls() : null
  if (controls) {
    e.preventDefault()
    controls.focusSearch()
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

onMounted(() => { void initializeSearchLanguage() })
watch(
  () => [localeParams.value.ui_locale, localeParams.value.secondary_ui_locale],
  () => { void initializeSearchLanguage() },
)

// Close the mobile drawer whenever the route changes.
watch(() => route.path, () => { menuOpen.value = false })
</script>

<template>
  <header class="appbar">
    <div class="left-group">
      <router-link to="/" class="brand" :aria-label="`${t('nav.home')} LangMap`">
        Lang<span class="em">Map</span>
      </router-link>

      <nav class="appnav" :aria-label="t('nav.menu')">
        <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">{{ t('nav.languages') }}</router-link>
        <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">{{ t('nav.handbooks') }}</router-link>
      </nav>
    </div>

    <div v-if="route.path !== '/search'" class="search-center">
      <form class="top-search" role="search" @submit.prevent="onSearch">
        <ExpressionSearchControls
          ref="desktopSearchControls"
          v-model:query="searchQuery"
          v-model:language="searchLanguage"
          :language-required="searchLanguageMissing"
          @update:language="onSearchLanguageUpdate"
          @submit="onSearch"
        />
        <button type="submit" class="sr-submit" :aria-label="t('nav.submitSearch')">{{ t('nav.submitSearch') }}</button>
      </form>
    </div>

    <div class="right-group">
      <router-link to="/contribute" class="btn btn-primary btn-sm contrib-btn">
        <Plus :size="14" aria-hidden="true" /> {{ t('nav.contribute') }}
      </router-link>

      <span class="lang-inline"><LangSwitcher /></span>

      <router-link v-if="auth.user" to="/profile" class="user-badge auth-inline">{{ auth.user.username }}</router-link>
      <router-link v-else to="/auth" class="btn btn-ghost btn-sm auth-inline">{{ t('nav.signIn') }}</router-link>
    </div>

    <button
      ref="toggleEl"
      class="menu-toggle"
      :class="{ on: menuOpen }"
      :aria-label="menuOpen ? t('nav.closeMenu') : t('nav.openMenu')"
      :aria-expanded="menuOpen"
      @click="toggleMenu"
    >
      <X v-if="menuOpen" :size="20" aria-hidden="true" />
      <Menu v-else :size="20" aria-hidden="true" />
    </button>

    <transition name="drawer">
      <div v-if="menuOpen" ref="drawerEl" class="drawer" role="dialog" :aria-label="t('nav.menu')">
        <form v-if="route.path !== '/search'" class="drawer-search" role="search" @submit.prevent="onSearch">
          <ExpressionSearchControls
            ref="drawerSearchControls"
            v-model:query="searchQuery"
            v-model:language="searchLanguage"
            :language-required="searchLanguageMissing"
            @update:language="onSearchLanguageUpdate"
            @submit="onSearch"
          />
          <button type="submit" class="sr-submit" :aria-label="t('nav.submitSearch')">{{ t('nav.submitSearch') }}</button>
        </form>
        <nav class="drawer-nav" :aria-label="t('nav.menu')">
          <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">{{ t('nav.languages') }}</router-link>
          <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">{{ t('nav.handbooks') }}</router-link>
        </nav>
        <div class="drawer-foot">
          <router-link to="/contribute" class="btn btn-primary">
            <Plus :size="14" aria-hidden="true" /> {{ t('nav.contribute') }}
          </router-link>
          <LangSwitcher />
          <router-link v-if="auth.user" to="/profile" class="user-badge">{{ auth.user.username }}</router-link>
          <router-link v-else to="/auth" class="btn btn-ghost">{{ t('nav.signIn') }}</router-link>
        </div>
      </div>
    </transition>
  </header>
</template>

<style scoped>
.appbar {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(420px, 560px) minmax(0, 1fr);
  align-items: center;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  padding: 0;
  font-weight: 700;
  font-size: 17px;
  letter-spacing: -0.03em;
  color: var(--fg);
  text-decoration: none;
}
.brand .em {
  font-family: var(--mono);
  font-size: 13px;
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
.left-group {
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 12px;
  justify-self: start;
}
.appnav { display: flex; gap: 2px; }
.appnav a {
  font-family: var(--mono);
  font-size: 14px;
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

.search-center {
  grid-column: 2;
  width: 100%;
  min-width: 0;
  justify-self: center;
}
.top-search {
  width: 100%;
  min-width: 0;
}

.right-group {
  grid-column: 3;
  justify-self: end;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-badge {
  font-family: var(--mono); font-size: 13px;
  color: var(--muted);
  text-decoration: none;
  cursor: pointer;
  transition: color 0.12s;
}
a.user-badge:hover {
  color: var(--fg);
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
  width: 100%;
  min-width: 0;
  margin-bottom: 12px;
}
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

@media (max-width: 1180px) {
  .appbar {
    grid-template-columns: auto minmax(320px, 1fr) auto;
  }
  .search-center {
    max-width: 440px;
  }
}

@media (max-width: 960px) {
  .appbar {
    display: flex;
  }
  .appnav,
  .search-center,
  .right-group,
  .lang-inline {
    display: none;
  }
  .menu-toggle { display: inline-flex; width: 44px; height: 44px; }

  .drawer-search :deep(.expression-search) {
    grid-template-columns: 1fr;
    height: auto;
    gap: 8px;
    border: 0;
    background: transparent;
  }
  .drawer-search :deep(.expression-search-language-wrap) {
    border: 0;
  }
  .drawer-search :deep(.expression-search-language),
  .drawer-search :deep(.expression-search-query) {
    min-height: 44px;
    border: 1px solid var(--border);
    border-radius: var(--r);
    background: var(--surface);
  }
  .drawer-search :deep(.expression-search-language) {
    height: 44px;
  }
  .drawer-search :deep(.expression-search-query) {
    padding: 0 12px;
  }
  .drawer-search :deep(.expression-search-input) {
    min-height: 44px;
  }
  .drawer-search :deep(.expression-search-dropdown) {
    width: 100%;
    max-width: none;
  }
}
</style>
