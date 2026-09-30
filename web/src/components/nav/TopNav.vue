<script setup lang="ts">
import { ref, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Menu, X, Plus, Search } from 'lucide-vue-next'
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
const mobileSearchOpen = ref(false)
const drawerEl = ref<HTMLElement | null>(null)
const toggleEl = ref<HTMLElement | null>(null)
const mobileSearchToggleEl = ref<HTMLElement | null>(null)
const desktopSearchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const mobileSearchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const localeParams = useLocaleParams()
const searchLanguages = useSearchLanguages()

function applyRememberedSearchLanguage() {
  const resolved = searchLanguages.resolveSearchLanguage(searchLanguage.value)
  if (resolved) {
    searchLanguage.value = resolved
    searchLanguageMissing.value = false
  }
}

function onSearchLanguageUpdate(value: string) {
  searchLanguage.value = value
  searchLanguageMissing.value = false
}

function controlsHost(control: InstanceType<typeof ExpressionSearchControls>): HTMLElement | null {
  const root = control.$el as HTMLElement | null
  return root?.closest('.search-center, .mobile-search-panel') as HTMLElement | null
}

function isControlsVisible(control: InstanceType<typeof ExpressionSearchControls>): boolean {
  const host = controlsHost(control)
  if (!host) return true
  const style = typeof window.getComputedStyle === 'function' ? window.getComputedStyle(host) : null
  if (style?.display === 'none' || style?.visibility === 'hidden') return false
  // jsdom does not calculate layout boxes. In a real browser, a mounted
  // control with no box is hidden; retain a permissive fallback for tests.
  if (host.getClientRects().length > 0 || host.offsetParent !== null) return true
  if (typeof window.matchMedia === 'function' && window.matchMedia('(max-width: 1120px)').matches) return false
  return true
}

function visibleSearchControls() {
  if (mobileSearchOpen.value && mobileSearchControls.value && isControlsVisible(mobileSearchControls.value)) {
    return mobileSearchControls.value
  }
  if (desktopSearchControls.value && isControlsVisible(desktopSearchControls.value)) {
    return desktopSearchControls.value
  }
  if (mobileSearchControls.value && isControlsVisible(mobileSearchControls.value)) {
    return mobileSearchControls.value
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
  mobileSearchOpen.value = false
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
  mobileSearchOpen.value = false
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

function openSearch() {
  menuOpen.value = false
  mobileSearchOpen.value = true
  void nextTick(() => mobileSearchControls.value?.focusSearch())
}
function closeMobileSearch() {
  mobileSearchOpen.value = false
  mobileSearchToggleEl.value?.focus()
}
function toggleMobileSearch() {
  mobileSearchOpen.value ? closeMobileSearch() : openSearch()
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
  if (e.defaultPrevented) return
  if (e.key === 'Escape' && mobileSearchOpen.value) {
    e.preventDefault()
    closeMobileSearch()
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

watch(searchLanguages.languages, applyRememberedSearchLanguage, { immediate: true })
watch(() => searchLanguages.loading.value, applyRememberedSearchLanguage)
watch(
  () => [localeParams.value.ui_locale, localeParams.value.secondary_ui_locale],
  () => {
    searchLanguage.value = ''
    searchLanguageMissing.value = false
    applyRememberedSearchLanguage()
  },
)

// Close the mobile drawer whenever the route changes.
watch(() => route.path, () => { menuOpen.value = false; mobileSearchOpen.value = false })
</script>

<template>
  <header class="appbar" :class="{ 'home-route': route.path === '/' }">
    <div class="left-group">
      <router-link to="/" class="brand" :aria-label="`${t('nav.home')} LangMap`">
        Lang<span class="em">Map</span>
      </router-link>

      <nav class="appnav" :aria-label="t('nav.menu')">
        <router-link to="/" :class="{ on: route.path === '/' }" :aria-current="route.path === '/' ? 'page' : undefined">{{ t('nav.home') }}</router-link>
        <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }" :aria-current="route.path.startsWith('/language') ? 'page' : undefined">{{ t('nav.languages') }}</router-link>
        <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }" :aria-current="route.path.startsWith('/handbook') ? 'page' : undefined">{{ t('nav.handbooks') }}</router-link>
      </nav>
    </div>

    <div v-if="route.path !== '/' && route.path !== '/search'" class="search-center">
      <form class="top-search" role="search" @submit.prevent="onSearch">
        <ExpressionSearchControls
          ref="desktopSearchControls"
          v-model:query="searchQuery"
          v-model:language="searchLanguage"
          show-submit
          :language-required="searchLanguageMissing"
          @update:language="onSearchLanguageUpdate"
          @submit="onSearch"
        />
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
      v-if="route.path !== '/' && route.path !== '/search'"
      ref="mobileSearchToggleEl"
      type="button"
      class="mobile-search-toggle"
      :aria-label="mobileSearchOpen ? t('common.close') : t('nav.searchExpressions')"
      aria-controls="mobile-search-panel"
      :aria-expanded="mobileSearchOpen"
      @click="toggleMobileSearch"
    >
      <X v-if="mobileSearchOpen" :size="20" aria-hidden="true" />
      <Search v-else :size="20" aria-hidden="true" />
    </button>

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
      <div v-if="mobileSearchOpen && route.path !== '/' && route.path !== '/search'" id="mobile-search-panel" class="mobile-search-panel">
        <form class="mobile-search-form" role="search" @submit.prevent="onSearch">
          <ExpressionSearchControls
            ref="mobileSearchControls"
            v-model:query="searchQuery"
            v-model:language="searchLanguage"
            show-submit
            :language-required="searchLanguageMissing"
            @update:language="onSearchLanguageUpdate"
            @submit="onSearch"
          />
        </form>
      </div>
    </transition>

    <transition name="drawer">
      <div v-if="menuOpen" ref="drawerEl" class="drawer" role="dialog" :aria-label="t('nav.menu')">
        <nav class="drawer-nav" :aria-label="t('nav.menu')">
          <router-link to="/" :class="{ on: route.path === '/' }" :aria-current="route.path === '/' ? 'page' : undefined">{{ t('nav.home') }}</router-link>
          <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }" :aria-current="route.path.startsWith('/language') ? 'page' : undefined">{{ t('nav.languages') }}</router-link>
          <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }" :aria-current="route.path.startsWith('/handbook') ? 'page' : undefined">{{ t('nav.handbooks') }}</router-link>
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
  grid-template-columns: max-content minmax(320px, 1fr) max-content;
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
.appbar.home-route { grid-template-columns: minmax(0, 1fr) auto; }
.appbar.home-route .right-group { grid-column: 2; }
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
  max-width: 560px;
  justify-self: center;
}
.top-search {
  width: 100%;
  min-width: 0;
}
.top-search :deep(.expression-search.has-submit) {
  grid-template-columns: minmax(112px, 0.38fr) minmax(0, 1fr) auto;
}
.top-search :deep(.expression-search-submit) {
  min-width: 72px;
  padding: 0 10px;
}

.right-group {
  grid-column: 3;
  justify-self: end;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 12px;
}

.contrib-btn {
  height: 30px;
  min-height: 30px;
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

/* Hamburger button — hidden on desktop */
.menu-toggle {
  display: none;
  flex-direction: column; justify-content: center; align-items: center;
  width: 40px; height: 40px;
  margin-left: auto;
  padding: 0; border: 1px solid var(--border); border-radius: var(--r);
  background: transparent; cursor: pointer; color: var(--fg);
}
.mobile-search-toggle {
  display: none;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  padding: 0;
  border: 1px solid transparent;
  border-radius: var(--r);
  background: transparent;
  color: var(--fg);
  cursor: pointer;
}
.mobile-search-toggle:hover { background: var(--surface-2); }
.mobile-search-toggle:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }

/* Mobile overlays */
.drawer,
.mobile-search-panel {
  position: absolute;
  top: 100%; left: 0; right: 0;
  padding: 12px 20px 16px;
  background: color-mix(in oklch, var(--bg) 98%, transparent);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--border);
  box-shadow: 0 8px 20px oklch(0 0 0 / 0.08);
}
.mobile-search-panel { z-index: 21; }
.mobile-search-form {
  width: 100%;
  min-width: 0;
  margin: 0;
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
    grid-template-columns: max-content minmax(320px, 1fr) max-content;
  }
  .search-center {
    max-width: 440px;
  }
}

@media (max-width: 1120px) {
  .appbar {
    display: flex;
  }
  .appnav,
  .search-center,
  .right-group,
  .lang-inline {
    display: none;
  }
  .mobile-search-toggle { display: inline-flex; margin-left: auto; }
  .mobile-search-toggle + .menu-toggle { margin-left: 0; }
  .menu-toggle { display: inline-flex; width: 44px; height: 44px; }

  .mobile-search-form :deep(.expression-search) {
    grid-template-columns: 1fr;
    height: auto;
    gap: 8px;
    border: 0;
    background: transparent;
  }
  .mobile-search-form :deep(.expression-search.has-submit) {
    grid-template-columns: minmax(0, 1fr) auto;
  }
  .mobile-search-form :deep(.expression-search-language-wrap) {
    border: 0;
  }
  .mobile-search-form :deep(.expression-search.has-submit .expression-search-language-wrap) {
    grid-column: 1 / -1;
  }
  .mobile-search-form :deep(.expression-search-language),
  .mobile-search-form :deep(.expression-search-query) {
    min-height: 44px;
    border: 1px solid var(--border);
    border-radius: var(--r);
    background: var(--surface);
  }
  .mobile-search-form :deep(.expression-search-language) {
    height: 44px;
  }
  .mobile-search-form :deep(.expression-search-query) {
    padding: 0 12px;
  }
  .mobile-search-form :deep(.expression-search.has-submit .expression-search-query) {
    grid-column: 1;
  }
  .mobile-search-form :deep(.expression-search.has-submit .expression-search-submit) {
    grid-column: 2;
    min-width: 72px;
    min-height: 44px;
    height: 44px;
    padding: 0 10px;
    border-left: 0;
    border-radius: var(--r);
  }
  .mobile-search-form :deep(.expression-search-input) {
    min-height: 44px;
  }
  .mobile-search-form :deep(.expression-search-dropdown) {
    width: 100%;
    max-width: none;
  }
}
</style>
