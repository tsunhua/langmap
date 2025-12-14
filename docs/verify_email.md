一、整体架构（先有全局感）

用户
 └─ 注册（email + password）
      ↓
你的后端 API
  ├─ 创建用户（email_verified = false）
  ├─ 生成 email verification token
  ├─ 调用 Resend API 发邮件
      ↓
用户邮箱（Gmail / Outlook）
      ↓
点击验证链接
      ↓
你的后端 API
  ├─ 校验 token
  ├─ 激活账号（email_verified = true）


⸻

二、Cloudflare 侧配置（一次性）

1️⃣ 域名已在 Cloudflare（你已完成）

不需要开任何 Cloudflare 邮箱产品
只用 DNS 功能即可

⸻

2️⃣ 为 Resend 添加 DNS 记录

在 Resend 后台 → Domains → Add domain
它会给你 3～4 条 DNS 记录，在 Cloudflare 中添加：

示例（以 example.com 为例）

TXT   example.com              v=spf1 include:resend.com ~all
TXT   resend._domainkey        v=DKIM1; k=rsa; p=MIIBIjANBgkq...
TXT   _dmarc.example.com       v=DMARC1; p=none; rua=mailto:dmarc@example.com

注意
	•	Proxy 状态：DNS only（灰云）
	•	生效后，Resend 会显示 ✅ Verified

⸻

三、Resend 配置（10 分钟搞定）

1️⃣ 创建 API Key

Resend → API Keys → Create

RESEND_API_KEY=sk_xxxxxxxxx


⸻

2️⃣ 发信地址规划（很重要）

推荐：

no-reply@example.com   ← 系统发信
support@example.com   ← 联系邮箱（可 Cloudflare 转发到 Gmail）


⸻

四、数据库设计（通用）

users 表

添加   email_verified BOOLEAN DEFAULT FALSE,

email_verification_tokens 表

CREATE TABLE email_verification_tokens (
  token VARCHAR(128) PRIMARY KEY,
  user_id UUID NOT NULL,
  expires_at TIMESTAMP NOT NULL
);

设计原则
	•	token 一次性
	•	有过期时间
	•	不放明文密码、不复用 token

⸻

五、后端实现（Node.js 示例，逻辑通用）

即使你用 Java / Spring / Hono，逻辑完全一样

⸻

1️⃣ 用户注册 API

POST /api/register

核心逻辑

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
    INSERT INTO users (id, email, password_hash)
    VALUES ($1, $2, $3)
  `, [userId, email, passwordHash]);

  // 3. 生成 token
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 小时 (60分钟)

  await db.query(`
    INSERT INTO email_verification_tokens (token, user_id, expires_at)
    VALUES ($1, $2, $3)
  `, [token, userId, expiresAt]);

  // 4. 发送验证邮件
  const verifyUrl = `https://example.com/verify-email?token=${token}`;

  await resend.emails.send({
    from: 'no-reply@example.com',
    to: email,
    subject: '請確認你的電子郵件地址',
    html: `
      <p>你好，</p>
      <p>請點擊以下連結確認你的電子郵件地址：</p>
      <p><a href="${verifyUrl}">確認電子郵件</a></p>
      <p>此連結 1 小時內有效。</p>
    `
  });
}

⸻

9️⃣ 分阶段实施计划（TODO）

以下是要实施的任务清单，分为几个阶段：

Phase 1: 基础邮件验证功能 ✅
- [x] 在数据库中添加 email_verified 字段到 users 表
- [x] 创建 email_verification_tokens 表
- [x] 修改注册接口，在创建用户时生成验证令牌并发送邮件
- [x] 添加验证邮件模板
- [x] 实现验证令牌检查和用户激活的 API 端点
- [x] 修改登录接口，拒绝未验证邮箱的用户登录
- [x] 在前端添加注册成功后的提示信息

Phase 2: 用户体验改进 ✅
- [x] 添加邮箱验证成功/失败页面
- [x] 在登录页面添加未验证邮箱的提示信息
- [x] 优化邮件模板设计和内容

Phase 3: 安全增强
- [ ] 实现验证令牌的哈希存储（服务器只存储哈希值，验证时计算哈希比较）
- [ ] 添加验证链接一次性使用限制
- [ ] 实现过期令牌定期清理机制

Phase 4: 可选功能（暂不实现）
- [ ] 添加重新发送验证邮件功能
- [ ] 实现发送频率限制


⸻

2️⃣ 邮箱验证 API

GET /verify-email?token=xxx

核心逻辑

async function verifyEmail(token) {
  // 1. 查 token
  const row = await db.query(`
    SELECT user_id, expires_at
    FROM email_verification_tokens
    WHERE token = $1
  `, [token]);

  if (!row || row.expires_at < new Date()) {
    throw new Error('Token 無效或已過期');
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


⸻

六、前端配合（最简）

注册后提示

我們已向你的電子郵件發送了一封確認信，
請點擊郵件中的連結完成註冊。

验证成功页面

你的電子郵件已成功驗證，現在可以登入了。


⸻

七、安全 & 体验增强（强烈建议）

✅ 必做
	•	token 只用一次
	•	设置过期时间
	•	未验证邮箱：
	•	❌ 禁止登录
	•	❌ 禁止关键操作

⸻

⭐ 推荐增强
	•	重发验证邮件
	•	频率限制（防刷）
	•	token 存 hash（更安全）

hash = sha256(token)

⸻

八、在 LangMap 项目中的具体实现

基于项目当前的技术栈和架构，我们需要做以下调整：

1️⃣ 环境变量配置

在 Cloudflare Workers 中配置以下环境变量：
- RESEND_API_KEY：从 Resend 获取的 API 密钥
- EMAIL_VERIFY_EXPIRY_HOURS：验证链接过期时间（小时），设置为 1

2️⃣ 数据库表结构调整

需要修改现有的 users 表，添加 email_verified 字段：

ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;

创建 email_verification_tokens 表：

CREATE TABLE email_verification_tokens (
  token TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  expires_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

3️⃣ 后端 API 实现

需要修改或新增以下几个 API 端点：

POST /api/v1/auth/register
- 在现有注册逻辑基础上，添加邮箱验证流程
- 创建用户后生成验证令牌并发送验证邮件

GET /api/v1/auth/verify-email
- 新增端点用于验证邮箱
- 验证令牌有效性并激活账户

POST /api/v1/auth/resend-verification
- 新增端点用于重新发送验证邮件
- 限制发送频率，防止滥用

4️⃣ 登录验证

需要修改登录端点：
POST /api/v1/auth/login
- 添加检查用户邮箱是否已经验证
- 如果未验证，则拒绝登录请求

5️⃣ 邮件服务集成

在项目中集成 Resend 邮件服务：
- 添加 resend 包依赖
- 创建邮件发送服务封装
- 设计验证邮件模板

6️⃣ 前端改动

需要在前端做以下调整：
- 注册成功后显示提示信息，告知用户检查邮箱
- 添加邮箱验证成功/失败页面
- 在登录页面提示未验证邮箱的用户重新发送验证邮件
- 添加重新发送验证邮件的功能页面

7️⃣ 错误处理

需要考虑并处理以下异常情况：
- 验证链接过期
- 无效的验证令牌
- 邮件发送失败
- 用户重复请求验证邮件
- 已经验证过的邮箱再次尝试验证

8️⃣ 安全加固

- 对验证令牌进行哈希存储，提高安全性
- 实施频率限制，防止恶意请求
- 验证链接只能使用一次
- 过期令牌及时清理