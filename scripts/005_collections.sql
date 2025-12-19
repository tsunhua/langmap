-- Create Collections table
CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 创建者ID，关联 users.id
    name TEXT NOT NULL,                -- 集合名称
    description TEXT,                  -- 集合描述
    is_public INTEGER DEFAULT 0,       -- 是否公开 (0: 私有, 1: 公开)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_collections_user_id ON collections(user_id);

-- Create Collection Items table
CREATE TABLE IF NOT EXISTS collection_items (
    id INTEGER PRIMARY KEY NOT NULL,
    collection_id INTEGER NOT NULL,    -- 关联 collections.id
    expression_id INTEGER NOT NULL,    -- 关联 expressions.id
    note TEXT,                         -- 用户对该词条在集合中的备注（可选）
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(collection_id, expression_id) -- 防止重复添加
);

CREATE INDEX IF NOT EXISTS idx_collection_items_collection_id ON collection_items(collection_id);
CREATE INDEX IF NOT EXISTS idx_collection_items_expression_id ON collection_items(expression_id);
