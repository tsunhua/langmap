<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Globe, ChevronDown, Languages } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { useLocalizationStore } from '@/stores/localization'
import type { UiLocale } from '@/api/localization'
import { useI18n } from 'vue-i18n'

const store = useLocalizationStore()
const { t } = useI18n()
const router = useRouter()
const open = ref(false)
const query = ref('')
const filtered = computed(() => store.locales.filter((item: UiLocale) => `${item.code} ${item.name} ${item.native_name || ''}`.toLowerCase().includes(query.value.toLowerCase())))
onMounted(() => { void store.loadLocales() })
async function choose(code: string) { await store.setLocale(code); open.value = false }
function openWorkbench() { open.value = false; router.push('/translate') }
</script>

<template>
  <button class="lang-switch" type="button" :aria-label="t('nav.switchLanguage')" aria-haspopup="listbox" :aria-expanded="open" @click="open = !open">
    <Globe :size="14" aria-hidden="true" />
    <span class="ls-code">{{ store.locale }}</span>
    <ChevronDown :size="12" aria-hidden="true" />
  </button>
  <div v-if="open" class="lang-menu" role="listbox" :aria-label="t('nav.switchLanguage')">
    <input v-model="query" type="search" :placeholder="t('common.search')" class="lang-search" />
    <button v-for="item in filtered" :key="item.code" class="lang-option" role="option" :aria-selected="item.code === store.locale" @click="choose(item.code)">
      <span>{{ item.native_name || item.name }}</span><small>{{ item.code }}</small>
    </button>
    <span v-if="!filtered.length" class="lang-empty">{{ t('languageSwitcher.noResults') }}</span>
    <button class="translate-link" type="button" @click="openWorkbench"><Languages :size="14" aria-hidden="true" />{{ t('translate.title') }}</button>
  </div>
</template>

<style scoped>
.lang-switch {
  display: inline-flex; align-items: center; gap: 5px;
  height: 30px; padding: 0 10px;
  border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); cursor: pointer;
  font-family: var(--mono); font-size: 10px;
  color: var(--muted); transition: color 0.15s, background 0.15s;
}
.lang-switch:hover { background: var(--bg); color: var(--fg); }
.ls-code { letter-spacing: 0.04em; }
.lang-menu { position: absolute; z-index: 20; margin-top: 6px; right: 0; width: 240px; max-height: 320px; overflow: auto; padding: 8px; background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); }
.lang-search { width: 100%; min-height: 36px; border: 1px solid var(--border); padding: 6px 8px; }
.lang-option { display: flex; justify-content: space-between; width: 100%; min-height: 40px; align-items: center; border: 0; background: transparent; text-align: left; padding: 6px 8px; cursor: pointer; }
.lang-option:hover { background: var(--bg); }
.lang-option small { color: var(--muted); font-family: var(--mono); }
.lang-empty { display: block; padding: 12px 8px; color: var(--muted); }
.translate-link { display:flex; align-items:center; gap:7px; width:100%; margin-top:6px; padding:10px 8px; border:0; border-top:1px solid var(--border); background:transparent; color:var(--accent); cursor:pointer; text-align:left; }
@media (max-width: 768px) {
  .lang-switch { height: 44px; padding: 0 12px; }
}
</style>
