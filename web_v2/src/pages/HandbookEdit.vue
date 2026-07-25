<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import SectionEditor from '@/components/handbook/SectionEditor.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'

const route = useRoute()
const router = useRouter()
const { detail, create, update } = useHandbooks()

const isNew = computed(() => route.params.id === 'new')
const id = computed(() => parseInt(route.params.id as string))

const title = ref('')
const visibility = ref('public')
const sections = ref<Array<{
  title: string
  expressions: Array<{ id: number; text: string; language_code: string; position: number }>
}>>([])
const saving = ref(false)
const loading = ref(true)
const loadError = ref('')
const saveError = ref('')

onMounted(async () => {
  if (isNew.value) {
    loading.value = false
    return
  }
  try {
    const hb = await detail(id.value)
    title.value = hb.title
    visibility.value = hb.visibility
    sections.value = hb.sections.map((s: any) => ({
      title: s.title || '',
      expressions: (s.expressions || []).map((e: any, i: number) => ({
        id: e.expression_id,
        text: e.text,
        language_code: e.language_code,
        position: i,
      })),
    }))
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
})

function addSection() {
  sections.value.push({ title: '', expressions: [] })
}

function removeSection(i: number) {
  sections.value.splice(i, 1)
}

function moveSection(i: number, dir: -1 | 1) {
  const j = i + dir
  if (j < 0 || j >= sections.value.length) return
  const temp = sections.value[i]
  sections.value[i] = sections.value[j]
  sections.value[j] = temp
}

function addExprToSection(i: number, expr: any) {
  if (!sections.value[i].expressions.find(e => e.id === expr.id)) {
    sections.value[i].expressions.push({ ...expr, position: sections.value[i].expressions.length })
  }
}

function removeExprFromSection(i: number, exprId: number) {
  sections.value[i].expressions = sections.value[i].expressions.filter(e => e.id !== exprId)
}

async function save() {
  saving.value = true
  saveError.value = ''
  try {
    const payload = {
      title: title.value,
      visibility: visibility.value,
      sections: sections.value.map(s => ({
        title: s.title,
        expressionIds: s.expressions.map(e => e.id),
      })),
    }
    if (isNew.value) {
      const result = await create(payload)
      router.push(`/handbook/${result.id}`)
    } else {
      await update(id.value, payload)
      router.push(`/handbook/${id.value}`)
    }
  } catch (e: any) {
    saveError.value = e.response?.data?.error || '儲存失敗'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError && isNew" :message="loadError" />

  <div v-else class="he-page">
    <router-link to="/handbooks" class="he-back">← 手冊列表</router-link>

    <div class="he-head">
      <input v-model="title" class="he-title" placeholder="手冊標題" />
      <select v-model="visibility" class="he-vis">
        <option value="public">公開</option>
        <option value="private">私有</option>
      </select>
    </div>

    <div class="he-actions">
      <button class="btn btn-primary" :disabled="saving || !title" @click="save">
        {{ saving ? '儲存中…' : '儲存' }}
      </button>
    </div>

    <SectionEditor
      v-for="(sec, i) in sections"
      :key="i"
      :title="sec.title"
      :expressions="sec.expressions"
      :index="i"
      @update:title="sec.title = $event"
      @remove="removeSection(i)"
      @move-up="moveSection(i, -1)"
      @move-down="moveSection(i, 1)"
      @add-expression="addExprToSection(i, $event)"
      @remove-expression="removeExprFromSection(i, $event)"
    />

    <button class="btn btn-ghost" @click="addSection">＋ 新增章節</button>

    <p v-if="loadError && !isNew" class="error">{{ loadError }}</p>
    <p v-if="saveError" class="error">{{ saveError }}</p>
  </div>
</template>

<style scoped>
.he-page { max-width: 760px; margin: 0 auto; }
.he-back { font-size: 14px; display: inline-block; margin-bottom: 12px; }
.he-head { display: flex; gap: 12px; align-items: center; margin-bottom: 16px; }
.he-title { flex: 1; font-size: 20px; font-family: "Noto Serif", serif; font-weight: 700; padding: 8px; border: 1px solid #EDE5D8; border-radius: 4px; }
.he-vis { padding: 8px; }
.he-actions { margin-bottom: 20px; }
.error { color: #A03030; font-size: 13px; margin-top: 16px; }
</style>
