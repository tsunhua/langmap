<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import RadialGraph from '@/components/mapping/RadialGraph.vue'
import MappingList from '@/components/mapping/MappingList.vue'
import LangBadge from '@/components/expression/LangBadge.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappings } = useExpressions()

const expr = ref<any>(null)
const mappingData = ref<any[]>([])
const hops = ref(1)
const loading = ref(true)
const loadError = ref('')

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
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="expr" class="md-page">
    <div class="crumbs">
      <router-link to="/languages">語言</router-link> / {{ expr.language_name }}
    </div>

    <div class="anchor-title">
      <h1>{{ expr.text }}</h1>
      <LangBadge :code="expr.language_code" />
    </div>

    <div class="anchor-meta">
      <span v-if="expr.region_name">{{ expr.region_name }}</span>
      <span v-if="expr.source_type" :class="['src-tag', expr.source_type]">{{ expr.source_type }}</span>
    </div>

    <div class="nb-head">
      <span>對照集</span>
      <span class="hint">{{ mappingData.length }} 個映射</span>
    </div>

    <RadialGraph
      :anchor-id="expr.id"
      :anchor-text="expr.text"
      :anchor-lang="expr.language_code"
      :mappings="mappingData"
      @select="selectNode"
    />

    <div class="hop-controls">
      <button
        v-for="h in [1, 2]"
        :key="h"
        :class="['btn btn-sm', hops === h ? 'btn-primary' : 'btn-ghost']"
        @click="changeHops(h)"
      >
        {{ h }}-hop
      </button>
    </div>

    <MappingList :mappings="mappingData" />
  </div>
</template>

<style scoped>
.md-page { max-width: 900px; margin: 0 auto; }
.crumbs { font-size: 13px; color: #4A6FA5; margin-bottom: 8px; }
.anchor-title { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.anchor-meta { display: flex; gap: 8px; margin-bottom: 16px; font-size: 13px; color: #4A6FA5; }
.hint { font-size: 12px; color: #4A6FA5; font-weight: 400; }
.hop-controls { display: flex; gap: 6px; margin: 16px 0 8px; }
</style>
