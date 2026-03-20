import { z } from 'zod'

const configSchema = z.object({
  api: z.object({
    version: z.string(),
    baseUrl: z.string().url()
  }),
  auth: z.object({
    jwtSecret: z.string().min(8),
    tokenExpiry: z.string(),
    resendApiKey: z.string().optional()
  }),
  storage: z.object({
    r2AccountId: z.string().optional(),
    r2AccessKeyId: z.string().optional(),
    r2SecretAccessKey: z.string().optional(),
    audioBucketName: z.string(),
    exportBucketName: z.string()
  }),
  cache: z.object({
    defaultTTL: z.number().int().positive(),
    statisticsTTL: z.number().int().positive(),
    languagesTTL: z.number().int().positive(),
    heatmapTTL: z.number().int().positive(),
    uiLocaleTTL: z.number().int().positive()
  }),
  limits: z.object({
    maxUploadSize: z.number().int().positive(),
    maxBatchSize: z.number().int().positive(),
    maxExpressionsPerBatch: z.number().int().positive()
  })
})

const rawConfig = {
  api: {
    version: 'v1',
    baseUrl: process.env.API_BASE_URL || 'http://localhost:8787'
  },
  
  auth: {
    jwtSecret: process.env.SECRET_KEY || 'your-secret-key-change-in-production',
    tokenExpiry: '24h',
    resendApiKey: process.env.RESEND_API_KEY
  },

  storage: {
    r2AccountId: process.env.R2_ACCOUNT_ID,
    r2AccessKeyId: process.env.R2_ACCESS_KEY_ID,
    r2SecretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    audioBucketName: 'langmap-audio',
    exportBucketName: 'langmap-exports'
  },

  cache: {
    defaultTTL: 3600,
    statisticsTTL: 1800,
    languagesTTL: 1800,
    heatmapTTL: 600,
    uiLocaleTTL: 3600
  },

  limits: {
    maxUploadSize: 1048576,
    maxBatchSize: 100,
    maxExpressionsPerBatch: 50
  }
}

// Validate config
const parsed = configSchema.safeParse(rawConfig)

if (!parsed.success) {
  console.error('❌ Invalid configuration:', JSON.stringify(parsed.error.format(), null, 2))
  throw new Error('Invalid configuration')
}

export const config = parsed.data
export default config

