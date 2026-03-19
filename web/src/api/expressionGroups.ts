import apiClient from './client.js'
import type { ExpressionGroup } from '../types/models.js'

export interface CreateGroupData {
  anchor_expression_id: number
}

export interface MergeGroupsData {
  source_group_id: number
}

export interface AddToGroupData {
  expression_id: number
}

export interface ApiResponse<T = any> {
  data: T
  message?: string
}

export const expressionGroupsApi = {
  async getGroup(id: number, languages?: string[]): Promise<ApiResponse<ExpressionGroup>> {
    const params = languages ? { lang: languages.join(',') } : {}
    const response = await apiClient.get(`/groups/${id}`, { params })
    return response.data as ApiResponse<ExpressionGroup>
  },

  async listGroups(
    skip: number = 0,
    limit: number = 20,
    languages?: string[]
  ): Promise<ApiResponse<{ items: ExpressionGroup[], total: number }>> {
    const params: any = { skip, limit }
    if (languages) {
      params.lang = languages.join(',')
    }
    const response = await apiClient.get('/groups', { params })
    return response.data as ApiResponse<{ items: ExpressionGroup[], total: number }>
  },

  async searchGroups(
    query: string,
    skip: number = 0,
    limit: number = 20,
    languages?: string[]
  ): Promise<ApiResponse<ExpressionGroup[]>> {
    const params: any = { q: query, skip, limit }
    if (languages) {
      params.lang = languages.join(',')
    }
    const response = await apiClient.get('/groups/search', { params })
    return response.data as ApiResponse<ExpressionGroup[]>
  },

  async createGroup(data: CreateGroupData): Promise<ApiResponse<ExpressionGroup>> {
    const response = await apiClient.post('/groups', data)
    return response.data as ApiResponse<ExpressionGroup>
  },

  async addToGroup(groupId: number, data: AddToGroupData): Promise<ApiResponse<null>> {
    const response = await apiClient.post(`/groups/${groupId}/expressions`, data)
    return response.data as ApiResponse<null>
  },

  async removeFromGroup(groupId: number, expressionId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}/expressions/${expressionId}`)
    return response.data as ApiResponse<null>
  },

  async mergeGroups(targetGroupId: number, data: MergeGroupsData): Promise<ApiResponse<any>> {
    const response = await apiClient.post(`/groups/${targetGroupId}/merge`, data)
    return response.data as ApiResponse<any>
  },

  async deleteGroup(groupId: number): Promise<ApiResponse<null>> {
    const response = await apiClient.delete(`/groups/${groupId}`)
    return response.data as ApiResponse<null>
  },

  async getExpressionGroups(expressionId: number): Promise<ApiResponse<ExpressionGroup[]>> {
    const response = await apiClient.get(`/expressions/${expressionId}/groups`)
    return response.data as ApiResponse<ExpressionGroup[]>
  },

  async linkExpressions(expressionIds: number[]): Promise<ApiResponse<{ group_id: number; updated_count: number }>> {
    const response = await apiClient.post('/expressions/associate', { expression_ids: expressionIds })
    return response.data as ApiResponse<{ group_id: number; updated_count: number }>
  }
}
