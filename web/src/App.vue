<template>
  <div id="app" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex-1 flex flex-col">
    <header class="py-6 border-b border-slate-200">
      <h1 class="text-3xl font-bold text-slate-800">langmap</h1>
      <p class="text-slate-600 mt-1">Mapping linguistic expressions across regions and languages</p>
    </header>
    <main class="py-6">
      <router-view />
    </main>
  </div>
  <footer class="py-6 border-t border-slate-200 text-center text-slate-500 text-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <p>© {{ new Date().getFullYear() }} langmap - Linguistic Expression Mapping Platform</p>
    </div>
  </footer>
</template>

<script>
export default {
  name: 'App'
}
</script>