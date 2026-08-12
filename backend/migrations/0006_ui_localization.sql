-- UI localization tables (spec §12.1, §12.2).

CREATE TABLE IF NOT EXISTS ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id TEXT NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-ui', 'system', 'LangMap UI source copy');

INSERT OR IGNORE INTO ui_locales (project_id, language_locale_code, status, mapping_revision, activation_source, activated_at)
VALUES ('langmap-web', 'eng-Latn-US', 'active', 0, 'system', CURRENT_TIMESTAMP);
