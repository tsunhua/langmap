ALTER TABLE ui_locales RENAME TO ui_locales_legacy;

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  code TEXT NOT NULL,
  native_name TEXT NOT NULL,
  direction TEXT NOT NULL DEFAULT 'ltr' CHECK (direction IN ('ltr', 'rtl')),
  fallback_code TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'draft', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  created_by TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_by TEXT,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, code),
  FOREIGN KEY (code) REFERENCES languages(code),
  FOREIGN KEY (project_id, fallback_code) REFERENCES ui_locales(project_id, code)
);

INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', u.language_code, COALESCE(l.name, u.language_code), COALESCE(l.direction, 'ltr'), 'active'
FROM ui_locales_legacy u LEFT JOIN languages l ON l.code = u.language_code
WHERE l.code IS NOT NULL;

DROP TABLE ui_locales_legacy;

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  key TEXT NOT NULL,
  description TEXT,
  scope TEXT NOT NULL DEFAULT 'global',
  message_format TEXT NOT NULL DEFAULT 'text',
  source_expression_id INTEGER NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '{}',
  source_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'retired')),
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);
CREATE INDEX idx_ui_messages_source ON ui_messages(project_id, source_expression_id);
