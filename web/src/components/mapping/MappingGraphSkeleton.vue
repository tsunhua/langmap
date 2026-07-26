<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
</script>

<template>
  <div class="graph-skeleton" role="status" :aria-label="t('components.graphLoading')">
    <div class="gs-ring">
      <div class="gs-dot gs-center" />
      <div class="gs-dot gs-ring-1" />
      <div class="gs-dot gs-ring-2" />
      <div class="gs-dot gs-ring-3" />
      <div class="gs-dot gs-ring-4" />
    </div>
    <span class="gs-text">{{ t('components.graphLoading') }}</span>
  </div>
</template>

<style scoped>
.graph-skeleton {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: clamp(520px, 68dvh, 820px);
  gap: 16px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.gs-ring {
  position: relative;
  width: 100px;
  height: 100px;
}
.gs-dot {
  position: absolute;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent);
  opacity: 0.2;
  animation: gs-pulse 1.5s ease-in-out infinite;
}
.gs-center {
  top: 46px;
  left: 46px;
  animation-delay: 0s;
}
.gs-ring-1 {
  top: 0;
  left: 46px;
  animation-delay: 0.15s;
}
.gs-ring-2 {
  top: 46px;
  right: 0;
  animation-delay: 0.3s;
}
.gs-ring-3 {
  bottom: 0;
  left: 46px;
  animation-delay: 0.45s;
}
.gs-ring-4 {
  top: 46px;
  left: 0;
  animation-delay: 0.6s;
}
@keyframes gs-pulse {
  0%, 100% { opacity: 0.15; transform: scale(1); }
  50% { opacity: 0.6; transform: scale(1.3); }
}
.gs-text {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
}
</style>
