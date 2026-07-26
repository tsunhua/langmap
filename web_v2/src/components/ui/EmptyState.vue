<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
defineProps<{
  message?: string
  actionLabel?: string
}>()
defineEmits<{ action: [] }>()
</script>

<template>
  <div class="empty">
    <p>{{ message || t('components.empty') }}</p>
    <button v-if="actionLabel" class="btn btn-ghost btn-sm" @click="$emit('action')">
      {{ actionLabel }}
    </button>
  </div>
</template>

<style scoped>
.empty {
  text-align: center;
  padding: var(--space-xxl) var(--space-md);
  color: var(--muted);
  font-size: 13px;
}
</style>
