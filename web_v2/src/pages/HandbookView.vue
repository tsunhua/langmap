<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import VotePill from '@/components/mapping/VotePill.vue'
import { ChevronRight } from 'lucide-vue-next'
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
          <span class="hv-sec-num">§{{ i + 1 }}</span>
          <h2>{{ sec.title || `章節 ${i + 1}` }}</h2>
        </div>
        <ol v-if="sec.items?.length" class="hb-expr-list">
          <li v-for="(expr, j) in sec.items" :key="expr.expression_id">
            <router-link :to="`/mapping/${expr.expression_id}`" class="hb-expr">
              <span class="hb-num">{{ j + 1 }}</span>
              <span class="hb-tx">{{ expr.text }}</span>
              <span class="lang-badge">{{ expr.language_code }}</span>
              <span class="hb-go"><ChevronRight :size="14" aria-hidden="true" /></span>
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
.hv-layout { display: grid; grid-template-columns: 220px 1fr; gap: 36px; max-width: 1000px; margin: 0 auto; }
.hv-toc { position: sticky; top: 60px; align-self: start; }
.hv-toc-label { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); margin-bottom: 8px; }
.hv-toc a { display: block; padding: 4px 8px; font-size: 13px; color: var(--muted); text-decoration: none; border-left: 2px solid transparent; }
.hv-toc a:hover { color: var(--fg); background: var(--accent-soft); border-left-color: var(--accent); }
.hv-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.hv-back:hover { color: var(--fg); }
.hv-content h1 { font-size: 26px; font-weight: 600; letter-spacing: -0.02em; }
.hv-meta { display: flex; gap: 10px; font-size: 13px; color: var(--muted); margin: 8px 0 16px; padding-bottom: 14px; border-bottom: 1px solid var(--border); }
.hv-vote-row { margin-bottom: 20px; }
.hv-section { margin-bottom: 24px; padding-top: 18px; border-top: 1px solid var(--border); }
.hv-section:first-of-type { border-top: none; padding-top: 0; }
.hv-sec-head { display: flex; align-items: baseline; gap: 8px; margin-bottom: 6px; }
.hv-sec-head h2 { font-size: 16px; font-weight: 600; }
.hv-sec-num { font-family: var(--mono); font-size: 12px; color: var(--accent); }
.hb-expr-list { list-style: none; padding: 0; }
.hb-expr {
  display: grid; grid-template-columns: 26px 1fr 56px 16px;
  align-items: center; gap: 12px; padding: 9px 4px;
  text-decoration: none; color: inherit; border-bottom: 1px solid var(--border);
}
.hb-expr:hover { background: var(--bg); }
.hb-expr:hover .hb-tx { color: var(--accent); }
.hb-num { font-family: var(--mono); font-size: 12px; color: var(--muted); }
.hb-go { color: var(--accent); }
@media (max-width: 768px) {
  .hv-layout { grid-template-columns: 1fr; }
  .hv-toc { position: static; margin-bottom: 16px; }
}
</style>
