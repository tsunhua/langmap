<script setup lang="ts">
import { ZoomIn, ZoomOut, Maximize2, Minus, RotateCcw } from 'lucide-vue-next'

defineProps<{
  zoomPercent: number
}>()

const emit = defineEmits<{
  zoomIn: []
  zoomOut: []
  fit: []
  actualSize: []
  reset: []
}>()
</script>

<template>
  <div class="graph-toolbar" role="toolbar" aria-label="圖譜工具列">
    <div class="tb-group">
      <button
        class="tb-btn"
        aria-label="放大"
        title="放大"
        @click="emit('zoomIn')"
      >
        <ZoomIn :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn"
        aria-label="縮小"
        title="縮小"
        @click="emit('zoomOut')"
      >
        <ZoomOut :size="16" aria-hidden="true" />
      </button>
      <span class="tb-pct">{{ zoomPercent }}%</span>
    </div>
    <div class="tb-group">
      <button
        class="tb-btn"
        aria-label="適應畫面"
        title="適應畫面"
        @click="emit('fit')"
      >
        <Maximize2 :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn"
        aria-label="實際大小 100%"
        title="實際大小"
        @click="emit('actualSize')"
      >
        <Minus :size="16" aria-hidden="true" />
      </button>
      <button
        class="tb-btn"
        aria-label="重置佈局"
        title="重置佈局"
        @click="emit('reset')"
      >
        <RotateCcw :size="16" aria-hidden="true" />
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
@media (max-width: 640px) {
  .graph-toolbar {
    right: 8px;
    top: 8px;
    padding: 3px;
  }
  .tb-btn {
    width: 44px;
    height: 44px;
  }
}
</style>
