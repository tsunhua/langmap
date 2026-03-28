import { z } from 'zod'

export const createExpressionSchema = z.object({
  text: z.string().min(1).max(1000),
  language_code: z.string().min(2).max(36),
  meaning_id: z.number().optional(),
  desc: z.string().max(1000).nullable().optional(),
  audio_url: z.string().nullable().optional(),
  region_code: z.string().nullable().optional(),
  region_name: z.string().nullable().optional(),
  region_latitude: z.number().nullable().optional(),
  region_longitude: z.number().nullable().optional(),
  created_by: z.string().optional()
}).superRefine((data, ctx) => {
  if (data.language_code === 'image') {
    if (!data.text.startsWith('http://') && !data.text.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Image URL must start with http:// or https://',
        path: ['text']
      })
    }

    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Only system-generated image URLs are allowed',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Invalid image URL format',
        path: ['text']
      })
    }
  }
})

export const updateExpressionSchema = z.object({
  text: z.string().min(1).max(1000).optional(),
  language_code: z.string().min(2).max(36).optional(),
  meaning_id: z.number().optional(),
  desc: z.string().max(1000).nullable().optional(),
  audio_url: z.string().nullable().optional(),
  region_code: z.string().nullable().optional(),
  region_name: z.string().nullable().optional(),
  region_latitude: z.number().nullable().optional(),
  region_longitude: z.number().nullable().optional(),
  updated_by: z.string().optional()
}).superRefine((data, ctx) => {
  if (data.language_code === 'image' && data.text) {
    if (!data.text.startsWith('http://') && !data.text.startsWith('https://')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Image URL must start with http:// or https://',
        path: ['text']
      })
    }

    try {
      const url = new URL(data.text)
      if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Only system-generated image URLs are allowed',
          path: ['text']
        })
      }
    } catch {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Invalid image URL format',
        path: ['text']
      })
    }
  }
})

export const batchExpressionSchema = z.object({
  expressions: z.array(z.object({
    text: z.string().min(1).max(1000),
    language_code: z.string().min(2).max(36),
    id: z.number().optional(),
    meaning_id: z.number().optional(),
    created_by: z.string().optional(),
    audio_url: z.string().nullable().optional(),
    region_code: z.string().nullable().optional(),
    region_name: z.string().nullable().optional(),
    region_latitude: z.number().nullable().optional(),
    region_longitude: z.number().nullable().optional(),
    desc: z.string().nullable().optional()
  })).min(1).max(50),
  ensure_new_group: z.boolean().optional()
}).superRefine((data, ctx) => {
  data.expressions.forEach((expr, index) => {
    if (expr.language_code === 'image') {
      if (!expr.text.startsWith('http://') && !expr.text.startsWith('https://')) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Image URL must start with http:// or https://',
          path: ['expressions', index, 'text']
        })
      }

      try {
        const url = new URL(expr.text)
        if (!url.hostname.endsWith('.langmap.io') && !url.hostname.includes('r2.cloudflarestorage.com')) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: 'Only system-generated image URLs are allowed',
            path: ['expressions', index, 'text']
          })
        }
      } catch {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: 'Invalid image URL format',
          path: ['expressions', index, 'text']
        })
      }
    }
  })
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
