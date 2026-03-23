# 图片词句功能设计

## System Reminder

**实现状态**：
- ✅ R2 存储桶/目录配置（图片用）已设置
- ✅ 预签名 URL API 已实现
- ✅ 前端图片上传组件已实现
- ✅ 前端图片压缩逻辑已实现
- ✅ 数据库 `language_code='image'` 插入已完成
- ✅ 前端根据 language_code 动态切换输入方式已实现

---

## 1. 背景与目标

为了丰富 LangMap 的表达形式，支持以图片作为词句的表达方式，系统需要提供图片上传、压缩、存储和展示功能。

**核心原则**：
- **符合当前架构**：基于 Cloudflare Workers + D1 + R2 + Vue 3 的无服务器应用架构。
- **尽量节约成本**：最小化 Worker 的内存、CPU 和执行时间，充分利用 R2 的免费额度和零下行流量费特性。
- **简洁实现**：使用 `language_code = "image"` 标识图片表达式，无需新增字段。

## 2. 存储与架构设计

### 2.1 架构数据流 (S3-compatible Presigned URL 直传)

采用 **客户端直传 R2 (Direct to R2 via Presigned URL)** 的架构，避免图片流经过 Cloudflare Worker 带来的带宽高负荷和执行时间消耗。

流程如下：
1. **申请**：客户端请求 Worker 获取 R2 上传预签名 URL (Presigned URL)。
2. **压缩与直传**：客户端压缩图片（目标 100KB 以内），使用预签名 URL 直接上传至 R2。
3. **绑定**：上传成功后，回传结果给 Worker，创建表达式记录。

### 2.2 数据格式与存储结构

- **Bucket**: Cloudflare R2 存储 `langmap-images`
- **路径**: `expressions/{expression_id}/{uuid}.webp`（使用 WebP 格式以获得更好的压缩率）
- **格式限制**: 支持 JPG/PNG/WebP，推荐 WebP
- **大小限制**: 压缩后最大 300KB（预签名 URL 限制 1MB）

### 2.3 成本优化核心策略

- **零流量费分发**：Cloudflare R2 不收取 Egress（出站流出）费用，完美适配图片此类读多写少、高频下载场景。
- **边缘缓存加速**：R2 前置绑定 Cloudflare CDN 自定义域（如 `images.langmap.io`），配置强静态缓存（`Cache-Control: public, max-age=31536000`）。
- **前端压缩降低存储**：客户端统一压缩到 600px 宽度，质量 0.7，目标 < 100KB。

## 3. 数据模型设计

### 3.1 Expression 表（复用现有字段）

无需新增字段，使用现有字段标识图片表达式：

```typescript
interface Expression {
  text: string               // 纯文本内容 OR 图片 URL
  language_code: string      // "en", "zh", "image" 等
  audio_url?: string
  region_code?: string
  // ... 其他现有字段
}
```

### 3.2 数据示例

| language_code | text | 说明 |
|---------------|------|------|
| "en" | "Hello" | 英文文本表达式 |
| "zh" | "你好" | 中文文本表达式 |
| "image" | "https://images.langmap.io/expressions/123/abc.webp" | 图片表达式 |

### 3.3 数据库查询

```sql
-- 查询所有图片表达式
SELECT * FROM expressions WHERE language_code = 'image';

-- 查询特定语言的文本表达式
SELECT * FROM expressions WHERE language_code = 'en';
```

## 4. 前端 UI 与交互设计

### 4.1 表达式创建/编辑页

根据 language 选择器动态切换输入方式：

```
┌─────────────────────────────────────────┐
│  创建表达式                              │
├─────────────────────────────────────────┤
│                                         │
│  语言: [English ▼]                      │
│         [image ▼]  ← 选择 "image" 时    │
│                                         │
│  [当 language = "image" 时]             │
│  ┌─────────────────────────────────┐   │
│  │  📷 点击上传图片                │   │
│  │  或拖拽图片到此处               │   │
│  │                                 │   │
│  │  支持格式: JPG, PNG, WebP      │   │
│  │  最大: 5MB (自动压缩)          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [当 language ≠ "image" 时]            │
│  表达式: [_________________________]    │
│                                         │
│  地域: [United States ▼]               │
│                                         │
│  [取消]  [保存]                         │
└─────────────────────────────────────────┘
```

### 4.2 表达式详情页

根据 `language_code` 字段动态展示：

```vue
<template>
  <div class="expression-detail">
    <div v-if="expression.language_code === 'image'">
      <img
        :src="expression.text"
        class="expression-image"
        style="width: 100%; max-width: 600px; height: auto;"
        alt="Expression image"
      />
    </div>
    <div v-else>
      <h1 class="expression-text">{{ expression.text }}</h1>
    </div>

    <!-- 其他信息：语言、地域、音频、含义等 -->
  </div>
</template>
```

### 4.3 图片上传交互流程

1. **选择图片**：用户点击上传区域或拖拽图片
2. **前端压缩**：使用 Canvas 自动压缩图片到 100KB 以内
3. **预览确认**：显示压缩后的图片预览
4. **获取签名**：调用 API 获取 R2 预签名 URL
5. **直传 R2**：使用预签名 URL 上传压缩后的图片
6. **保存数据**：上传成功后，保存到数据库（`language_code='image'`, `text=图片URL`）
7. **错误处理**：任何步骤失败，允许用户重新上传

### 4.4 前端判断逻辑

```vue
<template>
  <div class="create-expression">
    <label>语言</label>
    <select v-model="form.language_code">
      <option value="en">English</option>
      <option value="zh">中文</option>
      <option value="image">📷 图片</option>
    </select>

    <div v-if="form.language_code === 'image'">
      <div class="image-upload" @click="triggerFileInput">
        📷 点击上传图片
      </div>
      <input type="file" ref="fileInput" @change="handleImageUpload" accept="image/*" hidden>
    </div>
    <div v-else>
      <input v-model="form.text" placeholder="输入表达式" />
    </div>
  </div>
</template>
```

## 5. API 接口设计

### 5.1 获取预签名 URL

**Endpoint**: `POST /api/v1/images/upload-presign`

**Auth**: 限定已登录用户 (`JWT`)

**Request Parameters**:
- `content_type`: 图片 MIME 类型（如 `image/webp`）
- `content_length`: 预估文件大小

**Response**:
```json
{
  "upload_url": "https://<r2-bucket>.r2.cloudflarestorage.com/images/expressions/123/xxx.webp?X-Amz-Signature...",
  "image_url": "https://images.langmap.io/expressions/123/xxx.webp",
  "expires_in": 300
}
```

### 5.2 创建/更新表达式（复用现有接口）

**Endpoint**: `POST /api/v1/expressions`

**Request**（图片表达式）:
```json
{
  "text": "https://images.langmap.io/expressions/123/xxx.webp",
  "language_code": "image",
  "region_code": null,
  "meaning_id": 456
}
```

**后端验证**：
- 当 `language_code = "image"` 时，`text` 必须以 `http://` 或 `https://` 开头
- `region_code` 对于图片表达式可以为 `null`
- `text` 必须属于系统生成的 R2 域名（所有用户，包括管理员）

## 6. 前端图片压缩逻辑

### 6.1 压缩策略

使用 Canvas API 在浏览器端压缩图片：

```typescript
async function compressImage(file: File, maxWidth: number = 600, quality: number = 0.7): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      const canvas = document.createElement('canvas')
      let { width, height } = img

      // 按比例缩放到 600px 宽度
      if (width > maxWidth) {
        height = (height * maxWidth) / width
        width = maxWidth
      }

      canvas.width = width
      canvas.height = height

      const ctx = canvas.getContext('2d')!
      ctx.drawImage(img, 0, 0, width, height)

      // 转换为 WebP 格式，质量 0.7
      canvas.toBlob(
        (blob) => blob ? resolve(blob) : reject(new Error('压缩失败')),
        'image/webp',
        quality
      )
    }
    img.onerror = () => reject(new Error('图片加载失败'))
    img.src = URL.createObjectURL(file)
  })
}
```

### 6.2 完整上传流程

```typescript
async function uploadImage(file: File): Promise<string> {
  // 1. 压缩图片
  const compressed = await compressImage(file)

  // 2. 获取预签名 URL
  const { upload_url, image_url } = await fetch('/api/v1/images/upload-presign', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      content_type: compressed.type,
      content_length: compressed.size
    })
  }).then(r => r.json())

  // 3. 直传 R2
  await fetch(upload_url, {
    method: 'PUT',
    body: compressed
  })

  return image_url
}
```

### 6.3 压缩目标

- **格式**: 统一转换为 WebP
- **宽度**: 最大 600px
- **质量**: 0.7
- **目标大小**: < 100KB
- **如果压缩后仍 > 300KB**: 提示用户选择其他图片

### 6.4 显示样式

```css
.expression-image {
  width: 100%;
  max-width: 600px;
  height: auto;
  border-radius: 8px;
}
```

## 7. 系统安全与防滥用

### 7.1 速率限制

**预签名 URL 生成**:
- 普通用户：每分钟最多 5 次请求
- 管理员：无限制

**表达式创建**:
- 普通用户：每分钟最多 10 次图片表达式创建
- 管理员：无限制

**实现示例**:
```typescript
function getRateLimit(user: User): { maxRequests: number } {
  if (user.role === 'admin') {
    return { maxRequests: Infinity }
  }
  return { maxRequests: 5 } // 普通用户限制
}
```

### 7.2 文件验证

**预签名 URL Policy**（所有用户）:
```typescript
const policy = {
  conditions: [
    ['starts-with', '$Content-Type', 'image/'],
    ['content-length-range', 0, 1048576] // 最大 1MB
  ]
}
```

**后端验证**（保存表达式时，所有用户）:
```typescript
if (language_code === 'image') {
  if (!text.startsWith('http://') && !text.startsWith('https://')) {
    throw new Error('图片 URL 格式无效')
  }

  // 所有用户（包括管理员）都必须使用系统生成的图片 URL
  if (!text.startsWith('https://images.langmap.io/')) {
    throw new Error('仅允许使用系统生成的图片 URL')
  }
}
```

### 7.3 孤儿文件清理

通过 Cloudflare Cron Triggers 定期清理未绑定到数据库的图片：
- 每日凌晨扫描 R2 中的图片文件
- 检查 `expressions` 表中是否存在对应 URL
- 删除超过 24 小时未绑定的图片

## 8. 测试策略

### 8.1 单元测试

- **图片压缩函数测试**：验证不同尺寸图片的压缩效果
- **URL 解析测试**：验证图片 URL 前缀识别逻辑
- **后端验证测试**：测试域名来源验证、语言代码验证

### 8.2 集成测试

- **完整上传流程测试**：压缩 → 预签名 URL → 直传 R2 → 保存数据库
- **API 端点测试**：
  - `POST /api/v1/images/upload-presign`
  - `POST /api/v1/expressions`（图片表达式）
- **速率限制测试**：验证普通用户和管理员的不同限制

### 8.3 前端测试

- **图片上传组件测试**：文件选择、压缩、预览
- **语言选择器测试**：切换到 "image" 时显示上传按钮
- **错误处理测试**：文件过大、格式不支持、网络失败

### 8.4 边界测试

- 图片压缩后仍超大的处理
- 网络中断后的重试机制
- R2 上传成功但数据库保存失败的回滚

## 9. 部署说明

### 9.1 R2 配置

**创建 Bucket**:
```bash
wrangler r2 bucket create langmap-images
```

**配置自定义域名**（可选但推荐）:
- 在 Cloudflare Dashboard 中绑定自定义域名（如 `images.langmap.io`）
- 配置 CDN 缓存规则：`Cache-Control: public, max-age=31536000`

### 9.2 数据库迁移

添加语言 "image" 到 `languages` 表:
```sql
INSERT INTO languages (code, name, direction, is_active, region_code, region_name, created_by, updated_by)
VALUES ('image', 'Image', 'ltr', 1, NULL, NULL, 'system', 'system');
```

### 9.3 环境变量

在 `wrangler.toml` 中添加:
```toml
[vars]
R2_IMAGES_BUCKET = "langmap-images"
IMAGES_PUBLIC_URL = "https://images.langmap.io"
```

### 9.4 Cron Trigger（可选）

设置孤儿文件清理任务:
```toml
[[triggers.crons]]
cron = "0 0 * * *"  # 每日凌晨执行
```

## 10. 相关文档

- [系统架构设计](../system/architecture.md)
- [词条录音与上传功能设计](./feat-audio-upload.md)
- [数据库设计](./feat-database.md)
- [搜索功能设计](./feat-search.md)

## 11. 部署记录

**日期**：2026-03-23
**版本**：v1.0.0

**完成事项**：
- R2 bucket 创建完成
- API 端点部署完成
- 前端组件集成完成
- 数据库迁移完成
- 前端构建测试通过

**已知限制**：
- 图片最大尺寸限制为 600px 宽度
- 压缩质量固定为 0.7
- 预签名 URL 有效期为 5 分钟
- 普通用户速率限制：5 次/分钟（预签名），10 次/分钟（创建）
