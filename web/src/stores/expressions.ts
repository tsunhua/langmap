import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface Expression {
  id: number
  text: string
  language_code: string
  meaning_id?: number
  audio_url?: string
  created_by: string
  created_at: string
  updated_at?: string
  updated_by?: string
  meanings?: Array<{ id: number }>
}

export interface ExpressionFilters {
  language?: string
  meaningId?: number | number[]
  tagPrefix?: string
  excludeTagPrefix?: string
  includeMeanings?: boolean
  skip?: number
  limit?: number
}

export const useExpressionsStore = defineStore('expressions', () => {
  const expressions = ref<Map<number, Expression>>(new Map())
  const loading = ref(false)
  const error = ref<string | null>(null)
  const total = ref(0)

  const expressionsList = computed(() => Array.from(expressions.value.values()))

  function setExpressions(newExpressions: Expression[]) {
    const newMap = new Map<number, Expression>()
    newExpressions.forEach(expr => {
      newMap.set(expr.id, expr)
    })
    expressions.value = newMap
  }

  function addExpression(expression: Expression) {
    expressions.value.set(expression.id, expression)
  }

  function updateExpression(id: number, updates: Partial<Expression>) {
    const existing = expressions.value.get(id)
    if (existing) {
      expressions.value.set(id, { ...existing, ...updates })
    }
  }

  function removeExpression(id: number) {
    expressions.value.delete(id)
  }

  function getExpression(id: number): Expression | undefined {
    return expressions.value.get(id)
  }

  function clearExpressions() {
    expressions.value.clear()
    total.value = 0
  }

  function setLoading(value: boolean) {
    loading.value = value
  }

  function setError(value: string | null) {
    error.value = value
  }

  function setTotal(value: number) {
    total.value = value
  }

  return {
    expressions,
    expressionsList,
    loading,
    error,
    total,
    setExpressions,
    addExpression,
    updateExpression,
    removeExpression,
    getExpression,
    clearExpressions,
    setLoading,
    setError,
    setTotal
  }
})
