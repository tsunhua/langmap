<script setup lang="ts">
defineProps<{
  message?: string
  actionLabel?: string
}>()
defineEmits<{ action: [] }>()
</script>

<template>
  <div class="empty">
    <p>{{ message || '暫無資料' }}</p>
    <button v-if="actionLabel" class="btn btn-ghost btn-sm" @click="$emit('action')">
      {{ actionLabel }}
    </button>
  </div>
</template>

<style scoped>
.empty {
  text-align: center;
  padding: 48px 20px;
  color: var(--muted);
  font-size: 13px;
}
</style>
