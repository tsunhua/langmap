<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import { useLanguages } from '@/composables/useLanguages'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappings } = useExpressions()
const { list } = useLanguages()

const anchor = ref<any>(null)
const mappingData = ref<any[]>([])
const langMap = ref<Record<string, any>>({})
const loading = ref(true)
const loadError = ref('')
const activeId = ref<number | null>(null)

function latLngToXY(lat: number, lng: number) {
  const x = ((lng + 180) / 360) * 100
  const y = ((90 - lat) / 180) * 100
  return { x, y }
}

function pinTier(score: number) {
  if (score >= 20) return 's3'
  if (score >= 5) return 's2'
  return 's1'
}

// Plottable mappings: those whose language has geo coordinates.
const pins = computed(() =>
  mappingData.value
    .filter((m: any) => langMap.value[m.language_code])
    .map((m: any) => {
      const lang = langMap.value[m.language_code]
      const { x, y } = latLngToXY(lang.region_latitude, lang.region_longitude)
      return { ...m, x, y, region: lang.region_name || lang.name, tier: pinTier(m.score) }
    })
)

const anchorLang = computed(() => anchor.value ? langMap.value[anchor.value.language_code] : null)
const anchorPos = computed(() => {
  if (!anchorLang.value) return null
  return latLngToXY(anchorLang.value.region_latitude, anchorLang.value.region_longitude)
})

function sync(exprId: number | null) { activeId.value = exprId }

function openMapping(exprId: number) {
  router.push(`/mapping/${exprId}`)
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
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
}

onMounted(load)
watch(id, load)
</script>

<template>
  <div class="lens-page">
    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <template v-else-if="anchor">
      <div class="lens-head">
        <router-link :to="`/mapping/${id}`" class="lens-back">← 回對照集</router-link>
        <h1>概念分布:<span class="anc">{{ anchor.text }}</span></h1>
        <span class="lens-meta">{{ pins.length + (anchorPos ? 1 : 0) }} 種語言</span>
      </div>

      <EmptyState v-if="pins.length === 0" message="此概念尚無地理分布資料" />

      <div v-else class="lens-layout">
        <div class="lens-map">
          <div class="map-art" aria-hidden="true"></div>
          <div class="map-graticule" aria-hidden="true"></div>

          <button
            v-if="anchorPos"
            class="pin anchor"
            :class="{ active: activeId === anchor.id }"
            :style="{ left: anchorPos.x + '%', top: anchorPos.y + '%' }"
            :aria-label="`${anchor.text} · ${anchor.language_code} · 錨點`"
            @click="openMapping(anchor.id)"
            @focus="sync(anchor.id)"
            @blur="sync(null)"
            @mouseenter="sync(anchor.id)"
            @mouseleave="sync(null)"
          >
            <span class="pin-label">{{ anchor.text }} · {{ anchor.language_code }} · 錨點</span>
          </button>

          <button
            v-for="p in pins"
            :key="p.expression_id"
            :class="['pin', p.tier, { active: activeId === p.expression_id }]"
            :style="{ left: p.x + '%', top: p.y + '%' }"
            :aria-label="`${p.text} · ${p.language_code} · ${p.region} · ${p.score >= 0 ? '+' : ''}${p.score}`"
            @click="openMapping(p.expression_id)"
            @focus="sync(p.expression_id)"
            @blur="sync(null)"
            @mouseenter="sync(p.expression_id)"
            @mouseleave="sync(null)"
          >
            <span class="pin-label">{{ p.text }} · {{ p.language_code }} · {{ p.region }} · {{ p.score >= 0 ? '+' : '' }}{{ p.score }}</span>
          </button>

          <div class="map-legend" aria-hidden="true">
            <div class="lr"><span class="lg anchor"></span> 錨點</div>
            <div class="lr"><span class="lg s3"></span> 評分高</div>
            <div class="lr"><span class="lg s2"></span> 評分中</div>
            <div class="lr"><span class="lg s1"></span> 評分低</div>
          </div>
        </div>

        <aside class="lens-list">
          <div class="lens-list-head">對照集成員</div>
          <router-link
            v-if="anchorPos"
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
.lens-page { max-width: 1100px; margin: 0 auto; padding: 24px 28px 60px; }
.lens-head { display: flex; align-items: baseline; gap: 14px; flex-wrap: wrap; margin-bottom: 18px; }
.lens-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); text-decoration: none; }
.lens-back:hover { color: var(--fg); }
.lens-head h1 { font-size: 20px; font-weight: 600; letter-spacing: -0.02em; margin: 0; }
.lens-head h1 .anc { color: var(--accent); }
.lens-meta { font-family: var(--mono); font-size: 11px; color: var(--muted); }

.lens-layout { display: grid; grid-template-columns: 1fr 280px; gap: 16px; align-items: stretch; }
.lens-map {
  position: relative; height: 70vh; min-height: 420px;
  border: 1px solid var(--border); border-radius: 8px; overflow: hidden;
  background:
    radial-gradient(circle, oklch(0.90 0.010 88) 1px, transparent 1px) 0 0 / 18px 18px,
    linear-gradient(oklch(0.84 0.030 218), oklch(0.80 0.025 218));
}
.map-art {
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 200px 150px at 25% 40%, oklch(0.90 0.030 218 / 0.55) 0%, transparent 100%),
    radial-gradient(ellipse 180px 120px at 65% 35%, oklch(0.90 0.030 218 / 0.55) 0%, transparent 100%),
    radial-gradient(ellipse 120px 100px at 45% 65%, oklch(0.90 0.030 218 / 0.55) 0%, transparent 100%),
    radial-gradient(ellipse 100px 80px at 80% 60%, oklch(0.90 0.030 218 / 0.55) 0%, transparent 100%);
}
.map-graticule {
  position: absolute; inset: 0; opacity: 0.25;
  background-image:
    linear-gradient(oklch(0.62 0.13 245) 1px, transparent 1px),
    linear-gradient(90deg, oklch(0.62 0.13 245) 1px, transparent 1px);
  background-size: 10% 10%;
}

.pin {
  position: absolute; transform: translate(-50%, -50%);
  border: 2px solid #fff; border-radius: 50%; padding: 0;
  box-shadow: 0 1px 4px oklch(0 0 0 / 0.3); cursor: pointer;
  transition: transform 0.12s, box-shadow 0.12s;
}
.pin:hover, .pin.active {
  transform: translate(-50%, -50%) scale(1.25);
  box-shadow: 0 0 0 3px color-mix(in oklch, var(--accent) 35%, transparent), 0 0 16px color-mix(in oklch, var(--accent) 45%, transparent);
  z-index: 4;
}
.pin.s3 { width: 24px; height: 24px; background: oklch(0.54 0.18 28); }
.pin.s2 { width: 18px; height: 18px; background: oklch(0.64 0.16 35); }
.pin.s1 { width: 12px; height: 12px; background: oklch(0.84 0.08 55); }
.pin.anchor { width: 22px; height: 22px; background: var(--accent); box-shadow: 0 0 0 4px color-mix(in oklch, var(--accent) 25%, transparent); }

.pin-label {
  position: absolute; left: 50%; transform: translateX(-50%);
  bottom: calc(100% + 6px);
  background: var(--fg); color: var(--surface);
  font-family: var(--mono); font-size: 10px;
  padding: 3px 6px; border-radius: 2px; white-space: nowrap;
  pointer-events: none; opacity: 0; transition: opacity 0.12s;
}
.pin:hover .pin-label, .pin.active .pin-label, .pin:focus-visible .pin-label { opacity: 1; }

.map-legend {
  position: absolute; left: 12px; bottom: 12px; z-index: 5;
  background: color-mix(in oklch, var(--surface) 90%, transparent); backdrop-filter: blur(8px);
  border: 1px solid var(--border); border-radius: var(--r); padding: 8px 10px;
  font-family: var(--mono); font-size: 10px; color: var(--muted);
  display: flex; flex-direction: column; gap: 4px;
}
.map-legend .lr { display: flex; align-items: center; gap: 6px; }
.map-legend .lg { width: 9px; height: 9px; border-radius: 50%; display: inline-block; }
.map-legend .lg.anchor { background: var(--accent); }
.map-legend .lg.s3 { background: oklch(0.54 0.18 28); }
.map-legend .lg.s2 { background: oklch(0.64 0.16 35); }
.map-legend .lg.s1 { background: oklch(0.84 0.08 55); }

.lens-list {
  border: 1px solid var(--border); border-radius: 8px; background: var(--surface);
  overflow: auto; max-height: 70vh;
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
  .lens-map { height: 50vh; min-height: 300px; }
  .lens-list { max-height: none; }
  .lens-item { min-height: 44px; }
}
</style>
