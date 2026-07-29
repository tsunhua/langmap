<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/api/client'
import CliquePreview from '@/components/mapping/CliquePreview.vue'
import LanguagePicker from '@/components/language/LanguagePicker.vue'
import TagInput from '@/components/ui/TagInput.vue'
import { useI18n } from 'vue-i18n'

const router = useRouter()
const { t } = useI18n()

interface Row {
  key: number
  lang: string
  text: string
  tags: string
}

let keySeq = 0
const newRow = (): Row => ({ key: keySeq++, lang: '', text: '', tags: '' })
const rows = ref<Row[]>([newRow(), newRow()])

const submitting = ref(false)
const error = ref('')

const validRows = computed(() => rows.value.filter(r => r.text.trim() !== ''))
const nodeCount = computed(() => validRows.value.length)
const edgeCount = computed(() => {
  const n = nodeCount.value
  return n * (n - 1) / 2
})

function addRow() {
  rows.value.push(newRow())
}

function removeRow(key: number) {
  rows.value = rows.value.filter(r => r.key !== key)
}

async function submit() {
  const payload = validRows.value
    .filter(r => r.lang.trim() !== '')
    .map(r => ({ lang: r.lang.trim(), text: r.text.trim(), tags: r.tags.trim() || undefined }))
  if (payload.length < 2) {
    error.value = t('contribute.minRows')
    return
  }
  submitting.value = true
  error.value = ''
  try {
    await api.post('/contributions/batch', { expressions: payload })
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.error || t('contribute.submitFailed')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="contrib-page">
    <h1>{{ t('contribute.title') }}</h1>
    <p class="lead">{{ t('contribute.lead') }}</p>

    <div class="contrib-grid">
      <div class="contrib-left">
        <div class="ex-table">
          <div class="ex-head">
            <span>{{ t('contribute.language') }}</span><span>{{ t('contribute.expression') }}</span><span>{{ t('contribute.tags') }}</span><span></span>
          </div>
          <div class="ex-rows">
            <div v-for="row in rows" :key="row.key" class="ex-row">
              <LanguagePicker v-model="row.lang" :label="t('contribute.language')" :allow-create="true" />
              <input class="ex-text" v-model="row.text" :placeholder="t('contribute.expressionPlaceholder')" :aria-label="t('contribute.expression')" />
              <TagInput v-model="row.tags" :placeholder="t('contribute.tags')" />
              <button class="ex-del" :title="t('contribute.delete')" :aria-label="t('contribute.delete')" @click="removeRow(row.key)">✕</button>
            </div>
          </div>
          <button class="ex-add" type="button" @click="addRow">{{ t('contribute.addExpression') }}</button>
        </div>

        <div :class="['ex-counter', { warn: nodeCount < 2 }]">
          <span>{{ t('contribute.expressionCount', { count: nodeCount }) }}</span>
          <span class="arrow">→</span>
          <span>{{ t('contribute.directMappingCount', { count: edgeCount }) }}</span>
          <span class="tag">{{ t('contribute.completeGraph') }}</span>
        </div>

        <p v-if="error" class="error" role="alert">{{ error }}</p>

        <div class="ex-actions">
          <button class="btn btn-primary" type="button" data-action="submit-contribution" :disabled="nodeCount < 2 || submitting" @click="submit">
            {{ submitting ? t('contribute.submitting') : t('contribute.submit') }}
          </button>
        </div>
      </div>

      <div class="contrib-right">
        <CliquePreview :expressions="validRows" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.contrib-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.contrib-page h1 { font-size: 22px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: 6px; }
.lead { font-size: 13px; color: var(--muted); line-height: 1.55; margin-bottom: var(--space-xl); max-width: 60ch; }
.lead b { color: var(--fg); font-weight: 500; }

.contrib-grid { display: grid; grid-template-columns: 1fr 260px; gap: var(--space-xl); align-items: start; }

.ex-table { border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); overflow: hidden; }
.ex-head, .ex-row {
  display: grid; grid-template-columns: 140px 1fr 80px 32px; gap: var(--space-xs); align-items: start;
  padding: var(--space-xs) var(--space-sm);
}
.ex-head {
  border-bottom: 1px solid var(--border); background: var(--surface-2);
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted);
}
.ex-rows .ex-row { border-bottom: 1px solid var(--border); }
.ex-rows .ex-row:last-child { border-bottom: none; }
.ex-row .lang-picker { position: relative; }
.ex-row .lang-picker :deep(.picker-label) { display: none; }
.ex-row .lang-picker :deep(.picker-selected),
.ex-row .lang-picker :deep(.picker-input) {
  min-height: 32px; padding: 4px 10px;
}
.ex-row .lang-picker :deep(.picker-clear) {
  width: 28px; height: 28px;
}
.ex-row .lang-picker :deep(.picker-create) { display: none; }
.ex-row input {
  height: 32px; border: 1px solid var(--border); border-radius: var(--r);
  background: var(--bg); padding: 0 var(--space-xs); font-size: 13px; outline: none; min-width: 0;
}
.ex-row input:focus { border-color: var(--accent); }
.ex-del {
  width: 28px; height: 28px; border: none; background: transparent; color: var(--muted);
  cursor: pointer; border-radius: var(--r); font-size: 13px; display: grid; place-items: center;
}
.ex-del:hover { color: var(--down); background: color-mix(in oklch, var(--down) 8%, var(--surface)); }
.ex-add {
  width: 100%; border: none; border-top: 1px dashed var(--border); background: transparent;
  color: var(--muted); cursor: pointer; padding: var(--space-xs); font-size: 12px;
  font-family: var(--mono); letter-spacing: 0.04em;
}
.ex-add:hover { color: var(--accent); background: var(--accent-soft); }

.ex-counter {
  display: flex; align-items: center; gap: 12px; flex-wrap: wrap;
  margin: var(--space-md) 0; padding: var(--space-xs) var(--space-sm); background: var(--surface);
  border: 1px solid var(--border); border-radius: var(--r);
  font-size: 14px;
}
.ex-counter b { font-family: var(--mono); font-variant-numeric: tabular-nums; color: var(--accent); font-size: 16px; font-weight: 600; }
.ex-counter .arrow { color: var(--faint); }
.ex-counter .tag { font-family: var(--mono); font-size: 10px; color: var(--muted); letter-spacing: 0.04em; text-transform: uppercase; margin-left: auto; }
.ex-counter.warn b { color: var(--down); }

.ex-actions { display: flex; gap: 8px; }
.error { color: var(--down); font-size: 13px; }

.contrib-right { position: sticky; top: 60px; }

@media (max-width: 760px) {
  .contrib-grid { grid-template-columns: 1fr; }
  .contrib-right { position: static; }
  .ex-head, .ex-row { grid-template-columns: 1fr; gap: 8px; }
  .ex-head span:first-child { display: none; }
}
</style>
