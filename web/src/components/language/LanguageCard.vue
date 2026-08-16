<script setup lang="ts">
defineProps<{
  code: string
  name?: string
  name_en?: string
  expression_count: number
  script_code?: string
  direction?: string
}>()
</script>

<template>
  <router-link :to="`/language/${code}`" class="lg-row">
    <div class="lg-name">
      <div class="lg-title">
        <span class="nm">{{ name || name_en || code }}</span>
        <span class="lang-badge lg-code">{{ code }}</span>
      </div>
      <span class="en" v-if="name_en && name_en !== (name || code)">{{ name_en }}</span>
    </div>
    <span class="lg-geo">
      <span v-if="script_code" class="lg-script">{{ script_code }}</span>
      <template v-if="direction">
        <span v-if="direction === 'rtl'" class="lg-dir lg-rtl" title="right-to-left">rtl</span>
        <span v-else class="lg-dir">ltr</span>
      </template>
    </span>
    <span class="lg-count">{{ expression_count.toLocaleString() }}</span>
  </router-link>
</template>

<style scoped>
.lg-row {
  display: grid;
  grid-template-columns: subgrid;
  grid-column: 1 / -1;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
  text-decoration: none;
  color: inherit;
  transition: background 0.1s;
}
.lg-row:last-child { border-bottom: none; }
.lg-row:hover { background: var(--bg); }
.lg-name { min-width: 0; }
.lg-title { display: inline-flex; align-items: center; gap: 8px; min-width: 0; max-width: 100%; }
.lg-title .nm { font-size: 18px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
.lg-code { flex: none; white-space: nowrap; }
.lg-name .en { display: block; font-size: 13px; color: var(--muted); margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lg-geo { display: inline-flex; align-items: center; gap: 6px; font-family: var(--mono); font-size: 13px; color: var(--muted); white-space: nowrap; }
.lg-script { overflow: hidden; text-overflow: ellipsis; }
.lg-rtl { color: var(--accent); }
.lg-dir { text-transform: uppercase; letter-spacing: 0.04em; }
.lg-count {
  font-family: var(--mono);
  font-variant-numeric: tabular-nums;
  font-size: 16px;
  color: var(--accent);
  text-align: right;
}
@media (max-width: 640px) {
  .lg-row { min-height: 44px; }
  .lg-geo { display: none; }
}
</style>
