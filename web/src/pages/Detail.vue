<template>
  <div>
    <button @click="$router.push({ name: 'home' })" class="text-sm text-blue-600 mb-4">← Back</button>
    <div v-if="loading">Loading…</div>
    <div v-else-if="item">
      <div style="display:flex; gap:24px; align-items:flex-start;">
        <!-- Left column: current item + translations as a unified list -->
        <div style="flex: 1 1 65%;">
          <h3 style="margin:0 0 12px 0; font-weight:600">Expressions</h3>
          <div style="display:flex; flex-direction:column; gap:12px">
            <!-- current item shown as same card style -->
            <ExpressionCard :item="item" :key="item.id" />
            <div style="margin-top:8px">
              <button v-if="!associateMode" @click="associateMode = true" style="padding:6px 10px">Associate other expressions</button>
              <button v-else @click="associateMode = false" style="padding:6px 10px">Close associate panel</button>
            </div>

            <div v-if="associateMode" style="border:1px solid #eee; padding:12px; margin-top:8px; background:#fff">
              <div style="display:flex; gap:8px; align-items:center">
                <input v-model="assocQuery" placeholder="Search expressions to associate" style="flex:1; padding:8px" @keydown.enter="searchAssociate" />
                <button @click="searchAssociate" style="padding:8px 10px">Search</button>
              </div>
              <div style="margin-top:8px">
                <div v-if="assocLoading">Searching…</div>
                  <div v-else-if="assocResults.length === 0">No candidates.</div>
                  <div v-else>
                    <div v-for="c in assocResults" :key="c && c.id" style="display:flex; gap:8px; align-items:center; margin-top:8px">
                      <div v-if="c && item && c.id !== item.id" style="display:flex; gap:8px; align-items:center; width:100%">
                        <div style="flex:1"><ExpressionCard :item="c" /></div>
                        <div>
                          <button v-if="!isLinked(c.id)" @click="associateWith(c)" style="padding:6px 10px">Link</button>
                          <span v-else style="color:#666; padding:6px">Already linked</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div v-if="assocMsg" style="color:#070; margin-top:8px">{{ assocMsg }}</div>
                  <div v-if="assocHasCurrent" style="color:#a60; margin-top:8px">Search results include the current expression.</div>

                  <div style="margin-top:12px">
                    <label style="font-weight:600">Link to meaning:</label>
                    <select v-model="selectedMeaningId" style="margin-left:8px; padding:6px">
                      <option :value="null">-- Select meaning --</option>
                      <option v-for="m in meanings" :key="m.id" :value="m.id">{{ m.gloss }} — {{ m.description }}</option>
                      <option :value="'__new'">Create new meaning…</option>
                    </select>

                    <div v-if="selectedMeaningId === '__new'" style="margin-top:8px">
                      <input v-model="newMeaningGloss" placeholder="New meaning gloss" style="padding:6px; width:60%" />
                      <button @click="createMeaning" style="padding:6px 10px; margin-left:8px">Create</button>
                    </div>
                  </div>
              </div>
            </div>
            <!-- Meanings list -->
            <div style="margin-top:12px">
              <h4 style="margin:6px 0">Meanings</h4>
              <div v-if="meanings.length === 0" style="color:#666">No meanings.</div>
              <div v-else>
                <div v-for="m in meanings" :key="m.id" style="border:1px solid #eee; padding:8px; margin-top:8px; background:#fafafa">
                    <div style="display:flex; justify-content:space-between; align-items:center">
                      <div style="font-weight:600">{{ m.gloss }} <span style="color:#666; font-weight:400">{{ m.description ? '— ' + m.description : '' }}</span> <span style="color:#666; font-weight:400">({{ m.members ? m.members.length : 0 }})</span></div>
                      <div>
                        <button @click="toggleMeaning(m.id)" style="padding:6px">{{ isExpanded(m.id) ? 'Collapse' : 'Expand' }}</button>
                      </div>
                    </div>
                    <div v-show="isExpanded(m.id)" style="margin-top:8px">
                      <div v-if="!m.members || m.members.length === 0" style="color:#666">No members.</div>
                      <div v-else>
                        <div v-for="mem in m.members" :key="mem.id" style="margin-top:8px">
                          <div style="display:flex; align-items:center; gap:8px">
                            <div style="flex:1"><ExpressionCard :item="mem" /></div>
                            <div v-if="item && mem && mem.id === item.id" style="color:#006; font-weight:600; margin-left:8px">Current</div>
                          </div>
                        </div>
                      </div>
                    </div>
                </div>
              </div>
            </div>
            <!-- translations list removed — meanings are now the canonical grouping -->
          </div>
        </div>

        <!-- Right column: version history, aligned with the list -->
        <div style="flex: 0 0 320px;">
          <h3 style="margin:0 0 12px 0; font-weight:600">Version history</h3>
          <div>
            <VersionHistory :expressionId="id" />
          </div>
        </div>
      </div>
    </div>
    <div v-else>Not found.</div>
  </div>
</template>

<script>
import { ref, onMounted, watch, computed } from 'vue'
import VersionHistory from '../components/VersionHistory.vue'
import ExpressionCard from '../components/ExpressionCard.vue'

export default {
  components: { VersionHistory, ExpressionCard },
  props: ['id'],
  setup (props) {
    const item = ref(null)
    const loading = ref(false)
    const translations = ref([])
    const transLoading = ref(false)
    const associateMode = ref(false)
    const assocQuery = ref('')
    const assocResults = ref([])
    const assocLoading = ref(false)
    const assocMsg = ref('')
    const meanings = ref([])
    const selectedMeaningId = ref(null)
    const newMeaningGloss = ref('')
    const linkedIds = computed(() => {
      const s = new Set()
      if (item.value && item.value.id) s.add(item.value.id)
      for (const m of meanings.value || []) {
        if (m && m.members) {
          for (const mem of m.members) {
            if (mem && mem.id) s.add(mem.id)
          }
        }
      }
      return s
    })

    // whether the assoc search returned the current item
    const assocHasCurrent = computed(() => {
      try {
        if (!assocResults.value || !item.value) return false
        return assocResults.value.some(r => r && r.id === item.value.id)
      } catch (e) {
        return false
      }
    })

    // safe helper to check if an id is linked
    function isLinked (id) {
      try {
        return linkedIds && linkedIds.value && typeof linkedIds.value.has === 'function' ? linkedIds.value.has(id) : false
      } catch (e) {
        return false
      }
    }

    // collapse/expand state for meanings (object map for reactivity)
    const expanded = ref({})
    function toggleMeaning (mid) {
      const m = expanded.value || {}
      m[mid] = !m[mid]
      expanded.value = { ...m }
    }
    function isExpanded (mid) {
      return !!(expanded.value && expanded.value[mid])
    }

    async function load () {
      loading.value = true
      try {
        const res = await fetch(`/api/v1/expressions/${props.id}`)
        if (!res.ok) throw new Error('not found')
        item.value = await res.json()
        // fetch translations via server-side meaning grouping
        transLoading.value = true
        try {
          const tr = await fetch(`/api/v1/expressions/${props.id}/translations`)
          if (tr.ok) {
            translations.value = await tr.json()
          } else {
            translations.value = []
          }
        } catch (e) {
          console.warn('translations fetch failed', e)
          translations.value = []
        } finally {
          transLoading.value = false
        }
        // fetch meanings for this expression and their members
        try {
          const mr = await fetch(`/api/v1/expressions/${props.id}/meanings`)
          if (mr.ok) {
            const list = await mr.json()
            // for each meaning fetch its members
            for (const m of list) {
              try {
                const mm = await fetch(`/api/v1/meanings/${m.id}/members`)
                if (mm.ok) {
                  m.members = await mm.json()
                } else {
                  m.members = []
                }
              } catch (e) {
                m.members = []
              }
            }
            meanings.value = list
          } else meanings.value = []
        } catch (e) {
          meanings.value = []
        }
      } catch (e) {
        console.warn(e)
      } finally {
        loading.value = false
      }
    }

    async function searchAssociate () {
      assocLoading.value = true
      assocMsg.value = ''
      try {
        const params = new URLSearchParams()
        if (assocQuery.value) params.set('q', assocQuery.value)
        const url = `/api/v1/search?${params.toString()}`
        console.debug('Assoc search URL:', url)
        const res = await fetch(url)
        if (!res.ok) throw new Error('search failed')
        assocResults.value = await res.json()
        console.debug('Assoc search returned', assocResults.value.length, 'items')
        assocMsg.value = `Found ${assocResults.value.length} candidates.`
      } catch (e) {
        assocMsg.value = String(e)
        assocResults.value = []
      } finally {
        assocLoading.value = false
      }
    }

    async function createMeaning () {
      assocMsg.value = ''
      if (!newMeaningGloss.value || newMeaningGloss.value.trim() === '') {
        assocMsg.value = 'Please enter a gloss for the new meaning.'
        return null
      }
      try {
        const pm = await fetch('/api/v1/meanings', {
          method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ gloss: newMeaningGloss.value.trim(), description: 'Created via UI' })
        })
        if (!pm.ok) throw new Error('failed to create meaning')
        const newm = await pm.json()
        // attach empty members (will refresh on next load)
        newm.members = []
        meanings.value.push(newm)
        selectedMeaningId.value = newm.id
        newMeaningGloss.value = ''
        assocMsg.value = 'Created new meaning and selected it.'
        return newm
      } catch (e) {
        assocMsg.value = String(e)
        return null
      }
    }

    async function associateWith (target) {
      assocMsg.value = ''
      try {
        let mid = selectedMeaningId.value
        // if user chose to create new meaning via selector value '__new', use createMeaning
        if (mid === '__new') {
          const nm = await createMeaning()
          if (!nm) throw new Error('failed to create new meaning')
          mid = nm.id
        }
        // if still no mid, fallback to first meaning or create one from item text
        if (!mid) {
          if (meanings.value && meanings.value.length > 0) {
            mid = meanings.value[0].id
          } else {
            const pm = await fetch('/api/v1/meanings', {
              method: 'POST', headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ gloss: item.value.text, description: 'Created via UI association' })
            })
            if (!pm.ok) throw new Error('failed to create meaning')
            const newm = await pm.json()
            mid = newm.id
          }
        }

        // link current expression
        const link1 = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${props.id}`, { method: 'POST' })
        if (!link1.ok) throw new Error('failed to link current expression')
        // link target expression
        const link2 = await fetch(`/api/v1/meanings/${mid}/link?expression_id=${target.id}`, { method: 'POST' })
        if (!link2.ok) throw new Error('failed to link target expression')

        assocMsg.value = 'Linked successfully.'
        // refresh translations and meanings
        await load()
      } catch (e) {
        assocMsg.value = String(e)
      }
    }

    onMounted(load)
    // when the route param `id` changes the same component instance is reused by the router;
    // watch the prop and reload the details when it changes
    watch(() => props.id, (newId, oldId) => {
      if (newId !== oldId) load()
    })
    return { item, loading, translations, transLoading, associateMode, assocQuery, assocResults, assocLoading, assocMsg, meanings, linkedIds, assocHasCurrent, isLinked, searchAssociate, associateWith, selectedMeaningId, newMeaningGloss, createMeaning, toggleMeaning, isExpanded }
  }
}
</script>
