import type { User } from '../types/auth.js'
import { NotFoundError } from '../types/error.js'

interface DBService {
  getUserById(id: number): Promise<User | null>
  getUserByUsername(username: string): Promise<User | null>
  getUserByEmail(email: string): Promise<User | null>
  updateUser(id: number, data: any): Promise<User | null>
}

export class UserService {
  constructor(private db: DBService) {}

  async getById(id: number): Promise<User> {
    const user = await this.db.getUserById(id)
    if (!user) {
      throw new NotFoundError('User')
    }
    const { password_hash: _, ...userResponse } = user
    return userResponse as User
  }

  async getByUsername(username: string): Promise<User | null> {
    return this.db.getUserByUsername(username)
  }

  async getByEmail(email: string): Promise<User | null> {
    return this.db.getUserByEmail(email)
  }

  async update(id: number, data: any): Promise<User> {
    const user = await this.db.updateUser(id, data)
    if (!user) {
      throw new NotFoundError('User')
    }
    const { password_hash: _, ...userResponse } = user
    return userResponse as User
  }
}
