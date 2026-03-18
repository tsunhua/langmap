import { z } from 'zod'

export const createLanguageSchema = z.object({
  code: z.string().min(2).max(36),
  name: z.string().min(1).max(100),
  native_name: z.string().max(100).optional(),
  is_active: z.number().int().min(0).max(1).default(1),
  created_by: z.string().optional()
})

export const updateLanguageSchema = z.object({
  code: z.string().min(2).max(36).optional(),
  name: z.string().min(1).max(100).optional(),
  native_name: z.string().max(100).optional(),
  is_active: z.number().int().min(0).max(1).optional(),
  updated_by: z.string().optional()
})

export const languagesQuerySchema = z.object({
  is_active: z.string().optional()
})
