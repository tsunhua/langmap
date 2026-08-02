-- Generated managed system UI translation bundle
-- Project: langmap-web
-- Ownership scope: managed-system-ui

-- 1. Upsert locale metadata
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

-- Locale zh-Hans
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'zh-Hans', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'zh-Hans'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale zh-Hant
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'zh-Hant', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'zh-Hant'
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
VALUES (8771919700012927, 'e.g. en / zh-Hant', 'en', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.languageCodePlaceholder', 8771919700012927, '[]', '8771919700012927', 'active');

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
VALUES (682798659849548, 'ej. en / zh-Hant', 'es', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798659849548-8771919700012927', 8771919700012927, 682798659849548, 0, 'ui_i18n');

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
VALUES (5667657482722815, '例：en / zh-Hant', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5667657482722815-8771919700012927', 8771919700012927, 5667657482722815, 0, 'ui_i18n');

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

-- Locale zh-Hans
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642115394617474, '邮箱', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642115394617474-8771988929111883', 8771988929111883, 6642115394617474, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102074594911, '已有账号？', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642102074594911-8771987324928109', 8771987324928109, 6642102074594911, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025328564659, '登录', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642025328564659-8771985319534907', 8771985319534907, 6642025328564659, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642096269746521, '还没有账号？', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642096269746521-8771920874847316', 8771920874847316, 6642096269746521, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113949694275, '操作失败', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642113949694275-8771934955742921', 8771934955742921, 6642113949694275, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642014231965307, '密码', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642014231965307-8771993838728081', 8771993838728081, 6642014231965307, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089509849650, '处理中…', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089509849650-8772001046060388', 8772001046060388, 6642089509849650, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078250363025, '创建账号', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642078250363025-8771964374844751', 8771964374844751, 6642078250363025, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642114707359363, '用户名', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642114707359363-8772029311767367', 8772029311767367, 6642114707359363, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143445594122, '取消', 'zh-Hans', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642143445594122-8772001703307290', 8772001703307290, 6642143445594122, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136428173818, '关闭', 'zh-Hans', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642136428173818-8771958345505312', 8771958345505312, 6642136428173818, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771930947571421', 8771930947571421, 6642127179293910, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771966685762373', 8771966685762373, 6642127179293910, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131738404901, '加载中…', 'zh-Hans', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642131738404901-8771908386278726', 8771908386278726, 6642131738404901, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051158517347, '搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642051158517347-8772018337291447', 8772018337291447, 6642051158517347, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058290789573, '提交', 'zh-Hans', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642058290789573-8771955384790296', 8771955384790296, 6642058290789573, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642093757102008, '实际尺寸 100%', 'zh-Hans', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642093757102008-8771913559728006', 8771913559728006, 6642093757102008, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642069319013468, '匿名', 'zh-Hans', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642069319013468-8771963881461252', 8771963881461252, 6642069319013468, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081156745026, '{count} 个子节点；点击收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642081156745026-8772032837909466', 8772032837909466, 6642081156745026, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136322982617, '每条边皆为可投票的独立直接映射；低分映射自动收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642136322982617-8772028933737015', 8772028933737015, 6642136322982617, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148139512311, '待建立的映射图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642148139512311-8771990687804642', 8771990687804642, 6642148139512311, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642098157573679, '关闭信息面板', 'zh-Hans', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642098157573679-8771923580873788', 8771923580873788, 6642098157573679, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026681083988, '收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642026681083988-8772025115555117', 8772025115555117, 6642026681083988, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144285961115, '收起子分支', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642144285961115-8772021975712328', 8772021975712328, 6642144285961115, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642134677943425, '收起至第一层', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642134677943425-8771963062101045', 8771963062101045, 6642134677943425, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077642286612, '{count} 天前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642077642286612-8772016085305408', 8772016085305408, 6642077642286612, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137331510936, '深度 {depth}', 'zh-Hans', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642137331510936-8772018587383663', 8772018587383663, 6642137331510936, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113422439800, '直接映射词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642113422439800-8771921679343522', 8771921679343522, 6642113422439800, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058278029947, '踩', 'zh-Hans', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642058278029947-8771992127181974', 8771992127181974, 6642058278029947, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024565818150, '{count} 条边', 'zh-Hans', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024565818150-8771907018302878', 8771907018302878, 6642024565818150, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051204031784, '暂无数据', 'zh-Hans', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642051204031784-8772000424294921', 8772000424294921, 6642051204031784, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642109708261394, '退出全屏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642109708261394-8771995527490116', 8771995527490116, 6642109708261394, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016577311844, '展开', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016577311844-8771957005515059', 8771957005515059, 6642016577311844, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642094381681236, '全部展开', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642094381681236-8772033758268399', 8772033758268399, 6642094381681236, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040580204486, '展开子分支', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642040580204486-8771937729949713', 8771937729949713, 6642040580204486, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642125838566529-8772028411030279', 8772028411030279, 6642125838566529, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642049411049930, '筛选语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642049411049930-8771975185705787', 8771975185705787, 6642049411049930, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046664136497, '全屏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642046664136497-8771984311379866', 8771984311379866, 6642046664136497, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095937214170, '词句映射图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642095937214170-8771940176065576', 8771940176065576, 6642095937214170, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642092079493598, '加载图谱…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642092079493598-8771930916265390', 8771930916265390, 6642092079493598, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642121746906592, '图谱模式', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642121746906592-8772018055755937', 8772018055755937, 6642121746906592, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020706137208, '{nodes} 个映射节点 · {edges} 个关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642020706137208-8771930566920504', 8771930566920504, 6642020706137208, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642114642039717, '图谱工具栏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642114642039717-8771957995007293', 8771957995007293, 6642114642039717, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642035482337645, '映射层级列表', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642035482337645-8771972530005685', 8771972530005685, 6642035482337645, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033539062759, '跳数', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642033539062759-8771929108158859', 8771929108158859, 6642033539062759, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642101204301710, '{count} 小时前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642101204301710-8771972038859703', 8771972038859703, 6642101204301710, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122446194080, '刚刚', 'zh-Hans', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642122446194080-8772006156641051', 8772006156641051, 6642122446194080, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142757289698, '无法加载语言', 'zh-Hans', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642142757289698-8771907230355366', 8771907230355366, 6642142757289698, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642083768771338, '列表模式', 'zh-Hans', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642083768771338-8771978209325624', 8771978209325624, 6642083768771338, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642080789784466, '加载更多', 'zh-Hans', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642080789784466-8771968298248581', 8771968298248581, 6642080789784466, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642115400582522, '加载相关词句中', 'zh-Hans', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642115400582522-8771918922470710', 8771918922470710, 6642115400582522, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642048832804695, '映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642048832804695-8772009894682686', 8772009894682686, 6642048832804695, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148017508724, '映射评分', 'zh-Hans', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642148017508724-8772001613332908', 8772001613332908, 6642148017508724, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020836809391, '{count} 分钟前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642020836809391-8772029891163450', 8772029891163450, 6642020836809391, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642073609319436, '更多操作', 'zh-Hans', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642073609319436-8771927265880728', 8771927265880728, 6642073609319436, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642047064277754, '完整图谱中还有 {count} 个映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642047064277754-8771978296601845', 8771978296601845, 6642047064277754, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023906701874, '暂无直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642023906701874-8771916846886490', 8771916846886490, 6642023906701874, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034057783920, '找不到相符词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642034057783920-8771950851535873', 8771950851535873, 6642034057783920, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642045880832635, '{count} 个节点', 'zh-Hans', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642045880832635-8771915754603204', 8771915754603204, 6642045880832635, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642130634261447, '节点信息', 'zh-Hans', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642130634261447-8772032217763299', 8772032217763299, 6642130634261447, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113056048464, '其他关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642113056048464-8772011775552074', 8772011775552074, 6642113056048464, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018575302917, '相关词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642018575302917-8771996275317129', 8771996275317129, 6642018575302917, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144339670355, '{count} 个关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642144339670355-8771905570354775', 8771905570354775, 6642144339670355, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020053484063, '移除 {code}', 'zh-Hans', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642020053484063-8771968148353493', 8771968148353493, 6642020053484063, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089969828414, '重置布局', 'zh-Hans', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089969828414-8771923590138278', 8771923590138278, 6642089969828414, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032494514795, '根节点', 'zh-Hans', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642032494514795-8771991096471187', 8771991096471187, 6642032494514795, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051158517347, '搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642051158517347-8772018337291447', 8772018337291447, 6642051158517347, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044272242935-8771934172254861', 8771934172254861, 6642044272242935, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144962215817, '搜索中…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642144962215817-8771951969125148', 8771951969125148, 6642144962215817, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082865271552, '在图谱中选取节点以查看详情', 'zh-Hans', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642082865271552-8771969317410200', 8771969317410200, 6642082865271552, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642027042531887, '来源路径', 'zh-Hans', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642027042531887-8771977750841844', 8771977750841844, 6642027042531887, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112924811804, '赞', 'zh-Hans', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642112924811804-8772016238570208', 8772016238570208, 6642112924811804, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642119087582119, '查看词句详情', 'zh-Hans', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642119087582119-8771995720429284', 8771995720429284, 6642119087582119, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642047216674511, '投票失败，已撤销', 'zh-Hans', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642047216674511-8772020751025198', 8772020751025198, 6642047216674511, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079482068498, '放大', 'zh-Hans', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642079482068498-8772017398603959', 8772017398603959, 6642079482068498, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025294874845, '缩小', 'zh-Hans', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642025294874845-8772017289371875', 8772017289371875, 6642025294874845, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032444616585, '+ 添加词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642032444616585-8771945073983212', 8771945073983212, 6642032444616585, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642090723137487, '完全图', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642090723137487-8771921254303111', 8771921254303111, 6642090723137487, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023218325140, '删除', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642023218325140-8771944300238713', 8771944300238713, 6642023218325140, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112916184041, '{count} 个直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642112916184041-8771968945113345', 8771968945113345, 6642112916184041, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642125838566529-8772028411030279', 8772028411030279, 6642125838566529, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077404263859, '{count} 个词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642077404263859-8771918589046163', 8771918589046163, 6642077404263859, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146499129342, '输入词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642146499129342-8771975160452098', 8771975160452098, 6642146499129342, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771930947571421', 8771930947571421, 6642127179293910, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642133003804814, '提交一组含义相同的词句。系统会在每对之间创建直接映射。已有词句会自动关联，不会产生重复。', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642133003804814-8771938370927027', 8771938370927027, 6642133003804814, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108029963380, '至少需要 2 行，每行需填写语言和词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642108029963380-8771996574983759', 8771996574983759, 6642108029963380, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058290789573, '提交', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642058290789573-8771955384790296', 8771955384790296, 6642058290789573, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642021851191783, '提交失败', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642021851191783-8771930781451254', 8771930781451254, 6642021851191783, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015225216700, '提交中…', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642015225216700-8771996654725718', 8771996654725718, 6642015225216700, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120556679091, '标签', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120556679091-8772023049338365', 8772023049338365, 6642120556679091, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112039287404, '批量提交', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642112039287404-8771967116778370', 8771967116778370, 6642112039287404, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642123463387947, '返回首页', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642123463387947-8771954914944651', 8771954914944651, 6642123463387947, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016061835830-8771936602672507', 8771936602672507, 6642016061835830, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642036250957195, '页面未找到', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642036250957195-8771958158698832', 8771958158698832, 6642036250957195, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120627731577, '全部', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120627731577-8771912696777795', 8771912696777795, 6642120627731577, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142087711870, '提交映射 →', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642142087711870-8771952067596101', 8771952067596101, 6642142087711870, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024763942113-8771957966582874', 8771957966582874, 6642024763942113, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642064903439913, '映射 + 新词句', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642064903439913-8771971172552785', 8771971172552785, 6642064903439913, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082464782703, '找不到所需内容？', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642082464782703-8771964553678580', 8771964553678580, 6642082464782703, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033927307089, '新贡献', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642033927307089-8772013263074963', 8772013263074963, 6642033927307089, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642031639316449-8771912463566270', 8771912463566270, 6642031639316449, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642123269157666, '热门映射', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642123269157666-8771956320455891', 8771956320455891, 6642123269157666, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079566674863, '按评分 · 本周', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642079566674863-8772001941683119', 8772001941683119, 6642079566674863, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089022254142, '语义图的最新脉动——热门映射和新贡献。', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089022254142-8771985464043467', 8771985464043467, 6642089022254142, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642036622561096, '动态', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642036622561096-8771928668652497', 8771928668652497, 6642036622561096, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146271976254, '新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642146271976254-8772033519106127', 8772033519106127, 6642146271976254, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642068844191895, '新增章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642068844191895-8772013343930223', 8772013343930223, 6642068844191895, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642129843359201, '手册列表', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642129843359201-8771985524903836', 8771985524903836, 6642129843359201, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642149580848149, '第 {number} 章', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642149580848149-8771974942670538', 8771974942670538, 6642149580848149, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079167950557, '关闭词句信息', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642079167950557-8771948835977551', 8771948835977551, 6642079167950557, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026681083988, '收起', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642026681083988-8772025115555117', 8772025115555117, 6642026681083988, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016726918845, '删除章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016726918845-8771922363562335', 8771922363562335, 6642016726918845, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120031672278, '编辑手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120031672278-8771954520730023', 8771954520730023, 6642120031672278, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642017881713043, '词句信息', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642017881713043-8771958749403912', 8771958749403912, 6642017881713043, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089671840441, '词句的语言、地区和来源将显示在此处。', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089671840441-8771969048222271', 8771969048222271, 6642089671840441, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642103882805595, '这本手册有帮助吗？', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642103882805595-8771919030282571', 8771919030282571, 6642103882805595, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642059059264353, '无法加载词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642059059264353-8772001956145712', 8772001956145712, 6642059059264353, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016061835830-8771936602672507', 8771936602672507, 6642016061835830, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771930947571421', 8771930947571421, 6642127179293910, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642074108692098, '下移', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642074108692098-8772015839426216', 8772015839426216, 6642074108692098, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642066192585677, '下移章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642066192585677-8771974741123489', 8771974741123489, 6642066192585677, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642106328121191, '上移章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642106328121191-8771974343227837', 8771974343227837, 6642106328121191, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642059981534711, '上移', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642059981534711-8772035822327586', 8772035822327586, 6642059981534711, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105608384820, '私密', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642105608384820-8771981388316157', 8771981388316157, 6642105608384820, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084554365996, '公开', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642084554365996-8771978356150928', 8771978356150928, 6642084554365996, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642130808412435, '发布', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642130808412435-8771952311782197', 8771952311782197, 6642130808412435, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642091608036792-8771968624126325', 8771968624126325, 6642091608036792, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642076383493944, '无法加载相关词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642076383493944-8771991960796854', 8771991960796854, 6642076383493944, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058950257396, '移除 {text}', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642058950257396-8771948377233166', 8771948377233166, 6642058950257396, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642085065100565, '保存草稿', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642085065100565-8771974360984879', 8771974360984879, 6642085065100565, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131092186881, '保存中…', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642131092186881-8771980391249065', 8771980391249065, 6642131092186881, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642117391976558, '章节标题', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642117391976558-8771935521942479', 8771935521942479, 6642117391976558, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061309253725, '选择词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642061309253725-8771975315975664', 8771975315975664, 6642061309253725, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642138719738336, '来源', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642138719738336-8771933750484319', 8771933750484319, 6642138719738336, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063327100543, 'AI', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642063327100543-8771954789056127', 8771954789056127, 6642063327100543, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061587133200, '权威', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642061587133200-8772029059057248', 8772029059057248, 6642061587133200, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041095383372, '用户', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642041095383372-8772034803281550', 8772034803281550, 6642041095383372, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137208020458, '手册标题', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642137208020458-8771918701696347', 8771918701696347, 6642137208020458, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144354228922, '目录', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642144354228922-8771915172364840', 8771915172364840, 6642144354228922, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642103018624855, '查看完整关系图', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642103018624855-8771928949232797', 8771928949232797, 6642103018624855, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040432719166, '可见性', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642040432719166-8772029984927123', 8772029984927123, 6642040432719166, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020871996867, '新建手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642020871996867-8771984354571011', 8771984354571011, 6642020871996867, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033196167965, '加载手册失败', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642033196167965-8771915400044673', 8771915400044673, 6642033196167965, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642031639316449-8771912463566270', 8771912463566270, 6642031639316449, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023539860358, '未找到手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642023539860358-8772007530341875', 8772007530341875, 6642023539860358, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024763942113-8771957966582874', 8771957966582874, 6642024763942113, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642076270761945, '搜索手册…', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642076270761945-8772031472567985', 8772031472567985, 6642076270761945, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084896787549, '章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642084896787549-8771981869623564', 8771981869623564, 6642084896787549, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139377956737, '手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642139377956737-8771945183617329', 8771945183617329, 6642139377956737, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642132908422039, '上一步', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642132908422039-8772024038803789', 8772024038803789, 6642132908422039, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143445594122, '取消', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642143445594122-8772001703307290', 8772001703307290, 6642143445594122, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136428173818, '关闭', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642136428173818-8771958345505312', 8771958345505312, 6642136428173818, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070594191434, '创建语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642070594191434-8771972155504688', 8771972155504688, 6642070594191434, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046987427796, '语言创建失败', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642046987427796-8772008975730714', 8772008975730714, 6642046987427796, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077011999346, '创建中…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642077011999346-8771943301451236', 8771943301451236, 6642077011999346, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642052793160795, '请输入描述', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642052793160795-8771986788835322', 8771986788835322, 6642052793160795, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084343241388, '请选择 Glottolog 匹配或选择「无匹配」', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642084343241388-8771982145239141', 8771982145239141, 6642084343241388, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642055065295298, '请输入语言名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642055065295298-8771921060819264', 8771921060819264, 6642055065295298, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016949865552, '请选择仅限社区创建的原因', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016949865552-8771926836463632', 8771926836463632, 6642016949865552, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038163745702, '请输入语言子标签以继续', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642038163745702-8772026576042326', 8772026576042326, 6642038163745702, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025339739296, '找到 {count} 个候选', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642025339739296-8771956461019812', 8771956461019812, 6642025339739296, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120727006638, '选择匹配或标明无合适条目', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120727006638-8772033726980358', 8772033726980358, 6642120727006638, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023985409425, '匹配此候选', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642023985409425-8772036217067472', 8772036217067472, 6642023985409425, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642052762136868, '方言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642052762136868-8771959645210043', 8771959645210043, 6642052762136868, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771953851734414', 8771953851734414, 6642127179293910, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642050171564997, 'Glottolog 无合适条目', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642050171564997-8771907658003091', 8771907658003091, 6642050171564997, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105186652319, '搜索 Glottolog…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642105186652319-8771972676692740', 8771972676692740, 6642105186652319, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046720550534, '描述', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642046720550534-8771937301075282', 8771937301075282, 6642046720550534, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642049405854148, '描述此语言或变体…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642049405854148-8771929062150956', 8771929062150956, 6642049405854148, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137962924117, '名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642137962924117-8771913536651859', 8771913536651859, 6642137962924117, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024820877303, '英文名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024820877303-8772035648862723', 8772035648862723, 6642024820877303, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063252370902, '为何此语言未收录于 Glottolog？', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642063252370902-8771965397553798', 8771965397553798, 6642063252370902, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642045651765669, '社区特定用法', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642045651765669-8772029121364869', 8772029121364869, 6642045651765669, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139336329733, '新兴变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642139336329733-8771911763851130', 8771911763851130, 6642139336329733, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087125625219, 'Glottolog 未收录', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642087125625219-8772027448793331', 8772027448793331, 6642087125625219, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108110491018, '其他', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642108110491018-8771907717721822', 8771907717721822, 6642108110491018, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642066511159489, '选择原因…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642066511159489-8771908744199257', 8771908744199257, 6642066511159489, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642101084801619, '下一步', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642101084801619-8771946058185965', 8771946058185965, 6642101084801619, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642126523931480, '规范代码', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642126523931480-8771986283559204', 8771986283559204, 6642126523931480, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024076651823, '此语言已存在', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024076651823-8771963047592058', 8771963047592058, 6642024076651823, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034504555609, '使用现有语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642034504555609-8771911987565882', 8771911987565882, 6642034504555609, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070594191434, '创建语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642070594191434-8771972155504688', 8771972155504688, 6642070594191434, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046820247981, '警告', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642046820247981-8771976682274382', 8771976682274382, 6642046820247981, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044276832399, '临时标签', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044276832399-8771969301691665', 8771969301691665, 6642044276832399, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058528862255, 'Glottolog 匹配', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642058528862255-8771926452848847', 8771926452848847, 6642058528862255, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122397167053, '元数据', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642122397167053-8771988865126091', 8771988865126091, 6642122397167053, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642030876337248, '预览并创建', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642030876337248-8772002442315415', 8772002442315415, 6642030876337248, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137488696731, '语言标签', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642137488696731-8771982332401463', 8771982332401463, 6642137488696731, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771930947571421', 8771930947571421, 6642127179293910, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642091608036792-8771968624126325', 8771968624126325, 6642091608036792, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642110809127034, '文字', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642110809127034-8771976361115614', 8771976361115614, 6642110809127034, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026181148121, '搜索子标签…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642026181148121-8772015391400398', 8772015391400398, 6642026181148121, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642140869802494, '变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642140869802494-8771923711808765', 8771923711808765, 6642140869802494, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642054716608916, '已移除 1 个变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642054716608916-8772011217159086', 8772011217159086, 6642054716608916, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040221301703, '已移除 {count} 个变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642040221301703-8771998528580369', 8771998528580369, 6642040221301703, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032967744603, '按字母排序', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642032967744603-8772039352640020', 8772039352640020, 6642032967744603, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771966685762373', 8771966685762373, 6642127179293910, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642125838566529-8772004481370898', 8772004481370898, 6642125838566529, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642031639316449-8771912463566270', 8771912463566270, 6642031639316449, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016061835830-8771936602672507', 8771936602672507, 6642016061835830, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642086477397993, '已映射', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642086477397993-8771947211108180', 8771947211108180, 6642086477397993, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105878513476, '没有找到词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642105878513476-8771950851535873', 8771950851535873, 6642105878513476, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024763942113-8771957966582874', 8771957966582874, 6642024763942113, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044272242935-8771934172254861', 8771934172254861, 6642044272242935, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139140342272, '清除选择', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642139140342272-8771904155296746', 8771904155296746, 6642139140342272, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642057028286585, '创建新语言或变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642057028286585-8772010209718094', 8772010209718094, 6642057028286585, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148268882398, '无匹配语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642148268882398-8771905467432581', 8771905467432581, 6642148268882398, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038379665728, '搜索语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642038379665728-8771957308068965', 8771957308068965, 6642038379665728, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018197473222, '浏览器推荐', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642018197473222-8771943861429001', 8771943861429001, 6642018197473222, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642119964408799, '协助翻译 LangMap', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642119964408799-8771962203854555', 8771962203854555, 6642119964408799, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095251982521, '无匹配的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642095251982521-8771905467432581', 8771905467432581, 6642095251982521, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642106571402574, '最近使用的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642106571402574-8772017158300851', 8772017158300851, 6642106571402574, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642125838566529-8772004481370898', 8772004481370898, 6642125838566529, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771966685762373', 8771966685762373, 6642127179293910, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142757289698, '无法加载语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642142757289698-8771907230355366', 8771907230355366, 6642142757289698, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642110583821426, '未找到语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642110583821426-8772015486738705', 8772015486738705, 6642110583821426, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038379665728, '搜索语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642038379665728-8771957308068965', 8771957308068965, 6642038379665728, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081938320652, 'A–Z', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642081938320652-8771973400276236', 8771973400276236, 6642081938320652, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063274395674, '按数量', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642063274395674-8771994726877247', 8771994726877247, 6642063274395674, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112162477357, '浏览所有语言的词句与映射', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642112162477357-8772027985468400', 8772027985468400, 6642112162477357, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771966685762373', 8771966685762373, 6642127179293910, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120418342147, '锚点', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120418342147-8771952725719815', 8771952725719815, 6642120418342147, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033838363498, '返回映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642033838363498-8771984993053397', 8771984993053397, 6642033838363498, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642053565881172, '{count} 种语言', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642053565881172-8771995851022194', 8771995851022194, 6642053565881172, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016061835830-8771936602672507', 8771936602672507, 6642016061835830, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041400872994, '映射成员', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642041400872994-8771950928148051', 8771950928148051, 6642041400872994, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642097480840147, '此概念无地理分布数据', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642097480840147-8771989613412250', 8771989613412250, 6642097480840147, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081474362540, '{count} 个地区', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642081474362540-8772012470644251', 8772012470644251, 6642081474362540, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063197943086, '概念分布', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642063197943086-8771918829802721', 8771918829802721, 6642063197943086, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139064776557, '新增并建立映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642139064776557-8771969898159421', 8771969898159421, 6642139064776557, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146271976254, '新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642146271976254-8772033519106127', 8772033519106127, 6642146271976254, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038106021388, '无法新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642038106021388-8771908944297462', 8771908944297462, 6642038106021388, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078859997912, '新增中…', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642078859997912-8771928703559647', 8771928703559647, 6642078859997912, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061587133200, '权威', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642061587133200-8772029059057248', 8772029059057248, 6642061587133200, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143306286453, '面包屑', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642143306286453-8772001620797917', 8772001620797917, 6642143306286453, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108084805350, '关闭快速新增', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642108084805350-8771978190877962', 8771978190877962, 6642108084805350, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082249122029, '贡献映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642082249122029-8772005931944793', 8772005931944793, 6642082249122029, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046012797754, '直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642046012797754-8771956479287686', 8771956479287686, 6642046012797754, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642138688523942, '请输入词句与语言代码', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642138688523942-8771956618196526', 8771956618196526, 6642138688523942, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642125838566529-8772028411030279', 8772028411030279, 6642125838566529, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146499129342, '输入词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642146499129342-8771952819511586', 8771952819511586, 6642146499129342, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051864182420, '图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642051864182420-8771971766539087', 8771971766539087, 6642051864182420, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015883011005, '首页', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642015883011005-8771987694898855', 8771987694898855, 6642015883011005, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033539062759, '跳数', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642033539062759-8771987564932373', 8771987564932373, 6642033539062759, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040169873857, '间接', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642040169873857-8772028520330484', 8772028520330484, 6642040169873857, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018819739950, '语言代码', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642018819739950-8771920539132885', 8771920539132885, 6642018819739950, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642043949420875, '例如 en / zh-Hant', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642043949420875-8771919700012927', 8771919700012927, 6642043949420875, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102582852781, '列表', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642102582852781-8771992537520761', 8771992537520761, 6642102582852781, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642016061835830-8771936602672507', 8771936602672507, 6642016061835830, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070273407584, '映射集合', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642070273407584-8772011172535505', 8772011172535505, 6642070273407584, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089640514854, '尚无映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089640514854-8772036040577861', 8772036040577861, 6642089640514854, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079479919457, '选填', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642079479919457-8771986434294618', 8771986434294618, 6642079479919457, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642050127998894, '快速新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642050127998894-8772035320845087', 8772035320845087, 6642050127998894, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642062338381818, '新增词句并直接映射到当前词句。', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642062338381818-8771923205204397', 8771923205204397, 6642062338381818, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642091608036792-8771968624126325', 8771968624126325, 6642091608036792, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041095383372, '用户', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642041095383372-8772034803281550', 8772034803281550, 6642041095383372, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642116726950390, '在地图上查看此概念', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642116726950390-8772021818623523', 8772021818623523, 6642116726950390, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041505540305, '关闭菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642041505540305-8772008345770010', 8772008345770010, 6642041505540305, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131528409502, '贡献', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642131528409502-8772022393103823', 8772022393103823, 6642131528409502, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139377956737, '手册', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642139377956737-8771945183617329', 8771945183617329, 6642139377956737, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015883011005, '首页', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642015883011005-8771987694898855', 8771987694898855, 6642015883011005, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127179293910-8771966685762373', 8771966685762373, 6642127179293910, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642140394109144, '菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642140394109144-8771933905283078', 8771933905283078, 6642140394109144, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018926883882, '打开菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642018926883882-8771988489117883', 8771988489117883, 6642018926883882, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089756820891, '搜索词句', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089756820891-8772000153561666', 8772000153561666, 6642089756820891, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025328564659, '登录', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642025328564659-8771985319534907', 8771985319534907, 6642025328564659, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105006227901, '退出登录', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642105006227901-8771987956311474', 8771987956311474, 6642105006227901, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148011577706, '提交搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642148011577706-8772033727162136', 8772033727162136, 6642148011577706, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642096036980072, '切换界面语言', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642096036980072-8771905685377287', 8771905685377287, 6642096036980072, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044961162962, '按字母顺序', 'zh-Hans', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044961162962-8772039352640020', 8772039352640020, 6642044961162962, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077284734470, '提示：目前搜索匹配词句原文。翻译（语义）搜索即将推出。', 'zh-Hans', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642077284734470-8771909635790690', 8771909635790690, 6642077284734470, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642073469225317, '搜索失败', 'zh-Hans', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642073469225317-8771929026122151', 8771929026122151, 6642073469225317, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642031639316449-8771912463566270', 8771912463566270, 6642031639316449, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122973189618, '未找到结果', 'zh-Hans', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642122973189618-8771927555767000', 8771927555767000, 6642122973189618, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044272242935-8771934172254861', 8771934172254861, 6642044272242935, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642024763942113-8771957966582874', 8771957966582874, 6642024763942113, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642074798271187, '{count} 个结果', 'zh-Hans', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642074798271187-8772014433488480', 8772014433488480, 6642074798271187, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034968095778, '排序', 'zh-Hans', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642034968095778-8772001210440828', 8772001210440828, 6642034968095778, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089756820891, '搜索词句', 'zh-Hans', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642089756820891-8772000153561666', 8772000153561666, 6642089756820891, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642128338521838, '添加要翻译的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642128338521838-8771973106595188', 8771973106595188, 6642128338521838, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642086455717671, '提交 {count} 条翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642086455717671-8771943172288619', 8771943172288619, 6642086455717671, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087702866407, '当前翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642087702866407-8771982470884397', 8771982470884397, 6642087702866407, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031484495695, '选择已注册的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642031484495695-8772018182873778', 8772018182873778, 6642031484495695, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044267925848, '翻译覆盖率', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044267925848-8772013113555302', 8772013113555302, 6642044267925848, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642132218759146, '显示 {count} 条', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642132218759146-8772040929892299', 8772040929892299, 6642132218759146, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642062953991429, '社区本地化', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642062953991429-8771973543137726', 8771973543137726, 6642062953991429, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063470327339, '输入翻译…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642063470327339-8771990724594742', 8771990724594742, 6642063470327339, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087589191004, '无法加载翻译工作台', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642087589191004-8771920552784072', 8771920552784072, 6642087589191004, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131738404901, '加载中…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642131738404901-8771908386278726', 8771908386278726, 6642131738404901, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642048000147397, '目标语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642048000147397-8771996866079300', 8771996866079300, 6642048000147397, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642097466958424, '无法加载语言列表', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642097466958424-8771965827772292', 8771965827772292, 6642097466958424, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102363560784, '登录后可提交翻译；候选翻译按映射分数排序，无正分候选时使用回退文本。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642102363560784-8771995706904988', 8771995706904988, 6642102363560784, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642071530294532, '未找到匹配文本。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642071530294532-8771904910396271', 8771904910396271, 6642071530294532, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642057933617669, '预览', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642057933617669-8771969689937165', 8771969689937165, 6642057933617669, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642133450507984, '参考语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642133450507984-8772009963987850', 8772009963987850, 6642133450507984, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120305360689, '搜索键名或原文…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642120305360689-8771962647026930', 8771962647026930, 6642120305360689, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127357084685, '选择翻译语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642127357084685-8772037474898823', 8772037474898823, 6642127357084685, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148275677733, '英文原文', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642148275677733-8772014752541923', 8772014752541923, 6642148275677733, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642124861185059, '开始', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642124861185059-8772036201600543', 8772036201600543, 6642124861185059, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642021851191783, '提交失败', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642021851191783-8771930781451254', 8771930781451254, 6642021851191783, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137338923928, '提交映射', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642137338923928-8771938026129323', 8771938026129323, 6642137338923928, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642085585815152, '已提交', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642085585815152-8771906650908176', 8771906650908176, 6642085585815152, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108644210098, '帮助让 LangMap 界面文本更自然、更实用。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642108644210098-8771968758684575', 8771968758684575, 6642108644210098, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642104679747158, '翻译工作台', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642104679747158-8772002773137414', 8772002773137414, 6642104679747158, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044160390934, '翻译 {key}', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642044160390934-8771936438281310', 8771936438281310, 6642044160390934, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078564015755, '已翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642078564015755-8771916786083827', 8771916786083827, 6642078564015755, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095363145866, '翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('6642095363145866-8771951513286657', 8771951513286657, 6642095363145866, 0, 'ui_i18n');

-- Locale zh-Hant
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323672176916, '電子郵件', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127323672176916-8771988929111883', 8771988929111883, 5127323672176916, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127330808040466, '已經有帳號了？', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127330808040466-8771987324928109', 8771987324928109, 5127330808040466, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348918769733, '登入', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348918769733-8771985319534907', 8771985319534907, 5127348918769733, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127337032500718, '還沒有帳號？', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127337032500718-8771920874847316', 8771920874847316, 5127337032500718, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323751663103, '操作失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127323751663103-8771934955742921', 8771934955742921, 5127323751663103, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321548837028, '密碼', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321548837028-8771993838728081', 8771993838728081, 5127321548837028, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127434940273956, '處理中…', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127434940273956-8772001046060388', 8772001046060388, 5127434940273956, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127380536022303, '建立帳號', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127380536022303-8771964374844751', 8771964374844751, 5127380536022303, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389775119240, '使用者名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127389775119240-8772029311767367', 8772029311767367, 5127389775119240, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428739379210, '取消', 'zh-Hant', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428739379210-8772001703307290', 8772001703307290, 5127428739379210, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127399149304639, '關閉', 'zh-Hant', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127399149304639-8771958345505312', 8771958345505312, 5127399149304639, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771930947571421', 8771930947571421, 5127395378809533, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771966685762373', 8771966685762373, 5127395378809533, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424120773993, '載入中…', 'zh-Hant', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424120773993-8771908386278726', 8771908386278726, 5127424120773993, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326247675675, '搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127326247675675-8772018337291447', 8772018337291447, 5127326247675675, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127343584574661, '提交', 'zh-Hant', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127343584574661-8771955384790296', 8771955384790296, 5127343584574661, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373408271576, '實際尺寸 100%', 'zh-Hant', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127373408271576-8771913559728006', 8771913559728006, 5127373408271576, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354612798556, '匿名', 'zh-Hant', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127354612798556-8771963881461252', 8771963881461252, 5127354612798556, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127411910452997, '{count} 個子節點；點選收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127411910452997-8772032837909466', 8772032837909466, 5127411910452997, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127429206018100, '每條邊皆為可投票的獨立直接對應；低分對應自動收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127429206018100-8772028933737015', 8772028933737015, 5127429206018100, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127413501968188, '待建立的對應圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127413501968188-8771990687804642', 8771990687804642, 5127413501968188, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127398760176186, '關閉資訊面板', 'zh-Hant', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127398760176186-8771923580873788', 8771923580873788, 5127398760176186, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409285094977, '收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409285094977-8772025115555117', 8772025115555117, 5127409285094977, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354344241293, '收合子分支', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127354344241293-8772021975712328', 8772021975712328, 5127354344241293, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305289707300, '收合至第一層', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127305289707300-8771963062101045', 8771963062101045, 5127305289707300, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362936071700, '{count} 天前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127362936071700-8772016085305408', 8772016085305408, 5127362936071700, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422625296024, '深度 {depth}', 'zh-Hant', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127422625296024-8772018587383663', 8772018587383663, 5127422625296024, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341828277241, '直接對應詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127341828277241-8771921679343522', 8771921679343522, 5127341828277241, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127385631248035, '倒讚', 'zh-Hant', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127385631248035-8771992127181974', 8771992127181974, 5127385631248035, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320200758021, '{count} 條邊', 'zh-Hant', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127320200758021-8771907018302878', 8771907018302878, 5127320200758021, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127427486652796, '目前沒有資料', 'zh-Hant', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127427486652796-8772000424294921', 8772000424294921, 5127427486652796, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339606366818, '退出全螢幕', 'zh-Hant', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127339606366818-8771995527490116', 8771995527490116, 5127339606366818, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127314771949932, '展開', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127314771949932-8771957005515059', 8771957005515059, 5127314771949932, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323731090498, '全部展開', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127323731090498-8772033758268399', 8772033758268399, 5127323731090498, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127375826935204, '展開子分支', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127375826935204-8771937729949713', 8771937729949713, 5127375826935204, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386696296398-8772028411030279', 8772028411030279, 5127386696296398, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127328374082923, '篩選語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127328374082923-8771975185705787', 8771975185705787, 5127328374082923, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324976668075, '全螢幕', 'zh-Hant', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127324976668075-8771984311379866', 8771984311379866, 5127324976668075, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303258293634, '詞句對應圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127303258293634-8771940176065576', 8771940176065576, 5127303258293634, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357829988114, '載入圖譜…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127357829988114-8771930916265390', 8771930916265390, 5127357829988114, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362727882640, '圖譜模式', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127362727882640-8772018055755937', 8772018055755937, 5127362727882640, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127383236550486, '{nodes} 個對應節點 · {edges} 個關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127383236550486-8771930566920504', 8771930566920504, 5127383236550486, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303921713076, '圖譜工具列', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127303921713076-8771957995007293', 8771957995007293, 5127303921713076, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401754811483, '對應階層列表', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401754811483-8771972530005685', 8771972530005685, 5127401754811483, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127352115920652, '跳數', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127352115920652-8771929108158859', 8771929108158859, 5127352115920652, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127430965433435, '{count} 小時前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127430965433435-8771972038859703', 8771972038859703, 5127430965433435, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127356044789038, '剛剛', 'zh-Hant', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127356044789038-8772006156641051', 8772006156641051, 5127356044789038, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406946069111, '無法載入語言', 'zh-Hant', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127406946069111-8771907230355366', 8771907230355366, 5127406946069111, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127369062556426, '列表模式', 'zh-Hant', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127369062556426-8771978209325624', 8771978209325624, 5127369062556426, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394507017000, '載入更多', 'zh-Hant', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127394507017000-8771968298248581', 8771968298248581, 5127394507017000, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127425613437337, '載入相關詞句中', 'zh-Hant', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127425613437337-8771918922470710', 8771918922470710, 5127425613437337, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127426061523738, '對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127426061523738-8772009894682686', 8772009894682686, 5127426061523738, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321981857285, '對應評分', 'zh-Hant', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321981857285-8772001613332908', 8772001613332908, 5127321981857285, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127388230651521, '{count} 分鐘前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127388230651521-8772029891163450', 8772029891163450, 5127388230651521, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127358903104524, '更多操作', 'zh-Hant', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127358903104524-8771927265880728', 8771927265880728, 5127358903104524, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127412964521482, '完整圖譜中還有 {count} 個對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127412964521482-8771978296601845', 8771978296601845, 5127412964521482, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127413889982734, '尚無直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127413889982734-8771916846886490', 8771916846886490, 5127413889982734, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127340817221837, '找不到相符詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127340817221837-8771950851535873', 8771950851535873, 5127340817221837, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324813258851, '{count} 個節點', 'zh-Hant', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127324813258851-8771915754603204', 8771915754603204, 5127324813258851, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127372570890390, '節點資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127372570890390-8772032217763299', 8772032217763299, 5127372570890390, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127426289219311, '其他關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127426289219311-8772011775552074', 8772011775552074, 5127426289219311, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127427591081550, '相關詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127427591081550-8771996275317129', 8771996275317129, 5127427591081550, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127302236464772, '{count} 個關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127302236464772-8771905570354775', 8771905570354775, 5127302236464772, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305347269151, '移除 {code}', 'zh-Hant', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127305347269151-8771968148353493', 8771968148353493, 5127305347269151, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396005384761, '重設版面配置', 'zh-Hant', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127396005384761-8771923590138278', 8771923590138278, 5127396005384761, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341017166693, '根節點', 'zh-Hant', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127341017166693-8771991096471187', 8771991096471187, 5127341017166693, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326247675675, '搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127326247675675-8772018337291447', 8772018337291447, 5127326247675675, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428574434575-8771934172254861', 8771934172254861, 5127428574434575, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325686593724, '搜尋中…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127325686593724-8771951969125148', 8771951969125148, 5127325686593724, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127415394078254, '在圖譜中選取節點以檢視詳情', 'zh-Hant', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127415394078254-8771969317410200', 8771969317410200, 5127415394078254, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127311555620129, '來源路徑', 'zh-Hant', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127311555620129-8771977750841844', 8771977750841844, 5127311555620129, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127369104864848, '讚', 'zh-Hant', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127369104864848-8772016238570208', 8772016238570208, 5127369104864848, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127365362714954, '檢視詞句詳情', 'zh-Hant', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127365362714954-8771995720429284', 8771995720429284, 5127365362714954, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327273013829, '投票失敗，已復原', 'zh-Hant', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127327273013829-8772020751025198', 8772020751025198, 5127327273013829, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127364775853586, '放大', 'zh-Hant', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127364775853586-8772017398603959', 8772017398603959, 5127364775853586, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127347621174364, '縮小', 'zh-Hant', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127347621174364-8772017289371875', 8772017289371875, 5127347621174364, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127397292562184, '+ 新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127397292562184-8771945073983212', 8771945073983212, 5127397292562184, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342032578063, '完全圖', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127342032578063-8771921254303111', 8771921254303111, 5127342032578063, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393104111077, '刪除', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393104111077-8771944300238713', 8771944300238713, 5127393104111077, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127421487105242, '{count} 個直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127421487105242-8771968945113345', 8771968945113345, 5127421487105242, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386696296398-8772028411030279', 8772028411030279, 5127386696296398, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127398239187692, '{count} 個詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127398239187692-8771918589046163', 8771918589046163, 5127398239187692, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422154374367, '輸入詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127422154374367-8771975160452098', 8771975160452098, 5127422154374367, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771930947571421', 8771930947571421, 5127395378809533, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127334034501573, '提交一組意義相同的詞句。系統會在每對之間建立直接對應。已有詞句會自動關聯，不會重複。', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127334034501573-8771938370927027', 8771938370927027, 5127334034501573, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127366818595734, '至少需要 2 行，每行需填寫語言和詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127366818595734-8771996574983759', 8771996574983759, 5127366818595734, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127343584574661, '提交', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127343584574661-8771955384790296', 8771955384790296, 5127343584574661, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127377900057070, '提交失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127377900057070-8771930781451254', 8771930781451254, 5127377900057070, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127300519001788, '提交中…', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127300519001788-8771996654725718', 8771996654725718, 5127300519001788, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127433562088873, '標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127433562088873-8772023049338365', 8772023049338365, 5127433562088873, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319649845501, '批次提交', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127319649845501-8771967116778370', 8771967116778370, 5127319649845501, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127337382702811, '回首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127337382702811-8771954914944651', 8771954914944651, 5127337382702811, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321894270102-8771936602672507', 8771936602672507, 5127321894270102, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409989981163, '找不到頁面', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409989981163-8771958158698832', 8771958158698832, 5127409989981163, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127405921516665, '全部', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127405921516665-8771912696777795', 8771912696777795, 5127405921516665, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406982738348, '提交對應 →', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127406982738348-8771952067596101', 8771952067596101, 5127406982738348, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432503138096-8771957966582874', 8771957966582874, 5127432503138096, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414163456360, '對應 + 新詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127414163456360-8771971172552785', 8771971172552785, 5127414163456360, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360784678505, '找不到所需內容？', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127360784678505-8771964553678580', 8771964553678580, 5127360784678505, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401410314681, '新貢獻', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401410314681-8772013263074963', 8772013263074963, 5127401410314681, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316933101537-8771912463566270', 8771912463566270, 5127316933101537, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360616465762, '熱門對應', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127360616465762-8771956320455891', 8771956320455891, 5127360616465762, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393063341526, '依評分 · 本週', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393063341526-8772001941683119', 8772001941683119, 5127393063341526, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316881370889, '語意圖的最新脈動——熱門對應與新貢獻。', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316881370889-8771985464043467', 8771985464043467, 5127316881370889, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354044632791, '動態', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127354044632791-8771928668652497', 8771928668652497, 5127354044632791, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303129736814, '新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127303129736814-8772033519106127', 8772033519106127, 5127303129736814, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127330551910207, '新增章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127330551910207-8772013343930223', 8772013343930223, 5127330551910207, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414816170428, '手冊列表', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127414816170428-8771985524903836', 8771985524903836, 5127414816170428, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127434874633237, '第 {number} 章', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127434874633237-8771974942670538', 8771974942670538, 5127434874633237, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393964578570, '關閉詞句資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393964578570-8771948835977551', 8771948835977551, 5127393964578570, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409285094977, '收合', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409285094977-8772025115555117', 8772025115555117, 5127409285094977, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127363673457613, '刪除章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127363673457613-8771922363562335', 8771922363562335, 5127363673457613, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401929461774, '編輯手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401929461774-8771954520730023', 8771954520730023, 5127401929461774, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299105086469, '詞句資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127299105086469-8771958749403912', 8771958749403912, 5127299105086469, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424426329684, '詞句的語言、地區和來源將顯示在此處。', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424426329684-8771969048222271', 8771969048222271, 5127424426329684, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370708607989, '這本手冊有幫助嗎？', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127370708607989-8771919030282571', 8771919030282571, 5127370708607989, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392921577621, '無法載入詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127392921577621-8772001956145712', 8772001956145712, 5127392921577621, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321894270102-8771936602672507', 8771936602672507, 5127321894270102, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771930947571421', 8771930947571421, 5127395378809533, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127359402477186, '下移', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127359402477186-8772015839426216', 8772015839426216, 5127359402477186, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127353143480546, '下移章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127353143480546-8771974741123489', 8771974741123489, 5127353143480546, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338848751984, '上移章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127338848751984-8771974343227837', 8771974343227837, 5127338848751984, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345275319799, '上移', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127345275319799-8772035822327586', 8772035822327586, 5127345275319799, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127390902169908, '私密', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127390902169908-8771981388316157', 8771981388316157, 5127390902169908, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324637377220, '公開', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127324637377220-8771978356150928', 8771978356150928, 5127324637377220, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424832020837, '發布', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424832020837-8771952311782197', 8771952311782197, 5127424832020837, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127315776033294-8771968624126325', 8771968624126325, 5127315776033294, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357104677777, '無法載入相關詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127357104677777-8771991960796854', 8771991960796854, 5127357104677777, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127344244042484, '移除 {text}', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127344244042484-8771948377233166', 8771948377233166, 5127344244042484, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409309566625, '儲存草稿', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409309566625-8771974360984879', 8771974360984879, 5127409309566625, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127381679650516, '儲存中…', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127381679650516-8771980391249065', 8771980391249065, 5127381679650516, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370285683819, '章節標題', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127370285683819-8771935521942479', 8771935521942479, 5127370285683819, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418609851462, '選擇詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127418609851462-8771975315975664', 8771975315975664, 5127418609851462, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127349345736831, '來源', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127349345736831-8771933750484319', 8771933750484319, 5127349345736831, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348620885631, 'AI', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348620885631-8771954789056127', 8771954789056127, 5127348620885631, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362483023363, '權威', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127362483023363-8772029059057248', 8772029059057248, 5127362483023363, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407342914147, '使用者', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127407342914147-8772034803281550', 8772034803281550, 5127407342914147, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127431204867938, '手冊標題', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127431204867938-8771918701696347', 8771918701696347, 5127431204867938, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127382797528579, '目錄', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127382797528579-8771915172364840', 8771915172364840, 5127382797528579, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336131397323, '檢視完整關係圖', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336131397323-8771928949232797', 8771928949232797, 5127336131397323, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373453236120, '可見性', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127373453236120-8772029984927123', 8772029984927123, 5127373453236120, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127383589324033, '新增手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127383589324033-8771984354571011', 8771984354571011, 5127383589324033, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406551787969, '無法載入手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127406551787969-8771915400044673', 8771915400044673, 5127406551787969, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316933101537-8771912463566270', 8771912463566270, 5127316933101537, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360775839668, '找不到手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127360775839668-8772007530341875', 8772007530341875, 5127360775839668, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432503138096-8771957966582874', 8771957966582874, 5127432503138096, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319533546475, '搜尋手冊…', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127319533546475-8772031472567985', 8772031472567985, 5127319533546475, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127405602632112, '章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127405602632112-8771981869623564', 8771981869623564, 5127405602632112, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325826325841, '手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127325826325841-8771945183617329', 8771945183617329, 5127325826325841, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418202207127, '上一步', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127418202207127-8772024038803789', 8772024038803789, 5127418202207127, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428739379210, '取消', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428739379210-8772001703307290', 8772001703307290, 5127428739379210, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127399149304639, '關閉', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127399149304639-8771958345505312', 8771958345505312, 5127399149304639, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424239724439, '建立語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424239724439-8771972155504688', 8771972155504688, 5127424239724439, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127306526842157, '語言建立失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127306526842157-8772008975730714', 8772008975730714, 5127306526842157, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418771472175, '建立中…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127418771472175-8771943301451236', 8771943301451236, 5127418771472175, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336171575006, '請輸入描述', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336171575006-8771986788835322', 8771986788835322, 5127336171575006, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396955853811, '請選擇 Glottolog 比對或選擇「無比對」', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127396955853811-8771982145239141', 8771982145239141, 5127396955853811, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357418622251, '請輸入語言名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127357418622251-8771921060819264', 8771921060819264, 5127357418622251, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386277435953, '請選擇僅限社群建立的原因', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386277435953-8771926836463632', 8771926836463632, 5127386277435953, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127378882991109, '請輸入語言子標籤以繼續', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127378882991109-8772026576042326', 8772026576042326, 5127378882991109, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327376928924, '找到 {count} 個候選', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127327376928924-8771956461019812', 8771956461019812, 5127327376928924, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336372587732, '選擇比對或標示無合適條目', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336372587732-8772033726980358', 8772033726980358, 5127336372587732, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336574771018, '比對此候選', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336574771018-8772036217067472', 8772036217067472, 5127336574771018, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338055921956, '方言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127338055921956-8771959645210043', 8771959645210043, 5127338055921956, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771953851734414', 8771953851734414, 5127395378809533, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327695489615, 'Glottolog 無合適條目', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127327695489615-8771907658003091', 8771907658003091, 5127327695489615, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127309160014515, '搜尋 Glottolog…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127309160014515-8771972676692740', 8771972676692740, 5127309160014515, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332014335622, '描述', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127332014335622-8771937301075282', 8771937301075282, 5127332014335622, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406419923431, '描述此語言或變體…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127406419923431-8771929062150956', 8771929062150956, 5127406419923431, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401083130169, '名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401083130169-8771913536651859', 8771913536651859, 5127401083130169, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395725283619, '英文名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395725283619-8772035648862723', 8772035648862723, 5127395725283619, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127376065500682, '為何此語言未收錄於 Glottolog？', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127376065500682-8771965397553798', 8771965397553798, 5127376065500682, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428084200263, '社群特定用法', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428084200263-8772029121364869', 8772029121364869, 5127428084200263, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127385068999259, '新興變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127385068999259-8771911763851130', 8771911763851130, 5127385068999259, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373832153965, 'Glottolog 未收錄', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127373832153965-8772027448793331', 8772027448793331, 5127373832153965, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393404276106, '其他', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393404276106-8771907717721822', 8771907717721822, 5127393404276106, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432948284566, '選擇原因…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432948284566-8771908744199257', 8771908744199257, 5127432948284566, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386378586707, '下一步', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386378586707-8771946058185965', 8771946058185965, 5127386378586707, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127391768169041, '標準代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127391768169041-8771986283559204', 8771986283559204, 5127391768169041, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326733972958, '此語言已存在', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127326733972958-8771963047592058', 8771963047592058, 5127326733972958, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127363115870538, '使用現有語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127363115870538-8771911987565882', 8771911987565882, 5127363115870538, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424239724439, '建立語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424239724439-8771972155504688', 8771972155504688, 5127424239724439, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332114033069, '警告', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127332114033069-8771976682274382', 8771976682274382, 5127332114033069, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127297706246680, '暫時標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127297706246680-8771969301691665', 8771969301691665, 5127297706246680, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336938891640, 'Glottolog 比對', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336938891640-8771926452848847', 8771926452848847, 5127336938891640, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409985242551, '中繼資料', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409985242551-8771988865126091', 8771988865126091, 5127409985242551, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127375811029713, '預覽並建立', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127375811029713-8772002442315415', 8772002442315415, 5127375811029713, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299573860323, '語言標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127299573860323-8771982332401463', 8771982332401463, 5127299573860323, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771930947571421', 8771930947571421, 5127395378809533, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127315776033294-8771968624126325', 8771968624126325, 5127315776033294, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396102912122, '文字', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127396102912122-8771976361115614', 8771976361115614, 5127396102912122, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394299020306, '搜尋子標籤…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127394299020306-8772015391400398', 8772015391400398, 5127394299020306, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127301556984635, '變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127301556984635-8771923711808765', 8771923711808765, 5127301556984635, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299642411845, '已移除 1 個變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127299642411845-8772011217159086', 8772011217159086, 5127299642411845, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127297749018845, '已移除 {count} 個變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127297749018845-8771998528580369', 8771998528580369, 5127297749018845, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409120136913, '依字母排序', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127409120136913-8772039352640020', 8772039352640020, 5127409120136913, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771966685762373', 8771966685762373, 5127395378809533, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386696296398-8772004481370898', 8772004481370898, 5127386696296398, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316933101537-8771912463566270', 8771912463566270, 5127316933101537, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321894270102-8771936602672507', 8771936602672507, 5127321894270102, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127302636650680, '已對應', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127302636650680-8771947211108180', 8771947211108180, 5127302636650680, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127307506165183, '找不到詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127307506165183-8771950851535873', 8771950851535873, 5127307506165183, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432503138096-8771957966582874', 8771957966582874, 5127432503138096, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428574434575-8771934172254861', 8771934172254861, 5127428574434575, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345514774646, '清除選擇', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127345514774646-8771904155296746', 8771904155296746, 5127345514774646, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401028917826, '建立新語言或變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401028917826-8772010209718094', 8772010209718094, 5127401028917826, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392493406626, '無符合語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127392493406626-8771905467432581', 8771905467432581, 5127392493406626, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336744172322, '搜尋語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336744172322-8771957308068965', 8771957308068965, 5127336744172322, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316013967809, '瀏覽器推薦', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316013967809-8771943861429001', 8771943861429001, 5127316013967809, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327890852151, '協助翻譯 LangMap', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127327890852151-8771962203854555', 8771962203854555, 5127327890852151, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342592583443, '無符合的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127342592583443-8771905467432581', 8771905467432581, 5127342592583443, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127356744610830, '最近使用的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127356744610830-8772017158300851', 8772017158300851, 5127356744610830, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386696296398-8772004481370898', 8772004481370898, 5127386696296398, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771966685762373', 8771966685762373, 5127395378809533, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406946069111, '無法載入語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127406946069111-8771907230355366', 8771907230355366, 5127406946069111, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320598752207, '找不到語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127320598752207-8772015486738705', 8772015486738705, 5127320598752207, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336744172322, '搜尋語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336744172322-8771957308068965', 8771957308068965, 5127336744172322, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127367232105740, 'A–Z', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127367232105740-8771973400276236', 8771973400276236, 5127367232105740, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345311838321, '依數量', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127345311838321-8771994726877247', 8771994726877247, 5127345311838321, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407612154030, '瀏覽所有語言的詞句與對應關係', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127407612154030-8772027985468400', 8772027985468400, 5127407612154030, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771966685762373', 8771966685762373, 5127395378809533, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325788569537, '錨點', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127325788569537-8771952725719815', 8771952725719815, 5127325788569537, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127353920450648, '回到對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127353920450648-8771984993053397', 8771984993053397, 5127353920450648, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127333850393921, '{count} 種語言', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127333850393921-8771995851022194', 8771995851022194, 5127333850393921, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321894270102-8771936602672507', 8771936602672507, 5127321894270102, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127346707093309, '對應成員', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127346707093309-8771950928148051', 8771950928148051, 5127346707093309, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345917555958, '此概念無地理分佈資料', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127345917555958-8771989613412250', 8771989613412250, 5127345917555958, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339708916683, '{count} 個地區', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127339708916683-8772012470644251', 8772012470644251, 5127339708916683, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370786022020, '概念分佈', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127370786022020-8771918829802721', 8771918829802721, 5127370786022020, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127328290073417, '新增並建立對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127328290073417-8771969898159421', 8771969898159421, 5127328290073417, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303129736814, '新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127303129736814-8772033519106127', 8772033519106127, 5127303129736814, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357412748672, '無法新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127357412748672-8771908944297462', 8771908944297462, 5127357412748672, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127364153783000, '新增中…', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127364153783000-8771928703559647', 8771928703559647, 5127364153783000, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362483023363, '權威', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127362483023363-8772029059057248', 8772029059057248, 5127362483023363, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127314083101281, '麵包屑', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127314083101281-8772001620797917', 8772001620797917, 5127314083101281, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368668783181, '關閉快速新增', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127368668783181-8771978190877962', 8771978190877962, 5127368668783181, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348974270666, '貢獻對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348974270666-8772005931944793', 8772005931944793, 5127348974270666, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393373329322, '直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393373329322-8771956479287686', 8771956479287686, 5127393373329322, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127423992007254, '請輸入詞句與語言代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127423992007254-8771956618196526', 8771956618196526, 5127423992007254, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127386696296398-8772028411030279', 8772028411030279, 5127386696296398, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422154374367, '輸入詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127422154374367-8771952819511586', 8771952819511586, 5127422154374367, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332060219017, '圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127332060219017-8771971766539087', 8771971766539087, 5127332060219017, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389164030760, '首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127389164030760-8771987694898855', 8771987694898855, 5127389164030760, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127352115920652, '跳數', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127352115920652-8771987564932373', 8771987564932373, 5127352115920652, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341692916608, '間接', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127341692916608-8772028520330484', 8772028520330484, 5127341692916608, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316601222852, '語言代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316601222852-8771920539132885', 8771920539132885, 5127316601222852, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329243205963, '例如 en / zh-Hant', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127329243205963-8771919700012927', 8771919700012927, 5127329243205963, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127387876637869, '列表', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127387876637869-8771992537520761', 8771992537520761, 5127387876637869, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321894270102-8771936602672507', 8771936602672507, 5127321894270102, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396584597528, '對應集合', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127396584597528-8772011172535505', 8772011172535505, 5127396584597528, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401537819350, '尚無對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401537819350-8772036040577861', 8772036040577861, 5127401537819350, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327325514982, '選填', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127327325514982-8771986434294618', 8771986434294618, 5127327325514982, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305299939302, '快速新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127305299939302-8772035320845087', 8772035320845087, 5127305299939302, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127304051485505, '新增詞句並直接對應到目前詞句。', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127304051485505-8771923205204397', 8771923205204397, 5127304051485505, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127315776033294-8771968624126325', 8771968624126325, 5127315776033294, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407342914147, '使用者', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127407342914147-8772034803281550', 8772034803281550, 5127407342914147, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127350190805617, '在地圖上檢視此概念', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127350190805617-8772021818623523', 8772021818623523, 5127350190805617, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127403267666151, '關閉選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127403267666151-8772008345770010', 8772008345770010, 5127403267666151, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368640606434, '貢獻', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127368640606434-8772022393103823', 8772022393103823, 5127368640606434, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325826325841, '手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127325826325841-8771945183617329', 8771945183617329, 5127325826325841, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389164030760, '首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127389164030760-8771987694898855', 8771987694898855, 5127389164030760, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127395378809533-8771966685762373', 8771966685762373, 5127395378809533, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345595159729, '選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127345595159729-8771933905283078', 8771933905283078, 5127345595159729, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127318839016209, '開啟選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127318839016209-8771988489117883', 8771988489117883, 5127318839016209, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329900720419, '搜尋詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127329900720419-8772000153561666', 8772000153561666, 5127329900720419, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348918769733, '登入', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348918769733-8771985319534907', 8771985319534907, 5127348918769733, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418242438965, '登出', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127418242438965-8771987956311474', 8771987956311474, 5127418242438965, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321870233496, '送出搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127321870233496-8772033727162136', 8772033727162136, 5127321870233496, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127313955227942, '切換介面語言', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127313955227942-8771905685377287', 8771905685377287, 5127313955227942, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320410720783, '依字母順序', 'zh-Hant', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127320410720783-8772039352640020', 8772039352640020, 5127320410720783, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336447386655, '提示：目前搜尋比對詞句原文。語意搜尋即將推出。', 'zh-Hant', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127336447386655-8771909635790690', 8771909635790690, 5127336447386655, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127384545702382, '搜尋失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127384545702382-8771929026122151', 8771929026122151, 5127384545702382, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127316933101537-8771912463566270', 8771912463566270, 5127316933101537, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338185744753, '找不到結果', 'zh-Hant', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127338185744753-8771927555767000', 8771927555767000, 5127338185744753, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127428574434575-8771934172254861', 8771934172254861, 5127428574434575, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432503138096-8771957966582874', 8771957966582874, 5127432503138096, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127311127495684, '{count} 個結果', 'zh-Hant', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127311127495684-8772014433488480', 8772014433488480, 5127311127495684, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320261880866, '排序', 'zh-Hant', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127320261880866-8772001210440828', 8772001210440828, 5127320261880866, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329900720419, '搜尋詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127329900720419-8772000153561666', 8772000153561666, 5127329900720419, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127410440417596, '新增要翻譯的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127410440417596-8771973106595188', 8771973106595188, 5127410440417596, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394605177341, '提交 {count} 筆翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127394605177341-8771943172288619', 8771943172288619, 5127394605177341, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348097517782, '目前翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348097517782-8771982470884397', 8771982470884397, 5127348097517782, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342048278398, '選擇已註冊的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127342048278398-8772018182873778', 8772018182873778, 5127342048278398, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127431614850202, '翻譯涵蓋率', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127431614850202-8772013113555302', 8772013113555302, 5127431614850202, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127378811419550, '顯示 {count} 筆', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127378811419550-8772040929892299', 8772040929892299, 5127378811419550, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127358508397472, '社群本地化', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127358508397472-8771973543137726', 8771973543137726, 5127358508397472, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414657751069, '輸入翻譯…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127414657751069-8771990724594742', 8771990724594742, 5127414657751069, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299944318146, '無法載入翻譯工作台', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127299944318146-8771920552784072', 8771920552784072, 5127299944318146, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424120773993, '載入中…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127424120773993-8771908386278726', 8771908386278726, 5127424120773993, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348663027096, '目標語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348663027096-8771996866079300', 8771996866079300, 5127348663027096, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127382465469228, '無法載入語言列表', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127382465469228-8771965827772292', 8771965827772292, 5127382465469228, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127388180907309, '登入後可提交翻譯；候選翻譯依對應分數排序，無正分候選時使用備用文字。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127388180907309-8771995706904988', 8771995706904988, 5127388180907309, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127351988455630, '找不到相符文字。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127351988455630-8771904910396271', 8771904910396271, 5127351988455630, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432080397186, '預覽', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127432080397186-8771969689937165', 8771969689937165, 5127432080397186, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339140798464, '參考語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127339140798464-8772009963987850', 8772009963987850, 5127339140798464, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127420539926969, '搜尋鍵名或原文…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127420539926969-8771962647026930', 8771962647026930, 5127420539926969, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127349462449483, '選擇翻譯語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127349462449483-8772037474898823', 8772037474898823, 5127349462449483, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127433569462821, '英文原文', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127433569462821-8772014752541923', 8772014752541923, 5127433569462821, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392941268920, '開始', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127392941268920-8772036201600543', 8772036201600543, 5127392941268920, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127377900057070, '提交失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127377900057070-8771930781451254', 8771930781451254, 5127377900057070, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348787423001, '提交對應', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127348787423001-8771938026129323', 8771938026129323, 5127348787423001, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370879600240, '已提交', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127370879600240-8771906650908176', 8771906650908176, 5127370879600240, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319512300712, '幫助讓 LangMap 介面文字更自然、更實用。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127319512300712-8771968758684575', 8771968758684575, 5127319512300712, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368254100335, '翻譯工作台', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127368254100335-8772002773137414', 8772002773137414, 5127368254100335, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393508132181, '翻譯 {key}', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127393508132181-8771936438281310', 8771936438281310, 5127393508132181, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401344814638, '已翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127401344814638-8771916786083827', 8771916786083827, 5127401344814638, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127351365330507, '翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('5127351365330507-8771951513286657', 8771951513286657, 5127351365330507, 0, 'ui_i18n');

-- Done