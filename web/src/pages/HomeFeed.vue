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
  <section class="home-feed" aria-labelledby="home-feed-title">
    <div class="feed-hero">
      <h2 id="home-feed-title">{{ t('feed.title') }}</h2>
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
  </section>
</template>

<style scoped>
.home-feed {
  max-width: 760px;
  margin: clamp(40px, 7vh, 64px) auto var(--page-pad-bottom);
  padding-top: var(--space-lg);
  border-top: 1px solid var(--border);
}
.feed-hero { margin-bottom: var(--space-base); }
.feed-hero h2 { margin: 0 0 4px; font-size: 20px; font-weight: 600; }
.feed-hero p { margin: 0; color: var(--muted); font-size: 14px; }
.feed-sec { margin-bottom: var(--space-lg); }
  .new-list { display: flex; flex-direction: column; gap: 8px; }
.feed-cta {
  margin-top: var(--space-xs); padding: var(--space-base);
  border: 1px dashed var(--border); border-radius: var(--r);
  text-align: center; color: var(--muted); font-size: 16px;
}
.feed-cta a { color: var(--accent); font-weight: 500; }
.feed-cta a:hover { filter: brightness(1.08); }
@media (max-width: 640px) {
  .home-feed { margin-top: 40px; }
}
</style>
