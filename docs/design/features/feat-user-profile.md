# 用戶資料/個人中心設計

## System Reminder

**實現狀態**：
- ✅ 前端用戶資料頁面已實現 - `UserProfile.vue`
- ⏳ 後端用戶資料 API - 部分實現（`GET /api/v1/users/me` 已實現）
- ⏳ 用戶資料更新 API - 未實現（頭像、簡介等）
- ⏳ 用戶設置功能 - 未實現
- ⏳ 用戶活動記錄 - 未實現

**已實現的 API 端點**：
- `GET /api/v1/users/me` - 獲取當前用戶信息

**已實現的功能**：
- 基礎用戶信息展示
- 用戶基本信息（用戶名、郵箱）

**未實現的功能**：
- 用戶頭像上傳和管理
- 用戶簡介編輯
- 用戶偏好設置
- 用戶密碼修改
- 用戶活動記錄
- 用戶貢獻統計

---

## 概述

用戶資料/個人中心功能是用戶管理個人信息和查看個人活動的核心功能。用戶可以在個人中心編輯個人信息、查看貢獻記錄、管理賬戶設置等。

## 數據模型

### User 表（現有）

```typescript
interface User {
  id: number
  username: string
  email: string
  password_hash: string
  role: string              // 'user', 'admin', 'super_admin'
  email_verified?: number   // 0: 未驗證, 1: 已驗證
  created_at?: string
  updated_at?: string
}
```

### 擴展字段（建議新增）

爲了支持更豐富的用戶資料功能，建議擴展 User 表：

```sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN display_name TEXT;
ALTER TABLE users ADD COLUMN website_url TEXT;
ALTER TABLE users ADD COLUMN location TEXT;
ALTER TABLE users ADD COLUMN language_preference TEXT DEFAULT 'en-US';
ALTER TABLE users ADD COLUMN theme_preference TEXT DEFAULT 'light';
```

**新增字段說明**：
- `avatar_url` - 用戶頭像 URL
- `bio` - 用戶簡介
- `display_name` - 顯示名稱（可選，與 username 區分）
- `website_url` - 個人網站
- `location` - 所在地
- `language_preference` - 語言偏好
- `theme_preference` - 主題偏好（light/dark）

## API 設計

### 已實現的端點

#### GET /api/v1/users/me

獲取當前用戶的信息。

**認證**：需要

**響應**：
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

### 未實現的端點（建議新增）

#### PUT /api/v1/users/me

更新當前用戶的信息。

**認證**：需要

**請求體**：
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

**響應**：
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

上傳用戶頭像。

**認證**：需要

**請求**：multipart/form-data

**請求體**：
```
avatar: [binary image file]
```

**響應**：
```json
{
  "avatar_url": "https://example.com/avatars/user_1_avatar.jpg"
}
```

#### GET /api/v1/users/me/stats

獲取當前用戶的統計信息。

**認證**：需要

**響應**：
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

獲取當前用戶的活動記錄。

**認證**：需要

**查詢參數**：
- `skip` (number) - 跳過數量（默認 0）
- `limit` (number) - 返回數量限制（默認 20）

**響應**：
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

修改用戶密碼。

**認證**：需要

**請求體**：
```json
{
  "current_password": "old_password",
  "new_password": "new_password"
}
```

**響應**：
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

## 前端實現

### UserProfile.vue 頁面

主要功能：
1. 展示用戶基本信息
2. 編輯用戶資料
3. 上傳頭像
4. 修改密碼
5. 查看活動記錄
6. 查看貢獻統計

**頁面布局**：

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

**實現示例**：

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

## 安全考慮

### 頭像上傳

1. **文件驗證**：驗證文件類型（只允許圖片）
2. **文件大小限制**：限制文件大小（如 5MB）
3. **文件名隨機化**：避免文件名衝突和目錄遍歷攻擊
4. **存儲隔離**：用戶頭像存儲在獨立目錄
5. **URL 驗證**：驗證外部 URL（如果允許外部頭像）

### 密碼修改

1. **當前密碼驗證**：修改前必須提供當前密碼
2. **新密碼強度要求**：密碼長度、複雜度要求
3. **密碼加密**：使用 bcrypt 加密存儲
4. **會話更新**：密碼修改後重新登錄

## 用戶體驗優化

### 實時預覽

- **頭像預覽**：上傳前預覽頭像
- **資料預覽**：編輯時實時預覽資料卡片

### 表單驗證

- **客戶端驗證**：即時顯示錯誤提示
- **服務器端驗證**：最終驗證並返回詳細錯誤

### 加載狀態

- **加載指示器**：保存時顯示加載狀態
- **成功/失敗提示**：操作完成後顯示結果

## 測試策略

### 單元測試
- 測試用戶資料更新邏輯
- 測試頭像上傳邏輯
- 測試密碼修改邏輯

### 集成測試
- 測試用戶資料 API 端點
- 測試頭像上傳 API 端點
- 測試統計 API 端點
- 測試活動記錄 API 端點

### 前端測試
- 測試用戶資料頁面組件
- 測試表單提交
- 測試頭像上傳
- 測試分頁加載活動記錄

## 相關文檔

- [用戶與權限系統設計](./feat-user-system.md)
- [郵箱驗證實施指南](../../guides/email-verification.md)
- [系統架構設計](../system/architecture.md)
