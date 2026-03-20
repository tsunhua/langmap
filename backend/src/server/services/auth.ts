import type { User } from '../types/auth.js'
import { hashPassword, comparePassword } from '../utils/password.js'
import { ConflictError, ValidationError } from '../types/error.js'
import { signJWT } from '../utils/jwt.js'

interface DBService {
  users: any
}

export class AuthService {
  constructor(private db: DBService) {}

  async register(username: string, email: string, password: string, resend: any, baseUrl: string) {
    if (!username || !email || !password) {
      throw new ValidationError('Username, email, and password are required')
    }

    const existingUser = await this.db.users.findByUsername(username)
    if (existingUser) {
      throw new ConflictError('Username already exists')
    }

    const existingEmail = await this.db.users.findByEmail(email)
    if (existingEmail) {
      throw new ConflictError('Email already registered')
    }

    const password_hash = await hashPassword(password)

    const user = await this.db.users.create(email, {
      username,
      email,
      password_hash,
      role: 'user',
      email_verified: 0
    })

    const token = crypto.randomUUID()
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString()

    await this.db.users.createVerificationToken(token, user.id, expiresAt)

    const verificationUrl = `${baseUrl}/#/verify-email?token=${token}`

    await resend.emails.send({
      from: 'no-reply@langmap.io',
      to: email,
      subject: 'Verify your email address',
      html: `
        <p>Hello ${username},</p>
        <p>Thank you for registering with LangMap! To ensure your account security, please click button below to verify your email address.</p>
        <p><a href="${verificationUrl}" style="background-color: #2563eb; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Verify Email</a></p>
        <p>If you cannot click button, please copy following link and open it in your browser:</p>
        <p>${verificationUrl}</p>
        <p><strong>Note:</strong> This verification link will expire in 1 hour. Please verify your email as soon as possible.</p>
        <p>If you didn't register for a LangMap account, please ignore this email.</p>
        <p>&copy; 2025 LangMap. All rights reserved.</p>
      `
    })

    return { user, token }
  }

  async login(email: string, password: string, secretKey: string) {
    if (!email || !password) {
      throw new ValidationError('Email and password are required')
    }

    const user = await this.db.users.findByEmail(email)
    if (!user) {
      throw new ValidationError('Invalid credentials')
    }

    if (user.email_verified !== 1) {
      throw new ValidationError('Please verify your email before logging in')
    }

    const isValidPassword = await comparePassword(password, user.password_hash)
    if (!isValidPassword) {
      throw new ValidationError('Invalid credentials')
    }

    const token = await signJWT({
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role
    }, secretKey)

    const { password_hash: _, ...userResponse } = user
    return { token, user: userResponse }
  }

  async verifyEmail(token: string) {
    if (!token) {
      throw new ValidationError('Verification token is required')
    }

    const verificationToken = await this.db.users.findVerificationToken(token)
    if (!verificationToken) {
      throw new ValidationError('Invalid or expired verification token')
    }

    const now = new Date()
    const expiresAt = new Date(verificationToken.expires_at)
    if (now > expiresAt) {
      await this.db.users.deleteVerificationToken(token)
      throw new ValidationError('Verification token has expired')
    }

    await this.db.users.setEmailVerified(verificationToken.user_id)
    await this.db.users.deleteVerificationToken(token)
  }
}
