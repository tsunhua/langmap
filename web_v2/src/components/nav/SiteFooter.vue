<script setup lang="ts">
// ADR-0002 §6: API entry lives in the footer (not the header).
</script>

<template>
  <footer class="site-foot">
    <div class="foot-inner">
      <span class="copy">© {{ new Date().getFullYear() }} LangMap</span>
    </div>
  </footer>
</template>

<style scoped>
.site-foot {
  border-top: 1px solid var(--border);
  background: color-mix(in oklch, var(--bg) 60%, transparent);
  padding: 16px 20px;
}
.foot-inner {
  max-width: 920px; margin: 0 auto;
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; flex-wrap: wrap;
}
.foot-nav { display: flex; gap: 16px; }
.foot-nav a {
  font-family: var(--mono); font-size: 10px;
  text-transform: uppercase; letter-spacing: 0.06em;
  color: var(--muted); text-decoration: none;
}
.foot-nav a:hover { color: var(--accent); }
.copy {
  font-family: var(--mono); font-size: 10px;
  color: var(--muted);
}
@media (max-width: 640px) {
  .foot-inner { flex-direction: column; align-items: flex-start; gap: 8px; }
}
</style>
