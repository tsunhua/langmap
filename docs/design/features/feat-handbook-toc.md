# Handbook 目錄 (Table of Contents) 功能設計

## System Reminder

**設計來源**：根據用戶需求（在 HandbookView.vue 頁面左側顯示手冊目錄）設計。

**實現狀態**：⏸️ 待實現

---

## 概述

在 HandbookView.vue 頁面左側添加目錄（Table of Contents）功能，方便用戶快速導航到手冊的不同章節。

目錄會自動從 Markdown 內容中解析出各級標題（H1-H3），生成樹形結構，支持點擊跳轉和滾動高亮。

## 功能需求

### 1. 目錄生成
- 自動解析 Markdown 內容中的標題（H1, H2, H3）
- 根據標題層級生成樹形目錄結構
- 目錄項包含標題文本和對應的錨點 ID

### 2. 目錄顯示
- 在頁面左側固定顯示目錄
- 響應式設計：移動端可摺疊或隱藏
- 根據標題層級進行縮進顯示層級關係

### 3. 交互功能
- 點擊目錄項平滑滾動到對應章節
- 滾動頁面時，自動高亮當前所在的章節
- 支持目錄的展開/摺疊（可選）

## 技術方案

### 1. HTML 標題解析

從 `handbook.rendered_content`（後端已渲染的 HTML）中解析標題：

```javascript
// 解析 HTML 提取 h1, h2, h3 標題
const parseHeadingsFromHTML = (html) => {
  const parser = new DOMParser()
  const doc = parser.parseFromString(html, 'text/html')
  const headings = doc.querySelectorAll('h1, h2, h3')

  return Array.from(headings).map(heading => {
    let id = heading.id
    // 如果沒有 id，自動生成一個
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

// 生成目錄結構
[
  { level: 1, text: 'Chapter 1', id: 'chapter-1' },
  { level: 2, text: 'Section 1.1', id: 'section-1-1' },
  { level: 2, text: 'Section 1.2', id: 'section-1-2' },
  ...
]
```

### 2. 錨點 ID 生成規則

**後端渲染**：如果後端 Markdown 渲染器已自動爲標題生成 id（如 `h1 { id: "chapter-1" }`），前端直接使用。

**前端補充**：如果標題沒有 id，前端使用以下規則生成：
- 轉爲小寫
- 移除特殊字符
- 空格替換爲連字符
- 確保唯一性（添加序號後綴）

```javascript
const generateId = (text, existingIds = new Set()) => {
  let id = text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim()

  // 確保 id 唯一
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

### 3. UI 布局設計

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

### 4. 滾動監聽與高亮

使用 Intersection Observer 或 scroll 事件監聽：
- 監聽每個標題元素的可視狀態
- 根據當前可視的標題更新目錄項的 active 狀態

## 前端實現設計

### 1. 組件結構

```vue
<template>
  <div class="handbook-view-container">
    <!-- 左側目錄 -->
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

    <!-- 右側內容 -->
    <main class="handbook-content">
      <!-- 現有的 handbook 內容 -->
    </main>
  </div>
</template>
```

### 2. 狀態管理

```javascript
const tableOfContents = ref([])      // 目錄數據
const activeItemId = ref(null)       // 當前激活的目錄項 ID
const tocObserver = ref(null)        // Intersection Observer 實例
```

### 3. 核心函數

```javascript
// 解析 HTML 生成目錄
const parseTableOfContents = (htmlContent) => {
  const parser = new DOMParser()
  const doc = parser.parseFromString(htmlContent, 'text/html')
  const headingElements = doc.querySelectorAll('h1, h2, h3')
  const existingIds = new Set()

  const headings = Array.from(headingElements).map(heading => {
    let id = heading.id

    // 如果標題沒有 id，自動生成
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

// 滾動到指定章節
const scrollToSection = (id) => {
  const element = document.getElementById(id)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    activeItemId.value = id
  }
}

// 設置滾動監聽
const setupScrollObserver = () => {
  // 在組件掛載後，監聽渲染的 HTML 中的標題
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

### 4. 樣式設計

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

// 響應式：移動端隱藏目錄
@media (max-width: 768px) {
  .handbook-view-container {
    grid-template-columns: 1fr;
  }

  .handbook-toc {
    display: none;
  }
}
```

## 後端調整

### 當前渲染實現分析

根據 `backend/src/server/api/v1.ts:1836-2080`，當前使用 `markdown-it` 渲染 Markdown：

```javascript
const md = new MarkdownIt({
  html: true,
  breaks: true,
  linkify: false
})
```

**問題**：默認配置不會自動爲標題生成 id 屬性，需要前端手動補充。

### 推薦方案：後端添加標題 id 生成

使用 `markdown-it-anchor` 插件自動爲標題生成 id：

```javascript
import MarkdownIt from 'markdown-it'
import anchor from 'markdown-it-anchor'

const md = new MarkdownIt({
  html: true,
  breaks: true,
  linkify: false
}).use(anchor, {
  level: [1, 2, 3],  // 只爲 h1, h2, h3 生成 id
  slugify: (s) => s
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim(),
  permalink: false  // 不顯示可點擊的 permalink 符號
})
```

這樣渲染後的 HTML 將包含帶 id 的標題：

```html
<h1 id="chapter-1">Chapter 1</h1>
<h2 id="section-1-1">Section 1.1</h2>
<h3 id="section-1-1-1">Subsection 1.1.1</h3>
```

### 備選方案：前端補充 id

如果後端暫時未添加插件，前端會自動補充（如上文 `parseHeadingsFromHTML` 所示），但這樣會增加前端負擔且無法利用緩存。

## 國際化

在語言文件中添加：

```json
{
  "table_of_contents": "目錄",
  "toc_collapse": "收起目錄",
  "toc_expand": "展開目錄"
}
```

## 開發計劃 (Implementation Steps)

1. **解析邏輯**
   - [ ] 實現 `parseTableOfContents` 函數
   - [ ] 實現 `generateId` 函數

2. **UI 組件**
   - [ ] 添加左側目錄 aside 組件
   - [ ] 調整布局爲兩欄結構
   - [ ] 實現目錄項的樣式（不同層級）

3. **交互功能**
   - [ ] 實現點擊目錄項跳轉
   - [ ] 實現滾動監聽與高亮
   - [ ] 平滑滾動效果

4. **響應式適配**
   - [ ] 移動端隱藏或摺疊目錄
   - [ ] 目錄粘性定位優化

5. **測試與優化**
   - [ ] 測試各種 Markdown 標題格式
   - [ ] 性能優化（防抖、節流）
   - [ ] 邊界情況處理（無標題、標題重複）

## 注意事項

1. **標題唯一性**：確保生成的 ID 唯一，避免重複導致跳轉錯誤（前端生成時已處理）
2. **後端渲染時機**：目錄解析應在 `handbook.rendered_content` 加載完成後進行
3. **DOM 操作**：解析 HTML 後可能需要更新 DOM 中標題的 id（如果後端未生成）
4. **性能考慮**：長手冊可能有很多標題，使用 Intersection Observer 優化性能
5. **兼容性**：確保與現有的詞句嵌入功能（`{{exp:...}}`）不衝突
6. **HTML 清理**：使用 DOMParser 解析 HTML，需確保安全性（已通過後端渲染保障）

## 擴展功能（可選）

- 目錄摺疊/展開功能
- 閱讀進度條
- 目錄搜索功能
- 自定義目錄樣式配置
