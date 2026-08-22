-- Keep one locale attestation per expression and language locale.
-- Existing imports could create duplicates because SQLite treats NULL provenance
-- values as distinct under the former four-column UNIQUE constraint.

DELETE FROM expression_locale_attestations
WHERE id IN (
  SELECT id
  FROM (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY expression_id, language_locale_code
        ORDER BY created_at ASC, id ASC
      ) AS duplicate_rank
    FROM expression_locale_attestations
  )
  WHERE duplicate_rank > 1
);

CREATE TABLE expression_locale_attestations_v30 (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  UNIQUE (expression_id, language_locale_code),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

INSERT INTO expression_locale_attestations_v30
  (id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at)
SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at
FROM expression_locale_attestations;

DROP TABLE expression_locale_attestations;
ALTER TABLE expression_locale_attestations_v30 RENAME TO expression_locale_attestations;
