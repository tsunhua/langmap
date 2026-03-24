# 詞條錄音與上傳功能設計

## System Reminder

**實現狀態**：
- ❌ R2 存儲桶/目錄配置（音頻用）未設置
- ❌ 預籤名 URL API 未實現
- ❌ 前端錄音組件未實現
- ❌ 數據庫 `audio_url` 更新邏輯未完全對接

---

## 1. 背景與目標

爲了豐富 LangMap 的語言數據，幫助學習者更好地掌握不同地區語言的真實發音，系統需要提供詞條發音的錄音和上傳功能。
**核心原則**：
- **符合當前架構**：基於 Cloudflare Workers + D1 + R2 + Vue 3 的無服務器應用架構。
- **儘量節約成本**：最小化 Worker 的內存、CPU 和執行時間，充分利用 R2 的免費額度和零下行流量費特性，規避高昂的大文件處理開銷。
- **符合用戶操作習慣**：迎合移動端和 PC 端用戶的原生習慣，提供即錄、即聽、即傳的順滑無感體驗。

## 2. 存儲與架構設計

### 2.1 架構數據流 (S3-compatible Presigned URL 直傳)
採用 **客戶端直傳 R2 (Direct to R2 via Presigned URL)** 的架構，避免音頻流經過 Cloudflare Worker 帶來的帶寬高負荷和執行時間消耗（突破 Worker Payloads 限制並極大降低請求計費成本）。

流程如下：
1. **申請**：客戶端請求 Worker 獲取 R2 上傳預籤名 URL (Presigned URL)。
2. **直傳**：客戶端使用獲取的預籤名 URL 直接將音頻（如 WebM/MP3）通過 `PUT` 請求上傳至 R2。
3. **綁定**：客戶端判斷長鏈上傳成功後，回傳結果給 Worker，更新 D1 數據庫中該 `expressions` 記錄的 `audio_url`。

### 2.2 數據格式與存儲結構
- **Bucket**: 新的的 Cloudflare R2 存儲 `langmap-audio`。
- **Path Path**: `expressions/{expression_id}/{uuid}.webm`
- **格式限制**: 推薦前端使用瀏覽器原生 `MediaRecorder` API 統一錄製爲 `audio/webm` 或 `audio/mp4`。
- **大小限制**: 強制驗證最大 1MB。一般語言發音不超過 10 秒（50KB-150KB 左右）。

## 3. 成本優化核心策略

- **零流量費分發**：Cloudflare R2 不收取 Egress（出站流出）費用，完美適配語言字典此類具有長尾、讀多寫少、高頻下載場景的音頻業務。
- **邊緣緩存加速**：R2 前置綁定 Cloudflare CDN 自定義域 (如 `audio.langmap.io`)，配置強靜態緩存（`Cache-Control: public, max-age=31536000`）。這可以將絕大多數的 R2 Class B (Read) 操作擋在緩存層外，極大節省 R2 讀取費用。
- **直傳消除計算節點壓力**：將負擔最重的 I/O 上行任務剝離出 Worker 節點，只保留了最廉價的 JSON 計算請求（獲取籤名和更新 DB）。
- **前端預防與截斷**：前端組件設計爲最多錄製 15 秒即自動停止截斷，從源頭避免非預期巨型文件堆積。

## 4. 前端 UI 與交互設計 (符合操作習慣)

界面設計需注重直覺反饋和高容錯率，復刻用戶習慣的主流聊天軟件語音輸入體驗。

### 4.1 UI 表現層
- **詞條詳情頁** 內緊貼發音字符區域，或者在 **創建/編輯詞條表單** 內新增「發音採集」區塊。
- 默認狀態：主要視覺焦點爲一個帶有 🎤 圖標的 **「錄製發音」** 主按鈕。

### 4.2 錄音交互流程
1. **點擊錄音**：用戶點擊 🎤 按鈕，前端請求麥克風權限。獲得權限後，界面自動切換爲「錄音中」狀態，展示心跳波形動效與不斷遞增的計時器 (例如 00:00 / 00:15)。
2. **結束錄製**：再次點擊錄音按鈕（變爲 ⏺ 停止區塊）結束錄製。達到 15 秒上限時則自動觸髮結束。
3. **預覽、重錄與上傳**：錄製完成後進入「待確認」狀態。此時不立刻寫入服務器，而是提供三個直觀選項：
   - **[▶ 聽取]**：播放剛才的錄音，讓用戶確認質量是否合格（無雜音、發音準確）。
   - **[✖ 重錄]**：一鍵丟棄當前緩存並重新開始錄製。
   - **[✔ 確認並上傳]**：發起預籤名流程和文件直傳。
4. **過程反饋**：確認上傳階段展示無極進度條/轉圈動畫。成功後界面刷新，詞條旁直接顯示一個乾淨的迷你音頻播放器。

### 4.3 兼容性與降級機制
- 若檢測到當前運行環境（如舊版瀏覽器、無 HTTPS 等）不支持 `navigator.mediaDevices.getUserMedia`，則提示用戶「當前環境不支持錄音，請使用支持 WebRTC 的現代瀏覽器並確保在 HTTPS 環境下訪問」。

## 5. API 接口設計

### 5.1 獲取預籤名 URL (Worker)
- **Endpoint**: `POST /api/v1/expressions/:id/upload-audio`
- **Auth**: 限定已登錄用戶 (`JWT`)。
- **Request Parameters**:
  - `content_type`: 音頻 MIME 類型（方便生成對應後綴和設頭）。
  - `content_length`: 預估文件大小（用於超限阻斷）。
- **Response**:
  ```json
  {
    "upload_url": "https://<r2-bucket>.r2.cloudflarestorage.com/audio/expressions/123/xxx.webm?X-Amz-Signature...",
    "audio_url": "https://audio.langmap.io/expressions/123/xxx.webm",
    "expires_in": 300
  }
  ```

### 5.2 確認綁定並發布 (Worker + D1)
- **Endpoint**: `PATCH /api/v1/expressions/:id` (復用編輯接口)
- **Request Validation**:
  ```json
  {
    "audio_url": "https://audio.langmap.io/expressions/123/xxx.webm"
  }
  ```
- **業務邏輯**: 
  1. 通過 Session 獲取 User 校驗是否有權限操作。
  2. 將 D1 `expressions` 主表的 `audio_url` 字段更新爲最終 R2 的公網地址。
  3. *(如實現)* 向 `expression_versions` 寫入對應的發音補全歷史版本，確保改動可追溯。

## 6. 安全與防濫用管控

- **請求速率限制 (Rate Limiting)**：在獲取預定義 URL 接口針對 IP/User ID 實施嚴格的頻次限制（如每分鐘最多申請 5 次籤發），防止腳本消耗 R2 Class A 寫入操作額度。
- **文件嚴格校驗**：通過 AWS S3 SDK 籤署 Policy Condition（`content-length-range`），使具有預籤名鏈接的客戶端依然無法上傳大於約定（1MB）的文件。
- **過期無用空間清理 (可選)**：針對客戶端申請了預籤名 URL，並確已上傳至 R2，但最終斷網未回調 Worker 完成 D1 數據綁定的「孤兒音頻」。可通過 R2 生命周期管理 (Object Lifecycle Management) 或者 Cloudflare Cron Triggers 編寫後臺腳本，每日自動清理沒有存在於 `expressions.audio_url` 列表中的沉澱文件，省下存儲成本。
