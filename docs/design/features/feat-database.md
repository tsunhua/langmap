# 数据库设计

## System Reminder

**实现状态**：
- ✅ Cloudflare D1 数据库已部署
- ✅ 核心表结构已实现
- ✅ 基础索引已创建
- ⏳ 数据库迁移脚本未完善
- ⏳ 数据备份策略未实现
- ❌ 数据库性能监控未实现
- ❌ 读写分离未实现

**已实现的数据库表**：
- `languages` - 语言表
- `expressions` - 表达式主表
- `expression_versions` - 版本历史表
- `meanings` - 语义表
- `expression_meanings` - 表达式-语义关联表
- `users` - 用户表
- `collections` - 集合表
- `collection_items` - 集合项目表
- `email_verification_tokens` - 邮箱验证令牌表

**未实现的功能**：
- 数据库迁移管理工具
- 自动备份机制
- 数据库性能监控
- 读写分离（如需要）
- 分库分表策略

---

## 概述

LangMap 项目使用 Cloudflare D1 作为主数据库，这是一个兼容 SQLite 的边缘数据库。D1 提供了低延迟的全球分布式访问，非常适合需要快速响应的 Web 应用程序。

### 数据库选择理由

- **Cloudflare D1**：与 Cloudflare Workers 无缝集成，边缘部署
- **SQLite 兼容**：熟悉的 SQL 语法，易于开发和测试
- **低延迟**：全球分布式访问，就近响应
- **Serverless**：无需管理数据库服务器
- **成本效益**：按使用量计费，适合小到中型应用

### 数据库特性

- **ACID 事务**：支持事务，保证数据一致性
- **关系型**：支持复杂的关系查询和联表
- **边缘部署**：数据分布在多个边缘节点
- **自动扩展**：无需手动扩展数据库容量
- **读取一致性**：提供最终一致性保证

## 数据库架构

### 表关系图

```
users (用户表)
  ↓ 1:N
collections (集合表)
  ↓ 1:N
collection_items (集合项目表)
  ↓ N:1
expressions (表达式主表)
  ↓ 1:N
expression_versions (版本历史表)

languages (语言表)
  ↓ 1:N
expressions (表达式主表)

meanings (语义表)
  ↓ M:N (通过 expression_meanings)
expressions (表达式主表)

email_verification_tokens (邮箱验证令牌表)
  ↓ N:1
users (用户表)
```

## 表结构详情

### 1. languages 表

存储支持的语言及其地域信息。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,              -- BCP-47 语言代码 (如 "en-US", "zh-CN")
    name TEXT NOT NULL,                        -- 语言英文名称
    native_name TEXT,                         -- 语言本地化名称
    direction TEXT DEFAULT 'ltr',              -- 文本方向: "ltr" 或 "rtl"
    is_active INTEGER DEFAULT 0,              -- 是否激活: 0=否, 1=是
    region_code TEXT,                          -- 地区代码 (如 "US", "CN")
    region_name TEXT,                          -- 地区名称 (如 "New York", "Beijing")
    region_latitude TEXT,                       -- 地区纬度
    region_longitude TEXT,                      -- 地区经度
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**索引**：

```sql
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_is_active ON languages(is_active);
CREATE INDEX idx_languages_region ON languages(region_code);
```

**字段说明**：
- `id` - 主键，使用语言代码的哈希值
- `code` - 唯一键，BCP-47 标准语言代码
- `is_active` - 标识语言是否可用，只有激活的语言在前端显示
- `region_*` - 支持语言的地域化信息，用于地图可视化

### 2. expressions 表

存储语言表达式的当前版本。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,                         -- 表达式文本
    meaning_id INTEGER,                          -- 关联的语义 ID
    audio_url TEXT,                             -- 音频 URL
    language_code TEXT NOT NULL,                 -- 语言代码
    region_code TEXT,                            -- 地区代码
    region_name TEXT,                            -- 地区名称
    region_latitude TEXT,                         -- 地区纬度
    region_longitude TEXT,                        -- 地区经度
    tags TEXT,                                  -- JSON 数组，用于标签分类
    source_type TEXT DEFAULT 'user',              -- 来源类型: "authoritative", "ai", "user"
    source_ref TEXT,                             -- 来源引用 (书名、URL 等)
    review_status TEXT DEFAULT 'pending',          -- 审核状态: "pending", "approved", "rejected"
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expressions_language ON expressions(language_code);
CREATE INDEX idx_expressions_meaning ON expressions(meaning_id);
CREATE INDEX idx_expressions_review_status ON expressions(review_status);
CREATE INDEX idx_expressions_created_at ON expressions(created_at);
CREATE INDEX idx_expressions_source_type ON expressions(source_type);
```

**字段说明**：
- `meaning_id` - 关联到语义表，支持跨语言的语义链接
- `tags` - JSON 格式存储标签，例如 `["home", "title"]`
- `source_type` - 标识内容来源，AI 生成的内容可能自动审核通过
- `review_status` - 用户提交的内容需要审核
- `region_*` - 地域化信息，支持精细的地理定位

### 3. expression_versions 表

存储表达式的所有历史版本，支持版本回滚。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,               -- 关联的表达式 ID
    text TEXT NOT NULL,                         -- 版本文本
    meaning_id INTEGER,                          -- 语义 ID
    audio_url TEXT,                             -- 音频 URL
    region_name TEXT,                            -- 地区名称
    region_latitude TEXT,                         -- 地区纬度
    region_longitude TEXT,                        -- 地区经度
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expression_versions_expr_id ON expression_versions(expression_id);
CREATE INDEX idx_expression_versions_created_at ON expression_versions(created_at);
```

**字段说明**：
- `expression_id` - 指向当前表达式主表记录
- 不包含 `parent_version_id` - 当前实现中版本链未显式存储
- 不包含 `source_type`, `review_status` - 这些字段只在主表中维护

### 4. meanings 表

存储表达式的语义信息。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    gloss TEXT NOT NULL,                         -- 简短标签 (如 "langmap.home.title")
    description TEXT,                            -- 详细描述
    tags TEXT,                                  -- JSON 数组，用于分类
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**索引**：

```sql
CREATE INDEX idx_meanings_gloss ON meanings(gloss);
CREATE INDEX idx_meanings_tags ON meanings(tags);
```

**字段说明**：
- `gloss` - 唯一的短标签，用作语义标识符
- `tags` - JSON 格式，例如 `["langmap", "ui"]` 用于区分 UI 翻译

### 5. expression_meanings 表

表达式与语义的多对多关联表。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS expression_meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,                -- 表达式 ID
    meaning_id INTEGER NOT NULL,                  -- 语义 ID
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    note TEXT,                                   -- 关联备注
    parent_version_id INTEGER,                     -- 未使用的字段
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expression_meanings_expr_id ON expression_meanings(expression_id);
CREATE INDEX idx_expression_meanings_meaning_id ON expression_meanings(meaning_id);
```

**字段说明**：
- `parent_version_id` - 当前版本未使用，保留作为未来扩展
- `note` - 可选的关联说明

### 6. users 表

存储用户账户信息。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY NOT NULL,
    username TEXT UNIQUE NOT NULL,                 -- 用户名
    email TEXT UNIQUE NOT NULL,                    -- 邮箱
    password_hash TEXT NOT NULL,                   -- 密码哈希 (bcrypt)
    role TEXT DEFAULT 'user',                      -- 角色: "user", "admin", "super_admin"
    email_verified INTEGER DEFAULT 0,              -- 邮箱验证: 0=未验证, 1=已验证
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

**索引**：

```sql
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**字段说明**：
- `role` - 定义用户权限级别
- `email_verified` - 阻止未验证邮箱的用户登录

### 7. email_verification_tokens 表

存储邮箱验证令牌。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token TEXT PRIMARY KEY NOT NULL,                -- 验证令牌
    user_id INTEGER NOT NULL,                      -- 用户 ID
    expires_at TEXT NOT NULL,                      -- 过期时间
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**索引**：

```sql
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);
```

**字段说明**：
- `token` - 唯一标识，一次性使用
- `expires_at` - 令牌有效期，通常设置为 1 小时

### 8. collections 表

存储用户的收藏集合。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,                      -- 创建者 ID
    name TEXT NOT NULL,                            -- 集合名称
    description TEXT,                               -- 集合描述
    is_public INTEGER DEFAULT 0,                    -- 是否公开: 0=私有, 1=公开
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**索引**：

```sql
CREATE INDEX idx_collections_user_id ON collections(user_id);
CREATE INDEX idx_collections_is_public ON collections(is_public);
CREATE INDEX idx_collections_created_at ON collections(created_at);
```

**字段说明**：
- `is_public` - 标识集合是否对其他用户可见

### 9. collection_items 表

存储集合与表达式的关联。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,                 -- 集合 ID
    expression_id INTEGER NOT NULL,                  -- 表达式 ID
    note TEXT,                                    -- 备注
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id),
    FOREIGN KEY (collection_id) REFERENCES collections(id),
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX idx_collection_items_expression_id ON collection_items(expression_id);
```

**字段说明**：
- `UNIQUE(collection_id, expression_id)` - 保证同一表达式在同一集合中只出现一次
- `note` - 可选的添加说明

## 索引设计

### 索引策略

1. **主键索引**：所有表都有 `INTEGER PRIMARY KEY`
2. **唯一索引**：用于保证数据唯一性
3. **外键索引**：所有外键字段都创建索引
4. **查询索引**：为常用查询条件创建索引

### 索引性能考虑

- **避免过度索引**：索引会增加写入开销
- **复合索引**：根据查询模式选择
- **定期分析**：监控索引使用情况

### 未来优化

- **全文索引**：为 `expressions.text` 创建 FTS 索引
- **JSON 索引**：优化 `tags` 字段的查询
- **地理索引**：如果支持，为地理位置创建索引

## 数据迁移

### 迁移策略

1. **版本化迁移**：每个迁移文件编号（001, 002, 003...）
2. **幂等性**：迁移脚本可重复执行
3. **回滚支持**：提供降级脚本

### 迁移示例

```sql
-- Migration 001: Add region fields to expressions
ALTER TABLE expressions 
ADD COLUMN region_name TEXT,
ADD COLUMN region_latitude TEXT,
ADD COLUMN region_longitude TEXT;

-- Migration 002: Add email verification support
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token TEXT PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Migration 003: Add tags column to expressions
ALTER TABLE expressions ADD COLUMN tags TEXT;
```

### 未来改进

- **迁移框架**：自动化迁移管理
- **迁移日志**：记录迁移历史
- **数据校验**：迁移后验证数据完整性

## 性能优化

### 查询优化

1. **使用索引**：确保查询使用索引
2. **避免 SELECT *** **：只选择需要的字段
3. **限制结果集**：使用 `LIMIT` 分页
4. **批量操作**：减少数据库往返

### 事务管理

```sql
BEGIN TRANSACTION;
-- 多个相关操作
COMMIT;
```

### 连接池

- D1 自动管理连接
- 无需手动配置连接池
- 边缘节点自动路由

## 备份策略

### 当前状态

- ❌ 自动备份未实现
- ❌ 定期备份未实现
- ⏳ 手动导出可用（通过 Wrangler CLI）

### 建议策略

1. **定期备份**：每日自动备份数据库
2. **增量备份**：只备份变更数据
3. **多地域备份**：备份到多个存储位置
4. **备份验证**：定期验证备份的完整性

### 备份命令

```bash
# 导出数据库
wrangler d1 export DB_NAME backup.sql

# 导入数据库
wrangler d1 execute DB_NAME --file=backup.sql
```

## 数据安全

### 访问控制

- **环境变量**：数据库凭证存储在 Cloudflare Workers 环境变量中
- **最小权限**：应用只访问必要的表和字段
- **API 鉴权**：JWT 认证保护敏感操作

### 数据加密

- **传输加密**：HTTPS 加密所有数据库通信
- **静态加密**：敏感字段（如密码）使用 bcrypt 哈希
- **密钥管理**：使用 Cloudflare Secrets 管理敏感密钥

### 数据脱敏

- **日志脱敏**：日志中不记录敏感信息
- **API 响应**：不返回完整敏感数据
- **错误消息**：避免泄露数据库结构

## 监控与维护

### 性能监控

- **查询时间**：监控慢查询
- **连接数**：监控并发连接
- **错误率**：监控数据库错误

### 维护任务

- **索引重建**：定期重建索引
- **数据清理**：删除过期数据
- **统计更新**：更新缓存数据

### 未来改进

- **仪表盘**：实时监控数据库性能
- **自动告警**：异常情况自动通知
- **自优化**：自动调整数据库配置

## 相关文档

- [系统架构设计](../system/architecture.md)
- [后端 API 指南](../../api/backend-guide.md)
- [用户与权限系统](./feat-user-system.md)
- [UI 翻译系统](./feat-ui-translation.md)
