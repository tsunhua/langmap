# 郵箱驗證實施指南

## 概述

本文檔描述如何在 LangMap 項目中實現郵箱驗證功能，使用 Resend 作爲郵件服務提供商。

## 整體架構

```
用戶
  └─ 註冊（email + password）
        ↓
  後端 API
  ├─ 創建用戶（email_verified = false）
  ├─ 生成 email verification token
  ├─ 調用 Resend API 發郵件
        ↓
  用戶郵箱（Gmail / Outlook）
        ↓
  點擊驗證鏈接
        ↓
  後端 API
  ├─ 校驗 token
  ├─ 激活賬號（email_verified = true）
```

## Cloudflare 側配置

### 1. 域名配置

域名已在 Cloudflare，不需要開任何 Cloudflare 郵箱產品，只用 DNS 功能即可。

### 2. 爲 Resend 添加 DNS 記錄

在 Resend 後臺 → Domains → Add domain，它會給你 3～4 條 DNS 記錄，在 Cloudflare 中添加：

示例（以 example.com 爲例）：

```
TXT   example.com              v=spf1 include:resend.com ~all
TXT   resend._domainkey        v=DKIM1; k=rsa; p=MIIBIjANBgkq...
TXT   _dmarc.example.com       v=DMARC1; p=none; rua=mailto:dmarc@example.com
```

**注意**：
- Proxy 狀態：DNS only（灰雲）
- 生效後，Resend 會顯示 ✅ Verified

## Resend 配置

### 1. 創建 API Key

Resend → API Keys → Create

```
RESEND_API_KEY=sk_xxxxxxxxx
```

### 2. 發信地址規劃

推薦：
```
no-reply@example.com   ← 系統發信
support@example.com   ← 聯繫郵箱（可 Cloudflare 轉發到 Gmail）
```

## 數據庫設計

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

**設計原則**：
- token 一次性
- 有過期時間
- 不放明文密碼、不復用 token

## 後端實現

### 用戶註冊 API

**POST /api/register**

```javascript
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

async function register(email, password) {
  // 1. hash 密碼
  const passwordHash = await bcrypt.hash(password, 12);

  // 2. 創建用戶
  const userId = crypto.randomUUID();
  await db.query(`
    INSERT INTO users (id, email, password_hash, email_verified)
    VALUES ($1, $2, $3, FALSE)
  `, [userId, email, passwordHash]);

  // 3. 生成 token
  const token = crypto.randomBytes(32).toString('hex');
  const expiresAt = new Date(Date.now() + 1000 * 60 * 60); // 1 小時

  await db.query(`
    INSERT INTO email_verification_tokens (token, user_id, expires_at)
    VALUES ($1, $2, $3)
  `, [token, userId, expiresAt]);

  // 4. 發送驗證郵件
  const verifyUrl = `https://example.com/verify-email?token=${token}`;

  await resend.emails.send({
    from: 'no-reply@example.com',
    to: email,
    subject: '請確認你的電子郵箱',
    html: `
      <p>你好，</p>
      <p>請點擊以下鏈接確認你的電子郵箱：</p>
      <p><a href="${verifyUrl}">確認電子郵箱</a></p>
      <p>此鏈接 1 小時內有效。</p>
    `
  });
}
```

### 郵箱驗證 API

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
    throw new Error('Token 無效或已過期');
  }

  // 2. 激活用戶
  await db.query(`
    UPDATE users
    SET email_verified = TRUE
    WHERE id = $1
  `, [row.user_id]);

  // 3. 刪除 token
  await db.query(`
    DELETE FROM email_verification_tokens
    WHERE token = $1
  `, [token]);
}
```

### 重發驗證郵件（可選）

**POST /api/v1/auth/resend-verification**

- 檢查用戶是否已驗證
- 如果未驗證，生成新 token 並發送郵件
- 添加頻率限制（如 5 分鐘內只能發送一次）

## 前端實現

### 註冊後提示

```
我們已向你的電子郵箱發送了一封確認信，
請點擊郵件中的鏈接完成註冊。
```

### 驗證成功頁面

```
你的電子郵箱已成功驗證，現在可以登錄了。
```

### 登錄頁面提示

對於未驗證郵箱的用戶：
```
你的郵箱尚未驗證。是否需要重發驗證郵件？
[重發驗證郵件] 按鈕
```

## 安全考慮

### 必做
- Token 只用一次
- 設置過期時間（1小時）
- 未驗證郵箱：
  - ❌ 禁止登錄
  - ❌ 禁止關鍵操作

### 推薦增強
- 重發驗證郵件
- 頻率限制（防刷）
- Token 存 hash（更安全）：
  ```
  hash = sha256(token)
  ```

## 環境變量

在 Cloudflare Workers 中配置：
- `RESEND_API_KEY`：從 Resend 獲取的 API 密鑰
- `EMAIL_VERIFY_EXPIRY_HOURS`：驗證鏈接過期時間（小時），設置爲 1
- `BASE_URL`：應用基礎 URL，用於生成驗證鏈接

## 錯誤處理

需要處理以下異常情況：
- 驗證鏈接過期
- 無效的驗證令牌
- 郵件發送失敗
- 用戶重複請求驗證郵件
- 已經驗證過的郵箱再次嘗試驗證

## 後續擴展

1. 郵箱模板化（HTML 模板）
2. 多語言支持（根據用戶語言發送不同語言的郵件）
3. 密碼重置功能
4. 郵件發送日誌記錄

---

## 相關文檔

- [用戶與權限系統設計](../design/user-system.md)
- [後端部署指南](../api/backend-guide.md)
