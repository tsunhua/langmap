<template>
  <div>
    <h2 class="text-xl font-bold mb-4">Add New Expression</h2>

    <div style="max-width:700px">
      <label class="block mb-2">Text</label>
      <textarea v-model="text" rows="3" style="width:100%; padding:8px"></textarea>

      <label class="block mt-3 mb-2">Language (BCP-47)</label>
      <input v-model="language" placeholder="e.g. en, zh-CN" style="width:100%; padding:8px" />

      <label class="block mt-3 mb-2">Region (optional)</label>
      <input v-model="region" placeholder="e.g. China, Spain" style="width:100%; padding:8px" />

      <label class="block mt-3 mb-2">Source reference (optional)</label>
      <input v-model="source_ref" placeholder="e.g. 'Wiktionary' or a URL" style="width:100%; padding:8px" />

      <div style="margin-top:12px">
        <button @click="submit" style="padding:8px 12px">Create</button>
        <button @click="$router.back()" style="padding:8px 12px; margin-left:8px">Cancel</button>
      </div>

      <div v-if="error" style="color:#b00; margin-top:8px">{{ error }}</div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

export default {
  setup () {
    const route = useRoute()
    const router = useRouter()
    const text = ref(route.query.text || '')
    const language = ref(route.query.language || '')
    const region = ref(route.query.region || '')
    const source_ref = ref(route.query.source_ref || '')
    const error = ref(null)

    async function submit () {
      error.value = null
      if (!text.value || !language.value) {
        error.value = 'Language and text are required.'
        return
      }
      try {
        const payload = {
          text: text.value,
          language: language.value,
          region: region.value || null,
          source_ref: source_ref.value || null,
        }
        const res = await fetch('/api/v1/expressions', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        })
        if (!res.ok) {
          const txt = await res.text()
          throw new Error(txt || 'create failed')
        }
        const created = await res.json()
        // navigate to detail view for the created expression
        router.push({ name: 'detail', params: { id: created.id } })
      } catch (e) {
        error.value = e.message || String(e)
      }
    }

    return { text, language, region, source_ref, submit, error }
  }
}
</script>
