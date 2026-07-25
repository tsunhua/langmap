<script setup lang="ts">
import TopNav from './components/nav/TopNav.vue'
import SiteFooter from './components/nav/SiteFooter.vue'
</script>

<template>
  <TopNav />
  <main class="page">
    <router-view />
  </main>
  <SiteFooter />
</template>
