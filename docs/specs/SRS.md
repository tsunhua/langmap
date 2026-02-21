# LangMap 系统需求规格说明 (SRS)

## 1. 系统架构
LangMap 采用现代的前后端分离架构，全面适配 Cloudflare 平台。

- **前端 (Web)**: 基于 Vue 3 构建，使用 Vite 作为构建工具，Vercel/Pages 部署。
- **后端 (Backend)**: 基于 Hono (TypeScript) 构建，部署在 Cloudflare Workers。
- **数据库 (Database)**: 采用 Cloudflare D1 (SQLite)，由 Hono 逻辑层进行访问控制。
- **移动端 (iOS)**: 基于 SwiftUI 构建的原生应用。
- **存储 (Storage)**: 采用 Cloudflare R2 用于异步导出文件的存储。

## 2. 技术栈
### 2.1 后端 (Backend)
- **框架**: Hono (v4.10.7+)
- **语言**: TypeScript (v5.9.3+)
- **运行时**: Cloudflare Workers
- **库**: Zod (验证), Jose (JWT), Bcryptjs (加密), Resend (邮件)
- **数据库驱动**: Cloudflare D1 Native API

### 2.2 前端 (Web)
- **框架**: Vue 3
- **样式**: Tailwind CSS
- **构建**: Vite
- **地图**: Leaflet / OpenStreetMap

### 2.3 移动端 (Apple)
- **框架**: SwiftUI
- **语言**: Swift

## 3. 关键组件与设计
详细设计请参阅 `docs/design/features/` 目录：
- **用户与权限**: [feat-user-system.md](../design/features/feat-user-system.md)
- **数据库架构**: [feat-database.md](../design/features/feat-database.md)
- **地图可视化**: [feat-heatmap.md](../design/features/feat-heatmap.md)
- **搜索系统**: [feat-search.md](../design/features/feat-search.md)
- **异步导出**: [feat-export.md](../design/features/feat-export.md)
- **国际化 (i18n)**: [feat-i18n.md](../design/features/feat-i18n.md)

## 4. 接口协议
- 遵循 RESTful API 规范。
- 详情请参阅 `docs/api/`（如果存在）。

## 5. 性能与安全
- **缓存策略**: 在后端和前端均实施多级缓存。
- **权限校验**: 严格的 JWT 认证与 RBAC（基于角色的访问控制）。
