<script setup lang="ts">
defineProps<{
  hasMore: boolean
}>()
defineEmits<{ loadMore: [] }>()
</script>

<template>
  <div v-if="hasMore" class="pag">
    <button class="btn btn-ghost" @click="$emit('loadMore')">載入更多</button>
  </div>
</template>

<style scoped>
.pag { text-align: center; padding: 20px; }
</style>
