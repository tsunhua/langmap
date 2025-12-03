# 用户与权限系统设计

## 概述

本文档描述了LangMap应用程序中用户管理和权限控制系统的实现方案。该系统将包含三种用户角色：超级管理员、管理员和普通用户，每种角色具有不同的权限级别。

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewer_id INTEGER,
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (reviewer_id) REFERENCES users(id)
);
```

## API 接口设计

### 用户认证接口

#### 1. 用户注册
```
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "string",
  "email": "string",
  "password": "string"
}

Response:
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

#### 2. 用户登录
```
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "string",
  "password": "string"
}

Response:
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

#### 3. 用户登出
```
POST /api/v1/auth/logout
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Logged out successfully"
}
```

### 用户管理接口

#### 1. 获取当前用户信息
```
GET /api/v1/users/me
Authorization: Bearer <token>

Response:
{
  "success": true,
  "data": {
    "id": "integer",
    "username": "string",
    "email": "string",
    "role": "string",
    "created_at": "timestamp"
  }
}
```

#### 2. 更新用户角色（仅超级管理员）
```
PUT /api/v1/users/{id}/role
Authorization: Bearer <token>
Content-Type: application/json

{
  "role": "string" // 'super_admin', 'admin', 'user'
}

Response:
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

#### 1. 删除单个内容（管理员及以上）
```
DELETE /api/v1/expressions/{id}
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Expression deleted successfully"
}
```

#### 2. 编辑内容（所有用户）
```
PUT /api/v1/expressions/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "field": "value"
}

Response:
{
  "success": true,
  "data": {
    "id": "integer",
    "field": "value"
  }
}
```

#### 3. 提交内容修改待审核（普通用户编辑他人内容时）
```
POST /api/v1/expressions/{id}/revision
Authorization: Bearer <token>
Content-Type: application/json

{
  "field": "new_value"
}

Response:
{
  "success": true,
  "message": "Revision submitted for review"
}
```

#### 4. 审核内容修改（管理员及以上）
```
PUT /api/v1/expressions/{id}/revision/{revision_id}/approve
Authorization: Bearer <token>

Response:
{
  "success": true,
  "message": "Revision approved and applied"
}
```

#### 5. 批量删除内容（仅超级管理员）
```
DELETE /api/v1/expressions/batch
Authorization: Bearer <token>
Content-Type: application/json

{
  "ids": [1, 2, 3]
}

Response:
{
  "success": true,
  "message": "Expressions deleted successfully"
}
```

## 前端实现要点

### 权限控制组件

根据不同用户角色显示不同的操作按钮：

1. 普通用户：
   - 只能看到删除自己提交内容的选项
   - 编辑他人内容时显示"提交修改待审核"按钮
   - 无法看到批量删除按钮

2. 管理员：
   - 可以看到删除任何内容的选项
   - 可以看到审核待处理修改的界面
   - 无法看到批量删除按钮

3. 超级管理员：
   - 可以看到所有删除选项，包括批量删除

### 登录/注册页面

需要创建新的Vue组件：
- LoginPage.vue
- RegisterPage.vue
- UserProfile.vue

## 安全考虑

1. 密码加密存储（使用bcrypt或其他安全哈希算法）
2. JWT Token 管理
3. 请求频率限制防止暴力破解
4. 输入验证和清理防止SQL注入等攻击
5. CORS策略设置
6. HTTPS强制使用

## 实现步骤

1. 创建用户相关的数据库表
2. 实现用户认证API（注册、登录、登出）
3. 实现JWT管理机制
4. 添加用户角色检查中间件
5. 修改现有内容删除接口以支持权限控制
6. 实现内容修改和审核功能
7. 创建前端登录/注册页面
8. 根据用户角色动态显示操作按钮
9. 实现修订提交和审核流程
10. 测试各种权限场景

## 后续扩展

1. 邮箱验证机制
2. 密码重置功能
3. OAuth第三方登录（Google, GitHub等）
4. 用户活动日志记录
5. 更细粒度的权限控制