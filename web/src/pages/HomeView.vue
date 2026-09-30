<script setup lang="ts">
import { nextTick, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionSearchControls from '@/components/search/ExpressionSearchControls.vue'
import HomeFeed from '@/pages/HomeFeed.vue'
import TranslationWorkbench from '@/components/translation/TranslationWorkbench.vue'

type HomeMode = 'search' | 'translate'

const router = useRouter()
const { t } = useI18n()
const mode = ref<HomeMode>('search')
const query = ref('')
const language = ref('')
const languageRequired = ref(false)
const searchTab = ref<HTMLButtonElement>()
const translateTab = ref<HTMLButtonElement>()
const searchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)

function selectMode(next: HomeMode, focus = false) {
  mode.value = next
  if (focus) {
    void nextTick(() => (next === 'search' ? searchTab.value : translateTab.value)?.focus())
  }
}

function onTabKeydown(event: KeyboardEvent, current: HomeMode) {
  const next = event.key === 'Home'
    ? 'search'
    : event.key === 'End'
      ? 'translate'
      : event.key === 'ArrowLeft' || event.key === 'ArrowRight'
        ? current === 'search' ? 'translate' : 'search'
        : null
  if (!next) return
  event.preventDefault()
  selectMode(next, true)
}

function searchExpressions() {
  const text = query.value.trim()
  if (!text) return
  if (!language.value) {
    languageRequired.value = true
    void nextTick(() => searchControls.value?.focusLanguage())
    return
  }
  void router.push({ path: '/search', query: { q: text, lang: language.value } })
}

function onLanguageUpdate(value: string) {
  languageRequired.value = false
  language.value = value
}
</script>

<template>
  <main id="main-content" class="home-page" :class="{ 'is-translate': mode === 'translate' }">
    <div class="home-layout" :class="{ 'home-layout-translate': mode === 'translate' }">
      <h1 class="sr-only">{{ t('home.title') }}</h1>

      <div class="home-tabs" role="tablist" :aria-label="t('home.title')">
        <button
          id="home-search-tab"
          ref="searchTab"
          type="button"
          role="tab"
          :aria-selected="mode === 'search'"
          :tabindex="mode === 'search' ? 0 : -1"
          aria-controls="home-search-panel"
          @click="selectMode('search')"
          @keydown="onTabKeydown($event, 'search')"
        >
          {{ t('common.search') }}
        </button>
        <button
          id="home-translate-tab"
          ref="translateTab"
          type="button"
          role="tab"
          :aria-selected="mode === 'translate'"
          :tabindex="mode === 'translate' ? 0 : -1"
          aria-controls="home-translate-panel"
          @click="selectMode('translate')"
          @keydown="onTabKeydown($event, 'translate')"
        >
          {{ t('nav.phraseTranslate') }}
        </button>
      </div>

      <section
        v-show="mode === 'search'"
        id="home-search-panel"
        class="home-panel search-panel"
        role="tabpanel"
        aria-labelledby="home-search-tab"
        tabindex="0"
      >
        <header class="home-panel-intro">
          <h2>{{ t('home.search') }}</h2>
          <p>{{ t('home.searchHint') }}</p>
        </header>
        <form class="home-search-form" role="search" @submit.prevent="searchExpressions">
          <ExpressionSearchControls
            ref="searchControls"
            v-model:query="query"
            v-model:language="language"
            variant="page"
            show-submit
            :language-required="languageRequired"
            @update:language="onLanguageUpdate"
            @submit="searchExpressions"
          />
        </form>
        <HomeFeed v-if="mode === 'search'" />
      </section>

      <section
        v-show="mode === 'translate'"
        id="home-translate-panel"
        class="home-panel translate-panel"
        role="tabpanel"
        aria-labelledby="home-translate-tab"
        tabindex="0"
      >
        <TranslationWorkbench v-if="mode === 'translate'" />
      </section>
    </div>
  </main>
</template>

<style scoped>
.home-page {
  box-sizing: border-box;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  min-height: calc(100svh - var(--bar-h));
  width: 100%;
  padding: clamp(84px, 16vh, 140px) 24px 32px;
  background: transparent;
}
.home-page.is-translate { padding-bottom: var(--page-pad-bottom); }
.home-layout {
  width: 100%;
  max-width: 840px;
  min-width: 0;
}
.home-layout-translate { max-width: 1120px; }
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
.home-tabs {
  display: flex;
  width: min(100%, 360px);
  max-width: 100%;
  margin: 0 auto var(--space-md);
  border-bottom: 1px solid var(--border);
}
.home-tabs button {
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 1;
  min-height: 44px;
  padding: 0 16px;
  border: 0;
  border-bottom: 2px solid transparent;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font: inherit;
  font-weight: 600;
  transition: border-color 0.12s ease, color 0.12s ease;
}
.home-tabs button:hover { color: var(--fg); }
.home-tabs button[aria-selected='true'] {
  border-bottom-color: var(--accent);
  color: var(--accent);
}
.home-tabs button:focus-visible,
.home-panel:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 3px;
}
.home-search-form { width: 100%; min-width: 0; }
.home-panel-intro {
  display: grid;
  gap: 4px;
  margin-bottom: var(--space-base);
}
.home-panel-intro h2 {
  margin: 0;
  font-size: clamp(22px, 3vw, 26px);
  line-height: 1.25;
}
.home-panel-intro p { margin: 0; color: var(--muted); font-size: var(--text-ui); }
.home-search-form :deep(.expression-search.variant-page.has-submit) {
  height: auto;
  grid-template-columns: minmax(0, 1fr);
  gap: 14px;
  border: 0;
  border-radius: 0;
  background: transparent;
}
.home-search-form :deep(.expression-search-language-wrap) {
  width: 100%;
  border: 0;
}
.home-search-form :deep(.expression-search-language) {
  min-height: 48px;
  padding: 0 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.home-search-form :deep(.expression-search-query) {
  box-sizing: border-box;
  min-height: 84px;
  gap: 14px;
  padding: 0 20px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.home-search-form :deep(.expression-search-icon) { width: 24px; height: 24px; }
.home-search-form :deep(.expression-search-input) { min-height: 82px; font-size: 20px; }
.home-search-form :deep(.expression-search.variant-page.has-submit .expression-search-submit) {
  grid-column: 1 / -1;
  justify-self: center;
  width: 168px;
  height: 52px;
  min-height: 52px;
  border: 0;
  border-radius: var(--r);
  font-size: 16px;
  font-weight: 600;
  text-align: center;
}
.translate-panel { min-width: 0; }
@media (max-width: 768px) {
  .home-page { min-height: calc(100svh - var(--bar-h)); padding: clamp(20px, 4vh, 32px) 16px 32px; }
  .home-tabs { width: 100%; max-width: 320px; margin-bottom: var(--space-md); }
  .home-tabs button { min-width: 0; padding: 0 14px; }
  .home-search-form :deep(.expression-search.variant-page.has-submit) {
    height: auto;
    grid-template-columns: minmax(0, 1fr);
    gap: 12px;
    border: 0;
    border-radius: 0;
    background: transparent;
  }
  .home-search-form :deep(.expression-search-language-wrap) {
    grid-column: 1;
    width: 100%;
    border: 0;
  }
  .home-search-form :deep(.expression-search-language) {
    min-height: 48px;
    height: 48px;
    padding: 0 12px;
    border: 1px solid var(--border);
    border-radius: var(--r);
    background: var(--surface);
  }
  .home-search-form :deep(.expression-search-query) {
    grid-column: 1;
    min-height: 72px;
    padding: 0 16px;
    border: 1px solid var(--border);
    border-radius: var(--r);
    background: var(--surface);
  }
  .home-search-form :deep(.expression-search-input) { min-height: 70px; font-size: 18px; }
  .home-search-form :deep(.expression-search.variant-page.has-submit .expression-search-submit) {
    grid-column: 1 / -1;
    justify-self: center;
    width: 168px;
    height: 52px;
    min-height: 52px;
    border: 0;
    border-radius: var(--r);
  }
}
@media (prefers-reduced-motion: reduce) {
  .home-tabs button { transition: none; }
}
</style>
