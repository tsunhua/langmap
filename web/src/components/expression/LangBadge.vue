<script setup lang="ts">
defineProps<{
  code: string
  name?: string
  score?: number
}>()
</script>

<template>
  <span class="lang-badge" :title="code">
    {{ name || code }}<template v-if="score !== undefined"> · {{ score }}</template>
  </span>
</template>
