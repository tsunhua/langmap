-- Add explicit "positive" polarity feature so polarity is a true radio dimension.

-- 1. Name expressions for "positive"
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn', '肯定', 'p4egshpg447re5bxiwwnnwxy6a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng', 'positive', 'v6totkz2yzlu2uhgwvtu2xtwzq', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn', '肯定', 'p4egshpg447re5bxiwwnnwxy6a', 1, '', '[]', NULL, NULL, 'approved', NULL);
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES ('spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa', 'positivo', 'hx77yb5rwmqekcrr3tkqrm7skq', 1, '', '[]', NULL, NULL, 'approved', NULL);

-- 2. Locale attestations
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hans-CN:cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn-Hans-CN', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:cmn-Hant-TW:cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'cmn-Hant-TW', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:eng-Latn-US:eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'eng-Latn-US', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:jpn-Jpan-JP:jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn:p4egshpg447re5bxiwwnnwxy6a', 'jpn-Jpan-JP', NULL, NULL, NULL);
INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES ('morph-att:spa-Latn-ES:spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa:hx77yb5rwmqekcrr3tkqrm7skq', 'spa-Latn-ES', NULL, NULL, NULL);

-- 3. Translation edges (source=seed)
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:cmn:p4egshpg447re5bxiwwnnwxy6a:eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'cmn:p4egshpg447re5bxiwwnnwxy6a', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:v6totkz2yzlu2uhgwvtu2xtwzq:jpn:p4egshpg447re5bxiwwnnwxy6a', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'jpn:p4egshpg447re5bxiwwnnwxy6a', 0, 'seed', NULL);
INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by) VALUES ('morph-edge:eng:v6totkz2yzlu2uhgwvtu2xtwzq:spa:hx77yb5rwmqekcrr3tkqrm7skq', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 'spa:hx77yb5rwmqekcrr3tkqrm7skq', 0, 'seed', NULL);

-- 4. Morphological features
INSERT OR IGNORE INTO morphological_features (code, dimension_code, name_expression_id, sort_order) VALUES ('positive', 'polarity', 'eng:v6totkz2yzlu2uhgwvtu2xtwzq', 2);
