# 邮箱验证实施指南

## 概述

本文档描述如何在 LangMap 项目中实现邮箱验证功能，使用 Resend 作为邮件服务提供商。

## 整体架构

```
用户
  └─ 注册（email + password）
        ↓
  后端 API
  ├─ 创建用户（email_verified = false）
  ├─ 生成 email verification token
  ├─ 调用 Resend API 发邮件
        ↓
  用户邮箱（Gmail / Outlook）
        ↓
  点击验证链接
        ↓
  后端 API
  ├─ 校验 token
  ├─ 激活账号（email_verified = true）
```

## Cloudflare 侧配置

### 1. 域名配置

域名已在 Cloudflare，不需要开任何 Cloudflare 邮箱产品，只用 DNS 功能即可。

### 2. 为 Resend 添加 DNS 记录

在 Resend 后台 → Domains → Add domain，它会给你 3～4 条 DNS 记录，在 Cloudflare 中添加：

示例（以 example.com 为例）：

```
TXT   example.com              v=spf1 include:resend.com ~all
TXT   resend._domainkey        v=DKIM1; k=rsa; p=MIIBIjANBgkq...
TXT   _dmarc.example.com       v=DMARC1; p=none; rua=mailto:dmarc@example.com
```

**注意**：
- Proxy 状态：DNS only（灰云）
- 生效后，Resend 会显示 ✅ Verified

## Resend 配置

### 1. 创建 API Key

Resend → API Keys → Create

```
RESEND_API_KEY=sk_xxxxxxxxx
```

### 2. 发信地址规划

推荐：
```
no-reply@example.com   ← 系统发信
support@example.com   ← 联系邮箱（可 Cloudflare 转发到 Gmail）
```

## 数据库设计

### users 表

```sql
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
```

### email_verification_tokens 表

```sql
CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**设计原则**：
- token 一次性
- 有过期时间
- 不放明文密码、不复用 token

## 后端实现

### 用户注册 API

**POST /api/register**

```javascript
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

async function register(email, password) {
  // 1. hash 密码
  const passwordHash = await bcrypt.hash(password, 12);

  // 2. 创建用户
  const userId = crypto.randomUUID();
  await db.query(`
    INSERT INTO users (id, email, password_hash, email_verified)
    VALUES ($1, $2, $3, FALSE)
  `, [userId, email, passwordHash]);

  // 3. 生成 token
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 小时

  await db.query(`
    INSERT INTO email_verification_tokens (token, user_id, expires_at)
    VALUES ($1, $2, $3)
  `, [token, userId, expiresAt]);

  // 4. 发送验证邮件
  const verifyUrl = `https://example.com/verify-email?token=${token}`;

  await resend.emails.send({
    from: 'no-reply@example.com',
    to: email,
    subject: '请确认你的电子邮箱',
    html: `
      <p>你好，</p>
      <p>请点击以下链接确认你的电子邮箱：</p>
      <p><a href="${verifyUrl}">确认电子邮箱</a></p>
      <p>此链接 1 小时内有效。</p>
    `
  });
}
```

### 邮箱验证 API

**GET /verify-email?token=xxx**

```javascript
async function verifyEmail(token) {
  // 1. 查 token
  const row = await db.query(`
    SELECT user_id, expires_at
    FROM email_verification_tokens
    WHERE token = $1
  `, [token]);

  if (!row || row.expires_at < new Date()) {
    throw new Error('Token 无效或已过期');
  }

  // 2. 激活用户
  await db.query(`
    UPDATE users
    SET email_verified = TRUE
    WHERE id = $1
  `, [row.user_id]);

  // 3. 删除 token
  await db.query(`
    DELETE FROM email_verification_tokens
    WHERE token = $1
  `, [token]);
}
```

### 重发验证邮件（可选）

**POST /api/v1/auth/resend-verification**

- 检查用户是否已验证
- 如果未验证，生成新 token 并发送邮件
- 添加频率限制（如 5 分钟内只能发送一次）

## 前端实现

### 注册后提示

```
我们已向你的电子邮箱发送了一封确认信，
请点击邮件中的链接完成注册。
```

### 验证成功页面

```
你的电子邮箱已成功验证，现在可以登录了。
```

### 登录页面提示

对于未验证邮箱的用户：
```
你的邮箱尚未验证。是否需要重发验证邮件？
[重发验证邮件] 按钮
```

## 安全考虑

### 必做
- Token 只用一次
- 设置过期时间（1小时）
- 未验证邮箱：
  - ❌ 禁止登录
  - ❌ 禁止关键操作

### 推荐增强
- 重发验证邮件
- 频率限制（防刷）
- Token 存 hash（更安全）：
  ```
  hash = sha256(token)
  ```

## 环境变量

在 Cloudflare Workers 中配置：
- `RESEND_API_KEY`：从 Resend 获取的 API 密钥
- `EMAIL_VERIFY_EXPIRY_HOURS`：验证链接过期时间（小时），设置为 1
- `BASE_URL`：应用基础 URL，用于生成验证链接

## 错误处理

需要处理以下异常情况：
- 验证链接过期
- 无效的验证令牌
- 邮件发送失败
- 用户重复请求验证邮件
- 已经验证过的邮箱再次尝试验证

## 后续扩展

1. 邮箱模板化（HTML 模板）
2. 多语言支持（根据用户语言发送不同语言的邮件）
3. 密码重置功能
4. 邮件发送日志记录

---

## 相关文档

- [用户与权限系统设计](../design/user-system.md)
- [后端部署指南](../api/backend-guide.md)
