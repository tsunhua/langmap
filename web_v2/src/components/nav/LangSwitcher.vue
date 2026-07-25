<script setup lang="ts">
import { Globe, ChevronDown } from 'lucide-vue-next'
</script>

<template>
  <button class="lang-switch" type="button" aria-label="切換介面語言" aria-haspopup="listbox" aria-expanded="false">
    <Globe :size="14" aria-hidden="true" />
    <span class="ls-code">ZH-TW</span>
    <ChevronDown :size="12" aria-hidden="true" />
  </button>
</template>

<style scoped>
.lang-switch {
  display: inline-flex; align-items: center; gap: 5px;
  height: 30px; padding: 0 10px;
  border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); cursor: pointer;
  font-family: var(--mono); font-size: 10px;
  color: var(--muted); transition: color 0.15s, background 0.15s;
}
.lang-switch:hover { background: var(--bg); color: var(--fg); }
.ls-code { letter-spacing: 0.04em; }
@media (max-width: 768px) {
  .lang-switch { height: 44px; padding: 0 12px; }
}
</style>
