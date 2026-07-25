<script setup lang="ts">
defineProps<{
  id: number
  title: string
  author_username?: string
  section_count: number
  expression_count: number
  score: number
}>()
</script>

<template>
  <router-link :to="`/handbook/${id}`" class="hb-card">
    <h3>{{ title }}</h3>
    <div class="hb-card-meta">{{ section_count }} 章 · {{ expression_count }} 詞句</div>
    <div class="hb-card-foot">
      <span v-if="author_username" class="hb-author">{{ author_username }}</span>
      <span class="hb-score">★ {{ score }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.hb-card {
  display: flex; flex-direction: column; gap: 8px;
  padding: 16px; background: #fff;
  border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-decoration: none; color: inherit; transition: box-shadow 0.15s;
}
.hb-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.hb-card h3 { font-size: 15px; font-family: "Noto Serif", serif; }
.hb-card-meta { font-size: 13px; color: #4A6FA5; }
.hb-card-foot { display: flex; justify-content: space-between; font-size: 12px; color: #4A6FA5; margin-top: auto; }
.hb-score { font-family: "IBM Plex Mono", monospace; color: #8B4513; }
</style>
