<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useLanguages } from '@/composables/useLanguages'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const { list } = useLanguages()

const languages = ref<any[]>([])
const activePin = ref<string | null>(null)
const loading = ref(true)
const loadError = ref('')

function latLngToXY(lat: number, lng: number) {
  const x = ((lng + 180) / 360) * 100
  const y = ((90 - lat) / 180) * 100
  return { x, y }
}

onMounted(async () => {
  try {
    const all = await list()
    languages.value = all.filter((l: any) => l.region_latitude && l.region_longitude)
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="lens-page">
    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <div v-else class="lens-layout">
      <div class="lens-map">
        <div class="map-art"></div>
        <div class="map-graticule"></div>
        <button
          v-for="lang in languages"
          :key="lang.code"
          :class="['pin', { active: activePin === lang.code }]"
          :style="{ left: latLngToXY(lang.region_latitude, lang.region_longitude).x + '%', top: latLngToXY(lang.region_latitude, lang.region_longitude).y + '%' }"
          @mouseenter="activePin = lang.code"
          @mouseleave="activePin = null"
        >
          <span class="pin-label">{{ lang.name }}</span>
        </button>
      </div>

      <aside class="lens-list">
        <div class="lens-list-head">語言列表</div>
        <router-link
          v-for="lang in languages"
          :key="lang.code"
          :to="`/language/${lang.code}`"
          :class="['lens-item', { active: activePin === lang.code }]"
          @mouseenter="activePin = lang.code"
          @mouseleave="activePin = null"
        >
          <span class="lens-item-name">{{ lang.name }}</span>
          <span class="lens-item-count">{{ lang.expression_count }}</span>
        </router-link>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.lens-page { max-width: 1100px; margin: 0 auto; }
.lens-layout { display: grid; grid-template-columns: 1fr 280px; gap: 20px; }
.lens-map {
  position: relative;
  height: 70vh;
  background: #E6F0FF;
  border-radius: 4px;
  overflow: hidden;
}
.map-art {
  position: absolute; inset: 0;
  background:
    radial-gradient(ellipse 200px 150px at 25% 40%, #D4E8D4 0%, transparent 100%),
    radial-gradient(ellipse 180px 120px at 65% 35%, #D4E8D4 0%, transparent 100%),
    radial-gradient(ellipse 120px 100px at 45% 65%, #D4E8D4 0%, transparent 100%),
    radial-gradient(ellipse 100px 80px at 80% 60%, #D4E8D4 0%, transparent 100%);
}
.map-graticule {
  position: absolute; inset: 0;
  background-image:
    linear-gradient(#B0C4DE 1px, transparent 1px),
    linear-gradient(90deg, #B0C4DE 1px, transparent 1px);
  background-size: 10% 10%;
  opacity: 0.5;
}
.pin {
  position: absolute;
  width: 16px; height: 16px;
  border-radius: 50%;
  background: #8B4513;
  border: 2px solid #fff;
  box-shadow: 0 1px 4px rgba(0,0,0,0.3);
  cursor: pointer;
  transform: translate(-50%, -50%);
  transition: all 0.15s;
}
.pin.active { transform: translate(-50%, -50%) scale(1.3); box-shadow: 0 2px 8px rgba(0,0,0,0.4); }
.pin-label {
  display: none;
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  padding: 2px 6px;
  background: #1A1A1A;
  color: #fff;
  font-size: 11px;
  white-space: nowrap;
  border-radius: 3px;
  margin-bottom: 4px;
}
.pin.active .pin-label { display: block; }
.lens-list { overflow-y: auto; max-height: 70vh; }
.lens-list-head { font-family: "IBM Plex Mono", monospace; font-size: 11px; text-transform: uppercase; color: #4A6FA5; margin-bottom: 8px; }
.lens-item {
  display: flex; justify-content: space-between; align-items: center;
  padding: 6px 10px; text-decoration: none; color: inherit;
  border-radius: 4px; transition: background 0.1s;
}
.lens-item:hover, .lens-item.active { background: #F5E6D3; }
.lens-item-name { font-size: 13px; }
.lens-item-count { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: #4A6FA5; }
@media (max-width: 700px) {
  .lens-layout { grid-template-columns: 1fr; }
}
</style>
