<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>

<template>
  <div class="nf-page">
    <h1>404</h1>
    <p>{{ t('errors.pageMissing') }}</p>
    <router-link to="/" class="btn btn-ghost">{{ t('errors.home') }}</router-link>
  </div>
</template>

<style scoped>
.nf-page {
  text-align: center;
  padding: var(--page-pad-top) 20px var(--page-pad-bottom);
}
.nf-page h1 { font-size: 48px; margin-bottom: var(--space-sm); }
.nf-page p { color: oklch(0.52 0.010 200); margin-bottom: var(--space-md); }
</style>
