# 在 Cloudflare 上部署 LangMap

本文档介绍了如何在 Cloudflare 上部署 LangMap 应用程序。

## 部署选项

### 选项 1：使用 Cloudflare Pages 部署前端 + Cloudflare Workers 部署后端

这是推荐的方式，因为：

1. 前端可以充分利用 Cloudflare Pages 的静态网站托管能力
2. 后端可以利用 Cloudflare Workers 的边缘计算能力

#### 部署前端到 Cloudflare Pages

1. 构建前端应用：
   ```bash
   cd web
   npm run build
   ```

2. 将 `web/dist` 目录部署到 Cloudflare Pages

3. 在 Cloudflare Pages 项目设置中：
   - 构建命令: `npm run build`
   - 发布目录: `dist`

#### 部署后端到 Cloudflare Workers (Python)

Cloudflare Workers 现在支持 Python，但需要注意一些限制。

1. 安装必要的工具：
   ```bash
   # 确保安装了 uv 和 Node.js
   # 然后安装 workers-py
   uv tool install workers-py
   ```

2. 初始化项目：
   ```bash
   cd backend
   uv init
   uv add fastapi
   uv run pywrangler init
   ```

3. 配置 wrangler.toml：
   ```toml
   name = "langmap-api"
   main = "app/main.py"
   compatibility_date = "2024-03-20"
   
   [observability]
   enabled = true
   ```

4. 注意事项：
   - 由于 Workers 是无服务器环境，不能直接使用 SQLite
   - 需要使用 Cloudflare D1 或外部数据库
   - 文件系统访问受限

### 选项 2：使用 Cloudflare Tunnel 连接到自托管服务

如果您希望完全在 Cloudflare 生态系统中运行，但又需要完整的 Python 支持，可以考虑：

1. 在自己的服务器上部署完整的应用程序（前端+后端）
2. 使用 Cloudflare Tunnel 将服务暴露到互联网
3. 利用 Cloudflare 的安全和性能特性

## 数据库配置

应用程序现在支持多种数据库后端，包括 SQLite 和 Cloudflare D1，可以通过环境变量进行配置。

### 使用 SQLite（本地开发）

默认情况下，应用程序使用 SQLite 数据库：

```bash
export DATABASE_URL="sqlite:///./backend_dev.db"
```

### 使用 Cloudflare D1

要使用 Cloudflare D1，需要设置相应的数据库 URL：

```bash
export DATABASE_URL="d1://database-name"
```

在 Cloudflare Workers 环境中，还需要在 `wrangler.toml` 中配置 D1 绑定：

```toml
[[ d1_databases ]]
binding = "DB" # available in your Worker on env.DB
database_name = "your-database-name"
database_id = "your-database-id"
```

### 使用其他数据库（如 PostgreSQL, MySQL）

对于其他数据库，可以使用标准的数据库 URL 格式：

```bash
# PostgreSQL
export DATABASE_URL="postgresql://user:password@localhost:5432/mydatabase"

# MySQL
export DATABASE_URL="mysql://user:password@localhost:3306/mydatabase"
```

## 限制和注意事项

### Cloudflare Workers Python 支持的限制

根据 Cloudflare 的文档，Python Workers 目前：

1. 处于测试阶段，API 可能会发生变化
2. 对 Python 标准库的支持有限
3. 不能使用某些依赖项（如需要编译的 C 扩展）
4. 对文件系统的访问受限
5. SQLite 数据库无法直接使用

### 数据库考虑

由于 Cloudflare Workers 无法直接使用 SQLite，您需要：

1. 使用 Cloudflare D1（SQLite 兼容的数据库）
2. 使用其他外部数据库服务（如 Supabase, PlanetScale, MongoDB Atlas 等）
3. 重构数据访问层以适配无服务器环境

## 推荐的部署架构

```
┌─────────────────┐    ┌──────────────────────┐
│                 │    │                      │
│  Cloudflare     │    │  Cloudflare D1 or    │
│  Pages (Frontend)◄───►│  External Database   │
│                 │    │                      │
└─────────▲───────┘    └──────────────────────┘
          │
          │
┌─────────▼───────┐
│                 │
│  Cloudflare     │
│  Workers (API)  │
│                 │
└─────────────────┘
```

## 下一步建议

1. 考虑将后端重构为 JavaScript/TypeScript 以更好地适应 Cloudflare Workers
2. 或者使用传统部署方式（Docker）并在前面加上 Cloudflare Tunnel
3. 评估是否需要将 SQLite 替换为 Cloudflare D1 或其他云端数据库服务