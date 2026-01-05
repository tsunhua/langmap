# 异步导出系统设计文档

## 1. 概述 (Overview)
本文档概述了基于 Cloudflare Workers 平台的异步数据导出系统的技术设计。该系统旨在处理将大型数据集（特别是单词/句子的“收藏集”）导出为可下载的 ZIP 归档文件。通过利用 **Cloudflare Workers**、**Durable Objects** 和 **R2 Storage**，该系统确保了可扩展性、可靠性和成本效益，同时克服了标准无服务器函数的执行时间限制。

## 2. 架构 (Architecture)

系统采用异步任务队列模式，将请求处理与繁重的导出逻辑解耦。

### 2.1 高层架构图
```mermaid
graph TD
    Client[客户端 / 浏览器] -->|POST /api/export| API[API Worker]
    API -->|转发请求| DO[Durable Object (导出引擎)]
    DO -->|保存状态| Storage[DO Storage]
    DO -->|分批查询| DB[数据库]
    DO -->|流式传输 ZIP| R2[Cloudflare R2]
    Client -->|轮询状态| API
    API -->|获取状态| DO
```

### 2.2 组件职责

| 组件 | 职责 |
|-----------|----------------|
| **API Worker** | 客户端请求的入口点。负责验证输入参数，生成唯一的 Job ID，并将请求路由到特定的 Durable Object 实例。 |
| **Durable Object** | **导出引擎。** 管理单个导出任务的生命周期。处理状态持久化（进度跟踪），执行分批数据检索，执行流式压缩（ZIP），并将生成的文件上传到 R2。 |
| **Cloudflare R2** | 用于存储生成的导出文件的对象存储。提供安全的预签名 URL 或用于下载的公共访问权限。 |

## 3. 设计理由 (Design Rationale)

标准 Cloudflare Workers 有严格的 CPU（时间）和内存限制（例如 10ms - 30s CPU 时间，128MB 内存）。导出大型收藏集涉及：
1.  **不可预测的数据量**：一个收藏集可能包含数千个条目。
2.  **IO 延迟**：查询数据库和生成文件需要时间。
3.  **内存限制**：将整个数据集加载到内存中进行压缩可能会导致 OOM（内存溢出）错误。

**解决方案：**
*   **异步处理**：Durable Objects 可以比标准 Workers 运行更长时间并持久化状态，使其成为长时运行任务的理想选择。
*   **流式处理**：数据分块（流）处理，并直接通过管道传输到 ZIP 生成器，然后传输到 R2，从而最小化内存占用。

## 4. 数据模型 (Data Models)

### 4.1 导出任务结构 (Export Job Structure)
代表导出任务的核心数据结构。

```typescript
interface ExportJob {
  /** 导出任务的唯一标识符 */
  jobId: string;
  /** 导出任务的当前状态 */
  status: "pending" | "running" | "done" | "error";
  /** 进度百分比 (0.0 到 1.0)，用于 UI 反馈 */
  progress: number;
  /** 任务创建的时间戳 */
  createdAt: number;
  /** 任务完成的时间戳 */
  finishedAt?: number;
  /** 导出的配置选项 */
  options: ExportOptions;
  /** 最终结果数据 */
  result?: {
    r2Key: string;
    downloadUrl?: string;
    sizeBytes?: number;
  };
  /** 状态为 'error' 时的错误信息 */
  error?: string;
}

interface ExportOptions {
  /** 要导出的收藏集 ID */
  collectionId: string;
  /** 输出格式偏好 */
  format: "json" | "csv";
}
```

## 5. API 规范 (API Specification)

### 5.1 发起导出 (Initiate Export)
启动一个新的导出任务。

*   **端点**: `POST /api/export`
*   **请求体**:
    ```json
    {
      "collectionId": "col_123456",
      "format": "json" // 或 "csv"
    }
    ```
*   **响应**:
    ```json
    {
      "jobId": "exp_1704423456789_abcd1234",
      "status": "pending"
    }
    ```

### 5.2 查询导出状态 (Check Export Status)
轮询现有任务的状态。

*   **端点**: `GET /api/export/{jobId}`
*   **响应 (进行中)**:
    ```json
    {
      "status": "running",
      "progress": 0.45,
      "generatedAt": 1704423456789
    }
    ```
*   **响应 (已完成)**:
    ```json
    {
      "status": "done",
      "progress": 1.0,
      "url": "https://r2.example.com/exports/exp_1704423456789_abcd1234.zip",
      "finishedAt": 1704423500000
    }
    ```

## 6. 实现策略 (Implementation Strategy)

### 6.1 Worker (调度器)
Worker 拦截请求并通过 `jobId` 派生 ID 来实例化 `ExportDO`。

```javascript
// Worker 伪代码
export default {
  async fetch(req, env) {
    // ... 路由匹配 ...
    const jobId = `exp_${Date.now()}_${crypto.randomUUID()}`;
    const doId = env.EXPORT_DO.idFromName(jobId);
    const stub = env.EXPORT_DO.get(doId);
    
    // 异步触发启动方法
    stub.fetch("https://do/start", { ... });
    
    return Response.json({ jobId, status: "pending" });
  }
}
```

### 6.2 Durable Object (处理器)
DO 管理“任务状态”并使用分页执行繁重的处理工作，以保持低内存使用率。

**核心逻辑：**
1.  **初始化**：接收 `collectionId`，初始化状态 `status="running"`。
2.  **流式传输**：创建一个 `TransformStream`。可写端流向 ZIP 生成器；可读端通过管道传输到 `R2.put()`。
3.  **分页**：
    *   分批查询数据库中的收藏集条目（例如，每页 100 条）。
    *   将条目转换为所需格式（JSON/CSV）。
    *   将文件添加到 ZIP 流（例如 `part_1.json` 或追加到单个 CSV）。
    *   每批处理后在存储中更新 `progress`。
4.  **完成**：关闭流，更新状态为 `status="done"`，并保存 R2 key。

```javascript
// ExportDO.runExport 伪代码
async runExport(options) {
  const { readable, writable } = new TransformStream();
  // ... 初始化连接到 writable 的 zip writer ...
  
  // 启动 R2 上传，本质上与生成过程并行
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

## 7. 未来考量 (Future Considerations)

### 7.1 幂等性与缓存 (Idempotency & Caching)
*   **基于哈希的去重**：在创建新任务之前，对 `ExportOptions` 进行哈希处理。如果存在具有相同哈希值且最近已完成（例如 24 小时内）的任务，则直接返回现有结果，而不是重新处理。

### 7.2 Manifest 元数据 (Manifest Metadata)
在生成的 ZIP 文件中包含一个 `manifest.json`，其中包含有关导出的元数据：
```json
{
  "collectionId": "col_123456",
  "generatedAt": "2026-01-05T12:00:00Z",
  "itemCount": 5000,
  "format": "json"
}
```

### 7.3 错误处理与重试 (Error Handling & Retries)
*   **检查点**：存储最后成功处理的页面索引。如果 DO 崩溃（虽然罕见但有可能），它可以在下一次 `fetch` 调用时或通过计划事件（alarms）从最后一个检查点恢复。
