<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import RadialGraph from '@/components/mapping/RadialGraph.vue'
import MappingList from '@/components/mapping/MappingList.vue'
import LangBadge from '@/components/expression/LangBadge.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { ArrowUpRight, Plus, ChevronRight } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappings } = useExpressions()

const expr = ref<any>(null)
const mappingData = ref<any[]>([])
const hops = ref(1)
const loading = ref(true)
const loadError = ref('')

const MAX_HOPS = 3

async function load() {
  expr.value = null
  mappingData.value = []
  loading.value = true
  loadError.value = ''
  try {
    expr.value = await detail(id.value)
    mappingData.value = await mappings(id.value, hops.value)
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
}

onMounted(load)
watch(id, load)

async function changeHops(h: number) {
  hops.value = h
  try {
    mappingData.value = await mappings(id.value, h)
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  }
}

function selectNode(nodeId: number) {
  router.push(`/mapping/${nodeId}`)
}

// 對照集 meta — direct (1-hop) vs indirect (2-hop) counts
const directCount = computed(() => mappingData.value.filter(m => m.hops === 1).length)
const indirectCount = computed(() => mappingData.value.filter(m => m.hops === 2).length)

const coords = computed(() => {
  const lat = expr.value?.region_latitude
  const lng = expr.value?.region_longitude
  if (lat == null || lng == null) return null
  return `${lat}°N · ${lng}°E`
})

const sourceLabel = computed(() => {
  const t = expr.value?.source_type
  if (t === 'auth') return '權威'
  if (t === 'ai') return 'AI'
  if (t === 'user') return '用戶'
  return t || ''
})
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="expr" class="anchor">
    <nav class="crumbs" aria-label="麵包屑">
      <router-link to="/">首頁</router-link>
      <span class="sep">/</span>
      <span>{{ expr.text }}</span>
    </nav>

    <div class="anchor-title">
      <h1>{{ expr.text }}</h1>
      <LangBadge :code="expr.language_code" />
    </div>

    <div class="anchor-meta">
      <span>{{ expr.language_name }}</span>
      <span v-if="expr.region_name">· {{ expr.region_name }}</span>
      <span v-if="sourceLabel" :class="['src-tag', expr.source_type]">{{ sourceLabel }}</span>
      <span v-if="coords" class="mono coords">{{ coords }}</span>
    </div>

    <div class="anchor-acts">
      <router-link :to="`/contribute`" class="btn btn-primary btn-sm">
        <Plus :size="14" aria-hidden="true" /> 添加映射
      </router-link>
      <router-link :to="`/map/${expr.id}`" class="btn btn-sm">
        <ArrowUpRight :size="14" aria-hidden="true" /> 在地圖看此概念
      </router-link>
    </div>

    <div class="nb-head">
      <h2>對照集</h2>
      <span class="nb-meta">
        <b>{{ directCount }}</b> 直接映射<template v-if="indirectCount"> · <b>{{ indirectCount }}</b> 間接</template>
        · 預設 <b>{{ hops }} 跳</b><template v-if="hops < MAX_HOPS"> · 可展開至 {{ MAX_HOPS }} 跳</template>
      </span>
    </div>

    <template v-if="mappingData.length">
      <RadialGraph
        :anchor-id="expr.id"
        :anchor-text="expr.text"
        :anchor-lang="expr.language_code"
        :mappings="mappingData"
        @select="selectNode"
      />

      <div class="expand-hop">
        <span>顯示半徑:</span>
        <span class="hop-ring" :aria-label="`目前 ${hops} 跳`">
          <i
            v-for="h in MAX_HOPS"
            :key="h"
            class="hop-dot"
            :class="{ off: h > hops }"
          />
        </span>
        <button
          v-if="hops < MAX_HOPS"
          type="button"
          @click="changeHops(Math.min(hops + 1, MAX_HOPS))"
        >
          展開至 {{ Math.min(hops + 1, MAX_HOPS) }} 跳 →
        </button>
        <button v-else type="button" disabled>已展開 {{ MAX_HOPS }} 跳 ✓</button>
      </div>

      <MappingList :mappings="mappingData" />
    </template>

    <div v-else class="md-empty">
      <EmptyState message="尚無對照映射" />
      <router-link to="/contribute" class="btn btn-primary btn-sm">
        <ChevronRight :size="14" aria-hidden="true" /> 貢獻映射
      </router-link>
    </div>
  </div>
</template>

<style scoped>
.anchor { max-width: 920px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.crumbs {
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase;
  color: var(--muted); display: flex; gap: 6px; align-items: center; margin-bottom: 16px;
}
.crumbs a:hover { color: var(--fg); }
.crumbs .sep { opacity: 0.5; }
.anchor-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 8px; }
.anchor-title h1 { font-size: 30px; font-weight: 600; letter-spacing: -0.02em; }
.anchor-meta { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; color: var(--muted); font-size: 13px; }
.anchor-meta .coords { font-size: 11px; }
.anchor-acts { display: flex; gap: 8px; margin-top: var(--space-base); flex-wrap: wrap; }

.expand-hop {
  margin: var(--space-md) 0 var(--space-base); display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
  font-family: var(--mono); font-size: 11px; color: var(--muted);
}
.expand-hop button {
  font-family: var(--mono); font-size: 11px; letter-spacing: 0.04em; text-transform: uppercase;
  background: var(--surface); border: 1px solid var(--border); color: var(--fg);
  padding: 6px 12px; border-radius: var(--r); cursor: pointer;
}
.expand-hop button:hover:not(:disabled) { border-color: var(--accent); color: var(--accent); }
.expand-hop button:disabled { color: var(--faint); cursor: default; }
.hop-ring { display: inline-flex; gap: 3px; align-items: center; }
.hop-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--accent); }
.hop-dot.off { background: var(--border); }

.md-empty { display: flex; flex-direction: column; align-items: center; gap: var(--space-sm); margin: var(--space-lg) 0; }
</style>
