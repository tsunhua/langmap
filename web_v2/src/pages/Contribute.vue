<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/api/client'
import CliquePreview from '@/components/mapping/CliquePreview.vue'

const router = useRouter()

interface Row {
  key: number
  lang: string
  text: string
  region: string
}

let keySeq = 0
const newRow = (): Row => ({ key: keySeq++, lang: '', text: '', region: '' })
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
    .map(r => ({ lang: r.lang.trim(), text: r.text.trim(), region: r.region.trim() || undefined }))
  if (payload.length < 2) {
    error.value = '需要至少 2 個含語言與詞句的列'
    return
  }
  submitting.value = true
  error.value = ''
  try {
    await api.post('/contributions/batch', { expressions: payload })
    router.push('/')
  } catch (e: any) {
    error.value = e.response?.data?.error || '提交失敗'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="contrib-page">
    <h1>批次貢獻</h1>
    <p class="lead">提交一組<b>表達同一件事</b>的詞句,系統會在兩兩之間建立直接映射(<b>完全圖</b>)。已存在的詞句會自動連結,不重複建立。</p>

    <div class="contrib-grid">
      <div class="contrib-left">
        <div class="ex-table">
          <div class="ex-head">
            <span>語言</span><span>詞句</span><span>地區</span><span></span>
          </div>
          <div class="ex-rows">
            <div v-for="row in rows" :key="row.key" class="ex-row">
              <input class="ex-lang" v-model="row.lang" placeholder="語言" aria-label="語言" />
              <input class="ex-text" v-model="row.text" placeholder="輸入詞句…" aria-label="詞句" />
              <input class="ex-region" v-model="row.region" placeholder="地區" aria-label="地區" />
              <button class="ex-del" title="刪除" aria-label="刪除列" @click="removeRow(row.key)">✕</button>
            </div>
          </div>
          <button class="ex-add" type="button" @click="addRow">＋ 添加詞句</button>
        </div>

        <div :class="['ex-counter', { warn: nodeCount < 2 }]">
          <span><b>{{ nodeCount }}</b> 個詞句</span>
          <span class="arrow">→</span>
          <span><b>{{ edgeCount }}</b> 條直接映射</span>
          <span class="tag">完全圖</span>
        </div>

        <p v-if="error" class="error" role="alert">{{ error }}</p>

        <div class="ex-actions">
          <button class="btn btn-primary" type="button" :disabled="nodeCount < 2 || submitting" @click="submit">
            {{ submitting ? '提交中…' : '提交' }}
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
  display: grid; grid-template-columns: 80px 1fr 140px 32px; gap: var(--space-xs); align-items: center;
  padding: var(--space-xs) var(--space-sm);
}
.ex-head {
  border-bottom: 1px solid var(--border); background: var(--surface-2);
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted);
}
.ex-rows .ex-row { border-bottom: 1px solid var(--border); }
.ex-rows .ex-row:last-child { border-bottom: none; }
.ex-row input {
  height: 32px; border: 1px solid var(--border); border-radius: var(--r);
  background: var(--bg); padding: 0 var(--space-xs); font-size: 13px; outline: none; min-width: 0;
}
.ex-row input:focus { border-color: var(--accent); }
.ex-row .ex-lang { font-family: var(--mono); font-size: 12px; }
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
  .ex-head, .ex-row { grid-template-columns: 64px 1fr 100px 28px; gap: 8px; }
}
</style>
