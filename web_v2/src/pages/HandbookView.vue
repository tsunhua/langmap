<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import VotePill from '@/components/mapping/VotePill.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const id = computed(() => parseInt(route.params.id as string))

const { detail } = useHandbooks()

const hb = ref<any>(null)
const loading = ref(true)
const loadError = ref('')

async function load() {
  hb.value = null
  loading.value = true
  loadError.value = ''
  try {
    hb.value = await detail(id.value)
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
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="hb" class="hv-layout">
    <aside class="hv-toc">
      <div class="hv-toc-label">目錄</div>
      <a v-for="(sec, i) in hb.sections" :key="sec.id" :href="`#sec-${i}`">
        {{ sec.title || `章節 ${i + 1}` }}
      </a>
    </aside>

    <main class="hv-content">
      <router-link to="/handbooks" class="hv-back">← 手冊列表</router-link>
      <h1>{{ hb.title }}</h1>
      <div class="hv-meta">
        <span v-if="hb.author_username">{{ hb.author_username }}</span>
        <span v-if="hb.visibility">{{ hb.visibility }}</span>
      </div>

      <div class="hv-vote-row">
        <VotePill :target-id="String(hb.id)" target-type="handbook" :score="hb.score" />
      </div>

      <section v-for="(sec, i) in hb.sections" :key="sec.id" :id="`sec-${i}`" class="hv-section">
        <div class="hv-sec-head">
          <span class="hv-sec-num">{{ i + 1 }}</span>
          <h2>{{ sec.title || `章節 ${i + 1}` }}</h2>
        </div>
        <ol v-if="sec.expressions?.length" class="hb-expr-list">
          <li v-for="(expr, j) in sec.expressions" :key="expr.expression_id">
            <router-link :to="`/mapping/${expr.expression_id}`" class="hb-expr">
              <span class="hb-num">{{ j + 1 }}</span>
              <span class="hb-tx">{{ expr.text }}</span>
              <span class="lang-badge">{{ expr.language_code }}</span>
              <span class="hb-go">→</span>
            </router-link>
          </li>
        </ol>
      </section>

      <router-link :to="`/handbook/${id}/edit`" class="btn btn-ghost" style="margin-top: 20px;">
        編輯手冊
      </router-link>
    </main>
  </div>
</template>

<style scoped>
.hv-layout { display: grid; grid-template-columns: 220px 1fr; gap: 24px; max-width: 1000px; margin: 0 auto; }
.hv-toc { position: sticky; top: 60px; align-self: start; }
.hv-toc-label { font-family: "IBM Plex Mono", monospace; font-size: 11px; text-transform: uppercase; color: #4A6FA5; margin-bottom: 8px; }
.hv-toc a { display: block; padding: 4px 0; font-size: 13px; color: #4A6FA5; text-decoration: none; }
.hv-toc a:hover { color: #8B4513; }
.hv-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.hv-meta { display: flex; gap: 10px; font-size: 13px; color: #4A6FA5; margin: 8px 0 16px; }
.hv-vote-row { margin-bottom: 20px; }
.hv-section { margin-bottom: 24px; }
.hv-sec-head { display: flex; align-items: center; gap: 8px; padding: 8px 0; border-bottom: 1px solid #EDE5D8; }
.hv-sec-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: #4A6FA5; }
.hb-expr-list { list-style: none; padding: 0; }
.hb-expr {
  display: grid; grid-template-columns: 26px 1fr 56px 16px;
  align-items: center; gap: 8px; padding: 6px 8px;
  text-decoration: none; color: inherit; border-bottom: 1px solid #EDE5D8;
}
.hb-expr:hover { background: #F5F0E8; }
.hb-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: #4A6FA5; }
.hb-go { color: #8B4513; }
@media (max-width: 700px) {
  .hv-layout { grid-template-columns: 1fr; }
  .hv-toc { position: static; }
}
</style>
