<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLanguages } from '@/composables/useLanguages'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()
const code = computed(() => route.params.code as string)

const { loading, detail, expressions } = useLanguages()

const lang = ref<any>(null)
const exprs = ref<any[]>([])
const searchQuery = ref('')
const sortBy = ref('hot')
const selectedScript = ref('')
const loadError = ref('')

function scriptSuffix(profile: any): string {
  const prefix = profile.base_language ? `${profile.base_language}-` : `${code.value}-`
  const suffix = profile.code.startsWith(prefix) ? profile.code.slice(prefix.length) : profile.code
  return suffix.replace(/-x-[^-]+$/, '')
}

const scripts = computed(() => {
  const profiles: any[] = lang.value?.profiles ?? []
  return profiles.map((p) => ({
    code: scriptSuffix(p),
    profileCode: p.code,
    script_code: p.script_code,
    name: p.name || p.script_code || p.code,
    endonym: p.endonym || '',
  }))
})

const selectedProfile = computed(() => {
  const bySuffix = scripts.value.find((s) => s.code === selectedScript.value)
  if (bySuffix) return bySuffix
  return scripts.value.find((s) => s.script_code === selectedScript.value)
})

const scriptParam = computed(() => selectedProfile.value?.profileCode)

const title = computed(() =>
  selectedProfile.value?.endonym || lang.value?.name_en || lang.value?.name || '',
)

function cityDisplayName(city: any): string {
  const profileCode = selectedProfile.value?.profileCode
  if (!profileCode) {
    const en = city?.city_name_en
    const pinyin = city?.city_name
    if (en && pinyin && en !== pinyin) return `${en} (${pinyin})`
    return en || pinyin
  }
  if (!city?.city_name_localized) return city?.city_name
  try {
    const localized = JSON.parse(city.city_name_localized)
    return localized[profileCode] || city.city_name
  } catch {
    return city.city_name
  }
}

const filtered = computed(() => {
  if (!searchQuery.value) return exprs.value
  const q = searchQuery.value.toLowerCase()
  return exprs.value.filter((e: any) => e.text.toLowerCase().includes(q))
})

async function loadScript() {
  try {
    const data = await expressions(code.value, { sort: sortBy.value, limit: 100, script: scriptParam.value })
    exprs.value = data.items
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('languageDetail.loadFailed')
  }
}

async function load() {
  lang.value = null
  loadError.value = ''
  const q = route.query.script
  selectedScript.value = typeof q === 'string' ? q : ''
  try {
    lang.value = await detail(code.value)
    await loadScript()
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('languageDetail.loadFailed')
  }
}

onMounted(load)
watch(code, load)
watch(() => route.query.script, (script) => {
  const next = typeof script === 'string' ? script : ''
  if (next !== selectedScript.value) {
    selectedScript.value = next
    loadScript()
  }
})

const subtitle = computed(() => {
  const parts = []
  if (lang.value?.name_en && title.value !== lang.value.name_en) parts.push(lang.value.name_en)
  if (lang.value?.glottocode) parts.push(lang.value.glottocode)
  return parts.join(' · ')
})

async function changeSort(sort: string) {
  sortBy.value = sort
  await loadScript()
}

async function changeScript(script: string) {
  if (script === selectedScript.value) return
  selectedScript.value = script
  const query = { ...route.query }
  if (script) query.script = script
  else delete query.script
  router.replace({ query })
  await loadScript()
}
</script>

<template>
  <LoadingSpinner v-if="loading && !lang" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="lang" class="ld-page">
    <router-link to="/languages" class="ld-back">← {{ t('languageDetail.back') }}</router-link>

    <div class="ld-title">
      <h1>{{ title }}</h1>
      <span v-if="scripts.length <= 1" class="lang-badge">{{ lang.code }}</span>
    </div>
    <div v-if="scripts.length > 1" class="ld-scripts" role="group" :aria-label="t('languageDetail.scriptLabel')">
      <button :class="{ on: selectedScript === '' }" @click="changeScript('')">
        <span>{{ t('languageDetail.allScripts') }}</span>
        <small>{{ lang.code }}</small>
      </button>
      <button v-for="s in scripts" :key="s.code" :class="{ on: selectedScript === s.code }" @click="changeScript(s.code)">
        <span>{{ s.name }}</span>
        <small>{{ s.profileCode }}</small>
      </button>
    </div>
    <p class="ld-sub" v-if="subtitle">{{ subtitle }}</p>

    <div class="ld-stats">
      <StatBox :label="t('languageDetail.expressions')" :value="lang.expression_count" />
      <StatBox :label="t('languageDetail.mapped')" :value="lang.mapped_expression_count" />
    </div>

    <section v-if="lang.representative_cities?.length" class="ld-cities" aria-labelledby="representative-cities-title">
      <h2 id="representative-cities-title">{{ t('languageDetail.representativeCities') }}</h2>
      <p class="ld-cities-note">{{ t('languageDetail.representativeCitiesNote') }}</p>
      <ul>
        <li v-for="city in lang.representative_cities" :key="`${city.city_name}-${city.territory_code}-${city.script_code}`">
          <span>{{ cityDisplayName(city) }}</span>
          <small>{{ city.territory_code }}<template v-if="city.script_code"> · {{ city.script_code }}</template></small>
        </li>
      </ul>
    </section>

    <div class="ld-toolbar">
      <SearchBar v-model="searchQuery" :placeholder="t('languageDetail.searchPlaceholder')" style="flex: 1;" />
      <div class="ld-sort">
        <button :class="{ on: sortBy === 'hot' }" @click="changeSort('hot')">{{ t('languageDetail.popular') }}</button>
        <button :class="{ on: sortBy === 'new' }" @click="changeSort('new')">{{ t('languageDetail.latest') }}</button>
        <button :class="{ on: sortBy === 'alpha' }" @click="changeSort('alpha')">{{ t('languageDetail.alphabetical') }}</button>
      </div>
    </div>

    <EmptyState v-if="filtered.length === 0" :message="t('languageDetail.noResults')" />

    <div v-else class="ld-list">
      <ExpressionRow
        v-for="expr in filtered"
        :key="expr.id"
        v-bind="expr"
        :show-language="false"
      />
    </div>
  </div>
</template>

<style scoped>
.ld-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.ld-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.ld-back:hover { color: var(--fg); }
.ld-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 6px; }
.ld-title h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.ld-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: var(--space-base); }
.ld-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.ld-sort button { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; border: none; background: var(--surface); color: var(--muted); cursor: pointer; height: 30px; padding: 0 16px; transition: background 0.15s, color 0.15s; }
.ld-sort button:hover { color: var(--fg); }
.ld-sort button.on { background: var(--fg); color: var(--surface); }
.ld-sort button:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.ld-scripts { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; margin: 6px 0; }
.ld-scripts button { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; border: none; background: var(--surface); color: var(--muted); cursor: pointer; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; line-height: 1.1; height: 40px; padding: 0 14px; transition: background 0.15s, color 0.15s; }
.ld-scripts button small { font-size: 9px; letter-spacing: 0.08em; opacity: 0.7; }
.ld-scripts button:hover { color: var(--fg); }
.ld-scripts button:hover small { opacity: 0.9; }
.ld-scripts button.on { background: var(--fg); color: var(--surface); }
.ld-scripts button.on small { opacity: 0.75; }
.ld-scripts button:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
@media (max-width: 640px) {
  .ld-scripts button { height: 44px; padding: 0 16px; }
}
.ld-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.ld-sub { font-size: 13px; color: var(--muted); margin-top: 4px; }
.ld-cities { border-bottom: 1px solid var(--border); margin-bottom: 18px; padding-bottom: 16px; }
.ld-cities h2 { font-size: 16px; font-weight: 600; }
.ld-cities-note { color: var(--muted); font-size: 12px; margin: 4px 0 10px; }
.ld-cities ul { display: flex; flex-wrap: wrap; gap: 8px; list-style: none; padding: 0; margin: 0; }
.ld-cities li { width: fit-content; min-width: 0; border: 1px solid var(--border); background: var(--surface); padding: 8px 10px; }
.ld-cities li span, .ld-cities li small { display: block; }
.ld-cities li small { color: var(--muted); font-family: var(--mono); font-size: 10px; margin-top: 3px; }
</style>
