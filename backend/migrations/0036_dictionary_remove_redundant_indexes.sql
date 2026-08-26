-- Local/managed dictionary D1 keeps release membership in the binding and
-- evidence tables.  The per-object ownership journal was the dominant source
-- of duplicated rows and indexes, so it is intentionally removed.
DROP INDEX IF EXISTS idx_dictionary_bindings_release_claim;
DROP INDEX IF EXISTS idx_dictionary_edge_evidence_release;
DROP INDEX IF EXISTS idx_dictionary_release_objects_object;
DROP INDEX IF EXISTS idx_dictionary_release_objects_release;
DROP TABLE IF EXISTS dictionary_release_objects;
