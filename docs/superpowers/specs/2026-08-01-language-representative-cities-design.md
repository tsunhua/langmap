# 語言代表性城市設計

> 狀態：已實作核心 schema、生成器、seed data、API 與語言詳情列表。
>
> 尚未執行線上 observed code migration；目前 region code 仍保留作為內容變體。

## 1. 背景

LangMap 目前以 canonical BCP 47 content tag 作為 `languages.code`。其中
`region` 應描述內容的地區化慣例，不應被解讀為語言所屬國家或完整使用範圍。

語言通常跨越國界與行政區，也可能在同一地區重疊使用。若為了地圖呈現而把
每個使用地區都寫進 `languages.code`，會造成重複 profile，並讓政治邊界取代
語言 identity。若進一步把城市寫進 private-use code，則會造成 code 爆炸，且
城市邊界仍不等於語言邊界。

本設計採用一個刻意簡化的模型：只記錄語言變體的「代表性城市」。它服務於
地圖標點與按城市探索，不聲稱描述完整語言地理分布。

## 2. 目標

- 語言 identity 不由國家、地區或城市決定。
- 城市不進入 `languages.code`。
- 一個語言變體可以關聯一個或多個代表性城市。
- 全國廣泛使用的語言，預設使用首都作為代表性城市。
- 區域性語言使用公認的核心城市；有多個重要中心時可保留多筆。
- 每筆城市資料保留地圖座標與最小來源資訊。
- 沿用目前 `variety_key`，不新增 `language_varieties` 或通用地點圖譜。
- 生成流程可離線重現，輸出穩定排序，錯誤資料在生成階段失敗。

## 3. 非目標

- 不描述語言的完整分布範圍、人口或使用比例。
- 不建立國家、行政區、文化區或城市的階層模型。
- 不儲存 GeoJSON、多邊形、邊界或方言帶。
- 不以代表性城市推斷語言、方言或 Glottolog identity。
- 不因同一語言有多個代表性城市而自動建立多個 BCP 47 profile。
- 不在本階段提供社群新增、編輯或審核代表性城市的 UI。
- 不改動 Glottolog 或 IANA 上游資料。

## 4. 核心語意

### 4.1 `languages.code`

`languages.code` 仍是 BCP 47 content tag：

```text
language[-Script][-REGION][-variant...][-x-private...]
```

`region` 只在內容確實具有地區化慣例時使用，例如拼字、詞彙、正字法或正式
locale convention 不同。下列理由本身不足以加入 region：

- 該語言在某地有人使用。
- 該城市被選為地圖代表點。
- 該地是語言的核心或歷史使用區。
- 該語言在某地具有官方或區域地位。

因此實作時需審核現有 seed code：可由 script 或 languoid 充分區分的 profile
應移除不必要 region；確有內容慣例差異者保留。不得機械式移除所有 region。

### 4.2 代表性城市

代表性城市是地圖與探索入口，不是語言邊界。每筆資料只表示：

> 此城市可作為這個語言變體及書寫 profile 的一個代表性地圖點。

選擇規則：

1. 全國廣泛使用的語言，預設選首都。
2. 區域性語言，選公認核心城市。
3. 有多個同等重要中心時，可記錄多個城市。
4. 同一城市若有多種主要 script，可分別記錄。
5. 無可靠城市依據時不猜測，允許暫無資料。
6. UI 一律稱為「代表性城市」，不得稱為「完整分布」或「主要領土」。

## 5. 資料模型

新增單一資料表，不建立 `places` 表：

```sql
CREATE TABLE language_locations (
    variety_key TEXT NOT NULL,
    city_name TEXT NOT NULL,
    city_name_en TEXT,
    territory_code TEXT NOT NULL,
    script_code TEXT NOT NULL DEFAULT '',
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    reference TEXT NOT NULL,
    PRIMARY KEY (variety_key, city_name, territory_code, script_code)
);

CREATE INDEX idx_language_locations_variety
  ON language_locations(variety_key);
CREATE INDEX idx_language_locations_city
  ON language_locations(city_name, territory_code);
```

欄位語意：

- `variety_key`：沿用 `languages.variety_key`，把同一 languoid 的不同 content
  profile 歸到相同語言變體。
- `city_name`：當地常用城市名稱。
- `city_name_en`：可選英文名稱，作為跨語搜尋與 fallback。
- `territory_code`：ISO 3166-1 territory code，只協助消歧與定位；不表示主權、
  國家屬性或語言歸屬。`HK`、`MO` 等均按 territory 處理。
- `script_code`：ISO 15924 code；與 script 無關時保存空字串。
- `latitude`、`longitude`：城市代表點，不是語言中心或分布邊界。
- `reference`：支持該城市選擇的來源 URL 或可追溯來源描述。

`variety_key` 目前不是獨立資料表主鍵，因此本階段不加資料庫 foreign key。
生成器必須驗證每個 location 的 `variety_key` 至少存在於一筆 seed language；
這是刻意接受的簡化。若日後開放社群維護，再評估是否建立
`language_varieties` 表。

## 6. Seed 與 artifacts

代表性城市由現有 `language_seed_profiles.json` 的頂層 `locations` 陣列維護，
避免再引入一套設定入口：

```json
{
  "version": 3,
  "languages": [],
  "locations": [
    {
      "variety_key": "glotto:yuec1235",
      "city_name": "廣州",
      "city_name_en": "Guangzhou",
      "territory_code": "CN",
      "script_code": "Hans",
      "latitude": 23.1291,
      "longitude": 113.2644,
      "reference": "https://glottolog.org/resource/languoid/id/yuec1235"
    }
  ]
}
```

`sync_language_registry.py` 新增生成：

- `language-locations.csv`
- `language-registry.sql` 中的 `language_locations` idempotent upsert
- `manifest.json` 中的 `language_location_count`

CSV 欄位與資料表一致，按
`variety_key, territory_code, city_name, script_code` 穩定排序。

## 7. 查詢與呈現

查詢路徑保持簡單：

```text
languages.code
  → languages.variety_key
  → language_locations.variety_key
```

語言詳情 API 可在既有回應中加入 `representative_cities`：

```json
{
  "representative_cities": [
    {
      "name": "廣州",
      "name_en": "Guangzhou",
      "territory_code": "CN",
      "script_code": "Hans",
      "latitude": 23.1291,
      "longitude": 113.2644,
      "reference": "https://glottolog.org/resource/languoid/id/yuec1235"
    }
  ]
}
```

前端只用城市點標示，不繪製語言範圍。若同一 variety 有多個 content profile，
先按 `variety_key` 取得城市，再以當前 `script_code` 優先篩選；`script_code` 為
空字串的城市對所有 profile 可見。

## 8. 現有資料調整

實作時需人工審核目前 `language_seed_profiles.json`：

- 將純粹為表達使用地而加入的 region 從 code 移除。
- 將城市資訊搬到 `locations`。
- 確有內容慣例差異的 region 保留，不因本設計而移除。
- 多個舊 code 收斂成一個新 code 時，先盤點線上 expression 使用量，再建立
  明確的一次性 migration；不可猜測或長期維護 alias。
- `und`、`x-emoji`、`x-image` 不需要代表性城市。
- 既有特殊方言 profile 若無可靠城市來源，可暫時沒有 location。

例如粵語可收斂為 content profile：

```text
yue-Hans
yue-Hant
```

並以 location rows 表示廣州、香港與澳門。若審核證明香港或澳門存在必須由
region 表達的內容慣例，則保留對應 region profile；城市資料仍不取代該
content 差異。

## 9. 驗證與錯誤處理

生成器必須拒絕：

- `variety_key` 不存在於 seed languages。
- `territory_code` 不存在於 pinned IANA region registry。
- 非空 `script_code` 不存在於 pinned IANA script registry。
- 經緯度超出合法範圍。
- composite primary key 重複。
- `city_name`、`reference` 為空。
- 輸出排序不穩定或離線重跑產生不同內容。

生成失敗時不得留下部分更新 artifacts；沿用目前 temporary file／完整生成後
替換的策略。

## 10. 測試與驗收

至少包含：

1. location profile schema 與必填欄位測試。
2. territory、script、座標與 `variety_key` 驗證測試。
3. 重複城市關聯測試。
4. offline generator deterministic 測試。
5. SQL 在空資料庫及已載入資料庫皆可 idempotent 執行。
6. API 依 `variety_key` 回傳代表性城市，並正確處理 script 篩選。
7. 沒有 location 的語言仍可正常讀取，回傳空陣列。
8. 現有 code migration 不產生孤兒 expression。
9. 前端文字明確使用「代表性城市」，且地圖只顯示點。

驗收完成後，`languages.csv` 只負責 content profile；
`language-locations.csv` 只負責代表性城市，兩者不互相冒充。

## 11. 相容與回退

- 新表與新 CSV 為增量資料；尚未使用 location 的 API 可忽略它。
- code 收斂屬獨立 migration，必須在部署前備份並驗證引用數量。
- 若 location 功能需回退，可停止載入與查詢 `language_locations`，不影響
  `languages` 或 expressions。
- 已完成的 code migration 不因關閉 location 功能而自動逆轉；其回退映射需
  在實作計畫中逐筆列出。
