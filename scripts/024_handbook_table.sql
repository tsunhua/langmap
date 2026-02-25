-- Migration 024: Create Handbooks table
CREATE TABLE IF NOT EXISTS handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- Creator ID, links to users.id
    title TEXT NOT NULL,               -- Handbook title
    description TEXT,                  -- Handbook description
    content TEXT NOT NULL,             -- Markdown formatted content
    source_lang TEXT,                   -- Handbook written language (e.g., 'en')
    target_lang TEXT,                   -- Target learning language (e.g., 'zh-CN')
    is_public INTEGER DEFAULT 0,       -- Whether public (0: private, 1: public)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_handbooks_user_id ON handbooks(user_id);
CREATE INDEX IF NOT EXISTS idx_handbooks_is_public_created ON handbooks(is_public, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_handbooks_user_created ON handbooks(user_id, created_at DESC);
