<script setup lang="ts">
defineProps<{
  code: string
  score?: number
}>()
</script>

<template>
  <span class="lang-badge">
    {{ code }}<template v-if="score !== undefined"> · {{ score }}</template>
  </span>
</template>
