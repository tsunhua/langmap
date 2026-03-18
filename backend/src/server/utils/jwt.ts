import * as jose from 'jose'
import type { JWTPayload } from '../types/auth.js'

export async function signJWT(payload: jose.JWTPayload, secretKey: string): Promise<string> {
  const secret = new TextEncoder().encode(secretKey)
  const alg = 'HS256'

  const jwt = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg })
    .setIssuedAt()
    .setExpirationTime('24h')
    .sign(secret)

  return jwt
}

export async function verifyJWT(token: string, secretKey: string): Promise<JWTPayload | null> {
  try {
    const secret = new TextEncoder().encode(secretKey)
    const { payload } = await jose.jwtVerify(token, secret)
    return payload as JWTPayload
  } catch (error) {
    return null
  }
}
