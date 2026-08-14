<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useFeed } from '@/composables/useFeed'
import MappingCard from '@/components/feed/MappingCard.vue'
import NewContribution from '@/components/feed/NewContribution.vue'
import SegControl from '@/components/ui/SegControl.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'

const { hot, newest } = useFeed()
const { t } = useI18n()

const hotMappings = ref<any[]>([])
const newContribs = ref<any[]>([])
const segment = ref('all')
const loading = ref(true)
const loadError = ref('')

const visibleEmpty = computed(() => {
  if (segment.value === 'hot') return hotMappings.value.length === 0
  if (segment.value === 'new') return newContribs.value.length === 0
  return hotMappings.value.length === 0 && newContribs.value.length === 0
})


onMounted(async () => {
  loading.value = true
  try {
    const [h, n] = await Promise.all([hot(20), newest(20)])
    hotMappings.value = h
    newContribs.value = n
  } catch (e: any) {
    loadError.value = e.response?.data?.message || e.response?.data?.error || t('errors.loadFailed')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="feed-page">
    <div class="feed-hero">
      <h1>{{ t('feed.title') }}</h1>
      <p>{{ t('feed.subtitle') }}</p>
      <SegControl
        v-model="segment"
        :options="[
          { value: 'all', label: t('feed.all') },
          { value: 'hot', label: t('feed.hot') },
          { value: 'new', label: t('feed.newest') },
        ]"
      />
    </div>

    <LoadingSpinner v-if="loading" />

    <div v-else-if="loadError" role="alert">
      <EmptyState :message="loadError" />
    </div>

    <EmptyState v-else-if="visibleEmpty" :message="t('feed.noActivity')" />

    <template v-else>
      <section v-if="segment !== 'new'" class="feed-sec">
        <div class="feed-sec-head">
          <h2>{{ t('feed.popularMappings') }}</h2>
          <span class="hint">{{ t('feed.ratedThisWeek') }}</span>
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
          <h2>{{ t('feed.newContributions') }}</h2>
          <span class="hint">{{ t('feed.mappingsAndExpressions') }}</span>
        </div>
        <div class="new-list">
          <NewContribution
            v-for="c in newContribs"
            :key="c.id"
            v-bind="c"
          />
        </div>
        <div class="feed-cta">
          {{ t('feed.missing') }} <router-link to="/contribute">{{ t('feed.contributeMapping') }}</router-link>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
  .feed-page { max-width: 760px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
  .feed-hero { margin-bottom: var(--space-md); }
.feed-hero h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: 4px; }
.feed-hero p { font-size: 16px; color: var(--muted); margin-bottom: var(--space-lg); }
  .feed-sec { margin-bottom: var(--space-lg); }
  .feed-sec-head {
  display: flex; align-items: baseline; justify-content: space-between; gap: 12px;
  flex-wrap: wrap;
  margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid var(--border);
}
.feed-sec-head h2 { font-size: 18px; font-weight: 600; letter-spacing: -0.01em; }
.feed-sec-head .hint {
  font-family: var(--mono); font-size: 13px;
  color: var(--faint); letter-spacing: 0.04em; text-transform: uppercase;
}
  .map-list { display: flex; flex-direction: column; gap: 8px; }
  .new-list { display: flex; flex-direction: column; gap: 8px; }
.feed-cta {
  margin-top: var(--space-xs); padding: var(--space-base);
  border: 1px dashed var(--border); border-radius: 8px;
  text-align: center; color: var(--muted); font-size: 16px;
}
.feed-cta a { color: var(--accent); font-weight: 500; }
.feed-cta a:hover { filter: brightness(1.08); }
@media (max-width: 640px) {
  .feed-hero { margin-bottom: var(--space-md); }
}
</style>
