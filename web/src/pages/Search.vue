<template>
  <div>
    <div style="display:flex; gap:8px; margin-bottom:16px; align-items:center">
      <input v-model="q" placeholder="Search phrase" style="flex:1; padding:8px" @keydown.enter="search" />
      <button @click="search" style="padding:8px 12px">Search</button>
    </div>

    <div v-if="loading">Loading…</div>
    <div v-else>
      <div v-if="items.length === 0">
        <div>No results found.</div>
        <div style="margin-top:8px">
          <button @click="$router.push({ name: 'create', query: { text: q } })" style="padding:8px 12px">Add new expression</button>
        </div>
      </div>
      <div v-for="it in items" :key="it.id" style="margin-bottom:12px">
        <ExpressionCard :item="it" />
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import ExpressionCard from '../components/ExpressionCard.vue'

export default {
  components: { ExpressionCard },
  setup () {
    const q = ref('')
    const items = ref([])
    const loading = ref(false)

    async function search () {
      loading.value = true
      try {
        const params = new URLSearchParams()
        if (q.value) params.set('q', q.value)
        // no language selector in MVP; server will return cross-language matches via meanings
        const res = await fetch(`/api/v1/search?${params.toString()}`)
        if (!res.ok) throw new Error('search failed')
        const data = await res.json()
        items.value = data
      } catch (e) {
        console.error(e)
        items.value = []
      } finally {
        loading.value = false
      }
    }

    return { q, items, loading, search }
  }
}
</script>
