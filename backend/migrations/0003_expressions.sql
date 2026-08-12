-- Expression identity + locale attestations (spec §8.4, §9.1).

CREATE TABLE IF NOT EXISTS expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
