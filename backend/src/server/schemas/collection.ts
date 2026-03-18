import { z } from 'zod'

export const createCollectionSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(500).optional(),
  is_public: z.number().int().min(0).max(1).default(0)
})

export const updateCollectionSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  description: z.string().max(500).optional(),
  is_public: z.number().int().min(0).max(1).optional()
})

export const collectionsQuerySchema = z.object({
  user_id: z.string().optional(),
  is_public: z.string().optional(),
  skip: z.string().optional(),
  limit: z.string().optional()
})

export const checkItemQuerySchema = z.object({
  expression_id: z.string()
})
