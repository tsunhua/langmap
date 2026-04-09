-- Migration 043: Create handbook_pages table and add columns to handbooks
CREATE TABLE IF NOT EXISTS handbook_pages (
    id INTEGER PRIMARY KEY NOT NULL,
    handbook_id INTEGER NOT NULL,         -- Parent handbook ID
    title TEXT NOT NULL,                  -- Page title
    content TEXT NOT NULL DEFAULT '',     -- Markdown formatted content
    sort_order INTEGER NOT NULL DEFAULT 0,-- Display order within handbook
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    renders TEXT DEFAULT NULL,            -- Cached render output (JSON)
    FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_handbook_pages_handbook_id ON handbook_pages(handbook_id);
CREATE INDEX IF NOT EXISTS idx_handbook_pages_handbook_sort ON handbook_pages(handbook_id, sort_order);

-- Add author, published_at, and has_pages columns to handbooks table
ALTER TABLE handbooks ADD COLUMN author TEXT DEFAULT NULL;
ALTER TABLE handbooks ADD COLUMN published_at TEXT DEFAULT NULL;
ALTER TABLE handbooks ADD COLUMN has_pages INTEGER NOT NULL DEFAULT 0;
