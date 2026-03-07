-- Create ui_locales table to store flattened locale JSON strings
-- This table replaces the complex expressions-based UI translation system
-- Migration ID: 028
-- Date: 2025-03-07

CREATE TABLE IF NOT EXISTS ui_locales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    language_code TEXT UNIQUE NOT NULL,
    locale_json TEXT NOT NULL,  -- Flattened JSON object: {"about": "About", "home": "Home", ...}
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ui_locales_language_code ON ui_locales(language_code);
