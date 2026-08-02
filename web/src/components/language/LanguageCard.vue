<script setup lang="ts">
defineProps<{
  code: string
  name: string
  name_en?: string
  expression_count: number
  script_code?: string
  direction?: string
}>()
</script>

<template>
  <router-link :to="`/language/${code}`" class="lg-row">
    <div class="lg-name">
      <span class="nm">{{ name }}</span>
      <span class="en" v-if="name_en">{{ name_en }}</span>
    </div>
    <span class="lg-code lang-badge">{{ code }}</span>
    <span class="lg-geo">
      <span v-if="script_code" class="lg-script">{{ script_code }}</span>
      <span v-if="direction === 'rtl'" class="lg-rtl" title="right-to-left">rtl</span>
      <span v-if="!script_code && direction !== 'rtl'" class="lg-dim">—</span>
    </span>
    <span class="lg-count">{{ expression_count.toLocaleString() }}</span>
  </router-link>
</template>

<style scoped>
.lg-row {
  display: grid;
  grid-template-columns: 1.8fr 56px 1fr auto;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.lg-row:last-child { border-bottom: none; }
.lg-row:hover { background: var(--bg); }
.lg-name { min-width: 0; }
.lg-name .nm { display: block; font-size: 15px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lg-name .en { display: block; font-size: 11px; color: var(--muted); margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lg-geo { display: inline-flex; align-items: center; gap: 6px; font-family: var(--mono); font-size: 11px; color: var(--muted); overflow: hidden; white-space: nowrap; }
.lg-script { overflow: hidden; text-overflow: ellipsis; }
.lg-rtl { color: var(--accent); text-transform: uppercase; letter-spacing: 0.04em; }
.lg-dim { color: var(--border); }
.lg-count {
  font-family: var(--mono);
  font-variant-numeric: tabular-nums;
  font-size: 14px;
  color: var(--accent);
  text-align: right;
}
@media (max-width: 640px) {
  .lg-row { grid-template-columns: 1fr auto auto; gap: 8px; min-height: 44px; }
  .lg-geo { display: none; }
}
</style>
