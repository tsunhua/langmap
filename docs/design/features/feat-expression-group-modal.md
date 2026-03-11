# Handbook 词句组快捷弹窗功能设计

## System Reminder

**设计来源**：用户需求 - 在 HandbookView 页面点击词句时，弹出一个简略的词句详情框，显示当前词句组（meaning group）的所有词句，并支持快捷添加新词句到该组，使用表格形式展示（表头：语言、词句）。

**实现状态**：设计阶段，待实现

---

## 概述

在阅读 Handbook（学习手册）时，用户经常需要快速查看某个词句在不同语言下的翻译版本，或添加新的翻译版本。当前系统点击词句会跳转到完整的 Detail 页面，这在快速浏览时不够高效。

本功能设计一个快捷弹窗，提供：
1. **词句组概览**：展示该词句组（meaning group）中所有词句的翻译
2. **表格编辑**：以"语言 - 词句"表格形式展示，支持直接在表格中添加新行
3. **语言范围限定**：语言选择器的选项与 Handbook 的学习语言（target_lang）范围保持一致
4. **无缝交互**：支持关闭弹窗或跳转到完整详情页

## 交互流程

### 1. 点击词句触发弹窗

在 `HandbookView.vue` 中，渲染的词句元素（`<span class="expression-term">`）点击时不再直接跳转，而是：
- 调用新的全局函数 `window.showExpressionGroupModal(expressionId, meaningId)`
- 弹出词句组详情弹窗

### 2. 弹窗内容结构

弹窗采用表格编辑形式，每行显示一个语言的词句：

```
┌─────────────────────────────────────────────────────────┐
│  [×]  词句组详情                            [查看详情] │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┤
│  │ [+ 添加一行]                                         │
│  ├─────────────┬────────────────────────────────────────┤
│  │ 语言        │ 词句                    │ 操作        │
│  ├─────────────┼────────────────────────────────────────┤
│  │ English    │ Hello                      │ [×]       │
│  │ 中文（简体）│ 你好                        │ [×]       │
│  │ 中文（繁體）│ 你好                        │ [×]       │
│  │ 日本語      │ こんにちは                   │ [×]       │
│  │ [+ 新行]   │ [输入框]        │ [✓] [×]  │            │
│  └─────────────┴────────────────────────────────────────┤
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3. 表格操作

- **关闭弹窗**：点击右上角 × 或背景区域
- **跳转详情**：点击"查看详情"按钮，跳转到 `/detail/:id` 完整页面
- **添加新行**：
  - 点击"+ 添加一行"按钮，在表格末尾添加一个新的空行
  - 新行包含：语言下拉选择器、词句输入框、确认✓和取消×按钮
  - 语言选择器选项限定为 handbook 的学习语言范围（与页面顶部语言选择器一致）
  - 点击✓保存，调用后端 API 添加新词句
  - 点击×取消，移除新行

### 4. 添加逻辑

当用户点击✓保存新行时：
1. 前端验证：
   - 语言不能为空
   - 词句文本不能为空
   - 该语言在当前词句组中尚未存在
2. 调用后端 API：
   - 创建新的 expression 记录
   - 关联到现有的 meaning_id
3. 成功后刷新表格内容
4. 可选：同时刷新 Handbook 页面的渲染内容

### 5. 语言范围限定

**关键设计**：语言选择器的选项必须与当前 Handbook 的学习语言范围保持一致。

从 `HandbookView.vue` 的 `instructionLanguages` 状态获取当前选定的学习语言列表，仅显示这些语言作为添加选项。

如果用户还未选择任何学习语言，则显示 Handbook 默认的 `target_lang` 对应的语言。

## 组件设计

### ExpressionGroupModal.vue（新组件）

位于 `web/src/components/ExpressionGroupModal.vue`

#### Props
- `visible`: Boolean - 控制弹窗显示/隐藏
- `expressionId`: Number - 当前词句 ID（可选，用于获取完整词句信息）
- `meaningId`: Number - 词句组 ID（核心标识）
- `availableLanguages`: Array - 可用语言列表（从父组件传入，与 handbook 学习语言一致）
- `instructionLanguages`: Array - 当前选定的学习语言代码数组

#### Data
- `loading`: Boolean - 加载状态
- `expressions`: Array - 词句组中的所有词句
- `showNewRow`: Boolean - 是否显示新行
- `newRowLanguage`: String - 新行选择的语言
- `newRowText`: String - 新行词句文本
- `adding`: Boolean - 添加操作进行中
- `message`: String - 操作消息（成功/错误）

#### Computed
- `displayLanguages` - 计算属性：从 `availableLanguages` 中过滤，仅返回 `instructionLanguages` 中存在的语言

#### Methods
- `fetchGroupMembers()` - 获取词句组所有成员
- `addNewRow()` - 显示新行（编辑模式）
- `cancelNewRow()` - 取消添加，隐藏新行
- `confirmNewRow()` - 确认添加新词句
- `close()` - 关闭弹窗
- `goToDetail()` - 跳转到详情页

#### Events
- `close` - 关闭弹窗时触发
- `updated` - 成功添加翻译后触发（可触发父组件刷新渲染）

### HandbookView.vue 修改

#### Template
添加组件引用：

```vue
<ExpressionGroupModal
  :visible="showExpressionGroupModal"
  :expression-id="selectedExpressionId"
  :meaning-id="selectedMeaningId"
  :available-languages="languages"
  :instruction-languages="instructionLanguages"
  @close="showExpressionGroupModal = false"
  @updated="handleExpressionGroupUpdated"
/>
```

#### Script
添加状态和方法：

```javascript
// State
const showExpressionGroupModal = ref(false)
const selectedExpressionId = ref(null)
const selectedMeaningId = ref(null)

// 全局函数
window.showExpressionGroupModal = (expressionId, meaningId) => {
  selectedExpressionId.value = expressionId
  selectedMeaningId.value = meaningId
  showExpressionGroupModal.value = true
}

// 处理更新事件
const handleExpressionGroupUpdated = () => {
  // 刷新 handbook 内容以显示新翻译
  fetchInitialData()
}
```

#### 传递 languages 和 instructionLanguages

在 `return` 中暴露给组件：

```javascript
return {
  // ... other exports
  languages,
  instructionLanguages
}
```

## 后端 API 需求

现有 API 已经支持所需功能，无需修改：

1. **获取词句组成员**：
   - `GET /api/v1/expressions?meaning_id={meaningId}`
   - 返回词句组中所有词句

2. **添加新词句**：
   - `POST /api/v1/expressions`
   - Body: `{ text, language_code, meaning_id }`

## 数据结构

### 词句组响应示例

```json
[
  {
    "id": 123,
    "text": "Hello",
    "language_code": "en",
    "region_name": null,
    "audio_url": null,
    "meaning_id": 456
  },
  {
    "id": 124,
    "text": "你好",
    "language_code": "zh-CN",
    "region_name": null,
    "audio_url": null,
    "meaning_id": 456
  }
]
```

### 添加词句请求示例

```json
{
  "text": "Bonjour",
  "language_code": "fr",
  "meaning_id": 456
}
```

## 国际化支持

需要添加以下翻译键到所有 locale 文件：

| 键名 | 描述 | 示例（中文） |
|-----|------|------------|
| `expression_group_details` | 弹窗标题 | 词句组详情 |
| `more` | 更多按钮 | 更多 |
| `add_row` | 添加一行按钮 | 添加一行 |
| `cancel` | 取消按钮 | 取消 |
| `confirm` | 确认按钮 | 确认 |
| `language` | 表头：语言 | 语言 |
| `expression` | 表头：词句 | 词句 |
| `language_already_exists` | 语言已存在错误 | 该语言已存在 |
| `translation_added_successfully` | 添加成功消息 | 添加成功 |
| `please_select_language` | 选择语言提示 | 请选择语言 |
| `please_enter_expression` | 输入词句提示 | 请输入词句 |

## 样式设计

### 弹窗容器
- 最大宽度：600px
- 最大高度：80vh
- 圆角：12px
- 阴影：中等
- 背景：白色

### 表格样式
- 表头：浅灰色背景，加粗文字
- 行：底部边框分隔
- 操作列：固定宽度 80px
- 语言列：宽度 30%
- 词句列：宽度 50%（剩余空间）

### 新行样式
- 背景：浅蓝色高亮
- 语言选择器：下拉框样式
- 输入框：边框样式
- 按钮：✓ 绿色确认，× 灰色取消

### 按钮样式
- 添加一行：虚线边框，+ 图标，hover 时高亮
- 删除：× 图标，hover 时红色
- 查看详情：蓝色按钮

## 实施计划

### Phase 1: 基础弹窗
- [ ] 创建 `ExpressionGroupModal.vue` 组件
- [ ] 实现弹窗基础样式和布局
- [ ] 集成到 `HandbookView.vue`
- [ ] 修改 `window.navigateToExpression` 为 `window.showExpressionGroupModal`
- [ ] 传递 `languages` 和 `instructionLanguages` 到组件

### Phase 2: 表格展示
- [ ] 实现 `fetchGroupMembers()` 方法
- [ ] 实现表格展示逻辑
- [ ] 添加加载状态处理
- [ ] 实现关闭和跳转详情功能
- [ ] 实现删除按钮 UI（暂不实现功能）

### Phase 3: 表格编辑添加功能
- [ ] 实现"+ 添加一行"按钮
- [ ] 实现新行 UI（语言选择器 + 输入框 + 确认/取消按钮）
- [ ] 实现 `displayLanguages` 计算属性（过滤到 instructionLanguages）
- [ ] 实现添加翻译表单验证
- [ ] 实现后端 API 调用
- [ ] 实现成功后刷新逻辑

### Phase 4: 国际化与优化
- [ ] 添加所有翻译键到 10 个 locale 文件
- [ ] 优化响应式布局（移动端适配）
- [ ] 添加错误处理和用户反馈
- [ ] 测试边界情况

### Phase 5: 测试与文档
- [ ] 单元测试
- [ ] 集成测试
- [ ] 用户验收测试

## 相关文档

- [feat-handbook.md](feat-handbook.md) - Handbook 功能基础设计
- [feat-meaning-mapping.md](feat-meaning-mapping.md) - 词句与语义多对多关系
- [feat-ui-translation.md](feat-ui-translation.md) - UI 翻译系统

## 实现检查清单

- [ ] 组件 `ExpressionGroupModal.vue` 创建完成
- [ ] 弹窗样式符合设计稿
- [ ] 表格展示词句组所有成员
- [ ] "+ 添加一行"按钮功能正常
- [ ] 新行语言选择器选项正确限定（与 instructionLanguages 一致）
- [ ] 添加翻译功能正常工作
- [ ] 国际化翻译完整（所有 10 个语言）
- [ ] 移动端响应式正常
- [ ] 错误处理完善
- [ ] 后端 API 调用正确
- [ ] 成功后刷新逻辑正确

## 注意事项

1. **权限控制**：添加翻译需要用户登录，未登录用户应提示登录
2. **语言限定**：**关键** - 语言选择器必须只能选择 handbook 当前的学习语言范围
3. **缓存处理**：Handbook 的渲染内容有 24 小时缓存，添加新翻译后需要决定是否刷新缓存
4. **边界情况**：
   - 学习语言列表为空（应显示默认语言或提示）
   - 所有学习语言都已有翻译（应禁用添加按钮或提示）
   - 网络请求失败
   - 后端验证失败
   - 用户未登录

5. **可访问性**：
   - 弹窗支持 ESC 关闭
   - 支持焦点管理
   - 支持键盘导航

## 未来扩展

- 支持直接在表格中编辑现有翻译
- 支持直接在表格中删除翻译（需要权限检查）
- 支持播放录音（如果有）
- 支持批量导入翻译
