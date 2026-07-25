<script setup lang="ts">
defineProps<{
  id: number
  text: string
  language_code: string
  region_name?: string
  mapping_count?: number
  source_type?: string
}>()
</script>

<template>
  <router-link :to="`/mapping/${id}`" class="ex-row">
    <span class="ex-tx">{{ text }}</span>
    <span class="ex-lc"><span class="lang-badge">{{ language_code }}</span></span>
    <span class="ex-region">{{ region_name || '-' }}</span>
    <span v-if="source_type" class="ex-src">
      <span :class="['src-tag', source_type]">{{ source_type }}</span>
    </span>
    <span v-if="mapping_count !== undefined" class="ex-maps">{{ mapping_count }}</span>
  </router-link>
</template>

<style scoped>
.ex-row {
  display: grid;
  grid-template-columns: 1fr 70px 100px 60px 60px;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-bottom: 1px solid #EDE5D8;
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.ex-row:hover { background: #F5F0E8; }
.ex-tx { font-size: 14px; }
.ex-maps { font-family: "IBM Plex Mono", monospace; color: #8B4513; font-size: 13px; }
</style>
