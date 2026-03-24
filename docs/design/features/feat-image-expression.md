# 圖片詞句功能設計

## System Reminder

**實現狀態**：
- ✅ R2 存儲桶/目錄配置（圖片用）已設置
- ✅ 預籤名 URL API 已實現
- ✅ 前端圖片上傳組件已實現
- ✅ 前端圖片壓縮邏輯已實現
- ✅ 數據庫 `language_code='image'` 插入已完成
- ✅ 前端根據 language_code 動態切換輸入方式已實現

---

## 1. 背景與目標

爲了豐富 LangMap 的表達形式，支持以圖片作爲詞句的表達方式，系統需要提供圖片上傳、壓縮、存儲和展示功能。

**核心原則**：
- **符合當前架構**：基於 Cloudflare Workers + D1 + R2 + Vue 3 的無服務器應用架構。
- **儘量節約成本**：最小化 Worker 的內存、CPU 和執行時間，充分利用 R2 的免費額度和零下行流量費特性。
- **簡潔實現**：使用 `language_code = "image"` 標識圖片表達式，無需新增字段。

## 2. 存儲與架構設計

### 2.1 架構數據流 (Worker 代理上傳)
 
採用 **Worker 代理上傳至 R2** 的架構。客戶端將壓縮後的圖片發送至 Worker，由 Worker 驗證後寫入 R2。
 
流程如下：
1. **壓縮**：客戶端壓縮圖片（目標 100KB 以內）。
2. **上傳**：客戶端將圖片發送至 `/api/v1/images/upload` 接口。
3. **驗證與存儲**：Worker 接收圖片，驗證用戶權限，並將圖片流直接寫入 R2。
4. **返回**：Worker 返回圖片的公開訪問 URL。
5. **綁定**：客戶端使用返回的 URL 創建表達式記錄。

### 2.2 數據格式與存儲結構

- **Bucket**: Cloudflare R2 存儲 `langmap-images`
- **路徑**: `expressions/{expression_id}/{uuid}.webp`（使用 WebP 格式以獲得更好的壓縮率）
- **格式限制**: 支持 JPG/PNG/WebP，推薦 WebP
- **大小限制**: 壓縮後最大 300KB（預籤名 URL 限制 1MB）

### 2.3 成本優化核心策略

- **零流量費分發**：Cloudflare R2 不收取 Egress（出站流出）費用，完美適配圖片此類讀多寫少、高頻下載場景。
- **邊緣緩存加速**：R2 前置綁定 Cloudflare CDN 自定義域（如 `images.langmap.io`），配置強靜態緩存（`Cache-Control: public, max-age=31536000`）。
- **前端壓縮降低存儲**：客戶端統一壓縮到 600px 寬度，質量 0.7，目標 < 100KB。

## 3. 數據模型設計

### 3.1 Expression 表（復用現有字段）

無需新增字段，使用現有字段標識圖片表達式：

```typescript
interface Expression {
  text: string               // 純文本內容 OR 圖片 URL
  language_code: string      // "en", "zh", "image" 等
  audio_url?: string
  region_code?: string
  // ... 其他現有字段
}
```

### 3.2 數據示例

| language_code | text | 說明 |
|---------------|------|------|
| "en" | "Hello" | 英文文本表達式 |
| "zh" | "你好" | 中文文本表達式 |
| "image" | "https://images.langmap.io/expressions/123/abc.webp" | 圖片表達式 |

### 3.3 數據庫查詢

```sql
-- 查詢所有圖片表達式
SELECT * FROM expressions WHERE language_code = 'image';

-- 查詢特定語言的文本表達式
SELECT * FROM expressions WHERE language_code = 'en';
```

## 4. 前端 UI 與交互設計

### 4.1 表達式創建/編輯頁

根據 language 選擇器動態切換輸入方式：

```
┌─────────────────────────────────────────┐
│  創建表達式                              │
├─────────────────────────────────────────┤
│                                         │
│  語言: [English ▼]                      │
│         [image ▼]  ← 選擇 "image" 時    │
│                                         │
│  [當 language = "image" 時]             │
│  ┌─────────────────────────────────┐   │
│  │  📷 點擊上傳圖片                │   │
│  │  或拖拽圖片到此處               │   │
│  │                                 │   │
│  │  支持格式: JPG, PNG, WebP      │   │
│  │  最大: 5MB (自動壓縮)          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [當 language ≠ "image" 時]            │
│  表達式: [_________________________]    │
│                                         │
│  地域: [United States ▼]               │
│                                         │
│  [取消]  [保存]                         │
└─────────────────────────────────────────┘
```

### 4.2 表達式詳情頁

根據 `language_code` 字段動態展示：

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

    <!-- 其他信息：語言、地域、音頻、含義等 -->
  </div>
</template>
```

### 4.3 圖片上傳交互流程
 
1. **選擇圖片**：用戶點擊上傳區域或拖拽圖片
2. **前端壓縮**：使用 Canvas 自動壓縮圖片到 100KB 以內
3. **預覽確認**：顯示壓縮後的圖片預覽
4. **上傳圖片**：調用 `/api/v1/images/upload` 將壓縮後的圖片發送至 Worker
5. **保存數據**：上傳成功後，保存到數據庫（`language_code='image'`, `text=圖片URL`）
6. **錯誤處理**：任何步驟失敗，允許用戶重新上傳

### 4.4 前端判斷邏輯

```vue
<template>
  <div class="create-expression">
    <label>語言</label>
    <select v-model="form.language_code">
      <option value="en">English</option>
      <option value="zh">中文</option>
      <option value="image">📷 圖片</option>
    </select>

    <div v-if="form.language_code === 'image'">
      <div class="image-upload" @click="triggerFileInput">
        📷 點擊上傳圖片
      </div>
      <input type="file" ref="fileInput" @change="handleImageUpload" accept="image/*" hidden>
    </div>
    <div v-else>
      <input v-model="form.text" placeholder="輸入表達式" />
    </div>
  </div>
</template>
```

## 5. API 接口設計

### 5.1 圖片上傳
 
**Endpoint**: `POST /api/v1/images/upload`
 
**Auth**: 限定已登錄用戶 (`JWT`)
 
**Request**: `multipart/form-data`
- `image_file`: 圖片二進制文件 (Blob)
 
**Response**:
```json
{
  "image_url": "https://images.langmap.io/xxx.webp"
}
```

### 5.2 創建/更新表達式（復用現有接口）

**Endpoint**: `POST /api/v1/expressions`

**Request**（圖片表達式）:
```json
{
  "text": "https://images.langmap.io/expressions/123/xxx.webp",
  "language_code": "image",
  "region_code": null,
  "meaning_id": 456
}
```

**後端驗證**：
- 當 `language_code = "image"` 時，`text` 必須以 `http://` 或 `https://` 開頭
- `region_code` 對於圖片表達式可以爲 `null`
- `text` 必須屬於系統生成的 R2 域名（所有用戶，包括管理員）

## 6. 前端圖片壓縮邏輯

### 6.1 壓縮策略

使用 Canvas API 在瀏覽器端壓縮圖片：

```typescript
async function compressImage(file: File, maxWidth: number = 600, quality: number = 0.7): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => {
      const canvas = document.createElement('canvas')
      let { width, height } = img

      // 按比例縮放到 600px 寬度
      if (width > maxWidth) {
        height = (height * maxWidth) / width
        width = maxWidth
      }

      canvas.width = width
      canvas.height = height

      const ctx = canvas.getContext('2d')!
      ctx.drawImage(img, 0, 0, width, height)

      // 轉換爲 WebP 格式，質量 0.7
      canvas.toBlob(
        (blob) => blob ? resolve(blob) : reject(new Error('壓縮失敗')),
        'image/webp',
        quality
      )
    }
    img.onerror = () => reject(new Error('圖片加載失敗'))
    img.src = URL.createObjectURL(file)
  })
}
```

### 6.2 完整上傳流程
 
```typescript
async function uploadImage(file: File): Promise<string> {
  // 1. 壓縮圖片
  const compressed = await compressImage(file)
 
  // 2. 上傳至 Worker
  const formData = new FormData()
  formData.append('image_file', compressed)
  
  const { image_url } = await fetch('/api/v1/images/upload', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData
  }).then(r => r.json())
 
  return image_url
}
```

### 6.3 壓縮目標

- **格式**: 統一轉換爲 WebP
- **寬度**: 最大 600px
- **質量**: 0.7
- **目標大小**: < 100KB
- **如果壓縮後仍 > 300KB**: 提示用戶選擇其他圖片

### 6.4 顯示樣式

```css
.expression-image {
  width: 100%;
  max-width: 600px;
  height: auto;
  border-radius: 8px;
}
```

## 7. 系統安全與防濫用

### 7.1 速率限制

**預籤名 URL 生成**:
- 普通用戶：每分鐘最多 5 次請求
- 管理員：無限制

**表達式創建**:
- 普通用戶：每分鐘最多 10 次圖片表達式創建
- 管理員：無限制

**實現示例**:
```typescript
function getRateLimit(user: User): { maxRequests: number } {
  if (user.role === 'admin') {
    return { maxRequests: Infinity }
  }
  return { maxRequests: 5 } // 普通用戶限制
}
```

### 7.2 文件驗證

**預籤名 URL Policy**（所有用戶）:
```typescript
const policy = {
  conditions: [
    ['starts-with', '$Content-Type', 'image/'],
    ['content-length-range', 0, 1048576] // 最大 1MB
  ]
}
```

**後端驗證**（保存表達式時，所有用戶）:
```typescript
if (language_code === 'image') {
  if (!text.startsWith('http://') && !text.startsWith('https://')) {
    throw new Error('圖片 URL 格式無效')
  }

  // 所有用戶（包括管理員）都必須使用系統生成的圖片 URL
  if (!text.startsWith('https://images.langmap.io/')) {
    throw new Error('僅允許使用系統生成的圖片 URL')
  }
}
```

### 7.3 孤兒文件清理

通過 Cloudflare Cron Triggers 定期清理未綁定到數據庫的圖片：
- 每日凌晨掃描 R2 中的圖片文件
- 檢查 `expressions` 表中是否存在對應 URL
- 刪除超過 24 小時未綁定的圖片

## 8. 測試策略

### 8.1 單元測試

- **圖片壓縮函數測試**：驗證不同尺寸圖片的壓縮效果
- **URL 解析測試**：驗證圖片 URL 前綴識別邏輯
- **後端驗證測試**：測試域名來源驗證、語言代碼驗證

### 8.2 集成測試

- **完整上傳流程測試**：壓縮 → 預籤名 URL → 直傳 R2 → 保存數據庫
- **API 端點測試**：
  - `POST /api/v1/images/upload-presign`
  - `POST /api/v1/expressions`（圖片表達式）
- **速率限制測試**：驗證普通用戶和管理員的不同限制

### 8.3 前端測試

- **圖片上傳組件測試**：文件選擇、壓縮、預覽
- **語言選擇器測試**：切換到 "image" 時顯示上傳按鈕
- **錯誤處理測試**：文件過大、格式不支持、網絡失敗

### 8.4 邊界測試

- 圖片壓縮後仍超大的處理
- 網絡中斷後的重試機制
- R2 上傳成功但數據庫保存失敗的回滾

## 9. 部署說明

### 9.1 R2 配置

**創建 Bucket**:
```bash
wrangler r2 bucket create langmap-images
```

**配置自定義域名**（可選但推薦）:
- 在 Cloudflare Dashboard 中綁定自定義域名（如 `images.langmap.io`）
- 配置 CDN 緩存規則：`Cache-Control: public, max-age=31536000`

### 9.2 數據庫遷移

添加語言 "image" 到 `languages` 表:
```sql
INSERT INTO languages (code, name, direction, is_active, region_code, region_name, created_by, updated_by)
VALUES ('image', 'Image', 'ltr', 1, NULL, NULL, 'system', 'system');
```

### 9.3 環境變量

在 `wrangler.toml` 中添加:
```toml
[vars]
R2_IMAGES_BUCKET = "langmap-images"
IMAGES_PUBLIC_URL = "https://images.langmap.io"
```

### 9.4 Cron Trigger（可選）

設置孤兒文件清理任務:
```toml
[[triggers.crons]]
cron = "0 0 * * *"  # 每日凌晨執行
```

## 10. 相關文檔

- [系統架構設計](../system/architecture.md)
- [詞條錄音與上傳功能設計](./feat-audio-upload.md)
- [數據庫設計](./feat-database.md)
- [搜索功能設計](./feat-search.md)

## 11. 部署記錄

**日期**：2026-03-23
**版本**：v1.0.0

**完成事項**：
- R2 bucket 創建完成
- API 端點部署完成
- 前端組件集成完成
- 數據庫遷移完成
- 前端構建測試通過

**已知限制**：
- 圖片最大尺寸限制爲 600px 寬度
- 壓縮質量固定爲 0.7
- 預籤名 URL 有效期爲 5 分鐘
- 普通用戶速率限制：5 次/分鐘（預籤名），10 次/分鐘（創建）
