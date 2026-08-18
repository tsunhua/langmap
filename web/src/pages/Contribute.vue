<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/api/client'
import CliquePreview from '@/components/mapping/CliquePreview.vue'
import LanguageLocalePicker from '@/components/language/LanguageLocalePicker.vue'
import type { LanguageLocale } from '@/api/languageIdentity'
import { X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'

const router = useRouter()
const { t } = useI18n()

interface Row {
  key: number
  lang_code: string
  language_locale_code: string
  text: string
}

let keySeq = 0
const newRow = (): Row => ({ key: keySeq++, lang_code: '', language_locale_code: '', text: '' })
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

function selectLocale(row: Row, locale: LanguageLocale | null) {
  row.lang_code = locale?.lang_code ?? ''
}

async function submit() {
  const payload = validRows.value
    .filter(r => r.lang_code.trim() !== '')
    .map(r => ({ lang_code: r.lang_code.trim(), text: r.text.trim(), ...(r.language_locale_code ? { language_locale_code: r.language_locale_code } : {}) }))
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
            <span>{{ t('contribute.locale') }}</span><span>{{ t('contribute.expression') }}</span><span></span>
          </div>
          <div class="ex-rows">
            <div v-for="row in rows" :key="row.key" class="ex-row">
              <LanguageLocalePicker v-model="row.language_locale_code" :allow-create="false" :label="t('contribute.locale')" @selected="selectLocale(row, $event)" />
              <input class="ex-text" v-model="row.text" :placeholder="t('contribute.expressionPlaceholder')" :aria-label="t('contribute.expression')" />
              <button class="ex-del" :title="t('contribute.delete')" :aria-label="t('contribute.delete')" @click="removeRow(row.key)"><X :size="16" aria-hidden="true" /></button>
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

        <p v-if="nodeCount < 2" class="hint" role="status">{{ t('contribute.minRows') }}</p>

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
.contrib-page h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: 6px; }
.lead { font-size: 13px; color: var(--muted); line-height: 1.55; margin-bottom: var(--space-xl); max-width: 60ch; }
.lead b { color: var(--fg); font-weight: 500; }

.contrib-grid { display: grid; grid-template-columns: 1fr 260px; gap: var(--space-xl); align-items: start; }

.ex-table { border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); overflow: visible; }
.ex-head, .ex-row {
  display: grid; grid-template-columns: minmax(190px, 0.9fr) minmax(180px, 1.1fr) 40px; gap: var(--space-xs); align-items: start;
  padding: var(--space-xs) var(--space-sm);
}
.ex-head {
  border-bottom: 1px solid var(--border); background: var(--surface-2);
  border-radius: var(--r) var(--r) 0 0;
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted);
}
.ex-rows .ex-row { border-bottom: 1px solid var(--border); }
.ex-rows .ex-row:last-child { border-bottom: none; }
.ex-row :deep(.locale-picker) { gap: 0; min-width: 0; }
.ex-row :deep(.locale-picker > label),
.ex-row :deep(.locale-picker .create) { display: none; }
.ex-row :deep(.locale-picker input),
.ex-row :deep(.locale-picker .selected) {
  min-height: 44px;
  height: 44px;
  padding: 6px 10px;
  font-size: 13px;
}
.ex-row :deep(.locale-picker .selected button) {
  min-width: 44px;
  min-height: 44px;
  width: 44px;
  height: 44px;
}
.ex-row > input {
  height: 44px; border: 1px solid var(--border); border-radius: var(--r);
  background: var(--bg); padding: 0 var(--space-xs); font-size: 13px; outline: none; min-width: 0;
}
.ex-row input:focus { border-color: var(--accent); }
.ex-del {
  width: 40px; height: 40px; border: none; background: transparent; color: var(--muted);
  cursor: pointer; border-radius: var(--r); font-size: 13px; display: grid; place-items: center;
  align-self: center;
}
.ex-del:hover { color: var(--down); background: color-mix(in oklch, var(--down) 8%, var(--surface)); }
.ex-add {
  width: 100%; border: none; border-top: 1px dashed var(--border); background: transparent;
  border-radius: 0 0 var(--r) var(--r);
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
.hint { color: var(--muted); font-size: 13px; margin: 0 0 var(--space-sm); }
.error { color: var(--down); font-size: 13px; margin: 0 0 var(--space-sm); }

.contrib-right { position: sticky; top: 60px; }

@media (max-width: 760px) {
  .contrib-grid { grid-template-columns: 1fr; }
  .contrib-right { position: static; }
  .ex-head { display: none; }
  .ex-row { grid-template-columns: minmax(0, 1fr) 44px; gap: 8px; }
  .ex-row :deep(.locale-picker), .ex-row > input { grid-column: 1; }
  .ex-row :deep(.locale-picker > label) { display: block; margin-bottom: 4px; }
  .ex-del { grid-column: 2; grid-row: 1 / span 2; align-self: center; width: 44px; height: 44px; }
}
</style>
