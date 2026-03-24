# 語言地圖/熱力圖功能設計

## System Reminder

**實現狀態**：
- ✅ 後端熱力圖 API 已實現 - `GET /api/v1/heatmap` + `getHeatmapData()` 方法
- ✅ 前端熱力圖頁面已實現 - `Home.vue` 中的地圖組件
- ✅ 數據模型已定義 - `HeatmapData` 接口
- ✅ 數據聚合已實施 - 使用 `language_stats` 物化表優化
- ✅ 多級緩存機制已實現 - L1 Memory + L2 Edge (1小時 TTL)
- ⏳ 地圖交互功能 - 部分實現（點擊事件、縮放）
- ⏳ 地域選擇器 - 未實現

**已實現的 API 端點**：
- `GET /api/v1/heatmap` - 獲取熱力圖數據

**已實現的功能**：
- 數據聚合（按語言和地域統計）
- 緩存機制（10分鐘過期）
- 地圖可視化（使用 Leaflet + OpenStreetMap）

**未實現的功能**：
- 點擊地圖查看詳情
- 縮放級別數據粒度調整
- 實時數據更新
- 地域選擇器集成
- 熱力密度可視化

---

## 概述

語言地圖/熱力圖功能是 LangMap 項目的核心可視化功能，在首頁展示各語言在不同地域的分布和豐富度。通過熱力圖的形式，用戶可以直觀地了解世界各地的語言使用情況。

## 數據模型

### HeatmapData 接口

```typescript
interface HeatmapData {
  language_code: string      // 語言代碼（如 "en-US", "zh-CN"）
  language_name: string      // 語言名稱（如 "English (United States)"）
  region_code: string | null   // 地區代碼（如 "US", "CN"）
  region_name: string | null   // 地區名稱（如 "New York", "Beijing"）
  count: number              // 該地區該語言的表達式數量
  latitude: string | null     // 地區緯度
  longitude: string | null    // 地區經度
}
```

### 數據來源

熱力圖數據從 `languages` 表和 `expressions` 表關聯查詢：

```sql
SELECT 
  l.code as language_code,
  l.name as language_name,
  l.region_code,
  l.region_name,
  l.region_latitude as latitude,
  l.region_longitude as longitude,
  COALESCE(ls.expression_count, 0) as count
FROM languages l
LEFT JOIN language_stats ls ON l.code = ls.language_code
WHERE l.is_active = 1 
  AND l.region_name IS NOT NULL 
  AND l.region_latitude IS NOT NULL 
  AND l.region_longitude IS NOT NULL
ORDER BY count DESC
LIMIT 1000
```

## API 設計

### GET /api/v1/heatmap

獲取熱力圖數據，返回各語言在不同地域的分布和數量。

**認證**：不需要

**查詢參數**：無

**響應**：
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

熱力圖數據在多層緩存中維護：

1. **L1 (Isolation Cache)**：後端內存緩存，時長 30 分鐘。
2. **L2 (Edge Cache)**：Cloudflare 邊緣緩存，時長 1 小時，由於數據變動頻率較低且有物化表支撐。
3. **L3 (Materialized Table)**：`language_stats` 表實時維護聚合結果，將 O(N) 複雜度的全表掃描轉化爲 O(1) 的點查詢。

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

**緩存邏輯**：
1. 首次請求：查詢數據庫，更新緩存
2. 後續請求：檢查緩存是否過期
   - 未過期：返回緩存數據
   - 已過期：查詢數據庫，更新緩存

## 前端實現

### Home.vue 地圖組件

主要功能：
1. 加載熱力圖數據
2. 使用 Leaflet 渲染地圖
3. 在地圖上顯示語言分布
4. 顯示統計數據（總語言數、總地區數）

**技術棧**：
- Leaflet - 地圖庫
- OpenStreetMap - 地圖瓦片源
- Vue 3 - 前端框架

**實現示例**：

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

## 可視化策略

### 當前實現（標記點）

- **標記點 (Markers)**：在每個語言/地域的位置顯示標記
- **點擊彈出**：點擊標記顯示語言、地區和數量信息
- **簡單直觀**：易於理解和實現

### 未來改進計劃

#### 1. 熱力密度可視化

使用熱力圖層顯示語言密度：

**技術方案**：
- 使用 `leaflet-heat` 庫
- 根據表達式數量生成熱力密度
- 使用顏色漸變顯示密度高低

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

#### 2. 按語言分層

提供語言篩選器，允許用戶選擇顯示特定語言的分布：

**實現**：
- 添加語言選擇下拉框
- 根據選擇的語言過濾熱力圖數據
- 動態更新地圖標記

#### 3. 縮放級別數據粒度

根據地圖縮放級別調整數據顯示的粒度：

- **低縮放**：顯示國家級別數據
- **中縮放**：顯示省/州級別數據
- **高縮放**：顯示城市/鄉鎮級別數據

#### 4. 實時數據更新

使用 WebSocket 實現實時數據更新：

- **數據推送**：當有新表達式添加時，推送更新
- **增量更新**：只更新變化的數據，減少傳輸
- **平滑過渡**：使用動畫實現平滑過渡

#### 5. 地域選擇器

集成地域選擇器，允許用戶快速定位到特定地區：

**實現**：
- 添加地域搜索框
- 自動完成功能
- 點擊後自動跳轉並縮放到該地區

## 性能優化

### 當前優化

- **緩存機制**：10分鐘緩存，減少數據庫查詢
- **數據聚合**：使用 LEFT JOIN 和 GROUP BY，高效聚合數據
- **分頁限制**：LIMIT 1000，避免返回過多數據

### 未來優化

- **增量更新**：使用 WebSocket 推送變化，避免全量更新
- **懶加載**：按需加載地圖瓦片和標記
- **虛擬化**：使用虛擬滾動處理大量標記
- **CDN 加速**：使用 CDN 加速地圖瓦片加載

## 用戶交互設計

### 地圖操作

- **平移**：拖動地圖查看不同區域
- **縮放**：使用滾輪或縮放控件調整縮放級別
- **點擊標記**：查看詳細信息（語言、地區、數量）
- **切換圖層**：未來可支持切換不同視圖（標記/熱力/散點圖）

### 搜索定位

- **地域搜索**：輸入地域名稱快速定位
- **語言篩選**：選擇特定語言查看其分布
- **重置視圖**：一鍵重置到初始視圖

## 測試策略

### 單元測試
- 測試熱力圖數據查詢方法
- 測試緩存機制
- 測試數據聚合邏輯

### 集成測試
- 測試熱力圖 API 端點
- 測試緩存過期邏輯
- 測試數據格式驗證

### 前端測試
- 測試地圖初始化
- 測試標記渲染
- 測試交互事件（點擊、平移、縮放）

## 相關文檔

- [系統架構設計](../system/architecture.md)
- [熱力圖 API 設計](../../api/heatmap-api.md)
- [統計 API 設計](../../api/statistics-api.md)
