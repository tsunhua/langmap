# 语言地图/热力图功能设计

## System Reminder

**实现状态**：
- ✅ 后端热力图 API 已实现 - `GET /api/v1/heatmap` + `getHeatmapData()` 方法
- ✅ 前端热力图页面已实现 - `Home.vue` 中的地图组件
- ✅ 数据模型已定义 - `HeatmapData` 接口
- ✅ 数据聚合已实现 - 从 languages 表聚合数据
- ✅ 缓存机制已实现 - 10分钟缓存
- ⏳ 地图交互功能 - 部分实现（点击事件、缩放）
- ⏳ 地域选择器 - 未实现

**已实现的 API 端点**：
- `GET /api/v1/heatmap` - 获取热力图数据

**已实现的功能**：
- 数据聚合（按语言和地域统计）
- 缓存机制（10分钟过期）
- 地图可视化（使用 Leaflet + OpenStreetMap）

**未实现的功能**：
- 点击地图查看详情
- 缩放级别数据粒度调整
- 实时数据更新
- 地域选择器集成
- 热力密度可视化

---

## 概述

语言地图/热力图功能是 LangMap 项目的核心可视化功能，在首页展示各语言在不同地域的分布和丰富度。通过热力图的形式，用户可以直观地了解世界各地的语言使用情况。

## 数据模型

### HeatmapData 接口

```typescript
interface HeatmapData {
  language_code: string      // 语言代码（如 "en-US", "zh-CN"）
  language_name: string      // 语言名称（如 "English (United States)"）
  region_code: string | null   // 地区代码（如 "US", "CN"）
  region_name: string | null   // 地区名称（如 "New York", "Beijing"）
  count: number              // 该地区该语言的表达式数量
  latitude: string | null     // 地区纬度
  longitude: string | null    // 地区经度
}
```

### 数据来源

热力图数据从 `languages` 表和 `expressions` 表关联查询：

```sql
SELECT 
  l.code as language_code,
  l.name as language_name,
  l.region_code,
  l.region_name,
  l.region_latitude as latitude,
  l.region_longitude as longitude,
  COALESCE(e.expression_count, 0) as count
FROM languages l
LEFT JOIN (
  SELECT 
    language_code, 
    COUNT(*) as expression_count
  FROM expressions 
  GROUP BY language_code
) e ON l.code = e.language_code
WHERE l.is_active = 1 
  AND l.region_name IS NOT NULL 
  AND l.region_latitude IS NOT NULL 
  AND l.region_longitude IS NOT NULL
ORDER BY count DESC
LIMIT 1000
```

## API 设计

### GET /api/v1/heatmap

获取热力图数据，返回各语言在不同地域的分布和数量。

**认证**：不需要

**查询参数**：无

**响应**：
```json
{
  "data": [
    {
      "language_code": "en-US",
      "language_name": "English (United States)",
      "region_code": "US",
      "region_name": "New York",
      "count": 42,
      "latitude": "40.7128",
      "longitude": "-74.0060"
    },
    {
      "language_code": "zh-CN",
      "language_name": "Chinese (Simplified)",
      "region_code": "CN",
      "region_name": "Beijing",
      "count": 38,
      "latitude": "39.9042",
      "longitude": "116.4074"
    }
  ]
}
```

### 缓存机制

热力图数据在内存中缓存，缓存时长为 10 分钟：

```typescript
let heatmapCache: {
  data: HeatmapData[] | null;
  timestamp: number | null;
} = {
  data: null,
  timestamp: null
};
const HEATMAP_CACHE_DURATION = 10 * 60 * 1000; // 10 minutes
```

**缓存逻辑**：
1. 首次请求：查询数据库，更新缓存
2. 后续请求：检查缓存是否过期
   - 未过期：返回缓存数据
   - 已过期：查询数据库，更新缓存

## 前端实现

### Home.vue 地图组件

主要功能：
1. 加载热力图数据
2. 使用 Leaflet 渲染地图
3. 在地图上显示语言分布
4. 显示统计数据（总语言数、总地区数）

**技术栈**：
- Leaflet - 地图库
- OpenStreetMap - 地图瓦片源
- Vue 3 - 前端框架

**实现示例**：

```vue
<template>
  <div class="home">
    <div ref="mapContainer" class="map-container"></div>
    <div class="stats">
      <div>Total Languages: {{ stats.total_languages }}</div>
      <div>Total Regions: {{ stats.total_regions }}</div>
    </div>
  </div>
</template>

<script>
import L from 'leaflet'

export default {
  data() {
    return {
      map: null,
      heatmapData: [],
      stats: {
        total_languages: 0,
        total_regions: 0
      }
    }
  },
  async mounted() {
    await this.loadHeatmapData()
    this.initMap()
  },
  methods: {
    async loadHeatmapData() {
      const response = await fetch('/api/v1/heatmap')
      const json = await response.json()
      this.heatmapData = json.data
      this.calculateStats()
    },
    initMap() {
      this.map = L.map(this.$refs.mapContainer).setView([20, 0], 2)
      
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: 'OpenStreetMap contributors'
      }).addTo(this.map)
      
      this.renderMarkers()
    },
    renderMarkers() {
      this.heatmapData.forEach(item => {
        const marker = L.marker([item.latitude, item.longitude])
          .bindPopup(`
            <b>${item.language_name}</b><br>
            Region: ${item.region_name}<br>
            Count: ${item.count}
          `)
          .addTo(this.map)
      })
    },
    calculateStats() {
      const languages = new Set(this.heatmapData.map(d => d.language_code))
      const regions = new Set(this.heatmapData.map(d => d.region_code))
      
      this.stats = {
        total_languages: languages.size,
        total_regions: regions.size
      }
    }
  }
}
</script>
```

## 可视化策略

### 当前实现（标记点）

- **标记点 (Markers)**：在每个语言/地域的位置显示标记
- **点击弹出**：点击标记显示语言、地区和数量信息
- **简单直观**：易于理解和实现

### 未来改进计划

#### 1. 热力密度可视化

使用热力图层显示语言密度：

**技术方案**：
- 使用 `leaflet-heat` 库
- 根据表达式数量生成热力密度
- 使用颜色渐变显示密度高低

```javascript
import 'leaflet-heat'

const heat = L.heatLayer(heatData, {
  radius: 25,
  blur: 15,
  maxZoom: 10,
  gradient: {
    0.4: 'blue',
    0.65: 'lime',
    1: 'red'
  }
}).addTo(map)
```

#### 2. 按语言分层

提供语言筛选器，允许用户选择显示特定语言的分布：

**实现**：
- 添加语言选择下拉框
- 根据选择的语言过滤热力图数据
- 动态更新地图标记

#### 3. 缩放级别数据粒度

根据地图缩放级别调整数据显示的粒度：

- **低缩放**：显示国家级别数据
- **中缩放**：显示省/州级别数据
- **高缩放**：显示城市/乡镇级别数据

#### 4. 实时数据更新

使用 WebSocket 实现实时数据更新：

- **数据推送**：当有新表达式添加时，推送更新
- **增量更新**：只更新变化的数据，减少传输
- **平滑过渡**：使用动画实现平滑过渡

#### 5. 地域选择器

集成地域选择器，允许用户快速定位到特定地区：

**实现**：
- 添加地域搜索框
- 自动完成功能
- 点击后自动跳转并缩放到该地区

## 性能优化

### 当前优化

- **缓存机制**：10分钟缓存，减少数据库查询
- **数据聚合**：使用 LEFT JOIN 和 GROUP BY，高效聚合数据
- **分页限制**：LIMIT 1000，避免返回过多数据

### 未来优化

- **增量更新**：使用 WebSocket 推送变化，避免全量更新
- **懒加载**：按需加载地图瓦片和标记
- **虚拟化**：使用虚拟滚动处理大量标记
- **CDN 加速**：使用 CDN 加速地图瓦片加载

## 用户交互设计

### 地图操作

- **平移**：拖动地图查看不同区域
- **缩放**：使用滚轮或缩放控件调整缩放级别
- **点击标记**：查看详细信息（语言、地区、数量）
- **切换图层**：未来可支持切换不同视图（标记/热力/散点图）

### 搜索定位

- **地域搜索**：输入地域名称快速定位
- **语言筛选**：选择特定语言查看其分布
- **重置视图**：一键重置到初始视图

## 测试策略

### 单元测试
- 测试热力图数据查询方法
- 测试缓存机制
- 测试数据聚合逻辑

### 集成测试
- 测试热力图 API 端点
- 测试缓存过期逻辑
- 测试数据格式验证

### 前端测试
- 测试地图初始化
- 测试标记渲染
- 测试交互事件（点击、平移、缩放）

## 相关文档

- [系统架构设计](../system/architecture.md)
- [热力图 API 设计](../../api/heatmap-api.md)
- [统计 API 设计](../../api/statistics-api.md)
