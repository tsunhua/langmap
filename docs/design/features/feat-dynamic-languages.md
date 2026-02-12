# 前端动态语言支持

## System Reminder

**设计来源**：本实现基于代码库实际实现状态

**实现状态**：
- ✅ 静态语言加载（en, zh-CN, zh-TW, es, fr, ja, nan-TW, yue-HK）- 已实现
- ✅ 语言服务基础实现 - 已实现（fetchLanguages, fetchUITranslations）
- ✅ 动态 i18n 加载增强 - 已实现（混合模式）
- ⏳ 用户自定义语言创建 - 部分实现（UI 未完全实现）
- ❌ 完整的缓存策略 - 未实现（localStorage/IndexedDB with expiration）
- ❌ 语言切换完整流程 - 部分实现（偏好保存、缓存更新）

**已实现的功能**：
- 应用启动时从后端获取语言列表
- 静态语言从配置加载
- 动态语言从后端获取（通过 meanings）
- 翻译缓存机制（内存缓存）
- "添加新语言"功能（基础）

**未实现的功能**：
- 按需加载（per-component lazy loading）
- localStorage 持久化缓存
- 缓存过期机制（24小时）
- 强制刷新功能
- 用户自定义语言创建完整流程
- 离线支持
- 性能监控和优化

---

## 概述

前端动态语言支持的实现，允许应用程序从后端动态加载语言和翻译，支持用户贡献的语言和翻译。

## 实现详情

### 1. 语言服务

语言服务（`src/services/languageService.js`）提供与后端 API 通信的功能：

- `fetchLanguages()` - 从后端获取所有可用语言
- `fetchUITranslations(languageCode)` - 按含义获取特定语言的 UI 翻译
- `createLanguage(languageData)` - 在系统中创建新语言
- `transformTranslations(expressions)` - 将扁平的表达式列表转换为嵌套的 i18n 消息对象

### 2. 动态 i18n 加载

i18n 模块（`src/i18n.js`）已增强以支持动态语言加载：

1. **静态语言**：从现有配置加载
2. **动态语言**：需要时从后端获取
3. **翻译缓存**：防止对同一语言重复请求后端
4. **回退机制**：确保即使动态翻译加载失败，应用也能继续工作

### 3. 应用组件增强

App 组件（`src/App.vue`）已更新：

1. **应用启动时动态语言列表加载**：从后端获取
2. **合并到可用语言列表**：将静态和动态语言合并
3. **加载用户偏好语言**：从 localStorage 获取或使用默认语言
4. **语言切换**：支持静态和动态语言
5. **"添加新语言"功能**：允许用户贡献新语言

### 4. 技术架构

**数据流**
```
应用启动
  → 加载静态语言配置
  → 从后端获取动态语言列表
  → 合并语言列表
  → 加载用户偏好语言
  → 初始化 i18n

语言切换
  → 用户选择新语言
  → 检查是否为静态语言
    → 是：从配置加载
    → 否：从后端获取翻译
  → 更新 i18n 实例
  → 保存偏好到 localStorage
```

### 5. 集成与 Vue Router

实现与 Vue Router 无缝集成，确保在导航期间保持语言偏好：

1. 语言切换时保存到 localStorage
2. 路由变化时检查语言偏好
3. 保持语言状态同步

### 6. 缓存策略

翻译缓存在内存中以防止对同一语言重复请求后端：

1. 当动态语言首次加载时，其翻译存储在 `dynamicMessagesCache`
2. 后续对同一语言的请求使用缓存数据
3. 缓存在应用会话期间维护
4. 未来增强可包括 localStorage 持久化和过期机制

### 7. 错误处理

1. 翻译加载失败时回退到英文
2. 网络错误记录到控制台用于调试
3. 关键操作（如添加语言）的用户友好错误消息
4. 即使动态语言加载失败，应用也能继续工作

### 8. API 集成

前端与这些后端端点通信：

**GET /api/v1/languages**
获取所有可用语言

响应：
```json
[
  {
    "code": "en",
    "name": "English",
    "native_name": "English",
    "direction": "ltr"
  },
  {
    "code": "custom-lang",
    "name": "Custom Language",
    "native_name": "Native Name",
    "direction": "ltr"
  }
]
```

**GET /api/v1/ui-translations/{language}**
按含义获取特定语言的 UI 翻译

响应：
```json
[
  {
    "id": 1,
    "text": "Home",
    "language": "custom-lang",
    "gloss": "langmap.nav.home"
  }
]
```

**POST /api/v1/languages**
创建新语言

请求：
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

响应：
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

### 9. 未来改进

1. **持久化缓存**：将翻译存储在 localStorage 中以过期时间戳
2. **懒加载**：按需加载每个组件的翻译，而不是全部加载
3. **离线支持**：缓存翻译用于离线使用场景
4. **翻译管理 UI**：为用户贡献翻译提供界面
5. **语言包**：捆绑常用语言用于离线优先场景
6. **性能监控**：跟踪翻译加载时间并相应优化
7. **端到端测试**：为关键函数添加单元测试，以验证完整的动态加载工作流

### 10. 测试

已为语言服务中的关键函数添加了单元测试，特别是转换逻辑。应添加端到端测试以验证完整的动态加载工作流。
