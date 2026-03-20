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
      const result = await expressionsApi.getAll(filters)
      if (result.success && result.data) {
        const expressions = result.data
        expressionsStore.setExpressions(expressions)
        return { success: true, data: expressions }
      } else {
        return { success: false, error: result.error || result.message || 'Failed to fetch expressions' }
      }
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
      const result = await expressionsApi.getById(id)
      if (result.success && result.data) {
        const expression = result.data
        expressionsStore.addExpression(expression)
        return { success: true, data: expression }
      } else {
        return { success: false, error: result.error || result.message || 'Failed to fetch expression' }
      }
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
      const result = await expressionsApi.create(data)
      if (result.success && result.data) {
        const expression = result.data
        expressionsStore.addExpression(expression)
        return { success: true, data: expression }
      } else {
        return { success: false, error: result.error || result.message || 'Failed to create expression' }
      }
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
      const result = await expressionsApi.update(id, data)
      if (result.success && result.data) {
        const expression = result.data
        expressionsStore.updateExpression(id, expression)
        return { success: true, data: expression }
      } else {
        return { success: false, error: result.error || result.message || 'Failed to update expression' }
      }
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
      const result = await expressionsApi.search(query, filters)
      if (result.success && result.data) {
        const results = result.data
        return { success: true, data: results }
      } else {
        return { success: false, error: result.error || result.message || 'Search failed' }
      }
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
