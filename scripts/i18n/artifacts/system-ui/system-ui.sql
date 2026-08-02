-- Generated managed system UI translation bundle
-- Project: langmap-web
-- Ownership scope: managed-system-ui

-- 1. Upsert locale metadata
-- Locale cmn-Hans
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'cmn-Hans', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'cmn-Hans'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale cmn-Hant
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'cmn-Hant', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'cmn-Hant'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale en
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'en', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'en'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale es
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'es', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'es'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale ja
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'ja', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'ja'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- 2. Source messages (312 keys)
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771988929111883, 'Email', 'en', 'ui_i18n', 'langmap-web:auth.email', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.email', 8771988929111883, '[]', '8771988929111883', 'active');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771987324928109, 'Already have an account?', 'en', 'ui_i18n', 'langmap-web:auth.haveAccount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.haveAccount', 8771987324928109, '[]', '8771987324928109', 'active');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771985319534907, 'Sign in', 'en', 'ui_i18n', 'langmap-web:auth.login', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.login', 8771985319534907, '[]', '8771985319534907', 'active');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771920874847316, 'Don''t have an account?', 'en', 'ui_i18n', 'langmap-web:auth.noAccount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.noAccount', 8771920874847316, '[]', '8771920874847316', 'active');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771934955742921, 'Operation failed', 'en', 'ui_i18n', 'langmap-web:auth.operationFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.operationFailed', 8771934955742921, '[]', '8771934955742921', 'active');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771993838728081, 'Password', 'en', 'ui_i18n', 'langmap-web:auth.password', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.password', 8771993838728081, '[]', '8771993838728081', 'active');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001046060388, 'Processing…', 'en', 'ui_i18n', 'langmap-web:auth.processing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.processing', 8772001046060388, '[]', '8772001046060388', 'active');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771964374844751, 'Create account', 'en', 'ui_i18n', 'langmap-web:auth.register', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.register', 8771964374844751, '[]', '8771964374844751', 'active');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029311767367, 'Username', 'en', 'ui_i18n', 'langmap-web:auth.username', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.username', 8772029311767367, '[]', '8772029311767367', 'active');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001703307290, 'Cancel', 'en', 'ui_i18n', 'langmap-web:common.cancel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.cancel', 8772001703307290, '[]', '8772001703307290', 'active');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771958345505312, 'Close', 'en', 'ui_i18n', 'langmap-web:common.close', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.close', 8771958345505312, '[]', '8771958345505312', 'active');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930947571421, 'Language', 'en', 'ui_i18n', 'langmap-web:common.language', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.language', 8771930947571421, '[]', '8771930947571421', 'active');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771966685762373, 'Languages', 'en', 'ui_i18n', 'langmap-web:common.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.languages', 8771966685762373, '[]', '8771966685762373', 'active');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771908386278726, 'Loading…', 'en', 'ui_i18n', 'langmap-web:common.loading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.loading', 8771908386278726, '[]', '8771908386278726', 'active');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772018337291447, 'Search', 'en', 'ui_i18n', 'langmap-web:common.search', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.search', 8772018337291447, '[]', '8772018337291447', 'active');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771955384790296, 'Submit', 'en', 'ui_i18n', 'langmap-web:common.submit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.submit', 8771955384790296, '[]', '8771955384790296', 'active');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771913559728006, 'Actual size 100%', 'en', 'ui_i18n', 'langmap-web:components.actualSize', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.actualSize', 8771913559728006, '[]', '8771913559728006', 'active');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771963881461252, 'Anonymous', 'en', 'ui_i18n', 'langmap-web:components.anonymous', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.anonymous', 8771963881461252, '[]', '8771963881461252', 'active');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772032837909466, '{count} child nodes; click to collapse', 'en', 'ui_i18n', 'langmap-web:components.childNodes', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.childNodes', 8772032837909466, '[]', '8772032837909466', 'active');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772028933737015, 'Each edge is an independent direct mapping that can be upvoted or downvoted; low-scoring mappings are collapsed.', 'en', 'ui_i18n', 'langmap-web:components.cliqueNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.cliqueNote', 8772028933737015, '[]', '8772028933737015', 'active');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771990687804642, 'Mapping graph to be created', 'en', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.cliqueTitle', 8771990687804642, '[]', '8771990687804642', 'active');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771923580873788, 'Close information panel', 'en', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.closeInfoPanel', 8771923580873788, '[]', '8771923580873788', 'active');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772025115555117, 'Collapse', 'en', 'ui_i18n', 'langmap-web:components.collapse', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapse', 8772025115555117, '[]', '8772025115555117', 'active');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772021975712328, 'Collapse child branch', 'en', 'ui_i18n', 'langmap-web:components.collapseBranch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapseBranch', 8772021975712328, '[]', '8772021975712328', 'active');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771963062101045, 'Collapse to first hop', 'en', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapseToFirst', 8771963062101045, '[]', '8771963062101045', 'active');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772016085305408, '{count} days ago', 'en', 'ui_i18n', 'langmap-web:components.daysAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.daysAgo', 8772016085305408, '[]', '8772016085305408', 'active');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772018587383663, 'Depth {depth}', 'en', 'ui_i18n', 'langmap-web:components.depth', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.depth', 8772018587383663, '[]', '8772018587383663', 'active');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771921679343522, 'Directly mapped expressions', 'en', 'ui_i18n', 'langmap-web:components.directMappingList', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.directMappingList', 8771921679343522, '[]', '8771921679343522', 'active');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771992127181974, 'Downvote', 'en', 'ui_i18n', 'langmap-web:components.downvote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.downvote', 8771992127181974, '[]', '8771992127181974', 'active');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771907018302878, '{count} edges', 'en', 'ui_i18n', 'langmap-web:components.edgeCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.edgeCount', 8771907018302878, '[]', '8771907018302878', 'active');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772000424294921, 'No data yet', 'en', 'ui_i18n', 'langmap-web:components.empty', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.empty', 8772000424294921, '[]', '8772000424294921', 'active');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771995527490116, 'Exit fullscreen', 'en', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.exitFullscreen', 8771995527490116, '[]', '8771995527490116', 'active');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957005515059, 'Expand', 'en', 'ui_i18n', 'langmap-web:components.expand', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expand', 8771957005515059, '[]', '8771957005515059', 'active');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772033758268399, 'Expand all', 'en', 'ui_i18n', 'langmap-web:components.expandAll', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expandAll', 8772033758268399, '[]', '8772033758268399', 'active');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771937729949713, 'Expand child branch', 'en', 'ui_i18n', 'langmap-web:components.expandBranch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expandBranch', 8771937729949713, '[]', '8771937729949713', 'active');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772028411030279, 'Expression', 'en', 'ui_i18n', 'langmap-web:components.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expression', 8772028411030279, '[]', '8772028411030279', 'active');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771975185705787, 'Filter languages…', 'en', 'ui_i18n', 'langmap-web:components.filterLanguages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.filterLanguages', 8771975185705787, '[]', '8771975185705787', 'active');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771984311379866, 'Fullscreen', 'en', 'ui_i18n', 'langmap-web:components.fullscreen', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.fullscreen', 8771984311379866, '[]', '8771984311379866', 'active');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771940176065576, 'Expression mapping graph', 'en', 'ui_i18n', 'langmap-web:components.graphLabel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphLabel', 8771940176065576, '[]', '8771940176065576', 'active');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930916265390, 'Loading graph…', 'en', 'ui_i18n', 'langmap-web:components.graphLoading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphLoading', 8771930916265390, '[]', '8771930916265390', 'active');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772018055755937, 'Graph mode', 'en', 'ui_i18n', 'langmap-web:components.graphMode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphMode', 8772018055755937, '[]', '8772018055755937', 'active');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930566920504, '{nodes} mapped nodes · {edges} relations', 'en', 'ui_i18n', 'langmap-web:components.graphStats', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphStats', 8771930566920504, '[]', '8771930566920504', 'active');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957995007293, 'Graph toolbar', 'en', 'ui_i18n', 'langmap-web:components.graphToolbar', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphToolbar', 8771957995007293, '[]', '8771957995007293', 'active');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771972530005685, 'Mapping hierarchy list', 'en', 'ui_i18n', 'langmap-web:components.hierarchyList', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hierarchyList', 8771972530005685, '[]', '8771972530005685', 'active');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771929108158859, 'Hops', 'en', 'ui_i18n', 'langmap-web:components.hops', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hops', 8771929108158859, '[]', '8771929108158859', 'active');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771972038859703, '{count} hours ago', 'en', 'ui_i18n', 'langmap-web:components.hoursAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hoursAgo', 8771972038859703, '[]', '8771972038859703', 'active');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772006156641051, 'Just now', 'en', 'ui_i18n', 'langmap-web:components.justNow', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.justNow', 8772006156641051, '[]', '8772006156641051', 'active');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771907230355366, 'Unable to load languages', 'en', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.languageLoadFailed', 8771907230355366, '[]', '8771907230355366', 'active');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771978209325624, 'List mode', 'en', 'ui_i18n', 'langmap-web:components.listMode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.listMode', 8771978209325624, '[]', '8771978209325624', 'active');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968298248581, 'Load more', 'en', 'ui_i18n', 'langmap-web:components.loadMore', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.loadMore', 8771968298248581, '[]', '8771968298248581', 'active');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771918922470710, 'Loading related expressions', 'en', 'ui_i18n', 'langmap-web:components.loadingRelated', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.loadingRelated', 8771918922470710, '[]', '8771918922470710', 'active');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772009894682686, 'Mapping', 'en', 'ui_i18n', 'langmap-web:components.mapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.mapping', 8772009894682686, '[]', '8772009894682686', 'active');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001613332908, 'Mapping score', 'en', 'ui_i18n', 'langmap-web:components.mappingScore', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.mappingScore', 8772001613332908, '[]', '8772001613332908', 'active');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029891163450, '{count} minutes ago', 'en', 'ui_i18n', 'langmap-web:components.minutesAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.minutesAgo', 8772029891163450, '[]', '8772029891163450', 'active');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771927265880728, 'More actions', 'en', 'ui_i18n', 'langmap-web:components.moreActions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.moreActions', 8771927265880728, '[]', '8771927265880728', 'active');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771978296601845, '{count} more mappings are available in the full graph.', 'en', 'ui_i18n', 'langmap-web:components.moreMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.moreMappings', 8771978296601845, '[]', '8771978296601845', 'active');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771916846886490, 'No direct mappings yet.', 'en', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.noDirectMappings', 8771916846886490, '[]', '8771916846886490', 'active');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771950851535873, 'No expressions found', 'en', 'ui_i18n', 'langmap-web:components.noExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.noExpressions', 8771950851535873, '[]', '8771950851535873', 'active');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771915754603204, '{count} nodes', 'en', 'ui_i18n', 'langmap-web:components.nodeCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.nodeCount', 8771915754603204, '[]', '8771915754603204', 'active');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772032217763299, 'Node information', 'en', 'ui_i18n', 'langmap-web:components.nodeInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.nodeInfo', 8772032217763299, '[]', '8772032217763299', 'active');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772011775552074, 'Other relations', 'en', 'ui_i18n', 'langmap-web:components.otherRelations', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.otherRelations', 8772011775552074, '[]', '8772011775552074', 'active');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771996275317129, 'Related expressions', 'en', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.relatedExpressions', 8771996275317129, '[]', '8771996275317129', 'active');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771905570354775, '{count} relations', 'en', 'ui_i18n', 'langmap-web:components.relationCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.relationCount', 8771905570354775, '[]', '8771905570354775', 'active');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968148353493, 'Remove {code}', 'en', 'ui_i18n', 'langmap-web:components.removeLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.removeLanguage', 8771968148353493, '[]', '8771968148353493', 'active');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771923590138278, 'Reset layout', 'en', 'ui_i18n', 'langmap-web:components.resetLayout', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.resetLayout', 8771923590138278, '[]', '8771923590138278', 'active');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771991096471187, 'Root node', 'en', 'ui_i18n', 'langmap-web:components.rootNode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.rootNode', 8771991096471187, '[]', '8771991096471187', 'active');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772018337291447, 'Search', 'en', 'ui_i18n', 'langmap-web:components.search', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.search', 8772018337291447, '[]', '8772018337291447', 'active');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771934172254861, 'Search expressions…', 'en', 'ui_i18n', 'langmap-web:components.searchExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.searchExpressions', 8771934172254861, '[]', '8771934172254861', 'active');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771951969125148, 'Searching…', 'en', 'ui_i18n', 'langmap-web:components.searching', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.searching', 8771951969125148, '[]', '8771951969125148', 'active');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771969317410200, 'Select a node in the graph to view details', 'en', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.selectNodeHint', 8771969317410200, '[]', '8771969317410200', 'active');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771977750841844, 'Source path', 'en', 'ui_i18n', 'langmap-web:components.sourcePath', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.sourcePath', 8771977750841844, '[]', '8771977750841844', 'active');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772016238570208, 'Upvote', 'en', 'ui_i18n', 'langmap-web:components.upvote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.upvote', 8772016238570208, '[]', '8772016238570208', 'active');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771995720429284, 'View expression details', 'en', 'ui_i18n', 'langmap-web:components.viewExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.viewExpression', 8771995720429284, '[]', '8771995720429284', 'active');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772020751025198, 'Vote failed; reverted', 'en', 'ui_i18n', 'langmap-web:components.voteFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.voteFailed', 8772020751025198, '[]', '8772020751025198', 'active');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772017398603959, 'Zoom in', 'en', 'ui_i18n', 'langmap-web:components.zoomIn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.zoomIn', 8772017398603959, '[]', '8772017398603959', 'active');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772017289371875, 'Zoom out', 'en', 'ui_i18n', 'langmap-web:components.zoomOut', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.zoomOut', 8772017289371875, '[]', '8772017289371875', 'active');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771945073983212, '+ Add expression', 'en', 'ui_i18n', 'langmap-web:contribute.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.addExpression', 8771945073983212, '[]', '8771945073983212', 'active');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771921254303111, 'Complete graph', 'en', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.completeGraph', 8771921254303111, '[]', '8771921254303111', 'active');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771944300238713, 'Delete', 'en', 'ui_i18n', 'langmap-web:contribute.delete', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.delete', 8771944300238713, '[]', '8771944300238713', 'active');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968945113345, '{count} direct mappings', 'en', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.directMappingCount', 8771968945113345, '[]', '8771968945113345', 'active');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772028411030279, 'Expression', 'en', 'ui_i18n', 'langmap-web:contribute.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expression', 8772028411030279, '[]', '8772028411030279', 'active');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771918589046163, '{count} expressions', 'en', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expressionCount', 8771918589046163, '[]', '8771918589046163', 'active');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771975160452098, 'Enter an expression…', 'en', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expressionPlaceholder', 8771975160452098, '[]', '8771975160452098', 'active');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930947571421, 'Language', 'en', 'ui_i18n', 'langmap-web:contribute.language', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.language', 8771930947571421, '[]', '8771930947571421', 'active');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771938370927027, 'Submit a group of expressions that mean the same thing. The system creates direct mappings between every pair. Existing expressions are linked automatically without duplicates.', 'en', 'ui_i18n', 'langmap-web:contribute.lead', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.lead', 8771938370927027, '[]', '8771938370927027', 'active');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771996574983759, 'At least 2 rows with a language and expression are required', 'en', 'ui_i18n', 'langmap-web:contribute.minRows', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.minRows', 8771996574983759, '[]', '8771996574983759', 'active');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771955384790296, 'Submit', 'en', 'ui_i18n', 'langmap-web:contribute.submit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submit', 8771955384790296, '[]', '8771955384790296', 'active');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930781451254, 'Submission failed', 'en', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submitFailed', 8771930781451254, '[]', '8771930781451254', 'active');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771996654725718, 'Submitting…', 'en', 'ui_i18n', 'langmap-web:contribute.submitting', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submitting', 8771996654725718, '[]', '8771996654725718', 'active');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772023049338365, 'Tags', 'en', 'ui_i18n', 'langmap-web:contribute.tags', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.tags', 8772023049338365, '[]', '8772023049338365', 'active');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771967116778370, 'Batch contribution', 'en', 'ui_i18n', 'langmap-web:contribute.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.title', 8771967116778370, '[]', '8771967116778370', 'active');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771954914944651, 'Back home', 'en', 'ui_i18n', 'langmap-web:errors.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.home', 8771954914944651, '[]', '8771954914944651', 'active');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936602672507, 'Unable to load', 'en', 'ui_i18n', 'langmap-web:errors.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.loadFailed', 8771936602672507, '[]', '8771936602672507', 'active');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771958158698832, 'Page not found', 'en', 'ui_i18n', 'langmap-web:errors.pageMissing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.pageMissing', 8771958158698832, '[]', '8771958158698832', 'active');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771912696777795, 'All', 'en', 'ui_i18n', 'langmap-web:feed.all', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.all', 8771912696777795, '[]', '8771912696777795', 'active');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771952067596101, 'Contribute a mapping →', 'en', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.contributeMapping', 8771952067596101, '[]', '8771952067596101', 'active');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957966582874, 'Popular', 'en', 'ui_i18n', 'langmap-web:feed.hot', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.hot', 8771957966582874, '[]', '8771957966582874', 'active');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771971172552785, 'Mappings + new expressions', 'en', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.mappingsAndExpressions', 8771971172552785, '[]', '8771971172552785', 'active');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771964553678580, 'Can’t find what you need?', 'en', 'ui_i18n', 'langmap-web:feed.missing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.missing', 8771964553678580, '[]', '8771964553678580', 'active');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772013263074963, 'New contributions', 'en', 'ui_i18n', 'langmap-web:feed.newContributions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.newContributions', 8772013263074963, '[]', '8772013263074963', 'active');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771912463566270, 'Latest', 'en', 'ui_i18n', 'langmap-web:feed.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.newest', 8771912463566270, '[]', '8771912463566270', 'active');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771956320455891, 'Popular mappings', 'en', 'ui_i18n', 'langmap-web:feed.popularMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.popularMappings', 8771956320455891, '[]', '8771956320455891', 'active');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001941683119, 'By score · this week', 'en', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.ratedThisWeek', 8772001941683119, '[]', '8772001941683119', 'active');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771985464043467, 'The latest pulse of the semantic graph — popular mappings and new contributions.', 'en', 'ui_i18n', 'langmap-web:feed.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.subtitle', 8771985464043467, '[]', '8771985464043467', 'active');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771928668652497, 'Activity', 'en', 'ui_i18n', 'langmap-web:feed.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.title', 8771928668652497, '[]', '8771928668652497', 'active');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772033519106127, 'Add expression', 'en', 'ui_i18n', 'langmap-web:handbook.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.addExpression', 8772033519106127, '[]', '8772033519106127', 'active');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772013343930223, 'Add section', 'en', 'ui_i18n', 'langmap-web:handbook.addSection', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.addSection', 8772013343930223, '[]', '8772013343930223', 'active');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771985524903836, 'Handbook list', 'en', 'ui_i18n', 'langmap-web:handbook.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.back', 8771985524903836, '[]', '8771985524903836', 'active');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771974942670538, 'Chapter {number}', 'en', 'ui_i18n', 'langmap-web:handbook.chapter', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.chapter', 8771974942670538, '[]', '8771974942670538', 'active');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771948835977551, 'Close expression information', 'en', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.closeExpressionInfo', 8771948835977551, '[]', '8771948835977551', 'active');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772025115555117, 'Collapse', 'en', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.collapsePicker', 8772025115555117, '[]', '8772025115555117', 'active');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771922363562335, 'Delete section', 'en', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.deleteSection', 8771922363562335, '[]', '8771922363562335', 'active');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771954520730023, 'Edit handbook', 'en', 'ui_i18n', 'langmap-web:handbook.edit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.edit', 8771954520730023, '[]', '8771954520730023', 'active');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771958749403912, 'Expression information', 'en', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.expressionInfo', 8771958749403912, '[]', '8771958749403912', 'active');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771969048222271, 'The expression language, region, and source appear here.', 'en', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.expressionInfoHint', 8771969048222271, '[]', '8771969048222271', 'active');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771919030282571, 'Was this handbook helpful?', 'en', 'ui_i18n', 'langmap-web:handbook.helpful', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.helpful', 8771919030282571, '[]', '8771919030282571', 'active');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001956145712, 'Unable to load expression', 'en', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.inspectorFailed', 8772001956145712, '[]', '8772001956145712', 'active');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936602672507, 'Unable to load', 'en', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.loadFailed', 8771936602672507, '[]', '8771936602672507', 'active');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930947571421, 'Language', 'en', 'ui_i18n', 'langmap-web:handbook.locale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.locale', 8771930947571421, '[]', '8771930947571421', 'active');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772015839426216, 'Move down', 'en', 'ui_i18n', 'langmap-web:handbook.moveDown', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveDown', 8772015839426216, '[]', '8772015839426216', 'active');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771974741123489, 'Move section down', 'en', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveSectionDown', 8771974741123489, '[]', '8771974741123489', 'active');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771974343227837, 'Move section up', 'en', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveSectionUp', 8771974343227837, '[]', '8771974343227837', 'active');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772035822327586, 'Move up', 'en', 'ui_i18n', 'langmap-web:handbook.moveUp', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveUp', 8772035822327586, '[]', '8772035822327586', 'active');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771981388316157, 'Private', 'en', 'ui_i18n', 'langmap-web:handbook.private', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.private', 8771981388316157, '[]', '8771981388316157', 'active');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771978356150928, 'Public', 'en', 'ui_i18n', 'langmap-web:handbook.public', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.public', 8771978356150928, '[]', '8771978356150928', 'active');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771952311782197, 'Publish', 'en', 'ui_i18n', 'langmap-web:handbook.publish', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.publish', 8771952311782197, '[]', '8771952311782197', 'active');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968624126325, 'Region', 'en', 'ui_i18n', 'langmap-web:handbook.region', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.region', 8771968624126325, '[]', '8771968624126325', 'active');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771991960796854, 'Unable to load related expressions', 'en', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.relationsFailed', 8771991960796854, '[]', '8771991960796854', 'active');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771948377233166, 'Remove {text}', 'en', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.removeExpression', 8771948377233166, '[]', '8771948377233166', 'active');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771974360984879, 'Save draft', 'en', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.saveDraft', 8771974360984879, '[]', '8771974360984879', 'active');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771980391249065, 'Saving…', 'en', 'ui_i18n', 'langmap-web:handbook.saving', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.saving', 8771980391249065, '[]', '8771980391249065', 'active');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771935521942479, 'Section title', 'en', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sectionTitle', 8771935521942479, '[]', '8771935521942479', 'active');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771975315975664, 'Select an expression', 'en', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.selectExpression', 8771975315975664, '[]', '8771975315975664', 'active');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771933750484319, 'Source', 'en', 'ui_i18n', 'langmap-web:handbook.source', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.source', 8771933750484319, '[]', '8771933750484319', 'active');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771954789056127, 'AI', 'en', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceAi', 8771954789056127, '[]', '8771954789056127', 'active');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029059057248, 'Authority', 'en', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceAuthority', 8772029059057248, '[]', '8772029059057248', 'active');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772034803281550, 'User', 'en', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceUser', 8772034803281550, '[]', '8772034803281550', 'active');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771918701696347, 'Handbook title', 'en', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.titlePlaceholder', 8771918701696347, '[]', '8771918701696347', 'active');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771915172364840, 'Contents', 'en', 'ui_i18n', 'langmap-web:handbook.toc', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.toc', 8771915172364840, '[]', '8771915172364840', 'active');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771928949232797, 'View full relation graph', 'en', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.viewFullGraph', 8771928949232797, '[]', '8771928949232797', 'active');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029984927123, 'Visibility', 'en', 'ui_i18n', 'langmap-web:handbook.visibility', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.visibility', 8772029984927123, '[]', '8772029984927123', 'active');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771984354571011, 'New handbook', 'en', 'ui_i18n', 'langmap-web:handbooks.create', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.create', 8771984354571011, '[]', '8771984354571011', 'active');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771915400044673, 'Unable to load handbooks', 'en', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.loadFailed', 8771915400044673, '[]', '8771915400044673', 'active');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771912463566270, 'Latest', 'en', 'ui_i18n', 'langmap-web:handbooks.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.newest', 8771912463566270, '[]', '8771912463566270', 'active');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772007530341875, 'No handbooks found', 'en', 'ui_i18n', 'langmap-web:handbooks.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.noResults', 8772007530341875, '[]', '8772007530341875', 'active');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957966582874, 'Popular', 'en', 'ui_i18n', 'langmap-web:handbooks.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.popular', 8771957966582874, '[]', '8771957966582874', 'active');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772031472567985, 'Search handbooks…', 'en', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.searchPlaceholder', 8772031472567985, '[]', '8772031472567985', 'active');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771981869623564, 'sections', 'en', 'ui_i18n', 'langmap-web:handbooks.sections', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.sections', 8771981869623564, '[]', '8771981869623564', 'active');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771945183617329, 'Handbooks', 'en', 'ui_i18n', 'langmap-web:handbooks.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.title', 8771945183617329, '[]', '8771945183617329', 'active');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772024038803789, 'Back', 'en', 'ui_i18n', 'langmap-web:languageCreate.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.back', 8772024038803789, '[]', '8772024038803789', 'active');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001703307290, 'Cancel', 'en', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.cancel', 8772001703307290, '[]', '8772001703307290', 'active');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771958345505312, 'Close', 'en', 'ui_i18n', 'langmap-web:languageCreate.close', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.close', 8771958345505312, '[]', '8771958345505312', 'active');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771972155504688, 'Create language', 'en', 'ui_i18n', 'langmap-web:languageCreate.create', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.create', 8771972155504688, '[]', '8771972155504688', 'active');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772008975730714, 'Language creation failed', 'en', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.createFailed', 8772008975730714, '[]', '8772008975730714', 'active');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771943301451236, 'Creating…', 'en', 'ui_i18n', 'langmap-web:languageCreate.creating', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.creating', 8771943301451236, '[]', '8771943301451236', 'active');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771986788835322, 'Enter a description', 'en', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorDescription', 8771986788835322, '[]', '8771986788835322', 'active');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771982145239141, 'Choose a Glottolog match or select "no match"', 'en', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorGlottolog', 8771982145239141, '[]', '8771982145239141', 'active');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771921060819264, 'Enter a language name', 'en', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorName', 8771921060819264, '[]', '8771921060819264', 'active');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771926836463632, 'Select a reason for community-only creation', 'en', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorReason', 8771926836463632, '[]', '8771926836463632', 'active');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772026576042326, 'Enter a language subtag to continue', 'en', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorTag', 8772026576042326, '[]', '8772026576042326', 'active');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771956461019812, '{count} candidate(s) found', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologCandidates', 8771956461019812, '[]', '8771956461019812', 'active');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772033726980358, 'Choose a match or indicate no suitable entry', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologChoose', 8772033726980358, '[]', '8772033726980358', 'active');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772036217067472, 'Match this candidate', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologExactMatch', 8772036217067472, '[]', '8772036217067472', 'active');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771959645210043, 'dialect', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologLevelDialect', 8771959645210043, '[]', '8771959645210043', 'active');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771953851734414, 'language', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologLevelLanguage', 8771953851734414, '[]', '8771953851734414', 'active');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771907658003091, 'Glottolog has no suitable entry', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologNoMatch', 8771907658003091, '[]', '8771907658003091', 'active');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771972676692740, 'Search Glottolog…', 'en', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologSearchPlaceholder', 8771972676692740, '[]', '8771972676692740', 'active');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771937301075282, 'Description', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataDescription', 8771937301075282, '[]', '8771937301075282', 'active');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771929062150956, 'Describe this language or variety…', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataDescriptionPlaceholder', 8771929062150956, '[]', '8771929062150956', 'active');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771913536651859, 'Name', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataName', 8771913536651859, '[]', '8771913536651859', 'active');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772035648862723, 'English name', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataNameEn', 8772035648862723, '[]', '8772035648862723', 'active');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771965397553798, 'Why is this language missing from Glottolog?', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReason', 8771965397553798, '[]', '8771965397553798', 'active');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029121364869, 'Community-specific usage', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonCommunity', 8772029121364869, '[]', '8772029121364869', 'active');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771911763851130, 'Emerging variety', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonEmerging', 8771911763851130, '[]', '8771911763851130', 'active');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772027448793331, 'Missing from Glottolog', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonMissing', 8772027448793331, '[]', '8772027448793331', 'active');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771907717721822, 'Other', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonOther', 8771907717721822, '[]', '8771907717721822', 'active');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771908744199257, 'Select a reason…', 'en', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonPlaceholder', 8771908744199257, '[]', '8771908744199257', 'active');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771946058185965, 'Next', 'en', 'ui_i18n', 'langmap-web:languageCreate.next', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.next', 8771946058185965, '[]', '8771946058185965', 'active');

-- languageCreate.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771986434294618, 'Optional', 'en', 'ui_i18n', 'langmap-web:languageCreate.optional', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.optional', 8771986434294618, '[]', '8771986434294618', 'active');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771986283559204, 'Canonical code', 'en', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewCanonicalCode', 8771986283559204, '[]', '8771986283559204', 'active');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771963047592058, 'This language already exists', 'en', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewExisting', 8771963047592058, '[]', '8771963047592058', 'active');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771911987565882, 'Use existing language', 'en', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewExistingAction', 8771911987565882, '[]', '8771911987565882', 'active');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771972155504688, 'Create language', 'en', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewTitle', 8771972155504688, '[]', '8771972155504688', 'active');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771976682274382, 'Warnings', 'en', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewWarnings', 8771976682274382, '[]', '8771976682274382', 'active');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771969301691665, 'Provisional tag', 'en', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.provisionalTag', 8771969301691665, '[]', '8771969301691665', 'active');

-- languageCreate.requiredHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771998650043417, '* Required', 'en', 'ui_i18n', 'langmap-web:languageCreate.requiredHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.requiredHint', 8771998650043417, '[]', '8771998650043417', 'active');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771926452848847, 'Glottolog match', 'en', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepGlottolog', 8771926452848847, '[]', '8771926452848847', 'active');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771988865126091, 'Metadata', 'en', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepMetadata', 8771988865126091, '[]', '8771988865126091', 'active');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772002442315415, 'Preview & create', 'en', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepPreview', 8772002442315415, '[]', '8772002442315415', 'active');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771982332401463, 'Language tag', 'en', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepTag', 8771982332401463, '[]', '8771982332401463', 'active');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930947571421, 'Language', 'en', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagLanguage', 8771930947571421, '[]', '8771930947571421', 'active');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968624126325, 'Region', 'en', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagRegion', 8771968624126325, '[]', '8771968624126325', 'active');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771976361115614, 'Script', 'en', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagScript', 8771976361115614, '[]', '8771976361115614', 'active');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772015391400398, 'Search subtags…', 'en', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagSearch', 8772015391400398, '[]', '8772015391400398', 'active');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771923711808765, 'Variant', 'en', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagVariant', 8771923711808765, '[]', '8771923711808765', 'active');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772011217159086, '1 variant removed', 'en', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.variantRemoved', 8772011217159086, '[]', '8772011217159086', 'active');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771998528580369, '{count} variant(s) removed', 'en', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.variantsRemoved', 8771998528580369, '[]', '8771998528580369', 'active');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772039352640020, 'Alphabetical', 'en', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.alphabetical', 8772039352640020, '[]', '8772039352640020', 'active');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771966685762373, 'Languages', 'en', 'ui_i18n', 'langmap-web:languageDetail.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.back', 8771966685762373, '[]', '8771966685762373', 'active');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772004481370898, 'Expressions', 'en', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.expressions', 8772004481370898, '[]', '8772004481370898', 'active');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771912463566270, 'Latest', 'en', 'ui_i18n', 'langmap-web:languageDetail.latest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.latest', 8771912463566270, '[]', '8771912463566270', 'active');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936602672507, 'Unable to load', 'en', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.loadFailed', 8771936602672507, '[]', '8771936602672507', 'active');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771947211108180, 'Mapped', 'en', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.mapped', 8771947211108180, '[]', '8771947211108180', 'active');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771950851535873, 'No expressions found', 'en', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.noResults', 8771950851535873, '[]', '8771950851535873', 'active');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957966582874, 'Popular', 'en', 'ui_i18n', 'langmap-web:languageDetail.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.popular', 8771957966582874, '[]', '8771957966582874', 'active');

-- languageDetail.representativeCities
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771920285240829, 'Representative cities', 'en', 'ui_i18n', 'langmap-web:languageDetail.representativeCities', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.representativeCities', 8771920285240829, '[]', '8771920285240829', 'active');

-- languageDetail.representativeCitiesNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771986740325537, 'Reference points for exploration; not the full language distribution.', 'en', 'ui_i18n', 'langmap-web:languageDetail.representativeCitiesNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.representativeCitiesNote', 8771986740325537, '[]', '8771986740325537', 'active');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771934172254861, 'Search expressions…', 'en', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.searchPlaceholder', 8771934172254861, '[]', '8771934172254861', 'active');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771904155296746, 'Clear selection', 'en', 'ui_i18n', 'langmap-web:languagePicker.clear', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.clear', 8771904155296746, '[]', '8771904155296746', 'active');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772010209718094, 'Create new language or variety', 'en', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.createLanguage', 8772010209718094, '[]', '8772010209718094', 'active');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771905467432581, 'No matching languages', 'en', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.noResults', 8771905467432581, '[]', '8771905467432581', 'active');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957308068965, 'Search languages…', 'en', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.placeholder', 8771957308068965, '[]', '8771957308068965', 'active');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771943861429001, 'Suggested by your browser', 'en', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.browserSuggested', 8771943861429001, '[]', '8771943861429001', 'active');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771962203854555, 'Help translate LangMap', 'en', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.helpTranslate', 8771962203854555, '[]', '8771962203854555', 'active');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771905467432581, 'No matching languages', 'en', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.noResults', 8771905467432581, '[]', '8771905467432581', 'active');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772017158300851, 'Recent languages', 'en', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.recent', 8772017158300851, '[]', '8772017158300851', 'active');

-- languagesPage.addLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771909680784385, 'Add language', 'en', 'ui_i18n', 'langmap-web:languagesPage.addLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.addLanguage', 8771909680784385, '[]', '8771909680784385', 'active');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772004481370898, 'Expressions', 'en', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.expressionCount', 8772004481370898, '[]', '8772004481370898', 'active');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771966685762373, 'Languages', 'en', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.languageCount', 8771966685762373, '[]', '8771966685762373', 'active');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771907230355366, 'Unable to load languages', 'en', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.loadFailed', 8771907230355366, '[]', '8771907230355366', 'active');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772015486738705, 'No languages found', 'en', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.noResults', 8772015486738705, '[]', '8772015486738705', 'active');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957308068965, 'Search languages…', 'en', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.searchPlaceholder', 8771957308068965, '[]', '8771957308068965', 'active');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771973400276236, 'A–Z', 'en', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.sortAlphabetical', 8771973400276236, '[]', '8771973400276236', 'active');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771994726877247, 'Count', 'en', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.sortCount', 8771994726877247, '[]', '8771994726877247', 'active');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772027985468400, 'Explore expressions and mappings across all languages', 'en', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.subtitle', 8772027985468400, '[]', '8772027985468400', 'active');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771966685762373, 'Languages', 'en', 'ui_i18n', 'langmap-web:languagesPage.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.title', 8771966685762373, '[]', '8771966685762373', 'active');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771952725719815, 'Anchor', 'en', 'ui_i18n', 'langmap-web:mapLens.anchor', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.anchor', 8771952725719815, '[]', '8771952725719815', 'active');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771984993053397, 'Back to mapping', 'en', 'ui_i18n', 'langmap-web:mapLens.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.back', 8771984993053397, '[]', '8771984993053397', 'active');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771995851022194, '{count} languages', 'en', 'ui_i18n', 'langmap-web:mapLens.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.languages', 8771995851022194, '[]', '8771995851022194', 'active');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936602672507, 'Unable to load', 'en', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.loadFailed', 8771936602672507, '[]', '8771936602672507', 'active');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771950928148051, 'Mapping members', 'en', 'ui_i18n', 'langmap-web:mapLens.members', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.members', 8771950928148051, '[]', '8771950928148051', 'active');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771989613412250, 'No geographic distribution data for this concept', 'en', 'ui_i18n', 'langmap-web:mapLens.noData', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.noData', 8771989613412250, '[]', '8771989613412250', 'active');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772012470644251, '{count} regions', 'en', 'ui_i18n', 'langmap-web:mapLens.regions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.regions', 8772012470644251, '[]', '8772012470644251', 'active');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771918829802721, 'Concept distribution', 'en', 'ui_i18n', 'langmap-web:mapLens.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.title', 8771918829802721, '[]', '8771918829802721', 'active');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771969898159421, 'Add and create mapping', 'en', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addAndMap', 8771969898159421, '[]', '8771969898159421', 'active');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772033519106127, 'Add expression', 'en', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addExpression', 8772033519106127, '[]', '8772033519106127', 'active');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771908944297462, 'Unable to add expression', 'en', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addFailed', 8771908944297462, '[]', '8771908944297462', 'active');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771928703559647, 'Adding…', 'en', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.adding', 8771928703559647, '[]', '8771928703559647', 'active');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772029059057248, 'Authority', 'en', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.authority', 8772029059057248, '[]', '8772029059057248', 'active');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001620797917, 'Breadcrumb', 'en', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.breadcrumb', 8772001620797917, '[]', '8772001620797917', 'active');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771978190877962, 'Close quick add', 'en', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.closeQuickAdd', 8771978190877962, '[]', '8771978190877962', 'active');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772005931944793, 'Contribute mapping', 'en', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.contribute', 8772005931944793, '[]', '8772005931944793', 'active');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771956479287686, 'direct mappings', 'en', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.direct', 8771956479287686, '[]', '8771956479287686', 'active');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771956618196526, 'Enter expression and language code', 'en', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.enterRequired', 8771956618196526, '[]', '8771956618196526', 'active');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772028411030279, 'Expression', 'en', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.expression', 8772028411030279, '[]', '8772028411030279', 'active');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771952819511586, 'Enter expression…', 'en', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.expressionPlaceholder', 8771952819511586, '[]', '8771952819511586', 'active');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771971766539087, 'Graph', 'en', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.graph', 8771971766539087, '[]', '8771971766539087', 'active');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771987694898855, 'Home', 'en', 'ui_i18n', 'langmap-web:mappingDetail.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.home', 8771987694898855, '[]', '8771987694898855', 'active');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771987564932373, 'hops', 'en', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.hops', 8771987564932373, '[]', '8771987564932373', 'active');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772028520330484, 'indirect', 'en', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.indirect', 8772028520330484, '[]', '8772028520330484', 'active');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771920539132885, 'Language code', 'en', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.languageCode', 8771920539132885, '[]', '8771920539132885', 'active');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772027619502019, 'e.g. en / cmn-Hant', 'en', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.languageCodePlaceholder', 8772027619502019, '[]', '8772027619502019', 'active');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771992537520761, 'List', 'en', 'ui_i18n', 'langmap-web:mappingDetail.list', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.list', 8771992537520761, '[]', '8771992537520761', 'active');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936602672507, 'Unable to load', 'en', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.loadFailed', 8771936602672507, '[]', '8771936602672507', 'active');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772011172535505, 'Mapping set', 'en', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.mappingSet', 8772011172535505, '[]', '8772011172535505', 'active');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772036040577861, 'No mappings yet', 'en', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.noMappings', 8772036040577861, '[]', '8772036040577861', 'active');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771986434294618, 'Optional', 'en', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.optional', 8771986434294618, '[]', '8771986434294618', 'active');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772035320845087, 'Quickly add expression', 'en', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.quickAdd', 8772035320845087, '[]', '8772035320845087', 'active');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771923205204397, 'Add an expression and map it directly to the current expression.', 'en', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.quickAddLead', 8771923205204397, '[]', '8771923205204397', 'active');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968624126325, 'Region', 'en', 'ui_i18n', 'langmap-web:mappingDetail.region', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.region', 8771968624126325, '[]', '8771968624126325', 'active');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772034803281550, 'User', 'en', 'ui_i18n', 'langmap-web:mappingDetail.user', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.user', 8772034803281550, '[]', '8772034803281550', 'active');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772021818623523, 'View this concept on map', 'en', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.viewMap', 8772021818623523, '[]', '8772021818623523', 'active');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772008345770010, 'Close menu', 'en', 'ui_i18n', 'langmap-web:nav.closeMenu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.closeMenu', 8772008345770010, '[]', '8772008345770010', 'active');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772022393103823, 'Contribute', 'en', 'ui_i18n', 'langmap-web:nav.contribute', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.contribute', 8772022393103823, '[]', '8772022393103823', 'active');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771945183617329, 'Handbooks', 'en', 'ui_i18n', 'langmap-web:nav.handbooks', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.handbooks', 8771945183617329, '[]', '8771945183617329', 'active');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771987694898855, 'Home', 'en', 'ui_i18n', 'langmap-web:nav.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.home', 8771987694898855, '[]', '8771987694898855', 'active');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771966685762373, 'Languages', 'en', 'ui_i18n', 'langmap-web:nav.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.languages', 8771966685762373, '[]', '8771966685762373', 'active');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771933905283078, 'Menu', 'en', 'ui_i18n', 'langmap-web:nav.menu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.menu', 8771933905283078, '[]', '8771933905283078', 'active');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771988489117883, 'Open menu', 'en', 'ui_i18n', 'langmap-web:nav.openMenu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.openMenu', 8771988489117883, '[]', '8771988489117883', 'active');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772000153561666, 'Search expressions', 'en', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.searchExpressions', 8772000153561666, '[]', '8772000153561666', 'active');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771985319534907, 'Sign in', 'en', 'ui_i18n', 'langmap-web:nav.signIn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.signIn', 8771985319534907, '[]', '8771985319534907', 'active');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771987956311474, 'Sign out', 'en', 'ui_i18n', 'langmap-web:nav.signOut', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.signOut', 8771987956311474, '[]', '8771987956311474', 'active');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772033727162136, 'Submit search', 'en', 'ui_i18n', 'langmap-web:nav.submitSearch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.submitSearch', 8772033727162136, '[]', '8772033727162136', 'active');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771905685377287, 'Switch interface language', 'en', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.switchLanguage', 8771905685377287, '[]', '8771905685377287', 'active');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772039352640020, 'Alphabetical', 'en', 'ui_i18n', 'langmap-web:search.alphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.alphabetical', 8772039352640020, '[]', '8772039352640020', 'active');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771909635790690, 'Tip: search currently matches expression text. Translation (semantic) search is coming later.', 'en', 'ui_i18n', 'langmap-web:search.hint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.hint', 8771909635790690, '[]', '8771909635790690', 'active');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771929026122151, 'Search failed', 'en', 'ui_i18n', 'langmap-web:search.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.loadFailed', 8771929026122151, '[]', '8771929026122151', 'active');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771912463566270, 'Latest', 'en', 'ui_i18n', 'langmap-web:search.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.newest', 8771912463566270, '[]', '8771912463566270', 'active');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771927555767000, 'No results found', 'en', 'ui_i18n', 'langmap-web:search.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.noResults', 8771927555767000, '[]', '8771927555767000', 'active');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771934172254861, 'Search expressions…', 'en', 'ui_i18n', 'langmap-web:search.placeholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.placeholder', 8771934172254861, '[]', '8771934172254861', 'active');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771957966582874, 'Popular', 'en', 'ui_i18n', 'langmap-web:search.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.popular', 8771957966582874, '[]', '8771957966582874', 'active');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772014433488480, '{count} result | {count} results', 'en', 'ui_i18n', 'langmap-web:search.results', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.results', 8772014433488480, '[]', '8772014433488480', 'active');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772001210440828, 'Sort', 'en', 'ui_i18n', 'langmap-web:search.sort', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.sort', 8772001210440828, '[]', '8772001210440828', 'active');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772000153561666, 'Search expressions', 'en', 'ui_i18n', 'langmap-web:search.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.title', 8772000153561666, '[]', '8772000153561666', 'active');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771973106595188, 'Add a language to translate', 'en', 'ui_i18n', 'langmap-web:translate.addLocale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.addLocale', 8771973106595188, '[]', '8771973106595188', 'active');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771943172288619, 'Submit {count} translations', 'en', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.batchSubmit', 8771943172288619, '[]', '8771943172288619', 'active');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771982470884397, 'Current translation', 'en', 'ui_i18n', 'langmap-web:translate.candidate', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.candidate', 8771982470884397, '[]', '8771982470884397', 'active');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772018182873778, 'Choose a registered language', 'en', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.chooseRegistryLanguage', 8772018182873778, '[]', '8772018182873778', 'active');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772013113555302, 'Translation coverage', 'en', 'ui_i18n', 'langmap-web:translate.coverage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.coverage', 8772013113555302, '[]', '8772013113555302', 'active');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772040929892299, '{count} shown', 'en', 'ui_i18n', 'langmap-web:translate.displayed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.displayed', 8772040929892299, '[]', '8772040929892299', 'active');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771973543137726, 'COMMUNITY LOCALIZATION', 'en', 'ui_i18n', 'langmap-web:translate.eyebrow', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.eyebrow', 8771973543137726, '[]', '8771973543137726', 'active');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771990724594742, 'Enter translation…', 'en', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.inputPlaceholder', 8771990724594742, '[]', '8771990724594742', 'active');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771920552784072, 'Unable to load translation workbench', 'en', 'ui_i18n', 'langmap-web:translate.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loadFailed', 8771920552784072, '[]', '8771920552784072', 'active');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771908386278726, 'Loading…', 'en', 'ui_i18n', 'langmap-web:translate.loading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loading', 8771908386278726, '[]', '8771908386278726', 'active');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771996866079300, 'Target language', 'en', 'ui_i18n', 'langmap-web:translate.locale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.locale', 8771996866079300, '[]', '8771996866079300', 'active');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771965827772292, 'Unable to load locale list', 'en', 'ui_i18n', 'langmap-web:translate.localesFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.localesFailed', 8771965827772292, '[]', '8771965827772292', 'active');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771995706904988, 'Sign in to submit translations; candidates are selected by mapping score and fallback is used when no positive candidate exists.', 'en', 'ui_i18n', 'langmap-web:translate.loginNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loginNote', 8771995706904988, '[]', '8771995706904988', 'active');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771904910396271, 'No matching copy found.', 'en', 'ui_i18n', 'langmap-web:translate.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.noResults', 8771904910396271, '[]', '8771904910396271', 'active');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771969689937165, 'Preview', 'en', 'ui_i18n', 'langmap-web:translate.preview', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.preview', 8771969689937165, '[]', '8771969689937165', 'active');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772009963987850, 'Reference language', 'en', 'ui_i18n', 'langmap-web:translate.reference', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.reference', 8772009963987850, '[]', '8772009963987850', 'active');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771962647026930, 'Search key or source text…', 'en', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.searchPlaceholder', 8771962647026930, '[]', '8771962647026930', 'active');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772037474898823, 'Choose translation language', 'en', 'ui_i18n', 'langmap-web:translate.selectLocale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.selectLocale', 8772037474898823, '[]', '8772037474898823', 'active');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772014752541923, 'EN source', 'en', 'ui_i18n', 'langmap-web:translate.source', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.source', 8772014752541923, '[]', '8772014752541923', 'active');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772036201600543, 'Start', 'en', 'ui_i18n', 'langmap-web:translate.start', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.start', 8772036201600543, '[]', '8772036201600543', 'active');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771930781451254, 'Submission failed', 'en', 'ui_i18n', 'langmap-web:translate.submitFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitFailed', 8771930781451254, '[]', '8771930781451254', 'active');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771938026129323, 'Submit mapping', 'en', 'ui_i18n', 'langmap-web:translate.submitMapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitMapping', 8771938026129323, '[]', '8771938026129323', 'active');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771906650908176, 'Submitted', 'en', 'ui_i18n', 'langmap-web:translate.submitted', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitted', 8771906650908176, '[]', '8771906650908176', 'active');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771968758684575, 'Help make LangMap interface text natural and useful.', 'en', 'ui_i18n', 'langmap-web:translate.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.subtitle', 8771968758684575, '[]', '8771968758684575', 'active');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8772002773137414, 'Translation workbench', 'en', 'ui_i18n', 'langmap-web:translate.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.title', 8772002773137414, '[]', '8772002773137414', 'active');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771936438281310, 'Translate {key}', 'en', 'ui_i18n', 'langmap-web:translate.translateKey', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translateKey', 8771936438281310, '[]', '8771936438281310', 'active');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771916786083827, 'translated', 'en', 'ui_i18n', 'langmap-web:translate.translated', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translated', 8771916786083827, '[]', '8771916786083827', 'active');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8771951513286657, 'Translation', 'en', 'ui_i18n', 'langmap-web:translate.translation', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translation', 8771951513286657, '[]', '8771951513286657', 'active');

-- 3. Translation expressions and edges (1228 rows)
-- Locale cmn-Hans
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621602037776514, '邮箱', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621602037776514-8771988929111883', 8771988929111883, 621602037776514, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621588717753951, '已有账号？', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621588717753951-8771987324928109', 8771987324928109, 621588717753951, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511971723699, '登录', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511971723699-8771985319534907', 8771985319534907, 621511971723699, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621582912905561, '还没有账号？', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621582912905561-8771920874847316', 8771920874847316, 621582912905561, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621600592853315, '操作失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621600592853315-8771934955742921', 8771934955742921, 621600592853315, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621500875124347, '密码', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621500875124347-8771993838728081', 8771993838728081, 621500875124347, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576153008690, '处理中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576153008690-8772001046060388', 8772001046060388, 621576153008690, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621564893522065, '创建账号', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621564893522065-8771964374844751', 8771964374844751, 621564893522065, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621601350518403, '用户名', 'cmn-Hans', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621601350518403-8772029311767367', 8772029311767367, 621601350518403, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621630088753162, '取消', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621630088753162-8772001703307290', 8772001703307290, 621630088753162, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621623071332858, '关闭', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621623071332858-8771958345505312', 8771958345505312, 621623071332858, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771930947571421', 8771930947571421, 621613822452950, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771966685762373', 8771966685762373, 621613822452950, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621618381563941, '加载中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621618381563941-8771908386278726', 8771908386278726, 621618381563941, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621537801676387, '搜索', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621537801676387-8772018337291447', 8772018337291447, 621537801676387, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621544933948613, '提交', 'cmn-Hans', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621544933948613-8771955384790296', 8771955384790296, 621544933948613, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621580400261048, '实际尺寸 100%', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621580400261048-8771913559728006', 8771913559728006, 621580400261048, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621555962172508, '匿名', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621555962172508-8771963881461252', 8771963881461252, 621555962172508, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621567799904066, '{count} 个子节点；点击收起', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621567799904066-8772032837909466', 8772032837909466, 621567799904066, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621622966141657, '每条边皆为可投票的独立直接映射；低分映射自动收起', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621622966141657-8772028933737015', 8772028933737015, 621622966141657, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621634782671351, '待建立的映射图谱', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621634782671351-8771990687804642', 8771990687804642, 621634782671351, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621584800732719, '关闭信息面板', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621584800732719-8771923580873788', 8771923580873788, 621584800732719, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621513324243028, '收起', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621513324243028-8772025115555117', 8772025115555117, 621513324243028, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621630929120155, '收起子分支', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621630929120155-8772021975712328', 8772021975712328, 621630929120155, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621621321102465, '收起至第一层', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621621321102465-8771963062101045', 8771963062101045, 621621321102465, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621564285445652, '{count} 天前', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621564285445652-8772016085305408', 8772016085305408, 621564285445652, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621623974669976, '深度 {depth}', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621623974669976-8772018587383663', 8772018587383663, 621623974669976, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621600065598840, '直接映射词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621600065598840-8771921679343522', 8771921679343522, 621600065598840, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621544921188987, '踩', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621544921188987-8771992127181974', 8771992127181974, 621544921188987, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511208977190, '{count} 条边', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511208977190-8771907018302878', 8771907018302878, 621511208977190, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621537847190824, '暂无数据', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621537847190824-8772000424294921', 8772000424294921, 621537847190824, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621596351420434, '退出全屏', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621596351420434-8771995527490116', 8771995527490116, 621596351420434, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621503220470884, '展开', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621503220470884-8771957005515059', 8771957005515059, 621503220470884, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621581024840276, '全部展开', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621581024840276-8772033758268399', 8772033758268399, 621581024840276, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621527223363526, '展开子分支', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621527223363526-8771937729949713', 8771937729949713, 621527223363526, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621612481725569, '词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621612481725569-8772028411030279', 8772028411030279, 621612481725569, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621536054208970, '筛选语言…', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621536054208970-8771975185705787', 8771975185705787, 621536054208970, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533307295537, '全屏', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533307295537-8771984311379866', 8771984311379866, 621533307295537, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621582580373210, '词句映射图谱', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621582580373210-8771940176065576', 8771940176065576, 621582580373210, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621578722652638, '加载图谱…', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621578722652638-8771930916265390', 8771930916265390, 621578722652638, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621608390065632, '图谱模式', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621608390065632-8772018055755937', 8772018055755937, 621608390065632, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621507349296248, '{nodes} 个映射节点 · {edges} 个关系', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621507349296248-8771930566920504', 8771930566920504, 621507349296248, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621601285198757, '图谱工具栏', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621601285198757-8771957995007293', 8771957995007293, 621601285198757, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621522125496685, '映射层级列表', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621522125496685-8771972530005685', 8771972530005685, 621522125496685, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621520182221799, '跳数', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621520182221799-8771929108158859', 8771929108158859, 621520182221799, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621587847460750, '{count} 小时前', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621587847460750-8771972038859703', 8771972038859703, 621587847460750, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621609089353120, '刚刚', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621609089353120-8772006156641051', 8772006156641051, 621609089353120, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621629400448738, '无法加载语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621629400448738-8771907230355366', 8771907230355366, 621629400448738, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621570411930378, '列表模式', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621570411930378-8771978209325624', 8771978209325624, 621570411930378, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621567432943506, '加载更多', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621567432943506-8771968298248581', 8771968298248581, 621567432943506, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621602043741562, '加载相关词句中', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621602043741562-8771918922470710', 8771918922470710, 621602043741562, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621535475963735, '映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621535475963735-8772009894682686', 8772009894682686, 621535475963735, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621634660667764, '映射评分', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621634660667764-8772001613332908', 8772001613332908, 621634660667764, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621507479968431, '{count} 分钟前', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621507479968431-8772029891163450', 8772029891163450, 621507479968431, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621560252478476, '更多操作', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621560252478476-8771927265880728', 8771927265880728, 621560252478476, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533707436794, '完整图谱中还有 {count} 个映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533707436794-8771978296601845', 8771978296601845, 621533707436794, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621510549860914, '暂无直接映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621510549860914-8771916846886490', 8771916846886490, 621510549860914, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621520700942960, '找不到相符词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621520700942960-8771950851535873', 8771950851535873, 621520700942960, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621532523991675, '{count} 个节点', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621532523991675-8771915754603204', 8771915754603204, 621532523991675, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621617277420487, '节点信息', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621617277420487-8772032217763299', 8772032217763299, 621617277420487, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621599699207504, '其他关系', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621599699207504-8772011775552074', 8772011775552074, 621599699207504, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621505218461957, '相关词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621505218461957-8771996275317129', 8771996275317129, 621505218461957, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621630982829395, '{count} 个关系', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621630982829395-8771905570354775', 8771905570354775, 621630982829395, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621506696643103, '移除 {code}', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621506696643103-8771968148353493', 8771968148353493, 621506696643103, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576612987454, '重置布局', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576612987454-8771923590138278', 8771923590138278, 621576612987454, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621519137673835, '根节点', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621519137673835-8771991096471187', 8771991096471187, 621519137673835, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621537801676387, '搜索', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621537801676387-8772018337291447', 8772018337291447, 621537801676387, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530915401975, '搜索词句…', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530915401975-8771934172254861', 8771934172254861, 621530915401975, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621631605374857, '搜索中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621631605374857-8771951969125148', 8771951969125148, 621631605374857, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621569508430592, '在图谱中选取节点以查看详情', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621569508430592-8771969317410200', 8771969317410200, 621569508430592, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621513685690927, '来源路径', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621513685690927-8771977750841844', 8771977750841844, 621513685690927, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621599567970844, '赞', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621599567970844-8772016238570208', 8772016238570208, 621599567970844, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621605730741159, '查看词句详情', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621605730741159-8771995720429284', 8771995720429284, 621605730741159, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533859833551, '投票失败，已撤销', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533859833551-8772020751025198', 8772020751025198, 621533859833551, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621566125227538, '放大', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621566125227538-8772017398603959', 8772017398603959, 621566125227538, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511938033885, '缩小', 'cmn-Hans', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511938033885-8772017289371875', 8772017289371875, 621511938033885, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621519087775625, '+ 添加词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621519087775625-8771945073983212', 8771945073983212, 621519087775625, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621577366296527, '完全图', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621577366296527-8771921254303111', 8771921254303111, 621577366296527, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621509861484180, '删除', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621509861484180-8771944300238713', 8771944300238713, 621509861484180, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621599559343081, '{count} 个直接映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621599559343081-8771968945113345', 8771968945113345, 621599559343081, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621612481725569, '词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621612481725569-8772028411030279', 8772028411030279, 621612481725569, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621564047422899, '{count} 个词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621564047422899-8771918589046163', 8771918589046163, 621564047422899, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621633142288382, '输入词句…', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621633142288382-8771975160452098', 8771975160452098, 621633142288382, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771930947571421', 8771930947571421, 621613822452950, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621619646963854, '提交一组含义相同的词句。系统会在每对之间创建直接映射。已有词句会自动关联，不会产生重复。', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621619646963854-8771938370927027', 8771938370927027, 621619646963854, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621594673122420, '至少需要 2 行，每行需填写语言和词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621594673122420-8771996574983759', 8771996574983759, 621594673122420, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621544933948613, '提交', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621544933948613-8771955384790296', 8771955384790296, 621544933948613, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621508494350823, '提交失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621508494350823-8771930781451254', 8771930781451254, 621508494350823, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621501868375740, '提交中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621501868375740-8771996654725718', 8771996654725718, 621501868375740, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621607199838131, '标签', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621607199838131-8772023049338365', 8772023049338365, 621607199838131, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621598682446444, '批量提交', 'cmn-Hans', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621598682446444-8771967116778370', 8771967116778370, 621598682446444, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621610106546987, '返回首页', 'cmn-Hans', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621610106546987-8771954914944651', 8771954914944651, 621610106546987, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502704994870, '无法加载', 'cmn-Hans', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502704994870-8771936602672507', 8771936602672507, 621502704994870, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621522894116235, '页面未找到', 'cmn-Hans', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621522894116235-8771958158698832', 8771958158698832, 621522894116235, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621607270890617, '全部', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621607270890617-8771912696777795', 8771912696777795, 621607270890617, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621628730870910, '提交映射 →', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621628730870910-8771952067596101', 8771952067596101, 621628730870910, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511407101153, '热门', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511407101153-8771957966582874', 8771957966582874, 621511407101153, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621551546598953, '映射 + 新词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621551546598953-8771971172552785', 8771971172552785, 621551546598953, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621569107941743, '找不到所需内容？', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621569107941743-8771964553678580', 8771964553678580, 621569107941743, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621520570466129, '新贡献', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621520570466129-8772013263074963', 8772013263074963, 621520570466129, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621518282475489, '最新', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621518282475489-8771912463566270', 8771912463566270, 621518282475489, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621609912316706, '热门映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621609912316706-8771956320455891', 8771956320455891, 621609912316706, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621566209833903, '按评分 · 本周', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621566209833903-8772001941683119', 8772001941683119, 621566209833903, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621575665413182, '语义图的最新脉动——热门映射和新贡献。', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621575665413182-8771985464043467', 8771985464043467, 621575665413182, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621523265720136, '动态', 'cmn-Hans', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621523265720136-8771928668652497', 8771928668652497, 621523265720136, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621632915135294, '新增词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621632915135294-8772033519106127', 8772033519106127, 621632915135294, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621555487350935, '新增章节', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621555487350935-8772013343930223', 8772013343930223, 621555487350935, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621616486518241, '手册列表', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621616486518241-8771985524903836', 8771985524903836, 621616486518241, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621636224007189, '第 {number} 章', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621636224007189-8771974942670538', 8771974942670538, 621636224007189, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621565811109597, '关闭词句信息', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621565811109597-8771948835977551', 8771948835977551, 621565811109597, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621513324243028, '收起', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621513324243028-8772025115555117', 8772025115555117, 621513324243028, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621503370077885, '删除章节', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621503370077885-8771922363562335', 8771922363562335, 621503370077885, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621606674831318, '编辑手册', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621606674831318-8771954520730023', 8771954520730023, 621606674831318, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621504524872083, '词句信息', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621504524872083-8771958749403912', 8771958749403912, 621504524872083, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576314999481, '词句的语言、地区和来源将显示在此处。', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576314999481-8771969048222271', 8771969048222271, 621576314999481, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621590525964635, '这本手册有帮助吗？', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621590525964635-8771919030282571', 8771919030282571, 621590525964635, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621545702423393, '无法加载词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621545702423393-8772001956145712', 8772001956145712, 621545702423393, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502704994870, '无法加载', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502704994870-8771936602672507', 8771936602672507, 621502704994870, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771930947571421', 8771930947571421, 621613822452950, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621560751851138, '下移', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621560751851138-8772015839426216', 8772015839426216, 621560751851138, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621552835744717, '下移章节', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621552835744717-8771974741123489', 8771974741123489, 621552835744717, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621592971280231, '上移章节', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621592971280231-8771974343227837', 8771974343227837, 621592971280231, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621546624693751, '上移', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621546624693751-8772035822327586', 8772035822327586, 621546624693751, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621592251543860, '私密', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621592251543860-8771981388316157', 8771981388316157, 621592251543860, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621571197525036, '公开', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621571197525036-8771978356150928', 8771978356150928, 621571197525036, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621617451571475, '发布', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621617451571475-8771952311782197', 8771952311782197, 621617451571475, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621578251195832, '地区', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621578251195832-8771968624126325', 8771968624126325, 621578251195832, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621563026652984, '无法加载相关词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621563026652984-8771991960796854', 8771991960796854, 621563026652984, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621545593416436, '移除 {text}', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621545593416436-8771948377233166', 8771948377233166, 621545593416436, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621571708259605, '保存草稿', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621571708259605-8771974360984879', 8771974360984879, 621571708259605, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621617735345921, '保存中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621617735345921-8771980391249065', 8771980391249065, 621617735345921, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621604035135598, '章节标题', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621604035135598-8771935521942479', 8771935521942479, 621604035135598, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621547952412765, '选择词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621547952412765-8771975315975664', 8771975315975664, 621547952412765, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621625362897376, '来源', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621625362897376-8771933750484319', 8771933750484319, 621625362897376, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621549970259583, 'AI', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621549970259583-8771954789056127', 8771954789056127, 621549970259583, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621548230292240, '权威', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621548230292240-8772029059057248', 8772029059057248, 621548230292240, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621527738542412, '用户', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621527738542412-8772034803281550', 8772034803281550, 621527738542412, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621623851179498, '手册标题', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621623851179498-8771918701696347', 8771918701696347, 621623851179498, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621630997387962, '目录', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621630997387962-8771915172364840', 8771915172364840, 621630997387962, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621589661783895, '查看完整关系图', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621589661783895-8771928949232797', 8771928949232797, 621589661783895, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621527075878206, '可见性', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621527075878206-8772029984927123', 8772029984927123, 621527075878206, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621507515155907, '新建手册', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621507515155907-8771984354571011', 8771984354571011, 621507515155907, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621519839327005, '加载手册失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621519839327005-8771915400044673', 8771915400044673, 621519839327005, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621518282475489, '最新', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621518282475489-8771912463566270', 8771912463566270, 621518282475489, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621510183019398, '未找到手册', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621510183019398-8772007530341875', 8772007530341875, 621510183019398, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511407101153, '热门', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511407101153-8771957966582874', 8771957966582874, 621511407101153, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621562913920985, '搜索手册…', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621562913920985-8772031472567985', 8772031472567985, 621562913920985, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621571539946589, '章节', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621571539946589-8771981869623564', 8771981869623564, 621571539946589, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621626021115777, '手册', 'cmn-Hans', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621626021115777-8771945183617329', 8771945183617329, 621626021115777, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621619551581079, '上一步', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621619551581079-8772024038803789', 8772024038803789, 621619551581079, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621630088753162, '取消', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621630088753162-8772001703307290', 8772001703307290, 621630088753162, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621623071332858, '关闭', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621623071332858-8771958345505312', 8771958345505312, 621623071332858, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621557237350474, '创建语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621557237350474-8771972155504688', 8771972155504688, 621557237350474, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533630586836, '语言创建失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533630586836-8772008975730714', 8772008975730714, 621533630586836, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621563655158386, '创建中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621563655158386-8771943301451236', 8771943301451236, 621563655158386, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621539436319835, '请输入描述', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621539436319835-8771986788835322', 8771986788835322, 621539436319835, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621570986400428, '请选择 Glottolog 匹配或选择「无匹配」', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621570986400428-8771982145239141', 8771982145239141, 621570986400428, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621541708454338, '请输入语言名称', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621541708454338-8771921060819264', 8771921060819264, 621541708454338, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621503593024592, '请选择仅限社区创建的原因', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621503593024592-8771926836463632', 8771926836463632, 621503593024592, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621524806904742, '请输入语言子标签以继续', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621524806904742-8772026576042326', 8772026576042326, 621524806904742, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511982898336, '找到 {count} 个候选', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511982898336-8771956461019812', 8771956461019812, 621511982898336, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621607370165678, '选择匹配或标明无合适条目', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621607370165678-8772033726980358', 8772033726980358, 621607370165678, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621510628568465, '匹配此候选', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621510628568465-8772036217067472', 8772036217067472, 621510628568465, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621539405295908, '方言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621539405295908-8771959645210043', 8771959645210043, 621539405295908, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771953851734414', 8771953851734414, 621613822452950, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621536814724037, 'Glottolog 无合适条目', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621536814724037-8771907658003091', 8771907658003091, 621536814724037, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621591829811359, '搜索 Glottolog…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621591829811359-8771972676692740', 8771972676692740, 621591829811359, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533363709574, '描述', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533363709574-8771937301075282', 8771937301075282, 621533363709574, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621536049013188, '描述此语言或变体…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621536049013188-8771929062150956', 8771929062150956, 621536049013188, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621624606083157, '名称', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621624606083157-8771913536651859', 8771913536651859, 621624606083157, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511464036343, '英文名称', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511464036343-8772035648862723', 8772035648862723, 621511464036343, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621549895529942, '为何此语言未收录于 Glottolog？', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621549895529942-8771965397553798', 8771965397553798, 621549895529942, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621532294924709, '社区特定用法', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621532294924709-8772029121364869', 8772029121364869, 621532294924709, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621625979488773, '新兴变体', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621625979488773-8771911763851130', 8771911763851130, 621625979488773, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621573768784259, 'Glottolog 未收录', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621573768784259-8772027448793331', 8772027448793331, 621573768784259, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621594753650058, '其他', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621594753650058-8771907717721822', 8771907717721822, 621594753650058, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621553154318529, '选择原因…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621553154318529-8771908744199257', 8771908744199257, 621553154318529, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621587727960659, '下一步', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621587727960659-8771946058185965', 8771946058185965, 621587727960659, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613167090520, '规范代码', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613167090520-8771986283559204', 8771986283559204, 621613167090520, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621510719810863, '此语言已存在', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621510719810863-8771963047592058', 8771963047592058, 621510719810863, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621521147714649, '使用现有语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621521147714649-8771911987565882', 8771911987565882, 621521147714649, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621557237350474, '创建语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621557237350474-8771972155504688', 8771972155504688, 621557237350474, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621533463407021, '警告', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621533463407021-8771976682274382', 8771976682274382, 621533463407021, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530919991439, '临时标签', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530919991439-8771969301691665', 8771969301691665, 621530919991439, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621545172021295, 'Glottolog 匹配', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621545172021295-8771926452848847', 8771926452848847, 621545172021295, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621609040326093, '元数据', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621609040326093-8771988865126091', 8771988865126091, 621609040326093, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621517519496288, '预览并创建', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621517519496288-8772002442315415', 8772002442315415, 621517519496288, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621624131855771, '语言标签', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621624131855771-8771982332401463', 8771982332401463, 621624131855771, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771930947571421', 8771930947571421, 621613822452950, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621578251195832, '地区', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621578251195832-8771968624126325', 8771968624126325, 621578251195832, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621597452286074, '文字', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621597452286074-8771976361115614', 8771976361115614, 621597452286074, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621512824307161, '搜索子标签…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621512824307161-8772015391400398', 8772015391400398, 621512824307161, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621627512961534, '变体', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621627512961534-8771923711808765', 8771923711808765, 621627512961534, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621541359767956, '已移除 1 个变体', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621541359767956-8772011217159086', 8772011217159086, 621541359767956, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621526864460743, '已移除 {count} 个变体', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621526864460743-8771998528580369', 8771998528580369, 621526864460743, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621519610903643, '按字母排序', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621519610903643-8772039352640020', 8772039352640020, 621519610903643, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771966685762373', 8771966685762373, 621613822452950, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621612481725569, '词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621612481725569-8772004481370898', 8772004481370898, 621612481725569, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621518282475489, '最新', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621518282475489-8771912463566270', 8771912463566270, 621518282475489, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502704994870, '无法加载', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502704994870-8771936602672507', 8771936602672507, 621502704994870, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621573120557033, '已映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621573120557033-8771947211108180', 8771947211108180, 621573120557033, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621592521672516, '没有找到词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621592521672516-8771950851535873', 8771950851535873, 621592521672516, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511407101153, '热门', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511407101153-8771957966582874', 8771957966582874, 621511407101153, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530915401975, '搜索词句…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530915401975-8771934172254861', 8771934172254861, 621530915401975, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621625783501312, '清除选择', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621625783501312-8771904155296746', 8771904155296746, 621625783501312, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621543671445625, '创建新语言或变体', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621543671445625-8772010209718094', 8772010209718094, 621543671445625, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621634912041438, '无匹配语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621634912041438-8771905467432581', 8771905467432581, 621634912041438, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621525022824768, '搜索语言…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621525022824768-8771957308068965', 8771957308068965, 621525022824768, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621504840632262, '浏览器推荐', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621504840632262-8771943861429001', 8771943861429001, 621504840632262, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621606607567839, '协助翻译 LangMap', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621606607567839-8771962203854555', 8771962203854555, 621606607567839, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621581895141561, '无匹配的语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621581895141561-8771905467432581', 8771905467432581, 621581895141561, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621593214561614, '最近使用的语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621593214561614-8772017158300851', 8772017158300851, 621593214561614, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621612481725569, '词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621612481725569-8772004481370898', 8772004481370898, 621612481725569, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771966685762373', 8771966685762373, 621613822452950, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621629400448738, '无法加载语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621629400448738-8771907230355366', 8771907230355366, 621629400448738, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621597226980466, '未找到语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621597226980466-8772015486738705', 8772015486738705, 621597226980466, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621525022824768, '搜索语言…', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621525022824768-8771957308068965', 8771957308068965, 621525022824768, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621568581479692, 'A–Z', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621568581479692-8771973400276236', 8771973400276236, 621568581479692, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621549917554714, '按数量', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621549917554714-8771994726877247', 8771994726877247, 621549917554714, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621598805636397, '浏览所有语言的词句与映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621598805636397-8772027985468400', 8772027985468400, 621598805636397, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771966685762373', 8771966685762373, 621613822452950, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621607061501187, '锚点', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621607061501187-8771952725719815', 8771952725719815, 621607061501187, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621520481522538, '返回映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621520481522538-8771984993053397', 8771984993053397, 621520481522538, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621540209040212, '{count} 种语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621540209040212-8771995851022194', 8771995851022194, 621540209040212, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502704994870, '无法加载', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502704994870-8771936602672507', 8771936602672507, 621502704994870, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621528044032034, '映射成员', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621528044032034-8771950928148051', 8771950928148051, 621528044032034, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621584123999187, '此概念无地理分布数据', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621584123999187-8771989613412250', 8771989613412250, 621584123999187, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621568117521580, '{count} 个地区', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621568117521580-8772012470644251', 8772012470644251, 621568117521580, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621549841102126, '概念分布', 'cmn-Hans', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621549841102126-8771918829802721', 8771918829802721, 621549841102126, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621625707935597, '新增并建立映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621625707935597-8771969898159421', 8771969898159421, 621625707935597, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621632915135294, '新增词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621632915135294-8772033519106127', 8772033519106127, 621632915135294, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621524749180428, '无法新增词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621524749180428-8771908944297462', 8771908944297462, 621524749180428, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621565503156952, '新增中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621565503156952-8771928703559647', 8771928703559647, 621565503156952, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621548230292240, '权威', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621548230292240-8772029059057248', 8772029059057248, 621548230292240, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621629949445493, '面包屑', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621629949445493-8772001620797917', 8772001620797917, 621629949445493, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621594727964390, '关闭快速新增', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621594727964390-8771978190877962', 8771978190877962, 621594727964390, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621568892281069, '贡献映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621568892281069-8772005931944793', 8772005931944793, 621568892281069, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621532655956794, '直接映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621532655956794-8771956479287686', 8771956479287686, 621532655956794, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621625331682982, '请输入词句与语言代码', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621625331682982-8771956618196526', 8771956618196526, 621625331682982, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621612481725569, '词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621612481725569-8772028411030279', 8772028411030279, 621612481725569, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621633142288382, '输入词句…', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621633142288382-8771952819511586', 8771952819511586, 621633142288382, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621538507341460, '图谱', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621538507341460-8771971766539087', 8771971766539087, 621538507341460, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502526170045, '首页', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502526170045-8771987694898855', 8771987694898855, 621502526170045, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621520182221799, '跳数', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621520182221799-8771987564932373', 8771987564932373, 621520182221799, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621526813032897, '间接', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621526813032897-8772028520330484', 8772028520330484, 621526813032897, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621505462898990, '语言代码', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621505462898990-8771920539132885', 8771920539132885, 621505462898990, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621632349108903, '例如 en / cmn-Hant', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621632349108903-8772027619502019', 8772027619502019, 621632349108903, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621589226011821, '列表', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621589226011821-8771992537520761', 8771992537520761, 621589226011821, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502704994870, '无法加载', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502704994870-8771936602672507', 8771936602672507, 621502704994870, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621556916566624, '映射集合', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621556916566624-8772011172535505', 8772011172535505, 621556916566624, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576283673894, '尚无映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576283673894-8772036040577861', 8772036040577861, 621576283673894, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621566123078497, '选填', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621566123078497-8771986434294618', 8771986434294618, 621566123078497, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621536771157934, '快速新增词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621536771157934-8772035320845087', 8772035320845087, 621536771157934, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621548981540858, '新增词句并直接映射到当前词句。', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621548981540858-8771923205204397', 8771923205204397, 621548981540858, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621578251195832, '地区', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621578251195832-8771968624126325', 8771968624126325, 621578251195832, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621527738542412, '用户', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621527738542412-8772034803281550', 8772034803281550, 621527738542412, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621603370109430, '在地图上查看此概念', 'cmn-Hans', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621603370109430-8772021818623523', 8772021818623523, 621603370109430, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621528148699345, '关闭菜单', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621528148699345-8772008345770010', 8772008345770010, 621528148699345, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621618171568542, '贡献', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621618171568542-8772022393103823', 8772022393103823, 621618171568542, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621626021115777, '手册', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621626021115777-8771945183617329', 8771945183617329, 621626021115777, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621502526170045, '首页', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621502526170045-8771987694898855', 8771987694898855, 621502526170045, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621613822452950, '语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621613822452950-8771966685762373', 8771966685762373, 621613822452950, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621627037268184, '菜单', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621627037268184-8771933905283078', 8771933905283078, 621627037268184, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621505570042922, '打开菜单', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621505570042922-8771988489117883', 8771988489117883, 621505570042922, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576399979931, '搜索词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576399979931-8772000153561666', 8772000153561666, 621576399979931, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511971723699, '登录', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511971723699-8771985319534907', 8771985319534907, 621511971723699, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621591649386941, '退出登录', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621591649386941-8771987956311474', 8771987956311474, 621591649386941, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621634654736746, '提交搜索', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621634654736746-8772033727162136', 8772033727162136, 621634654736746, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621582680139112, '切换界面语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621582680139112-8771905685377287', 8771905685377287, 621582680139112, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621531604322002, '按字母顺序', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621531604322002-8772039352640020', 8772039352640020, 621531604322002, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621563927893510, '提示：目前搜索匹配词句原文。翻译（语义）搜索即将推出。', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621563927893510-8771909635790690', 8771909635790690, 621563927893510, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621560112384357, '搜索失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621560112384357-8771929026122151', 8771929026122151, 621560112384357, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621518282475489, '最新', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621518282475489-8771912463566270', 8771912463566270, 621518282475489, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621609616348658, '未找到结果', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621609616348658-8771927555767000', 8771927555767000, 621609616348658, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530915401975, '搜索词句…', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530915401975-8771934172254861', 8771934172254861, 621530915401975, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621511407101153, '热门', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621511407101153-8771957966582874', 8771957966582874, 621511407101153, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621561441430227, '{count} 个结果', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621561441430227-8772014433488480', 8772014433488480, 621561441430227, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621521611254818, '排序', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621521611254818-8772001210440828', 8772001210440828, 621521611254818, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621576399979931, '搜索词句', 'cmn-Hans', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621576399979931-8772000153561666', 8772000153561666, 621576399979931, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621614981680878, '添加要翻译的语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621614981680878-8771973106595188', 8771973106595188, 621614981680878, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621573098876711, '提交 {count} 条翻译', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621573098876711-8771943172288619', 8771943172288619, 621573098876711, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621574346025447, '当前翻译', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621574346025447-8771982470884397', 8771982470884397, 621574346025447, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621518127654735, '选择已注册的语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621518127654735-8772018182873778', 8772018182873778, 621518127654735, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530911084888, '翻译覆盖率', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530911084888-8772013113555302', 8772013113555302, 621530911084888, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621618861918186, '显示 {count} 条', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621618861918186-8772040929892299', 8772040929892299, 621618861918186, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621549597150469, '社区本地化', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621549597150469-8771973543137726', 8771973543137726, 621549597150469, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621550113486379, '输入翻译…', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621550113486379-8771990724594742', 8771990724594742, 621550113486379, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621574232350044, '无法加载翻译工作台', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621574232350044-8771920552784072', 8771920552784072, 621574232350044, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621618381563941, '加载中…', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621618381563941-8771908386278726', 8771908386278726, 621618381563941, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621534643306437, '目标语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621534643306437-8771996866079300', 8771996866079300, 621534643306437, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621584110117464, '无法加载语言列表', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621584110117464-8771965827772292', 8771965827772292, 621584110117464, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621589006719824, '登录后可提交翻译；候选翻译按映射分数排序，无正分候选时使用回退文本。', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621589006719824-8771995706904988', 8771995706904988, 621589006719824, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621558173453572, '未找到匹配文本。', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621558173453572-8771904910396271', 8771904910396271, 621558173453572, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621544576776709, '预览', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621544576776709-8771969689937165', 8771969689937165, 621544576776709, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621620093667024, '参考语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621620093667024-8772009963987850', 8772009963987850, 621620093667024, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621606948519729, '搜索键名或原文…', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621606948519729-8771962647026930', 8771962647026930, 621606948519729, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621614000243725, '选择翻译语言', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621614000243725-8772037474898823', 8772037474898823, 621614000243725, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621634918836773, '英文原文', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621634918836773-8772014752541923', 8772014752541923, 621634918836773, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621611504344099, '开始', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621611504344099-8772036201600543', 8772036201600543, 621611504344099, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621508494350823, '提交失败', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621508494350823-8771930781451254', 8771930781451254, 621508494350823, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621623982082968, '提交映射', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621623982082968-8771938026129323', 8771938026129323, 621623982082968, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621572228974192, '已提交', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621572228974192-8771906650908176', 8771906650908176, 621572228974192, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621595287369138, '帮助让 LangMap 界面文本更自然、更实用。', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621595287369138-8771968758684575', 8771968758684575, 621595287369138, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621591322906198, '翻译工作台', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621591322906198-8772002773137414', 8772002773137414, 621591322906198, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621530803549974, '翻译 {key}', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621530803549974-8771936438281310', 8771936438281310, 621530803549974, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621565207174795, '已翻译', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621565207174795-8771916786083827', 8771916786083827, 621565207174795, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (621582006304906, '翻译', 'cmn-Hans', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('621582006304906-8771951513286657', 8771951513286657, 621582006304906, 0, 'ui_i18n');

-- Locale cmn-Hant
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007614343702804, '電子郵件', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007614343702804-8771988929111883', 8771988929111883, 5007614343702804, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007621479566354, '已經有帳號了？', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007621479566354-8771987324928109', 8771987324928109, 5007621479566354, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639590295621, '登入', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639590295621-8771985319534907', 8771985319534907, 5007639590295621, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627704026606, '還沒有帳號？', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627704026606-8771920874847316', 8771920874847316, 5007627704026606, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007614423188991, '操作失敗', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007614423188991-8771934955742921', 8771934955742921, 5007614423188991, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612220362916, '密碼', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612220362916-8771993838728081', 8771993838728081, 5007612220362916, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007725611799844, '處理中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007725611799844-8772001046060388', 8772001046060388, 5007725611799844, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007671207548191, '建立帳號', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007671207548191-8771964374844751', 8771964374844751, 5007671207548191, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007680446645128, '使用者名稱', 'cmn-Hant', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007680446645128-8772029311767367', 8772029311767367, 5007680446645128, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719410905098, '取消', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719410905098-8772001703307290', 8772001703307290, 5007719410905098, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007689820830527, '關閉', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007689820830527-8771958345505312', 8771958345505312, 5007689820830527, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771930947571421', 8771930947571421, 5007686050335421, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771966685762373', 8771966685762373, 5007686050335421, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007714792299881, '載入中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007714792299881-8771908386278726', 8771908386278726, 5007714792299881, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616919201563, '搜尋', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616919201563-8772018337291447', 8772018337291447, 5007616919201563, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007634256100549, '提交', 'cmn-Hant', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007634256100549-8771955384790296', 8771955384790296, 5007634256100549, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007664079797464, '實際尺寸 100%', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007664079797464-8771913559728006', 8771913559728006, 5007664079797464, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007645284324444, '匿名', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007645284324444-8771963881461252', 8771963881461252, 5007645284324444, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007702581978885, '{count} 個子節點；點選收合', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007702581978885-8772032837909466', 8772032837909466, 5007702581978885, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719877543988, '每條邊皆為可投票的獨立直接對應；低分對應自動收合', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719877543988-8772028933737015', 8772028933737015, 5007719877543988, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007704173494076, '待建立的對應圖譜', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007704173494076-8771990687804642', 8771990687804642, 5007704173494076, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007689431702074, '關閉資訊面板', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007689431702074-8771923580873788', 8771923580873788, 5007689431702074, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007699956620865, '收合', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007699956620865-8772025115555117', 8772025115555117, 5007699956620865, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007645015767181, '收合子分支', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007645015767181-8772021975712328', 8772021975712328, 5007645015767181, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007595961233188, '收合至第一層', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007595961233188-8771963062101045', 8771963062101045, 5007595961233188, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007653607597588, '{count} 天前', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007653607597588-8772016085305408', 8772016085305408, 5007653607597588, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007713296821912, '深度 {depth}', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007713296821912-8772018587383663', 8772018587383663, 5007713296821912, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007632499803129, '直接對應詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007632499803129-8771921679343522', 8771921679343522, 5007632499803129, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007676302773923, '倒讚', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007676302773923-8771992127181974', 8771992127181974, 5007676302773923, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007610872283909, '{count} 條邊', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007610872283909-8771907018302878', 8771907018302878, 5007610872283909, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007718158178684, '目前沒有資料', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007718158178684-8772000424294921', 8772000424294921, 5007718158178684, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007630277892706, '退出全螢幕', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007630277892706-8771995527490116', 8771995527490116, 5007630277892706, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007605443475820, '展開', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007605443475820-8771957005515059', 8771957005515059, 5007605443475820, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007614402616386, '全部展開', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007614402616386-8772033758268399', 8772033758268399, 5007614402616386, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007666498461092, '展開子分支', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007666498461092-8771937729949713', 8771937729949713, 5007666498461092, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677367822286, '詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677367822286-8772028411030279', 8772028411030279, 5007677367822286, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007619045608811, '篩選語言…', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007619045608811-8771975185705787', 8771975185705787, 5007619045608811, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007615648193963, '全螢幕', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007615648193963-8771984311379866', 8771984311379866, 5007615648193963, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007593929819522, '詞句對應圖譜', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007593929819522-8771940176065576', 8771940176065576, 5007593929819522, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007648501514002, '載入圖譜…', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007648501514002-8771930916265390', 8771930916265390, 5007648501514002, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007653399408528, '圖譜模式', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007653399408528-8772018055755937', 8772018055755937, 5007653399408528, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007673908076374, '{nodes} 個對應節點 · {edges} 個關係', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007673908076374-8771930566920504', 8771930566920504, 5007673908076374, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007594593238964, '圖譜工具列', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007594593238964-8771957995007293', 8771957995007293, 5007594593238964, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007692426337371, '對應階層列表', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007692426337371-8771972530005685', 8771972530005685, 5007692426337371, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007642787446540, '跳數', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007642787446540-8771929108158859', 8771929108158859, 5007642787446540, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007721636959323, '{count} 小時前', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007721636959323-8771972038859703', 8771972038859703, 5007721636959323, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007646716314926, '剛剛', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007646716314926-8772006156641051', 8772006156641051, 5007646716314926, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007697617594999, '無法載入語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007697617594999-8771907230355366', 8771907230355366, 5007697617594999, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007659734082314, '列表模式', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007659734082314-8771978209325624', 8771978209325624, 5007659734082314, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007685178542888, '載入更多', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007685178542888-8771968298248581', 8771968298248581, 5007685178542888, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007716284963225, '載入相關詞句中', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007716284963225-8771918922470710', 8771918922470710, 5007716284963225, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007716733049626, '對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007716733049626-8772009894682686', 8772009894682686, 5007716733049626, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612653383173, '對應評分', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612653383173-8772001613332908', 8772001613332908, 5007612653383173, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007678902177409, '{count} 分鐘前', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007678902177409-8772029891163450', 8772029891163450, 5007678902177409, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007649574630412, '更多操作', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007649574630412-8771927265880728', 8771927265880728, 5007649574630412, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007703636047370, '完整圖譜中還有 {count} 個對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007703636047370-8771978296601845', 8771978296601845, 5007703636047370, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007704561508622, '尚無直接對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007704561508622-8771916846886490', 8771916846886490, 5007704561508622, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007631488747725, '找不到相符詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007631488747725-8771950851535873', 8771950851535873, 5007631488747725, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007615484784739, '{count} 個節點', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007615484784739-8771915754603204', 8771915754603204, 5007615484784739, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007663242416278, '節點資訊', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007663242416278-8772032217763299', 8772032217763299, 5007663242416278, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007716960745199, '其他關係', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007716960745199-8772011775552074', 8772011775552074, 5007716960745199, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007718262607438, '相關詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007718262607438-8771996275317129', 8771996275317129, 5007718262607438, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007592907990660, '{count} 個關係', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007592907990660-8771905570354775', 8771905570354775, 5007592907990660, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007596018795039, '移除 {code}', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007596018795039-8771968148353493', 8771968148353493, 5007596018795039, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686676910649, '重設版面配置', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686676910649-8771923590138278', 8771923590138278, 5007686676910649, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007631688692581, '根節點', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007631688692581-8771991096471187', 8771991096471187, 5007631688692581, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616919201563, '搜尋', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616919201563-8772018337291447', 8772018337291447, 5007616919201563, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719245960463, '搜尋詞句…', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719245960463-8771934172254861', 8771934172254861, 5007719245960463, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616358119612, '搜尋中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616358119612-8771951969125148', 8771951969125148, 5007616358119612, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007706065604142, '在圖譜中選取節點以檢視詳情', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007706065604142-8771969317410200', 8771969317410200, 5007706065604142, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007602227146017, '來源路徑', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007602227146017-8771977750841844', 8771977750841844, 5007602227146017, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007659776390736, '讚', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007659776390736-8772016238570208', 8772016238570208, 5007659776390736, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007656034240842, '檢視詞句詳情', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007656034240842-8771995720429284', 8771995720429284, 5007656034240842, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007617944539717, '投票失敗，已復原', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007617944539717-8772020751025198', 8772020751025198, 5007617944539717, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007655447379474, '放大', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007655447379474-8772017398603959', 8772017398603959, 5007655447379474, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007638292700252, '縮小', 'cmn-Hant', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007638292700252-8772017289371875', 8772017289371875, 5007638292700252, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007687964088072, '+ 新增詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007687964088072-8771945073983212', 8771945073983212, 5007687964088072, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007632704103951, '完全圖', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007632704103951-8771921254303111', 8771921254303111, 5007632704103951, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007683775636965, '刪除', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007683775636965-8771944300238713', 8771944300238713, 5007683775636965, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007712158631130, '{count} 個直接對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007712158631130-8771968945113345', 8771968945113345, 5007712158631130, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677367822286, '詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677367822286-8772028411030279', 8772028411030279, 5007677367822286, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007688910713580, '{count} 個詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007688910713580-8771918589046163', 8771918589046163, 5007688910713580, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007712825900255, '輸入詞句…', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007712825900255-8771975160452098', 8771975160452098, 5007712825900255, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771930947571421', 8771930947571421, 5007686050335421, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007624706027461, '提交一組意義相同的詞句。系統會在每對之間建立直接對應。已有詞句會自動關聯，不會重複。', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007624706027461-8771938370927027', 8771938370927027, 5007624706027461, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007657490121622, '至少需要 2 行，每行需填寫語言和詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007657490121622-8771996574983759', 8771996574983759, 5007657490121622, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007634256100549, '提交', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007634256100549-8771955384790296', 8771955384790296, 5007634256100549, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007668571582958, '提交失敗', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007668571582958-8771930781451254', 8771930781451254, 5007668571582958, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007591190527676, '提交中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007591190527676-8771996654725718', 8771996654725718, 5007591190527676, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007724233614761, '標籤', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007724233614761-8772023049338365', 8772023049338365, 5007724233614761, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007610321371389, '批次提交', 'cmn-Hant', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007610321371389-8771967116778370', 8771967116778370, 5007610321371389, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007628054228699, '回首頁', 'cmn-Hant', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007628054228699-8771954914944651', 8771954914944651, 5007628054228699, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612565795990, '無法載入', 'cmn-Hant', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612565795990-8771936602672507', 8771936602672507, 5007612565795990, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007700661507051, '找不到頁面', 'cmn-Hant', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007700661507051-8771958158698832', 8771958158698832, 5007700661507051, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007696593042553, '全部', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007696593042553-8771912696777795', 8771912696777795, 5007696593042553, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007697654264236, '提交對應 →', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007697654264236-8771952067596101', 8771952067596101, 5007697654264236, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007723174663984, '熱門', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007723174663984-8771957966582874', 8771957966582874, 5007723174663984, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007704834982248, '對應 + 新詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007704834982248-8771971172552785', 8771971172552785, 5007704834982248, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007651456204393, '找不到所需內容？', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007651456204393-8771964553678580', 8771964553678580, 5007651456204393, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007692081840569, '新貢獻', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007692081840569-8772013263074963', 8772013263074963, 5007692081840569, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607604627425, '最新', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607604627425-8771912463566270', 8771912463566270, 5007607604627425, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007651287991650, '熱門對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007651287991650-8771956320455891', 8771956320455891, 5007651287991650, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007683734867414, '依評分 · 本週', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007683734867414-8772001941683119', 8772001941683119, 5007683734867414, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607552896777, '語意圖的最新脈動——熱門對應與新貢獻。', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607552896777-8771985464043467', 8771985464043467, 5007607552896777, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007644716158679, '動態', 'cmn-Hant', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007644716158679-8771928668652497', 8771928668652497, 5007644716158679, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007593801262702, '新增詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007593801262702-8772033519106127', 8772033519106127, 5007593801262702, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007621223436095, '新增章節', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007621223436095-8772013343930223', 8772013343930223, 5007621223436095, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007705487696316, '手冊列表', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007705487696316-8771985524903836', 8771985524903836, 5007705487696316, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007725546159125, '第 {number} 章', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007725546159125-8771974942670538', 8771974942670538, 5007725546159125, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007684636104458, '關閉詞句資訊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007684636104458-8771948835977551', 8771948835977551, 5007684636104458, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007699956620865, '收合', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007699956620865-8772025115555117', 8772025115555117, 5007699956620865, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007654344983501, '刪除章節', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007654344983501-8771922363562335', 8771922363562335, 5007654344983501, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007692600987662, '編輯手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007692600987662-8771954520730023', 8771954520730023, 5007692600987662, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007589776612357, '詞句資訊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007589776612357-8771958749403912', 8771958749403912, 5007589776612357, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007715097855572, '詞句的語言、地區和來源將顯示在此處。', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007715097855572-8771969048222271', 8771969048222271, 5007715097855572, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007661380133877, '這本手冊有幫助嗎？', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007661380133877-8771919030282571', 8771919030282571, 5007661380133877, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007683593103509, '無法載入詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007683593103509-8772001956145712', 8772001956145712, 5007683593103509, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612565795990, '無法載入', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612565795990-8771936602672507', 8771936602672507, 5007612565795990, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771930947571421', 8771930947571421, 5007686050335421, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007650074003074, '下移', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007650074003074-8772015839426216', 8772015839426216, 5007650074003074, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007643815006434, '下移章節', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007643815006434-8771974741123489', 8771974741123489, 5007643815006434, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007629520277872, '上移章節', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007629520277872-8771974343227837', 8771974343227837, 5007629520277872, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007635946845687, '上移', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007635946845687-8772035822327586', 8772035822327586, 5007635946845687, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007681573695796, '私密', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007681573695796-8771981388316157', 8771981388316157, 5007681573695796, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007615308903108, '公開', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007615308903108-8771978356150928', 8771978356150928, 5007615308903108, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007715503546725, '發布', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007715503546725-8771952311782197', 8771952311782197, 5007715503546725, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007606447559182, '地區', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007606447559182-8771968624126325', 8771968624126325, 5007606447559182, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007647776203665, '無法載入相關詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007647776203665-8771991960796854', 8771991960796854, 5007647776203665, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007634915568372, '移除 {text}', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007634915568372-8771948377233166', 8771948377233166, 5007634915568372, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007699981092513, '儲存草稿', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007699981092513-8771974360984879', 8771974360984879, 5007699981092513, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007672351176404, '儲存中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007672351176404-8771980391249065', 8771980391249065, 5007672351176404, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007660957209707, '章節標題', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007660957209707-8771935521942479', 8771935521942479, 5007660957209707, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007709281377350, '選擇詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007709281377350-8771975315975664', 8771975315975664, 5007709281377350, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007640017262719, '來源', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007640017262719-8771933750484319', 8771933750484319, 5007640017262719, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639292411519, 'AI', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639292411519-8771954789056127', 8771954789056127, 5007639292411519, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007653154549251, '權威', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007653154549251-8772029059057248', 8772029059057248, 5007653154549251, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007698014440035, '使用者', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007698014440035-8772034803281550', 8772034803281550, 5007698014440035, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007721876393826, '手冊標題', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007721876393826-8771918701696347', 8771918701696347, 5007721876393826, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007673469054467, '目錄', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007673469054467-8771915172364840', 8771915172364840, 5007673469054467, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007626802923211, '檢視完整關係圖', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007626802923211-8771928949232797', 8771928949232797, 5007626802923211, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007664124762008, '可見性', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007664124762008-8772029984927123', 8772029984927123, 5007664124762008, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007674260849921, '新增手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007674260849921-8771984354571011', 8771984354571011, 5007674260849921, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007697223313857, '無法載入手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007697223313857-8771915400044673', 8771915400044673, 5007697223313857, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607604627425, '最新', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607604627425-8771912463566270', 8771912463566270, 5007607604627425, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007651447365556, '找不到手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007651447365556-8772007530341875', 8772007530341875, 5007651447365556, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007723174663984, '熱門', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007723174663984-8771957966582874', 8771957966582874, 5007723174663984, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007610205072363, '搜尋手冊…', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007610205072363-8772031472567985', 8772031472567985, 5007610205072363, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007696274158000, '章節', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007696274158000-8771981869623564', 8771981869623564, 5007696274158000, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616497851729, '手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616497851729-8771945183617329', 8771945183617329, 5007616497851729, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007708873733015, '上一步', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007708873733015-8772024038803789', 8772024038803789, 5007708873733015, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719410905098, '取消', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719410905098-8772001703307290', 8772001703307290, 5007719410905098, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007689820830527, '關閉', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007689820830527-8771958345505312', 8771958345505312, 5007689820830527, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007714911250327, '建立語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007714911250327-8771972155504688', 8771972155504688, 5007714911250327, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007597198368045, '語言建立失敗', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007597198368045-8772008975730714', 8772008975730714, 5007597198368045, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007709442998063, '建立中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007709442998063-8771943301451236', 8771943301451236, 5007709442998063, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007626843100894, '請輸入描述', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007626843100894-8771986788835322', 8771986788835322, 5007626843100894, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007687627379699, '請選擇 Glottolog 比對或選擇「無比對」', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007687627379699-8771982145239141', 8771982145239141, 5007687627379699, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007648090148139, '請輸入語言名稱', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007648090148139-8771921060819264', 8771921060819264, 5007648090148139, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007676948961841, '請選擇僅限社群建立的原因', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007676948961841-8771926836463632', 8771926836463632, 5007676948961841, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007669554516997, '請輸入語言子標籤以繼續', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007669554516997-8772026576042326', 8772026576042326, 5007669554516997, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007618048454812, '找到 {count} 個候選', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007618048454812-8771956461019812', 8771956461019812, 5007618048454812, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627044113620, '選擇比對或標示無合適條目', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627044113620-8772033726980358', 8772033726980358, 5007627044113620, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627246296906, '比對此候選', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627246296906-8772036217067472', 8772036217067472, 5007627246296906, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007628727447844, '方言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007628727447844-8771959645210043', 8771959645210043, 5007628727447844, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771953851734414', 8771953851734414, 5007686050335421, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007618367015503, 'Glottolog 無合適條目', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007618367015503-8771907658003091', 8771907658003091, 5007618367015503, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007599831540403, '搜尋 Glottolog…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007599831540403-8771972676692740', 8771972676692740, 5007599831540403, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007622685861510, '描述', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007622685861510-8771937301075282', 8771937301075282, 5007622685861510, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007697091449319, '描述此語言或變體…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007697091449319-8771929062150956', 8771929062150956, 5007697091449319, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007691754656057, '名稱', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007691754656057-8771913536651859', 8771913536651859, 5007691754656057, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686396809507, '英文名稱', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686396809507-8772035648862723', 8772035648862723, 5007686396809507, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007666737026570, '為何此語言未收錄於 Glottolog？', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007666737026570-8771965397553798', 8771965397553798, 5007666737026570, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007718755726151, '社群特定用法', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007718755726151-8772029121364869', 8772029121364869, 5007718755726151, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007675740525147, '新興變體', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007675740525147-8771911763851130', 8771911763851130, 5007675740525147, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007664503679853, 'Glottolog 未收錄', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007664503679853-8772027448793331', 8772027448793331, 5007664503679853, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007684075801994, '其他', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007684075801994-8771907717721822', 8771907717721822, 5007684075801994, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007723619810454, '選擇原因…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007723619810454-8771908744199257', 8771908744199257, 5007723619810454, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677050112595, '下一步', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677050112595-8771946058185965', 8771946058185965, 5007677050112595, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007682439694929, '標準代碼', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007682439694929-8771986283559204', 8771986283559204, 5007682439694929, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007617405498846, '此語言已存在', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007617405498846-8771963047592058', 8771963047592058, 5007617405498846, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007653787396426, '使用現有語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007653787396426-8771911987565882', 8771911987565882, 5007653787396426, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007714911250327, '建立語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007714911250327-8771972155504688', 8771972155504688, 5007714911250327, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007622785558957, '警告', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007622785558957-8771976682274382', 8771976682274382, 5007622785558957, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007588377772568, '暫時標籤', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007588377772568-8771969301691665', 8771969301691665, 5007588377772568, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627610417528, 'Glottolog 比對', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627610417528-8771926452848847', 8771926452848847, 5007627610417528, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007700656768439, '中繼資料', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007700656768439-8771988865126091', 8771988865126091, 5007700656768439, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007666482555601, '預覽並建立', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007666482555601-8772002442315415', 8772002442315415, 5007666482555601, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007590245386211, '語言標籤', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007590245386211-8771982332401463', 8771982332401463, 5007590245386211, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771930947571421', 8771930947571421, 5007686050335421, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007606447559182, '地區', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007606447559182-8771968624126325', 8771968624126325, 5007606447559182, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686774438010, '文字', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686774438010-8771976361115614', 8771976361115614, 5007686774438010, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007684970546194, '搜尋子標籤…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007684970546194-8772015391400398', 8772015391400398, 5007684970546194, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007592228510523, '變體', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007592228510523-8771923711808765', 8771923711808765, 5007592228510523, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007590313937733, '已移除 1 個變體', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007590313937733-8772011217159086', 8772011217159086, 5007590313937733, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007588420544733, '已移除 {count} 個變體', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007588420544733-8771998528580369', 8771998528580369, 5007588420544733, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007699791662801, '依字母排序', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007699791662801-8772039352640020', 8772039352640020, 5007699791662801, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771966685762373', 8771966685762373, 5007686050335421, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677367822286, '詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677367822286-8772004481370898', 8772004481370898, 5007677367822286, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607604627425, '最新', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607604627425-8771912463566270', 8771912463566270, 5007607604627425, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612565795990, '無法載入', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612565795990-8771936602672507', 8771936602672507, 5007612565795990, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007593308176568, '已對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007593308176568-8771947211108180', 8771947211108180, 5007593308176568, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007598177691071, '找不到詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007598177691071-8771950851535873', 8771950851535873, 5007598177691071, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007723174663984, '熱門', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007723174663984-8771957966582874', 8771957966582874, 5007723174663984, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719245960463, '搜尋詞句…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719245960463-8771934172254861', 8771934172254861, 5007719245960463, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007636186300534, '清除選擇', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007636186300534-8771904155296746', 8771904155296746, 5007636186300534, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007691700443714, '建立新語言或變體', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007691700443714-8772010209718094', 8772010209718094, 5007691700443714, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007683164932514, '無符合語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007683164932514-8771905467432581', 8771905467432581, 5007683164932514, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627415698210, '搜尋語言…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627415698210-8771957308068965', 8771957308068965, 5007627415698210, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007606685493697, '瀏覽器推薦', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007606685493697-8771943861429001', 8771943861429001, 5007606685493697, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007618562378039, '協助翻譯 LangMap', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007618562378039-8771962203854555', 8771962203854555, 5007618562378039, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007633264109331, '無符合的語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007633264109331-8771905467432581', 8771905467432581, 5007633264109331, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007647416136718, '最近使用的語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007647416136718-8772017158300851', 8772017158300851, 5007647416136718, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677367822286, '詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677367822286-8772004481370898', 8772004481370898, 5007677367822286, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771966685762373', 8771966685762373, 5007686050335421, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007697617594999, '無法載入語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007697617594999-8771907230355366', 8771907230355366, 5007697617594999, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007611270278095, '找不到語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007611270278095-8772015486738705', 8772015486738705, 5007611270278095, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627415698210, '搜尋語言…', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627415698210-8771957308068965', 8771957308068965, 5007627415698210, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007657903631628, 'A–Z', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007657903631628-8771973400276236', 8771973400276236, 5007657903631628, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007635983364209, '依數量', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007635983364209-8771994726877247', 8771994726877247, 5007635983364209, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007698283679918, '瀏覽所有語言的詞句與對應關係', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007698283679918-8772027985468400', 8772027985468400, 5007698283679918, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771966685762373', 8771966685762373, 5007686050335421, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616460095425, '錨點', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616460095425-8771952725719815', 8771952725719815, 5007616460095425, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007644591976536, '回到對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007644591976536-8771984993053397', 8771984993053397, 5007644591976536, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007624521919809, '{count} 種語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007624521919809-8771995851022194', 8771995851022194, 5007624521919809, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612565795990, '無法載入', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612565795990-8771936602672507', 8771936602672507, 5007612565795990, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007637378619197, '對應成員', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007637378619197-8771950928148051', 8771950928148051, 5007637378619197, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007636589081846, '此概念無地理分佈資料', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007636589081846-8771989613412250', 8771989613412250, 5007636589081846, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007630380442571, '{count} 個地區', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007630380442571-8772012470644251', 8772012470644251, 5007630380442571, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007661457547908, '概念分佈', 'cmn-Hant', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007661457547908-8771918829802721', 8771918829802721, 5007661457547908, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007618961599305, '新增並建立對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007618961599305-8771969898159421', 8771969898159421, 5007618961599305, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007593801262702, '新增詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007593801262702-8772033519106127', 8772033519106127, 5007593801262702, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007648084274560, '無法新增詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007648084274560-8771908944297462', 8771908944297462, 5007648084274560, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007654825308888, '新增中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007654825308888-8771928703559647', 8771928703559647, 5007654825308888, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007653154549251, '權威', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007653154549251-8772029059057248', 8772029059057248, 5007653154549251, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007604754627169, '麵包屑', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007604754627169-8772001620797917', 8772001620797917, 5007604754627169, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007659340309069, '關閉快速新增', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007659340309069-8771978190877962', 8771978190877962, 5007659340309069, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639645796554, '貢獻對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639645796554-8772005931944793', 8772005931944793, 5007639645796554, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007684044855210, '直接對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007684044855210-8771956479287686', 8771956479287686, 5007684044855210, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007714663533142, '請輸入詞句與語言代碼', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007714663533142-8771956618196526', 8771956618196526, 5007714663533142, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007677367822286, '詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007677367822286-8772028411030279', 8772028411030279, 5007677367822286, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007712825900255, '輸入詞句…', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007712825900255-8771952819511586', 8771952819511586, 5007712825900255, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007622731744905, '圖譜', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007622731744905-8771971766539087', 8771971766539087, 5007622731744905, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007679835556648, '首頁', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007679835556648-8771987694898855', 8771987694898855, 5007679835556648, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007642787446540, '跳數', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007642787446540-8771987564932373', 8771987564932373, 5007642787446540, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007632364442496, '間接', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007632364442496-8772028520330484', 8772028520330484, 5007632364442496, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607272748740, '語言代碼', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607272748740-8771920539132885', 8771920539132885, 5007607272748740, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007721671260839, '例如 en / cmn-Hant', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007721671260839-8772027619502019', 8772027619502019, 5007721671260839, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007678548163757, '列表', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007678548163757-8771992537520761', 8771992537520761, 5007678548163757, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612565795990, '無法載入', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612565795990-8771936602672507', 8771936602672507, 5007612565795990, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007687256123416, '對應集合', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007687256123416-8772011172535505', 8772011172535505, 5007687256123416, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007692209345238, '尚無對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007692209345238-8772036040577861', 8772036040577861, 5007692209345238, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007617997040870, '選填', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007617997040870-8771986434294618', 8771986434294618, 5007617997040870, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007595971465190, '快速新增詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007595971465190-8772035320845087', 8772035320845087, 5007595971465190, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007594723011393, '新增詞句並直接對應到目前詞句。', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007594723011393-8771923205204397', 8771923205204397, 5007594723011393, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007606447559182, '地區', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007606447559182-8771968624126325', 8771968624126325, 5007606447559182, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007698014440035, '使用者', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007698014440035-8772034803281550', 8772034803281550, 5007698014440035, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007640862331505, '在地圖上檢視此概念', 'cmn-Hant', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007640862331505-8772021818623523', 8772021818623523, 5007640862331505, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007693939192039, '關閉選單', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007693939192039-8772008345770010', 8772008345770010, 5007693939192039, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007659312132322, '貢獻', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007659312132322-8772022393103823', 8772022393103823, 5007659312132322, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007616497851729, '手冊', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007616497851729-8771945183617329', 8771945183617329, 5007616497851729, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007679835556648, '首頁', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007679835556648-8771987694898855', 8771987694898855, 5007679835556648, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007686050335421, '語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007686050335421-8771966685762373', 8771966685762373, 5007686050335421, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007636266685617, '選單', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007636266685617-8771933905283078', 8771933905283078, 5007636266685617, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007609510542097, '開啟選單', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007609510542097-8771988489117883', 8771988489117883, 5007609510542097, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007620572246307, '搜尋詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007620572246307-8772000153561666', 8772000153561666, 5007620572246307, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639590295621, '登入', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639590295621-8771985319534907', 8771985319534907, 5007639590295621, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007708913964853, '登出', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007708913964853-8771987956311474', 8771987956311474, 5007708913964853, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007612541759384, '送出搜尋', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007612541759384-8772033727162136', 8772033727162136, 5007612541759384, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007604626753830, '切換介面語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007604626753830-8771905685377287', 8771905685377287, 5007604626753830, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007611082246671, '依字母順序', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007611082246671-8772039352640020', 8772039352640020, 5007611082246671, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007627118912543, '提示：目前搜尋比對詞句原文。語意搜尋即將推出。', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007627118912543-8771909635790690', 8771909635790690, 5007627118912543, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007675217228270, '搜尋失敗', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007675217228270-8771929026122151', 8771929026122151, 5007675217228270, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007607604627425, '最新', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007607604627425-8771912463566270', 8771912463566270, 5007607604627425, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007628857270641, '找不到結果', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007628857270641-8771927555767000', 8771927555767000, 5007628857270641, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007719245960463, '搜尋詞句…', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007719245960463-8771934172254861', 8771934172254861, 5007719245960463, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007723174663984, '熱門', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007723174663984-8771957966582874', 8771957966582874, 5007723174663984, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007601799021572, '{count} 個結果', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007601799021572-8772014433488480', 8772014433488480, 5007601799021572, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007610933406754, '排序', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007610933406754-8772001210440828', 8772001210440828, 5007610933406754, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007620572246307, '搜尋詞句', 'cmn-Hant', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007620572246307-8772000153561666', 8772000153561666, 5007620572246307, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007701111943484, '新增要翻譯的語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007701111943484-8771973106595188', 8771973106595188, 5007701111943484, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007685276703229, '提交 {count} 筆翻譯', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007685276703229-8771943172288619', 8771943172288619, 5007685276703229, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007638769043670, '目前翻譯', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007638769043670-8771982470884397', 8771982470884397, 5007638769043670, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007632719804286, '選擇已註冊的語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007632719804286-8772018182873778', 8772018182873778, 5007632719804286, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007722286376090, '翻譯涵蓋率', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007722286376090-8772013113555302', 8772013113555302, 5007722286376090, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007669482945438, '顯示 {count} 筆', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007669482945438-8772040929892299', 8772040929892299, 5007669482945438, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007649179923360, '社群本地化', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007649179923360-8771973543137726', 8771973543137726, 5007649179923360, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007705329276957, '輸入翻譯…', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007705329276957-8771990724594742', 8771990724594742, 5007705329276957, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007590615844034, '無法載入翻譯工作台', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007590615844034-8771920552784072', 8771920552784072, 5007590615844034, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007714792299881, '載入中…', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007714792299881-8771908386278726', 8771908386278726, 5007714792299881, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639334552984, '目標語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639334552984-8771996866079300', 8771996866079300, 5007639334552984, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007673136995116, '無法載入語言列表', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007673136995116-8771965827772292', 8771965827772292, 5007673136995116, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007678852433197, '登入後可提交翻譯；候選翻譯依對應分數排序，無正分候選時使用備用文字。', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007678852433197-8771995706904988', 8771995706904988, 5007678852433197, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007642659981518, '找不到相符文字。', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007642659981518-8771904910396271', 8771904910396271, 5007642659981518, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007722751923074, '預覽', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007722751923074-8771969689937165', 8771969689937165, 5007722751923074, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007629812324352, '參考語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007629812324352-8772009963987850', 8772009963987850, 5007629812324352, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007711211452857, '搜尋鍵名或原文…', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007711211452857-8771962647026930', 8771962647026930, 5007711211452857, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007640133975371, '選擇翻譯語言', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007640133975371-8772037474898823', 8772037474898823, 5007640133975371, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007724240988709, '英文原文', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007724240988709-8772014752541923', 8772014752541923, 5007724240988709, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007683612794808, '開始', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007683612794808-8772036201600543', 8772036201600543, 5007683612794808, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007668571582958, '提交失敗', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007668571582958-8771930781451254', 8771930781451254, 5007668571582958, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007639458948889, '提交對應', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007639458948889-8771938026129323', 8771938026129323, 5007639458948889, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007661551126128, '已提交', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007661551126128-8771906650908176', 8771906650908176, 5007661551126128, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007610183826600, '幫助讓 LangMap 介面文字更自然、更實用。', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007610183826600-8771968758684575', 8771968758684575, 5007610183826600, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007658925626223, '翻譯工作台', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007658925626223-8772002773137414', 8772002773137414, 5007658925626223, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007684179658069, '翻譯 {key}', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007684179658069-8771936438281310', 8771936438281310, 5007684179658069, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007692016340526, '已翻譯', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007692016340526-8771916786083827', 8771916786083827, 5007692016340526, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5007642036856395, '翻譯', 'cmn-Hant', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5007642036856395-8771951513286657', 8771951513286657, 5007642036856395, 0, 'ui_i18n');

-- Locale es
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682868324365489, 'Correo electrónico', 'es', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682868324365489-8771988929111883', 8771988929111883, 682868324365489, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913794312592, '¿Ya tienes cuenta?', 'es', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913794312592-8771987324928109', 8771987324928109, 682913794312592, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892872018745, 'Iniciar sesión', 'es', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892872018745-8771985319534907', 8771985319534907, 682892872018745, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824306479408, '¿No tienes cuenta?', 'es', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824306479408-8771920874847316', 8771920874847316, 682824306479408, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682806459380331, 'Operación fallida', 'es', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682806459380331-8771934955742921', 8771934955742921, 682806459380331, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903623135850, 'Contraseña', 'es', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903623135850-8771993838728081', 8771993838728081, 682903623135850, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682800676237530, 'Procesando…', 'es', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682800676237530-8772001046060388', 8772001046060388, 682800676237530, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878957095027, 'Crear cuenta', 'es', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878957095027-8771964374844751', 8771964374844751, 682878957095027, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682803377749737, 'Nombre de usuario', 'es', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682803377749737-8772029311767367', 8772029311767367, 682803377749737, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798661288703, 'Cancelar', 'es', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798661288703-8772001703307290', 8772001703307290, 682798661288703, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883488560665, 'Cerrar', 'es', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883488560665-8771958345505312', 8771958345505312, 682883488560665, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-8771930947571421', 8771930947571421, 682900757579840, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-8771966685762373', 8771966685762373, 682828789630925, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859154714796, 'Cargando…', 'es', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859154714796-8771908386278726', 8771908386278726, 682859154714796, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904154017666, 'Buscar', 'es', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904154017666-8772018337291447', 8772018337291447, 682904154017666, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909207233641, 'Enviar', 'es', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909207233641-8771955384790296', 8771955384790296, 682909207233641, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900282106249, 'Tamaño real 100%', 'es', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900282106249-8771913559728006', 8771913559728006, 682900282106249, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878566757732, 'Anónimo', 'es', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878566757732-8771963881461252', 8771963881461252, 682878566757732, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682811764541936, '{count} nodos hijos; haz clic para colapsar', 'es', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682811764541936-8772032837909466', 8772032837909466, 682811764541936, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682852513874987, 'Cada arista es una relación directa independiente que se puede votar a favor o en contra; las relaciones con baja puntuación se colapsan.', 'es', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682852513874987-8772028933737015', 8772028933737015, 682852513874987, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919370768583, 'Grafo de relaciones a crear', 'es', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919370768583-8771990687804642', 8771990687804642, 682919370768583, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682816040996372, 'Cerrar panel de información', 'es', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682816040996372-8771923580873788', 8771923580873788, 682816040996372, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914227463087, 'Colapsar', 'es', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914227463087-8772025115555117', 8772025115555117, 682914227463087, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682803607295846, 'Colapsar rama hija', 'es', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682803607295846-8772021975712328', 8772021975712328, 682803607295846, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859696644566, 'Colapsar al primer nivel', 'es', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859696644566-8771963062101045', 8771963062101045, 682859696644566, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919851973958, 'Hace {count} días', 'es', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919851973958-8772016085305408', 8772016085305408, 682919851973958, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842955261625, 'Profundidad {depth}', 'es', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842955261625-8772018587383663', 8772018587383663, 682842955261625, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815072780171, 'Expresiones con relación directa', 'es', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815072780171-8771921679343522', 8771921679343522, 682815072780171, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889948742785, 'Votar en contra', 'es', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889948742785-8771992127181974', 8771992127181974, 682889948742785, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905389963153, '{count} aristas', 'es', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905389963153-8771907018302878', 8771907018302878, 682905389963153, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812603593886, 'Aún no hay datos', 'es', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812603593886-8772000424294921', 8772000424294921, 682812603593886, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682898902420755, 'Salir de pantalla completa', 'es', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682898902420755-8771995527490116', 8771995527490116, 682898902420755, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888528901639, 'Expandir', 'es', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888528901639-8771957005515059', 8771957005515059, 682888528901639, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855150211439, 'Expandir todo', 'es', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855150211439-8772033758268399', 8772033758268399, 682855150211439, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905168406966, 'Expandir rama hija', 'es', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905168406966-8771937729949713', 8771937729949713, 682905168406966, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-8772028411030279', 8772028411030279, 682831404901271, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858781814402, 'Filtrar idiomas…', 'es', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858781814402-8771975185705787', 8771975185705787, 682858781814402, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870740246259, 'Pantalla completa', 'es', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870740246259-8771984311379866', 8771984311379866, 682870740246259, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865789089431, 'Grafo de relaciones de expresiones', 'es', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865789089431-8771940176065576', 8771940176065576, 682865789089431, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858747257175, 'Cargando grafo…', 'es', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858747257175-8771930916265390', 8771930916265390, 682858747257175, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682841174674405, 'Modo grafo', 'es', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682841174674405-8772018055755937', 8772018055755937, 682841174674405, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864010028789, '{nodes} nodos mapeados · {edges} relaciones', 'es', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864010028789-8771930566920504', 8771930566920504, 682864010028789, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822929160288, 'Barra de herramientas del grafo', 'es', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822929160288-8771957995007293', 8771957995007293, 682822929160288, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869729672125, 'Lista jerárquica de relaciones', 'es', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869729672125-8771972530005685', 8771972530005685, 682869729672125, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682835277438690, 'Saltos', 'es', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682835277438690-8771929108158859', 8771929108158859, 682835277438690, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914700697726, 'Hace {count} horas', 'es', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914700697726-8771972038859703', 8771972038859703, 682914700697726, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858170221799, 'Ahora mismo', 'es', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858170221799-8772006156641051', 8772006156641051, 682858170221799, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897399365859, 'No se pudieron cargar los idiomas', 'es', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897399365859-8771907230355366', 8771907230355366, 682897399365859, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682929803561659, 'Modo lista', 'es', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682929803561659-8771978209325624', 8771978209325624, 682929803561659, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682809581221683, 'Cargar más', 'es', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682809581221683-8771968298248581', 8771968298248581, 682809581221683, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890862435526, 'Cargando expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890862435526-8771918922470710', 8771918922470710, 682890862435526, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682839530633697, 'Relación', 'es', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682839530633697-8772009894682686', 8772009894682686, 682839530633697, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890402565558, 'Puntuación de la relación', 'es', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890402565558-8772001613332908', 8772001613332908, 682890402565558, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682817694689253, 'Hace {count} minutos', 'es', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682817694689253-8772029891163450', 8772029891163450, 682817694689253, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682819625579845, 'Más acciones', 'es', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682819625579845-8771927265880728', 8771927265880728, 682819625579845, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903147448559, '{count} relaciones más disponibles en el grafo completo', 'es', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903147448559-8771978296601845', 8771978296601845, 682903147448559, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854737236104, 'Aún no hay relaciones directas', 'es', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854737236104-8771916846886490', 8771916846886490, 682854737236104, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682884245166836, 'No se encontraron expresiones', 'es', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682884245166836-8771950851535873', 8771950851535873, 682884245166836, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914114350784, '{count} nodos', 'es', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914114350784-8771915754603204', 8771915754603204, 682914114350784, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853735237920, 'Información del nodo', 'es', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853735237920-8772032217763299', 8772032217763299, 682853735237920, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682810019697541, 'Otras relaciones', 'es', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682810019697541-8772011775552074', 8772011775552074, 682810019697541, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931322749113, 'Expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931322749113-8771996275317129', 8771996275317129, 682931322749113, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901541740022, '{count} relaciones', 'es', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901541740022-8771905570354775', 8771905570354775, 682901541740022, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871527117091, 'Eliminar {code}', 'es', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871527117091-8771968148353493', 8771968148353493, 682871527117091, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824764392007, 'Restablecer diseño', 'es', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824764392007-8771923590138278', 8771923590138278, 682824764392007, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905582744699, 'Nodo raíz', 'es', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905582744699-8771991096471187', 8771991096471187, 682905582744699, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904154017666, 'Buscar', 'es', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904154017666-8772018337291447', 8772018337291447, 682904154017666, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-8771934172254861', 8771934172254861, 682820215961472, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682839248463634, 'Buscando…', 'es', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682839248463634-8771951969125148', 8771951969125148, 682839248463634, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682797643305883, 'Selecciona un nodo en el grafo para ver detalles', 'es', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682797643305883-8771969317410200', 8771969317410200, 682797643305883, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855228652320, 'Ruta de origen', 'es', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855228652320-8771977750841844', 8771977750841844, 682855228652320, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682848709766753, 'Votar a favor', 'es', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682848709766753-8772016238570208', 8772016238570208, 682848709766753, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682882404036245, 'Ver detalles de la expresión', 'es', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682882404036245-8771995720429284', 8771995720429284, 682882404036245, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842684816837, 'Voto fallido; revertido', 'es', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842684816837-8772020751025198', 8772020751025198, 682842684816837, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854827697630, 'Acercar', 'es', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854827697630-8772017398603959', 8772017398603959, 682854827697630, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682886003065027, 'Alejar', 'es', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682886003065027-8772017289371875', 8772017289371875, 682886003065027, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851144798066, '+ Añadir expresión', 'es', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851144798066-8771945073983212', 8771945073983212, 682851144798066, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682926967595430, 'Grafo completo', 'es', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682926967595430-8771921254303111', 8771921254303111, 682926967595430, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865595864632, 'Eliminar', 'es', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865595864632-8771944300238713', 8771944300238713, 682865595864632, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682836725062290, '{count} relaciones directas', 'es', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682836725062290-8771968945113345', 8771968945113345, 682836725062290, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-8772028411030279', 8772028411030279, 682831404901271, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876212042190, '{count} expresiones', 'es', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876212042190-8771918589046163', 8771918589046163, 682876212042190, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682899105867642, 'Introduce una expresión…', 'es', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682899105867642-8771975160452098', 8771975160452098, 682899105867642, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-8771930947571421', 8771930947571421, 682900757579840, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870347524468, 'Envía un grupo de expresiones que significan lo mismo. El sistema crea relaciones directas entre cada par. Las expresiones existentes se vinculan automáticamente sin duplicados.', 'es', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870347524468-8771938370927027', 8771938370927027, 682870347524468, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873791744221, 'Se requieren al menos 2 filas con idioma y expresión', 'es', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873791744221-8771996574983759', 8771996574983759, 682873791744221, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909207233641, 'Enviar', 'es', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909207233641-8771955384790296', 8771955384790296, 682909207233641, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798159782041, 'Error al enviar', 'es', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798159782041-8771930781451254', 8771930781451254, 682798159782041, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814360395519, 'Enviando…', 'es', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814360395519-8771996654725718', 8771996654725718, 682814360395519, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682817218566349, 'Etiquetas', 'es', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682817218566349-8772023049338365', 8772023049338365, 682817218566349, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682930493925566, 'Contribución por lotes', 'es', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682930493925566-8771967116778370', 8771967116778370, 682930493925566, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827446740449, 'Volver al inicio', 'es', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827446740449-8771954914944651', 8771954914944651, 682827446740449, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-8771936602672507', 8771936602672507, 682931450456078, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883833799037, 'Página no encontrada', 'es', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883833799037-8771958158698832', 8771958158698832, 682883833799037, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897294012569, 'Todo', 'es', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897294012569-8771912696777795', 8771912696777795, 682897294012569, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682924233918709, 'Contribuir una relación →', 'es', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682924233918709-8771952067596101', 8771952067596101, 682924233918709, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-8771957966582874', 8771957966582874, 682850921034842, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682912286542237, 'Relaciones + nuevas expresiones', 'es', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682912286542237-8771971172552785', 8771971172552785, 682912286542237, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885280317750, '¿No encuentras lo que buscas?', 'es', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885280317750-8771964553678580', 8771964553678580, 682885280317750, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903296125126, 'Nuevas contribuciones', 'es', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903296125126-8772013263074963', 8772013263074963, 682903296125126, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-8771912463566270', 8771912463566270, 682854338769382, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876078164459, 'Relaciones populares', 'es', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876078164459-8771956320455891', 8771956320455891, 682876078164459, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682874855282633, 'Por puntuación · esta semana', 'es', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682874855282633-8772001941683119', 8772001941683119, 682874855282633, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682879301535115, 'El pulso más reciente del grafo semántico: relaciones populares y nuevas contribuciones.', 'es', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682879301535115-8771985464043467', 8771985464043467, 682879301535115, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851376042934, 'Actividad', 'es', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851376042934-8771928668652497', 8771928668652497, 682851376042934, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682896175839391, 'Añadir expresión', 'es', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682896175839391-8772033519106127', 8772033519106127, 682896175839391, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682907584357528, 'Añadir sección', 'es', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682907584357528-8772013343930223', 8772013343930223, 682907584357528, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887455285958, 'Lista de manuales', 'es', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887455285958-8771985524903836', 8771985524903836, 682887455285958, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909247411400, 'Capítulo {number}', 'es', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909247411400-8771974942670538', 8771974942670538, 682909247411400, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682802420165888, 'Cerrar información de la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682802420165888-8771948835977551', 8771948835977551, 682802420165888, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914227463087, 'Colapsar', 'es', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914227463087-8772025115555117', 8772025115555117, 682914227463087, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847392263001, 'Eliminar sección', 'es', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847392263001-8771922363562335', 8771922363562335, 682847392263001, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903001549444, 'Editar manual', 'es', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903001549444-8771954520730023', 8771954520730023, 682903001549444, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871456822120, 'Información de la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871456822120-8771958749403912', 8771958749403912, 682871456822120, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682918537509057, 'El idioma, la región y la fuente de la expresión aparecerán aquí.', 'es', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682918537509057-8771969048222271', 8771969048222271, 682918537509057, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865333050613, '¿Te resultó útil este manual?', 'es', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865333050613-8771919030282571', 8771919030282571, 682865333050613, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871525229530, 'No se pudo cargar la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871525229530-8772001956145712', 8772001956145712, 682871525229530, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-8771936602672507', 8771936602672507, 682931450456078, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-8771930947571421', 8771930947571421, 682900757579840, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820585428709, 'Mover abajo', 'es', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820585428709-8772015839426216', 8772015839426216, 682820585428709, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682840750863606, 'Mover sección abajo', 'es', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682840750863606-8771974741123489', 8771974741123489, 682840750863606, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853627392960, 'Mover sección arriba', 'es', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853627392960-8771974343227837', 8771974343227837, 682853627392960, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682801072299066, 'Mover arriba', 'es', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682801072299066-8772035822327586', 8772035822327586, 682801072299066, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682923071600521, 'Privado', 'es', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682923071600521-8771981388316157', 8771981388316157, 682923071600521, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682910096190915, 'Público', 'es', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682910096190915-8771978356150928', 8771978356150928, 682910096190915, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913156609638, 'Publicar', 'es', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913156609638-8771952311782197', 8771952311782197, 682913156609638, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-8771968624126325', 8771968624126325, 682890354277950, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682930588561372, 'No se pudieron cargar las expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682930588561372-8771991960796854', 8771991960796854, 682930588561372, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682846178918264, 'Eliminar {text}', 'es', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682846178918264-8771948377233166', 8771948377233166, 682846178918264, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901426200083, 'Guardar borrador', 'es', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901426200083-8771974360984879', 8771974360984879, 682901426200083, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919067142996, 'Guardando…', 'es', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919067142996-8771980391249065', 8771980391249065, 682919067142996, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883612905517, 'Título de la sección', 'es', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883612905517-8771935521942479', 8771935521942479, 682883612905517, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847725144221, 'Seleccionar una expresión', 'es', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847725144221-8771975315975664', 8771975315975664, 682847725144221, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892161499513, 'Fuente', 'es', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892161499513-8771933750484319', 8771933750484319, 682892161499513, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682932709012149, 'IA', 'es', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682932709012149-8771954789056127', 8771954789056127, 682932709012149, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873592117071, 'Autoridad', 'es', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873592117071-8772029059057248', 8772029059057248, 682873592117071, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925132503903, 'Usuario', 'es', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925132503903-8772034803281550', 8772034803281550, 682925132503903, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682908876610953, 'Título del manual', 'es', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682908876610953-8771918701696347', 8771918701696347, 682908876610953, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682819580133454, 'Contenido', 'es', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682819580133454-8771915172364840', 8771915172364840, 682819580133454, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682856006386013, 'Ver grafo completo de relaciones', 'es', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682856006386013-8771928949232797', 8771928949232797, 682856006386013, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885242904874, 'Visibilidad', 'es', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885242904874-8772029984927123', 8772029984927123, 682885242904874, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682840614580731, 'Nuevo manual', 'es', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682840614580731-8771984354571011', 8771984354571011, 682840614580731, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828325867692, 'No se pudieron cargar los manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828325867692-8771915400044673', 8771915400044673, 682828325867692, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-8771912463566270', 8771912463566270, 682854338769382, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814365188442, 'No se encontraron manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814365188442-8772007530341875', 8772007530341875, 682814365188442, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-8771957966582874', 8771957966582874, 682850921034842, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682845859077642, 'Buscar manuales…', 'es', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682845859077642-8772031472567985', 8772031472567985, 682845859077642, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820985582214, 'secciones', 'es', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820985582214-8771981869623564', 8771981869623564, 682820985582214, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682921146202531, 'Manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682921146202531-8771945183617329', 8771945183617329, 682921146202531, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682881325797934, 'Atrás', 'es', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682881325797934-8772024038803789', 8772024038803789, 682881325797934, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798661288703, 'Cancelar', 'es', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798661288703-8772001703307290', 8772001703307290, 682798661288703, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883488560665, 'Cerrar', 'es', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883488560665-8771958345505312', 8771958345505312, 682883488560665, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904885771263, 'Crear idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904885771263-8771972155504688', 8771972155504688, 682904885771263, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682893540709366, 'Error al crear el idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682893540709366-8772008975730714', 8772008975730714, 682893540709366, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682826813618939, 'Creando…', 'es', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682826813618939-8771943301451236', 8771943301451236, 682826813618939, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831989539817, 'Introduce una descripción', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831989539817-8771986788835322', 8771986788835322, 682831989539817, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931417783940, 'Elige una coincidencia Glottolog o selecciona «sin coincidencia»', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931417783940-8771982145239141', 8771982145239141, 682931417783940, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814340105906, 'Introduce un nombre de idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814340105906-8771921060819264', 8771921060819264, 682814340105906, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682917329596165, 'Selecciona un motivo para la creación solo comunitaria', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682917329596165-8771926836463632', 8771926836463632, 682917329596165, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682825626662306, 'Introduce una subetiqueta de idioma para continuar', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682825626662306-8772026576042326', 8772026576042326, 682825626662306, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799931959085, '{count} candidato(s) encontrado(s)', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799931959085-8771956461019812', 8771956461019812, 682799931959085, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869629998340, 'Elige una coincidencia o indica que no hay entrada adecuada', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869629998340-8772033726980358', 8772033726980358, 682869629998340, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915180693699, 'Elegir este candidato', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915180693699-8772036217067472', 8772036217067472, 682915180693699, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682895952382846, 'dialecto', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682895952382846-8771959645210043', 8771959645210043, 682895952382846, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824256985236, 'idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824256985236-8771953851734414', 8771953851734414, 682824256985236, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682813918400823, 'Glottolog no tiene una entrada adecuada', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682813918400823-8771907658003091', 8771907658003091, 682813918400823, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931260832027, 'Buscar en Glottolog…', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931260832027-8771972676692740', 8771972676692740, 682931260832027, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865550849454, 'Descripción', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865550849454-8771937301075282', 8771937301075282, 682865550849454, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864204631545, 'Describe este idioma o variedad…', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864204631545-8771929062150956', 8771929062150956, 682864204631545, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897020949278, 'Nombre', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897020949278-8771913536651859', 8771913536651859, 682897020949278, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878840728431, 'Nombre en inglés', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878840728431-8772035648862723', 8772035648862723, 682878840728431, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682834735258162, '¿Por qué falta este idioma en Glottolog?', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682834735258162-8771965397553798', 8771965397553798, 682834735258162, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828421562039, 'Uso específico de la comunidad', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828421562039-8772029121364869', 8772029121364869, 682828421562039, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869368838054, 'Variante emergente', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869368838054-8771911763851130', 8771911763851130, 682869368838054, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871876394970, 'Falta en Glottolog', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871876394970-8772027448793331', 8772027448793331, 682871876394970, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682836132939567, 'Otro', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682836132939567-8771907717721822', 8771907717721822, 682836132939567, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827073546062, 'Selecciona un motivo…', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827073546062-8771908744199257', 8771908744199257, 682827073546062, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873107003134, 'Siguiente', 'es', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873107003134-8771946058185965', 8771946058185965, 682873107003134, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682856233469549, 'Código canónico', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682856233469549-8771986283559204', 8771986283559204, 682856233469549, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682801129462806, 'Este idioma ya existe', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682801129462806-8771963047592058', 8771963047592058, 682801129462806, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682830840681764, 'Usar idioma existente', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682830840681764-8771911987565882', 8771911987565882, 682830840681764, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904885771263, 'Crear idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904885771263-8771972155504688', 8771972155504688, 682904885771263, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682838014240047, 'Advertencias', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682838014240047-8771976682274382', 8771976682274382, 682838014240047, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682807648996300, 'Etiqueta provisional', 'es', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682807648996300-8771969301691665', 8771969301691665, 682807648996300, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925626679266, 'Coincidencia Glottolog', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925626679266-8771926452848847', 8771926452848847, 682925626679266, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876390474633, 'Metadatos', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876390474633-8771988865126091', 8771988865126091, 682876390474633, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682841843489511, 'Vista previa y crear', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682841843489511-8772002442315415', 8772002442315415, 682841843489511, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854301270668, 'Etiqueta de idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854301270668-8771982332401463', 8771982332401463, 682854301270668, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-8771930947571421', 8771930947571421, 682900757579840, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-8771968624126325', 8771968624126325, 682890354277950, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855713333931, 'Escritura', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855713333931-8771976361115614', 8771976361115614, 682855713333931, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682933636836112, 'Buscar subetiquetas…', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682933636836112-8772015391400398', 8772015391400398, 682933636836112, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815391355869, 'Variante', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815391355869-8771923711808765', 8771923711808765, 682815391355869, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915042677354, '1 variante eliminada', 'es', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915042677354-8772011217159086', 8772011217159086, 682915042677354, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815962453613, '{count} variante(s) eliminada(s)', 'es', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815962453613-8771998528580369', 8771998528580369, 682815962453613, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858707408402, 'Alfabético', 'es', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858707408402-8772039352640020', 8772039352640020, 682858707408402, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-8771966685762373', 8771966685762373, 682828789630925, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858267578336, 'Expresiones', 'es', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858267578336-8772004481370898', 8772004481370898, 682858267578336, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-8771912463566270', 8771912463566270, 682854338769382, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-8771936602672507', 8771936602672507, 682931450456078, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824803330268, 'Mapeado', 'es', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824803330268-8771947211108180', 8771947211108180, 682824803330268, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682884245166836, 'No se encontraron expresiones', 'es', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682884245166836-8771950851535873', 8771950851535873, 682884245166836, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-8771957966582874', 8771957966582874, 682850921034842, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-8771934172254861', 8771934172254861, 682820215961472, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682886289173715, 'Limpiar selección', 'es', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682886289173715-8771904155296746', 8771904155296746, 682886289173715, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873961011240, 'Crear nuevo idioma o variedad', 'es', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873961011240-8772010209718094', 8772010209718094, 682873961011240, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889306946654, 'No hay idiomas coincidentes', 'es', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889306946654-8771905467432581', 8771905467432581, 682889306946654, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799108127581, 'Buscar idiomas…', 'es', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799108127581-8771957308068965', 8771957308068965, 682799108127581, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682881132194991, 'Sugerido por tu navegador', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682881132194991-8771943861429001', 8771943861429001, 682881132194991, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854943128373, 'Ayuda a traducir LangMap', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854943128373-8771962203854555', 8771962203854555, 682854943128373, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889306946654, 'No hay idiomas coincidentes', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889306946654-8771905467432581', 8771905467432581, 682889306946654, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682816805029573, 'Idiomas recientes', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682816805029573-8772017158300851', 8772017158300851, 682816805029573, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858267578336, 'Expresiones', 'es', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858267578336-8772004481370898', 8772004481370898, 682858267578336, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-8771966685762373', 8771966685762373, 682828789630925, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897399365859, 'No se pudieron cargar los idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897399365859-8771907230355366', 8771907230355366, 682897399365859, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682917137608984, 'No se encontraron idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682917137608984-8772015486738705', 8772015486738705, 682917137608984, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799108127581, 'Buscar idiomas…', 'es', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799108127581-8771957308068965', 8771957308068965, 682799108127581, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682866354728204, 'A–Z', 'es', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682866354728204-8771973400276236', 8771973400276236, 682866354728204, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864643608963, 'Cantidad', 'es', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864643608963-8771994726877247', 8771994726877247, 682864643608963, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853329049107, 'Explorar expresiones y relaciones entre todos los idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853329049107-8772027985468400', 8772027985468400, 682853329049107, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-8771966685762373', 8771966685762373, 682828789630925, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682912173538717, 'Ancla', 'es', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682912173538717-8771952725719815', 8771952725719815, 682912173538717, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682872087619218, 'Volver a la relación', 'es', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682872087619218-8771984993053397', 8771984993053397, 682872087619218, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682867790418795, '{count} idiomas', 'es', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682867790418795-8771995851022194', 8771995851022194, 682867790418795, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-8771936602672507', 8771936602672507, 682931450456078, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870297095054, 'Miembros de la relación', 'es', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870297095054-8771950928148051', 8771950928148051, 682870297095054, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827769770520, 'No hay datos de distribución geográfica para este concepto', 'es', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827769770520-8771989613412250', 8771989613412250, 682827769770520, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682920716217478, '{count} regiones', 'es', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682920716217478-8772012470644251', 8772012470644251, 682920716217478, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892970271580, 'Distribución del concepto', 'es', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892970271580-8771918829802721', 8771918829802721, 682892970271580, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842464784433, 'Añadir y crear relación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842464784433-8771969898159421', 8771969898159421, 682842464784433, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682896175839391, 'Añadir expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682896175839391-8772033519106127', 8772033519106127, 682896175839391, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682843224142211, 'No se pudo añadir la expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682843224142211-8771908944297462', 8771908944297462, 682843224142211, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805183102062, 'Añadiendo…', 'es', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805183102062-8771928703559647', 8771928703559647, 682805183102062, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873592117071, 'Autoridad', 'es', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873592117071-8772029059057248', 8772029059057248, 682873592117071, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873975241213, 'Ruta de navegación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873975241213-8772001620797917', 8772001620797917, 682873975241213, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799712267891, 'Cerrar adición rápida', 'es', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799712267891-8771978190877962', 8771978190877962, 682799712267891, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682857813529004, 'Contribuir relación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682857813529004-8772005931944793', 8772005931944793, 682857813529004, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853510439182, 'relaciones directas', 'es', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853510439182-8771956479287686', 8771956479287686, 682853510439182, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815386380562, 'Introduce expresión y código de idioma', 'es', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815386380562-8771956618196526', 8771956618196526, 682815386380562, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-8772028411030279', 8772028411030279, 682831404901271, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682899105867642, 'Introduce una expresión…', 'es', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682899105867642-8771952819511586', 8771952819511586, 682899105867642, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858844350788, 'Grafo', 'es', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858844350788-8771971766539087', 8771971766539087, 682858844350788, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824951258194, 'Inicio', 'es', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824951258194-8771987694898855', 8771987694898855, 682824951258194, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682830496309961, 'saltos', 'es', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682830496309961-8771987564932373', 8771987564932373, 682830496309961, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682843895611736, 'indirecta', 'es', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682843895611736-8772028520330484', 8772028520330484, 682843895611736, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827335594089, 'Código de idioma', 'es', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827335594089-8771920539132885', 8771920539132885, 682827335594089, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876869018337, 'ej. en / cmn-Hant', 'es', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876869018337-8772027619502019', 8772027619502019, 682876869018337, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901415595687, 'Lista', 'es', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901415595687-8771992537520761', 8771992537520761, 682901415595687, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-8771936602672507', 8771936602672507, 682931450456078, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805074331733, 'Conjunto de relaciones', 'es', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805074331733-8772011172535505', 8772011172535505, 682805074331733, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682846121113471, 'Aún no hay relaciones', 'es', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682846121113471-8772036040577861', 8772036040577861, 682846121113471, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885264102196, 'Opcional', 'es', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885264102196-8771986434294618', 8771986434294618, 682885264102196, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812213013071, 'Añadir expresión rápidamente', 'es', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812213013071-8772035320845087', 8772035320845087, 682812213013071, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887862607436, 'Añade una expresión y relaciónala directamente con la expresión actual.', 'es', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887862607436-8771923205204397', 8771923205204397, 682887862607436, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-8771968624126325', 8771968624126325, 682890354277950, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925132503903, 'Usuario', 'es', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925132503903-8772034803281550', 8772034803281550, 682925132503903, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902911665001, 'Ver este concepto en el mapa', 'es', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902911665001-8772021818623523', 8772021818623523, 682902911665001, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682911615961836, 'Cerrar menú', 'es', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682911615961836-8772008345770010', 8772008345770010, 682911615961836, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798765517243, 'Contribuir', 'es', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798765517243-8772022393103823', 8772022393103823, 682798765517243, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682921146202531, 'Manuales', 'es', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682921146202531-8771945183617329', 8771945183617329, 682921146202531, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824951258194, 'Inicio', 'es', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824951258194-8771987694898855', 8771987694898855, 682824951258194, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-8771966685762373', 8771966685762373, 682828789630925, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682868240392030, 'Menú', 'es', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682868240392030-8771933905283078', 8771933905283078, 682868240392030, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682918219546097, 'Abrir menú', 'es', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682918219546097-8771988489117883', 8771988489117883, 682918219546097, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822282195727, 'Buscar expresiones', 'es', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822282195727-8772000153561666', 8772000153561666, 682822282195727, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892872018745, 'Iniciar sesión', 'es', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892872018745-8771985319534907', 8771985319534907, 682892872018745, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812225867769, 'Cerrar sesión', 'es', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812225867769-8771987956311474', 8771987956311474, 682812225867769, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873350178443, 'Enviar búsqueda', 'es', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873350178443-8772033727162136', 8772033727162136, 682873350178443, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682895671786413, 'Cambiar idioma de la interfaz', 'es', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682895671786413-8771905685377287', 8771905685377287, 682895671786413, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858707408402, 'Alfabético', 'es', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858707408402-8772039352640020', 8772039352640020, 682858707408402, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913899921960, 'Consejo: la búsqueda actual coincide con el texto de la expresión. La búsqueda semántica llegará más adelante.', 'es', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913899921960-8771909635790690', 8771909635790690, 682913899921960, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682893587666340, 'Error al buscar', 'es', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682893587666340-8771929026122151', 8771929026122151, 682893587666340, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-8771912463566270', 8771912463566270, 682854338769382, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900973909582, 'Sin resultados', 'es', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900973909582-8771927555767000', 8771927555767000, 682900973909582, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-8771934172254861', 8771934172254861, 682820215961472, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-8771957966582874', 8771957966582874, 682850921034842, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900848121381, '{count} resultado | {count} resultados', 'es', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900848121381-8772014433488480', 8772014433488480, 682900848121381, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873763431196, 'Ordenar', 'es', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873763431196-8772001210440828', 8772001210440828, 682873763431196, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822282195727, 'Buscar expresiones', 'es', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822282195727-8772000153561666', 8772000153561666, 682822282195727, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854818986642, 'Añadir un idioma para traducir', 'es', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854818986642-8771973106595188', 8771973106595188, 682854818986642, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915187627195, 'Enviar {count} traducciones', 'es', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915187627195-8771943172288619', 8771943172288619, 682915187627195, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851258589248, 'Traducción actual', 'es', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851258589248-8771982470884397', 8771982470884397, 682851258589248, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682838786706383, 'Elige un idioma registrado', 'es', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682838786706383-8772018182873778', 8772018182873778, 682838786706383, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888380089522, 'Cobertura de traducción', 'es', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888380089522-8772013113555302', 8772013113555302, 682888380089522, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925240585946, '{count} mostrados', 'es', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925240585946-8772040929892299', 8772040929892299, 682925240585946, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831581261239, 'LOCALIZACIÓN COMUNITARIA', 'es', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831581261239-8771973543137726', 8771973543137726, 682831581261239, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682924372803922, 'Introduce la traducción…', 'es', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682924372803922-8771990724594742', 8771990724594742, 682924372803922, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887335369782, 'No se pudo cargar el área de trabajo de traducción', 'es', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887335369782-8771920552784072', 8771920552784072, 682887335369782, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859154714796, 'Cargando…', 'es', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859154714796-8771908386278726', 8771908386278726, 682859154714796, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805787749021, 'Idioma de destino', 'es', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805787749021-8771996866079300', 8771996866079300, 682805787749021, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902014794540, 'No se pudo cargar la lista de idiomas', 'es', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902014794540-8771965827772292', 8771965827772292, 682902014794540, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682834234688838, 'Inicia sesión para enviar traducciones; los candidatos se seleccionan por puntuación de relación y se usa el texto de respaldo cuando no hay un candidato positivo.', 'es', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682834234688838-8771995706904988', 8771995706904988, 682834234688838, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888628710154, 'No se encontraron textos coincidentes.', 'es', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888628710154-8771904910396271', 8771904910396271, 682888628710154, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682906610341361, 'Vista previa', 'es', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682906610341361-8771969689937165', 8771969689937165, 682906610341361, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682863126124520, 'Idioma de referencia', 'es', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682863126124520-8772009963987850', 8772009963987850, 682863126124520, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889113673816, 'Buscar clave o texto original…', 'es', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889113673816-8771962647026930', 8771962647026930, 682889113673816, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865675337327, 'Elegir idioma de traducción', 'es', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865675337327-8772037474898823', 8772037474898823, 682865675337327, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870996044253, 'Original en inglés', 'es', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870996044253-8772014752541923', 8772014752541923, 682870996044253, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822813444135, 'Comenzar', 'es', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822813444135-8772036201600543', 8772036201600543, 682822813444135, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798159782041, 'Error al enviar', 'es', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798159782041-8771930781451254', 8771930781451254, 682798159782041, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902106631267, 'Enviar relación', 'es', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902106631267-8771938026129323', 8771938026129323, 682902106631267, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831990627040, 'Enviado', 'es', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831990627040-8771906650908176', 8771906650908176, 682831990627040, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682929278454242, 'Ayuda a que el texto de la interfaz de LangMap sea natural y útil.', 'es', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682929278454242-8771968758684575', 8771968758684575, 682929278454242, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815193255977, 'Área de trabajo de traducción', 'es', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815193255977-8772002773137414', 8772002773137414, 682815193255977, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682825696738240, 'Traducir {key}', 'es', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682825696738240-8771936438281310', 8771936438281310, 682825696738240, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847168128679, 'traducido', 'es', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847168128679-8771916786083827', 8771916786083827, 682847168128679, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820936960095, 'Traducción', 'es', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820936960095-8771951513286657', 8771951513286657, 682820936960095, 0, 'ui_i18n');

-- Locale ja
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639165672169, 'メールアドレス', 'ja', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639165672169-8771988929111883', 8771988929111883, 5667639165672169, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643600055019, 'すでにアカウントをお持ちですか？', 'ja', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667643600055019-8771987324928109', 8771987324928109, 5667643600055019, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667637138127513, 'ログイン', 'ja', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667637138127513-8771985319534907', 8771985319534907, 5667637138127513, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667681854911873, 'アカウントをお持ちでないですか？', 'ja', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667681854911873-8771920874847316', 8771920874847316, 5667681854911873, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667687394613636, '操作に失敗しました', 'ja', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667687394613636-8771934955742921', 8771934955742921, 5667687394613636, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658495762766, 'パスワード', 'ja', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667658495762766-8771993838728081', 8771993838728081, 5667658495762766, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667576652918371, '処理中…', 'ja', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667576652918371-8772001046060388', 8772001046060388, 5667576652918371, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667662270756379, 'アカウント作成', 'ja', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667662270756379-8771964374844751', 8771964374844751, 5667662270756379, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667691864346811, 'ユーザー名', 'ja', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667691864346811-8772029311767367', 8772029311767367, 5667691864346811, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595026247812, 'キャンセル', 'ja', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667595026247812-8772001703307290', 8772001703307290, 5667595026247812, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679919267773, '閉じる', 'ja', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667679919267773-8771958345505312', 8771958345505312, 5667679919267773, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771930947571421', 8771930947571421, 5667688633057075, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771966685762373', 8771966685762373, 5667688633057075, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680432488224, '読み込み中…', 'ja', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667680432488224-8771908386278726', 8771908386278726, 5667680432488224, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667636864923714, '検索', 'ja', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667636864923714-8772018337291447', 8772018337291447, 5667636864923714, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635910157711, '送信', 'ja', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667635910157711-8771955384790296', 8771955384790296, 5667635910157711, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705077379244, '実際のサイズ 100%', 'ja', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667705077379244-8771913559728006', 8771913559728006, 5667705077379244, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667627138896988, '匿名', 'ja', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667627138896988-8771963881461252', 8771963881461252, 5667627138896988, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667704125133743, '{count} 個の子ノード；クリックして折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667704125133743-8772032837909466', 8772032837909466, 5667704125133743, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695215960406, '各エッジは独立した直接関係で、賛成・反対の投票が可能です。低スコアの関係は自動的に折りたたまれます。', 'ja', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667695215960406-8772028933737015', 8772028933737015, 5667695215960406, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665893607938, '作成する関係グラフ', 'ja', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667665893607938-8771990687804642', 8771990687804642, 5667665893607938, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622146578295, '情報パネルを閉じる', 'ja', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667622146578295-8771923580873788', 8771923580873788, 5667622146578295, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647414230792, '折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667647414230792-8772025115555117', 8772025115555117, 5667647414230792, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595467188476, '子ノードを折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667595467188476-8772021975712328', 8772021975712328, 5667595467188476, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602835528759, '最初の階層に折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667602835528759-8771963062101045', 8771963062101045, 5667602835528759, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660629563939, '{count} 日前', 'ja', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667660629563939-8772016085305408', 8772016085305408, 5667660629563939, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599363342566, '深さ {depth}', 'ja', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667599363342566-8772018587383663', 8772018587383663, 5667599363342566, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621450979350, '直接関係のある表現', 'ja', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667621450979350-8771921679343522', 8771921679343522, 5667621450979350, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667641664082987, '反対', 'ja', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667641664082987-8771992127181974', 8771992127181974, 5667641664082987, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612355688340, '{count} エッジ', 'ja', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667612355688340-8771907018302878', 8771907018302878, 5667612355688340, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626905715116, 'データはまだありません', 'ja', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667626905715116-8772000424294921', 8772000424294921, 5667626905715116, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643830645123, '全画面を終了', 'ja', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667643830645123-8771995527490116', 8771995527490116, 5667643830645123, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587298048364, '展開', 'ja', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667587298048364-8771957005515059', 8771957005515059, 5667587298048364, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667588107604965, 'すべて展開', 'ja', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667588107604965-8772033758268399', 8772033758268399, 5667588107604965, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667672684673798, '子ノードを展開', 'ja', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667672684673798-8771937729949713', 8771937729949713, 5667672684673798, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645040737135-8772028411030279', 8772028411030279, 5667645040737135, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690226659892, '言語をフィルター…', 'ja', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667690226659892-8771975185705787', 8771975185705787, 5667690226659892, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602854178051, '全画面', 'ja', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667602854178051-8771984311379866', 8771984311379866, 5667602854178051, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683111697606, '表現関係グラフ', 'ja', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667683111697606-8771940176065576', 8771940176065576, 5667683111697606, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600207637940, 'グラフを読み込み中…', 'ja', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600207637940-8771930916265390', 8771930916265390, 5667600207637940, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679560174028, 'グラフモード', 'ja', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667679560174028-8772018055755937', 8772018055755937, 5667679560174028, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638561368417, '{nodes} 個のマッピングノード · {edges} 件の関係', 'ja', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667638561368417-8771930566920504', 8771930566920504, 5667638561368417, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593987798820, 'グラフツールバー', 'ja', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667593987798820-8771957995007293', 8771957995007293, 5667593987798820, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623800548345, '関係階層リスト', 'ja', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667623800548345-8771972530005685', 8771972530005685, 5667623800548345, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582865883104, 'ホップ数', 'ja', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667582865883104-8771929108158859', 8771929108158859, 5667582865883104, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667604953481249, '{count} 時間前', 'ja', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667604953481249-8771972038859703', 8771972038859703, 5667604953481249, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591711089547, 'たった今', 'ja', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667591711089547-8772006156641051', 8772006156641051, 5667591711089547, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610322011774, '言語を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667610322011774-8771907230355366', 8771907230355366, 5667610322011774, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667577656080399, 'リストモード', 'ja', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667577656080399-8771978209325624', 8771978209325624, 5667577656080399, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591167941758, 'さらに読み込む', 'ja', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667591167941758-8771968298248581', 8771968298248581, 5667591167941758, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638287645590, '関連表現を読み込み中', 'ja', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667638287645590-8771918922470710', 8771918922470710, 5667638287645590, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667577551126800, '関係', 'ja', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667577551126800-8772009894682686', 8772009894682686, 5667577551126800, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677073700359, '関係スコア', 'ja', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667677073700359-8772001613332908', 8772001613332908, 5667677073700359, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590042843220, '{count} 分前', 'ja', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667590042843220-8772029891163450', 8772029891163450, 5667590042843220, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667578694717845, 'その他の操作', 'ja', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667578694717845-8771927265880728', 8771927265880728, 5667578694717845, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596028796915, '完全なグラフにはさらに {count} 件の関係があります', 'ja', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667596028796915-8771978296601845', 8771978296601845, 5667596028796915, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639941268368, '直接関係はまだありません', 'ja', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639941268368-8771916846886490', 8771916846886490, 5667639941268368, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694062377766, '表現が見つかりません', 'ja', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694062377766-8771950851535873', 8771950851535873, 5667694062377766, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664456116257, '{count} ノード', 'ja', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667664456116257-8771915754603204', 8771915754603204, 5667664456116257, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667704813735011, 'ノード情報', 'ja', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667704813735011-8772032217763299', 8772032217763299, 5667704813735011, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587189796271, 'その他の関係', 'ja', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667587189796271-8772011775552074', 8772011775552074, 5667587189796271, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667633354751803, '関連表現', 'ja', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667633354751803-8771996275317129', 8771996275317129, 5667633354751803, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694758653266, '{count} 件の関係', 'ja', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694758653266-8771905570354775', 8771905570354775, 5667694758653266, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667585691115513, '{code} を削除', 'ja', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667585691115513-8771968148353493', 8771968148353493, 5667585691115513, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635890823393, 'レイアウトをリセット', 'ja', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667635890823393-8771923590138278', 8771923590138278, 5667635890823393, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663237814889, 'ルートノード', 'ja', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667663237814889-8771991096471187', 8771991096471187, 5667663237814889, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667636864923714, '検索', 'ja', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667636864923714-8772018337291447', 8772018337291447, 5667636864923714, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667602001034739-8771934172254861', 8771934172254861, 5667602001034739, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667676834316056, '検索中…', 'ja', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667676834316056-8771951969125148', 8771951969125148, 5667676834316056, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623628533232, 'グラフ内のノードを選択して詳細を表示', 'ja', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667623628533232-8771969317410200', 8771969317410200, 5667623628533232, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660251571215, '元の経路', 'ja', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667660251571215-8771977750841844', 8771977750841844, 5667660251571215, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658371786207, '賛成', 'ja', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667658371786207-8772016238570208', 8772016238570208, 5667658371786207, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599780785659, '表現の詳細を表示', 'ja', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667599780785659-8771995720429284', 8771995720429284, 5667599780785659, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706980891720, '投票に失敗しました。元に戻しました', 'ja', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667706980891720-8772020751025198', 8772020751025198, 5667706980891720, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660362713436, '拡大', 'ja', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667660362713436-8772017398603959', 8772017398603959, 5667660362713436, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667620147272796, '縮小', 'ja', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667620147272796-8772017289371875', 8772017289371875, 5667620147272796, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667614041538610, '+ 表現を追加', 'ja', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667614041538610-8771945073983212', 8771945073983212, 5667614041538610, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648348787071, '完全グラフ', 'ja', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667648348787071-8771921254303111', 8771921254303111, 5667648348787071, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587121146465, '削除', 'ja', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667587121146465-8771944300238713', 8771944300238713, 5667587121146465, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667584367383178, '{count} 件の直接関係', 'ja', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667584367383178-8771968945113345', 8771968945113345, 5667584367383178, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645040737135-8772028411030279', 8772028411030279, 5667645040737135, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664773091494, '{count} 件の表現', 'ja', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667664773091494-8771918589046163', 8771918589046163, 5667664773091494, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629262680456, '表現を入力…', 'ja', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667629262680456-8771975160452098', 8771975160452098, 5667629262680456, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771930947571421', 8771930947571421, 5667688633057075, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619715122750, '同じ意味を持つ表現のグループを送信します。システムは各ペア間に直接関係を作成します。既存の表現は重複なく自動的にリンクされます。', 'ja', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667619715122750-8771938370927027', 8771938370927027, 5667619715122750, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663103663489, '言語と表現を入力した行が少なくとも2行必要です', 'ja', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667663103663489-8771996574983759', 8771996574983759, 5667663103663489, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635910157711, '送信', 'ja', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667635910157711-8771955384790296', 8771955384790296, 5667635910157711, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589757005077, '送信に失敗しました', 'ja', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589757005077-8771930781451254', 8771930781451254, 5667589757005077, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599360416322, '送信中…', 'ja', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667599360416322-8771996654725718', 8771996654725718, 5667599360416322, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600711195237, 'タグ', 'ja', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600711195237-8772023049338365', 8772023049338365, 5667600711195237, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645326250629, '一括投稿', 'ja', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645326250629-8771967116778370', 8771967116778370, 5667645326250629, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583774054725, 'ホームに戻る', 'ja', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667583774054725-8771954914944651', 8771954914944651, 5667583774054725, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579068168092-8771936602672507', 8771936602672507, 5667579068168092, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677441704212, 'ページが見つかりません', 'ja', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667677441704212-8771958158698832', 8771958158698832, 5667677441704212, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626689511354, 'すべて', 'ja', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667626689511354-8771912696777795', 8771912696777795, 5667626689511354, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626918417847, '関係を投稿する →', 'ja', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667626918417847-8771952067596101', 8771952067596101, 5667626918417847, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600188693356-8771957966582874', 8771957966582874, 5667600188693356, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667698229312944, '関係 + 新しい表現', 'ja', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667698229312944-8771971172552785', 8771971172552785, 5667698229312944, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667576212878837, '必要なものが見つかりませんか？', 'ja', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667576212878837-8771964553678580', 8771964553678580, 5667576212878837, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631844621370, '新しい貢献', 'ja', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667631844621370-8772013263074963', 8772013263074963, 5667631844621370, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589459199969-8771912463566270', 8771912463566270, 5667589459199969, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667581213623373, '人気の関係', 'ja', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667581213623373-8771956320455891', 8771956320455891, 5667581213623373, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667607307273749, 'スコア順 · 今週', 'ja', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667607307273749-8772001941683119', 8772001941683119, 5667607307273749, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587526185973, '意味グラフの最新情報 — 人気の関係と新しい貢献。', 'ja', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667587526185973-8771985464043467', 8771985464043467, 5667587526185973, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664190240873, 'アクティビティ', 'ja', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667664190240873-8771928668652497', 8771928668652497, 5667664190240873, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657431263471, '表現を追加', 'ja', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667657431263471-8772033519106127', 8772033519106127, 5667657431263471, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589945556192, 'セクションを追加', 'ja', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589945556192-8772013343930223', 8772013343930223, 5667589945556192, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647303323444, 'ハンドブック一覧', 'ja', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667647303323444-8771985524903836', 8771985524903836, 5667647303323444, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667707400731669, '第 {number} 章', 'ja', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667707400731669-8771974942670538', 8771974942670538, 5667707400731669, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667632234504261, '表現情報を閉じる', 'ja', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667632234504261-8771948835977551', 8771948835977551, 5667632234504261, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647414230792, '折りたたむ', 'ja', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667647414230792-8772025115555117', 8772025115555117, 5667647414230792, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645713485755, 'セクションを削除', 'ja', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645713485755-8771922363562335', 8771922363562335, 5667645713485755, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667584200423865, 'ハンドブックを編集', 'ja', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667584200423865-8771954520730023', 8771954520730023, 5667584200423865, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667608287100218, '表現情報', 'ja', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667608287100218-8771958749403912', 8771958749403912, 5667608287100218, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697393233440, '表現の言語、地域、ソースがここに表示されます。', 'ja', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667697393233440-8771969048222271', 8771969048222271, 5667697393233440, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590862209198, 'このハンドブックは役に立ちましたか？', 'ja', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667590862209198-8771919030282571', 8771919030282571, 5667590862209198, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590132862834, '表現を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667590132862834-8772001956145712', 8772001956145712, 5667590132862834, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579068168092-8771936602672507', 8771936602672507, 5667579068168092, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771930947571421', 8771930947571421, 5667688633057075, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667592930808359, '下に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667592930808359-8772015839426216', 8772015839426216, 5667592930808359, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667686037406860, 'セクションを下に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667686037406860-8771974741123489', 8771974741123489, 5667686037406860, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667628219000442, 'セクションを上に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667628219000442-8771974343227837', 8771974343227837, 5667628219000442, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619659722302, '上に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667619659722302-8772035822327586', 8772035822327586, 5667619659722302, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688641655419, '非公開', 'ja', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688641655419-8771981388316157', 8771981388316157, 5667688641655419, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667597163475652, '公開', 'ja', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667597163475652-8771978356150928', 8771978356150928, 5667597163475652, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667597163475652, '公開', 'ja', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667597163475652-8771952311782197', 8771952311782197, 5667597163475652, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667695151549854-8771968624126325', 8771968624126325, 5667695151549854, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583785466950, '関連表現を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667583785466950-8771991960796854', 8771991960796854, 5667583785466950, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667659096217242, '{text} を削除', 'ja', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667659096217242-8771948377233166', 8771948377233166, 5667659096217242, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572235872905, '下書きを保存', 'ja', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667572235872905-8771974360984879', 8771974360984879, 5667572235872905, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688912070401, '保存中…', 'ja', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688912070401-8771980391249065', 8771980391249065, 5667688912070401, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667616146054046, 'セクションタイトル', 'ja', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667616146054046-8771935521942479', 8771935521942479, 5667616146054046, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667672049644118, '表現を選択', 'ja', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667672049644118-8771975315975664', 8771975315975664, 5667672049644118, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667594135305634, 'ソース', 'ja', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667594135305634-8771933750484319', 8771933750484319, 5667594135305634, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621146984063, 'AI', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667621146984063-8771954789056127', 8771954789056127, 5667621146984063, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667642644092467, '権威', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667642644092467-8772029059057248', 8772029059057248, 5667642644092467, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593348696707, 'ユーザー', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667593348696707-8772034803281550', 8772034803281550, 5667593348696707, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667682192777813, 'ハンドブックのタイトル', 'ja', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667682192777813-8771918701696347', 8771918701696347, 5667682192777813, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579323900406, '目次', 'ja', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579323900406-8771915172364840', 8771915172364840, 5667579323900406, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667692312739958, '完全な関係グラフを表示', 'ja', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667692312739958-8771928949232797', 8771928949232797, 5667692312739958, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612661686889, '公開設定', 'ja', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667612661686889-8772029984927123', 8772029984927123, 5667612661686889, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677295209796, '新しいハンドブック', 'ja', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667677295209796-8771984354571011', 8771984354571011, 5667677295209796, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660139797948, 'ハンドブックを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667660139797948-8771915400044673', 8771915400044673, 5667660139797948, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589459199969-8771912463566270', 8771912463566270, 5667589459199969, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667574177099599, 'ハンドブックが見つかりません', 'ja', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667574177099599-8772007530341875', 8772007530341875, 5667574177099599, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600188693356-8771957966582874', 8771957966582874, 5667600188693356, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705480166510, 'ハンドブックを検索…', 'ja', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667705480166510-8772031472567985', 8772031472567985, 5667705480166510, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647811879499, 'セクション', 'ja', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667647811879499-8771981869623564', 8771981869623564, 5667647811879499, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705114884036, 'ハンドブック', 'ja', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667705114884036-8771945183617329', 8771945183617329, 5667705114884036, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677944766523, '戻る', 'ja', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667677944766523-8772024038803789', 8772024038803789, 5667677944766523, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595026247812, 'キャンセル', 'ja', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667595026247812-8772001703307290', 8772001703307290, 5667595026247812, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679919267773, '閉じる', 'ja', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667679919267773-8771958345505312', 8771958345505312, 5667679919267773, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612444597544, '言語を作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667612444597544-8771972155504688', 8771972155504688, 5667612444597544, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690506718434, '言語の作成に失敗しました', 'ja', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667690506718434-8772008975730714', 8772008975730714, 5667690506718434, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667693422064228, '作成中…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667693422064228-8771943301451236', 8771943301451236, 5667693422064228, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591545427858, '説明を入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667591545427858-8771986788835322', 8771986788835322, 5667591545427858, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667662591605031, 'Glottolog の一致を選択するか、「一致なし」を選択', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667662591605031-8771982145239141', 8771982145239141, 5667662591605031, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667656899394892, '言語名を入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667656899394892-8771921060819264', 8771921060819264, 5667656899394892, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631357468679, 'コミュニティのみ作成の理由を選択してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667631357468679-8771926836463632', 8771926836463632, 5667631357468679, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667571702640112, '続行するには言語サブタグを入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667571702640112-8772026576042326', 8772026576042326, 5667571702640112, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648277038737, '{count} 件の候補が見つかりました', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667648277038737-8771956461019812', 8771956461019812, 5667648277038737, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694367528648, '一致を選択するか、適切な項目がないことを指定', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694367528648-8772033726980358', 8772033726980358, 5667694367528648, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667592190268120, 'この候補に一致', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667592190268120-8772036217067472', 8772036217067472, 5667592190268120, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610582020388, '方言', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667610582020388-8771959645210043', 8771959645210043, 5667610582020388, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771953851734414', 8771953851734414, 5667688633057075, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690992352106, 'Glottolog に適切な項目がありません', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667690992352106-8771907658003091', 8771907658003091, 5667690992352106, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699937109125, 'Glottolog を検索…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667699937109125-8771972676692740', 8771972676692740, 5667699937109125, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667684090940545, '説明', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667684090940545-8771937301075282', 8771937301075282, 5667684090940545, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667575867259256, 'この言語または変種を説明…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667575867259256-8771929062150956', 8771929062150956, 5667575867259256, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648595681284, '名前', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667648595681284-8771913536651859', 8771913536651859, 5667648595681284, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621908159537, '英語名', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667621908159537-8772035648862723', 8772035648862723, 5667621908159537, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683865193530, 'この言語が Glottolog にない理由は？', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667683865193530-8771965397553798', 8771965397553798, 5667683865193530, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610675283792, 'コミュニティ固有の用法', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667610675283792-8772029121364869', 8772029121364869, 5667610675283792, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667625067957717, '新しい変種', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667625067957717-8771911763851130', 8771911763851130, 5667625067957717, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643589559118, 'Glottolog に未収録', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667643589559118-8772027448793331', 8772027448793331, 5667643589559118, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591971252444, 'その他', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667591971252444-8771907717721822', 8771907717721822, 5667591971252444, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667603879877440, '理由を選択…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667603879877440-8771908744199257', 8771908744199257, 5667603879877440, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583610699684, '次へ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667583610699684-8771946058185965', 8771946058185965, 5667583610699684, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706515947714, '正規コード', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667706515947714-8771986283559204', 8771986283559204, 5667706515947714, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667700503765697, 'この言語はすでに存在します', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667700503765697-8771963047592058', 8771963047592058, 5667700503765697, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667571445869872, '既存の言語を使用', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667571445869872-8771911987565882', 8771911987565882, 5667571445869872, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612444597544, '言語を作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667612444597544-8771972155504688', 8771972155504688, 5667612444597544, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667604640131501, '警告', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667604640131501-8771976682274382', 8771976682274382, 5667604640131501, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667605779127548, '暫定タグ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667605779127548-8771969301691665', 8771969301691665, 5667605779127548, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683439617817, 'Glottolog マッチ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667683439617817-8771926452848847', 8771926452848847, 5667683439617817, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572374094601, 'メタデータ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667572374094601-8771988865126091', 8771988865126091, 5667572374094601, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595107642193, 'プレビューと作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667595107642193-8772002442315415', 8772002442315415, 5667595107642193, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667620806371744, '言語タグ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667620806371744-8771982332401463', 8771982332401463, 5667620806371744, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771930947571421', 8771930947571421, 5667688633057075, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667695151549854-8771968624126325', 8771968624126325, 5667695151549854, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668629010554, '文字', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667668629010554-8771976361115614', 8771976361115614, 5667668629010554, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667630904547622, 'サブタグを検索…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667630904547622-8772015391400398', 8772015391400398, 5667630904547622, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680592269473, '変種', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667680592269473-8771923711808765', 8771923711808765, 5667680592269473, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639521899342, '1 件の変種を削除', 'ja', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639521899342-8772011217159086', 8772011217159086, 5667639521899342, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629146176193, '{count} 件の変種を削除', 'ja', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667629146176193-8771998528580369', 8771998528580369, 5667629146176193, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635203282018, 'アルファベット順', 'ja', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667635203282018-8772039352640020', 8772039352640020, 5667635203282018, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771966685762373', 8771966685762373, 5667688633057075, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645040737135-8772004481370898', 8772004481370898, 5667645040737135, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589459199969-8771912463566270', 8771912463566270, 5667589459199969, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579068168092-8771936602672507', 8771936602672507, 5667579068168092, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664079615083, 'マッピング済み', 'ja', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667664079615083-8771947211108180', 8771947211108180, 5667664079615083, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694062377766, '表現が見つかりません', 'ja', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694062377766-8771950851535873', 8771950851535873, 5667694062377766, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600188693356-8771957966582874', 8771957966582874, 5667600188693356, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667602001034739-8771934172254861', 8771934172254861, 5667602001034739, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697207154478, '選択をクリア', 'ja', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667697207154478-8771904155296746', 8771904155296746, 5667697207154478, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667651110958074, '新しい言語または変種を作成', 'ja', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667651110958074-8772010209718094', 8772010209718094, 5667651110958074, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638669500572, '一致する言語がありません', 'ja', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667638669500572-8771905467432581', 8771905467432581, 5667638669500572, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706191235415, '言語を検索…', 'ja', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667706191235415-8771957308068965', 8771957308068965, 5667706191235415, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667580023891022, 'ブラウザの推奨', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667580023891022-8771943861429001', 8771943861429001, 5667580023891022, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665763627933, 'LangMap の翻訳に協力する', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667665763627933-8771962203854555', 8771962203854555, 5667665763627933, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638669500572, '一致する言語がありません', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667638669500572-8771905467432581', 8771905467432581, 5667638669500572, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667652711662600, '最近使用した言語', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667652711662600-8772017158300851', 8772017158300851, 5667652711662600, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645040737135-8772004481370898', 8772004481370898, 5667645040737135, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771966685762373', 8771966685762373, 5667688633057075, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610322011774, '言語を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667610322011774-8771907230355366', 8771907230355366, 5667610322011774, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667682750135680, '言語が見つかりません', 'ja', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667682750135680-8772015486738705', 8772015486738705, 5667682750135680, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706191235415, '言語を検索…', 'ja', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667706191235415-8771957308068965', 8771957308068965, 5667706191235415, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639758204172, 'A–Z', 'ja', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639758204172-8771973400276236', 8771973400276236, 5667639758204172, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643967046884, '件数', 'ja', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667643967046884-8771994726877247', 8771994726877247, 5667643967046884, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619264481605, 'すべての言語の表現と関係を探索', 'ja', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667619264481605-8772027985468400', 8772027985468400, 5667619264481605, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771966685762373', 8771966685762373, 5667688633057075, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665665358673, 'アンカー', 'ja', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667665665358673-8771952725719815', 8771952725719815, 5667665665358673, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669126727841, '関係に戻る', 'ja', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667669126727841-8771984993053397', 8771984993053397, 5667669126727841, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694610067066, '{count} 言語', 'ja', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694610067066-8771995851022194', 8771995851022194, 5667694610067066, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579068168092-8771936602672507', 8771936602672507, 5667579068168092, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667684740105522, '関係メンバー', 'ja', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667684740105522-8771950928148051', 8771950928148051, 5667684740105522, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583805649822, 'この概念の地理的分布データはありません', 'ja', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667583805649822-8771989613412250', 8771989613412250, 5667583805649822, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647625900147, '{count} 地域', 'ja', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667647625900147-8772012470644251', 8772012470644251, 5667647625900147, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645152367454, '概念の分布', 'ja', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645152367454-8771918829802721', 8771918829802721, 5667645152367454, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657018994234, '追加して関係を作成', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667657018994234-8771969898159421', 8771969898159421, 5667657018994234, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657431263471, '表現を追加', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667657431263471-8772033519106127', 8772033519106127, 5667657431263471, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667689930205488, '表現を追加できませんでした', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667689930205488-8771908944297462', 8771908944297462, 5667689930205488, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590354595841, '追加中…', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667590354595841-8771928703559647', 8771928703559647, 5667590354595841, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667642644092467, '権威', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667642644092467-8772029059057248', 8772029059057248, 5667642644092467, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667607243147769, 'パンくず', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667607243147769-8772001620797917', 8772001620797917, 5667607243147769, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660409065919, 'クイック追加を閉じる', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667660409065919-8771978190877962', 8771978190877962, 5667660409065919, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657461770191, '関係を投稿', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667657461770191-8772005931944793', 8772005931944793, 5667657461770191, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658640639859, '直接関係', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667658640639859-8771956479287686', 8771956479287686, 5667658640639859, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629285692593, '表現と言語コードを入力してください', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667629285692593-8771956618196526', 8771956618196526, 5667629285692593, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667645040737135-8772028411030279', 8772028411030279, 5667645040737135, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629262680456, '表現を入力…', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667629262680456-8771952819511586', 8771952819511586, 5667629262680456, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667598153216873, 'グラフ', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667598153216873-8771971766539087', 8771971766539087, 5667598153216873, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639456493742, 'ホーム', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639456493742-8771987694898855', 8771987694898855, 5667639456493742, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582865883104, 'ホップ数', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667582865883104-8771987564932373', 8771987564932373, 5667582865883104, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667614219015040, '間接', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667614219015040-8772028520330484', 8772028520330484, 5667614219015040, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697302661086, '言語コード', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667697302661086-8771920539132885', 8771920539132885, 5667697302661086, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667592694812107, '例：en / cmn-Hant', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667592694812107-8772027619502019', 8772027619502019, 5667592694812107, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667692412114179, 'リスト', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667692412114179-8771992537520761', 8771992537520761, 5667692412114179, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667579068168092-8771936602672507', 8771936602672507, 5667579068168092, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669647114617, '関係セット', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667669647114617-8772011172535505', 8772011172535505, 5667669647114617, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699953258741, 'まだ関係がありません', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667699953258741-8772036040577861', 8772036040577861, 5667699953258741, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663308019802, '任意', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667663308019802-8771986434294618', 8771986434294618, 5667663308019802, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667627843783666, '表現をすばやく追加', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667627843783666-8772035320845087', 8772035320845087, 5667627843783666, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699921826826, '表現を追加し、現在の表現に直接マップします。', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667699921826826-8771923205204397', 8771923205204397, 5667699921826826, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667695151549854-8771968624126325', 8771968624126325, 5667695151549854, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593348696707, 'ユーザー', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667593348696707-8772034803281550', 8772034803281550, 5667593348696707, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668313793424, 'この概念を地図で表示', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667668313793424-8772021818623523', 8772021818623523, 5667668313793424, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619578096162, 'メニューを閉じる', 'ja', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667619578096162-8772008345770010', 8772008345770010, 5667619578096162, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572724542352, '貢献', 'ja', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667572724542352-8772022393103823', 8772022393103823, 5667572724542352, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705114884036, 'ハンドブック', 'ja', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667705114884036-8771945183617329', 8771945183617329, 5667705114884036, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639456493742, 'ホーム', 'ja', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667639456493742-8771987694898855', 8771987694898855, 5667639456493742, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667688633057075-8771966685762373', 8771966685762373, 5667688633057075, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667613981738673, 'メニュー', 'ja', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667613981738673-8771933905283078', 8771933905283078, 5667613981738673, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631886926617, 'メニューを開く', 'ja', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667631886926617-8771988489117883', 8771988489117883, 5667631886926617, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667653472473278, '表現を検索', 'ja', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667653472473278-8772000153561666', 8772000153561666, 5667653472473278, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667637138127513, 'ログイン', 'ja', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667637138127513-8771985319534907', 8771985319534907, 5667637138127513, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667685914767722, 'ログアウト', 'ja', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667685914767722-8771987956311474', 8771987956311474, 5667685914767722, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683549604550, '検索を実行', 'ja', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667683549604550-8772033727162136', 8772033727162136, 5667683549604550, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669084658122, 'インターフェース言語を切り替え', 'ja', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667669084658122-8771905685377287', 8771905685377287, 5667669084658122, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635203282018, 'アルファベット順', 'ja', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667635203282018-8772039352640020', 8772039352640020, 5667635203282018, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694022710483, 'ヒント：現在の検索は表現テキストに一致します。意味検索は後日提供予定です。', 'ja', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694022710483-8771909635790690', 8771909635790690, 5667694022710483, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705487484089, '検索に失敗しました', 'ja', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667705487484089-8771929026122151', 8771929026122151, 5667705487484089, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589459199969-8771912463566270', 8771912463566270, 5667589459199969, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677682108323, '結果が見つかりません', 'ja', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667677682108323-8771927555767000', 8771927555767000, 5667677682108323, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667602001034739-8771934172254861', 8771934172254861, 5667602001034739, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667600188693356-8771957966582874', 8771957966582874, 5667600188693356, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667698386206722, '{count} 件の結果', 'ja', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667698386206722-8772014433488480', 8772014433488480, 5667698386206722, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667570617145113, '並び替え', 'ja', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667570617145113-8772001210440828', 8772001210440828, 5667570617145113, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667653472473278, '表現を検索', 'ja', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667653472473278-8772000153561666', 8772000153561666, 5667653472473278, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694457332178, '翻訳する言語を追加', 'ja', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667694457332178-8771973106595188', 8771973106595188, 5667694457332178, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572450753410, '{count} 件の翻訳を送信', 'ja', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667572450753410-8771943172288619', 8771943172288619, 5667572450753410, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669168742844, '現在の翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667669168742844-8771982470884397', 8771982470884397, 5667669168742844, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622430523750, '登録済みの言語を選択', 'ja', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667622430523750-8772018182873778', 8772018182873778, 5667622430523750, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596433518312, '翻訳カバレッジ', 'ja', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667596433518312-8772013113555302', 8772013113555302, 5667596433518312, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582116133995, '{count} 件表示', 'ja', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667582116133995-8772040929892299', 8772040929892299, 5667582116133995, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622341490826, 'コミュニティ翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667622341490826-8771973543137726', 8771973543137726, 5667622341490826, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667654375948093, '翻訳を入力…', 'ja', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667654375948093-8771990724594742', 8771990724594742, 5667654375948093, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596830065687, '翻訳ワークベンチを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667596830065687-8771920552784072', 8771920552784072, 5667596830065687, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680432488224, '読み込み中…', 'ja', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667680432488224-8771908386278726', 8771908386278726, 5667680432488224, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667640575561994, '対象言語', 'ja', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667640575561994-8771996866079300', 8771996866079300, 5667640575561994, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667696289522144, '言語リストを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667696289522144-8771965827772292', 8771965827772292, 5667696289522144, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619093799340, 'ログインして翻訳を送信。候補は関係スコアで選択され、適切な候補がない場合はフォールバックが使用されます。', 'ja', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667619093799340-8771995706904988', 8771995706904988, 5667619093799340, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667608258291644, '一致するテキストが見つかりません。', 'ja', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667608258291644-8771904910396271', 8771904910396271, 5667608258291644, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638050451361, 'プレビュー', 'ja', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667638050451361-8771969689937165', 8771969689937165, 5667638050451361, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667616238195236, '参照言語', 'ja', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667616238195236-8772009963987850', 8772009963987850, 5667616238195236, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667640926848452, 'キーまたは原文を検索…', 'ja', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667640926848452-8771962647026930', 8771962647026930, 5667640926848452, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667661382849748, '翻訳言語を選択', 'ja', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667661382849748-8772037474898823', 8772037474898823, 5667661382849748, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668513784419, '英語原文', 'ja', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667668513784419-8772014752541923', 8772014752541923, 5667668513784419, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665467367352, '開始', 'ja', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667665467367352-8772036201600543', 8772036201600543, 5667665467367352, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589757005077, '送信に失敗しました', 'ja', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589757005077-8771930781451254', 8771930781451254, 5667589757005077, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589821787306, '関係を送信', 'ja', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667589821787306-8771938026129323', 8771938026129323, 5667589821787306, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667685993114428, '送信済み', 'ja', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667685993114428-8771906650908176', 8771906650908176, 5667685993114428, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572173092342, 'LangMap のインターフェース文言を自然で使いやすくするお手伝いをします。', 'ja', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667572173092342-8771968758684575', 8771968758684575, 5667572173092342, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667649130183263, '翻訳ワークベンチ', 'ja', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667649130183263-8772002773137414', 8772002773137414, 5667649130183263, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623919646098, '{key} を翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667623919646098-8771936438281310', 8771936438281310, 5667623919646098, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667601406170839, '翻訳済み', 'ja', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667601406170839-8771916786083827', 8771916786083827, 5667601406170839, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667601297578574, '翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667601297578574-8771951513286657', 8771951513286657, 5667601297578574, 0, 'ui_i18n');

-- Done