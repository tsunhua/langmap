<template>
  <div id="app" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex-1 flex flex-col">
    <header class="py-6">
      <div class="flex items-center justify-between">
        <router-link to="/" class="no-underline">
          <h1 class="text-3xl font-bold text-slate-800 hover:text-blue-600 transition-colors">Langmap</h1>
        </router-link>
        <nav class="flex items-center gap-6">
          <router-link 
            to="/" 
            class="text-slate-600 hover:text-slate-900 font-medium transition-colors"
            active-class="text-blue-600"
          >
            Home
          </router-link>
          <router-link 
            to="/search" 
            class="text-slate-600 hover:text-slate-900 font-medium transition-colors"
            active-class="text-blue-600"
          >
            Search
          </router-link>
          <router-link 
            to="/expressions/new" 
            class="inline-flex items-center justify-center px-4 py-2 rounded-md bg-blue-600 text-white hover:bg-blue-700 font-medium transition-colors"
          >
            Add Expression
          </router-link>
        </nav>
      </div>
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