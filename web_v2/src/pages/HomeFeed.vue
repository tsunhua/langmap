<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFeed } from '@/composables/useFeed'
import MappingCard from '@/components/feed/MappingCard.vue'
import NewContribution from '@/components/feed/NewContribution.vue'
import SegControl from '@/components/ui/SegControl.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const { loading, hot, newest } = useFeed()

const hotMappings = ref<any[]>([])
const newContribs = ref<any[]>([])
const segment = ref('all')
const loadError = ref('')

onMounted(async () => {
  try {
    const [h, n] = await Promise.all([hot(20), newest(20)])
    hotMappings.value = h
    newContribs.value = n
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  }
})
</script>

<template>
  <div class="feed-page">
    <div class="feed-hero">
      <h1>LangMap</h1>
      <p style="color: #4A6FA5; margin: 8px 0 16px;">
        探索世界各地的詞句對照
      </p>
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
          <span class="hint">評分最高</span>
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
        </div>
        <div class="new-list">
          <NewContribution
            v-for="c in newContribs"
            :key="c.id"
            v-bind="c"
          />
        </div>
      </section>

      <div class="feed-cta">
        <router-link to="/contribute" class="btn btn-primary">+ 新增映射</router-link>
      </div>
    </template>
  </div>
</template>

<style scoped>
.feed-page { max-width: 760px; margin: 0 auto; }
.feed-hero { margin-bottom: 24px; }
.feed-sec { margin-bottom: 32px; }
.feed-sec-head {
  display: flex; align-items: baseline; gap: 10px;
  padding: 10px 0; border-bottom: 1px solid #EDE5D8;
  margin-bottom: 12px;
}
.feed-sec-head h2 { font-family: "Noto Serif", serif; font-size: 18px; }
.hint { font-size: 12px; color: #4A6FA5; }
.map-list { display: flex; flex-direction: column; gap: 8px; }
.new-list { background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.feed-cta { text-align: center; padding: 24px; }
</style>
