# Handbook 目录 (Table of Contents) 功能设计

## System Reminder

**设计来源**：根据用户需求（在 HandbookView.vue 页面左侧显示手册目录）设计。

**实现状态**：⏸️ 待实现

---

## 概述

在 HandbookView.vue 页面左侧添加目录（Table of Contents）功能，方便用户快速导航到手册的不同章节。

目录会自动从 Markdown 内容中解析出各级标题（H1-H3），生成树形结构，支持点击跳转和滚动高亮。

## 功能需求

### 1. 目录生成
- 自动解析 Markdown 内容中的标题（H1, H2, H3）
- 根据标题层级生成树形目录结构
- 目录项包含标题文本和对应的锚点 ID

### 2. 目录显示
- 在页面左侧固定显示目录
- 响应式设计：移动端可折叠或隐藏
- 根据标题层级进行缩进显示层级关系

### 3. 交互功能
- 点击目录项平滑滚动到对应章节
- 滚动页面时，自动高亮当前所在的章节
- 支持目录的展开/折叠（可选）

## 技术方案

### 1. HTML 标题解析

从 `handbook.rendered_content`（后端已渲染的 HTML）中解析标题：

```javascript
// 解析 HTML 提取 h1, h2, h3 标题
const parseHeadingsFromHTML = (html) => {
  const parser = new DOMParser()
  const doc = parser.parseFromString(html, 'text/html')
  const headings = doc.querySelectorAll('h1, h2, h3')

  return Array.from(headings).map(heading => {
    let id = heading.id
    // 如果没有 id，自动生成一个
    if (!id) {
      id = generateId(heading.textContent)
      heading.id = id  // 更新 DOM 中的 id
    }
    return {
      level: parseInt(heading.tagName.charAt(1)),
      text: heading.textContent,
      id: id
    }
  })
}

// 生成目录结构
[
  { level: 1, text: 'Chapter 1', id: 'chapter-1' },
  { level: 2, text: 'Section 1.1', id: 'section-1-1' },
  { level: 2, text: 'Section 1.2', id: 'section-1-2' },
  ...
]
```

### 2. 锚点 ID 生成规则

**后端渲染**：如果后端 Markdown 渲染器已自动为标题生成 id（如 `h1 { id: "chapter-1" }`），前端直接使用。

**前端补充**：如果标题没有 id，前端使用以下规则生成：
- 转为小写
- 移除特殊字符
- 空格替换为连字符
- 确保唯一性（添加序号后缀）

```javascript
const generateId = (text, existingIds = new Set()) => {
  let id = text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim()

  // 确保 id 唯一
  let counter = 1
  let uniqueId = id
  while (existingIds.has(uniqueId)) {
    uniqueId = `${id}-${counter}`
    counter++
  }
  existingIds.add(uniqueId)

  return uniqueId
}
```

### 3. UI 布局设计

```
┌─────────────────────────────────────────┐
│  Header (Title + Language Switcher)    │
├──────────────┬──────────────────────────┤
│   TOC        │  Content                │
│   (Left)     │  (Right)                │
│              │                         │
│ • Chapter 1  │  # Chapter 1            │
│   • Sec 1.1  │  ## Section 1.1         │
│   • Sec 1.2  │  Content...             │
│              │                         │
│ • Chapter 2  │  # Chapter 2            │
│   • Sec 2.1  │  ## Section 2.1         │
│              │  Content...             │
│              │                         │
└──────────────┴──────────────────────────┘
```

### 4. 滚动监听与高亮

使用 Intersection Observer 或 scroll 事件监听：
- 监听每个标题元素的可视状态
- 根据当前可视的标题更新目录项的 active 状态

## 前端实现设计

### 1. 组件结构

```vue
<template>
  <div class="handbook-view-container">
    <!-- 左侧目录 -->
    <aside class="handbook-toc" v-if="tableOfContents.length > 0">
      <div class="toc-header">{{ $t('table_of_contents') }}</div>
      <div class="toc-list">
        <div
          v-for="item in tableOfContents"
          :key="item.id"
          :class="['toc-item', `toc-level-${item.level}`, { active: activeItemId === item.id }]"
          @click="scrollToSection(item.id)"
        >
          {{ item.text }}
        </div>
      </div>
    </aside>

    <!-- 右侧内容 -->
    <main class="handbook-content">
      <!-- 现有的 handbook 内容 -->
    </main>
  </div>
</template>
```

### 2. 状态管理

```javascript
const tableOfContents = ref([])      // 目录数据
const activeItemId = ref(null)       // 当前激活的目录项 ID
const tocObserver = ref(null)        // Intersection Observer 实例
```

### 3. 核心函数

```javascript
// 解析 HTML 生成目录
const parseTableOfContents = (htmlContent) => {
  const parser = new DOMParser()
  const doc = parser.parseFromString(htmlContent, 'text/html')
  const headingElements = doc.querySelectorAll('h1, h2, h3')
  const existingIds = new Set()

  const headings = Array.from(headingElements).map(heading => {
    let id = heading.id

    // 如果标题没有 id，自动生成
    if (!id) {
      id = generateId(heading.textContent, existingIds)
      heading.id = id
    }

    existingIds.add(id)

    return {
      level: parseInt(heading.tagName.charAt(1)),
      text: heading.textContent.trim(),
      id: id
    }
  })

  return headings
}

// 生成唯一 ID
const generateId = (text, existingIds = new Set()) => {
  let id = text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim()

  let counter = 1
  let uniqueId = id
  while (existingIds.has(uniqueId)) {
    uniqueId = `${id}-${counter}`
    counter++
  }
  existingIds.add(uniqueId)

  return uniqueId
}

// 滚动到指定章节
const scrollToSection = (id) => {
  const element = document.getElementById(id)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    activeItemId.value = id
  }
}

// 设置滚动监听
const setupScrollObserver = () => {
  // 在组件挂载后，监听渲染的 HTML 中的标题
  const contentElement = document.querySelector('.markdown-body')
  if (!contentElement) return

  const headings = contentElement.querySelectorAll('h1, h2, h3')

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        activeItemId.value = entry.target.id
      }
    })
  }, {
    rootMargin: '-20% 0px -70% 0px',
    threshold: 0
  })

  headings.forEach(heading => observer.observe(heading))
  tocObserver.value = observer
}
```

### 4. 样式设计

```scss
.handbook-view-container {
  display: grid;
  grid-template-columns: 250px 1fr;
  gap: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.handbook-toc {
  position: sticky;
  top: 2rem;
  height: fit-content;
  max-height: calc(100vh - 4rem);
  overflow-y: auto;
}

.toc-item {
  padding: 0.5rem;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s;

  &.toc-level-1 {
    font-weight: 600;
    margin-top: 0.5rem;
  }

  &.toc-level-2 {
    padding-left: 1.5rem;
    font-size: 0.9rem;
  }

  &.toc-level-3 {
    padding-left: 2.5rem;
    font-size: 0.85rem;
  }

  &.active {
    background-color: #eff6ff;
    color: #2563eb;
    border-left: 3px solid #2563eb;
  }

  &:hover:not(.active) {
    background-color: #f3f4f6;
  }
}

// 响应式：移动端隐藏目录
@media (max-width: 768px) {
  .handbook-view-container {
    grid-template-columns: 1fr;
  }

  .handbook-toc {
    display: none;
  }
}
```

## 后端调整

### 当前渲染实现分析

根据 `backend/src/server/api/v1.ts:1836-2080`，当前使用 `markdown-it` 渲染 Markdown：

```javascript
const md = new MarkdownIt({
  html: true,
  breaks: true,
  linkify: false
})
```

**问题**：默认配置不会自动为标题生成 id 属性，需要前端手动补充。

### 推荐方案：后端添加标题 id 生成

使用 `markdown-it-anchor` 插件自动为标题生成 id：

```javascript
import MarkdownIt from 'markdown-it'
import anchor from 'markdown-it-anchor'

const md = new MarkdownIt({
  html: true,
  breaks: true,
  linkify: false
}).use(anchor, {
  level: [1, 2, 3],  // 只为 h1, h2, h3 生成 id
  slugify: (s) => s
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim(),
  permalink: false  // 不显示可点击的 permalink 符号
})
```

这样渲染后的 HTML 将包含带 id 的标题：

```html
<h1 id="chapter-1">Chapter 1</h1>
<h2 id="section-1-1">Section 1.1</h2>
<h3 id="section-1-1-1">Subsection 1.1.1</h3>
```

### 备选方案：前端补充 id

如果后端暂时未添加插件，前端会自动补充（如上文 `parseHeadingsFromHTML` 所示），但这样会增加前端负担且无法利用缓存。

## 国际化

在语言文件中添加：

```json
{
  "table_of_contents": "目錄",
  "toc_collapse": "收起目錄",
  "toc_expand": "展開目錄"
}
```

## 开发计划 (Implementation Steps)

1. **解析逻辑**
   - [ ] 实现 `parseTableOfContents` 函数
   - [ ] 实现 `generateId` 函数

2. **UI 组件**
   - [ ] 添加左侧目录 aside 组件
   - [ ] 调整布局为两栏结构
   - [ ] 实现目录项的样式（不同层级）

3. **交互功能**
   - [ ] 实现点击目录项跳转
   - [ ] 实现滚动监听与高亮
   - [ ] 平滑滚动效果

4. **响应式适配**
   - [ ] 移动端隐藏或折叠目录
   - [ ] 目录粘性定位优化

5. **测试与优化**
   - [ ] 测试各种 Markdown 标题格式
   - [ ] 性能优化（防抖、节流）
   - [ ] 边界情况处理（无标题、标题重复）

## 注意事项

1. **标题唯一性**：确保生成的 ID 唯一，避免重复导致跳转错误（前端生成时已处理）
2. **后端渲染时机**：目录解析应在 `handbook.rendered_content` 加载完成后进行
3. **DOM 操作**：解析 HTML 后可能需要更新 DOM 中标题的 id（如果后端未生成）
4. **性能考虑**：长手册可能有很多标题，使用 Intersection Observer 优化性能
5. **兼容性**：确保与现有的词句嵌入功能（`{{exp:...}}`）不冲突
6. **HTML 清理**：使用 DOMParser 解析 HTML，需确保安全性（已通过后端渲染保障）

## 扩展功能（可选）

- 目录折叠/展开功能
- 阅读进度条
- 目录搜索功能
- 自定义目录样式配置
