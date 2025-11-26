<template>
  <div id="app" class="container">
    <header class="py-6 border-b">
      <h1 class="text-2xl font-semibold">langmap — Demo</h1>
    </header>
    <main class="py-6">
      <router-view />
    </main>
  </div>
</template>

<script>
import Search from './pages/Search.vue'
export default {
  components: { Search }
}
</script>

<style>
body { font-family: system-ui, sans-serif; }
</style>
