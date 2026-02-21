# 功能设计：批量语义提交 (Batch Meaning Submission)

## 1. 概述
用户可以一次性提交一组跨语言的词句，这些词句共享同一个语义（Meaning）。系统需要自动处理重复数据并建立正确的关联。同时，当某一词句因内容错误需要修正或重新关联时，系统应具备自动传播更新的能力，确保关联数据的一致性。

## 2. 核心流程

### 2.1 提交阶段
用户输入：一组 `{ language_code, text, region_code? }`。
1. **ID 生成与查重**：
   - 针对每一项提交，基于 `text + language_code`（哈希值）生成确定的 `expression_id`。
   - 直接通过 `id` 在 `expressions` 表中查找是否存在。
   - **命中**：复用现有的 `expression_id` 及其 `meaning_id` 状态。
   - **未命中**：准备创建新记录。
2. **语义锚点确认**：根据逻辑推断或选择一个 `expression_id` 作全组的 `meaning_id`。
3. **建立关联**：将组内所有表达式的 `meaning_id` 设置为选定的锚点 ID。

### 2.2 更新、纠正与关联传播
当词句内容存在错误需要修正，或其语义归属需要调整时：

1. **内容修正 (Correction)**：
   - 用户修正 `expressions.text`。
   - 系统检查是否有其他 `expression` 记录与新内容重叠。
   - **合并逻辑**：如果修正后的内容与现有表达式重复，系统应将旧表达式的关联（如：所属的收藏夹、其他的语义组）迁移到现有表达式上，并标记旧记录为历史版本。
2. **自动更新关联 (Automatic Propagation)**：
   - 由于 `meaning_id` 绑定的是表达式 ID，一旦表达式内容更新，所有引用该表达式的语义图景都会自动反映新内容。
   - **语义重组**：如果用户认为某词句不属于现有 `meaning` 组，将其移出后，系统应自动检查该 `meaning` 下是否还有剩余语言，若为空则清理该语义记录。

## 3. 记录模型与 API

### 3.1 数据模型定义
- **Expressions (表达式)**: 继承现有的 `expressions` 表字段。
  - `meaning_id`: 语义锚点 ID（指向 `expressions.id`），用于将不同语言的同义词句分到同一组（由后端智能推断）。
  - `review_status`: 批量提交的新语料默认状态为 `pending`。

### 3.2 API 设计：批量提交
`POST /api/v1/expressions/batch`
为保持接口简洁，客户端只需提交一组跨语言词句。

**Request Body**:
```json
{
  "expressions": [
    {
      "language_code": "zh-CN",
      "text": "你好",
      "region_code": "CN",
      "audio_url": "...",     // 参考单个表达式创建接口
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

## 4. 智能语义锚点选择逻辑 (Intelligent Meaning Selection)

后端在接收到批量提交后，将按以下步骤自动确定 `meaning_id`：

1. **ID 计算与批量查重 (ID Generation & Batch Lookup)**：
   - 为提交列表中的每一项生成 `expression_id`。
   - 执行**单次批量查询**：`SELECT id, meaning_id FROM expressions WHERE id IN (:calc_ids)`，获取所有已存在的记录及其关联状态。

2. **预排序 (Pre-sorting)**：
   - 首先将提交的词句列表按以下**语言权重顺序**进行排列：
     - `en-GB`, `en-US`, `zh-TW`, `zh-CN`, `hi-IN`, `es-ES`, `fr-FR`, `ar-SA`, `bn-IN`, `pt-BR`, `ru-RU`, `ur-PK`, `id-ID`, `de-DE`, `ja-JP`, `ko-KR`, `tr-TR`, `it-IT`。
   - 不在列表中的语言排在末尾。

3. **确定语义锚点 (Anchor Selection)**：
   - **优先追溯**：遍历**排序后**的列表，根据第 1 步的批量查询结果进行匹配。若发现某个词句在库中已有 `meaning_id`，则全组立即复用该 `meaning_id`。
   - **保底锚点**：若全组皆为新词（或均无现成关联），则取**排序后列表首位**记录的 `expression_id` 作为全组的 `meaning_id`。

## 5. 业务细节处理 (Business Logic)

### 5.1 词句修正接口与引用迁移 (Update API & Migration)
纠正词句内容时，由于 ID 系根据内容生成，系统将通过专门的接口执行以下原子操作：

1. **接口定义**：`PATCH /api/v1/expressions/:id`
2. **操作流程**：
   - **创建新记录**：根据新内容生成 `new_id` 并创建 `expressions` 记录（若 `new_id` 已存在则跳过创建）。
   - **资产迁移 (Asset Migration)**：
     - **关联迁移**：将所有 `meaning_id = old_id` 的记录更新为 `meaning_id = new_id`（级联连动）。
     - **归属迁移**：将 `collection_items` 中原属于 `old_id` 的记录迁移至 `new_id`。
     - **版本历史**：将 `old_id` 的记录转入 `expression_versions` 作为历史快照。
   - **清理**：物理删除或标记失效 `old_id` 记录。

### 5.2 级联连动机制 (Cascading Mechanism)
- **连动触发**：当「锚点」表达式（作为 `meaning_id` 的对象）发生上述迁移时，系统会扫描并更新数据库中所有引用旧 ID 的表达式。
- **一致性保护**：此操作必须在数据库事务（Transaction）内完成，确保迁移过程中不会出现断点或孤立词句。

## 6. SQL 示例 (SQL Examples)

### 6.1 批量提交中的查询与插入

**1. ID 基准批量查重（计算 ID 后批量查找）：**
```sql
-- 后端预先计算全组 calc_ids，一次性查出现有记录
SELECT id, meaning_id 
FROM expressions 
WHERE id IN (:calc_ids);
```

**2. 插入或更新表达式（UPSERT / 原子操作）：**
使用 SQLite 的 `ON CONFLICT` 语法，可以在一条 SQL 中实现“不存在则插入，已存在则更新（如 tags, meaning_id 等）”：

```sql
INSERT INTO expressions (id, text, language_code, region_code, meaning_id, tags, created_by)
VALUES (:id, :text, :language_code, :region_code, :meaning_id, :tags, :user)
ON CONFLICT(id) DO UPDATE SET
    meaning_id = excluded.meaning_id,
    tags = CASE WHEN excluded.tags IS NOT NULL THEN excluded.tags ELSE tags END,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = excluded.created_by;
```

### 6.2 词句修正与级联迁移 (Cascading Update)

当词句 ID 因内容修改而变更（从 `old_id` 变为 `new_id`）时：

**1. 级联更新关联词句的语义指向：**
```sql
-- 将所有以此词句为“锚点”的关联词句全部指向新 ID
UPDATE expressions 
SET meaning_id = :new_id 
WHERE meaning_id = :old_id;
```

**2. 迁移用户收藏记录：**
```sql
UPDATE collection_items 
SET expression_id = :new_id 
WHERE expression_id = :old_id;
```

**3. 归档旧版本：**
```sql
INSERT INTO expression_versions (expression_id, text, meaning_id, created_by)
SELECT id, text, meaning_id, created_by 
FROM expressions 
WHERE id = :old_id;
```

**4. 清理旧记录：**
```sql
DELETE FROM expressions WHERE id = :old_id;
```

## 7. System Reminder

**实现状态**：
- ⏳ 需求定义：已完成（补充了智能锚点选择与级联逻辑）
- ❌ 后端开发：未完成
- ❌ 前端开发：未完成
- ❌ API 测试：未完成

---
相关文档：
- [数据库设计](./feat-database.md)
- [产品需求文档 (PRD)](../../specs/PRD.md)
