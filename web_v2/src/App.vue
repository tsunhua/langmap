<script setup lang="ts">
import TopNav from './components/nav/TopNav.vue'
</script>

<template>
  <TopNav />
  <main class="page">
    <router-view />
  </main>
</template>
