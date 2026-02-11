# 用户与权限系统设计

## 概述

本文档描述了 LangMap 应用程序中用户管理和权限控制系统的实现方案。该系统包含三种用户角色：超级管理员、管理员和普通用户，每种角色具有不同的权限级别。

## 用户角色定义

### 1. 超级管理员 (Super Admin)
- 权限最高级别
- 可以批量删除内容
- 可以管理所有用户账户
- 可以分配其他用户的管理员权限

### 2. 管理员 (Admin)
- 可以单条删除任何内容（包括其他用户提交的内容）
- 可以编辑内容
- 不能批量删除内容

### 3. 普通用户 (Regular User)
- 只能删除自己提交的内容
- 可以创建新的词条
- 可以编辑自己提交的内容
- 可以编辑他人提交的内容，但需要管理员审核后才能展示

## 数据库设计

### users 表结构

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

### email_verification_tokens 表结构

```sql
CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### revisions 表结构（用于存储待审核的内容修改）

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

## API 接口设计

### 用户认证接口

#### POST /api/v1/auth/register

创建新用户账户并发送邮箱验证邮件。

**请求体：**
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

**响应：**
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

用户登录并获取 JWT token。

**请求体：**
```json
{
  "email": "string",
  "password": "string"
}
```

**响应：**
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

用户登出。

**请求头：** `Authorization: Bearer <token>`

**响应：**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

#### GET /api/v1/auth/verify-email

验证邮箱并激活账户。

**查询参数：** `?token=xxx`

**响应：**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

### 用户管理接口

#### GET /api/v1/users/me

获取当前用户信息。

**请求头：** `Authorization: Bearer <token>`

**响应：**
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

更新用户角色（仅超级管理员）。

**请求头：** `Authorization: Bearer <token>`

**请求体：**
```json
{
  "role": "string" // 'super_admin', 'admin', 'user'
}
```

**响应：**
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

### 内容管理接口

#### DELETE /api/v1/expressions/{id}

删除单个内容（管理员及以上）。

**请求头：** `Authorization: Bearer <token>`

**响应：**
```json
{
  "success": true,
  "message": "Expression deleted successfully"
}
```

#### PUT /api/v1/expressions/{id}

编辑内容（所有用户）。

**请求头：** `Authorization: Bearer <token>`

**请求体：**
```json
{
  "field": "value"
}
```

**响应：**
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

提交内容修改待审核（普通用户编辑他人内容时）。

**请求头：** `Authorization: Bearer <token>`

**请求体：**
```json
{
  "field": "new_value"
}
```

**响应：**
```json
{
  "success": true,
  "message": "Revision submitted for review"
}
```

#### PUT /api/v1/expressions/{id}/revision/{revision_id}/approve

审核内容修改（管理员及以上）。

**请求头：** `Authorization: Bearer <token>`

**响应：**
```json
{
  "success": true,
  "message": "Revision approved and applied"
}
```

#### DELETE /api/v1/expressions/batch

批量删除内容（仅超级管理员）。

**请求头：** `Authorization: Bearer <token>`

**请求体：**
```json
{
  "ids": [1, 2, 3]
}
```

**响应：**
```json
{
  "success": true,
  "message": "Expressions deleted successfully"
}
```

## 前端实现要点

### 权限控制组件

根据不同用户角色显示不同的操作按钮：

**普通用户：**
- 只能看到删除自己提交内容的选项
- 编辑他人内容时显示"提交修改待审核"按钮
- 无法看到批量删除按钮

**管理员：**
- 可以看到删除任何内容的选项
- 可以看到审核待处理修改的界面
- 无法看到批量删除按钮

**超级管理员：**
- 可以看到所有删除选项，包括批量删除

### 登录/注册页面

需要创建的 Vue 组件：
- `LoginPage.vue`
- `RegisterPage.vue`
- `UserProfile.vue`

## 邮箱验证

### 验证流程

1. 用户注册时，后端创建账户（`email_verified = false`）
2. 生成验证 token 并保存到 `email_verification_tokens` 表
3. 调用邮件服务发送验证链接
4. 用户点击验证链接，后端验证 token 并激活账户
5. 激活后删除 token

### 安全考虑

- Token 一次性使用
- Token 设置过期时间（1小时）
- 未验证邮箱的用户禁止登录和关键操作

## 安全考虑

1. 密码加密存储（使用 bcrypt 或其他安全哈希算法）
2. JWT Token 管理
3. 请求频率限制防止暴力破解
4. 输入验证和清理防止 SQL 注入等攻击
5. CORS 策略设置
6. HTTPS 强制使用
7. 邮箱验证机制

## 实现步骤

1. 创建用户相关的数据库表
2. 实现用户认证 API（注册、登录、登出）
3. 实现邮箱验证功能
4. 实现 JWT 管理机制
5. 添加用户角色检查中间件
6. 修改现有内容删除接口以支持权限控制
7. 实现内容修改和审核功能
8. 创建前端登录/注册页面
9. 根据用户角色动态显示操作按钮
10. 实现修订提交和审核流程
11. 测试各种权限场景

## 后续扩展

1. 密码重置功能
2. OAuth 第三方登录（Google, GitHub等）
3. 用户活动日志记录
4. 更细粒度的权限控制
5. 两步验证

---

## 相关文档

- [UI 翻译系统设计](./ui-translation.md)
- [系统架构设计](./system-architecture.md)
- [集合功能设计](./collection-feature.md)
