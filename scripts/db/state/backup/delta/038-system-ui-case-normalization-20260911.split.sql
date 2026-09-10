-- Data-independent, source-scoped follow-up for system-ui rows added after
-- the full expression case normalization.  It preserves all-uppercase ASCII
-- expressions and the same no-case locale policy as the full migration.
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_form_targets;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_edge_targets;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_map;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_keys;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_policy;
-- langmap:batch
CREATE TABLE _lm_ui_case_20260911_policy(prefix TEXT PRIMARY KEY);
-- langmap:batch
INSERT INTO _lm_ui_case_20260911_policy(prefix) VALUES ('cmn-Hans'),('cmn-Hant'),('jpn'),('kor'),('nan-Hant');
-- langmap:batch
CREATE TABLE _lm_ui_case_20260911_keys(expression_id INTEGER PRIMARY KEY,language_id INTEGER NOT NULL,homograph_index INTEGER NOT NULL,normalized_text TEXT NOT NULL);
-- langmap:batch
CREATE INDEX _lm_ui_case_20260911_keys_identity ON _lm_ui_case_20260911_keys(language_id,homograph_index,normalized_text,expression_id);
-- langmap:batch
CREATE TABLE _lm_ui_case_20260911_map(old_expression_id INTEGER PRIMARY KEY,survivor_expression_id INTEGER NOT NULL,target_text TEXT NOT NULL);
-- langmap:batch
CREATE INDEX _lm_ui_case_20260911_map_survivor ON _lm_ui_case_20260911_map(survivor_expression_id);
-- langmap:batch
INSERT OR IGNORE INTO _lm_ui_case_20260911_keys(expression_id,language_id,homograph_index,normalized_text)
SELECT e.id,e.language_id,e.homograph_index,upper(substr(lower(trim(e.text)),1,1)) || substr(lower(trim(e.text)),2)
FROM expressions e
WHERE e.source_id=(SELECT id FROM sources WHERE name='system-ui' ORDER BY id LIMIT 1)
AND trim(e.text) GLOB '[A-Za-z]*'
AND trim(e.text) NOT GLOB '*[^ -~]*'
AND NOT (trim(e.text) GLOB '*[A-Z]*' AND trim(e.text) NOT GLOB '*[a-z]*')
AND EXISTS (SELECT 1 FROM expression_locale_links ell JOIN language_locales ll ON ll.id=ell.locale_id WHERE ell.expression_id=e.id AND NOT EXISTS (SELECT 1 FROM _lm_ui_case_20260911_policy p WHERE ll.code LIKE p.prefix || '%'));
-- langmap:batch
WITH candidates AS (
  SELECT k.expression_id,k.normalized_text,
    COALESCE(
      (SELECT e2.id FROM expressions e2 WHERE e2.language_id=k.language_id AND e2.homograph_index=k.homograph_index AND e2.text=k.normalized_text ORDER BY e2.id LIMIT 1),
      (SELECT k2.expression_id FROM _lm_ui_case_20260911_keys k2 WHERE k2.language_id=k.language_id AND k2.homograph_index=k.homograph_index AND k2.normalized_text=k.normalized_text ORDER BY k2.expression_id LIMIT 1)
    ) AS survivor_id
  FROM _lm_ui_case_20260911_keys k
)
INSERT OR IGNORE INTO _lm_ui_case_20260911_map(old_expression_id,survivor_expression_id,target_text)
SELECT expression_id,survivor_id,normalized_text FROM candidates WHERE survivor_id<>expression_id;
-- langmap:batch
UPDATE expressions AS survivor SET pos_mask=pos_mask | COALESCE((SELECT old.pos_mask FROM expressions old JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=old.id WHERE m.survivor_expression_id=survivor.id ORDER BY old.id LIMIT 1),0) WHERE survivor.id IN (SELECT survivor_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE expressions AS survivor SET source_id=COALESCE(source_id,(SELECT old.source_id FROM expressions old JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=old.id WHERE m.survivor_expression_id=survivor.id AND old.source_id IS NOT NULL ORDER BY old.id LIMIT 1)),created_by=COALESCE(created_by,(SELECT old.created_by FROM expressions old JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=old.id WHERE m.survivor_expression_id=survivor.id AND old.created_by IS NOT NULL ORDER BY old.id LIMIT 1)) WHERE survivor.id IN (SELECT survivor_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id) SELECT m.survivor_expression_id,l.locale_id FROM expression_locale_links l JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=l.expression_id;
-- langmap:batch
DELETE FROM expression_locale_links WHERE expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
INSERT OR IGNORE INTO expression_readings(expression_id,locale_id,scheme,value,source_id) SELECT m.survivor_expression_id,r.locale_id,r.scheme,r.value,r.source_id FROM expression_readings r JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=r.expression_id;
-- langmap:batch
UPDATE expression_readings AS target SET source_id=COALESCE(source_id,(SELECT MIN(old.source_id) FROM expression_readings old JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=old.expression_id WHERE m.survivor_expression_id=target.expression_id AND old.locale_id=target.locale_id AND old.scheme=target.scheme AND old.value=target.value AND old.source_id IS NOT NULL)) WHERE target.expression_id IN (SELECT survivor_expression_id FROM _lm_ui_case_20260911_map) AND target.source_id IS NULL;
-- langmap:batch
DELETE FROM expression_readings WHERE expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
INSERT OR IGNORE INTO expression_sources(expression_id,source_id,source_marker) SELECT m.survivor_expression_id,s.source_id,s.source_marker FROM expression_sources s JOIN _lm_ui_case_20260911_map m ON m.old_expression_id=s.expression_id;
-- langmap:batch
DELETE FROM expression_sources WHERE expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE languages SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=languages.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE language_locales SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=language_locales.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE scripts SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=scripts.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE regions SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=regions.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE morphological_dimensions SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=morphological_dimensions.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE morphological_features SET name_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=morphological_features.name_expression_id) WHERE name_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
DELETE FROM handbook_section_items AS h WHERE EXISTS (SELECT 1 FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=h.expression_id AND EXISTS (SELECT 1 FROM handbook_section_items h2 WHERE h2.section_id=h.section_id AND h2.expression_id=m.survivor_expression_id));
-- langmap:batch
DELETE FROM handbook_section_items AS h WHERE EXISTS (SELECT 1 FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=h.expression_id AND EXISTS (SELECT 1 FROM handbook_section_items h2 JOIN _lm_ui_case_20260911_map m2 ON m2.old_expression_id=h2.expression_id WHERE h2.section_id=h.section_id AND m2.survivor_expression_id=m.survivor_expression_id AND (h2.position<h.position OR (h2.position=h.position AND h2.expression_id<h.expression_id))));
-- langmap:batch
UPDATE handbook_section_items SET expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=handbook_section_items.expression_id) WHERE expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE ui_messages SET source_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=ui_messages.source_expression_id) WHERE source_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE expression_splits SET source_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=expression_splits.source_expression_id) WHERE source_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE expression_splits SET target_expression_id=(SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=expression_splits.target_expression_id) WHERE target_expression_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
CREATE TABLE _lm_ui_case_20260911_edge_targets(edge_id INTEGER PRIMARY KEY,target_a INTEGER NOT NULL,target_b INTEGER NOT NULL,survivor_edge_id INTEGER);
-- langmap:batch
CREATE INDEX _lm_ui_case_20260911_edge_targets_target ON _lm_ui_case_20260911_edge_targets(target_a,target_b);
-- langmap:batch
WITH mapped AS (
  SELECT e.id,
    MIN(COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.expression_a_id),e.expression_a_id),COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.expression_b_id),e.expression_b_id)) AS target_a,
    MAX(COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.expression_a_id),e.expression_a_id),COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.expression_b_id),e.expression_b_id)) AS target_b
  FROM expression_edges e WHERE e.expression_a_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map) OR e.expression_b_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map)
)
INSERT INTO _lm_ui_case_20260911_edge_targets(edge_id,target_a,target_b) SELECT id,target_a,target_b FROM mapped;
-- langmap:batch
INSERT OR IGNORE INTO _lm_ui_case_20260911_edge_targets(edge_id,target_a,target_b) SELECT e.id,e.expression_a_id,e.expression_b_id FROM expression_edges e WHERE EXISTS (SELECT 1 FROM _lm_ui_case_20260911_edge_targets h WHERE h.target_a=e.expression_a_id AND h.target_b=e.expression_b_id);
-- langmap:batch
UPDATE _lm_ui_case_20260911_edge_targets SET survivor_edge_id=(SELECT MIN(h2.edge_id) FROM _lm_ui_case_20260911_edge_targets h2 WHERE h2.target_a=_lm_ui_case_20260911_edge_targets.target_a AND h2.target_b=_lm_ui_case_20260911_edge_targets.target_b);
-- langmap:batch
CREATE INDEX _lm_ui_case_20260911_edge_targets_survivor ON _lm_ui_case_20260911_edge_targets(survivor_edge_id,edge_id);
-- langmap:batch
INSERT OR IGNORE INTO expression_edge_sources(edge_id,source_id,source_marker) SELECT h.survivor_edge_id,s.source_id,s.source_marker FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edge_sources s ON s.edge_id=h.edge_id WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b;
-- langmap:batch
INSERT OR IGNORE INTO edge_votes(user_id,edge_id,vote) SELECT v.user_id,h.survivor_edge_id,v.vote FROM _lm_ui_case_20260911_edge_targets h JOIN edge_votes v ON v.edge_id=h.edge_id WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b;
-- langmap:batch
INSERT OR IGNORE INTO expression_split_moves(split_id,edge_id) SELECT sm.split_id,h.survivor_edge_id FROM _lm_ui_case_20260911_edge_targets h JOIN expression_split_moves sm ON sm.edge_id=h.edge_id WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b;
-- langmap:batch
UPDATE expression_edges SET relation_mask=relation_mask | 1 WHERE id IN (SELECT h.survivor_edge_id FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id IS NOT NULL AND (old.relation_mask & 1)<>0);
-- langmap:batch
UPDATE expression_edges SET relation_mask=relation_mask | 2 WHERE id IN (SELECT h.survivor_edge_id FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id IS NOT NULL AND (old.relation_mask & 2)<>0);
-- langmap:batch
UPDATE expression_edges SET relation_mask=relation_mask | 4 WHERE id IN (SELECT h.survivor_edge_id FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id IS NOT NULL AND (old.relation_mask & 4)<>0);
-- langmap:batch
UPDATE expression_edges AS survivor SET score=MAX(score,COALESCE((SELECT MAX(old.score) FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id=survivor.id),score)),created_by=COALESCE(created_by,(SELECT old.created_by FROM _lm_ui_case_20260911_edge_targets h JOIN expression_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id=survivor.id AND old.created_by IS NOT NULL ORDER BY old.id LIMIT 1)) WHERE id IN (SELECT survivor_edge_id FROM _lm_ui_case_20260911_edge_targets WHERE target_a<target_b);
-- langmap:batch
DELETE FROM expression_split_moves WHERE edge_id IN (SELECT edge_id FROM _lm_ui_case_20260911_edge_targets WHERE target_a=target_b);
-- langmap:batch
DELETE FROM expression_split_moves WHERE edge_id IN (SELECT edge_id FROM _lm_ui_case_20260911_edge_targets WHERE edge_id<>survivor_edge_id);
-- langmap:batch
DELETE FROM expression_edges WHERE id IN (SELECT edge_id FROM _lm_ui_case_20260911_edge_targets WHERE target_a=target_b OR edge_id<>survivor_edge_id);
-- langmap:batch
UPDATE expression_edges SET expression_a_id=(SELECT target_a FROM _lm_ui_case_20260911_edge_targets h WHERE h.edge_id=expression_edges.id),expression_b_id=(SELECT target_b FROM _lm_ui_case_20260911_edge_targets h WHERE h.edge_id=expression_edges.id) WHERE id IN (SELECT survivor_edge_id FROM _lm_ui_case_20260911_edge_targets WHERE target_a<target_b);
-- langmap:batch
CREATE TABLE _lm_ui_case_20260911_form_targets(edge_id INTEGER PRIMARY KEY,target_form INTEGER NOT NULL,target_lemma INTEGER NOT NULL,survivor_edge_id INTEGER);
-- langmap:batch
CREATE INDEX _lm_ui_case_20260911_form_targets_target ON _lm_ui_case_20260911_form_targets(target_form,target_lemma);
-- langmap:batch
WITH mapped AS (SELECT e.id,COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.form_id),e.form_id) AS target_form,COALESCE((SELECT m.survivor_expression_id FROM _lm_ui_case_20260911_map m WHERE m.old_expression_id=e.lemma_id),e.lemma_id) AS target_lemma FROM expression_form_edges e WHERE e.form_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map) OR e.lemma_id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map)) INSERT INTO _lm_ui_case_20260911_form_targets(edge_id,target_form,target_lemma) SELECT id,target_form,target_lemma FROM mapped;
-- langmap:batch
INSERT OR IGNORE INTO _lm_ui_case_20260911_form_targets(edge_id,target_form,target_lemma) SELECT e.id,e.form_id,e.lemma_id FROM expression_form_edges e WHERE EXISTS (SELECT 1 FROM _lm_ui_case_20260911_form_targets h WHERE h.target_form=e.form_id AND h.target_lemma=e.lemma_id);
-- langmap:batch
UPDATE _lm_ui_case_20260911_form_targets SET survivor_edge_id=(SELECT MIN(h2.edge_id) FROM _lm_ui_case_20260911_form_targets h2 WHERE h2.target_form=_lm_ui_case_20260911_form_targets.target_form AND h2.target_lemma=_lm_ui_case_20260911_form_targets.target_lemma);
-- langmap:batch
INSERT OR IGNORE INTO expression_form_edge_features(edge_id,feature_code) SELECT h.survivor_edge_id,f.feature_code FROM _lm_ui_case_20260911_form_targets h JOIN expression_form_edge_features f ON f.edge_id=h.edge_id WHERE h.edge_id<>h.survivor_edge_id AND h.target_form<>h.target_lemma;
-- langmap:batch
UPDATE expression_form_edges AS survivor SET created_by=COALESCE(created_by,(SELECT old.created_by FROM _lm_ui_case_20260911_form_targets h JOIN expression_form_edges old ON old.id=h.edge_id WHERE h.survivor_edge_id=survivor.id AND old.created_by IS NOT NULL ORDER BY old.id LIMIT 1)) WHERE id IN (SELECT survivor_edge_id FROM _lm_ui_case_20260911_form_targets WHERE target_form<>target_lemma);
-- langmap:batch
DELETE FROM expression_form_edges WHERE id IN (SELECT edge_id FROM _lm_ui_case_20260911_form_targets WHERE target_form=target_lemma OR edge_id<>survivor_edge_id);
-- langmap:batch
UPDATE expression_form_edges SET form_id=(SELECT target_form FROM _lm_ui_case_20260911_form_targets h WHERE h.edge_id=expression_form_edges.id),lemma_id=(SELECT target_lemma FROM _lm_ui_case_20260911_form_targets h WHERE h.edge_id=expression_form_edges.id) WHERE id IN (SELECT survivor_edge_id FROM _lm_ui_case_20260911_form_targets WHERE target_form<>target_lemma);
-- langmap:batch
DELETE FROM expressions WHERE id IN (SELECT old_expression_id FROM _lm_ui_case_20260911_map);
-- langmap:batch
UPDATE expressions SET text=(SELECT normalized_text FROM _lm_ui_case_20260911_keys k WHERE k.expression_id=expressions.id) WHERE id IN (SELECT expression_id FROM _lm_ui_case_20260911_keys) AND text<>(SELECT normalized_text FROM _lm_ui_case_20260911_keys k WHERE k.expression_id=expressions.id);
-- langmap:batch
UPDATE ui_messages SET source_text=(SELECT text FROM expressions e WHERE e.id=ui_messages.source_expression_id);
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_form_targets;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_edge_targets;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_map;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_keys;
-- langmap:batch
DROP TABLE IF EXISTS _lm_ui_case_20260911_policy;
