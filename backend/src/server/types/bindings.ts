import { D1Database, DurableObjectNamespace, R2Bucket } from '@cloudflare/workers-types'

export interface Bindings {
  DB: D1Database;
  RESEND_API_KEY: string;
  SECRET_KEY: string;
  EXPORT_DO: DurableObjectNamespace;
  EXPORT_BUCKET: R2Bucket;
  AUDIO_BUCKET: R2Bucket;
  IMAGES_BUCKET: R2Bucket;
  R2_ACCOUNT_ID: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
}

export interface JWTPayload {
  id: number;
  username: string;
  role: string;
}

export default Bindings
