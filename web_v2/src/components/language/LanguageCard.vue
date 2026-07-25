<script setup lang="ts">
defineProps<{
  code: string
  name: string
  expression_count: number
  region_name?: string
}>()
</script>

<template>
  <router-link :to="`/language/${code}`" class="lg-row">
    <div class="lg-name">
      <span class="nm">{{ name }}</span>
    </div>
    <span class="lg-code lang-badge">{{ code }}</span>
    <span class="lg-geo">{{ region_name || '-' }}</span>
    <span class="lg-count">{{ expression_count }}</span>
  </router-link>
</template>

<style scoped>
.lg-row {
  display: grid;
  grid-template-columns: 1.8fr 56px 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-bottom: 1px solid #EDE5D8;
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.lg-row:hover { background: #F5F0E8; }
.lg-name .nm { font-size: 15px; }
.lg-count {
  font-family: "IBM Plex Mono", monospace;
  font-size: 14px;
  color: #8B4513;
}
</style>
