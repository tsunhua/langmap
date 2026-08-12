-- Expression readings + user preferences (spec §9.2, §11).

CREATE TABLE IF NOT EXISTS expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code, scheme, value, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
