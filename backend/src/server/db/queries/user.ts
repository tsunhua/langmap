import { D1Database } from '@cloudflare/workers-types'
import { User } from '../protocol.js'

export class UserQueries {
  constructor(private db: D1Database) {}

  async findById(id: number): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE id = ?'
    ).bind(id).first<User>()
    return user || null
  }

  async findByUsername(username: string): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE username = ?'
    ).bind(username).first<User>()
    return user || null
  }

  async findByEmail(email: string): Promise<User | null> {
    const user = await this.db.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email).first<User>()
    return user || null
  }

  async create(id: number, data: Partial<User>): Promise<User> {
    const emailVerifiedInt = data.email_verified !== undefined
      ? (data.email_verified ? 1 : 0)
      : 0

    const bindValues = [
      id,
      data.username || null,
      data.email || null,
      data.password_hash || null,
      data.role || 'user',
      emailVerifiedInt
    ]

    const result = await this.db.prepare(
      `INSERT INTO users (
        id, username, email, password_hash, role, email_verified
      ) VALUES (?, ?, ?, ?, ?, ?) RETURNING *`
    ).bind(...bindValues).first<User>()

    if (!result) {
      throw new Error('Failed to create user')
    }

    return result
  }

  async update(id: number, data: Partial<User>): Promise<User> {
    const fields: string[] = []
    const values: any[] = []

    Object.entries(data).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at') {
        fields.push(`${key} = ?`)
        values.push(key === 'email_verified' ? (value ? 1 : 0) : value)
      }
    })

    values.push(id)

    const result = await this.db.prepare(
      `UPDATE users SET ${fields.join(', ')} WHERE id = ? RETURNING *`
    ).bind(...values).first<User>()

    if (!result) {
      throw new Error('Failed to update user')
    }

    return result
  }

  async createVerificationToken(token: string, userId: number, expiresAt: string): Promise<void> {
    const result = await this.db.prepare(
      'INSERT INTO email_verification_tokens (token, user_id, expires_at) VALUES (?, ?, ?)'
    ).bind(token, userId, expiresAt).run()

    if (!result.success) {
      throw new Error('Failed to create email verification token')
    }
  }

  async findVerificationToken(token: string): Promise<{ user_id: number, expires_at: string } | null> {
    return await this.db.prepare(
      'SELECT user_id, expires_at FROM email_verification_tokens WHERE token = ?'
    ).bind(token).first<{ user_id: number, expires_at: string }>() || null
  }

  async deleteVerificationToken(token: string): Promise<void> {
    await this.db.prepare(
      'DELETE FROM email_verification_tokens WHERE token = ?'
    ).bind(token).run()
  }

  async setEmailVerified(userId: number): Promise<void> {
    const result = await this.db.prepare(
      'UPDATE users SET email_verified = 1 WHERE id = ?'
    ).bind(userId).run()

    if (!result.success) {
      throw new Error('Failed to set email verified')
    }
  }
}
