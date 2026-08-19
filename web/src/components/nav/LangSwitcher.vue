<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { Globe, ChevronDown, Languages } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { useLocalizationStore } from '@/stores/localization'
import { groupLocalesByVariety } from '@/composables/useLocaleVarieties'
import { useI18n } from 'vue-i18n'

const store = useLocalizationStore()
const { t } = useI18n()
const router = useRouter()
const open = ref(false)
const query = ref('')
const rootEl = ref<HTMLElement>()
const triggerEl = ref<HTMLButtonElement>()
const searchEl = ref<HTMLInputElement>()
const activeIndex = ref(-1)
// 暫時隱藏尚未完成 UI 翻譯的語言；資料與其他語言選擇入口不受影響。
const HIDDEN_LANGUAGE_VARIETIES = new Set(['nan', 'yue'])

const groupedWithOptions = computed(() => {
  const groups = groupLocalesByVariety(
    store.locales.filter(locale => !HIDDEN_LANGUAGE_VARIETIES.has(locale.language_locale_code.split('-')[0])),
    store.locale,
  )
  const q = query.value.toLowerCase().trim()
  const filtered = q
    ? groups.filter(g =>
        g.varietyLabel.toLowerCase().includes(q) ||
        g.base.toLowerCase().includes(q) ||
        g.items.some(it => (it.scriptLabel || '').toLowerCase().includes(q) || it.code.toLowerCase().includes(q)),
      )
    : groups
  let i = 0
  return filtered.map(g => ({ ...g, items: g.items.map(it => ({ ...it, flatIndex: i++ })) }))
})
const flatCodes = computed(() => groupedWithOptions.value.flatMap(g => g.items.map(it => it.code)))
watch(flatCodes, list => { activeIndex.value = list.length > 0 ? 0 : -1 })

function openMenu() {
  open.value = true
  activeIndex.value = flatCodes.value.length > 0 ? 0 : -1
  nextTick(() => searchEl.value?.focus())
}
function closeMenu() {
  open.value = false
  query.value = ''
  activeIndex.value = -1
}
function toggle() { open.value ? closeMenu() : openMenu() }
async function choose(code: string) {
  await store.setLocale(code)
  closeMenu()
  nextTick(() => triggerEl.value?.focus())
}
function openWorkbench() { closeMenu(); router.push('/translate') }

function scrollActiveIntoView() {
  nextTick(() => {
    rootEl.value?.querySelector<HTMLElement>(`[data-idx="${activeIndex.value}"]`)?.scrollIntoView({ block: 'nearest' })
  })
}
function onKeydown(e: KeyboardEvent) {
  if (!open.value) return
  if (e.key === 'Escape') { e.preventDefault(); closeMenu(); nextTick(() => triggerEl.value?.focus()); return }
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    if (flatCodes.value.length) { activeIndex.value = (activeIndex.value + 1) % flatCodes.value.length; scrollActiveIntoView() }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    if (flatCodes.value.length) { activeIndex.value = (activeIndex.value - 1 + flatCodes.value.length) % flatCodes.value.length; scrollActiveIntoView() }
  } else if (e.key === 'Enter') {
    const code = flatCodes.value[activeIndex.value]
    if (code) { e.preventDefault(); void choose(code) }
  }
}
function onDocumentMousedown(e: MouseEvent) {
  if (open.value && rootEl.value && !rootEl.value.contains(e.target as Node)) closeMenu()
}

onMounted(() => {
  void store.loadLocales()
  document.addEventListener('mousedown', onDocumentMousedown)
  document.addEventListener('keydown', onKeydown)
})
onUnmounted(() => {
  document.removeEventListener('mousedown', onDocumentMousedown)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div ref="rootEl" class="lang-switcher">
    <button ref="triggerEl" class="lang-switch" type="button" :aria-label="t('nav.switchLanguage')" aria-haspopup="listbox" :aria-expanded="open" @click="toggle">
      <Globe :size="14" aria-hidden="true" />
      <span class="ls-code">{{ store.locale }}</span>
      <ChevronDown :size="12" aria-hidden="true" />
    </button>
    <div v-if="open" class="lang-menu" role="listbox" :aria-label="t('nav.switchLanguage')">
      <input ref="searchEl" v-model="query" type="search" :placeholder="t('common.search')" class="lang-search" :aria-label="t('common.search')" />
      <template v-for="group in groupedWithOptions" :key="group.base">
        <button v-if="group.items.length === 1" class="lang-option" type="button" role="option" :data-idx="group.items[0].flatIndex" :aria-selected="group.items[0].code === store.locale" :class="{ 'is-active': group.items[0].flatIndex === activeIndex }" @click="choose(group.items[0].code)">
          <span>{{ group.varietyLabel }}</span><small>{{ group.items[0].code }}</small>
        </button>
        <div v-else class="lang-variety">
          <div class="lang-variety-head">
            <span class="lang-variety-name">{{ group.varietyLabel }}</span>
            <small>{{ group.base }}</small>
          </div>
          <div class="lang-scripts" role="group" :aria-label="group.varietyLabel">
            <button v-for="item in group.items" :key="item.code" class="lang-script" type="button" role="option" :data-idx="item.flatIndex" :aria-selected="item.code === store.locale" :class="{ 'is-active': item.flatIndex === activeIndex }" @click="choose(item.code)">{{ item.scriptLabel || item.code }}</button>
          </div>
        </div>
      </template>
      <span v-if="!groupedWithOptions.length" class="lang-empty">{{ t('languageSwitcher.noResults') }}</span>
      <button class="translate-link" type="button" @click="openWorkbench"><Languages :size="12" aria-hidden="true" />{{ t('translate.title') }}</button>
    </div>
  </div>
</template>

<style scoped>
.lang-switcher { position: relative; display: inline-flex; }
.lang-switch {
  display: inline-flex; align-items: center; gap: 5px;
  height: 30px; padding: 0 10px;
  border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); cursor: pointer;
  font-family: var(--mono); font-size: 10px;
  color: var(--muted); transition: color 0.15s, background 0.15s, border-color 0.15s;
}
.lang-switch:hover { background: var(--bg); color: var(--fg); }
.lang-switch:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.ls-code { letter-spacing: 0.04em; }
.lang-menu { position: absolute; top: 100%; z-index: 50; margin-top: 6px; right: 0; width: 240px; max-height: 320px; overflow: auto; padding: 6px; background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); box-shadow: 0 8px 24px -8px rgba(0, 0, 0, 0.18); animation: lang-menu-in 0.15s ease-out; }
@keyframes lang-menu-in { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
@media (prefers-reduced-motion: reduce) { .lang-menu { animation: none; } .lang-option, .lang-script, .lang-switch { transition: none; } }
.lang-search { width: 100%; min-height: 36px; border: 1px solid var(--border); padding: 6px 8px; }
.lang-search:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.lang-option { display: flex; justify-content: space-between; width: 100%; min-height: 32px; align-items: center; border: 0; border-radius: var(--r); background: transparent; text-align: left; padding: 4px 8px; cursor: pointer; font-size: 14px; transition: background 0.15s, color 0.15s; }
.lang-option:hover { background: var(--bg); }
.lang-option[aria-selected="true"] { color: var(--accent); font-weight: 600; }
.lang-option.is-active { background: var(--surface-2); }
.lang-option.is-active[aria-selected="true"] { background: var(--accent-soft); }
.lang-option:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.lang-option small { color: var(--muted); font-family: var(--mono); font-size: 10px; }
.lang-variety { display: flex; flex-direction: column; gap: 4px; padding: 4px 8px; }
.lang-variety-head { display: flex; justify-content: space-between; align-items: center; min-height: 32px; }
.lang-variety-name { font-size: 13px; color: var(--fg); }
.lang-variety-head small { color: var(--muted); font-family: var(--mono); font-size: 10px; }
.lang-scripts { display: inline-flex; align-self: flex-start; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.lang-script { min-height: 26px; padding: 2px 10px; border: 0; background: transparent; cursor: pointer; font-size: 11px; color: var(--muted); transition: background 0.15s, color 0.15s; }
.lang-script:hover { background: var(--bg); color: var(--fg); }
.lang-script[aria-selected="true"] { background: var(--accent); color: var(--surface); }
.lang-script.is-active:not([aria-selected="true"]) { background: var(--surface-2); color: var(--fg); }
.lang-script:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.lang-empty { display: block; padding: 12px 8px; color: var(--muted); }
.translate-link { display:flex; align-items:center; gap:6px; width:100%; min-height:36px; margin-top:6px; padding:6px 8px; border:0; border-top:1px solid var(--border); background:transparent; color:var(--accent); cursor:pointer; font-size:13px; text-align:left; }
.translate-link:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
@media (max-width: 768px) {
  .lang-switch { height: 44px; padding: 0 12px; }
  .lang-option, .lang-variety-head { min-height: 44px; }
  .lang-script { min-height: 44px; padding: 6px 16px; }
  .translate-link { min-height: 44px; }
}
</style>
