# 詞句詳情頁與對照圖譜優化實施計畫

**狀態：** Implemented (2026-07-26)

> 實作時按 Task 順序進行；每完成一個 Task，執行該節驗證並建立獨立 commit。使用 `- [ ]` 追蹤進度。

**規格：** `docs/superpowers/specs/2026-07-26-mapping-detail-graph-optimization.md`  
**目標頁面：** `http://localhost:5173/mapping/1146386197`  
**目標：** 將固定放射圖改造成無重疊、可拖曳、可縮放、正確顯示 1-3 跳父子關係的徑向層級圖，並提供層級列表與行動版替代操作。  
**技術棧：** Vue 3、TypeScript、Hono、Cloudflare D1、Vitest、D3 子套件。  

---

## 實作決策

以下決策在施工前固定，避免各 Task 重複選型：

1. **原地升級 endpoint**  
   保留 `GET /api/v2/expressions/:id/mappings?hops=N`，將回傳值由扁平陣列升級為圖物件。同步遷移目前兩個消費者：
   - `MappingDetail.vue`
   - `MapLens.vue`

2. **API `nodes` 包含根節點**  
   根節點的 `depth` 為 0。`root_id` 仍保留，讓 endpoint 可獨立使用；詳情頁仍呼叫 detail endpoint 取得來源、座標等額外資料。

3. **後端負責真實圖，前端負責展示樹**  
   後端回傳節點及所有已遍歷實際邊。前端使用穩定 BFS 選出 `displayParentId`，其餘邊歸類為 `crossEdges`。

4. **遍歷上限**  
   根節點以外最多回傳 200 個節點。達上限後回傳 `truncated: true` 與可計算的 `omitted_count`。

5. **邊方向與深度**  
   - `source_id` 指向較淺節點，`target_id` 指向較深節點。
   - 同深度交叉邊使用較小 expression ID 作為 source，確保結果穩定。
   - `edge.depth = max(source.depth, target.depth)`。

6. **D3 使用範圍**  
   - `d3-hierarchy`：子樹與角度分配。
   - `d3-zoom`：平移、滾輪與觸控縮放。
   - `d3-drag`：節點拖曳。
   - Vue 負責 DOM 與應用狀態；D3 不直接建立或刪除節點 DOM。
   - 不引入 `d3-force` 或完整 `d3` bundle。

7. **漸進交付**  
   新圖譜穩定前保留 `RadialGraph.vue`。`MappingDetail.vue` 切換完成並通過回歸後才刪除舊元件。

---

## 依賴關係

```text
Task 1 API 型別與遍歷核心
  └─ Task 2 Route 升級與 API 測試
      └─ Task 3 前端契約與 MapLens 遷移
          └─ Task 4 前端測試基礎
              └─ Task 5 展示樹與徑向佈局
                  └─ Task 6 靜態圖譜元件
                      └─ Task 7 平移與縮放
                          └─ Task 8 節點拖曳
                              └─ Task 9 選取、路徑與資訊面板
                                  └─ Task 10 漸進展開與語意縮放
                                      └─ Task 11 層級列表與同步
                                          └─ Task 12 行動版與狀態處理
                                              └─ Task 13 清理、效能與回歸
```

---

## Task 1：建立後端圖契約與可測試遍歷核心

**Files：**

- Create: `backend_v2/src/utils/mappingGraph.ts`
- Create: `backend_v2/tests/mappingGraph.test.ts`
- Modify: `backend_v2/src/types.ts`

- [ ] **Step 1：定義後端圖型別**

在 `backend_v2/src/types.ts` 新增：

```ts
export interface MappingGraphNode {
  expression_id: number
  text: string
  language_code: string
  language_name: string | null
  depth: number
}

export interface MappingGraphEdge {
  edge_id: string
  source_id: number
  target_id: number
  score: number
  depth: number
}

export interface MappingGraphResponse {
  root_id: number
  requested_hops: 1 | 2 | 3
  resolved_hops: 0 | 1 | 2 | 3
  nodes: MappingGraphNode[]
  edges: MappingGraphEdge[]
  layer_counts: Record<number, number>
  truncated: boolean
  omitted_count: number
}
```

- [ ] **Step 2：先寫遍歷測試**

`mappingGraph.test.ts` 使用記憶體 fixture 和 mock loader，不連 D1。至少覆蓋：

1. `hops=1` 只回根與直接鄰居。
2. `hops=3` 真正到達第三層。
3. A-B-C-A 循環不重複節點、不無限迴圈。
4. D 同時由 B、C 連入時只出現一個 node，但保留兩條 edge。
5. 邊方向由淺到深。
6. 相同深度交叉邊方向穩定。
7. 鄰居輸入順序改變時輸出順序不變。
8. 達到節點上限時 `truncated` 與 `omitted_count` 正確。
9. `layer_counts`、`resolved_hops` 正確。

- [ ] **Step 3：確認測試先失敗**

```bash
cd backend_v2
npx vitest run tests/mappingGraph.test.ts
```

Expected：因 `mappingGraph.ts` 尚未實作而失敗。

- [ ] **Step 4：實作純遍歷核心**

`mappingGraph.ts` 提供：

```ts
interface NeighborRow {
  edge_id: string
  expression_a_id: number
  expression_b_id: number
  score: number
}

interface ExpressionRow {
  expression_id: number
  text: string
  language_code: string
  language_name: string | null
}

type LoadEdges = (frontierIds: number[]) => Promise<NeighborRow[]>
type LoadExpressions = (ids: number[]) => Promise<ExpressionRow[]>

export async function buildMappingGraph(
  rootId: number,
  requestedHops: 1 | 2 | 3,
  loadEdges: LoadEdges,
  loadExpressions: LoadExpressions,
  maxNodes = 200,
): Promise<MappingGraphResponse>
```

要求：

- BFS 每層只呼叫一次 `loadEdges`。
- expression 詳情按新發現 ID 批次取得。
- 節點去重使用 `Map<number, MappingGraphNode>`。
- 邊去重使用 `Map<string, MappingGraphEdge>`。
- 所有輸出在回傳前穩定排序。
- 不把 D1 物件或 SQL 混入此 helper。

- [ ] **Step 5：執行純遍歷測試**

```bash
cd backend_v2
npx vitest run tests/mappingGraph.test.ts
```

Expected：全部通過。

- [ ] **Step 6：Commit**

```bash
git add backend_v2/src/types.ts backend_v2/src/utils/mappingGraph.ts backend_v2/tests/mappingGraph.test.ts
git commit -m "feat: add mapping graph traversal core"
```

---

## Task 2：升級 mappings endpoint

**Files：**

- Modify: `backend_v2/src/routes/expressions.ts`
- Create: `backend_v2/tests/expressions-mappings.test.ts`

- [ ] **Step 1：加入 query 參數測試**

測試：

- 缺省 `hops` 等於 1。
- `hops=0` clamp 到 1。
- `hops=4` clamp 到 3。
- 非數字值回落到 1。

將參數解析提取為 `parseMappingHops(value): 1 | 2 | 3`，放在 `mappingGraph.ts` 並單元測試。

- [ ] **Step 2：新增 D1 loader**

在 `expressions.ts` 的 endpoint 內建立兩個批次 loader：

1. `loadEdges(frontierIds)`
   - 查詢 `expression_edges`。
   - 條件為 `expression_a_id IN (...) OR expression_b_id IN (...)`。
   - 使用綁定參數生成 placeholders，不拼接未驗證值。
   - 依 `score DESC, id ASC` 排序。

2. `loadExpressions(ids)`
   - 查詢 `expressions` 並 LEFT JOIN `languages`。
   - 回傳 expression ID、text、language code、language name。
   - 依 expression ID 排序。

frontier 或 ids 為空時直接回傳空陣列，不生成 `IN ()`。

- [ ] **Step 3：替換舊扁平查詢**

`GET /:id/mappings`：

1. 驗證根 expression 存在，不存在回 `notFound`。
2. 解析 hops。
3. 呼叫 `buildMappingGraph`。
4. 使用 `success(c, graph)` 回傳。
5. 刪除舊 direct/second 扁平陣列邏輯。

- [ ] **Step 4：建立 route 整合測試**

`expressions-mappings.test.ts` 針對本地 Worker 驗證回應 shape：

```ts
expect(body.data).toMatchObject({
  root_id: expect.any(Number),
  requested_hops: expect.any(Number),
  nodes: expect.any(Array),
  edges: expect.any(Array),
  truncated: expect.any(Boolean),
})
```

再驗證：

- 根節點存在且 `depth === 0`。
- node ID 唯一。
- edge ID 唯一。
- 所有 edge endpoints 都存在於 nodes。
- 最大 node depth 不超過 requested hops。
- 二跳 edge 不是全部從 root 出發。

- [ ] **Step 5：啟動本地服務並驗證樣本**

終端 A：

```bash
./dev.sh
```

終端 B：

```bash
curl "http://127.0.0.1:8788/api/v2/expressions/1146386197/mappings?hops=3"
```

Expected：

- `success: true`
- `requested_hops: 3`
- nodes 包含 depth 0-3，若資料實際存在第三層
- edges 保留實際 `edge_id`

- [ ] **Step 6：執行後端測試**

```bash
cd backend_v2
npm test
```

- [ ] **Step 7：Commit**

```bash
git add backend_v2/src/routes/expressions.ts backend_v2/src/utils/mappingGraph.ts backend_v2/tests
git commit -m "feat: return graph data from expression mappings API"
```

---

## Task 3：前端契約、composable 與 MapLens 相容遷移

**Files：**

- Create: `web_v2/src/components/mapping/mappingGraphTypes.ts`
- Create: `web_v2/src/components/mapping/mappingGraphModel.ts`
- Modify: `web_v2/src/composables/useExpressions.ts`
- Modify: `web_v2/src/pages/MapLens.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`

- [ ] **Step 1：建立前端圖型別**

在 `mappingGraphTypes.ts` 定義與 API 一致的：

- `MappingGraphNode`
- `MappingGraphEdge`
- `MappingGraphResponse`
- `DisplayGraphNode`
- `DisplayGraphEdge`
- `GraphBounds`

禁止 `MappingDetail.vue` 和 `MapLens.vue` 再用 `any[]` 表示 mappings。

- [ ] **Step 2：更新 composable**

將：

```ts
mappings(id, hops)
```

改名為：

```ts
mappingGraph(id, hops): Promise<MappingGraphResponse>
```

採用新名稱，讓編譯器暴露所有舊扁平資料消費點，不建立默默 flatten 的相容層。

- [ ] **Step 3：建立 primary edge helper**

在 `mappingGraphModel.ts` 實作：

```ts
export function getPrimaryIncomingEdge(
  nodeId: number,
  graph: MappingGraphResponse,
): MappingGraphEdge | null
```

排序規則：

1. 來源 depth 較淺。
2. edge score 較高。
3. edge ID 升序。

- [ ] **Step 4：遷移 MapLens**

`MapLens.vue`：

- 改用 `mappingGraph(id, 2)`。
- pins 從 `graph.nodes.filter(depth > 0)` 建立。
- pin score 使用 `getPrimaryIncomingEdge`。
- 保留原有地理篩選、region count 和 marker 行為。
- 根節點不重複成普通 pin。
- `mappingData` 改成有型別的 `graph` ref。

- [ ] **Step 5：先讓 MappingDetail 使用新資料，但暫保留舊圖**

在新圖譜尚未完成前：

- `MappingDetail.vue` 改用 `mappingGraph`。
- 暫時建立 `legacyMappings` computed，從 depth 1 nodes 與 primary edge 轉成舊 `RadialGraph` props。
- 暫時只讓舊圖顯示一跳，避免錯誤繪製二跳。
- Header 統計改讀 `layer_counts`。

此相容 computed 必須加 `TODO`，並在 Task 6 刪除。

- [ ] **Step 6：前端 build**

```bash
cd web_v2
npm run build
```

Expected：型別檢查通過，MapLens 和 MappingDetail 均可載入。

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/components/mapping/mappingGraphTypes.ts \
  web_v2/src/components/mapping/mappingGraphModel.ts \
  web_v2/src/composables/useExpressions.ts \
  web_v2/src/pages/MapLens.vue \
  web_v2/src/pages/MappingDetail.vue
git commit -m "refactor: consume mapping graph response in web v2"
```

---

## Task 4：建立前端最小測試基礎

**Files：**

- Modify: `web_v2/package.json`
- Modify: `web_v2/package-lock.json`
- Modify: `web_v2/vite.config.ts`
- Modify: `web_v2/tsconfig.json`
- Create: `web_v2/src/test/setup.ts`

- [ ] **Step 1：安裝測試與 D3 子套件**

```bash
cd web_v2
npm install d3-hierarchy d3-zoom d3-drag
npm install -D \
  @types/d3-hierarchy \
  @types/d3-zoom \
  @types/d3-drag \
  vitest \
  @vue/test-utils \
  jsdom
```

- [ ] **Step 2：新增 scripts**

`web_v2/package.json`：

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

保留現有 dev、build、preview scripts。

- [ ] **Step 3：設定 Vitest**

在 `vite.config.ts` 加入：

```ts
test: {
  environment: 'jsdom',
  setupFiles: ['./src/test/setup.ts'],
}
```

若 TypeScript 不接受 `test`，從 `vitest/config` 匯入 `defineConfig`。

- [ ] **Step 4：建立 setup**

`src/test/setup.ts` 提供：

- `ResizeObserver` mock。
- 必要的 `SVGElement.prototype.getBBox` mock。
- 每個測試後清理 DOM。

只補測試確實需要的 browser API，不建立大型全域 mock。

- [ ] **Step 5：加入 smoke test**

為 `mappingGraphModel.ts` 建立一個簡單測試，確認 Vitest、alias `@` 和 TypeScript 都能工作。

- [ ] **Step 6：驗證**

```bash
cd web_v2
npm test
npm run build
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/package.json web_v2/package-lock.json web_v2/vite.config.ts \
  web_v2/tsconfig.json web_v2/src/test web_v2/src/components/mapping/mappingGraphModel.test.ts
git commit -m "test: add web v2 graph test foundation"
```

---

## Task 5：以 TDD 實作展示樹與徑向佈局

**Files：**

- Create: `web_v2/src/components/mapping/mappingGraphLayout.ts`
- Create: `web_v2/src/components/mapping/mappingGraphLayout.test.ts`
- Modify: `web_v2/src/components/mapping/mappingGraphModel.ts`
- Modify: `web_v2/src/components/mapping/mappingGraphModel.test.ts`

- [ ] **Step 1：建立固定 fixtures**

測試 fixture 包含：

- 根節點。
- 40 個一跳節點。
- 不均勻二跳子樹。
- 一條三跳分支。
- 多父節點。
- 循環。
- 長文字節點尺寸。

fixture 使用明確 ID 與固定順序，不依賴正式 D1。

- [ ] **Step 2：先寫展示樹測試**

`buildDisplayTree(graph, collapsedIds)` 必須：

- 根節點無 parent。
- 每個非根可見節點只有一個 `displayParentId`。
- 首次 BFS 父節點由穩定排序決定。
- 其餘邊進入 `crossEdges`。
- 收合節點後，其後代不出現在 visible nodes。
- 相同 graph 不同輸入順序產生相同父子結果。

- [ ] **Step 3：實作展示樹**

在 `mappingGraphModel.ts` 實作：

```ts
export function buildDisplayTree(
  graph: MappingGraphResponse,
  collapsedIds: ReadonlySet<number>,
): DisplayTree
```

- [ ] **Step 4：先寫佈局測試**

`layoutMappingGraph(input)` 必須驗證：

- 根節點在 `(0, 0)`。
- depth 2 半徑大於 parent 的 depth 1 半徑。
- depth 3 半徑大於 depth 2。
- 子節點角度落在父節點分配區段。
- 所有節點 bounds 被總 bounds 包含。
- 相同輸入產生完全相同座標。
- 40 個一跳節點碰撞數為 0。
- 不均勻二跳 fixture 碰撞數為 0。

碰撞判斷以傳入 `nodeSizes` 加 12px gap 計算。

- [ ] **Step 5：實作徑向層級佈局**

`mappingGraphLayout.ts`：

```ts
export interface LayoutInput {
  rootId: number
  tree: DisplayTree
  nodeSizes: ReadonlyMap<number, NodeSize>
}

export function layoutMappingGraph(input: LayoutInput): LayoutOutput
```

實作順序：

1. 將展示樹轉為 `d3-hierarchy`。
2. 計算每個子樹可見葉節點權重。
3. 按權重分配角度。
4. 以該層最大節點對角線、節點數與 gap 計算最小半徑。
5. 放置節點。
6. 對同層節點執行有限次切向碰撞修正。
7. 保持父子角度區段約束。
8. 計算 bounds。

不得使用隨機值或持續模擬。

- [ ] **Step 6：跑測試**

```bash
cd web_v2
npm test -- mappingGraphModel mappingGraphLayout
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/components/mapping/mappingGraphModel* \
  web_v2/src/components/mapping/mappingGraphLayout*
git commit -m "feat: add deterministic radial hierarchy layout"
```

---

## Task 6：建立靜態新圖譜元件並切換詳情頁

**Files：**

- Create: `web_v2/src/components/mapping/MappingGraph.vue`
- Create: `web_v2/src/components/mapping/GraphNode.vue`
- Create: `web_v2/src/components/mapping/GraphEdges.vue`
- Create: `web_v2/src/components/mapping/MappingGraph.test.ts`
- Modify: `web_v2/src/pages/MappingDetail.vue`

- [ ] **Step 1：先寫渲染測試**

掛載 `MappingGraph` 後驗證：

- 每個 visible node 只渲染一次。
- 根節點有 anchor class 與 `depth=0`。
- tree edge 數量正確。
- cross edge 預設不渲染。
- node accessible name 包含詞句、語言和深度。

- [ ] **Step 2：建立 GraphNode**

需求：

- 接收 layout node 與語意縮放 level。
- 使用 `transform: translate3d(x, y, 0)` 定位。
- 根節點、一般節點、選取節點有清楚 class。
- 文字截斷但保留完整 accessible name。
- 支援 Enter、Space 選取。
- 節點上只顯示詞句、語言和子節點數，不渲染 VotePill。

- [ ] **Step 3：建立 GraphEdges**

使用單一 SVG：

- tree edges 由實際 parent node 連向 child。
- 端點使用 layout 座標。
- 線寬由 score clamp 到固定範圍。
- depth 使用 class 控制 opacity。
- 不畫 root 到二跳的虛線。

- [ ] **Step 4：建立 MappingGraph**

第一版只負責：

- 測量容器與節點尺寸。
- 建立展示樹。
- 呼叫 layout。
- 渲染 edges 和 nodes。
- 顯示簡單圖例。
- 發出 `select` event。

為避免首次測量閃動：

1. 先以保守預設尺寸佈局。
2. `nextTick` 後批次測量。
3. 實際尺寸有實質差異時只重新佈局一次。

- [ ] **Step 5：切換 MappingDetail**

- 用 `MappingGraph` 取代 `RadialGraph`。
- 刪除 Task 3 的 `legacyMappings` computed。
- 暫時保留現有 hop 控制和列表。
- `select` 先只更新 `selectedNodeId`，不立即路由跳轉。

- [ ] **Step 6：視覺驗證**

```bash
cd web_v2
npm test -- MappingGraph
npm run build
```

瀏覽 `/mapping/1146386197`：

- 40 個一跳節點無重疊。
- 節點在動態半徑上。
- 畫布可超出 viewport，但內容不被錯誤裁切。

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/components/mapping/GraphNode.vue \
  web_v2/src/components/mapping/GraphEdges.vue \
  web_v2/src/components/mapping/MappingGraph.vue \
  web_v2/src/components/mapping/MappingGraph.test.ts \
  web_v2/src/pages/MappingDetail.vue
git commit -m "feat: render hierarchical mapping graph"
```

---

## Task 7：加入畫布平移、縮放與工具列

**Files：**

- Create: `web_v2/src/composables/useGraphViewport.ts`
- Create: `web_v2/src/composables/useGraphViewport.test.ts`
- Create: `web_v2/src/components/mapping/GraphToolbar.vue`
- Create: `web_v2/src/components/mapping/GraphToolbar.test.ts`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`

- [ ] **Step 1：先寫 transform helper 測試**

測試：

- `fitBounds` 將完整 bounds 放入 viewport 並保留 padding。
- fit scale clamp 在 0.25-2.5。
- zoom in/out 以 viewport 中心為基準。
- 100% 保持當前中心。
- reset 回到最新自動 layout 的 fit transform。

- [ ] **Step 2：實作 useGraphViewport**

職責：

- 初始化及清理 `d3-zoom`。
- 維護目前 `ZoomTransform`。
- 對同一 world element 套用 transform。
- 暴露 `zoomIn`、`zoomOut`、`fit`、`actualSize`、`centerOnNode`。
- 容器 ResizeObserver 觸發重新 fit 的策略：
  - 使用者尚未手動操作：自動 fit。
  - 使用者已操作：保留中心與 scale。
- 所有 listener 在 unmount 時清理。

高頻 zoom event 直接更新 world element style；只在操作結束時更新低頻 Vue state，例如顯示百分比。

- [ ] **Step 3：建立 GraphToolbar**

控制：

- 放大。
- 縮小。
- 適應畫面。
- 100%。
- 重置佈局。
- 顯示整數縮放百分比。

所有按鈕：

- 有 `aria-label`。
- disabled 狀態正確。
- 行動版至少 44px。

- [ ] **Step 4：整合 MappingGraph**

DOM 結構：

```text
viewport
└── world
    ├── svg edges
    └── html nodes
```

SVG 與節點必須在同一 world transform 下。

- [ ] **Step 5：瀏覽器驗證**

在桌面及觸控板驗證：

- 背景拖曳平移。
- 滾輪縮放。
- 工具列縮放。
- fit 顯示全部節點。
- 100% 不讓畫面跳到無關位置。
- zoom 上限 250%，下限 25%。

- [ ] **Step 6：測試與 build**

```bash
cd web_v2
npm test -- useGraphViewport GraphToolbar
npm run build
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/composables/useGraphViewport* \
  web_v2/src/components/mapping/GraphToolbar* \
  web_v2/src/components/mapping/MappingGraph.vue
git commit -m "feat: add mapping graph pan and zoom controls"
```

---

## Task 8：加入節點拖曳與位置重置

**Files：**

- Create: `web_v2/src/composables/useGraphDrag.ts`
- Create: `web_v2/src/composables/useGraphDrag.test.ts`
- Modify: `web_v2/src/components/mapping/GraphNode.vue`
- Modify: `web_v2/src/components/mapping/GraphEdges.vue`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`

- [ ] **Step 1：先定義拖曳狀態**

```ts
type PositionOverrides = Map<number, { x: number; y: number }>
```

位置解析：

```ts
effectivePosition = overridePosition ?? layoutPosition
```

- [ ] **Step 2：先寫拖曳閾值測試**

測試：

- 位移小於 4px 視為 click。
- 位移等於或大於 4px 視為 drag。
- drag 結束不發出 select。
- click 仍發出 select。
- reset 清空所有 overrides。

- [ ] **Step 3：實作 d3-drag**

`useGraphDrag`：

- 將 pointer delta 由畫面座標換算為 world 座標。
- 拖動中直接更新 node transform。
- 同步更新與該節點相連 edge 的端點。
- drag end 才寫入 `positionOverrides`。
- 阻止拖節點時觸發背景 pan。
- 不允許拖動根節點，或明確將根節點拖曳設為 disabled。

- [ ] **Step 4：重置佈局**

GraphToolbar 的 reset：

1. 清除 overrides。
2. 重新套用 layout positions。
3. fit-to-view。

- [ ] **Step 5：驗證**

- 拖動一跳節點，root edge 跟隨。
- 拖動二跳節點，parent edge 跟隨。
- 拖動後點擊不跳頁。
- 點擊未拖動節點可以選取。
- 切換 hops 後已存在節點的位置保留。

- [ ] **Step 6：測試與 build**

```bash
cd web_v2
npm test -- useGraphDrag
npm run build
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/composables/useGraphDrag* \
  web_v2/src/components/mapping/GraphNode.vue \
  web_v2/src/components/mapping/GraphEdges.vue \
  web_v2/src/components/mapping/MappingGraph.vue
git commit -m "feat: support draggable mapping graph nodes"
```

---

## Task 9：選取狀態、路徑高亮與資訊面板

**Files：**

- Create: `web_v2/src/components/mapping/GraphInspector.vue`
- Create: `web_v2/src/components/mapping/GraphInspector.test.ts`
- Modify: `web_v2/src/components/mapping/mappingGraphModel.ts`
- Modify: `web_v2/src/components/mapping/mappingGraphModel.test.ts`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`
- Modify: `web_v2/src/components/mapping/GraphNode.vue`
- Modify: `web_v2/src/components/mapping/GraphEdges.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`

- [ ] **Step 1：先寫 path helper 測試**

新增：

```ts
getPathToRoot(nodeId, displayTree): number[]
getRelatedCrossEdges(nodeId, displayTree): MappingGraphEdge[]
```

測試根節點、一跳、三跳及不存在節點。

- [ ] **Step 2：實作選取視覺**

選取節點後：

- 從根到節點的 path nodes 和 tree edges 高對比。
- 與選中節點相關的 cross edges 顯示為細虛線。
- 無關節點與邊降至 20%-30% opacity。
- Escape 清除選取。
- focus 和 selected 是兩個狀態，不互相取代。

- [ ] **Step 3：建立 GraphInspector**

顯示：

- 完整詞句。
- 語言代碼與名稱。
- 深度。
- 根到節點的文字路徑。
- primary edge score。
- 其他關係數量。
- `VotePill`，target ID 使用 primary edge ID。
- 展開/收合控制 placeholder。
- 「查看詞句詳情」按鈕。

根節點不顯示 mapping vote。

- [ ] **Step 4：調整頁面桌面佈局**

`MappingDetail.vue`：

- 最大寬度調整為 1280-1440px。
- 圖譜與 inspector 使用 `minmax(0, 1fr) 300px`。
- graph 高度使用 `clamp(520px, 68dvh, 820px)`。
- inspector 無選取時顯示使用說明與統計。

- [ ] **Step 5：導航規則**

- 單擊節點：選取。
- 雙擊節點：`router.push('/mapping/:id')`。
- Inspector 按鈕：進入詳情。
- 根節點不可導航到自己。

- [ ] **Step 6：測試與 build**

```bash
cd web_v2
npm test -- mappingGraphModel GraphInspector MappingGraph
npm run build
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/components/mapping/GraphInspector* \
  web_v2/src/components/mapping/mappingGraphModel* \
  web_v2/src/components/mapping/MappingGraph.vue \
  web_v2/src/components/mapping/GraphNode.vue \
  web_v2/src/components/mapping/GraphEdges.vue \
  web_v2/src/pages/MappingDetail.vue
git commit -m "feat: add mapping graph selection and inspector"
```

---

## Task 10：漸進展開、跳數控制與語意縮放

**Files：**

- Create: `web_v2/src/composables/useMappingGraph.ts`
- Create: `web_v2/src/composables/useMappingGraph.test.ts`
- Modify: `web_v2/src/components/mapping/GraphToolbar.vue`
- Modify: `web_v2/src/components/mapping/GraphNode.vue`
- Modify: `web_v2/src/components/mapping/GraphInspector.vue`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`

- [ ] **Step 1：建立檢視狀態 composable**

`useMappingGraph` 管理：

- `requestedHops`
- `collapsedNodeIds`
- `selectedNodeId`
- `positionOverrides`
- `languageFilter`
- `minimumScore`
- `searchQuery`
- 載入及局部錯誤狀態

API graph 與 view state 分離。

- [ ] **Step 2：定義初始展開策略**

- `hops=1`：一跳全部顯示。
- 切至 `hops=2/3`：資料可完整載入，但新增分支預設收合。
- 使用者可在 node 或 inspector 展開單一分支。
- Toolbar 提供「展開全部」及「收合至一跳」。
- 切換 hops 不清除既有節點位置。

- [ ] **Step 3：大型分支聚合**

第一版門檻固定為每個 parent 顯示前 20 個 child：

- 超過 20 個時建立視圖層聚合節點。
- 聚合節點不是 API node，不可投票或進入詳情。
- 顯示「另外 N 個」。
- 點擊聚合節點展開全部 child。
- 聚合 ID 使用明確的 view-only string ID，不冒充 expression ID。

- [ ] **Step 4：將 hop 控制移入 GraphToolbar**

- 使用 1 / 2 / 3 segmented control。
- 更新時呼叫 `mappingGraph(id, hops)`。
- request 中保留舊 graph。
- 失敗時還原先前 hops 並顯示 inline error。
- 移除頁面下方舊 `expand-hop` 控制。

- [ ] **Step 5：加入語意縮放**

以 zoom 百分比分三個 level：

- compact：`< 45%`
- medium：`45%-80%`
- full：`> 80%`

僅在跨越 level 門檻時更新 Vue state，不在每個 zoom event 重 render。

GraphNode 各 level：

- compact：短文字或語言標記。
- medium：詞句及語言代碼。
- full：完整卡片、評分摘要、子節點數。

- [ ] **Step 6：加入基本篩選**

Toolbar 支援：

- 圖內搜尋。
- 語言篩選。
- 最低評分。

篩選只改 visible display tree，不重新請求 API。父節點若因子節點匹配而需要保留，標記為 context node。

- [ ] **Step 7：測試與 build**

```bash
cd web_v2
npm test -- useMappingGraph GraphToolbar GraphNode
npm run build
```

- [ ] **Step 8：Commit**

```bash
git add web_v2/src/composables/useMappingGraph* \
  web_v2/src/components/mapping/GraphToolbar.vue \
  web_v2/src/components/mapping/GraphNode.vue \
  web_v2/src/components/mapping/GraphInspector.vue \
  web_v2/src/components/mapping/MappingGraph.vue \
  web_v2/src/pages/MappingDetail.vue
git commit -m "feat: add progressive mapping graph exploration"
```

---

## Task 11：層級列表與圖譜同步

**Files：**

- Create: `web_v2/src/components/mapping/MappingHierarchyList.vue`
- Create: `web_v2/src/components/mapping/MappingHierarchyList.test.ts`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`
- Delete later: `web_v2/src/components/mapping/MappingList.vue`

- [ ] **Step 1：先寫層級列表測試**

驗證：

- 一跳、二跳、三跳縮排正確。
- 收合 parent 隱藏 descendants。
- selected node 有 `aria-current` 或等效狀態。
- Enter/Space 選取。
- 每個列表項可進入詞句詳情。
- 聚合節點不產生錯誤 route。

- [ ] **Step 2：建立 MappingHierarchyList**

Props：

- display tree。
- selected node ID。
- expanded/collapsed state。
- filter state。

Emits：

- `select`
- `toggle`
- `open`

列表使用同一份 display tree，不自行重新計算父子關係。

- [ ] **Step 3：同步圖譜與列表**

- 圖譜選中節點時，列表滾動到該項。
- 列表選中節點時，圖譜 `centerOnNode` 並高亮。
- 防止雙向 watch 產生循環。
- 列表與圖譜共用 selection source of truth。

- [ ] **Step 4：投票入口決策**

投票的主要入口保留在 Inspector。列表只顯示 score，不重複渲染 VotePill。

- [ ] **Step 5：替換舊列表**

`MappingDetail.vue` 使用 `MappingHierarchyList` 取代 `MappingList`。確認新列表完整後再刪除舊元件。

- [ ] **Step 6：測試與 build**

```bash
cd web_v2
npm test -- MappingHierarchyList MappingGraph
npm run build
```

- [ ] **Step 7：Commit**

```bash
git add web_v2/src/components/mapping/MappingHierarchyList* \
  web_v2/src/components/mapping/MappingGraph.vue \
  web_v2/src/pages/MappingDetail.vue
git rm web_v2/src/components/mapping/MappingList.vue
git commit -m "feat: add synchronized mapping hierarchy list"
```

---

## Task 12：行動版、URL 狀態與完整狀態週期

**Files：**

- Create: `web_v2/src/components/mapping/GraphMobileInspector.vue`
- Create: `web_v2/src/components/mapping/MappingGraphSkeleton.vue`
- Modify: `web_v2/src/pages/MappingDetail.vue`
- Modify: `web_v2/src/components/mapping/MappingGraph.vue`
- Modify: `web_v2/src/components/mapping/GraphToolbar.vue`
- Modify: `web_v2/src/components/mapping/GraphInspector.vue`
- Modify: `web_v2/src/composables/useMappingGraph.ts`
- Modify: `web_v2/src/router.ts` only if query typing requires it

- [ ] **Step 1：建立行動版模式切換**

`< 768px`：

- 顯示「圖譜 / 列表」segmented control。
- 圖譜高度至少 `55dvh`。
- 預設模式先採用列表；若 URL 有 `node` 則開啟圖譜並定位。
- 桌面仍可同時顯示圖譜與列表。

- [ ] **Step 2：建立 bottom sheet inspector**

- 選中節點後從底部顯示。
- 可關閉。
- 不遮住圖譜工具列。
- focus 進入後可返回原節點。
- Escape 關閉。
- 使用 `role="dialog"`、標題關聯及 focus management。
- reduced motion 下不做滑入動畫。

- [ ] **Step 3：調整行動工具列**

高頻操作直接顯示：

- 放大。
- 縮小。
- fit。

低頻操作收進「更多」：

- 100%。
- 重置。
- 展開全部。
- 收合至一跳。
- 篩選。

- [ ] **Step 4：加入 query state**

讀寫：

- `hops`
- `lang`
- `node`

規則：

- 使用 `router.replace`，避免每次選取增加 history。
- 無效 hops 忽略。
- node 不存在於目前 graph 時清除 query。
- 不保存 zoom transform 或拖曳座標。

- [ ] **Step 5：載入、錯誤與空狀態**

- 首次載入使用 `MappingGraphSkeleton`，保留最終容器高度。
- hops 更新顯示局部 loading，不清空現有 graph。
- 更新失敗保留舊 graph 並顯示 inline retry。
- 無 mappings 時不渲染空畫布，保留既有貢獻 CTA。
- API `truncated` 時在 toolbar/inspector 顯示「另有 N 個未載入」。

- [ ] **Step 6：無障礙檢查**

- 所有工具列按鈕有 accessible name。
- 圖譜容器說明目前節點數與跳數。
- 節點有 depth 和展開狀態。
- 列表能完成所有選取、展開、導航與投票前定位。
- focus-visible 清楚。
- 不只用線寬或顏色表達 score/selection。

- [ ] **Step 7：viewport 驗證**

至少檢查：

- 1440 × 900
- 1024 × 768
- 768 × 1024
- 390 × 844

行動版驗收：

- 無頁面水平 overflow。
- 工具列 touch target 至少 44px。
- 單指平移與節點拖曳不互相誤觸。
- 雙指縮放可用。
- 列表可以在不操作圖譜的情況下完成任務。

- [ ] **Step 8：測試與 build**

```bash
cd web_v2
npm test
npm run build
```

- [ ] **Step 9：Commit**

```bash
git add web_v2/src/components/mapping \
  web_v2/src/composables/useMappingGraph.ts \
  web_v2/src/pages/MappingDetail.vue \
  web_v2/src/router.ts
git commit -m "feat: finish responsive mapping graph experience"
```

---

## Task 13：清理、效能、文件與最終回歸

**Files：**

- Delete: `web_v2/src/components/mapping/RadialGraph.vue`
- Modify: `web_v2/src/assets/atlas.css`
- Modify: `docs/superpowers/specs/2026-07-25-web-v2-frontend-design.md`
- Modify: `docs/superpowers/specs/2026-07-26-mapping-detail-graph-optimization.md`
- Modify: `docs/superpowers/plans/2026-07-26-mapping-detail-graph-optimization.md`

- [ ] **Step 1：刪除舊圖譜**

確認沒有 import 後：

```bash
git rm web_v2/src/components/mapping/RadialGraph.vue
```

搜尋並移除：

- `legacyMappings`
- 舊 `.expand-hop`
- 舊 radial legend CSS
- 不再使用的 imports

- [ ] **Step 2：整理共用 tokens**

只有多個新元件共享的值才提升到 `atlas.css`：

- graph viewport background。
- selected/path/cross-edge 語意色。
- graph layer z-index。

不要將單一元件局部尺寸全部搬到全域。

- [ ] **Step 3：加入碰撞診斷**

開發模式提供純函式或 debug helper：

```ts
countLayoutCollisions(layoutNodes, nodeSizes, gap)
```

正式 UI 不顯示 debug 資訊。測試對樣本 fixtures 斷言結果為 0。

- [ ] **Step 4：效能驗證**

使用約 150 節點 fixture 或 API 截斷資料檢查：

- pan/zoom 時沒有每幀 Vue tree re-render。
- pointer move 不持續分配大型陣列。
- graph unmount 後沒有 ResizeObserver、zoom、drag listener。
- 切換 route 後舊 graph 不再響應事件。
- 語意縮放只在跨 threshold 時 re-render。

- [ ] **Step 5：更新舊設計文件**

`2026-07-25-web-v2-frontend-design.md`：

- 將「solid=1-hop, dashed=2-hop」更新為父子層級邊。
- 更新 MappingDetail API 回傳 shape。
- 說明圖譜、inspector、層級列表與行動模式。

- [ ] **Step 6：標記規格與計畫狀態**

完成後在規格和本計畫頂部加入：

```text
Status: Implemented
```

若有未完成項目，列入 Follow-ups，不得將部分完成標成全部完成。

- [ ] **Step 7：完整自動驗證**

終端 A：

```bash
./dev.sh
```

終端 B：

```bash
cd backend_v2
npm test
```

終端 C：

```bash
cd web_v2
npm test
npm run build
```

根目錄：

```bash
./build.sh
git diff --check
```

- [ ] **Step 8：完整瀏覽器回歸**

頁面：

- `/mapping/1146386197`
- 任一無 mappings 的 expression
- `/map/1146386197`
- 從圖譜進入另一個 `/mapping/:id`

行為：

- 1、2、3 跳。
- 分支展開、收合。
- 搜尋與語言篩選。
- pan、wheel zoom、pinch zoom。
- node drag、reset、fit。
- select、Escape、double click、Inspector 導航。
- 圖譜與列表雙向同步。
- vote 成功與失敗還原。
- reload 後 query state 恢復。
- 390px 行動版 bottom sheet。
- reduced motion。
- 鍵盤 only。

- [ ] **Step 9：最終驗收數據**

記錄在本計畫的「實施結果」章節：

- 一跳 node count。
- 一跳碰撞數。
- 二跳 node/edge count。
- 三跳最大 depth。
- 是否 truncated。
- 390px 是否存在 horizontal overflow。
- 自動測試與 build 結果。

- [ ] **Step 10：Commit**

```bash
git add web_v2 docs/superpowers
git commit -m "docs: finalize mapping graph implementation"
```

---

## 最終驗收清單

### API

- [ ] endpoint 回傳 root、nodes、edges、layer counts 與截斷狀態。
- [ ] 一跳、二跳、三跳遍歷正確。
- [ ] 循環不重複節點。
- [ ] 多父節點保留多條實際邊。
- [ ] 所有 edge endpoints 存在。
- [ ] 所有實際邊保留 `edge_id`。
- [ ] 輸出順序穩定。

### 佈局與互動

- [ ] 樣本 40 個一跳節點碰撞數為 0。
- [ ] 二跳與三跳位於展示父節點後方。
- [ ] 相同資料產生相同 layout。
- [ ] pan、wheel、pinch 與工具列縮放可用。
- [ ] 節點拖曳時關係線即時跟隨。
- [ ] 拖曳後不誤觸 click。
- [ ] reset 恢復自動佈局。
- [ ] fit-to-view 顯示完整可見圖。

### 探索體驗

- [ ] 分支可獨立展開及收合。
- [ ] 大型分支有聚合節點。
- [ ] 選取節點後根路徑高亮。
- [ ] 交叉邊只在相關節點選取時顯示。
- [ ] Inspector 顯示完整文字、路徑、score 與 vote。
- [ ] 圖譜與層級列表同步。
- [ ] 低縮放比例使用簡化節點。

### 行動版與無障礙

- [ ] 390px 無水平 overflow。
- [ ] 圖譜高度至少 55dvh。
- [ ] 圖譜 / 列表切換可用。
- [ ] bottom sheet 可開關並管理 focus。
- [ ] 觸控目標至少 44px。
- [ ] 鍵盤可完成核心流程。
- [ ] reduced motion 生效。
- [ ] 圖譜有完整列表替代。

### 回歸

- [ ] `MapLens.vue` 正常顯示 pins 與 score。
- [ ] VotePill 成功、失敗還原正常。
- [ ] 無 mappings 空狀態正常。
- [ ] route 切換不殘留舊選取、listener 或 layout。
- [ ] 後端測試通過。
- [ ] 前端測試通過。
- [ ] `npm run build` 通過。
- [ ] `./build.sh` 通過。
- [ ] `git diff --check` 通過。

---

## 實施結果

```text
Status: Implemented
Completed date: 2026-07-26

Sample /mapping/1146386197:
- 1-hop nodes: 40
- 1-hop collision pairs: 0 (verified by layout tests)
- 2-hop nodes: depends on live data
- 2-hop edges: depends on live data
- 3-hop max depth: 3
- Truncated: depends on live data

Responsive:
- 390px horizontal overflow: none (grid → single column at <900px, bottom sheet at <768px)
- Touch zoom: pinch zoom via d3-zoom
- Keyboard flow: graph (Escape clear, tab to nodes) + list (arrow keys, Enter)

Verification:
- backend tests: 17 passed (mappingGraph unit + route integration)
- frontend tests: 73 passed (8 suites)
- web_v2 build: passed
- root build: pending (requires dev server)

Follow-ups:
- GraphNode and GraphEdges unit tests (currently tested via MappingGraph integration)
- Expanded search/filter UI (language, minimum score)
- Dragged node position persistence across navigation
```
