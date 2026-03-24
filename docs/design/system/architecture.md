# 系統總體架構設計

## 技術棧（已實現）

### 前端
- Vue 3 + Vite
- vue-i18n (國際化)
- Tailwind CSS (樣式)
- Leaflet + OpenStreetMap (地圖)

### 後端
- Hono + TypeScript
- Cloudflare Workers (無服務器運行時)
- JWT 認證
- bcrypt 密碼加密
- Resend (郵件服務)

### 數據庫
- Cloudflare D1 (SQLite 兼容邊緣數據庫)
- Cloudflare R2 (對象存儲，用於導出功能)
- Cloudflare KV (緩存和會話存儲，可選)

**詳細設計**：完整的數據庫設計、表結構、索引策略、性能優化等內容，請參見 [feat-database.md](features/feat-database.md)

### 部署
- Wrangler CLI (Cloudflare Workers 開發和部署工具)
- GitHub Actions (CI/CD)

## 數據模型（已實現）

### 核心表

**注意**：以下列出了所有核心表的簡要說明。完整的數據庫設計（包括詳細字段、索引、遷移策略、性能優化等），請參見 [feat-database.md](features/feat-database.md)

**Expression 表** - 表達式主表
- 存儲當前活動的表達式版本
- 字段：id, text, meaning_id, audio_url, language_code, region_code, region_name, region_latitude, region_longitude, tags, source_type, source_ref, review_status, created_by, created_at, updated_by, updated_at

**ExpressionVersion 表** - 版本歷史表
- 採用追加寫（append-only）模式記錄每次變更
- 字段：id, expression_id, text, meaning_id, audio_url, region_name, region_latitude, region_longitude, created_by, created_at
- 注意：實際實現中沒有 `parent_version_id` 字段

**Meaning 表** - 語義表
- 字段：id, gloss, description, tags, created_by, created_at

**ExpressionMeaning 表** - 表達式-語義關聯表
- 字段：id, expression_id, meaning_id, created_by, created_at, note
- 注意：包含了 `parent_version_id` 字段，但當前版本系統未使用

**User 表** - 用戶表
- 字段：id, username, email, password_hash, role, email_verified, created_at, updated_at

**Language 表** - 語言表
- 字段：id, code, name, direction, is_active, region_code, region_name, region_latitude, region_longitude, created_by, updated_at

**Collection 表** - 集合表
- 字段：id, user_id, name, description, is_public, created_at, updated_at

**CollectionItem 表** - 集合項目表
- 字段：id, collection_id, expression_id, note, created_at

## API 端點

### 已實現的端點

**語言管理**
- `GET /api/v1/languages` - 獲取支持的語言列表
- `GET /api/v1/languages?is_active=1` - 獲取激活的語言

**表達式管理**
- `GET /api/v1/expressions` - 獲取表達式列表（支持過濾）
- `GET /api/v1/expressions/:id` - 獲取表達式詳情
- `POST /api/v1/expressions` - 創建表達式
- `GET /api/v1/expressions/:id/versions` - ⚠️ 已實現 - 獲取表達式版本歷史
- `GET /api/v1/expressions/:id/meanings` - 獲取表達式含義

**語義管理**
- `POST /api/v1/meanings` - 創建含義
- `POST /api/v1/meanings/:id/link` - 關聯表達式與含義

**用戶認證**
- `POST /api/v1/auth/register` - 用戶註冊
- `POST /api/v1/auth/login` - 用戶登錄
- `POST /api/v1/auth/logout` - 用戶登出

**統計和熱力圖**
- `GET /api/v1/statistics` - 獲取系統統計信息
- `GET /api/v1/heatmap` - 獲取熱力圖數據

**搜索**
- `GET /api/v1/search` - 搜索表達式（支持關鍵詞、語言、地域過濾）

**集合管理**
- `GET /api/v1/collections` - 獲取集合列表
- `POST /api/v1/collections` - 創建集合
- `GET /api/v1/collections/:id` - 獲取集合詳情
- `PUT /api/v1/collections/:id` - 更新集合
- `DELETE /api/v1/collections/:id` - 刪除集合
- `GET /api/v1/collections/:id/items` - 獲取集合內容
- `POST /api/v1/collections/:id/items` - 添加內容到集合
- `DELETE /api/v1/collections/:id/items/:expressionId` - 從集合移除內容

### 未實現或部分實現的端點

**版本歷史相關**
- `GET /api/v1/expressions/:id/versions/:vid` - ❌ 未實現 - 無法獲取單個版本的詳細信息
- `PATCH /api/v1/expressions/:id` - ⚠️ 僅定義未實現 - 沒有專門的編輯和版本創建端點
- `POST /api/v1/expressions/:id/versions/:vid/revert` - ❌ 未實現 - 缺少版本回滾功能
- `GET /api/v1/expressions/:id/diff?from=vid1&to=vid2` - ❌ 未實現 - 沒有版本差異比較 API

**AI 建議**
- `POST /api/v1/ai/suggest` - ❌ 未實現 - AI 生成表達式建議

**用戶管理**
- `GET /api/v1/users/me` - ✅ 已實現 - 獲取當前用戶信息
- `PUT /api/v1/users/:id/role` - ❌ 未實現 - 更新用戶角色（僅超級管理員）

**內容審核**
- `PUT /api/v1/expressions/:id/revision/:revision_id/approve` - ❌ 未實現 - 審核內容修改

**UI 翻譯**
- `POST /api/v1/ui-translations/:language` - ✅ 已實現 - 保存 UI 翻譯

**郵件驗證**
- `GET /api/v1/auth/verify-email` - ⚠️ 部分實現 - 文檔已設計，端點可能已實現需確認
- `POST /api/v1/auth/resend-verification` - ❌ 未實現 - 重發驗證郵件

**搜索**
- `GET /api/v1/search` - ✅ 已實現 - 搜索表達式（支持關鍵詞、語言、地域過濾）
- **詳細設計**：參見 [feat-search.md](features/feat-search.md)

**地域查詢**
- `GET /api/v1/regions?near=lat,lng&max_level=town` - ❌ 未實現 - 地域選擇器

**導出功能**
- `POST /api/v1/export` - ❌ 未實現 - 發起導出
- `GET /api/v1/export/:jobId` - ❌ 未實現 - 查詢導出狀態

## 版本歷史實現狀態

### 數據模型
- ✅ 已實現版本存儲（`ExpressionVersion` 表）
- ✅ 已實現版本查詢 API
- ⚠️ `Expression` 表不包含 `current_version_id` 外鍵
- ❌ `ExpressionVersion` 缺少 `parent_version_id` 字段
- ❌ `ExpressionVersion` 缺少 `source_type`, `review_status`, `auto_approved` 字段

### API 端點
- ✅ `GET /api/v1/expressions/:expr_id/versions` - 已實現
- ❌ `GET /api/v1/expressions/:expr_id/versions/:vid` - 未實現
- ⚠️ `PATCH /api/v1/expressions/:id` - 僅定義未實現
- ❌ `POST /api/v1/expressions/:id/versions/:vid/revert` - 未實現
- ❌ `GET /api/v1/expressions/:id/diff` - 未實現

### 前端
- ✅ `VersionHistory.vue` 組件已實現
- ❌ 變更摘要功能未實現
- ❌ 差異預覽功能未實現

### 關鍵差異

| 設計預期 | 實際實現 |
|---------|---------|
| `Expression` 表包含 `current_version_id` 外鍵 | `Expression` 表直接存儲當前數據 |
| `ExpressionVersion` 包含 `parent_version_id` | `parent_version_id` 字段不存在 |
| 支持版本回滾和 diff 比較 | 相關 API 端點和功能尚未實現 |
| 用戶編輯需審核後才成爲當前版本 | 當前實現中，任何編輯都會立即成爲當前版本 |

## 核心頁面

### 已實現
- 首頁：表達式展示和語言統計（包含熱力圖可視化）
- 查詢詞條頁面：搜索和瀏覽表達式
- 表達式詳情頁：顯示表達式信息、關聯翻譯、版本歷史
- 集合頁面：創建和管理收藏集
- 用戶認證頁面：登錄和註冊

### 未實現
- AI 補全功能界面
- 地域選擇器

## 架構特點

### 已實現
- 無服務器架構（Cloudflare Workers）
- 邊緣數據庫（D1）
- 邊緣對象存儲（R2，用於導出）
- JWT 認證
- 前後端分離
- 版本歷史追蹤

### 設計中但未實現
- 實時地理空間查詢（PostGIS）
- 高並發檢索（Typesense/Elasticsearch）
- 異步任務隊列（Durable Objects 用於導出）
- 分布式緩存（KV 存儲）

## 相關文檔

- [功能模塊設計](../features/)
- [API 文檔](../../api/)
- [實施指南](../../guides/)
