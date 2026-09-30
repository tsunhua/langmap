<script setup lang="ts">
import { nextTick, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { ArrowLeftRight, Search } from 'lucide-vue-next'
import ExpressionSearchControls from '@/components/search/ExpressionSearchControls.vue'
import HomeFeed from '@/pages/HomeFeed.vue'
import TranslationWorkbench from '@/components/translation/TranslationWorkbench.vue'
import { useSearchLanguages } from '@/composables/useSearchLanguages'

type HomeMode = 'search' | 'translate'

const router = useRouter()
const { t } = useI18n()
const mode = ref<HomeMode>('search')
const translateMounted = ref(false)
const query = ref('')
const language = ref('')
const languageRequired = ref(false)
const searchTab = ref<HTMLButtonElement>()
const translateTab = ref<HTMLButtonElement>()
const searchControls = ref<InstanceType<typeof ExpressionSearchControls> | null>(null)
const searchLanguages = useSearchLanguages()

watch(searchLanguages.languages, (languages) => {
  if (language.value) return
  language.value = searchLanguages.resolveSearchLanguage()
    || (languages.some((item) => item.code === 'eng') ? 'eng' : '')
}, { immediate: true })

function selectMode(next: HomeMode, focus = false) {
  if (next === 'translate') translateMounted.value = true
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
  <div class="home-page" :class="{ 'is-translate': mode === 'translate' }">
    <div class="home-layout" :class="{ 'home-layout-translate': mode === 'translate' }">
      <header class="home-hero">
        <h1>{{ t('home.heroTitle') }}</h1>
        <p>{{ t('home.heroSubtitle') }}</p>
      </header>

      <div class="home-workspace">
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
            <Search :size="16" aria-hidden="true" />
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
            <ArrowLeftRight :size="16" aria-hidden="true" />
            {{ t('nav.phraseTranslate') }}
          </button>
        </div>

        <div class="home-task-card">
          <section
            v-show="mode === 'search'"
            id="home-search-panel"
            class="home-panel search-panel"
            role="tabpanel"
            aria-labelledby="home-search-tab"
            tabindex="0"
          >
            <form class="home-search-form" role="search" @submit.prevent="searchExpressions">
              <ExpressionSearchControls
                ref="searchControls"
                v-model:query="query"
                v-model:language="language"
                variant="page"
                show-submit
                show-field-labels
                :language-label="t('home.languageLabel')"
                :query-label="t('home.expressionLabel')"
                :query-placeholder="t('home.expressionPlaceholder')"
                :language-required="languageRequired"
                @update:language="onLanguageUpdate"
                @submit="searchExpressions"
              />
            </form>
          </section>

          <section
            v-show="mode === 'translate'"
            id="home-translate-panel"
            class="home-panel translate-panel"
            role="tabpanel"
            aria-labelledby="home-translate-tab"
            tabindex="0"
          >
            <TranslationWorkbench v-if="translateMounted" />
          </section>
        </div>
      </div>

      <HomeFeed v-if="mode === 'search'" />
    </div>
  </div>
</template>

<style scoped>
.home-page {
  box-sizing: border-box;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  min-height: calc(100svh - var(--bar-h));
  width: 100%;
  padding: clamp(40px, 6vh, 72px) 24px 32px;
  background: transparent;
}
.home-page.is-translate { padding-bottom: var(--page-pad-bottom); }
.home-layout {
  width: min(100%, 822px);
  min-width: 0;
}
.home-layout-translate {
  width: min(100%, 1120px);
  max-width: 1120px;
}
.home-task-card {
  box-sizing: border-box;
  min-width: 0;
  padding: 20px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.home-hero {
  display: grid;
  gap: 6px;
  margin: 0 auto 24px;
  text-align: center;
}
.home-hero h1 {
  margin: 0;
  font-size: clamp(28px, 3.4vw, 38px);
  font-weight: 700;
  line-height: 1.15;
  letter-spacing: -0.025em;
}
.home-hero p {
  margin: 0;
  color: var(--muted);
  font-size: 15px;
  line-height: 1.5;
}
.home-workspace {
  width: 100%;
  min-width: 0;
}
.home-tabs {
  display: flex;
  width: min(100%, 360px);
  max-width: 100%;
  gap: 6px;
  margin: 0 auto 12px;
  padding: 4px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
}
.home-tabs button {
  display: flex;
  align-items: center;
  justify-content: center;
  flex: 1;
  gap: 8px;
  min-height: 44px;
  padding: 0 16px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font: inherit;
  font-weight: 600;
  transition: background-color 0.12s ease, color 0.12s ease;
}
.home-tabs button:hover { color: var(--fg); }
.home-tabs button[aria-selected='true'] {
  background: var(--accent-soft);
  color: var(--accent);
}
.home-tabs button:focus-visible,
.home-panel:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 3px;
}
.home-search-form { width: 100%; min-width: 0; }
.home-search-form :deep(.expression-search.has-field-labels) { gap: 14px; }
.home-search-form :deep(.expression-search-field-label) { font-size: 13px; }
.home-search-form :deep(.expression-search.has-field-labels .expression-search-language) {
  min-height: 44px;
  padding: 0 12px;
}
.home-search-form :deep(.expression-search.has-field-labels .expression-search-input-wrap) {
  min-height: 56px;
  padding: 0 12px;
}
.home-search-form :deep(.expression-search.has-field-labels .expression-search-input) {
  min-height: 52px;
  font-size: 16px;
}
.home-search-form :deep(.expression-search.has-field-labels .expression-search-submit) {
  height: 52px;
  min-height: 52px;
  font-size: 15px;
  font-weight: 600;
}
.translate-panel { min-width: 0; }
@media (max-width: 768px) {
  .home-page { min-height: calc(100svh - var(--bar-h)); padding: clamp(40px, 6vh, 52px) 16px 32px; }
  .home-task-card { padding: 16px; }
  .home-hero { margin-bottom: 24px; }
  .home-hero h1 { font-size: clamp(30px, 7vw, 34px); line-height: 1.12; }
  .home-tabs { width: 100%; max-width: 360px; margin-bottom: 12px; }
  .home-tabs button { min-width: 0; padding: 0 14px; }
}
@media (prefers-reduced-motion: reduce) {
  .home-tabs button { transition: none; }
}
</style>
