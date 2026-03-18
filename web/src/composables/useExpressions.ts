import { ref } from 'vue'
import { useExpressionsStore } from '../stores/expressions.js'
import { expressionsApi } from '../api/expressions.js'
import type { ExpressionFilters } from '../stores/expressions.js'

export function useExpressions() {
  const expressionsStore = useExpressionsStore()
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchAll(filters: ExpressionFilters = {}) {
    loading.value = true
    error.value = null

    try {
      const expressions = await expressionsApi.getAll(filters)
      expressionsStore.setExpressions(expressions)
      return { success: true, data: expressions }
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch expressions'
      expressionsStore.setError(err.message)
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  async function fetchById(id: number) {
    loading.value = true
    error.value = null

    try {
      const expression = await expressionsApi.getById(id)
      expressionsStore.addExpression(expression)
      return { success: true, data: expression }
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch expression'
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  async function create(data: any) {
    loading.value = true
    error.value = null

    try {
      const expression = await expressionsApi.create(data)
      expressionsStore.addExpression(expression)
      return { success: true, data: expression }
    } catch (err: any) {
      error.value = err.message || 'Failed to create expression'
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  async function update(id: number, data: any) {
    loading.value = true
    error.value = null

    try {
      const expression = await expressionsApi.update(id, data)
      expressionsStore.updateExpression(id, expression)
      return { success: true, data: expression }
    } catch (err: any) {
      error.value = err.message || 'Failed to update expression'
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  async function remove(id: number) {
    loading.value = true
    error.value = null

    try {
      await expressionsApi.delete(id)
      expressionsStore.removeExpression(id)
      return { success: true }
    } catch (err: any) {
      error.value = err.message || 'Failed to delete expression'
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  async function search(query: string, filters: any = {}) {
    loading.value = true
    error.value = null

    try {
      const results = await expressionsApi.search(query, filters)
      return { success: true, data: results }
    } catch (err: any) {
      error.value = err.message || 'Search failed'
      return { success: false, error: err.message }
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    error,
    expressions: expressionsStore.expressionsList,
    fetchAll,
    fetchById,
    create,
    update,
    remove,
    search
  }
}
