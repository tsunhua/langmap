# 異步導出系統設計文檔

## 1. 概述 (Overview)
本文檔概述了基於 Cloudflare Workers 平臺的異步數據導出系統的技術設計。該系統旨在處理將大型數據集（特別是單詞/句子的「收藏集」）導出爲可下載的 ZIP 歸檔文件。通過利用 **Cloudflare Workers**、**Durable Objects** 和 **R2 Storage**，該系統確保了可擴展性、可靠性和成本效益，同時克服了標準無服務器函數的執行時間限制。

## 2. 架構 (Architecture)

系統採用異步任務隊列模式，將請求處理與繁重的導出邏輯解耦。

### 2.1 高層架構圖
```mermaid
graph TD
    Client[客戶端 / 瀏覽器] -->|POST /api/export| API[API Worker]
    API -->|轉發請求| DO[Durable Object (導出引擎)]
    DO -->|保存狀態| Storage[DO Storage]
    DO -->|分批查詢| DB[數據庫]
    DO -->|流式傳輸 ZIP| R2[Cloudflare R2]
    Client -->|輪詢狀態| API
    API -->|獲取狀態| DO
```

### 2.2 組件職責

| 組件 | 職責 |
|-----------|----------------|
| **API Worker** | 客戶端請求的入口點。負責驗證輸入參數，生成唯一的 Job ID，並將請求路由到特定的 Durable Object 實例。 |
| **Durable Object** | **導出引擎。** 管理單個導出任務的生命周期。處理狀態持久化（進度跟蹤），執行分批數據檢索，執行流式壓縮（ZIP），並將生成的文件上傳到 R2。 |
| **Cloudflare R2** | 用於存儲生成的導出文件的對象存儲。提供安全的預籤名 URL 或用於下載的公共訪問權限。 |

## 3. 設計理由 (Design Rationale)

標準 Cloudflare Workers 有嚴格的 CPU（時間）和內存限制（例如 10ms - 30s CPU 時間，128MB 內存）。導出大型收藏集涉及：
1.  **不可預測的數據量**：一個收藏集可能包含數千個條目。
2.  **IO 延遲**：查詢數據庫和生成文件需要時間。
3.  **內存限制**：將整個數據集加載到內存中進行壓縮可能會導致 OOM（內存溢出）錯誤。

**解決方案：**
*   **異步處理**：Durable Objects 可以比標準 Workers 運行更長時間並持久化狀態，使其成爲長時運行任務的理想選擇。
*   **流式處理**：數據分塊（流）處理，並直接通過管道傳輸到 ZIP 生成器，然後傳輸到 R2，從而最小化內存佔用。

## 4. 數據模型 (Data Models)

### 4.1 導出任務結構 (Export Job Structure)
代表導出任務的核心數據結構。

```typescript
interface ExportJob {
  /** 導出任務的唯一標識符 */
  jobId: string;
  /** 導出任務的當前狀態 */
  status: "pending" | "running" | "done" | "error";
  /** 進度百分比 (0.0 到 1.0)，用於 UI 反饋 */
  progress: number;
  /** 任務創建的時間戳 */
  createdAt: number;
  /** 任務完成的時間戳 */
  finishedAt?: number;
  /** 導出的配置選項 */
  options: ExportOptions;
  /** 最終結果數據 */
  result?: {
    r2Key: string;
    downloadUrl?: string;
    sizeBytes?: number;
  };
  /** 狀態爲 'error' 時的錯誤信息 */
  error?: string;
}

interface ExportOptions {
  /** 要導出的收藏集 ID */
  collectionId: string;
  /** 輸出格式偏好 */
  format: "json" | "csv";
}
```

## 5. API 規範 (API Specification)

### 5.1 發起導出 (Initiate Export)
啓動一個新的導出任務。

*   **端點**: `POST /api/export`
*   **請求體**:
    ```json
    {
      "collectionId": "col_123456",
      "format": "json" // 或 "csv"
    }
    ```
*   **響應**:
    ```json
    {
      "jobId": "exp_1704423456789_abcd1234",
      "status": "pending"
    }
    ```

### 5.2 查詢導出狀態 (Check Export Status)
輪詢現有任務的狀態。

*   **端點**: `GET /api/export/{jobId}`
*   **響應 (進行中)**:
    ```json
    {
      "status": "running",
      "progress": 0.45,
      "generatedAt": 1704423456789
    }
    ```
*   **響應 (已完成)**:
    ```json
    {
      "status": "done",
      "progress": 1.0,
      "url": "https://r2.example.com/exports/exp_1704423456789_abcd1234.zip",
      "finishedAt": 1704423500000
    }
    ```

## 6. 實現策略 (Implementation Strategy)

### 6.1 Worker (調度器)
Worker 攔截請求並通過 `jobId` 派生 ID 來實例化 `ExportDO`。

```javascript
// Worker 僞代碼
export default {
  async fetch(req, env) {
    // ... 路由匹配 ...
    const jobId = `exp_${Date.now()}_${crypto.randomUUID()}`;
    const doId = env.EXPORT_DO.idFromName(jobId);
    const stub = env.EXPORT_DO.get(doId);
    
    // 異步觸發啓動方法
    stub.fetch("https://do/start", { ... });
    
    return Response.json({ jobId, status: "pending" });
  }
}
```

### 6.2 Durable Object (處理器)
DO 管理「任務狀態」並使用分頁執行繁重的處理工作，以保持低內存使用率。

**核心邏輯：**
1.  **初始化**：接收 `collectionId`，初始化狀態 `status="running"`。
2.  **流式傳輸**：創建一個 `TransformStream`。可寫端流向 ZIP 生成器；可讀端通過管道傳輸到 `R2.put()`。
3.  **分頁**：
    *   分批查詢數據庫中的收藏集條目（例如，每頁 100 條）。
    *   將條目轉換爲所需格式（JSON/CSV）。
    *   將文件添加到 ZIP 流（例如 `part_1.json` 或追加到單個 CSV）。
    *   每批處理後在存儲中更新 `progress`。
4.  **完成**：關閉流，更新狀態爲 `status="done"`，並保存 R2 key。

```javascript
// ExportDO.runExport 僞代碼
async runExport(options) {
  const { readable, writable } = new TransformStream();
  // ... 初始化連接到 writable 的 zip writer ...
  
  // 啓動 R2 上傳，本質上與生成過程並行
  const uploadPromise = this.env.EXPORT_BUCKET.put(key, readable);
  
  const totalPages = await db.countPages(options.collectionId);
  
  for (let page = 0; page < totalPages; page++) {
    const data = await db.fetchPage(options.collectionId, page);
    zip.add(`data_${page}.json`, JSON.stringify(data));
    
    await this.updateProgress((page + 1) / totalPages);
  }
  
  zip.end();
  await uploadPromise;
  await this.markAsDone(key);
}
```

## 7. 未來考量 (Future Considerations)

### 7.1 冪等性與緩存 (Idempotency & Caching)
*   **基於哈希的去重**：在創建新任務之前，對 `ExportOptions` 進行哈希處理。如果存在具有相同哈希值且最近已完成（例如 24 小時內）的任務，則直接返回現有結果，而不是重新處理。

### 7.2 Manifest 元數據 (Manifest Metadata)
在生成的 ZIP 文件中包含一個 `manifest.json`，其中包含有關導出的元數據：
```json
{
  "collectionId": "col_123456",
  "generatedAt": "2026-01-05T12:00:00Z",
  "itemCount": 5000,
  "format": "json"
}
```

### 7.3 錯誤處理與重試 (Error Handling & Retries)
*   **檢查點**：存儲最後成功處理的頁面索引。如果 DO 崩潰（雖然罕見但有可能），它可以在下一次 `fetch` 調用時或通過計劃事件（alarms）從最後一個檢查點恢復。

## 8. UI 集成 (UI Integration)

### 8.1 導出入口 (Export Entry Point)
在「收藏集詳情」頁面增加一個「導出」按鈕。
*   **位置**：頁面頂部操作欄，靠近「編輯」或「分享」按鈕。
*   **樣式**：使用次級按鈕樣式（Secondary Button）或圖標按鈕（例如帶有下載圖標）。

### 8.2 交互流程 (User Flow)
1.  **點擊導出**：用戶點擊「導出」按鈕。
2.  **格式選擇**：彈出一個模態框或下拉菜單，詢問導出格式（JSON 或 CSV）。
3.  **觸發任務**：
    *   前端調用 `POST /api/v1/export`。
    *   UI 顯示「正在準備導出...」或進度條。
    *   前端開始每隔 1-2 秒輪詢 `GET /api/v1/export/{jobId}`。
4.  **下載**：
    *   當狀態變爲 `done` 時，UI 顯示「下載」按鈕或自動觸發下載。
    *   鏈接指向 `result.url` (R2 的 URL)。
    *   或者前端可以顯示「導出成功」，用戶點擊通知進行下載。
