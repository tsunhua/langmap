# 功能設計：批量語義提交 (Batch Meaning Submission)

## 1. 概述
用戶可以一次性提交一組跨語言的詞句，這些詞句共享同一個語義（Meaning）。系統需要自動處理重複數據並建立正確的關聯。同時，當某一詞句因內容錯誤需要修正或重新關聯時，系統應具備自動傳播更新的能力，確保關聯數據的一致性。

## 2. 核心流程

### 2.1 提交階段
用戶輸入：一組 `{ language_code, text, region_code? }`。
1. **ID 生成與查重**：
   - 針對每一項提交，基於 `text + language_code`（哈希值）生成確定的 `expression_id`。
   - 直接通過 `id` 在 `expressions` 表中查找是否存在。
   - **命中**：復用現有的 `expression_id` 及其 `meaning_id` 狀態。
   - **未命中**：準備創建新記錄。
2. **語義錨點確認**：根據邏輯推斷或選擇一個 `expression_id` 作全組的 `meaning_id`。
3. **建立關聯**：將組內所有表達式的 `meaning_id` 設置爲選定的錨點 ID。

### 2.2 更新、糾正與關聯傳播
當詞句內容存在錯誤需要修正，或其語義歸屬需要調整時：

1. **內容修正 (Correction)**：
   - 用戶修正 `expressions.text`。
   - 系統檢查是否有其他 `expression` 記錄與新內容重疊。
   - **合併邏輯**：如果修正後的內容與現有表達式重複，系統應將舊錶達式的關聯（如：所屬的收藏夾、其他的語義組）遷移到現有表達式上，並標記舊記錄爲歷史版本。
2. **自動更新關聯 (Automatic Propagation)**：
   - 由於 `meaning_id` 綁定的是表達式 ID，一旦表達式內容更新，所有引用該表達式的語義圖景都會自動反映新內容。
   - **語義重組**：如果用戶認爲某詞句不屬於現有 `meaning` 組，將其移出後，系統應自動檢查該 `meaning` 下是否還有剩餘語言，若爲空則清理該語義記錄。

## 3. 記錄模型與 API

### 3.1 數據模型定義
- **Expressions (表達式)**: 繼承現有的 `expressions` 表字段。
  - `meaning_id`: 語義錨點 ID（指向 `expressions.id`），用於將不同語言的同義詞句分到同一組（由後端智能推斷）。
  - `review_status`: 批量提交的新語料默認狀態爲 `pending`。

### 3.2 API 設計：批量提交
`POST /api/v1/expressions/batch`
爲保持接口簡潔，客戶端只需提交一組跨語言詞句。

**Request Body**:
```json
{
  "expressions": [
    {
      "language_code": "zh-CN",
      "text": "你好",
      "region_code": "CN",
      "audio_url": "...",     // 參考單個表達式創建接口
      "tags": "[\"informal\"]",
      "source_type": "user"
    },
    {
      "language_code": "en-US",
      "text": "Hello",
      "region_code": "US"
    }
  ]
}
```

## 4. 智能語義錨點選擇邏輯 (Intelligent Meaning Selection)

後端在接收到批量提交後，將按以下步驟自動確定 `meaning_id`：

1. **ID 計算與批量查重 (ID Generation & Batch Lookup)**：
   - 爲提交列表中的每一項生成 `expression_id`。
   - 執行**單次批量查詢**：`SELECT id, meaning_id FROM expressions WHERE id IN (:calc_ids)`，獲取所有已存在的記錄及其關聯狀態。

2. **預排序 (Pre-sorting)**：
   - 首先將提交的詞句列表按以下**語言權重順序**進行排列：
     - `en-GB`, `en-US`, `zh-TW`, `zh-CN`, `hi-IN`, `es-ES`, `fr-FR`, `ar-SA`, `bn-IN`, `pt-BR`, `ru-RU`, `ur-PK`, `id-ID`, `de-DE`, `ja-JP`, `ko-KR`, `tr-TR`, `it-IT`。
   - 不在列表中的語言排在末尾。

3. **確定語義錨點 (Anchor Selection)**：
   - **優先追溯**：遍歷**排序後**的列表，根據第 1 步的批量查詢結果進行匹配。若發現某個詞句在庫中已有 `meaning_id`，則全組立即復用該 `meaning_id`。
   - **保底錨點**：若全組皆爲新詞（或均無現成關聯），則取**排序後列表首位**記錄的 `expression_id` 作爲全組的 `meaning_id`。

## 5. 業務細節處理 (Business Logic)

### 5.1 詞句修正接口與引用遷移 (Update API & Migration)
糾正詞句內容時，由於 ID 系根據內容生成，系統將通過專門的接口執行以下原子操作：

1. **接口定義**：`PATCH /api/v1/expressions/:id`
2. **操作流程**：
   - **創建新記錄**：根據新內容生成 `new_id` 並創建 `expressions` 記錄（若 `new_id` 已存在則跳過創建）。
   - **資產遷移 (Asset Migration)**：
     - **關聯遷移**：將所有 `meaning_id = old_id` 的記錄更新爲 `meaning_id = new_id`（級聯連動）。
     - **歸屬遷移**：將 `collection_items` 中原屬於 `old_id` 的記錄遷移至 `new_id`。
     - **版本歷史**：將 `old_id` 的記錄轉入 `expression_versions` 作爲歷史快照。
   - **清理**：物理刪除或標記失效 `old_id` 記錄。

### 5.2 級聯連動機制 (Cascading Mechanism)
- **連動觸發**：當「錨點」表達式（作爲 `meaning_id` 的對象）發生上述遷移時，系統會掃描並更新數據庫中所有引用舊 ID 的表達式。
- **一致性保護**：此操作必須在數據庫事務（Transaction）內完成，確保遷移過程中不會出現斷點或孤立詞句。

## 6. SQL 示例 (SQL Examples)

### 6.1 批量提交中的查詢與插入

**1. ID 基準批量查重（計算 ID 後批量查找）：**
```sql
-- 後端預先計算全組 calc_ids，一次性查出現有記錄
SELECT id, meaning_id 
FROM expressions 
WHERE id IN (:calc_ids);
```

**2. 插入或更新表達式（UPSERT / 原子操作）：**
使用 SQLite 的 `ON CONFLICT` 語法，可以在一條 SQL 中實現「不存在則插入，已存在則更新（如 tags, meaning_id 等）」：

```sql
INSERT INTO expressions (id, text, language_code, region_code, meaning_id, tags, created_by)
VALUES (:id, :text, :language_code, :region_code, :meaning_id, :tags, :user)
ON CONFLICT(id) DO UPDATE SET
    meaning_id = excluded.meaning_id,
    tags = CASE WHEN excluded.tags IS NOT NULL THEN excluded.tags ELSE tags END,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = excluded.created_by;
```

### 6.2 詞句修正與級聯遷移 (Cascading Update)

當詞句 ID 因內容修改而變更（從 `old_id` 變爲 `new_id`）時：

**1. 級聯更新關聯詞句的語義指向：**
```sql
-- 將所有以此詞句爲「錨點」的關聯詞句全部指向新 ID
UPDATE expressions 
SET meaning_id = :new_id 
WHERE meaning_id = :old_id;
```

**2. 遷移用戶收藏記錄：**
```sql
UPDATE collection_items 
SET expression_id = :new_id 
WHERE expression_id = :old_id;
```

**3. 歸檔舊版本：**
```sql
INSERT INTO expression_versions (expression_id, text, meaning_id, created_by)
SELECT id, text, meaning_id, created_by 
FROM expressions 
WHERE id = :old_id;
```

**4. 清理舊記錄：**
```sql
DELETE FROM expressions WHERE id = :old_id;
```

## 7. System Reminder

**實現狀態**：
- ⏳ 需求定義：已完成（補充了智能錨點選擇與級聯邏輯）
- ❌ 後端開發：未完成
- ❌ 前端開發：未完成
- ❌ API 測試：未完成

---
相關文檔：
- [數據庫設計](./feat-database.md)
- [產品需求文檔 (PRD)](../../specs/PRD.md)
