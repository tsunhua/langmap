CREATE TABLE IF NOT EXISTS languoids (
    id TEXT PRIMARY KEY NOT NULL,
    glottocode TEXT UNIQUE NOT NULL,
    preferred_name TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('family', 'language', 'dialect')),
    iso639_3 TEXT,
    parent_id TEXT,
    latitude REAL,
    longitude REAL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired')),
    source_version TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES languoids(id)
);
CREATE INDEX IF NOT EXISTS idx_languoids_glottocode ON languoids(glottocode);
CREATE INDEX IF NOT EXISTS idx_languoids_iso639_3 ON languoids(iso639_3);
ALTER TABLE languages ADD COLUMN languoid_id TEXT;
ALTER TABLE languages ADD COLUMN base_language TEXT;
ALTER TABLE languages ADD COLUMN script_code TEXT;
ALTER TABLE languages ADD COLUMN source_version TEXT;
