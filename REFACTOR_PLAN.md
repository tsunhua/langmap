# LangMap 前后端代码重构计划

**制定日期**: 2026年3月18日  
**优先级**: 分三阶段执行

---

## 📊 现状分析

### 后端 (Backend)
- **框架**: Hono.js + Cloudflare Workers
- **数据库**: Cloudflare D1 (SQLite)
- **存储**: R2 Bucket (音频/导出)
- **认证**: JWT + bcryptjs
- **当前问题**:
  - API v1.ts 文件过大，需要模块化拆分
  - 缺少统一的错误处理层
  - 数据库查询逻辑未充分抽象
  - 缺少API文档和OpenAPI规范
  - 环境变量管理不规范
  - 缺少测试框架和单元测试

### 前端 (Frontend)
- **框架**: Vue 3 + Composition API
- **路由**: Vue Router 4
- **国际化**: Vue i18n
- **样式**: Tailwind CSS
- **HTTP客户端**: Axios
- **当前问题**:
  - 组件划分不够清晰
  - 状态管理缺失（无Pinia/Vuex）
  - 重复的API调用逻辑
  - 缺少错误处理标准化
  - 缺少TypeScript类型定义
  - 页面组件和业务逻辑混杂

---

## 🎯 重构目标

1. **提高代码可维护性** - 模块化、单一职责
2. **增强类型安全** - 完整的TypeScript类型定义
3. **规范化错误处理** - 统一的异常管理
4. **提升开发效率** - 自动化测试、文档生成
5. **性能优化** - 代码分割、缓存策略
6. **团队协作** - API文档、代码规范

---

## 📋 第一阶段：架构和基础设施 (2-3周)

### 后端重构

#### 1.1 API路由模块化
**目标**: 将单一的 `v1.ts` 拆分为功能模块

```
backend/src/server/
├── routes/
│   ├── auth.ts          # 认证相关
│   ├── expressions.ts   # 表达式管理
│   ├── languages.ts     # 语言管理
│   ├── collections.ts   # 收藏集合
│   ├── users.ts         # 用户管理
│   ├── export.ts        # 导出功能
│   └── index.ts         # 路由汇总
├── middleware/
│   ├── auth.ts          # 认证中间件
│   ├── error.ts         # 错误处理
│   ├── validation.ts    # 数据验证
│   └── logging.ts       # 日志记录
├── schemas/             # Zod验证模式
│   ├── auth.ts
│   ├── expression.ts
│   ├── user.ts
│   └── collection.ts
├── services/            # 业务逻辑
│   ├── auth.ts
│   ├── expression.ts
│   ├── user.ts
│   └── collection.ts
├── db/
│   ├── queries/         # 数据库查询
│   │   ├── auth.ts
│   │   ├── expression.ts
│   │   └── ...
│   └── migrations/      # 迁移文件
├── types/               # 类型定义
│   ├── api.ts           # API响应类型
│   ├── entity.ts        # 数据实体
│   └── error.ts         # 错误类型
└── utils/
    ├── jwt.ts           # JWT工具
    ├── password.ts
    └── response.ts      # 标准响应格式
```

**关键任务**:
- [x] 创建文件夹结构
- [ ] 提取认证逻辑到 `services/auth.ts`
- [ ] 提取表达式逻辑到 `services/expression.ts`
- [x] 使用Zod定义所有验证schema
- [x] 统一使用 `utils/response.ts` 返回响应 (所有路由已更新使用统一响应格式)


#### 1.2 错误处理层
**创建**: `backend/src/server/error/handler.ts`

```typescript
// 错误类型和处理
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: any
  ) {
    super(message)
  }
}

export const errorHandler = (error: unknown) => {
  // 统一处理所有错误
}
```

**关键任务**:
- [ ] 定义标准错误响应格式
- [ ] 创建自定义错误类
- [ ] 添加全局错误处理中间件
- [ ] 完善调试日志

#### 1.3 环境配置规范化
**创建**：`backend/src/config.ts`

```typescript
export const config = {
  api: {
    baseUrl: process.env.API_BASE_URL,
    version: 'v1'
  },
  db: {
    // D1配置
  },
  auth: {
    jwtSecret: process.env.SECRET_KEY,
    tokenExpiry: '24h'
  },
  storage: {
    // R2配置
  }
}
```

**关键任务**:
- [ ] 整合所有环境变量
- [x] 创建 `.env.example`
- [ ] 添加配置验证

#### 1.4 数据库查询层抽象
**创建**: `backend/src/server/db/queries/`

```typescript
// 每个功能模块一个查询文件
// 示例: queries/expression.ts
export class ExpressionQueries {
  async findById(db: D1Database, id: number) { }
  async findAll(db: D1Database, filters: object) { }
  async create(db: D1Database, data: object) { }
  async update(db: D1Database, id: number, data: object) { }
  async delete(db: D1Database, id: number) { }
}
```

**关键任务**:
- [ ] 提取所有SQL查询到专用模块
- [ ] 创建参数化查询以防SQL注入
- [ ] 添加查询日志

---

### 前端重构

#### 2.1 状态管理 (Pinia)
**创建**: `web/src/stores/`

```
web/src/stores/
├── auth.ts          # 认证状态
├── expressions.ts   # 表达式列表
├── user.ts         # 用户信息
├── ui.ts           # UI状态
└── index.ts        # 导出
```

**关键任务**:
- [ ] 安装Pinia: `npm install pinia`
- [ ] 创建认证store
- [ ] 创建用户store
- [ ] 迁移Axios调用到actions

#### 2.2 API客户端层
**创建**: `web/src/api/`

```
web/src/api/
├── client.ts           # Axios配置和拦截器
├── interceptors.ts     # 请求/响应拦截
├── auth.ts            # 认证API
├── expressions.ts     # 表达式API
├── users.ts           # 用户API
└── types.ts           # API类型定义
```

**关键任务**:
- [ ] 集中Axios配置
- [ ] 添加请求/响应拦截器
- [ ] 错误处理标准化
- [ ] 添加请求loading状态

#### 2.3 类型定义完善
**创建**: `web/src/types/`

```typescript
// types/api.ts - API响应类型
export interface ApiResponse<T> {
  code: number
  message: string
  data?: T
}

// types/models.ts - 数据模型
export interface Expression {
  id: number
  language: string
  phrase: string
  // ...
}

// types/components.ts - 组件props类型
```

**关键任务**:
- [ ] 统一API响应类型
- [ ] 定义所有数据模型
- [ ] 定义组件props类型

#### 2.4 组件结构优化
**重新组织**: `web/src/components/`

```
web/src/components/
├── common/            # 可复用组件
│   ├── Button.vue
│   ├── Modal.vue
│   ├── Form.vue
│   └── ...
├── layout/            # 布局组件
│   ├── Header.vue
│   ├── Sidebar.vue
│   └── Footer.vue
├── features/          # 功能组件
│   ├── ExpressionCard.vue
│   ├── LanguageSelector.vue
│   └── ...
└── README.md          # 组件文档
```

**关键任务**:
- [x] 分类组件
- [x] 提取公共逻辑到composables (useAuth.ts, useForm.ts, useExpressions.ts 已存在)
- [x] 编写组件文档 (web/src/components/README.md 已创建)

#### 2.5 Composables提取
**创建**: `web/src/composables/`

```
web/src/composables/
├── useAuth.ts           # 认证逻辑
├── useExpressions.ts    # 表达式获取
├── useForm.ts          # 表单处理
├── useNotification.ts  # 通知
└── useAsyncData.ts     # 异步数据加载
```

**关键任务**:
- [x] 提取表达式获取逻辑 (useExpressions.ts 已存在)
- [x] 提取表单验证逻辑 (useForm.ts 已存在)
- [x] 提取认证逻辑 (useAuth.ts 已存在)

---

## 📋 第二阶段：测试和文档 (2-3周)

### 后端测试

#### 3.1 单元测试框架
- [ ] 安装Vitest: `npm install vitest`
- [ ] 配置测试环境
- [ ] 为services编写单元测试
- [ ] 目标覆盖率: 70%+

```
backend/src/__tests__/
├── unit/
│   ├── services/auth.test.ts
│   ├── services/expression.test.ts
│   └── utils/jwt.test.ts
└── integration/
    ├── api/auth.test.ts
    └── api/expressions.test.ts
```

#### 3.2 API文档
- [ ] 安装OpenAPI生成: `npm install -D @hono/typegen-hono-openapi`
- [ ] 为所有API端点添加OpenAPI注释
- [ ] 生成Swagger文档
- [ ] 部署API文档到 `/api/docs`

### 前端测试

#### 3.3 单元和集成测试
- [ ] 安装Vitest + Vue Test Utils
- [ ] 为组件编写单元测试
- [ ] 为store编写测试
- [ ] 目标覆盖率: 60%+

```
web/src/__tests__/
├── unit/
│   ├── components/ExpressionCard.test.ts
│   ├── stores/auth.test.ts
│   └── composables/useAuth.test.ts
└── integration/
    ├── pages/CreateExpression.test.ts
    └── api/expressions.test.ts
```

#### 3.4 E2E测试
- [ ] 安装Cypress或Playwright
- [ ] 编写关键用户流程测试
- [ ] 配置CI/CD测试自动化

### 代码文档

#### 3.5 API文档 (后端)
- [ ] README.md - 项目概览
- [ ] ARCHITECTURE.md - 架构说明
- [ ] API_DOCS.md - API文档
- [ ] DATABASE.md - 数据库架构

#### 3.6 代码文档 (前端)
- [ ] COMPONENTS.md - 组件指南
- [ ] STATE_MANAGEMENT.md - 状态管理说明
- [ ] DEVELOPMENT.md - 开发指南

---

## 📋 第三阶段：性能优化和部署 (1-2周)

### 后端优化

#### 4.1 缓存策略
- [ ] 实现HTTP缓存头
- [ ] 添加Cloudflare缓存规则
- [ ] 为热门查询添加缓存

#### 4.2 数据库优化
- [ ] 添加适当的数据库索引
- [ ] 优化N+1查询问题
- [ ] 添加数据库查询日志和监控

#### 4.3 API性能
- [ ] 添加请求速率限制
- [ ] 实现分页
- [ ] 优化大数据响应

### 前端优化

#### 4.4 代码分割
- [ ] 配置动态import实现路由代码分割
- [ ] 预加载关键资源
- [ ] 优化bundle大小

#### 4.5 性能监控
- [ ] 集成Web Vitals监控
- [ ] 添加错误追踪 (Sentry)
- [ ] 监控API响应时间

#### 4.6 构建优化
- [ ] 配置Vite预构建
- [ ] 优化CSS和JS压缩
- [ ] 生成源地图用于生产调试

### 部署和CI/CD

#### 4.7 自动化部署
- [ ] 配置GitHub Actions
- [ ] 自动运行测试
- [ ] 自动部署到预发布环境
- [ ] 手动批准生产部署

```yaml
# .github/workflows/deploy.yml
name: Deploy
on: [push, pull_request]
jobs:
  test:
    # 运行测试
  deploy-staging:
    # 部署到staging
  deploy-production:
    # 手动批准后部署
```

---

## 🔄 重构顺序和优先级

### Week 1-2: 后端基础架构
1. **高优先级** (必须):
    - [x] API路由模块化
    - [ ] 错误处理层
    - [x] 环境配置规范化

2. **中优先级** (应该):
    - [ ] 数据库查询层抽象
    - [x] 使用Zod验证

### Week 3: 前端基础架构
1. **高优先级** (必须):
    - [ ] 状态管理 (Pinia)
    - [ ] API客户端层
    - [ ] 类型定义完善

2. **中优先级** (应该):
    - [x] 组件结构优化
    - [x] Composables提取

### Week 4-5: 测试和文档
1. **高优先级**:
   - [ ] 后端单元测试
   - [ ] 前端单元测试
   - [ ] API文档

2. **中优先级**:
   - [ ] E2E测试
   - [ ] 代码文档

### Week 6-7: 性能优化
1. **中优先级**:
   - [ ] 缓存策略
   - [ ] 代码分割
   - [ ] 构建优化

2. **低优先级**:
   - [ ] 性能监控
   - [ ] 细粒度优化

---

## 📦 依赖安装清单

### 后端
```bash
# 数据验证
npm install zod @hono/zod-validator

# 测试
npm install -D vitest @testing-library/node

# 日志
npm install pino

# 监控/追踪
npm install @opentelemetry/api @opentelemetry/sdk-node
```

### 前端
```bash
# 状态管理
npm install pinia

# 表单/验证
npm install vee-validate zod

# 测试
npm install -D vitest @testing-library/vue @vue/test-utils

# Linting和格式化
npm install -D eslint prettier eslint-plugin-vue

# 性能监控
npm install web-vitals
```

---

## 🎯 成功指标

### 代码质量
- [ ] 类型覆盖率: 85%+
- [ ] 测试覆盖率: 65%+ (后端 70%, 前端 60%)
- [ ] ESLint通过率: 100%
- [ ] 没有关键代码味问题

### 性能
- [ ] Lighthouse评分: 85+
- [ ] First Contentful Paint (FCP): < 1.5s
- [ ] Time to Interactive (TTI): < 2.5s
- [ ] API响应时间: < 200ms (中位数)

### 维护性
- [ ] 所有公共API都有文档
- [ ] 新文件都有类型定义
- [ ] 代码审查时间降低30%
- [ ] Bug修复时间缩短25%

---

## 🚀 执行建议

### 团队协作
- **后端小组**: 专注阶段1的后端部分
- **前端小组**: 同时进行阶段1的前端部分
- **QA**: 准备测试用例，为阶段2做准备

### 风险管理
- 每阶段结束前进行代码审查
- 保持旧代码兼容，逐步迁移
- 使用Feature flags隐藏未完成的功能
- 频繁merge到主分支 (日常)

### 沟通
- 每日站会 15分钟
- 每周进度评审
- 文档同步更新

---

## 📚 相关文件

- 现有项目: `/Users/share.lim/Documents/GitHub/langmap`
- 后端源码: `backend/src`
- 前端源码: `web/src`
- 脚本: `scripts/`

---

**下一步**: 选择第一阶段的任务开始执行，或需要我详细解析某个模块的重构方案。
