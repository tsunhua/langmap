<script setup lang="ts">
withDefaults(defineProps<{
  id: number
  text: string
  language_profile_code: string
  region_name?: string
  mapping_count?: number
  source_type?: string
  showLanguage?: boolean
}>(), { showLanguage: true })
</script>

<template>
  <router-link :to="`/mapping/${id}`" :class="['ex-row', { 'ex-row--no-lang': !showLanguage }]">
    <span class="ex-tx">{{ text }}</span>
    <span v-if="showLanguage" class="ex-lc"><span class="lang-badge">{{ language_profile_code }}</span></span>
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
  grid-template-columns: minmax(0,1fr) 70px 100px auto 60px;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.ex-row--no-lang { grid-template-columns: minmax(0,1fr) 100px auto 60px; }
.ex-row:last-child { border-bottom: none; }
.ex-row:hover { background: var(--bg); }
.ex-row:hover .ex-tx { color: var(--accent); }
.ex-tx { font-size: 14px; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ex-region { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ex-maps { font-family: var(--mono); font-variant-numeric: tabular-nums; color: var(--accent); font-size: 13px; text-align: right; white-space: nowrap; }
@media (max-width: 640px) {
  .ex-row { grid-template-columns: 1fr auto auto; gap: 6px; padding: 8px 10px; }
  .ex-row--no-lang { grid-template-columns: 1fr auto; }
  .ex-region, .ex-src { display: none; }
}
</style>
