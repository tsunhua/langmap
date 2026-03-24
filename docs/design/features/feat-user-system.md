# 用戶與權限系統設計

## System Reminder

**設計來源**：本設計基於原始 `design_user.md` 和系統架構設計文檔

**實現狀態**：
- ✅ 用戶基礎認證（註冊、登錄、登出）- 已實現
- ✅ JWT 認證機制 - 已實現（Hono + jose）
- ✅ 用戶數據模型（users 表）- 已實現
- ⏳ 郵箱驗證功能 - 設計已定義，實現狀態需確認
- ⚠️ 用戶角色管理（更新角色、分配權限）- 部分實現（僅超級管理員角色定義）
- ❌ 修訂審核隊列 - 未實現（revisions 表未創建）
- ❌ 兩步驗證 - 未實現

**未實現或需確認的功能**：
- `POST /api/v1/users/:id/role` - 更新用戶角色（僅超級管理員）
- `PUT /api/v1/expressions/:id/revision/:revision_id/approve` - 審核內容修改
- `GET /api/v1/auth/verify-email` - 驗證郵箱
- `POST /api/v1/auth/resend-verification` - 重發驗證郵件

---

## 概述

本文檔描述了 LangMap 應用程序中用戶管理和權限控制系統的設計。該系統包含三種用戶角色：超級管理員、管理員和普通用戶，每種角色具有不同的權限級別。

## 用戶角色定義

### 1. 超級管理員 (Super Admin)
- 權限最高級別
- 可以批量刪除內容
- 可以管理所有用戶賬戶
- 可以分配其他用戶的管理員權限

### 2. 管理員 (Admin)
- 可以單條刪除任何內容（包括其他用戶提交的內容）
- 可以編輯內容
- 不能批量刪除內容

### 3. 普通用戶 (Regular User)
- 只能刪除自己提交的內容
- 可以創建新的詞條
- 可以編輯自己提交的內容
- 可以編輯他人提交的內容，但需要管理員審核後才能展示

## 數據庫設計

### users 表結構

```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user', -- 'super_admin', 'admin', 'user'
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### email_verification_tokens 表結構

```sql
CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### revisions 表結構（用於存儲待審核的內容修改）

```sql
CREATE TABLE revisions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    expression_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewer_id INTEGER,
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (reviewer_id) REFERENCES users(id)
);
```

## API 接口設計

### 用戶認證接口

#### POST /api/v1/auth/register

創建新用戶賬戶並發送郵箱驗證郵件。

**請求體：**
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

**響應：**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "integer",
      "username": "string",
      "email": "string",
      "role": "string"
    }
  }
}
```

#### POST /api/v1/auth/login

用戶登錄並獲取 JWT token。

**請求體：**
```json
{
  "email": "string",
  "password": "string"
}
```

**響應：**
```json
{
  "success": true,
  "data": {
    "token": "string",
    "user": {
      "id": "integer",
      "username": "string",
      "email": "string",
      "role": "string"
    }
  }
}
```

#### POST /api/v1/auth/logout

用戶登出。

**請求頭：** `Authorization: Bearer <token>`

**響應：**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### GET /api/v1/auth/verify-email

驗證郵箱並激活賬戶。

**查詢參數：** `?token=xxx`

**響應：**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

### 用戶管理接口

#### GET /api/v1/users/me

獲取當前用戶信息。

**請求頭：** `Authorization: Bearer <token>`

**響應：**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "username": "string",
    "email": "string",
    "role": "string",
    "email_verified": "boolean",
    "created_at": "timestamp"
  }
}
```

#### PUT /api/v1/users/{id}/role

更新用戶角色（僅超級管理員）。

**請求頭：** `Authorization: Bearer <token>`

**請求體：**
```json
{
  "role": "string" // 'super_admin', 'admin', 'user'
}
```

**響應：**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "username": "string",
    "email": "string",
    "role": "string"
  }
}
```

### 內容管理接口

#### DELETE /api/v1/expressions/{id}

刪除單個內容（管理員及以上）。

**請求頭：** `Authorization: Bearer <token>`

**響應：**
```json
{
  "success": true,
  "message": "Expression deleted successfully"
}
```

#### PUT /api/v1/expressions/{id}

編輯內容（所有用戶）。

**請求頭：** `Authorization: Bearer <token>`

**請求體：**
```json
{
  "field": "value"
}
```

**響應：**
```json
{
  "success": true,
  "data": {
    "id": "integer",
    "field": "value"
  }
}
```

#### POST /api/v1/expressions/{id}/revision

提交內容修改待審核（普通用戶編輯他人內容時）。

**請求頭：** `Authorization: Bearer <token>`

**請求體：**
```json
{
  "field": "new_value"
}
```

**響應：**
```json
{
  "success": true,
  "message": "Revision submitted for review"
}
```

#### PUT /api/v1/expressions/{id}/revision/{revision_id}/approve

審核內容修改（管理員及以上）。

**請求頭：** `Authorization: Bearer <token>`

**響應：**
```json
{
  "success": true,
  "message": "Revision approved and applied"
}
```

#### DELETE /api/v1/expressions/batch

批量刪除內容（僅超級管理員）。

**請求頭：** `Authorization: Bearer <token>`

**請求體：**
```json
{
  "ids": [1, 2, 3]
}
```

**響應：**
```json
{
  "success": true,
  "message": "Expressions deleted successfully"
}
```

## 前端實現要點

### 權限控制組件

根據不同用戶角色顯示不同的操作按鈕：

**普通用戶：**
- 只能看到刪除自己提交內容的選項
- 編輯他人內容時顯示"提交修改待審核"按鈕
- 無法看到批量刪除按鈕

**管理員：**
- 可以看到刪除任何內容的選項
- 可以看到審核待處理修改的界面
- 無法看到批量刪除按鈕

**超級管理員：**
- 可以看到所有刪除選項，包括批量刪除

### 登錄/註冊頁面

需要創建的 Vue 組件：
- `LoginPage.vue`
- `RegisterPage.vue`
- `UserProfile.vue`

## 郵箱驗證

### 驗證流程

1. 用戶註冊時，後端創建賬戶（`email_verified = false`）
2. 生成驗證 token 並保存到 `email_verification_tokens` 表
3. 調用郵件服務發送驗證鏈接
4. 用戶點擊驗證鏈接，後端驗證 token 並激活賬戶
5. 激活後刪除 token

### 安全考慮

- Token 一次性使用
- Token 設置過期時間（1小時）
- 未驗證郵箱的用戶禁止登錄和關鍵操作

## 安全考慮

1. 密碼加密存儲（使用 bcrypt 或其他安全哈希算法）
2. JWT Token 管理
3. 請求頻率限制防止暴力破解
4. 輸入驗證和清理防止 SQL 注入等攻擊
5. CORS 策略設置
6. HTTPS 強制使用
7. 郵箱驗證機制

## 實現步驟

1. 創建用戶相關的數據庫表
2. 實現用戶認證 API（註冊、登錄、登出）
3. 實現郵箱驗證功能
4. 實現 JWT 管理機制
5. 添加用戶角色檢查中間件
6. 修改現有內容刪除接口以支持權限控制
7. 實現內容修改和審核功能
8. 創建前端登錄/註冊頁面
9. 根據用戶角色動態顯示操作按鈕
10. 實現修訂提交和審核流程
11. 測試各種權限場景

## 後續擴展

1. 密碼重置功能
2. OAuth 第三方登錄（Google, GitHub等）
3. 用戶活動日誌記錄
4. 更細粒度的權限控制
5. 兩步驗證

---

## 相關文檔

- [UI 翻譯系統設計](./ui-translation.md)
- [系統架構設計](./system-architecture.md)
- [集合功能設計](./collection-feature.md)
