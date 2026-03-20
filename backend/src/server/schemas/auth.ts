import { z } from 'zod'

export const registerSchema = z.object({
  username: z.string().min(3).max(50),
  email: z.string().email(),
  password: z.string().min(8).max(100)
})

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
})

export const emailVerificationSchema = z.object({
  token: z.string().uuid()
})

export const verifyEmailQuerySchema = z.object({
  token: z.string().uuid()
})
