<template>
  <div>
    <div v-if="loading">Loading versions…</div>
    <div v-else>
      <div v-if="versions.length === 0">No versions available.</div>
      <ul class="mt-2 space-y-2">
        <li v-for="v in versions" :key="v.id" class="p-3 border rounded">
          <div class="text-sm text-gray-700"><strong>{{ v.text }}</strong></div>
          <div class="text-xs text-gray-500">{{ v.created_at }} · {{ v.review_status }} <span v-if="v.auto_approved">(auto)</span></div>
          <div class="mt-2 text-sm text-gray-600">{{ v.change_summary || '' }}</div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'

export default {
  props: ['expressionId'],
  setup (props) {
    const versions = ref([])
    const loading = ref(false)

    async function load () {
      loading.value = true
      try {
        const res = await fetch(`/api/v1/expressions/${props.expressionId}/versions`)
        if (!res.ok) {
          versions.value = []
          return
        }
        versions.value = await res.json()
      } catch (e) {
        console.warn(e)
      } finally {
        loading.value = false
      }
    }

    onMounted(load)
    return { versions, loading }
  }
}
</script>
