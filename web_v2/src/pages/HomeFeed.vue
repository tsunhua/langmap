<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFeed } from '@/composables/useFeed'
import MappingCard from '@/components/feed/MappingCard.vue'
import NewContribution from '@/components/feed/NewContribution.vue'
import SegControl from '@/components/ui/SegControl.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const { hot, newest } = useFeed()

const hotMappings = ref<any[]>([])
const newContribs = ref<any[]>([])
const segment = ref('all')
const loading = ref(true)
const loadError = ref('')

onMounted(async () => {
  loading.value = true
  try {
    const [h, n] = await Promise.all([hot(20), newest(20)])
    hotMappings.value = h
    newContribs.value = n
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="feed-page">
    <div class="feed-hero">
      <h1>動態</h1>
      <p>語義圖譜的最新脈動--熱門映射與新貢獻。</p>
      <SegControl
        v-model="segment"
        :options="[
          { value: 'all', label: '全部' },
          { value: 'hot', label: '熱門' },
          { value: 'new', label: '最新' },
        ]"
      />
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <template v-else>
      <section v-if="segment !== 'new'" class="feed-sec">
        <div class="feed-sec-head">
          <h2>熱門映射</h2>
          <span class="hint">依評分 · 本週</span>
        </div>
        <div class="map-list">
          <MappingCard
            v-for="m in hotMappings"
            :key="m.id"
            v-bind="m"
          />
        </div>
      </section>

      <section v-if="segment !== 'hot'" class="feed-sec">
        <div class="feed-sec-head">
          <h2>最新貢獻</h2>
          <span class="hint">映射 + 新詞句</span>
        </div>
        <div class="new-list">
          <NewContribution
            v-for="c in newContribs"
            :key="c.id"
            v-bind="c"
          />
        </div>
        <div class="feed-cta">
          沒看到你想找的？<router-link to="/contribute">貢獻一個新映射 -></router-link>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.feed-page { max-width: 760px; margin: 0 auto; }
.feed-hero { margin-bottom: 28px; }
.feed-hero h1 { font-size: 22px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: 4px; }
.feed-hero p { font-size: 13px; color: #6B7280; }
.feed-sec { margin-bottom: 34px; }
.feed-sec-head {
  display: flex; align-items: baseline; justify-content: space-between; gap: 12px;
  margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid #EDE5D8;
}
.feed-sec-head h2 { font-size: 13px; font-weight: 600; letter-spacing: -0.01em; }
.feed-sec-head .hint {
  font-family: "IBM Plex Mono", monospace; font-size: 10px;
  color: #B0B0B0; letter-spacing: 0.04em; text-transform: uppercase;
}
.map-list { display: flex; flex-direction: column; gap: 5px; }
.new-list { display: flex; flex-direction: column; }
.feed-cta {
  margin-top: 8px; padding: 16px;
  border: 1px dashed #EDE5D8; border-radius: 8px;
  text-align: center; color: #6B7280; font-size: 13px;
}
.feed-cta a { color: #8B4513; font-weight: 500; }
</style>
