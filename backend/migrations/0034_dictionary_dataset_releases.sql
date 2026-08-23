-- Managed dictionary release lifecycle. Visibility is controlled exclusively by
-- dictionary_dataset_state.active_release_id; release status is load metadata.

CREATE TABLE dictionary_dataset_releases (
  id TEXT PRIMARY KEY,
  dataset_key TEXT NOT NULL,
  parent_release_id TEXT,
  input_manifest_hash TEXT NOT NULL,
  exporter_schema_version INTEGER NOT NULL,
  adapter_bundle_hash TEXT NOT NULL,
  reconciliation_config_hash TEXT NOT NULL,
  artifact_hash TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('planned', 'applying', 'validated', 'failed')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activated_at TEXT,
  UNIQUE (dataset_key, input_manifest_hash, adapter_bundle_hash, reconciliation_config_hash),
  FOREIGN KEY (parent_release_id) REFERENCES dictionary_dataset_releases(id)
);

CREATE TABLE dictionary_dataset_state (
  dataset_key TEXT PRIMARY KEY,
  active_release_id TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (active_release_id) REFERENCES dictionary_dataset_releases(id)
);

CREATE TABLE dictionary_expression_bindings (
  release_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  cluster_key TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('headword', 'equivalent', 'synonym', 'example_text', 'example_translation')),
  expression_id TEXT NOT NULL,
  binding_kind TEXT NOT NULL CHECK (binding_kind IN ('allocated', 'reused', 'ai_merged', 'explicit_group')),
  PRIMARY KEY (release_id, claim_key, role),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (expression_id) REFERENCES expressions(id)
);

CREATE TABLE expression_edge_evidence (
  release_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  evidence_kind TEXT NOT NULL CHECK (evidence_kind IN ('equivalent', 'synonym', 'example')),
  PRIMARY KEY (release_id, edge_id, claim_key, evidence_kind),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

CREATE TABLE dictionary_release_objects (
  release_id TEXT NOT NULL,
  object_kind TEXT NOT NULL CHECK (object_kind IN ('expression', 'edge', 'reading', 'locale_attestation', 'pos_attestation')),
  object_id TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  object_action TEXT NOT NULL CHECK (object_action IN ('created', 'reused')),
  promoted_at TEXT,
  promotion_actor_kind TEXT CHECK (promotion_actor_kind IN ('user', 'system')),
  promoted_by INTEGER,
  PRIMARY KEY (release_id, object_kind, object_id, claim_key),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (promoted_by) REFERENCES users(id),
  CHECK (promoted_at IS NULL OR object_action = 'created'),
  CHECK (
    (promoted_at IS NULL AND promotion_actor_kind IS NULL AND promoted_by IS NULL)
    OR (promoted_at IS NOT NULL AND promotion_actor_kind = 'user' AND promoted_by IS NOT NULL)
    OR (promoted_at IS NOT NULL AND promotion_actor_kind = 'system' AND promoted_by IS NULL)
  )
);

CREATE TABLE parts_of_speech (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  sort_order INTEGER NOT NULL UNIQUE
);

CREATE TABLE expression_pos_attestations (
  release_id TEXT NOT NULL,
  expression_id TEXT NOT NULL,
  pos_code TEXT NOT NULL,
  claim_key TEXT NOT NULL,
  PRIMARY KEY (release_id, expression_id, pos_code, claim_key),
  FOREIGN KEY (release_id) REFERENCES dictionary_dataset_releases(id),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (pos_code) REFERENCES parts_of_speech(code)
);

CREATE INDEX idx_dictionary_releases_dataset_created
  ON dictionary_dataset_releases(dataset_key, created_at DESC, id ASC);
CREATE INDEX idx_dictionary_bindings_expression
  ON dictionary_expression_bindings(expression_id, release_id, role, claim_key);
CREATE INDEX idx_dictionary_bindings_release_claim
  ON dictionary_expression_bindings(release_id, claim_key, role, expression_id);
CREATE INDEX idx_dictionary_edge_evidence_edge
  ON expression_edge_evidence(edge_id, release_id, evidence_kind, claim_key);
CREATE INDEX idx_dictionary_edge_evidence_release
  ON expression_edge_evidence(release_id, edge_id, claim_key, evidence_kind);
CREATE INDEX idx_dictionary_release_objects_object
  ON dictionary_release_objects(object_kind, object_id, object_action, release_id);
CREATE INDEX idx_dictionary_release_objects_release
  ON dictionary_release_objects(release_id, object_kind, object_action, object_id);
CREATE INDEX idx_dictionary_pos_expression
  ON expression_pos_attestations(expression_id, release_id, pos_code, claim_key);
CREATE INDEX idx_dictionary_pos_release
  ON expression_pos_attestations(release_id, expression_id, pos_code, claim_key);

INSERT OR IGNORE INTO parts_of_speech (code, name_en, sort_order) VALUES
  ('noun', 'Noun', 1),
  ('proper-noun', 'Proper noun', 2),
  ('verb', 'Verb', 3),
  ('auxiliary', 'Auxiliary verb', 4),
  ('adjective', 'Adjective', 5),
  ('adverb', 'Adverb', 6),
  ('pronoun', 'Pronoun', 7),
  ('determiner', 'Determiner', 8),
  ('numeral', 'Numeral', 9),
  ('adposition', 'Adposition', 10),
  ('conjunction', 'Conjunction', 11),
  ('particle', 'Particle', 12),
  ('interjection', 'Interjection', 13),
  ('abbreviation', 'Abbreviation', 14),
  ('phrase', 'Phrase', 15);
