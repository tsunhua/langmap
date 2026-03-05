-- LangMap Meaning Mapping - 多对多关系改造
-- Date: 2026-03-04
-- Description: 添加 meanings 和 expression_meaning 表，支持词句与语义的多对多关系
-- 执行：npx wrangler d1 execute langmap --remote --file=../scripts/025_meaning_mapping.sql --y

--------------------------------------------------------------------------------
-- 1. 创建 meanings 表
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meanings (
    id INTEGER PRIMARY KEY NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

--------------------------------------------------------------------------------
-- 2. 创建 expression_meaning 表
--------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS expression_meaning (
    id TEXT PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    meaning_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (expression_id) REFERENCES expressions(id),
    FOREIGN KEY (meaning_id) REFERENCES meanings(id)
);

--------------------------------------------------------------------------------
-- 3. 数据迁移：将现有的 meaning_id 迁移到新的多对多关系
--------------------------------------------------------------------------------

-- 步骤 3.1: 为每个唯一的 meaning_id 创建 meanings 记录
INSERT INTO meanings (id, created_by, created_at)
SELECT DISTINCT
    e.meaning_id,
    (SELECT created_by FROM expressions WHERE id = e.meaning_id),
    (SELECT created_at FROM expressions WHERE id = e.meaning_id)
FROM expressions e
WHERE e.meaning_id IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM meanings WHERE id = e.meaning_id);

-- 步骤 3.2: 创建 expression_meaning 关联记录
-- 为每个有 meaning_id 的 expression 创建关联
INSERT INTO expression_meaning (id, expression_id, meaning_id, created_at)
SELECT
    -- 使用拼接的 ID 格式：expression_id-meaning_id
    e.id || '-' || e.meaning_id,
    e.id,
    e.meaning_id,
    CURRENT_TIMESTAMP
FROM expressions e
WHERE e.meaning_id IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM expression_meaning em
    WHERE em.expression_id = e.id AND em.meaning_id = e.meaning_id
);

--------------------------------------------------------------------------------
-- 4. 创建索引
--------------------------------------------------------------------------------

-- expression_meaning 表索引
CREATE INDEX IF NOT EXISTS idx_expression_meaning_expression_id ON expression_meaning(expression_id);
CREATE INDEX IF NOT EXISTS idx_expression_meaning_meaning_id ON expression_meaning(meaning_id);
