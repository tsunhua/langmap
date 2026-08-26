-- Replace repeated language/locale strings in the packed catalog with small
-- integer foreign keys.  The catalog is rebuildable, so old packed rows are
-- intentionally discarded instead of being rewritten in place.

DROP VIEW IF EXISTS dictionary_expression_rows;
DROP VIEW IF EXISTS dictionary_edge_rows;
DROP VIEW IF EXISTS dictionary_reading_rows;
DROP VIEW IF EXISTS all_expression_rows;
DROP VIEW IF EXISTS all_expression_edges;
DROP VIEW IF EXISTS all_expression_readings;

DROP TABLE IF EXISTS dictionary_readings;
DROP TABLE IF EXISTS dictionary_edges;
DROP TABLE IF EXISTS dictionary_terms;
DROP TABLE IF EXISTS dictionary_locales;
DROP TABLE IF EXISTS dictionary_languages;

CREATE TABLE dictionary_languages (
  language_id INTEGER PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  FOREIGN KEY (code) REFERENCES languages(code)
);

CREATE TABLE dictionary_locales (
  locale_id INTEGER PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  language_id INTEGER NOT NULL,
  FOREIGN KEY (language_id) REFERENCES dictionary_languages(language_id),
  FOREIGN KEY (code) REFERENCES language_locales(code)
);

CREATE TABLE dictionary_terms (
  term_id INTEGER PRIMARY KEY,
  language_id INTEGER NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  pos_mask INTEGER NOT NULL DEFAULT 0 CHECK (pos_mask >= 0),
  UNIQUE (language_id, text, homograph_index),
  FOREIGN KEY (language_id) REFERENCES dictionary_languages(language_id)
);

CREATE TABLE dictionary_edges (
  edge_id INTEGER PRIMARY KEY,
  expression_a_id INTEGER NOT NULL,
  expression_b_id INTEGER NOT NULL,
  relation_kind INTEGER NOT NULL DEFAULT 0 CHECK (relation_kind IN (0, 1, 2)),
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES dictionary_terms(term_id),
  FOREIGN KEY (expression_b_id) REFERENCES dictionary_terms(term_id)
);

CREATE INDEX idx_dictionary_edges_a_id ON dictionary_edges(expression_a_id);
CREATE INDEX idx_dictionary_edges_b_id ON dictionary_edges(expression_b_id);

CREATE TABLE dictionary_readings (
  reading_id INTEGER PRIMARY KEY,
  expression_id INTEGER NOT NULL,
  locale_id INTEGER NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  UNIQUE (expression_id, locale_id, scheme, value),
  FOREIGN KEY (expression_id) REFERENCES dictionary_terms(term_id),
  FOREIGN KEY (locale_id) REFERENCES dictionary_locales(locale_id)
);

CREATE VIEW dictionary_expression_rows AS
SELECT
  'd' || printf('%08d', t.term_id) AS id,
  l.code AS lang_code,
  t.text,
  t.text_hash,
  t.homograph_index,
  '' AS description,
  '[]' AS tags_json,
  NULL AS source_id,
  NULL AS source_ref,
  'approved' AS review_status,
  NULL AS created_by,
  COALESCE((
    SELECT r.created_at
    FROM dictionary_dataset_releases r
    JOIN dictionary_dataset_state s ON s.active_release_id = r.id
    WHERE s.dataset_key = 'managed-dictionaries'
    LIMIT 1
  ), '1970-01-01 00:00:00') AS created_at,
  COALESCE((
    SELECT r.created_at
    FROM dictionary_dataset_releases r
    JOIN dictionary_dataset_state s ON s.active_release_id = r.id
    WHERE s.dataset_key = 'managed-dictionaries'
    LIMIT 1
  ), '1970-01-01 00:00:00') AS updated_at
FROM dictionary_terms t
JOIN dictionary_languages l ON l.language_id = t.language_id;

CREATE VIEW dictionary_edge_rows AS
SELECT
  'e' || printf('%08d', e.edge_id) AS id,
  'd' || printf('%08d', e.expression_a_id) AS expression_a_id,
  'd' || printf('%08d', e.expression_b_id) AS expression_b_id,
  0 AS score,
  'dictionary' AS source,
  NULL AS created_by,
  COALESCE((
    SELECT r.created_at
    FROM dictionary_dataset_releases r
    JOIN dictionary_dataset_state s ON s.active_release_id = r.id
    WHERE s.dataset_key = 'managed-dictionaries'
    LIMIT 1
  ), '1970-01-01 00:00:00') AS created_at
FROM dictionary_edges e;

CREATE VIEW dictionary_reading_rows AS
SELECT
  'r' || printf('%08d', r.reading_id) AS id,
  'd' || printf('%08d', r.expression_id) AS expression_id,
  l.code AS language_locale_code,
  r.scheme,
  r.value,
  NULL AS source_id,
  NULL AS source_ref,
  NULL AS created_by,
  COALESCE((
    SELECT dr.created_at
    FROM dictionary_dataset_releases dr
    JOIN dictionary_dataset_state ds ON ds.active_release_id = dr.id
    WHERE ds.dataset_key = 'managed-dictionaries'
    LIMIT 1
  ), '1970-01-01 00:00:00') AS created_at
FROM dictionary_readings r
JOIN dictionary_locales l ON l.locale_id = r.locale_id;

CREATE VIEW all_expression_rows AS
SELECT id, lang_code, text, text_hash, homograph_index, description,
       tags_json, source_id, source_ref, review_status, created_by,
       created_at, updated_at
FROM expressions
UNION ALL
SELECT id, lang_code, text, text_hash, homograph_index, description,
       tags_json, source_id, source_ref, review_status, created_by,
       created_at, updated_at
FROM dictionary_expression_rows;

CREATE VIEW all_expression_edges AS
SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at
FROM expression_edges
UNION ALL
SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at
FROM dictionary_edge_rows;

CREATE VIEW all_expression_readings AS
SELECT id, expression_id, language_locale_code, scheme, value,
       source_id, source_ref, created_by, created_at
FROM expression_readings
UNION ALL
SELECT id, expression_id, language_locale_code, scheme, value,
       source_id, source_ref, created_by, created_at
FROM dictionary_reading_rows;
