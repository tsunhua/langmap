# 词条录音与上传功能设计

## System Reminder

**实现状态**：
- ❌ R2 存储桶/目录配置（音频用）未设置
- ❌ 预签名 URL API 未实现
- ❌ 前端录音组件未实现
- ❌ 数据库 `audio_url` 更新逻辑未完全对接

---

## 1. 背景与目标

为了丰富 LangMap 的语言数据，帮助学习者更好地掌握不同地区语言的真实发音，系统需要提供词条发音的录音和上传功能。
**核心原则**：
- **符合当前架构**：基于 Cloudflare Workers + D1 + R2 + Vue 3 的无服务器应用架构。
- **尽量节约成本**：最小化 Worker 的内存、CPU 和执行时间，充分利用 R2 的免费额度和零下行流量费特性，规避高昂的大文件处理开销。
- **符合用户操作习惯**：迎合移动端和 PC 端用户的原生习惯，提供即录、即听、即传的顺滑无感体验。

## 2. 存储与架构设计

### 2.1 架构数据流 (S3-compatible Presigned URL 直传)
采用 **客户端直传 R2 (Direct to R2 via Presigned URL)** 的架构，避免音频流经过 Cloudflare Worker 带来的带宽高负荷和执行时间消耗（突破 Worker Payloads 限制并极大降低请求计费成本）。

流程如下：
1. **申请**：客户端请求 Worker 获取 R2 上传预签名 URL (Presigned URL)。
2. **直传**：客户端使用获取的预签名 URL 直接将音频（如 WebM/MP3）通过 `PUT` 请求上传至 R2。
3. **绑定**：客户端判断长链上传成功后，回传结果给 Worker，更新 D1 数据库中该 `expressions` 记录的 `audio_url`。

### 2.2 数据格式与存储结构
- **Bucket**: 新的的 Cloudflare R2 存储 `langmap-audio`。
- **Path Path**: `expressions/{expression_id}/{uuid}.webm`
- **格式限制**: 推荐前端使用浏览器原生 `MediaRecorder` API 统一录制为 `audio/webm` 或 `audio/mp4`。
- **大小限制**: 强制验证最大 1MB。一般语言发音不超过 10 秒（50KB-150KB 左右）。

## 3. 成本优化核心策略

- **零流量费分发**：Cloudflare R2 不收取 Egress（出站流出）费用，完美适配语言字典此类具有长尾、读多写少、高频下载场景的音频业务。
- **边缘缓存加速**：R2 前置绑定 Cloudflare CDN 自定义域 (如 `audio.langmap.io`)，配置强静态缓存（`Cache-Control: public, max-age=31536000`）。这可以将绝大多数的 R2 Class B (Read) 操作挡在缓存层外，极大节省 R2 读取费用。
- **直传消除计算节点压力**：将负担最重的 I/O 上行任务剥离出 Worker 节点，只保留了最廉价的 JSON 计算请求（获取签名和更新 DB）。
- **前端预防与截断**：前端组件设计为最多录制 15 秒即自动停止截断，从源头避免非预期巨型文件堆积。

## 4. 前端 UI 与交互设计 (符合操作习惯)

界面设计需注重直觉反馈和高容错率，复刻用户习惯的主流聊天软件语音输入体验。

### 4.1 UI 表现层
- **词条详情页** 内紧贴发音字符区域，或者在 **创建/编辑词条表单** 内新增“发音采集”区块。
- 默认状态：主要视觉焦点为一个带有 🎤 图标的 **「录制发音」** 主按钮。

### 4.2 录音交互流程
1. **点击录音**：用户点击 🎤 按钮，前端请求麦克风权限。获得权限后，界面自动切换为“录音中”状态，展示心跳波形动效与不断递增的计时器 (例如 00:00 / 00:15)。
2. **结束录制**：再次点击录音按钮（变为 ⏺ 停止区块）结束录制。达到 15 秒上限时则自动触发结束。
3. **预览、重录与上传**：录制完成后进入“待确认”状态。此时不立刻写入服务器，而是提供三个直观选项：
   - **[▶ 听取]**：播放刚才的录音，让用户确认质量是否合格（无杂音、发音准确）。
   - **[✖ 重录]**：一键丢弃当前缓存并重新开始录制。
   - **[✔ 确认并上传]**：发起预签名流程和文件直传。
4. **过程反馈**：确认上传阶段展示无极进度条/转圈动画。成功后界面刷新，词条旁直接显示一个干净的迷你音频播放器。

### 4.3 兼容性与降级机制
- 若检测到当前运行环境（如旧版浏览器、无 HTTPS 等）不支持 `navigator.mediaDevices.getUserMedia`，则提示用户“当前环境不支持录音，请使用支持 WebRTC 的现代浏览器并确保在 HTTPS 环境下访问”。

## 5. API 接口设计

### 5.1 获取预签名 URL (Worker)
- **Endpoint**: `POST /api/v1/expressions/:id/upload-audio`
- **Auth**: 限定已登录用户 (`JWT`)。
- **Request Parameters**:
  - `content_type`: 音频 MIME 类型（方便生成对应后缀和设头）。
  - `content_length`: 预估文件大小（用于超限阻断）。
- **Response**:
  ```json
  {
    "upload_url": "https://<r2-bucket>.r2.cloudflarestorage.com/audio/expressions/123/xxx.webm?X-Amz-Signature...",
    "audio_url": "https://audio.langmap.io/expressions/123/xxx.webm",
    "expires_in": 300
  }
  ```

### 5.2 确认绑定并发布 (Worker + D1)
- **Endpoint**: `PATCH /api/v1/expressions/:id` (复用编辑接口)
- **Request Validation**:
  ```json
  {
    "audio_url": "https://audio.langmap.io/expressions/123/xxx.webm"
  }
  ```
- **业务逻辑**: 
  1. 通过 Session 获取 User 校验是否有权限操作。
  2. 将 D1 `expressions` 主表的 `audio_url` 字段更新为最终 R2 的公网地址。
  3. *(如实现)* 向 `expression_versions` 写入对应的发音补全历史版本，确保改动可追溯。

## 6. 安全与防滥用管控

- **请求速率限制 (Rate Limiting)**：在获取预定义 URL 接口针对 IP/User ID 实施严格的频次限制（如每分钟最多申请 5 次签发），防止脚本消耗 R2 Class A 写入操作额度。
- **文件严格校验**：通过 AWS S3 SDK 签署 Policy Condition（`content-length-range`），使具有预签名链接的客户端依然无法上传大于约定（1MB）的文件。
- **过期无用空间清理 (可选)**：针对客户端申请了预签名 URL，并确已上传至 R2，但最终断网未回调 Worker 完成 D1 数据绑定的“孤儿音频”。可通过 R2 生命周期管理 (Object Lifecycle Management) 或者 Cloudflare Cron Triggers 编写后台脚本，每日自动清理没有存在于 `expressions.audio_url` 列表中的沉淀文件，省下存储成本。
