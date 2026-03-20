import type { User } from '../types/auth.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  users: any
}

export class UserService {
  constructor(private db: DBService) {}

  async getById(id: number): Promise<User> {
    const user = await this.db.users.findById(id)
    if (!user) {
      throw new NotFoundError('User')
    }
    const { password_hash: _, ...userResponse } = user
    return userResponse as User
  }

  async getByUsername(username: string): Promise<User | null> {
    return this.db.users.findByUsername(username)
  }

  async getByEmail(email: string): Promise<User | null> {
    return this.db.users.findByEmail(email)
  }

  async update(id: number, data: any): Promise<User> {
    const user = await this.db.users.update(id, data)
    if (!user) {
      throw new NotFoundError('User')
    }
    const { password_hash: _, ...userResponse } = user
    return userResponse as User
  }
}
