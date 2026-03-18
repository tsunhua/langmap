export const config = {
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

export default config
