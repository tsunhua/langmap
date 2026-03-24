# 前端動態語言支持

## System Reminder

**設計來源**：本實現基於代碼庫實際實現狀態

**實現狀態**：
- ✅ 靜態語言加載（en, zh-CN, zh-TW, es, fr, ja, nan-TW, yue-HK）- 已實現
- ✅ 語言服務基礎實現 - 已實現（fetchLanguages, fetchUITranslations）
- ✅ 動態 i18n 加載增強 - 已實現（混合模式）
- ✅ 後端 L1 語言緩存 (30min) - 已實現 (D1DatabaseService)
- ⏳ 用戶自定義語言創建 - 部分實現（UI 未完全實現）
- ❌ 語言切換完整流程 - 部分實現（偏好保存、緩存更新）

**已實現的功能**：
- 應用啓動時從後端獲取語言列表
- 靜態語言從配置加載
- 動態語言從後端獲取（通過 meanings）
- 翻譯緩存機制（內存緩存）
- "添加新語言"功能（基礎）

**未實現的功能**：
- 按需加載（per-component lazy loading）
- localStorage 持久化緩存
- 緩存過期機制（24小時）
- 強制刷新功能
- 用戶自定義語言創建完整流程
- 離線支持
- 性能監控和優化

---

## 概述

前端動態語言支持的實現，允許應用程序從後端動態加載語言和翻譯，支持用戶貢獻的語言和翻譯。

## 實現詳情

### 1. 語言服務

語言服務（`src/services/languageService.js`）提供與後端 API 通信的功能：

- `fetchLanguages()` - 從後端獲取所有可用語言
- `fetchUITranslations(languageCode)` - 按含義獲取特定語言的 UI 翻譯
- `createLanguage(languageData)` - 在系統中創建新語言
- `transformTranslations(expressions)` - 將扁平的表達式列錶轉換爲嵌套的 i18n 消息對象

### 2. 動態 i18n 加載

i18n 模塊（`src/i18n.js`）已增強以支持動態語言加載：

1. **靜態語言**：從現有配置加載
2. **動態語言**：需要時從後端獲取
3. **翻譯緩存**：防止對同一語言重複請求後端
4. **回退機制**：確保即使動態翻譯加載失敗，應用也能繼續工作

### 3. 應用組件增強

App 組件（`src/App.vue`）已更新：

1. **應用啓動時動態語言列表加載**：從後端獲取
2. **合併到可用語言列表**：將靜態和動態語言合併
3. **加載用戶偏好語言**：從 localStorage 獲取或使用默認語言
4. **語言切換**：支持靜態和動態語言
5. **"添加新語言"功能**：允許用戶貢獻新語言

### 4. 技術架構

**數據流**
```
應用啓動
  → 加載靜態語言配置
  → 從後端獲取動態語言列表
  → 合併語言列表
  → 加載用戶偏好語言
  → 初始化 i18n

語言切換
  → 用戶選擇新語言
  → 檢查是否爲靜態語言
    → 是：從配置加載
    → 否：從後端獲取翻譯
  → 更新 i18n 實例
  → 保存偏好到 localStorage
```

### 5. 集成與 Vue Router

實現與 Vue Router 無縫集成，確保在導航期間保持語言偏好：

1. 語言切換時保存到 localStorage
2. 路由變化時檢查語言偏好
3. 保持語言狀態同步

### 6. 緩存策略

翻譯緩存在內存中以防止對同一語言重複請求後端：

1. 當動態語言首次加載時，其翻譯存儲在 `dynamicMessagesCache`
2. 後續對同一語言的請求使用緩存數據
3. 緩存在應用會話期間維護
4. **後端優化**：後端 D1DatabaseService 實施了 30 分鐘的 L1 內存緩存，並在邊緣側集成了 L2 緩存 (1小時)，確保即使動態加載也能秒開。

### 7. 錯誤處理

1. 翻譯加載失敗時回退到英文
2. 網絡錯誤記錄到控制臺用於調試
3. 關鍵操作（如添加語言）的用戶友好錯誤消息
4. 即使動態語言加載失敗，應用也能繼續工作

### 8. API 集成

前端與這些後端端點通信：

**GET /api/v1/languages**
獲取所有可用語言

響應：
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
按含義獲取特定語言的 UI 翻譯

響應：
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
創建新語言

請求：
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

響應：
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

### 9. 未來改進

1. **持久化緩存**：將翻譯存儲在 localStorage 中以過期時間戳
2. **懶加載**：按需加載每個組件的翻譯，而不是全部加載
3. **離線支持**：緩存翻譯用於離線使用場景
4. **翻譯管理 UI**：爲用戶貢獻翻譯提供界面
5. **語言包**：捆綁常用語言用於離線優先場景
6. **性能監控**：跟蹤翻譯加載時間並相應優化
7. **端到端測試**：爲關鍵函數添加單元測試，以驗證完整的動態加載工作流

### 10. 測試

已爲語言服務中的關鍵函數添加了單元測試，特別是轉換邏輯。應添加端到端測試以驗證完整的動態加載工作流。
