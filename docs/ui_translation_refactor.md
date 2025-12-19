# 将 UI 翻译重构为基于集合（Collection）的方案

## 概述

本文档概述了将 UI 翻译系统从基于标签（Tag）/ 用户归属（User Attribution）的方法迁移到基于集合（Collection）的方法的计划。

目前，UI 翻译键是通过由系统用户 `langmap` 创建的表达式或具有特定标签的表达式来识别的。为了提高可维护性并更轻松地管理 UI 字符串，我们将使用一个名为 `langmap` 的特定集合来存储所有作为本地化键的表达式。

## 方案变更

### 1. 后端逻辑 (D1DatabaseService)

*   **`getUITranslations(language, skip, limit)`**:
    - 不再通过 `created_by = 'langmap'` 进行过滤，而是将 `expressions` 表与 `collection_items` 和 `collections` 表进行连接。
    - 查找属于名为 `langmap` 的集合且语言为目标 `language` 的表达式。
*   **`saveUITranslation(language, key, text, username)`**:
    - 在为 UI 键创建新翻译时，系统不仅会创建表达式记录，还会将其链接到 `langmap` 集合。
    - 它将使用该集合中对应 `en-US` 键表达式的 `meaning_id` 来维护关联关系。

### 2. API 路由

*   现有的 `/api/v1/ui-translations/:language` 接口将保持兼容，但在底层将使用新的基于集合的数据库查询。

## 数据迁移

我们需要将现有的 UI 翻译记录迁移到新的 `collections` 和 `collection_items` 表中。

### SQL 迁移脚本

```sql
-- UI 翻译迁移：从标签/用户到集合

-- 1. 创建系统集合 'langmap' 
-- 假设 ID 为 1 的用户是主要管理员。
-- 使用 1000000 作为该系统集合的稳定占位 ID。
INSERT INTO collections (id, user_id, name, description, is_public)
SELECT 1000000, 1, 'langmap', '系统 UI 翻译集合', 1
WHERE NOT EXISTS (SELECT 1 FROM collections WHERE name = 'langmap');

-- 2. 将现有的 en-US UI 翻译键链接到该集合
-- 我们通过语言 'en-US' 以及现有的本地化标签或 'langmap' 作者身份来识别它们。
INSERT OR IGNORE INTO collection_items (id, collection_id, expression_id)
SELECT 
    -- 简化的 ID 生成逻辑
    (1000000 * 1000 + e.id), 
    1000000, 
    e.id
FROM expressions e
WHERE e.created_by = 'langmap';

-- 3. 验证目标表达式是否已通过 meaning_id 正确分组
--（现有的 meaning_id 逻辑仍然是关联关系的真相来源）
```

## 实施计划

1.  **步骤 1**: 在生产环境 D1 数据库上执行迁移 SQL。
2.  **步骤 2**: 更新 `backend/src/server/db/d1.ts` 中的 `D1DatabaseService.getUITranslations`。
3.  **步骤 3**: 更新 `backend/src/server/db/d1.ts` 中的 `D1DatabaseService.saveUITranslation`。
4.  **步骤 4**: 在 `/translate` 界面验证功能。
