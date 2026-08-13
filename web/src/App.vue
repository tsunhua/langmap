<script setup lang="ts">
import TopNav from './components/nav/TopNav.vue'
import SiteFooter from './components/nav/SiteFooter.vue'
</script>

<template>
  <a class="skip-link" href="#main-content">{{ $t('nav.skipToContent') }}</a>
  <TopNav />
  <main id="main-content" class="page" tabindex="-1">
    <router-view />
  </main>
  <SiteFooter />
</template>

<style scoped>
.skip-link {
  position: fixed;
  z-index: 200;
  top: 8px;
  left: 8px;
  transform: translateY(calc(-100% - 16px));
  padding: 10px 14px;
  border: 2px solid var(--accent);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--fg);
  transition: transform 0.15s;
}
.skip-link:focus { transform: translateY(0); }
@media (prefers-reduced-motion: reduce) {
  .skip-link { transition: none; }
}
</style>
