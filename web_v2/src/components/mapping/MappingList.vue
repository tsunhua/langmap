<script setup lang="ts">
import VotePill from './VotePill.vue'

defineProps<{
  mappings: Array<{
    edge_id: string | null
    expression_id: number
    text: string
    language_code: string
    language_name: string
    score: number
    hops: number
  }>
}>()
</script>

<template>
  <div class="mapping-list">
    <div
      v-for="m in mappings"
      :key="m.expression_id"
      class="map-row"
    >
      <router-link :to="`/mapping/${m.expression_id}`" class="map-link">
        <span class="map-text">{{ m.text }}</span>
        <span class="lang-badge">{{ m.language_code }}</span>
        <span class="map-name">{{ m.language_name }}</span>
      </router-link>
      <span v-if="m.hops === 2" class="hop-tag">間接</span>
      <VotePill
        v-if="m.edge_id"
        :target-id="m.edge_id"
        target-type="mapping"
        :score="m.score"
      />
    </div>
  </div>
</template>

<style scoped>
.mapping-list { display: flex; flex-direction: column; }
.map-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-bottom: 1px solid #EDE5D8;
}
.map-link {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
  color: inherit;
  flex: 1;
}
.map-text { font-size: 14px; }
.map-name { font-size: 12px; color: #4A6FA5; }
.hop-tag {
  font-size: 11px;
  padding: 1px 5px;
  border-radius: 3px;
  background: #E6F0FF;
  color: #4A6FA5;
}
</style>
