# 用户资料/个人中心设计

## System Reminder

**实现状态**：
- ✅ 前端用户资料页面已实现 - `UserProfile.vue`
- ⏳ 后端用户资料 API - 部分实现（`GET /api/v1/users/me` 已实现）
- ⏳ 用户资料更新 API - 未实现（头像、简介等）
- ⏳ 用户设置功能 - 未实现
- ⏳ 用户活动记录 - 未实现

**已实现的 API 端点**：
- `GET /api/v1/users/me` - 获取当前用户信息

**已实现的功能**：
- 基础用户信息展示
- 用户基本信息（用户名、邮箱）

**未实现的功能**：
- 用户头像上传和管理
- 用户简介编辑
- 用户偏好设置
- 用户密码修改
- 用户活动记录
- 用户贡献统计

---

## 概述

用户资料/个人中心功能是用户管理个人信息和查看个人活动的核心功能。用户可以在个人中心编辑个人信息、查看贡献记录、管理账户设置等。

## 数据模型

### User 表（现有）

```typescript
interface User {
  id: number
  username: string
  email: string
  password_hash: string
  role: string              // 'user', 'admin', 'super_admin'
  email_verified?: number   // 0: 未验证, 1: 已验证
  created_at?: string
  updated_at?: string
}
```

### 扩展字段（建议新增）

为了支持更丰富的用户资料功能，建议扩展 User 表：

```sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN display_name TEXT;
ALTER TABLE users ADD COLUMN website_url TEXT;
ALTER TABLE users ADD COLUMN location TEXT;
ALTER TABLE users ADD COLUMN language_preference TEXT DEFAULT 'en-US';
ALTER TABLE users ADD COLUMN theme_preference TEXT DEFAULT 'light';
```

**新增字段说明**：
- `avatar_url` - 用户头像 URL
- `bio` - 用户简介
- `display_name` - 显示名称（可选，与 username 区分）
- `website_url` - 个人网站
- `location` - 所在地
- `language_preference` - 语言偏好
- `theme_preference` - 主题偏好（light/dark）

## API 设计

### 已实现的端点

#### GET /api/v1/users/me

获取当前用户的信息。

**认证**：需要

**响应**：
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "user",
  "email_verified": 1,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-15T00:00:00Z"
}
```

### 未实现的端点（建议新增）

#### PUT /api/v1/users/me

更新当前用户的信息。

**认证**：需要

**请求体**：
```json
{
  "avatar_url": "https://example.com/avatar.jpg",
  "bio": "I love languages",
  "display_name": "John Doe",
  "website_url": "https://johndoe.com",
  "location": "New York, USA",
  "language_preference": "en-US",
  "theme_preference": "dark"
}
```

**响应**：
```json
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "avatar_url": "https://example.com/avatar.jpg",
  "bio": "I love languages",
  "display_name": "John Doe",
  "website_url": "https://johndoe.com",
  "location": "New York, USA",
  "language_preference": "en-US",
  "theme_preference": "dark",
  "updated_at": "2024-01-20T00:00:00Z"
}
```

#### POST /api/v1/users/avatar

上传用户头像。

**认证**：需要

**请求**：multipart/form-data

**请求体**：
```
avatar: [binary image file]
```

**响应**：
```json
{
  "avatar_url": "https://example.com/avatars/user_1_avatar.jpg"
}
```

#### GET /api/v1/users/me/stats

获取当前用户的统计信息。

**认证**：需要

**响应**：
```json
{
  "total_expressions": 42,
  "total_collections": 5,
  "total_votes": 128,
  "total_meanings": 15,
  "joined_date": "2024-01-01T00:00:00Z"
}
```

#### GET /api/v1/users/me/activity

获取当前用户的活动记录。

**认证**：需要

**查询参数**：
- `skip` (number) - 跳过数量（默认 0）
- `limit` (number) - 返回数量限制（默认 20）

**响应**：
```json
{
  "activities": [
    {
      "type": "expression_created",
      "data": {
        "expression_id": 123,
        "text": "Hello"
      },
      "created_at": "2024-01-20T10:30:00Z"
    },
    {
      "type": "collection_created",
      "data": {
        "collection_id": 5,
        "name": "My Favorites"
      },
      "created_at": "2024-01-19T15:45:00Z"
    }
  ],
  "total": 47,
  "skip": 0,
  "limit": 20
}
```

#### POST /api/v1/users/me/change-password

修改用户密码。

**认证**：需要

**请求体**：
```json
{
  "current_password": "old_password",
  "new_password": "new_password"
}
```

**响应**：
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

## 前端实现

### UserProfile.vue 页面

主要功能：
1. 展示用户基本信息
2. 编辑用户资料
3. 上传头像
4. 修改密码
5. 查看活动记录
6. 查看贡献统计

**页面布局**：

```
┌─────────────────────────────────────────┐
│  User Profile                        │
├─────────────────────────────────────────┤
│  Avatar Upload                       │
│  [Avatar Image] [Upload Button]       │
├─────────────────────────────────────────┤
│  Basic Information                   │
│  Username: [Field]                  │
│  Display Name: [Field]               │
│  Email: [Field] (read-only)         │
│  Location: [Field]                  │
│  Website: [Field]                   │
│  Bio: [Textarea]                    │
│  [Save Changes]                      │
├─────────────────────────────────────────┤
│  Account Settings                    │
│  Language: [Dropdown]               │
│  Theme: [Light/Dark]               │
│  [Save Settings]                     │
├─────────────────────────────────────────┤
│  Change Password                     │
│  Current Password: [Password]         │
│  New Password: [Password]            │
│  Confirm Password: [Password]         │
│  [Change Password]                   │
├─────────────────────────────────────────┤
│  Statistics                         │
│  Expressions: 42                    │
│  Collections: 5                      │
│  Votes: 128                         │
│  Meanings: 15                       │
├─────────────────────────────────────────┤
│  Activity Log                       │
│  [Activity List]                     │
│  [Load More]                        │
└─────────────────────────────────────────┘
```

**实现示例**：

```vue
<template>
  <div class="user-profile">
    <h1>My Profile</h1>
    
    <div class="section">
      <h2>Avatar</h2>
      <div class="avatar-section">
        <img :src="user.avatar_url || defaultAvatar" alt="Avatar" />
        <input type="file" @change="handleAvatarUpload" accept="image/*" />
      </div>
    </div>
    
    <div class="section">
      <h2>Basic Information</h2>
      <form @submit.prevent="handleSaveProfile">
        <div class="form-group">
          <label>Username</label>
          <input v-model="profile.username" readonly />
        </div>
        <div class="form-group">
          <label>Display Name</label>
          <input v-model="profile.display_name" />
        </div>
        <div class="form-group">
          <label>Email</label>
          <input v-model="profile.email" readonly />
        </div>
        <div class="form-group">
          <label>Location</label>
          <input v-model="profile.location" />
        </div>
        <div class="form-group">
          <label>Website</label>
          <input v-model="profile.website_url" />
        </div>
        <div class="form-group">
          <label>Bio</label>
          <textarea v-model="profile.bio"></textarea>
        </div>
        <button type="submit">Save Changes</button>
      </form>
    </div>
    
    <div class="section">
      <h2>Account Settings</h2>
      <form @submit.prevent="handleSaveSettings">
        <div class="form-group">
          <label>Language</label>
          <select v-model="settings.language_preference">
            <option value="en-US">English</option>
            <option value="zh-CN">中文</option>
          </select>
        </div>
        <div class="form-group">
          <label>Theme</label>
          <select v-model="settings.theme_preference">
            <option value="light">Light</option>
            <option value="dark">Dark</option>
          </select>
        </div>
        <button type="submit">Save Settings</button>
      </form>
    </div>
    
    <div class="section">
      <h2>Statistics</h2>
      <div class="stats">
        <div>Expressions: {{ stats.total_expressions }}</div>
        <div>Collections: {{ stats.total_collections }}</div>
        <div>Votes: {{ stats.total_votes }}</div>
        <div>Meanings: {{ stats.total_meanings }}</div>
      </div>
    </div>
    
    <div class="section">
      <h2>Activity Log</h2>
      <div class="activities">
        <div v-for="activity in activities" :key="activity.created_at" class="activity">
          <span class="type">{{ activity.type }}</span>
          <span class="date">{{ formatDate(activity.created_at) }}</span>
        </div>
      </div>
      <button @click="loadMoreActivities" :disabled="!hasMore">Load More</button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      user: {},
      profile: {},
      settings: {},
      stats: {},
      activities: [],
      defaultAvatar: '/default-avatar.png',
      hasMore: false
    }
  },
  async mounted() {
    await this.loadUserData()
    await this.loadUserStats()
    await this.loadUserActivity()
  },
  methods: {
    async loadUserData() {
      const response = await fetch('/api/v1/users/me', {
        headers: { 'Authorization': `Bearer ${this.getToken()}` }
      })
      this.user = await response.json()
      this.profile = { ...this.user }
    },
    async loadUserStats() {
      const response = await fetch('/api/v1/users/me/stats', {
        headers: { 'Authorization': `Bearer ${this.getToken()}` }
      })
      this.stats = await response.json()
    },
    async loadUserActivity() {
      const response = await fetch('/api/v1/users/me/activity', {
        headers: { 'Authorization': `Bearer ${this.getToken()}` }
      })
      const json = await response.json()
      this.activities = json.activities
      this.hasMore = json.activities.length >= 20
    },
    async handleAvatarUpload(event) {
      const file = event.target.files[0]
      const formData = new FormData()
      formData.append('avatar', file)
      
      const response = await fetch('/api/v1/users/avatar', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${this.getToken()}` },
        body: formData
      })
      const result = await response.json()
      this.user.avatar_url = result.avatar_url
    },
    async handleSaveProfile() {
      const response = await fetch('/api/v1/users/me', {
        method: 'PUT',
        headers: { 
          'Authorization': `Bearer ${this.getToken()}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.profile)
      })
      this.user = await response.json()
      alert('Profile saved successfully')
    },
    async handleSaveSettings() {
      const response = await fetch('/api/v1/users/me', {
        method: 'PUT',
        headers: { 
          'Authorization': `Bearer ${this.getToken()}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.settings)
      })
      alert('Settings saved successfully')
    },
    formatDate(date) {
      return new Date(date).toLocaleString()
    }
  }
}
</script>
```

## 安全考虑

### 头像上传

1. **文件验证**：验证文件类型（只允许图片）
2. **文件大小限制**：限制文件大小（如 5MB）
3. **文件名随机化**：避免文件名冲突和目录遍历攻击
4. **存储隔离**：用户头像存储在独立目录
5. **URL 验证**：验证外部 URL（如果允许外部头像）

### 密码修改

1. **当前密码验证**：修改前必须提供当前密码
2. **新密码强度要求**：密码长度、复杂度要求
3. **密码加密**：使用 bcrypt 加密存储
4. **会话更新**：密码修改后重新登录

## 用户体验优化

### 实时预览

- **头像预览**：上传前预览头像
- **资料预览**：编辑时实时预览资料卡片

### 表单验证

- **客户端验证**：即时显示错误提示
- **服务器端验证**：最终验证并返回详细错误

### 加载状态

- **加载指示器**：保存时显示加载状态
- **成功/失败提示**：操作完成后显示结果

## 测试策略

### 单元测试
- 测试用户资料更新逻辑
- 测试头像上传逻辑
- 测试密码修改逻辑

### 集成测试
- 测试用户资料 API 端点
- 测试头像上传 API 端点
- 测试统计 API 端点
- 测试活动记录 API 端点

### 前端测试
- 测试用户资料页面组件
- 测试表单提交
- 测试头像上传
- 测试分页加载活动记录

## 相关文档

- [用户与权限系统设计](./feat-user-system.md)
- [邮箱验证实施指南](../../guides/email-verification.md)
- [系统架构设计](../system/architecture.md)
