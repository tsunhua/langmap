import { z } from 'zod'

export const createExpressionSchema = z.object({
  text: z.string().min(1).max(1000),
  language_code: z.string().min(2).max(36),
  meaning_id: z.number().optional(),
  audio_url: z.string().optional()
})

export const updateExpressionSchema = z.object({
  text: z.string().min(1).max(1000).optional(),
  language_code: z.string().min(2).max(36).optional(),
  meaning_id: z.number().optional(),
  audio_url: z.string().optional()
})

export const batchExpressionSchema = z.object({
  expressions: z.array(z.object({
    text: z.string().min(1).max(1000),
    language_code: z.string().min(2).max(36),
    id: z.number().optional(),
    created_by: z.string().optional()
  })).min(1).max(50),
  ensure_new_meaning: z.boolean().optional()
})

export const ensureExpressionsSchema = z.object({
  expressions: z.array(z.object({
    text: z.string().min(1).max(1000),
    language_code: z.string().min(2).max(36),
    meaning_id: z.number().optional()
  })).min(1)
})

export const addMeaningSchema = z.object({
  meaning_id: z.number()
})

export const expressionsQuerySchema = z.object({
  skip: z.string().optional(),
  limit: z.string().optional(),
  language: z.string().optional(),
  meaning_id: z.string().optional(),
  tag: z.string().optional(),
  exclude_tag: z.string().optional(),
  include_meanings: z.string().optional()
})

export const searchQuerySchema = z.object({
  q: z.string().min(1),
  from_lang: z.string().optional(),
  region: z.string().optional(),
  skip: z.string().optional(),
  limit: z.string().optional(),
  include_meanings: z.string().optional()
})
