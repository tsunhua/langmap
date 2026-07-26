<script setup lang="ts">
import { computed, ref } from 'vue'
import { ZoomIn, ZoomOut, Maximize2, Minimize2, Minus, RotateCcw, MoreHorizontal, List, Share2 } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

const props = defineProps<{
  zoomPercent: number
  currentHops: number
  maxHops: number
  mobileMode?: 'graph' | 'list'
  isFullscreen?: boolean
}>()

const emit = defineEmits<{
  zoomIn: []
  zoomOut: []
  fit: []
  actualSize: []
  reset: []
  changeHops: [hops: number]
  toggleMode: []
  expandAll: []
  collapseToFirst: []
  toggleFullscreen: []
}>()

const showMore = ref(false)

const hopsOptions = computed(() => {
  const arr: number[] = []
  for (let i = 1; i <= props.maxHops; i++) arr.push(i)
  return arr
})

function toggleMore() {
  showMore.value = !showMore.value
}
</script>

<template>
  <div class="graph-toolbar" role="toolbar" :aria-label="t('components.graphToolbar')">
    <template v-if="mobileMode !== undefined">
      <div class="tb-group tb-mode">
        <button
          class="tb-btn tb-mode-btn"
          :class="{ active: mobileMode === 'graph' }"
          :aria-label="t('components.graphMode')"
          @click="emit('toggleMode')"
        >
          <Share2 :size="16" aria-hidden="true" />
        </button>
        <button
          class="tb-btn tb-mode-btn"
          :class="{ active: mobileMode === 'list' }"
          :aria-label="t('components.listMode')"
          @click="emit('toggleMode')"
        >
          <List :size="16" aria-hidden="true" />
        </button>
      </div>
    </template>
    <div class="tb-group">
      <button
        class="tb-btn"
        :aria-label="t('components.zoomIn')"
        :title="t('components.zoomIn')"
        @click="emit('zoomIn')"
      >
        <ZoomIn :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn"
        :aria-label="t('components.zoomOut')"
        :title="t('components.zoomOut')"
        @click="emit('zoomOut')"
      >
        <ZoomOut :size="16" aria-hidden="true" />
      </button>
      <span class="tb-pct">{{ zoomPercent }}%</span>
    </div>
    <div class="tb-group">
      <button
        class="tb-btn"
        :aria-label="isFullscreen ? t('components.exitFullscreen') : t('components.fullscreen')"
        :title="isFullscreen ? t('components.exitFullscreen') : t('components.fullscreen')"
        @click="emit('toggleFullscreen')"
      >
        <Maximize2 v-if="!isFullscreen" :size="16" aria-hidden="true" />
        <Minimize2 v-else :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn tb-btn-hide-mobile"
        :aria-label="t('components.actualSize')"
        :title="t('components.actualSize')"
        @click="emit('actualSize')"
      >
        <Minus :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn tb-btn-hide-mobile"
        :aria-label="t('components.resetLayout')"
        :title="t('components.resetLayout')"
        @click="emit('reset')"
      >
        <RotateCcw :size="16" aria-hidden="true" />
      </button>
    </div>
    <div class="tb-group tb-group-more-mobile">
      <button
        class="tb-btn"
        :aria-label="t('components.moreActions')"
        :title="t('components.moreActions')"
        @click="toggleMore"
      >
        <MoreHorizontal :size="16" aria-hidden="true" />
      </button>
      <div v-if="showMore" class="tb-more-menu" role="menu">
        <button
          class="tb-more-item"
          role="menuitem"
          @click="emit('actualSize'); showMore = false"
        >
          {{ t('components.actualSize') }}
        </button>
        <button
          class="tb-more-item"
          role="menuitem"
          @click="emit('reset'); showMore = false"
        >
          {{ t('components.resetLayout') }}
        </button>
        <button
          class="tb-more-item"
          role="menuitem"
          @click="emit('expandAll'); showMore = false"
        >
          {{ t('components.expandAll') }}
        </button>
        <button
          class="tb-more-item"
          role="menuitem"
          @click="emit('collapseToFirst'); showMore = false"
        >
          {{ t('components.collapseToFirst') }}
        </button>
      </div>
    </div>
    <div v-if="showMore" class="tb-overlay" @click="showMore = false" />
    <div v-if="maxHops > 1" class="tb-group">
      <span class="tb-label">{{ t('components.hops') }}</span>
      <button
        v-for="h in hopsOptions"
        :key="h"
        class="tb-hop"
        :class="{ active: currentHops === h }"
        :aria-label="`${h} ${t('components.hops')}`"
        :aria-pressed="currentHops === h"
        @click="emit('changeHops', h)"
      >
        {{ h }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.graph-toolbar {
  position: absolute;
  right: 12px;
  top: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  background: color-mix(in oklch, var(--surface) 92%, transparent);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 4px;
  backdrop-filter: blur(4px);
  z-index: 10;
}
.tb-group {
  display: flex;
  align-items: center;
  gap: 2px;
}
.tb-group + .tb-group {
  padding-top: 4px;
  border-top: 1px solid var(--border);
}
.tb-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: var(--muted);
  border-radius: calc(var(--r) - 2px);
  cursor: pointer;
  transition: background 0.1s, color 0.1s;
}
.tb-btn:hover {
  background: var(--accent);
  color: #fff;
}
.tb-btn:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 1px;
}
.tb-pct {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  min-width: 32px;
  text-align: center;
}
.tb-label {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--faint);
  margin-right: 2px;
}
.tb-hop {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border: 1px solid var(--border);
  background: transparent;
  color: var(--muted);
  border-radius: calc(var(--r) - 2px);
  font-family: var(--mono);
  font-size: 11px;
  cursor: pointer;
  transition: background 0.1s, color 0.1s, border-color 0.1s;
}
.tb-hop:hover {
  border-color: var(--accent);
  color: var(--accent);
}
.tb-hop.active {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
}
.tb-hop:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 1px;
}
.tb-mode { gap: 0; }
.tb-mode-btn {
  width: 36px;
  height: 32px;
  border-radius: 0;
}
.tb-mode-btn:first-child { border-radius: calc(var(--r) - 2px) 0 0 calc(var(--r) - 2px); }
.tb-mode-btn:last-child { border-radius: 0 calc(var(--r) - 2px) calc(var(--r) - 2px) 0; }
.tb-mode-btn.active { background: var(--accent); color: #fff; }
.tb-mode-btn:not(.active) { border: 1px solid var(--border); }
.tb-mode-btn:not(.active):hover { border-color: var(--accent); color: var(--accent); }
.tb-group-more-mobile { display: none; }

.tb-more-menu {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 4px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 4px;
  display: flex;
  flex-direction: column;
  gap: 2px;
  z-index: 20;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  min-width: 140px;
}
.tb-more-item {
  display: block;
  width: 100%;
  text-align: left;
  padding: 8px 12px;
  border: none;
  background: transparent;
  color: var(--fg);
  border-radius: calc(var(--r) - 2px);
  cursor: pointer;
  font-size: 13px;
  white-space: nowrap;
}
.tb-more-item:hover { background: color-mix(in oklch, var(--accent) 8%, transparent); }
.tb-more-item:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.tb-overlay {
  position: fixed;
  inset: 0;
  z-index: 15;
  background: transparent;
}

@media (max-width: 640px) {
  .graph-toolbar {
    right: 8px;
    top: 8px;
    padding: 3px;
  }
  .tb-btn, .tb-mode-btn {
    width: 44px;
    height: 44px;
  }
  .tb-hop {
    width: 36px;
    height: 36px;
  }
  .tb-btn-hide-mobile { display: none; }
  .tb-group-more-mobile { display: flex; }
}
</style>
