<template>
  <div class="max-w-2xl mx-auto">
    <div class="flex items-center mb-6">
      <button @click="$router.back()" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 border border-slate-300 bg-transparent text-slate-700 hover:bg-slate-50 focus:ring-slate-500 px-4 py-2 flex items-center mr-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
        </svg>
        Back
      </button>
      <h2 class="text-2xl font-bold text-slate-800">Add New Expression</h2>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-1">Text *</label>
        <textarea 
          v-model="text" 
          rows="3" 
          class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
          placeholder="Enter the linguistic expression"
        ></textarea>
        <p class="text-sm text-slate-500 mt-1">The actual word or phrase in the language</p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Language (BCP-47) *</label>
          <input 
            v-model="language" 
            placeholder="e.g. en, zh-CN, es-ES" 
            class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
          />
          <p class="text-sm text-slate-500 mt-1">Standard language code</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Region (optional)</label>
          <input 
            v-model="region" 
            placeholder="e.g. China, Spain, Global" 
            class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
          />
          <p class="text-sm text-slate-500 mt-1">Geographic region or area</p>
        </div>
      </div>

      <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-1">Source reference (optional)</label>
        <input 
          v-model="source_ref" 
          placeholder="e.g. Wiktionary, Dictionary.com, or a URL" 
          class="block w-full rounded-md border-slate-300 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50" 
        />
        <p class="text-sm text-slate-500 mt-1">Origin or reference for this expression</p>
      </div>

      <div class="flex flex-wrap gap-3">
        <button @click="submit" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          Create Expression
        </button>
        <button @click="$router.back()" class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
          Cancel
        </button>
      </div>

      <div v-if="error" class="mt-4 p-3 bg-red-50 text-red-700 rounded-lg flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

export default {
  name: 'CreateExpression',
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