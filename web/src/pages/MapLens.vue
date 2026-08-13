<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import { listLanguageLocales, type LanguageLocale } from '@/api/languageIdentity'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { getPrimaryIncomingEdge } from '@/components/mapping/mappingGraphModel'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()
const id = computed(() => route.params.id as string)

const { detail: getExpressionDetail, mappingGraph } = useExpressions()

const mapEl = ref<HTMLElement>()
let map: L.Map | null = null
const anchor = ref<{ id: string; lang_code: string; text: string } | null>(null)
const graph = ref<MappingGraphResponse | null>(null)
const langMap = ref<Record<string, LanguageLocale>>({})
const loading = ref(true)
const loadError = ref('')
const activeId = ref<string | null>(null)
let loadRequest = 0

interface Pin {
  expression_id: string
  text: string
  lang_code: string
  score: number
  lat: number
  lng: number
  region: string
  tier: 's1' | 's2' | 's3'
}

const pins = computed<Pin[]>(() => {
  const g = graph.value
  if (!g) return []
  const lm = langMap.value
  const out: Pin[] = []
  for (const n of g.nodes) {
    if (n.depth === 0) continue
    const lang = lm[n.lang_code]
    if (!lang || lang.latitude == null || lang.longitude == null) continue
    const edge = getPrimaryIncomingEdge(n.expression_id, g)
    const score = edge?.score ?? 0
    out.push({
      expression_id: n.expression_id,
      text: n.text,
      lang_code: n.lang_code,
      score,
      lat: lang.latitude,
      lng: lang.longitude,
      region: lang.name,
      tier: pinTier(score),
    })
  }
  return out
})

const regionCount = computed(() => {
  const regions = new Set(pins.value.map((p) => p.region))
  if (anchor.value && anchorLang.value) regions.add(anchorLang.value.name)
  return regions.size
})

function pinTier(score: number): 's1' | 's2' | 's3' {
  if (score >= 20) return 's3'
  if (score >= 5) return 's2'
  return 's1'
}

const anchorLang = computed(() => anchor.value ? langMap.value[anchor.value.lang_code] : null)

function sync(exprId: string | null) { activeId.value = exprId }

function openMapping(exprId: string) {
  router.push(`/mapping/${exprId}`)
}

function tierColor(tier: string) {
  if (tier === 's3') return '#b83b3b'
  if (tier === 's2') return '#c76c3a'
  return '#c7a83a'
}

function addMarkers() {
  if (!map) return
  const m = map

  if (anchorLang.value && anchor.value) {
    const lang = anchorLang.value
    const icon = L.divIcon({
      className: 'pin-marker anchor-marker',
      html: `<div class="pin-dot anchor-dot"></div>`,
      iconSize: [24, 24],
      iconAnchor: [12, 12]
    })
    L.marker([lang.latitude!, lang.longitude!], { icon })
      .bindPopup(`<b>${anchor.value.text}</b><br/>${anchor.value.lang_code} · ${t('mapLens.anchor')}`)
      .addTo(m)
  }

  pins.value.forEach(p => {
    if (!Number.isFinite(p.lat) || !Number.isFinite(p.lng)) return
    const color = tierColor(p.tier)
    const icon = L.divIcon({
      className: 'pin-marker',
      html: `<div class="pin-dot" style="background:${color}"></div>`,
      iconSize: [20, 20],
      iconAnchor: [10, 10]
    })
    L.marker([p.lat, p.lng], { icon })
      .bindPopup(`<b>${p.text}</b><br/>${p.lang_code} · ${p.region} · ${p.score >= 0 ? '+' : ''}${p.score}`)
      .addTo(m)
  })
}

async function load() {
  const request = ++loadRequest
  const requestedId = id.value
  loading.value = true
  loadError.value = ''
  anchor.value = null
  graph.value = null
  try {
    const [localePage, expressionDetail, g] = await Promise.all([
      listLanguageLocales({ limit: 200 }),
      getExpressionDetail(requestedId),
      mappingGraph(requestedId, 2),
    ])
    if (request !== loadRequest) return
    const lm: Record<string, LanguageLocale> = {}
    for (const locale of localePage.items) {
      if (locale.latitude != null && locale.longitude != null && !lm[locale.lang_code]) lm[locale.lang_code] = locale
    }
    langMap.value = lm
    anchor.value = expressionDetail.expression
    graph.value = g
  } catch (e: any) {
    if (request !== loadRequest) return
    loadError.value = e.response?.data?.error || t('mapLens.loadFailed')
  } finally {
    if (request === loadRequest) loading.value = false
  }
  if (request !== loadRequest) return
  if (loadError.value || !anchor.value) return
  await nextTick()
  if (request !== loadRequest) return
  initMap()
}

function initMap() {
  if (map) { map.remove(); map = null }
  if (!mapEl.value) return

  map = L.map(mapEl.value, { zoomControl: true }).setView([20, 0], 2)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(map)

  addMarkers()

  if (pins.value.length > 0) {
    const bounds = L.latLngBounds(pins.value.map(p => [p.lat, p.lng]))
    if (anchorLang.value?.latitude != null && anchorLang.value.longitude != null) bounds.extend([anchorLang.value.latitude, anchorLang.value.longitude])
    map.fitBounds(bounds, { padding: [40, 40] })
  }
}

onMounted(load)
watch(id, () => {
  if (map) { map.remove(); map = null }
  load()
})

function cleanup() {
  loadRequest++
  if (map) { map.remove(); map = null }
}
onUnmounted(cleanup)
</script>

<template>
  <div class="lens-page">
    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <template v-else-if="anchor">
      <div class="lens-head">
        <router-link :to="`/mapping/${id}`" class="lens-back">← {{ t('mapLens.back') }}</router-link>
        <h1>{{ t('mapLens.title') }}:<span class="anc">{{ anchor.text }}</span></h1>
        <span class="lens-meta">{{ t('mapLens.languages', { count: pins.length + 1 }) }} · {{ t('mapLens.regions', { count: regionCount }) }}</span>
      </div>

      <EmptyState v-if="pins.length === 0" :message="t('mapLens.noData')" />

      <div v-else class="lens-layout">
        <div class="lens-map-wrap">
          <div ref="mapEl" class="leaflet-map"></div>
        </div>

        <aside class="lens-list">
          <div class="lens-list-head">{{ t('mapLens.members') }}</div>
          <router-link
            :to="`/mapping/${id}`"
            :class="['lens-item', 'anchor', { active: activeId === anchor.id }]"
            @focus="sync(anchor.id)"
            @blur="sync(null)"
            @mouseenter="sync(anchor.id)"
            @mouseleave="sync(null)"
          >
            <span class="lc">{{ anchor.lang_code }}</span>
            <span class="tx">{{ anchor.text }}</span>
            <span class="meta">{{ t('mapLens.anchor') }}</span>
          </router-link>
          <router-link
            v-for="p in pins"
            :key="p.expression_id"
            :to="`/mapping/${p.expression_id}`"
            :class="['lens-item', { active: activeId === p.expression_id }]"
            @focus="sync(p.expression_id)"
            @blur="sync(null)"
            @mouseenter="sync(p.expression_id)"
            @mouseleave="sync(null)"
          >
            <span class="lc">{{ p.lang_code }}</span>
            <span class="tx">{{ p.text }}</span>
            <span class="meta">{{ p.score >= 0 ? '+' : '' }}{{ p.score }}</span>
          </router-link>
        </aside>
      </div>
    </template>
  </div>
</template>

<style scoped>
.lens-page { max-width: 1100px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.lens-head { display: flex; align-items: baseline; gap: 14px; flex-wrap: wrap; margin-bottom: 18px; }
.lens-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); text-decoration: none; }
.lens-back:hover { color: var(--fg); }
.lens-head h1 { font-size: 20px; font-weight: 600; letter-spacing: -0.02em; margin: 0; }
.lens-head h1 .anc { color: var(--accent); }
.lens-meta { font-family: var(--mono); font-size: 11px; color: var(--muted); }

.lens-layout { display: grid; grid-template-columns: 1fr 280px; gap: 16px; align-items: stretch; }

.lens-map-wrap {
  border: 1px solid var(--border); border-radius: 8px; overflow: hidden;
}
.leaflet-map {
  width: 100%; height: 500px;
}

.lens-list {
  border: 1px solid var(--border); border-radius: 8px; background: var(--surface);
  overflow: auto; max-height: 500px;
}
.lens-list-head {
  padding: 10px 12px; font-family: var(--mono); font-size: 10px;
  letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted);
  border-bottom: 1px solid var(--border); position: sticky; top: 0; background: var(--surface);
}
.lens-item {
  display: grid; grid-template-columns: 40px 1fr auto; gap: 8px; align-items: center;
  padding: 9px 12px; border-bottom: 1px solid var(--border); color: inherit;
  text-decoration: none; transition: background 0.1s;
}
.lens-item:last-child { border-bottom: none; }
.lens-item:hover, .lens-item.active { background: var(--accent-soft); }
.lens-item .lc { font-family: var(--mono); font-size: 10px; color: var(--muted); }
.lens-item .tx { font-size: 13px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lens-item .meta { font-family: var(--mono); font-size: 10px; color: var(--muted); text-align: right; white-space: nowrap; }
.lens-item.anchor .lc, .lens-item.anchor .meta { color: var(--accent); }

@media (max-width: 768px) {
  .lens-layout { grid-template-columns: 1fr; }
  .leaflet-map { height: 350px; }
  .lens-list { max-height: none; }
  .lens-item { min-height: 44px; }
}
</style>

<style>
.pin-marker {
  background: transparent !important;
  border: none !important;
}
.pin-dot {
  width: 16px; height: 16px; border-radius: 50%;
  border: 2px solid #fff;
  box-shadow: 0 1px 4px rgba(0,0,0,0.3);
  transition: transform 0.12s;
}
.pin-dot:hover { transform: scale(1.25); }
.anchor-dot {
  width: 20px; height: 20px;
  background: #3b82f6 !important;
  box-shadow: 0 0 0 4px rgba(59,130,246,0.25), 0 1px 4px rgba(0,0,0,0.3);
}
</style>
