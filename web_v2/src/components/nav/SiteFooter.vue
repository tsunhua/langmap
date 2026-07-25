<script setup lang="ts">
// ADR-0002 §6: API entry lives in the footer (not the header).
</script>

<template>
  <footer class="site-foot">
    <div class="foot-inner">
      <span class="brand">lang<span class="em">map</span> · atlas</span>
      <nav class="foot-nav">
        <a href="/api/v2" title="API 端點">API</a>
        <router-link to="/handbooks">手冊</router-link>
        <router-link to="/languages">語言</router-link>
      </nav>
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
.brand {
  font-weight: 600; font-size: 14px; color: var(--fg);
}
.brand .em {
  font-family: var(--mono); font-size: 9px;
  background: var(--accent); color: #fff; padding: 1px 3px;
  border-radius: 2px; margin-left: 2px; vertical-align: super;
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
