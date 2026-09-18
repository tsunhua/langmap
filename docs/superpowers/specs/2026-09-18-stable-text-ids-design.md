# 稳定文字标识（stable text keys）设计

日期：2026-09-18
状态：已与用户逐段确认

## 背景与动机

前端 URL 与 API 目前以内部整数 id 标识 expression（`/mapping/123`、`GET /expressions/123`）。整数 id 在数据迁移（进行中的 D1 → Postgres 迁移）与数据修复过程中会被重新分配，导致对外链接失效。

数据模型已具备稳定自然键：

- `expressions` 表：`UNIQUE (language_id, text, homograph_index)`（migration 0003 / 0038）
- `expression_edges` 表：`UNIQUE (expression_a_id, expression_b_id)`（mapping 的自然身份即两端 expression 自然键的组合）

本设计将对外标识从整数 id 切换为自然文字 key，使 URL 与 API 查询参数对 id 重编号免疫。

## 决策摘要

| 决策点 | 结论 |
|---|---|
| 替换范围 | URL + API 查询参数改用稳定 key；API 回应保留数字 id 供内部操作（如 split 的 `edge_ids`） |
| Key 形式 | 自然文字 key（`/mapping/en/hello`、同形词尾缀 `~2`） |
| Mapping 配对 URL | 不需要，URL 只标识 expression（维持现状） |
| 旧数字 URL | 页面层自动转址（canonicalize）至文字 URL；API 层双形式接受 |

不采用的两个替代方案：

- **前端解析层**（后端不动，route guard 先 resolve key → id）：每次导航多一次 round-trip，API 仍以 id 为主，未真正移除暴露。
- **衍生哈希 key / 存储 slug 列**：URL 短但不可读，与「使用 text」目标不符；slug 列需 schema 变更与回填，无必要。

## 1. Key 格式与编码规则

```
页面 URL:  /mapping/{lang_code}/{text}~{N}      （N 省略 = homograph 1）
           /map/{lang_code}/{text}~{N}
API:       GET /expressions/{lang_code}/{text}~{N}
           GET /expressions/{lang_code}/{text}~{N}/graph
           GET /expressions/{lang_code}/{text}~{N}/edges
           PUT/DELETE /expressions/{lang_code}/{text}~{N}/locales/{locale}
           POST /expressions/{lang_code}/{text}~{N}/readings
           POST /expressions/{lang_code}/{text}~{N}/split
```

- `lang_code` 为独立 path segment（registry code，字符集受限：字母数字连字符，如 `en`、`nan`、`x-image`）。
- `text` 为单个 path segment，经 `encodeURIComponent` 编码；文字中的 `/` 编为 `%2F`。vue-router 与 Hono 均在 raw path 上匹配后才 decode，segment 不会被切开（实现时需以测试验证）。
- **`~` 语义保留**：text 部分一律把 `~` 编为 `%7E`（合法 percent-encoding），因此尾端字面 `~N` 无歧义地表示 `homograph_index`。
- 长例句文字：URL 较长但功能正常，已确认为可接受。
- 查找为精确匹配（stored text），不做查找时的文本规范化；创建路径的规范化维持现状。

## 2. 后端：解析服务与路由

新增 `backend/src/services/expressionKeys.ts`：

- `parseExpressionKey(lang, text)` → `{ lang_code, text, homograph_index } | null`
  - 两段皆 percent-decode；text 尾端未编码的 `~\d+` 解析为 `homograph_index`（缺省 1）。
- `resolveExpressionKey(db, key)` → `ExpressionRow | null`
  - `JOIN languages ON code = lang_code`，`WHERE language_id=? AND text=? AND homograph_index=?`，命中现有 UNIQUE index。

路由变更（`backend/src/routes/expressions.ts`）：

| 端点 | 现在 | 之后 |
|---|---|---|
| `GET /expressions/:id` | 数字 id | 双段文字 key + 数字回退（见 §3） |
| `GET /expressions/:id/graph`、`/edges` | 数字 id | 同上 |
| `PUT/DELETE /expressions/:id/locales/:locale` | 数字 id | 同上 |
| `POST /expressions/:id/readings` | 数字 id | 同上 |
| `POST /expressions/:id/split` | 数字 id | 路径改 key；**body 的 `edge_ids` 维持数字** |
| `POST /expressions` | — | 不变；回应包含新 expression 的 `lang_code`/`text`/`homograph_index` |

其他读取端点（search、language expressions、feed、graph）回应结构不变——已携带 `lang_code`+`text`。补齐缺失字段：

- `ExpressionDetail.expression` 补 `homograph_index`。
- split 回应的 target expression 补 key 所需字段（`lang_code`/`text`/`homograph_index`）。

错误处理（沿用现有 error envelope）：

- key 格式无效 → 400
- lang/text/homograph 找不到 → 404

## 3. 数字 URL 兼容与转址

**API 层——双形式接受，不转址**：`/expressions/*` 系列端点先尝试文字 key（双段），若路径为单段纯数字则回退为 id 查找。

**页面层——route guard 转址（canonicalize）**：`/mapping/:id`、`/map/:id`（单段数字）路由保留，guard 逻辑：

1. 调用 `GET /expressions/{id}` 取得 detail（含 key 字段）。
2. `router.replace` 至 `/mapping/{lang}/{text}~{N}`（replace 不留历史记录，避免返回键卡在数字 URL）。

**时效性**：D1→PG 迁移重编 id 后，数字回退自然失效（404），为预期行为；文字 URL 不受影响。

## 4. 前端变更

路由（`web/src/router.ts`）：

```typescript
{ path: '/mapping/:lang/:text(.*)', component: MappingDetail }   // 新 canonical
{ path: '/mapping/:id',             component: MappingDetail }   // 旧形式 → guard 转址
{ path: '/map/:lang/:text(.*)',     component: MapLens }
{ path: '/map/:id',                 component: MapLens }
```

新增 `web/src/utils/expressionUrl.ts`：

```typescript
// expressionPath(lang, text, homographIndex = 1) → '/mapping/en/hello' | '/mapping/en/hello~2'
// 编码规则集中在此：encodeURIComponent + `~` → `%7E`
```

连产生点改造（数据来源均已携带 `lang_code`+`text`）：

| 文件 | 改动 |
|---|---|
| `web/src/components/expression/ExpressionRow.vue` | 改用 `expressionPath`；props 需补 `homograph_index` |
| `web/src/pages/MappingDetail.vue` | `navigateToNode`（graph node 带 `lang_code`+`text`）、`submitQuickAdd`、`confirmSplit` |
| `web/src/pages/MapLens.vue` | `openMapping` 改用 node 的 lang/text |
| `web/src/components/feed/NewContribution.vue` | feed row 的 `a_lang`/`a_text` 组 key |
| `MorphologyPanel` / `ExpressionSplitDialog` 等 lemma 连结 | 同样改 helper |

API 层（`web/src/api/expressions.ts`）：`path(id)` 改为 `keyPath(lang, text, homograph?)`，各函数签名由 id 改为 key 参数。

错误处理：`/mapping/:id` guard 解析失败（id 已因迁移失效）→ 404 页面，讯息提示数据已迁移。

## 5. 测试

后端：

- `expressionKeys` 单元测试：unicode、`/`（`%2F`）、`~`（`%7E`）编码、homograph 尾缀解析、格式错误。
- 路由整合测试：文字 key 查找、数字回退、404/400、split 路径 key + body 数字 edge_ids。

前端：

- `expressionUrl` helper 测试：编码边界（`~`、`/`、unicode、homograph 缺省与显式）。
- router guard 转址测试：数字 → 文字 replace、失效 id → 404。

## 6. 实施顺序

1. 本设计先行落地（移除公开介面对 id 的依赖）。
2. 之后进行 D1 → PG 迁移（id 重编号不再影响对外链接）。

## 已确认的局限

- 文字本身若被修正/重命名，URL 仍会断（key 稳定性以 text 稳定为前提）。
- 长例句 URL 较长（已接受）。
- 迁移后旧数字连结失效（已接受，guard 提供 404 说明）。
