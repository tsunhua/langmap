-- Remove migrated Yue UI translation expressions; keep the yue registry and locale.
DELETE FROM handbook_section_items
WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = 'yue');
DELETE FROM expression_form_edge_features
WHERE edge_id IN (
  SELECT id FROM expression_form_edges
  WHERE form_id IN (SELECT id FROM expressions WHERE lang_code = 'yue')
     OR lemma_id IN (SELECT id FROM expressions WHERE lang_code = 'yue')
);
DELETE FROM expression_form_edges
WHERE form_id IN (SELECT id FROM expressions WHERE lang_code = 'yue')
   OR lemma_id IN (SELECT id FROM expressions WHERE lang_code = 'yue');
DELETE FROM expression_locale_attestations
WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = 'yue');
DELETE FROM expression_readings
WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = 'yue');
DELETE FROM expression_edges
WHERE expression_a_id IN (SELECT id FROM expressions WHERE lang_code = 'yue')
   OR expression_b_id IN (SELECT id FROM expressions WHERE lang_code = 'yue');
DELETE FROM expressions WHERE lang_code = 'yue';
