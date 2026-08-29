<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useFeed } from '@/composables/useFeed'
import NewContribution from '@/components/feed/NewContribution.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'

const { newest } = useFeed()
const { t } = useI18n()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()

const newContribs = ref<any[]>([])
const loading = ref(true)
const loadError = ref('')

let feedRequest = 0

async function load() {
  const request = ++feedRequest
  loading.value = true
  loadError.value = ''
  try {
    const n = await newest(20, localeParams.value)
    if (request !== feedRequest) return
    newContribs.value = n
  } catch (e: any) {
    if (request !== feedRequest) return
    loadError.value = e.response?.data?.message || e.response?.data?.error || t('errors.loadFailed')
  } finally {
    if (request === feedRequest) loading.value = false
  }
}

watch([() => localization.locale, () => localization.secondary], () => { void load() })
onMounted(() => { void load() })
onUnmounted(() => { feedRequest++ })
</script>

<template>
  <div class="feed-page">
    <div class="feed-hero">
      <h1>{{ t('feed.title') }}</h1>
      <p>{{ t('feed.subtitle') }}</p>
    </div>

    <LoadingSpinner v-if="loading" />

    <div v-else-if="loadError" role="alert">
      <EmptyState :message="loadError" />
    </div>

    <EmptyState v-else-if="newContribs.length === 0" :message="t('feed.noActivity')" />

    <template v-else>
      <section class="feed-sec">
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