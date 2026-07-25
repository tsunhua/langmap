<script setup lang="ts">
defineProps<{
  id: string
  left_text: string
  left_lang: string
  right_text: string
  right_lang: string
  author?: string
  created_at?: string
}>()

function timeAgo(dateStr?: string): string {
  if (!dateStr) return ''
  const diff = Date.now() - new Date(dateStr).getTime()
  const min = Math.floor(diff / 60000)
  if (min < 1) return '剛剛'
  if (min < 60) return `${min} 分鐘前`
  const hr = Math.floor(min / 60)
  if (hr < 24) return `${hr} 小時前`
  return `${Math.floor(hr / 24)} 天前`
}
</script>

<template>
  <router-link :to="`/mapping/${id}`" class="new-row">
    <span class="new-kind">映射</span>
    <span class="new-body">
      <span class="new-pair">
        <span class="tx">{{ left_text }}</span>
        <span class="arrow">↔</span>
        <span class="tx">{{ right_text }}</span>
      </span>
      <span class="lang-badge">{{ left_lang }} · {{ right_lang }}</span>
    </span>
    <span class="new-meta">
      <template v-if="timeAgo(created_at)">{{ timeAgo(created_at) }} · </template>@{{ author || '匿名' }}
    </span>
  </router-link>
</template>

<style scoped>
.new-row {
  display: grid;
  grid-template-columns: 92px 1fr auto;
  gap: 12px;
  align-items: center;
  padding: 11px 0;
  border-bottom: 1px solid #EDE5D8;
  color: inherit;
  text-decoration: none;
  cursor: pointer;
}
.new-row:last-child { border-bottom: none; }
.new-row:hover .tx { color: #8B4513; }
.new-kind {
  font-family: "IBM Plex Mono", monospace;
  font-size: 9px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #8B4513;
  border: 1px solid #D4A574;
  padding: 2px 7px;
  border-radius: 2px;
  justify-self: start;
  background: #F5E6D3;
}
.new-body { display: flex; align-items: baseline; gap: 8px; min-width: 0; flex-wrap: wrap; }
.new-pair { font-size: 14px; }
.new-pair .arrow { color: #B0B0B0; margin: 0 4px; }
.new-pair .tx { font-weight: 500; transition: color 0.12s; }
.new-meta {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  color: #6B7280;
  white-space: nowrap;
}
</style>
