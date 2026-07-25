<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import { useLanguages } from '@/composables/useLanguages'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappings } = useExpressions()
const { list } = useLanguages()

const mapEl = ref<HTMLElement>()
let map: L.Map | null = null
const anchor = ref<any>(null)
const mappingData = ref<any[]>([])
const langMap = ref<Record<string, any>>({})
const loading = ref(true)
const loadError = ref('')
const activeId = ref<number | null>(null)

const pins = computed(() =>
  mappingData.value
    .filter((m: any) => langMap.value[m.language_code])
    .map((m: any) => {
      const lang = langMap.value[m.language_code]
      return { ...m, lat: lang.region_latitude, lng: lang.region_longitude, region: lang.region_name || lang.name, tier: pinTier(m.score) }
    })
)

const regionCount = computed(() => {
  const regions = new Set(pins.value.map((p: any) => p.region))
  if (anchor.value && anchorLang.value) regions.add(anchorLang.value.region_name || anchorLang.value.name)
  return regions.size
})

function pinTier(score: number) {
  if (score >= 20) return 's3'
  if (score >= 5) return 's2'
  return 's1'
}

const anchorLang = computed(() => anchor.value ? langMap.value[anchor.value.language_code] : null)

function sync(exprId: number | null) { activeId.value = exprId }

function openMapping(exprId: number) {
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
    L.marker([lang.region_latitude, lang.region_longitude], { icon })
      .bindPopup(`<b>${anchor.value.text}</b><br/>${anchor.value.language_code} · 錨點`)
      .addTo(m)
  }

  pins.value.forEach(p => {
    if (!p.lat || !p.lng) return
    const color = tierColor(p.tier)
    const icon = L.divIcon({
      className: 'pin-marker',
      html: `<div class="pin-dot" style="background:${color}"></div>`,
      iconSize: [20, 20],
      iconAnchor: [10, 10]
    })
    L.marker([p.lat, p.lng], { icon })
      .bindPopup(`<b>${p.text}</b><br/>${p.language_code} · ${p.region} · ${p.score >= 0 ? '+' : ''}${p.score}`)
      .addTo(m)
  })
}

async function load() {
  loading.value = true
  loadError.value = ''
  anchor.value = null
  mappingData.value = []
  try {
    const [langs, expr, maps] = await Promise.all([
      list(),
      detail(id.value),
      mappings(id.value, 2),
    ])
    const lm: Record<string, any> = {}
    for (const l of langs) if (l.region_latitude && l.region_longitude) lm[l.code] = l
    langMap.value = lm
    anchor.value = expr
    mappingData.value = maps

    await nextTick()
    initMap()
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
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
    if (anchorLang.value) bounds.extend([anchorLang.value.region_latitude, anchorLang.value.region_longitude])
    map.fitBounds(bounds, { padding: [40, 40] })
  }
}

onMounted(load)
watch(id, () => {
  if (map) { map.remove(); map = null }
  load()
})

function cleanup() { if (map) { map.remove(); map = null } }
onUnmounted(cleanup)
</script>

<template>
  <div class="lens-page">
    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <template v-else-if="anchor">
      <div class="lens-head">
        <router-link :to="`/mapping/${id}`" class="lens-back">← 回對照集</router-link>
        <h1>概念分布:<span class="anc">{{ anchor.text }}</span></h1>
        <span class="lens-meta">{{ pins.length + 1 }} 種語言 · {{ regionCount }} 地區</span>
      </div>

      <EmptyState v-if="pins.length === 0" message="此概念尚無地理分布資料" />

      <div v-else class="lens-layout">
        <div class="lens-map-wrap">
          <div ref="mapEl" class="leaflet-map"></div>
        </div>

        <aside class="lens-list">
          <div class="lens-list-head">對照集成員</div>
          <router-link
            :to="`/mapping/${id}`"
            :class="['lens-item', 'anchor', { active: activeId === anchor.id }]"
            @focus="sync(anchor.id)"
            @blur="sync(null)"
            @mouseenter="sync(anchor.id)"
            @mouseleave="sync(null)"
          >
            <span class="lc">{{ anchor.language_code }}</span>
            <span class="tx">{{ anchor.text }}</span>
            <span class="meta">錨點</span>
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
            <span class="lc">{{ p.language_code }}</span>
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
