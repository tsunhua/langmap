<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import api from '@/api/client'
import ExpressionPicker from '@/components/expression/ExpressionPicker.vue'
import CliquePreview from '@/components/mapping/CliquePreview.vue'

const router = useRouter()

interface Expr {
  id: number
  text: string
  language_code: string
  region?: string
}

const expressions = ref<Expr[]>([])
const submitting = ref(false)
const error = ref('')

const edgeCount = computed(() => {
  const n = expressions.value.length
  return n * (n - 1) / 2
})

function addExpression(expr: { id: number; text: string; language_code: string }) {
  if (!expressions.value.find(e => e.id === expr.id)) {
    expressions.value.push({ ...expr })
  }
}

function removeExpression(id: number) {
  expressions.value = expressions.value.filter(e => e.id !== id)
}

async function submit() {
  if (expressions.value.length < 2) return
  submitting.value = true
  error.value = ''
  try {
    await api.post('/contributions/batch', {
      expressions: expressions.value.map(e => ({
        lang: e.language_code,
        text: e.text,
        region: e.region,
      })),
    })
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
    <p class="lead">新增多個詞句，系統自動建立所有配對映射</p>

    <div class="contrib-grid">
      <div class="contrib-left">
        <ExpressionPicker @select="addExpression" />

        <div v-if="expressions.length" class="ex-table">
          <div v-for="(expr, i) in expressions" :key="expr.id" class="ex-row">
            <span class="ex-num">{{ i + 1 }}</span>
            <span class="ex-text">{{ expr.text }}</span>
            <span class="lang-badge">{{ expr.language_code }}</span>
            <button class="btn btn-icon btn-ghost" @click="removeExpression(expr.id)">✕</button>
          </div>
        </div>

        <div class="ex-counter">
          {{ expressions.length }} 個詞句 → {{ edgeCount }} 條直接映射 · 完全圖
        </div>

        <p v-if="error" class="error">{{ error }}</p>

        <div class="ex-actions">
          <button
            class="btn btn-primary"
            :disabled="expressions.length < 2 || submitting"
            @click="submit"
          >
            {{ submitting ? '提交中…' : '提交映射' }}
          </button>
        </div>
      </div>

      <div class="contrib-right">
        <CliquePreview :expressions="expressions" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.contrib-page { max-width: 900px; margin: 0 auto; }
.lead { color: #4A6FA5; margin: 8px 0 20px; }
.contrib-grid { display: grid; grid-template-columns: 1fr 260px; gap: 20px; }
.contrib-left { display: flex; flex-direction: column; gap: 16px; }
.contrib-right { position: sticky; top: 60px; align-self: start; }
.ex-table { background: #fff; border-radius: 4px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }
.ex-row { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid #EDE5D8; }
.ex-num { font-family: "IBM Plex Mono", monospace; font-size: 12px; color: #4A6FA5; width: 24px; }
.ex-text { flex: 1; font-size: 14px; }
.ex-counter { font-family: "IBM Plex Mono", monospace; font-size: 13px; color: #4A6FA5; }
.ex-actions { display: flex; gap: 8px; }
.error { color: #A03030; font-size: 13px; }
@media (max-width: 700px) {
  .contrib-grid { grid-template-columns: 1fr; }
  .contrib-right { position: static; }
}
</style>
