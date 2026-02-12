# 国际化动态语言支持

## System Reminder

**设计来源**：本设计基于原始 `i18n.md`

**实现状态**：
- ✅ 基础架构设计 - 已完成
- ✅ 数据模型扩展 - 已完成（languages 表、tags 字段）
- ✅ 后端 API 基础实现 - 已实现（语言列表、UI 翻译端点）
- ⏳ 前端动态语言加载 - 部分实现（后端端点可用，前端集成需确认）
- ⏳ 用户自定义语言创建 - 部分实现（API 已实现，前端集成需确认）
- ❌ 语言切换流程 - 未实现完整（缓存策略、用户偏好保存）
- ❌ 用户贡献流程 - 未实现完整（翻译贡献、质量控制、审核）
- ❌ 性能优化 - 未实现（按需加载、多级缓存）
- ❌ 混合模式实现 - 未实现（核心语言静态配置 + 动态语言）

**未实现的 API 端点**：
- `POST /api/v1/languages` - 提交新语言（API 已定义，实现需确认）
- 完成度计算 API（`calculateUITranslationCompletion` 在抽象层定义，具体实现需确认）

**未实现的功能**：
- 用户语言贡献界面
- 翻译质量控制机制
- 机器翻译建议集成
- 翻译记忆功能
- 术语表集成

---

## 概述

国际化动态语言支持扩展方案，支持通过数据库动态添加新语言，允许用户自由贡献界面翻译。

## 目标

1. 支持通过数据库动态添加新语言
2. 允许用户自由贡献界面翻译
3. 实现界面文本的动态加载
4. 保持现有i18n框架的兼容性
5. 确保系统性能不受影响
6. 支持没有标准BCP-47代码的小众语言

## 设计方案

### 1. 数据模型设计

#### languages表
```sql
CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,  -- 自定义语言代码 (如: en, zh-CN, toki-pona, x-dialect)
    name VARCHAR(100) NOT NULL,        -- 语言显示名称
    native_name VARCHAR(100),          -- 本地语言名称
    direction VARCHAR(3) DEFAULT 'ltr', -- 文字方向 (ltr/rtl)
    is_active BOOLEAN DEFAULT true,    -- 是否启用
    created_by INTEGER,                -- 创建者用户ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### expressions表扩展
在现有expressions表基础上添加tags字段：
```sql
ALTER TABLE expressions ADD COLUMN tags TEXT[]; -- 标签数组字段
```

### 2. 后端API设计

#### 获取支持的语言列表
```
GET /api/v1/languages
响应:
[
  {
    "code": "en",
    "name": "English",
    "native_name": "English",
    "direction": "ltr"
  },
  {
    "code": "zh-CN",
    "name": "Simplified Chinese",
    "native_name": "简体中文",
    "direction": "ltr"
  },
  {
    "code": "toki-pona",
    "name": "Toki Pona",
    "native_name": "toki pona",
    "direction": "ltr"
  }
]
```

#### 获取指定语言的UI翻译
```
GET /api/v1/expressions?language={language_code}&tags=langmap
响应:
[
  {
    "id": 1,
    "text": "Explore the World of Languages",
    "language": "en",
    "region": "global",
    "tags": ["langmap", "home.title"]
  },
  {
    "id": 2,
    "text": "Home",
    "language": "en",
    "region": "global",
    "tags": ["langmap", "nav.home"]
  }
]
```

#### 提交新的语言
```
POST /api/v1/languages
请求体:
{
  "code": "custom-lang",        // 用户自定义代码
  "name": "Custom Language",    // 语言名称
  "native_name": "Native Name", // 本地名称
  "direction": "ltr"            // 文字方向
}
```

#### 提交新的翻译（UI文本作为特殊的表达式）
```
POST /api/v1/expressions
请求体:
{
  "text": "Home",
  "language": "custom-lang",
  "region": "global",
  "source_type": "ui",
  "tags": ["langmap", "nav.home"]
}
```

### 3. 前端实现方案

#### 动态加载翻译
1. 应用启动时从后端获取当前用户选择的语言翻译（带langmap标签的表达式）
2. 将获取的翻译转换为i18n所需的格式
3. 实现缓存机制避免重复请求

#### 语言切换流程
1. 用户选择新语言
2. 检查本地是否有缓存翻译
3. 如果没有缓存，则从后端获取带langmap标签的表达式
4. 转换为i18n消息格式并更新i18n实例
5. 保存到本地缓存

#### 用户自定义语言创建流程
1. 提供"添加新语言"按钮
2. 用户填写语言信息表单（代码、名称、本地名称、文字方向）
3. 提交到后端创建新语言
4. 自动切换到新创建的语言

#### 缓存策略
1. 使用localStorage或IndexedDB缓存翻译
2. 实现缓存过期机制（如24小时）
3. 提供强制刷新缓存的机制

### 4. 混合模式实现

为了保持性能和兼容性，采用混合模式：

1. 保留核心语言（en, zh-CN, zh-TW, es, fr, ja）在静态配置中
2. 动态语言通过数据库加载
3. 当用户选择动态语言时，从后端获取带langmap标签的表达式并动态注册到i18n实例

### 5. 用户贡献流程

#### 语言贡献
1. 用户可以添加新语言，包括没有标准代码的小众语言
2. 提供简单的表单收集必要信息
3. 新语言创建后立即可用

#### 翻译贡献
1. 用户可以在界面中提交缺失的翻译
2. UI翻译作为带langmap标签的表达式存储在expressions表中
3. 提交的翻译进入待审核状态
4. 管理员审核通过后生效

#### 质量控制
1. 实现投票机制，用户可以对翻译进行投票
2. 基于用户信誉度加权投票结果
3. 实现举报机制处理不当翻译

### 6. 性能优化

#### 数据加载优化
1. 按需加载：只加载当前页面需要的翻译
2. 分批加载：将翻译按功能模块分组
3. 预加载：预测用户可能访问的页面并预加载翻译

#### 缓存策略
1. 实现多级缓存（内存缓存 + 本地存储）
2. 使用HTTP缓存头优化API响应
3. 实现缓存版本控制

## 实施步骤

### 第一阶段：基础架构
1. 修改expressions表，添加tags字段
2. 修改后端API接口以支持标签查询
3. 实现后端语言管理接口
4. 修改前端i18n初始化逻辑以支持动态加载

### 第二阶段：核心功能
1. 实现语言切换功能
2. 实现翻译缓存机制
3. 实现混合模式（静态+动态语言）
4. 实现用户自定义语言创建功能

### 第三阶段：用户功能
1. 实现翻译贡献界面
2. 实现审核流程
3. 实现质量控制机制

### 第四阶段：优化完善
1. 实施性能优化
2. 添加错误处理和降级机制
3. 完善测试用例

## 风险与应对

### 性能风险
**风险**：动态加载可能影响页面加载速度
**应对**：
- 实施缓存机制
- 使用懒加载策略
- 提供加载状态提示

### 数据一致性风险
**风险**：数据库中的翻译与静态配置可能不一致
**应对**：
- 建立同步机制
- 实施数据验证
- 提供版本控制

### 用户贡献质量风险
**风险**：用户贡献的翻译质量参差不齐
**应对**：
- 实施审核机制
- 建立信誉系统
- 提供举报功能

## 总结

通过实现基于数据库的动态语言支持系统，Langmap可以支持更多的语言，并允许社区贡献翻译。该方案在保持现有功能的基础上，扩展了系统的语言支持能力，为项目的国际化发展提供了可持续的解决方案。用户可以自由添加任何语言，包括那些没有标准BCP-47代码的小众语言，真正实现了语言的自由扩展。

通过在expressions表中添加tags字段，我们可以有效地区分UI翻译和普通表达式，同时保持数据模型的统一性。这种方法充分利用了现有的表达式管理系统功能，如版本控制、审核机制等，避免了数据冗余和维护复杂性。使用"langmap"作为专有标签能够更好地标识这些UI翻译属于Langmap项目。