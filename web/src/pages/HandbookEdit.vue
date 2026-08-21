<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import SectionEditor from '@/components/handbook/SectionEditor.vue'
import { Plus } from 'lucide-vue-next'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()
const { detail, create, update } = useHandbooks()

const isNew = computed(() => route.params.id === 'new')
const id = computed(() => route.params.id as string)

const title = ref('')
const visibility = ref('public')
const sections = ref<Array<{
  title: string
  expressions: Array<{ id: string; text: string; lang_code: string; position: number }>
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
      expressions: (s.items || []).map((e: any, i: number) => ({
        id: e.id,
        text: e.text,
        lang_code: e.lang_code,
        position: i,
      })),
    }))
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('handbook.loadFailed')
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

function removeExprFromSection(i: number, exprId: string) {
  sections.value[i].expressions = sections.value[i].expressions.filter(e => e.id !== exprId)
}

function moveExpression(sectionId: number, itemId: string, direction: 'up' | 'down') {
  const section = sections.value[sectionId]
  if (!section) return
  const idx = section.expressions.findIndex(e => e.id === itemId)
  if (idx < 0) return
  const newIdx = direction === 'up' ? idx - 1 : idx + 1
  if (newIdx < 0 || newIdx >= section.expressions.length) return
  const temp = section.expressions[idx]
  section.expressions[idx] = section.expressions[newIdx]
  section.expressions[newIdx] = temp
}

async function save(status: string) {
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
      status,
    }
    if (isNew.value) {
      const result = await create(payload)
      router.push(`/handbooks/${result.id}`)
    } else {
      await update(id.value, payload)
    router.push(`/handbooks/${id.value}`)
    }
  } catch (e: any) {
    saveError.value = e.response?.data?.error || t('handbook.loadFailed')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError && !isNew" :message="loadError" />

  <div v-else class="he-page">
    <router-link to="/handbooks" class="he-back">← {{ t('handbook.back') }}</router-link>

    <div class="he-head">
      <input v-model="title" class="he-title" :placeholder="t('handbook.titlePlaceholder')" :aria-label="t('handbook.titlePlaceholder')" />
      <select v-model="visibility" class="he-vis" :aria-label="t('handbook.visibility')">
        <option value="public">{{ t('handbook.public') }}</option>
        <option value="private">{{ t('handbook.private') }}</option>
      </select>
    </div>

    <div class="he-actions">
      <button class="btn" @click="save('draft')" :disabled="saving || !title">
        {{ saving ? t('handbook.saving') : t('handbook.saveDraft') }}
      </button>
      <button class="btn btn-primary" @click="save('published')" :disabled="saving || !title">
        {{ saving ? t('handbook.saving') : t('handbook.publish') }}
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
      @move-expr-up="(id) => moveExpression(i, id, 'up')"
      @move-expr-down="(id) => moveExpression(i, id, 'down')"
    />

    <button class="btn btn-ghost" @click="addSection"><Plus :size="14" aria-hidden="true" /> {{ t('handbook.addSection') }}</button>

    <p v-if="loadError && !isNew" class="error" role="alert">{{ loadError }}</p>
    <p v-if="saveError" class="error" role="alert">{{ saveError }}</p>
  </div>
</template>

<style scoped>
.he-page { max-width: 760px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.he-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.he-back:hover { color: var(--fg); }
.he-head { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
.he-title { flex: 1; min-width: 0; font-size: 24px; font-weight: 600; font-family: var(--font); padding: 6px 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); }
.he-title:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent); }
.he-vis { padding: 8px 10px; }
.he-actions { margin-bottom: var(--space-md); }
.error { color: var(--down); font-size: 13px; margin-top: var(--space-base); }
</style>
