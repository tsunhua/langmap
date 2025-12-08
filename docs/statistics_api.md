# Statistics API 设计文档

## 概述

本文档描述了新增的统计接口 [/statistics](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L18-L18)，用于提供系统的核心统计数据，包括表达式总数、语言总数和地区总数。该接口旨在替代原先在前端通过请求所有表达式数据并计算统计信息的方式，以提高性能和减轻服务器负载。

## 背景

在原有的实现中，首页统计数据（总表达式数、总语言数、总地区数）是通过前端向 [/api/v1/expressions](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L36-L53) 发送请求获取所有表达式数据，然后在浏览器中进行计算得到的。这种方式存在以下问题：

1. 性能问题：随着表达式数量增加，传输数据量会变得很大，影响加载速度
2. 资源浪费：获取所有表达式数据仅用于统计计算，浪费网络带宽和服务器资源
3. 用户体验：用户需要等待大量数据传输和计算完成才能看到统计数据

为了解决这些问题，我们实现了专门的统计接口，直接在服务器端计算并返回统计数据。

## API 端点

### 获取系统统计信息

- **URL**: `/api/v1/statistics`
- **方法**: `GET`
- **认证**: 不需要

### 响应格式

```json
{
  "total_expressions": 1250,
  "total_languages": 24,
  "total_regions": 18
}
```

### 响应字段说明

| 字段名 | 类型 | 描述 |
|--------|------|------|
| total_expressions | integer | 系统中表达式的总数量 |
| total_languages | integer | 系统中激活语言的总数量 |
| total_regions | integer | 系统中不同地区的总数量 |

### SQL 查询逻辑

根据您的建议，我们将使用更高效的查询方式：

1. **total_expressions**: 
   ```sql
   SELECT COUNT(*) as count FROM expressions
   ```
   直接统计 expressions 表中的行数来获取表达式总数。

2. **total_languages**: 
   ```sql
   SELECT COUNT(*) as count FROM languages WHERE is_active = 1
   ```
   统计激活的语言数量。

3. **total_regions**: 
   ```sql
   SELECT COUNT(DISTINCT region_name) as count 
   FROM languages 
   WHERE region_name IS NOT NULL AND region_name != ''
   ```
   统计 languages 表中不同的地区数量，而不是从 expressions 表中获取。

## 实现细节

### 后端实现

1. 在数据库抽象层添加 `getStatistics()` 方法
2. 在 D1 数据库实现中具体实现统计查询逻辑
3. 在 API v1 路由中添加 [/statistics](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L18-L18) 端点

### 前端实现

1. 修改 Home.vue 组件，使其通过 [/api/v1/statistics](file:///Users/lim/Documents/Code/tsunhua/langmap/backend/src/server/api/v1.ts#L18-L18) 接口获取统计数据
2. 保留原有的热力图数据获取逻辑，因为这部分仍需要详细的表达式信息

## 缓存机制

为了进一步提高性能，我们将在统计接口中实现缓存机制：

1. 默认缓存时间为10分钟（600秒）
2. 缓存将在以下情况下失效：
   - 当有新的表达式被创建时
   - 当有语言被激活/停用时
   - 当有地区信息被更新时
   - 手动清除缓存

在 Cloudflare Workers 环境中，我们可以使用以下方式实现缓存：
1. 使用 Worker 的全局变量存储缓存数据（适用于单个 Worker 实例）
2. 使用 KV 存储实现分布式缓存（适用于多个 Worker 实例）

## 性能优势

1. **减少数据传输**: 原先需要传输所有表达式记录（可能上千条），现在只需要传输3个数字
2. **降低服务器负载**: 数据库只需执行简单的 COUNT 查询，而不需要检索所有表达式数据
3. **提升用户体验**: 页面加载速度显著提升，统计数据几乎可以瞬间显示
4. **优化查询逻辑**: 根据建议，从 languages 表统计地区数量比从 expressions 表统计更加高效和准确
5. **缓存机制**: 通过添加缓存，可以进一步减少数据库查询次数，提高响应速度

## 测试用例

### 成功响应
```
GET /api/v1/statistics

Response:
Status: 200 OK
Content-Type: application/json

{
  "total_expressions": 1250,
  "total_languages": 24,
  "total_regions": 18
}
```

### 错误处理
如果发生数据库错误，接口应该返回 500 错误：
```
Status: 500 Internal Server Error
Content-Type: application/json

{
  "error": "Failed to fetch statistics"
}
```

## 后续优化建议

1. 添加缓存机制，定期刷新统计数据而非每次请求都查询数据库
2. 扩展统计接口，提供更多维度的统计数据，如：
   - 按语言分组的表达式数量
   - 用户贡献统计
   - 最近添加的表达式数量
3. 添加历史趋势数据，支持统计图表展示