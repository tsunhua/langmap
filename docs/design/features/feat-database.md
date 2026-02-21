# 数据库设计

## System Reminder

**实现状态**：
- ✅ Cloudflare D1 数据库已部署
- ✅ 核心表结构已实现
- ✅ 复合优化索引已部署 (013_optimization_indexes.sql)
- ✅ 多级缓存机制已实施 (L1 Memory + L2 Edge Cache)
- ✅ 反范式化统计已实施 (items_count & language_stats)
- ✅ 数据库迁移脚本已规范化
- ⏳ 数据备份策略待自动化
- ✅ 数据库性能监控初步实现 (Edge Log)

**已实现的数据库表**：
- `languages` - 语言表
- `expressions` - 表达式主表
- `expression_versions` - 版本历史表
- `users` - 用户表
- `collections` - 集合表 (含 `items_count` 冗余字段)
- `collection_items` - 集合项目表
- `email_verification_tokens` - 邮箱验证令牌表
- `language_stats` - 语言词数统计表 (物化统计)

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
languages (语言表)
  ↓ 1:N
expressions (表达式主表)
  ↓ 1:N
expression_versions (版本历史表)

languages (语言表)
  ↔ 1:1
language_stats (物化统计表)

users (用户表)
  ↓ 1:N
collections (集合表)
  ↓ 1:N
collection_items (集合项目表)
  ↓ N:1
expressions (表达式主表)
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
CREATE INDEX idx_languages_active_name ON languages(is_active, name); -- 优化常用语言列表
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
    FOREIGN KEY (meaning_id) REFERENCES expressions(id)
);
```

**索引**：

```sql
CREATE INDEX idx_expressions_language_code ON expressions(language_code);
CREATE INDEX idx_expressions_meaning_id ON expressions(meaning_id);
CREATE INDEX idx_expressions_text ON expressions(text);
-- 复合索引：优化针对特定语言的分页列表
CREATE INDEX idx_expressions_lang_meaning_created ON expressions(language_code, meaning_id, created_at DESC);
-- 复合索引：优化同步与去重检查
CREATE INDEX idx_expressions_lang_text ON expressions(language_code, text);
```

**字段说明**：
- `id` - 主键，基于 `text + language_code` 计算的确定性哈希值，确保相同内容的词句具有唯一且稳定的 ID。
- `meaning_id` - 语义锚点 ID（指向 expressions.id），用于将不同语言的同义词句分到同一组。同一组的词句共享相同的 `meaning_id`，通常该 ID 取自该组中第一个被创建或最主要的表达记录。
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
- `meaning_id` - 记录快照时的语义关联
- 不包含 `source_type`, `review_status` - 这些字段只在主表中维护


### 5. users 表

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
    items_count INTEGER DEFAULT 0,                 -- 反范式化字段：集合项目总数
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**索引**：

```sql
CREATE INDEX idx_collections_user_id ON collections(user_id);
CREATE INDEX idx_collections_name ON collections(name);
-- 复合索引：优化公共/个人列表的分页排序
CREATE INDEX idx_collections_is_public_created ON collections(is_public, created_at DESC);
CREATE INDEX idx_collections_user_created ON collections(user_id, created_at DESC);
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
-- 复合索引：优化集合详情页的加载
CREATE INDEX idx_collection_items_query ON collection_items(collection_id, created_at DESC);
```

**字段说明**：
- `UNIQUE(collection_id, expression_id)` - 保证同一表达式在同一集合中只出现一次
- `note` - 可选的添加说明
- `items_count` (在 collections 表) - 每次增删 collection_items 时同步更新，避免昂贵的 COUNT 子查询。

### 10. language_stats 表

物化统计表，用于加速热力图和仪表盘的显示。

**表结构**：

```sql
CREATE TABLE IF NOT EXISTS language_stats (
    language_code TEXT PRIMARY KEY,               -- 语言代码
    expression_count INTEGER DEFAULT 0             -- 该语言下的表达式总数
);
```

**字段说明**：
- 物化视图：取代了所有针对 `expressions` 表的 `GROUP BY language_code` 的聚合查询。
- 维护机制：在 Expression 进行 CRUD 或批处理迁移时，由后端 Service 实时同步更新。

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

- **全文索引 (FTS5)**：为 `expressions.text` 创建 FTS5 虚拟表，实现毫秒级前缀匹配与全文搜索。
- **R2 整合**：针对静态资源（如音频、导出结果）的元数据管理优化

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

### 1. 多级缓存策略 (Multi-layer Caching)

为了抵消 Cloudflare D1 的 "Rows Read" 限制并提升响应性能，系统实施了三级缓存：
- **L1 (Isolation Cache)**: 后端单次请求作用域内的 `languagesCache`，TTL 为 30 分钟。
- **L2 (Edge Cache)**: 利用 Workers Cache API，在边缘节点缓存高频 GET 请求（热力图、搜索、UI 翻译等）。
- **L3 (Materialized)**: 通过 `language_stats` 等物化表将聚合结果持久化，变 O(N) 为 O(1)。

### 2. 反范式化设计 (De-normalization)

- **items_count**: 在 `collections` 表中冗余存储项目数量，消除列表展示时的统计开销。

### 3. 索引精细化

- 针对分页查询（`created_at DESC`）普遍补充了复合索引。
- 针对 UI 翻译（`WHERE collection.name = 'langmap'`）补充了 `idx_collections_name`。

### 4. 批量操作优化

- **db.batch()**: 在进行批处理提交 (Upsert) 和 ID 迁移时，使用 D1 的原子批处理语句，大幅减少数据库往返次数。

### 5. 全文检索 (FTS5) 架构

为了消除 `LIKE '%query%'` 带来的全表扫描（High Rows Read），系统引入了 FTS5 虚拟表：
- **虚拟表**：`expressions_fts` (External Content 模式)。
- **同步机制**：通过触发器（Trigger）在数据增删改时自动保持主表与搜索索引的实时同步。
- **分词器**：使用 `unicode61` 以支持全球多语言字符的搜索。

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
