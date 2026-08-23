"""SQLite schema for the offline dictionary staging area."""

from __future__ import annotations

import sqlite3
from pathlib import Path

SCHEMA_VERSION = 1

DDL = """
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS staging_releases (
  id TEXT PRIMARY KEY,
  manifest_hash TEXT NOT NULL UNIQUE,
  schema_version INTEGER NOT NULL CHECK (schema_version = 1),
  status TEXT NOT NULL CHECK (status IN ('loading','staged','failed')),
  input_records INTEGER NOT NULL DEFAULT 0,
  staged_entries INTEGER NOT NULL DEFAULT 0,
  staged_senses INTEGER NOT NULL DEFAULT 0,
  quarantined INTEGER NOT NULL DEFAULT 0,
  failure_reason TEXT
);
CREATE TABLE IF NOT EXISTS input_entries (
  release_id TEXT NOT NULL,
  entry_key TEXT NOT NULL,
  dictionary_key TEXT NOT NULL,
  raw_headword TEXT NOT NULL,
  canonical_headword TEXT NOT NULL,
  homograph_marker TEXT,
  direction_hint TEXT,
  record_fingerprint TEXT NOT NULL,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, entry_key),
  FOREIGN KEY (release_id) REFERENCES staging_releases(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_senses (
  release_id TEXT NOT NULL,
  sense_key TEXT NOT NULL,
  entry_key TEXT NOT NULL,
  ordinal INTEGER NOT NULL CHECK (ordinal >= 1),
  definitions_json TEXT NOT NULL,
  pos_json TEXT NOT NULL,
  equivalents_json TEXT NOT NULL,
  relations_json TEXT NOT NULL,
  examples_json TEXT NOT NULL,
  labels_json TEXT NOT NULL,
  raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_forms (
  release_id TEXT NOT NULL, entry_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  value TEXT NOT NULL, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, entry_key, ordinal),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_pronunciations (
  release_id TEXT NOT NULL, entry_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  value TEXT NOT NULL, scheme TEXT NOT NULL, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, entry_key, ordinal),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_equivalents (
  release_id TEXT NOT NULL, sense_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  value TEXT NOT NULL, language_hint TEXT, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key, ordinal),
  FOREIGN KEY (release_id, sense_key) REFERENCES input_senses(release_id, sense_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_relations (
  release_id TEXT NOT NULL, sense_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  kind TEXT NOT NULL, related_text TEXT NOT NULL, reading TEXT, language_hint TEXT, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key, ordinal),
  FOREIGN KEY (release_id, sense_key) REFERENCES input_senses(release_id, sense_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_examples (
  release_id TEXT NOT NULL, sense_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  text TEXT NOT NULL, translation TEXT, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key, ordinal),
  FOREIGN KEY (release_id, sense_key) REFERENCES input_senses(release_id, sense_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS input_pos (
  release_id TEXT NOT NULL, sense_key TEXT NOT NULL, ordinal INTEGER NOT NULL,
  value TEXT NOT NULL, raw_json TEXT NOT NULL,
  PRIMARY KEY (release_id, sense_key, ordinal),
  FOREIGN KEY (release_id, sense_key) REFERENCES input_senses(release_id, sense_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS lexical_occurrences (
  release_id TEXT NOT NULL, claim_key TEXT NOT NULL, occurrence_kind TEXT NOT NULL,
  entry_key TEXT NOT NULL, sense_key TEXT, raw_value TEXT NOT NULL,
  canonical_text TEXT NOT NULL, lang_code TEXT, locale_code TEXT, cluster_key TEXT NOT NULL,
  metadata_json TEXT NOT NULL, errors_json TEXT NOT NULL,
  PRIMARY KEY (release_id, claim_key),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS lexical_readings (
  release_id TEXT NOT NULL, claim_key TEXT NOT NULL, entry_key TEXT NOT NULL,
  raw_value TEXT NOT NULL, value TEXT NOT NULL, scheme TEXT NOT NULL, locale_code TEXT,
  errors_json TEXT NOT NULL, PRIMARY KEY (release_id, claim_key),
  FOREIGN KEY (release_id, entry_key) REFERENCES input_entries(release_id, entry_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS normalized_pos (
  release_id TEXT NOT NULL, claim_key TEXT NOT NULL, sense_key TEXT NOT NULL,
  raw_value TEXT NOT NULL, code TEXT, errors_json TEXT NOT NULL,
  PRIMARY KEY (release_id, claim_key),
  FOREIGN KEY (release_id, sense_key) REFERENCES input_senses(release_id, sense_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS lexical_clusters (
  release_id TEXT NOT NULL, cluster_key TEXT NOT NULL, occurrence_kind TEXT NOT NULL,
  lang_code TEXT, canonical_text TEXT NOT NULL,
  PRIMARY KEY (release_id, cluster_key)
);
CREATE TABLE IF NOT EXISTS cluster_members (
  release_id TEXT NOT NULL, cluster_key TEXT NOT NULL, claim_key TEXT NOT NULL,
  PRIMARY KEY (release_id, cluster_key, claim_key),
  FOREIGN KEY (release_id, cluster_key) REFERENCES lexical_clusters(release_id, cluster_key) ON DELETE CASCADE,
  FOREIGN KEY (release_id, claim_key) REFERENCES lexical_occurrences(release_id, claim_key) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS merge_decisions (
  release_id TEXT NOT NULL, decision_key TEXT NOT NULL, left_cluster_key TEXT NOT NULL,
  right_cluster_key TEXT NOT NULL, decision TEXT NOT NULL, confidence REAL,
  rationale_json TEXT NOT NULL, PRIMARY KEY (release_id, decision_key)
);
CREATE TABLE IF NOT EXISTS quarantine_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT, release_id TEXT NOT NULL, dictionary_key TEXT,
  entry_key TEXT, sense_key TEXT, claim_key TEXT, error_code TEXT NOT NULL,
  detail TEXT NOT NULL, raw_json TEXT, UNIQUE (release_id, claim_key, error_code, detail),
  FOREIGN KEY (release_id) REFERENCES staging_releases(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_input_entries_release_dict ON input_entries(release_id, dictionary_key);
CREATE INDEX IF NOT EXISTS idx_quarantine_release_error ON quarantine_items(release_id, error_code);
CREATE INDEX IF NOT EXISTS idx_occurrence_text ON lexical_occurrences(release_id, lang_code, canonical_text);
CREATE INDEX IF NOT EXISTS idx_clusters_text ON lexical_clusters(release_id, lang_code, canonical_text);
"""


def create_staging_database(path: Path) -> sqlite3.Connection:
    """Create/open a staging database and enable integrity protections."""

    path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(path)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA journal_mode = WAL")
    connection.executescript(DDL)
    connection.commit()
    return connection
