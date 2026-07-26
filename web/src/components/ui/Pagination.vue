<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
defineProps<{
  hasMore: boolean
}>()
defineEmits<{ loadMore: [] }>()
</script>

<template>
  <div v-if="hasMore" class="pag">
    <button class="btn btn-ghost" @click="$emit('loadMore')">{{ t('components.loadMore') }}</button>
  </div>
</template>

<style scoped>
.pag { text-align: center; padding: 20px; }
</style>
