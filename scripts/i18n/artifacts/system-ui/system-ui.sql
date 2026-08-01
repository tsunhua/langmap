-- Generated managed system UI translation bundle
-- Project: langmap-web
-- Ownership scope: managed-system-ui

-- 1. Upsert locale metadata
-- Locale es-ES
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'es-ES', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'es-ES'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale ja-JP
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'ja-JP', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'ja-JP'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale zh-Hans-CN
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'zh-Hans-CN', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'zh-Hans-CN'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- Locale zh-Hant-TW
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
SELECT 'langmap-web', 'zh-Hant-TW', l.name, l.direction, 'active'
FROM languages l WHERE l.code = 'zh-Hant-TW'
ON CONFLICT(project_id, code) DO UPDATE SET
  native_name = excluded.native_name,
  direction = excluded.direction,
  status = excluded.status;

-- 2. Source messages (312 keys)
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039278566303563, 'Email', 'en-US', 'ui_i18n', 'langmap-web:auth.email', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.email', 4039278566303563, '[]', '4039278566303563', 'active');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039276962119789, 'Already have an account?', 'en-US', 'ui_i18n', 'langmap-web:auth.haveAccount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.haveAccount', 4039276962119789, '[]', '4039276962119789', 'active');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039274956726587, 'Sign in', 'en-US', 'ui_i18n', 'langmap-web:auth.login', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.login', 4039274956726587, '[]', '4039274956726587', 'active');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039210512038996, 'Don''t have an account?', 'en-US', 'ui_i18n', 'langmap-web:auth.noAccount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.noAccount', 4039210512038996, '[]', '4039210512038996', 'active');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039224592934601, 'Operation failed', 'en-US', 'ui_i18n', 'langmap-web:auth.operationFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.operationFailed', 4039224592934601, '[]', '4039224592934601', 'active');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039283475919761, 'Password', 'en-US', 'ui_i18n', 'langmap-web:auth.password', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.password', 4039283475919761, '[]', '4039283475919761', 'active');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039290683252068, 'Processing…', 'en-US', 'ui_i18n', 'langmap-web:auth.processing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.processing', 4039290683252068, '[]', '4039290683252068', 'active');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039254012036431, 'Create account', 'en-US', 'ui_i18n', 'langmap-web:auth.register', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.register', 4039254012036431, '[]', '4039254012036431', 'active');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318948959047, 'Username', 'en-US', 'ui_i18n', 'langmap-web:auth.username', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'auth.username', 4039318948959047, '[]', '4039318948959047', 'active');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291340498970, 'Cancel', 'en-US', 'ui_i18n', 'langmap-web:common.cancel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.cancel', 4039291340498970, '[]', '4039291340498970', 'active');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247982696992, 'Close', 'en-US', 'ui_i18n', 'langmap-web:common.close', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.close', 4039247982696992, '[]', '4039247982696992', 'active');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220584763101, 'Language', 'en-US', 'ui_i18n', 'langmap-web:common.language', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.language', 4039220584763101, '[]', '4039220584763101', 'active');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256322954053, 'Languages', 'en-US', 'ui_i18n', 'langmap-web:common.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.languages', 4039256322954053, '[]', '4039256322954053', 'active');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039198023470406, 'Loading…', 'en-US', 'ui_i18n', 'langmap-web:common.loading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.loading', 4039198023470406, '[]', '4039198023470406', 'active');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039307974483127, 'Search', 'en-US', 'ui_i18n', 'langmap-web:common.search', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.search', 4039307974483127, '[]', '4039307974483127', 'active');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039245021981976, 'Submit', 'en-US', 'ui_i18n', 'langmap-web:common.submit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'common.submit', 4039245021981976, '[]', '4039245021981976', 'active');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039203196919686, 'Actual size 100%', 'en-US', 'ui_i18n', 'langmap-web:components.actualSize', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.actualSize', 4039203196919686, '[]', '4039203196919686', 'active');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039253518652932, 'Anonymous', 'en-US', 'ui_i18n', 'langmap-web:components.anonymous', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.anonymous', 4039253518652932, '[]', '4039253518652932', 'active');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039322475101146, '{count} child nodes; click to collapse', 'en-US', 'ui_i18n', 'langmap-web:components.childNodes', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.childNodes', 4039322475101146, '[]', '4039322475101146', 'active');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318570928695, 'Each edge is an independent direct mapping that can be upvoted or downvoted; low-scoring mappings are collapsed.', 'en-US', 'ui_i18n', 'langmap-web:components.cliqueNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.cliqueNote', 4039318570928695, '[]', '4039318570928695', 'active');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039280324996322, 'Mapping graph to be created', 'en-US', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.cliqueTitle', 4039280324996322, '[]', '4039280324996322', 'active');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039213218065468, 'Close information panel', 'en-US', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.closeInfoPanel', 4039213218065468, '[]', '4039213218065468', 'active');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039314752746797, 'Collapse', 'en-US', 'ui_i18n', 'langmap-web:components.collapse', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapse', 4039314752746797, '[]', '4039314752746797', 'active');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039311612904008, 'Collapse child branch', 'en-US', 'ui_i18n', 'langmap-web:components.collapseBranch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapseBranch', 4039311612904008, '[]', '4039311612904008', 'active');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039252699292725, 'Collapse to first hop', 'en-US', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.collapseToFirst', 4039252699292725, '[]', '4039252699292725', 'active');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039305722497088, '{count} days ago', 'en-US', 'ui_i18n', 'langmap-web:components.daysAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.daysAgo', 4039305722497088, '[]', '4039305722497088', 'active');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039308224575343, 'Depth {depth}', 'en-US', 'ui_i18n', 'langmap-web:components.depth', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.depth', 4039308224575343, '[]', '4039308224575343', 'active');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039211316535202, 'Directly mapped expressions', 'en-US', 'ui_i18n', 'langmap-web:components.directMappingList', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.directMappingList', 4039211316535202, '[]', '4039211316535202', 'active');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039281764373654, 'Downvote', 'en-US', 'ui_i18n', 'langmap-web:components.downvote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.downvote', 4039281764373654, '[]', '4039281764373654', 'active');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039196655494558, '{count} edges', 'en-US', 'ui_i18n', 'langmap-web:components.edgeCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.edgeCount', 4039196655494558, '[]', '4039196655494558', 'active');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039290061486601, 'No data yet', 'en-US', 'ui_i18n', 'langmap-web:components.empty', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.empty', 4039290061486601, '[]', '4039290061486601', 'active');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039285164681796, 'Exit fullscreen', 'en-US', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.exitFullscreen', 4039285164681796, '[]', '4039285164681796', 'active');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246642706739, 'Expand', 'en-US', 'ui_i18n', 'langmap-web:components.expand', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expand', 4039246642706739, '[]', '4039246642706739', 'active');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039323395460079, 'Expand all', 'en-US', 'ui_i18n', 'langmap-web:components.expandAll', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expandAll', 4039323395460079, '[]', '4039323395460079', 'active');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039227367141393, 'Expand child branch', 'en-US', 'ui_i18n', 'langmap-web:components.expandBranch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expandBranch', 4039227367141393, '[]', '4039227367141393', 'active');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318048221959, 'Expression', 'en-US', 'ui_i18n', 'langmap-web:components.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.expression', 4039318048221959, '[]', '4039318048221959', 'active');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039264822897467, 'Filter languages…', 'en-US', 'ui_i18n', 'langmap-web:components.filterLanguages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.filterLanguages', 4039264822897467, '[]', '4039264822897467', 'active');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039273948571546, 'Fullscreen', 'en-US', 'ui_i18n', 'langmap-web:components.fullscreen', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.fullscreen', 4039273948571546, '[]', '4039273948571546', 'active');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039229813257256, 'Expression mapping graph', 'en-US', 'ui_i18n', 'langmap-web:components.graphLabel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphLabel', 4039229813257256, '[]', '4039229813257256', 'active');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220553457070, 'Loading graph…', 'en-US', 'ui_i18n', 'langmap-web:components.graphLoading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphLoading', 4039220553457070, '[]', '4039220553457070', 'active');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039307692947617, 'Graph mode', 'en-US', 'ui_i18n', 'langmap-web:components.graphMode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphMode', 4039307692947617, '[]', '4039307692947617', 'active');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220204112184, '{nodes} mapped nodes · {edges} relations', 'en-US', 'ui_i18n', 'langmap-web:components.graphStats', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphStats', 4039220204112184, '[]', '4039220204112184', 'active');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247632198973, 'Graph toolbar', 'en-US', 'ui_i18n', 'langmap-web:components.graphToolbar', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.graphToolbar', 4039247632198973, '[]', '4039247632198973', 'active');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039262167197365, 'Mapping hierarchy list', 'en-US', 'ui_i18n', 'langmap-web:components.hierarchyList', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hierarchyList', 4039262167197365, '[]', '4039262167197365', 'active');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218745350539, 'Hops', 'en-US', 'ui_i18n', 'langmap-web:components.hops', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hops', 4039218745350539, '[]', '4039218745350539', 'active');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039261676051383, '{count} hours ago', 'en-US', 'ui_i18n', 'langmap-web:components.hoursAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.hoursAgo', 4039261676051383, '[]', '4039261676051383', 'active');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039295793832731, 'Just now', 'en-US', 'ui_i18n', 'langmap-web:components.justNow', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.justNow', 4039295793832731, '[]', '4039295793832731', 'active');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039196867547046, 'Unable to load languages', 'en-US', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.languageLoadFailed', 4039196867547046, '[]', '4039196867547046', 'active');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039267846517304, 'List mode', 'en-US', 'ui_i18n', 'langmap-web:components.listMode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.listMode', 4039267846517304, '[]', '4039267846517304', 'active');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039257935440261, 'Load more', 'en-US', 'ui_i18n', 'langmap-web:components.loadMore', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.loadMore', 4039257935440261, '[]', '4039257935440261', 'active');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039208559662390, 'Loading related expressions', 'en-US', 'ui_i18n', 'langmap-web:components.loadingRelated', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.loadingRelated', 4039208559662390, '[]', '4039208559662390', 'active');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039299531874366, 'Mapping', 'en-US', 'ui_i18n', 'langmap-web:components.mapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.mapping', 4039299531874366, '[]', '4039299531874366', 'active');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291250524588, 'Mapping score', 'en-US', 'ui_i18n', 'langmap-web:components.mappingScore', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.mappingScore', 4039291250524588, '[]', '4039291250524588', 'active');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039319528355130, '{count} minutes ago', 'en-US', 'ui_i18n', 'langmap-web:components.minutesAgo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.minutesAgo', 4039319528355130, '[]', '4039319528355130', 'active');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039216903072408, 'More actions', 'en-US', 'ui_i18n', 'langmap-web:components.moreActions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.moreActions', 4039216903072408, '[]', '4039216903072408', 'active');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039267933793525, '{count} more mappings are available in the full graph.', 'en-US', 'ui_i18n', 'langmap-web:components.moreMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.moreMappings', 4039267933793525, '[]', '4039267933793525', 'active');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039206484078170, 'No direct mappings yet.', 'en-US', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.noDirectMappings', 4039206484078170, '[]', '4039206484078170', 'active');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039240488727553, 'No expressions found', 'en-US', 'ui_i18n', 'langmap-web:components.noExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.noExpressions', 4039240488727553, '[]', '4039240488727553', 'active');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039205391794884, '{count} nodes', 'en-US', 'ui_i18n', 'langmap-web:components.nodeCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.nodeCount', 4039205391794884, '[]', '4039205391794884', 'active');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039321854954979, 'Node information', 'en-US', 'ui_i18n', 'langmap-web:components.nodeInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.nodeInfo', 4039321854954979, '[]', '4039321854954979', 'active');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039301412743754, 'Other relations', 'en-US', 'ui_i18n', 'langmap-web:components.otherRelations', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.otherRelations', 4039301412743754, '[]', '4039301412743754', 'active');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039285912508809, 'Related expressions', 'en-US', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.relatedExpressions', 4039285912508809, '[]', '4039285912508809', 'active');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039195207546455, '{count} relations', 'en-US', 'ui_i18n', 'langmap-web:components.relationCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.relationCount', 4039195207546455, '[]', '4039195207546455', 'active');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039257785545173, 'Remove {code}', 'en-US', 'ui_i18n', 'langmap-web:components.removeLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.removeLanguage', 4039257785545173, '[]', '4039257785545173', 'active');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039213227329958, 'Reset layout', 'en-US', 'ui_i18n', 'langmap-web:components.resetLayout', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.resetLayout', 4039213227329958, '[]', '4039213227329958', 'active');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039280733662867, 'Root node', 'en-US', 'ui_i18n', 'langmap-web:components.rootNode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.rootNode', 4039280733662867, '[]', '4039280733662867', 'active');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039307974483127, 'Search', 'en-US', 'ui_i18n', 'langmap-web:components.search', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.search', 4039307974483127, '[]', '4039307974483127', 'active');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039223809446541, 'Search expressions…', 'en-US', 'ui_i18n', 'langmap-web:components.searchExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.searchExpressions', 4039223809446541, '[]', '4039223809446541', 'active');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039241606316828, 'Searching…', 'en-US', 'ui_i18n', 'langmap-web:components.searching', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.searching', 4039241606316828, '[]', '4039241606316828', 'active');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258954601880, 'Select a node in the graph to view details', 'en-US', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.selectNodeHint', 4039258954601880, '[]', '4039258954601880', 'active');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039267388033524, 'Source path', 'en-US', 'ui_i18n', 'langmap-web:components.sourcePath', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.sourcePath', 4039267388033524, '[]', '4039267388033524', 'active');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039305875761888, 'Upvote', 'en-US', 'ui_i18n', 'langmap-web:components.upvote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.upvote', 4039305875761888, '[]', '4039305875761888', 'active');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039285357620964, 'View expression details', 'en-US', 'ui_i18n', 'langmap-web:components.viewExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.viewExpression', 4039285357620964, '[]', '4039285357620964', 'active');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039310388216878, 'Vote failed; reverted', 'en-US', 'ui_i18n', 'langmap-web:components.voteFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.voteFailed', 4039310388216878, '[]', '4039310388216878', 'active');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039307035795639, 'Zoom in', 'en-US', 'ui_i18n', 'langmap-web:components.zoomIn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.zoomIn', 4039307035795639, '[]', '4039307035795639', 'active');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039306926563555, 'Zoom out', 'en-US', 'ui_i18n', 'langmap-web:components.zoomOut', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'components.zoomOut', 4039306926563555, '[]', '4039306926563555', 'active');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039234711174892, '+ Add expression', 'en-US', 'ui_i18n', 'langmap-web:contribute.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.addExpression', 4039234711174892, '[]', '4039234711174892', 'active');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039210891494791, 'Complete graph', 'en-US', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.completeGraph', 4039210891494791, '[]', '4039210891494791', 'active');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039233937430393, 'Delete', 'en-US', 'ui_i18n', 'langmap-web:contribute.delete', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.delete', 4039233937430393, '[]', '4039233937430393', 'active');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258582305025, '{count} direct mappings', 'en-US', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.directMappingCount', 4039258582305025, '[]', '4039258582305025', 'active');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318048221959, 'Expression', 'en-US', 'ui_i18n', 'langmap-web:contribute.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expression', 4039318048221959, '[]', '4039318048221959', 'active');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039208226237843, '{count} expressions', 'en-US', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expressionCount', 4039208226237843, '[]', '4039208226237843', 'active');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039264797643778, 'Enter an expression…', 'en-US', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.expressionPlaceholder', 4039264797643778, '[]', '4039264797643778', 'active');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220584763101, 'Language', 'en-US', 'ui_i18n', 'langmap-web:contribute.language', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.language', 4039220584763101, '[]', '4039220584763101', 'active');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039228008118707, 'Submit a group of expressions that mean the same thing. The system creates direct mappings between every pair. Existing expressions are linked automatically without duplicates.', 'en-US', 'ui_i18n', 'langmap-web:contribute.lead', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.lead', 4039228008118707, '[]', '4039228008118707', 'active');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039286212175439, 'At least 2 rows with a language and expression are required', 'en-US', 'ui_i18n', 'langmap-web:contribute.minRows', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.minRows', 4039286212175439, '[]', '4039286212175439', 'active');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039245021981976, 'Submit', 'en-US', 'ui_i18n', 'langmap-web:contribute.submit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submit', 4039245021981976, '[]', '4039245021981976', 'active');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220418642934, 'Submission failed', 'en-US', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submitFailed', 4039220418642934, '[]', '4039220418642934', 'active');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039286291917398, 'Submitting…', 'en-US', 'ui_i18n', 'langmap-web:contribute.submitting', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.submitting', 4039286291917398, '[]', '4039286291917398', 'active');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039312686530045, 'Tags', 'en-US', 'ui_i18n', 'langmap-web:contribute.tags', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.tags', 4039312686530045, '[]', '4039312686530045', 'active');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256753970050, 'Batch contribution', 'en-US', 'ui_i18n', 'langmap-web:contribute.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'contribute.title', 4039256753970050, '[]', '4039256753970050', 'active');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039244552136331, 'Back home', 'en-US', 'ui_i18n', 'langmap-web:errors.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.home', 4039244552136331, '[]', '4039244552136331', 'active');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226239864187, 'Unable to load', 'en-US', 'ui_i18n', 'langmap-web:errors.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.loadFailed', 4039226239864187, '[]', '4039226239864187', 'active');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247795890512, 'Page not found', 'en-US', 'ui_i18n', 'langmap-web:errors.pageMissing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'errors.pageMissing', 4039247795890512, '[]', '4039247795890512', 'active');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039202333969475, 'All', 'en-US', 'ui_i18n', 'langmap-web:feed.all', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.all', 4039202333969475, '[]', '4039202333969475', 'active');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039241704787781, 'Contribute a mapping →', 'en-US', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.contributeMapping', 4039241704787781, '[]', '4039241704787781', 'active');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247603774554, 'Popular', 'en-US', 'ui_i18n', 'langmap-web:feed.hot', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.hot', 4039247603774554, '[]', '4039247603774554', 'active');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039260809744465, 'Mappings + new expressions', 'en-US', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.mappingsAndExpressions', 4039260809744465, '[]', '4039260809744465', 'active');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039254190870260, 'Can’t find what you need?', 'en-US', 'ui_i18n', 'langmap-web:feed.missing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.missing', 4039254190870260, '[]', '4039254190870260', 'active');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039302900266643, 'New contributions', 'en-US', 'ui_i18n', 'langmap-web:feed.newContributions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.newContributions', 4039302900266643, '[]', '4039302900266643', 'active');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039202100757950, 'Latest', 'en-US', 'ui_i18n', 'langmap-web:feed.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.newest', 4039202100757950, '[]', '4039202100757950', 'active');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039245957647571, 'Popular mappings', 'en-US', 'ui_i18n', 'langmap-web:feed.popularMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.popularMappings', 4039245957647571, '[]', '4039245957647571', 'active');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291578874799, 'By score · this week', 'en-US', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.ratedThisWeek', 4039291578874799, '[]', '4039291578874799', 'active');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039275101235147, 'The latest pulse of the semantic graph — popular mappings and new contributions.', 'en-US', 'ui_i18n', 'langmap-web:feed.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.subtitle', 4039275101235147, '[]', '4039275101235147', 'active');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218305844177, 'Activity', 'en-US', 'ui_i18n', 'langmap-web:feed.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'feed.title', 4039218305844177, '[]', '4039218305844177', 'active');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039323156297807, 'Add expression', 'en-US', 'ui_i18n', 'langmap-web:handbook.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.addExpression', 4039323156297807, '[]', '4039323156297807', 'active');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039302981121903, 'Add section', 'en-US', 'ui_i18n', 'langmap-web:handbook.addSection', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.addSection', 4039302981121903, '[]', '4039302981121903', 'active');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039275162095516, 'Handbook list', 'en-US', 'ui_i18n', 'langmap-web:handbook.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.back', 4039275162095516, '[]', '4039275162095516', 'active');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039264579862218, 'Chapter {number}', 'en-US', 'ui_i18n', 'langmap-web:handbook.chapter', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.chapter', 4039264579862218, '[]', '4039264579862218', 'active');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039238473169231, 'Close expression information', 'en-US', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.closeExpressionInfo', 4039238473169231, '[]', '4039238473169231', 'active');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039314752746797, 'Collapse', 'en-US', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.collapsePicker', 4039314752746797, '[]', '4039314752746797', 'active');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039212000754015, 'Delete section', 'en-US', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.deleteSection', 4039212000754015, '[]', '4039212000754015', 'active');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039244157921703, 'Edit handbook', 'en-US', 'ui_i18n', 'langmap-web:handbook.edit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.edit', 4039244157921703, '[]', '4039244157921703', 'active');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039248386595592, 'Expression information', 'en-US', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.expressionInfo', 4039248386595592, '[]', '4039248386595592', 'active');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258685413951, 'The expression language, region, and source appear here.', 'en-US', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.expressionInfoHint', 4039258685413951, '[]', '4039258685413951', 'active');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039208667474251, 'Was this handbook helpful?', 'en-US', 'ui_i18n', 'langmap-web:handbook.helpful', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.helpful', 4039208667474251, '[]', '4039208667474251', 'active');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291593337392, 'Unable to load expression', 'en-US', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.inspectorFailed', 4039291593337392, '[]', '4039291593337392', 'active');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226239864187, 'Unable to load', 'en-US', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.loadFailed', 4039226239864187, '[]', '4039226239864187', 'active');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220584763101, 'Language', 'en-US', 'ui_i18n', 'langmap-web:handbook.locale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.locale', 4039220584763101, '[]', '4039220584763101', 'active');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039305476617896, 'Move down', 'en-US', 'ui_i18n', 'langmap-web:handbook.moveDown', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveDown', 4039305476617896, '[]', '4039305476617896', 'active');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039264378315169, 'Move section down', 'en-US', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveSectionDown', 4039264378315169, '[]', '4039264378315169', 'active');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039263980419517, 'Move section up', 'en-US', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveSectionUp', 4039263980419517, '[]', '4039263980419517', 'active');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039325459519266, 'Move up', 'en-US', 'ui_i18n', 'langmap-web:handbook.moveUp', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.moveUp', 4039325459519266, '[]', '4039325459519266', 'active');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039271025507837, 'Private', 'en-US', 'ui_i18n', 'langmap-web:handbook.private', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.private', 4039271025507837, '[]', '4039271025507837', 'active');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039267993342608, 'Public', 'en-US', 'ui_i18n', 'langmap-web:handbook.public', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.public', 4039267993342608, '[]', '4039267993342608', 'active');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039241948973877, 'Publish', 'en-US', 'ui_i18n', 'langmap-web:handbook.publish', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.publish', 4039241948973877, '[]', '4039241948973877', 'active');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258261318005, 'Region', 'en-US', 'ui_i18n', 'langmap-web:handbook.region', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.region', 4039258261318005, '[]', '4039258261318005', 'active');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039281597988534, 'Unable to load related expressions', 'en-US', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.relationsFailed', 4039281597988534, '[]', '4039281597988534', 'active');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039238014424846, 'Remove {text}', 'en-US', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.removeExpression', 4039238014424846, '[]', '4039238014424846', 'active');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039263998176559, 'Save draft', 'en-US', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.saveDraft', 4039263998176559, '[]', '4039263998176559', 'active');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039270028440745, 'Saving…', 'en-US', 'ui_i18n', 'langmap-web:handbook.saving', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.saving', 4039270028440745, '[]', '4039270028440745', 'active');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039225159134159, 'Section title', 'en-US', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sectionTitle', 4039225159134159, '[]', '4039225159134159', 'active');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039264953167344, 'Select an expression', 'en-US', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.selectExpression', 4039264953167344, '[]', '4039264953167344', 'active');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039223387675999, 'Source', 'en-US', 'ui_i18n', 'langmap-web:handbook.source', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.source', 4039223387675999, '[]', '4039223387675999', 'active');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039244426247807, 'AI', 'en-US', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceAi', 4039244426247807, '[]', '4039244426247807', 'active');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318696248928, 'Authority', 'en-US', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceAuthority', 4039318696248928, '[]', '4039318696248928', 'active');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039324440473230, 'User', 'en-US', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.sourceUser', 4039324440473230, '[]', '4039324440473230', 'active');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039208338888027, 'Handbook title', 'en-US', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.titlePlaceholder', 4039208338888027, '[]', '4039208338888027', 'active');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039204809556520, 'Contents', 'en-US', 'ui_i18n', 'langmap-web:handbook.toc', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.toc', 4039204809556520, '[]', '4039204809556520', 'active');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218586424477, 'View full relation graph', 'en-US', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.viewFullGraph', 4039218586424477, '[]', '4039218586424477', 'active');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039319622118803, 'Visibility', 'en-US', 'ui_i18n', 'langmap-web:handbook.visibility', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbook.visibility', 4039319622118803, '[]', '4039319622118803', 'active');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039273991762691, 'New handbook', 'en-US', 'ui_i18n', 'langmap-web:handbooks.create', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.create', 4039273991762691, '[]', '4039273991762691', 'active');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039205037236353, 'Unable to load handbooks', 'en-US', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.loadFailed', 4039205037236353, '[]', '4039205037236353', 'active');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039202100757950, 'Latest', 'en-US', 'ui_i18n', 'langmap-web:handbooks.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.newest', 4039202100757950, '[]', '4039202100757950', 'active');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039297167533555, 'No handbooks found', 'en-US', 'ui_i18n', 'langmap-web:handbooks.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.noResults', 4039297167533555, '[]', '4039297167533555', 'active');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247603774554, 'Popular', 'en-US', 'ui_i18n', 'langmap-web:handbooks.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.popular', 4039247603774554, '[]', '4039247603774554', 'active');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039321109759665, 'Search handbooks…', 'en-US', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.searchPlaceholder', 4039321109759665, '[]', '4039321109759665', 'active');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039271506815244, 'sections', 'en-US', 'ui_i18n', 'langmap-web:handbooks.sections', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.sections', 4039271506815244, '[]', '4039271506815244', 'active');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039234820809009, 'Handbooks', 'en-US', 'ui_i18n', 'langmap-web:handbooks.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'handbooks.title', 4039234820809009, '[]', '4039234820809009', 'active');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039313675995469, 'Back', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.back', 4039313675995469, '[]', '4039313675995469', 'active');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291340498970, 'Cancel', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.cancel', 4039291340498970, '[]', '4039291340498970', 'active');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247982696992, 'Close', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.close', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.close', 4039247982696992, '[]', '4039247982696992', 'active');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039261792696368, 'Create language', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.create', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.create', 4039261792696368, '[]', '4039261792696368', 'active');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039298612922394, 'Language creation failed', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.createFailed', 4039298612922394, '[]', '4039298612922394', 'active');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039232938642916, 'Creating…', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.creating', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.creating', 4039232938642916, '[]', '4039232938642916', 'active');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039276426027002, 'Enter a description', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorDescription', 4039276426027002, '[]', '4039276426027002', 'active');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039271782430821, 'Choose a Glottolog match or select "no match"', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorGlottolog', 4039271782430821, '[]', '4039271782430821', 'active');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039210698010944, 'Enter a language name', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorName', 4039210698010944, '[]', '4039210698010944', 'active');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039216473655312, 'Select a reason for community-only creation', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorReason', 4039216473655312, '[]', '4039216473655312', 'active');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039316213234006, 'Enter a language subtag to continue', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.errorTag', 4039316213234006, '[]', '4039316213234006', 'active');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246098211492, '{count} candidate(s) found', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologCandidates', 4039246098211492, '[]', '4039246098211492', 'active');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039323364172038, 'Choose a match or indicate no suitable entry', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologChoose', 4039323364172038, '[]', '4039323364172038', 'active');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039325854259152, 'Match this candidate', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologExactMatch', 4039325854259152, '[]', '4039325854259152', 'active');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039249282401723, 'dialect', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologLevelDialect', 4039249282401723, '[]', '4039249282401723', 'active');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039243488926094, 'language', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologLevelLanguage', 4039243488926094, '[]', '4039243488926094', 'active');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039197295194771, 'Glottolog has no suitable entry', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologNoMatch', 4039197295194771, '[]', '4039197295194771', 'active');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039262313884420, 'Search Glottolog…', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.glottologSearchPlaceholder', 4039262313884420, '[]', '4039262313884420', 'active');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226938266962, 'Description', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataDescription', 4039226938266962, '[]', '4039226938266962', 'active');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218699342636, 'Describe this language or variety…', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataDescriptionPlaceholder', 4039218699342636, '[]', '4039218699342636', 'active');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039203173843539, 'Name', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataName', 4039203173843539, '[]', '4039203173843539', 'active');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039325286054403, 'English name', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataNameEn', 4039325286054403, '[]', '4039325286054403', 'active');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039255034745478, 'Why is this language missing from Glottolog?', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReason', 4039255034745478, '[]', '4039255034745478', 'active');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318758556549, 'Community-specific usage', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonCommunity', 4039318758556549, '[]', '4039318758556549', 'active');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039201401042810, 'Emerging variety', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonEmerging', 4039201401042810, '[]', '4039201401042810', 'active');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039317085985011, 'Missing from Glottolog', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonMissing', 4039317085985011, '[]', '4039317085985011', 'active');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039197354913502, 'Other', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonOther', 4039197354913502, '[]', '4039197354913502', 'active');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039198381390937, 'Select a reason…', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.metadataReasonPlaceholder', 4039198381390937, '[]', '4039198381390937', 'active');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039235695377645, 'Next', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.next', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.next', 4039235695377645, '[]', '4039235695377645', 'active');

-- languageCreate.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039276071486298, 'Optional', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.optional', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.optional', 4039276071486298, '[]', '4039276071486298', 'active');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039275920750884, 'Canonical code', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewCanonicalCode', 4039275920750884, '[]', '4039275920750884', 'active');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039252684783738, 'This language already exists', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewExisting', 4039252684783738, '[]', '4039252684783738', 'active');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039201624757562, 'Use existing language', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewExistingAction', 4039201624757562, '[]', '4039201624757562', 'active');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039261792696368, 'Create language', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewTitle', 4039261792696368, '[]', '4039261792696368', 'active');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039266319466062, 'Warnings', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.previewWarnings', 4039266319466062, '[]', '4039266319466062', 'active');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258938883345, 'Provisional tag', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.provisionalTag', 4039258938883345, '[]', '4039258938883345', 'active');

-- languageCreate.requiredHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039288287235097, '* Required', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.requiredHint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.requiredHint', 4039288287235097, '[]', '4039288287235097', 'active');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039216090040527, 'Glottolog match', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepGlottolog', 4039216090040527, '[]', '4039216090040527', 'active');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039278502317771, 'Metadata', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepMetadata', 4039278502317771, '[]', '4039278502317771', 'active');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039292079507095, 'Preview & create', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepPreview', 4039292079507095, '[]', '4039292079507095', 'active');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039271969593143, 'Language tag', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.stepTag', 4039271969593143, '[]', '4039271969593143', 'active');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220584763101, 'Language', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagLanguage', 4039220584763101, '[]', '4039220584763101', 'active');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258261318005, 'Region', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagRegion', 4039258261318005, '[]', '4039258261318005', 'active');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039265998307294, 'Script', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagScript', 4039265998307294, '[]', '4039265998307294', 'active');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039305028592078, 'Search subtags…', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagSearch', 4039305028592078, '[]', '4039305028592078', 'active');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039213349000445, 'Variant', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.subtagVariant', 4039213349000445, '[]', '4039213349000445', 'active');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039300854350766, '1 variant removed', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.variantRemoved', 4039300854350766, '[]', '4039300854350766', 'active');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039288165772049, '{count} variant(s) removed', 'en-US', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageCreate.variantsRemoved', 4039288165772049, '[]', '4039288165772049', 'active');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039328989831700, 'Alphabetical', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.alphabetical', 4039328989831700, '[]', '4039328989831700', 'active');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256322954053, 'Languages', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.back', 4039256322954053, '[]', '4039256322954053', 'active');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039294118562578, 'Expressions', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.expressions', 4039294118562578, '[]', '4039294118562578', 'active');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039202100757950, 'Latest', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.latest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.latest', 4039202100757950, '[]', '4039202100757950', 'active');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226239864187, 'Unable to load', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.loadFailed', 4039226239864187, '[]', '4039226239864187', 'active');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039236848299860, 'Mapped', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.mapped', 4039236848299860, '[]', '4039236848299860', 'active');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039240488727553, 'No expressions found', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.noResults', 4039240488727553, '[]', '4039240488727553', 'active');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247603774554, 'Popular', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.popular', 4039247603774554, '[]', '4039247603774554', 'active');

-- languageDetail.representativeCities
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039209922432509, 'Representative cities', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.representativeCities', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.representativeCities', 4039209922432509, '[]', '4039209922432509', 'active');

-- languageDetail.representativeCitiesNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039276377517217, 'Reference points for exploration; not the full language distribution.', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.representativeCitiesNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.representativeCitiesNote', 4039276377517217, '[]', '4039276377517217', 'active');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039223809446541, 'Search expressions…', 'en-US', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageDetail.searchPlaceholder', 4039223809446541, '[]', '4039223809446541', 'active');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039193792488426, 'Clear selection', 'en-US', 'ui_i18n', 'langmap-web:languagePicker.clear', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.clear', 4039193792488426, '[]', '4039193792488426', 'active');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039299846909774, 'Create new language or variety', 'en-US', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.createLanguage', 4039299846909774, '[]', '4039299846909774', 'active');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039195104624261, 'No matching languages', 'en-US', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.noResults', 4039195104624261, '[]', '4039195104624261', 'active');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246945260645, 'Search languages…', 'en-US', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagePicker.placeholder', 4039246945260645, '[]', '4039246945260645', 'active');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039233498620681, 'Suggested by your browser', 'en-US', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.browserSuggested', 4039233498620681, '[]', '4039233498620681', 'active');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039251841046235, 'Help translate LangMap', 'en-US', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.helpTranslate', 4039251841046235, '[]', '4039251841046235', 'active');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039195104624261, 'No matching languages', 'en-US', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.noResults', 4039195104624261, '[]', '4039195104624261', 'active');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039306795492531, 'Recent languages', 'en-US', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languageSwitcher.recent', 4039306795492531, '[]', '4039306795492531', 'active');

-- languagesPage.addLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039199317976065, 'Add language', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.addLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.addLanguage', 4039199317976065, '[]', '4039199317976065', 'active');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039294118562578, 'Expressions', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.expressionCount', 4039294118562578, '[]', '4039294118562578', 'active');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256322954053, 'Languages', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.languageCount', 4039256322954053, '[]', '4039256322954053', 'active');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039196867547046, 'Unable to load languages', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.loadFailed', 4039196867547046, '[]', '4039196867547046', 'active');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039305123930385, 'No languages found', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.noResults', 4039305123930385, '[]', '4039305123930385', 'active');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246945260645, 'Search languages…', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.searchPlaceholder', 4039246945260645, '[]', '4039246945260645', 'active');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039263037467916, 'A–Z', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.sortAlphabetical', 4039263037467916, '[]', '4039263037467916', 'active');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039284364068927, 'Count', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.sortCount', 4039284364068927, '[]', '4039284364068927', 'active');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039317622660080, 'Explore expressions and mappings across all languages', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.subtitle', 4039317622660080, '[]', '4039317622660080', 'active');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256322954053, 'Languages', 'en-US', 'ui_i18n', 'langmap-web:languagesPage.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'languagesPage.title', 4039256322954053, '[]', '4039256322954053', 'active');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039242362911495, 'Anchor', 'en-US', 'ui_i18n', 'langmap-web:mapLens.anchor', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.anchor', 4039242362911495, '[]', '4039242362911495', 'active');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039274630245077, 'Back to mapping', 'en-US', 'ui_i18n', 'langmap-web:mapLens.back', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.back', 4039274630245077, '[]', '4039274630245077', 'active');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039285488213874, '{count} languages', 'en-US', 'ui_i18n', 'langmap-web:mapLens.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.languages', 4039285488213874, '[]', '4039285488213874', 'active');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226239864187, 'Unable to load', 'en-US', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.loadFailed', 4039226239864187, '[]', '4039226239864187', 'active');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039240565339731, 'Mapping members', 'en-US', 'ui_i18n', 'langmap-web:mapLens.members', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.members', 4039240565339731, '[]', '4039240565339731', 'active');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039279250603930, 'No geographic distribution data for this concept', 'en-US', 'ui_i18n', 'langmap-web:mapLens.noData', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.noData', 4039279250603930, '[]', '4039279250603930', 'active');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039302107835931, '{count} regions', 'en-US', 'ui_i18n', 'langmap-web:mapLens.regions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.regions', 4039302107835931, '[]', '4039302107835931', 'active');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039208466994401, 'Concept distribution', 'en-US', 'ui_i18n', 'langmap-web:mapLens.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mapLens.title', 4039208466994401, '[]', '4039208466994401', 'active');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039259535351101, 'Add and create mapping', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addAndMap', 4039259535351101, '[]', '4039259535351101', 'active');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039323156297807, 'Add expression', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addExpression', 4039323156297807, '[]', '4039323156297807', 'active');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039198581489142, 'Unable to add expression', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.addFailed', 4039198581489142, '[]', '4039198581489142', 'active');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218340751327, 'Adding…', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.adding', 4039218340751327, '[]', '4039218340751327', 'active');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318696248928, 'Authority', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.authority', 4039318696248928, '[]', '4039318696248928', 'active');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039291257989597, 'Breadcrumb', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.breadcrumb', 4039291257989597, '[]', '4039291257989597', 'active');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039267828069642, 'Close quick add', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.closeQuickAdd', 4039267828069642, '[]', '4039267828069642', 'active');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039295569136473, 'Contribute mapping', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.contribute', 4039295569136473, '[]', '4039295569136473', 'active');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246116479366, 'direct mappings', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.direct', 4039246116479366, '[]', '4039246116479366', 'active');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039246255388206, 'Enter expression and language code', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.enterRequired', 4039246255388206, '[]', '4039246255388206', 'active');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318048221959, 'Expression', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.expression', 4039318048221959, '[]', '4039318048221959', 'active');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039242456703266, 'Enter expression…', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.expressionPlaceholder', 4039242456703266, '[]', '4039242456703266', 'active');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039261403730767, 'Graph', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.graph', 4039261403730767, '[]', '4039261403730767', 'active');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039277332090535, 'Home', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.home', 4039277332090535, '[]', '4039277332090535', 'active');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039277202124053, 'hops', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.hops', 4039277202124053, '[]', '4039277202124053', 'active');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039318157522164, 'indirect', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.indirect', 4039318157522164, '[]', '4039318157522164', 'active');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039210176324565, 'Language code', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.languageCode', 4039210176324565, '[]', '4039210176324565', 'active');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039209337204607, 'e.g. en / zh-Hant', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.languageCodePlaceholder', 4039209337204607, '[]', '4039209337204607', 'active');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039282174712441, 'List', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.list', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.list', 4039282174712441, '[]', '4039282174712441', 'active');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226239864187, 'Unable to load', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.loadFailed', 4039226239864187, '[]', '4039226239864187', 'active');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039300809727185, 'Mapping set', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.mappingSet', 4039300809727185, '[]', '4039300809727185', 'active');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039325677769541, 'No mappings yet', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.noMappings', 4039325677769541, '[]', '4039325677769541', 'active');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039276071486298, 'Optional', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.optional', 4039276071486298, '[]', '4039276071486298', 'active');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039324958036767, 'Quickly add expression', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.quickAdd', 4039324958036767, '[]', '4039324958036767', 'active');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039212842396077, 'Add an expression and map it directly to the current expression.', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.quickAddLead', 4039212842396077, '[]', '4039212842396077', 'active');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258261318005, 'Region', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.region', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.region', 4039258261318005, '[]', '4039258261318005', 'active');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039324440473230, 'User', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.user', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.user', 4039324440473230, '[]', '4039324440473230', 'active');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039311455815203, 'View this concept on map', 'en-US', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'mappingDetail.viewMap', 4039311455815203, '[]', '4039311455815203', 'active');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039297982961690, 'Close menu', 'en-US', 'ui_i18n', 'langmap-web:nav.closeMenu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.closeMenu', 4039297982961690, '[]', '4039297982961690', 'active');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039312030295503, 'Contribute', 'en-US', 'ui_i18n', 'langmap-web:nav.contribute', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.contribute', 4039312030295503, '[]', '4039312030295503', 'active');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039234820809009, 'Handbooks', 'en-US', 'ui_i18n', 'langmap-web:nav.handbooks', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.handbooks', 4039234820809009, '[]', '4039234820809009', 'active');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039277332090535, 'Home', 'en-US', 'ui_i18n', 'langmap-web:nav.home', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.home', 4039277332090535, '[]', '4039277332090535', 'active');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039256322954053, 'Languages', 'en-US', 'ui_i18n', 'langmap-web:nav.languages', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.languages', 4039256322954053, '[]', '4039256322954053', 'active');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039223542474758, 'Menu', 'en-US', 'ui_i18n', 'langmap-web:nav.menu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.menu', 4039223542474758, '[]', '4039223542474758', 'active');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039278126309563, 'Open menu', 'en-US', 'ui_i18n', 'langmap-web:nav.openMenu', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.openMenu', 4039278126309563, '[]', '4039278126309563', 'active');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039289790753346, 'Search expressions', 'en-US', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.searchExpressions', 4039289790753346, '[]', '4039289790753346', 'active');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039274956726587, 'Sign in', 'en-US', 'ui_i18n', 'langmap-web:nav.signIn', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.signIn', 4039274956726587, '[]', '4039274956726587', 'active');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039277593503154, 'Sign out', 'en-US', 'ui_i18n', 'langmap-web:nav.signOut', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.signOut', 4039277593503154, '[]', '4039277593503154', 'active');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039323364353816, 'Submit search', 'en-US', 'ui_i18n', 'langmap-web:nav.submitSearch', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.submitSearch', 4039323364353816, '[]', '4039323364353816', 'active');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039195322568967, 'Switch interface language', 'en-US', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'nav.switchLanguage', 4039195322568967, '[]', '4039195322568967', 'active');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039328989831700, 'Alphabetical', 'en-US', 'ui_i18n', 'langmap-web:search.alphabetical', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.alphabetical', 4039328989831700, '[]', '4039328989831700', 'active');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039199272982370, 'Tip: search currently matches expression text. Translation (semantic) search is coming later.', 'en-US', 'ui_i18n', 'langmap-web:search.hint', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.hint', 4039199272982370, '[]', '4039199272982370', 'active');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039218663313831, 'Search failed', 'en-US', 'ui_i18n', 'langmap-web:search.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.loadFailed', 4039218663313831, '[]', '4039218663313831', 'active');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039202100757950, 'Latest', 'en-US', 'ui_i18n', 'langmap-web:search.newest', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.newest', 4039202100757950, '[]', '4039202100757950', 'active');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039217192958680, 'No results found', 'en-US', 'ui_i18n', 'langmap-web:search.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.noResults', 4039217192958680, '[]', '4039217192958680', 'active');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039223809446541, 'Search expressions…', 'en-US', 'ui_i18n', 'langmap-web:search.placeholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.placeholder', 4039223809446541, '[]', '4039223809446541', 'active');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039247603774554, 'Popular', 'en-US', 'ui_i18n', 'langmap-web:search.popular', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.popular', 4039247603774554, '[]', '4039247603774554', 'active');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039304070680160, '{count} result | {count} results', 'en-US', 'ui_i18n', 'langmap-web:search.results', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.results', 4039304070680160, '[]', '4039304070680160', 'active');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039290847632508, 'Sort', 'en-US', 'ui_i18n', 'langmap-web:search.sort', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.sort', 4039290847632508, '[]', '4039290847632508', 'active');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039289790753346, 'Search expressions', 'en-US', 'ui_i18n', 'langmap-web:search.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'search.title', 4039289790753346, '[]', '4039289790753346', 'active');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039262743786868, 'Add a language to translate', 'en-US', 'ui_i18n', 'langmap-web:translate.addLocale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.addLocale', 4039262743786868, '[]', '4039262743786868', 'active');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039232809480299, 'Submit {count} translations', 'en-US', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.batchSubmit', 4039232809480299, '[]', '4039232809480299', 'active');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039272108076077, 'Current translation', 'en-US', 'ui_i18n', 'langmap-web:translate.candidate', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.candidate', 4039272108076077, '[]', '4039272108076077', 'active');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039307820065458, 'Choose a registered language', 'en-US', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.chooseRegistryLanguage', 4039307820065458, '[]', '4039307820065458', 'active');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039302750746982, 'Translation coverage', 'en-US', 'ui_i18n', 'langmap-web:translate.coverage', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.coverage', 4039302750746982, '[]', '4039302750746982', 'active');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039330567083979, '{count} shown', 'en-US', 'ui_i18n', 'langmap-web:translate.displayed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.displayed', 4039330567083979, '[]', '4039330567083979', 'active');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039263180329406, 'COMMUNITY LOCALIZATION', 'en-US', 'ui_i18n', 'langmap-web:translate.eyebrow', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.eyebrow', 4039263180329406, '[]', '4039263180329406', 'active');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039280361786422, 'Enter translation…', 'en-US', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.inputPlaceholder', 4039280361786422, '[]', '4039280361786422', 'active');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039210189975752, 'Unable to load translation workbench', 'en-US', 'ui_i18n', 'langmap-web:translate.loadFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loadFailed', 4039210189975752, '[]', '4039210189975752', 'active');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039198023470406, 'Loading…', 'en-US', 'ui_i18n', 'langmap-web:translate.loading', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loading', 4039198023470406, '[]', '4039198023470406', 'active');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039286503270980, 'Target language', 'en-US', 'ui_i18n', 'langmap-web:translate.locale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.locale', 4039286503270980, '[]', '4039286503270980', 'active');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039255464963972, 'Unable to load locale list', 'en-US', 'ui_i18n', 'langmap-web:translate.localesFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.localesFailed', 4039255464963972, '[]', '4039255464963972', 'active');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039285344096668, 'Sign in to submit translations; candidates are selected by mapping score and fallback is used when no positive candidate exists.', 'en-US', 'ui_i18n', 'langmap-web:translate.loginNote', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.loginNote', 4039285344096668, '[]', '4039285344096668', 'active');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039194547587951, 'No matching copy found.', 'en-US', 'ui_i18n', 'langmap-web:translate.noResults', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.noResults', 4039194547587951, '[]', '4039194547587951', 'active');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039259327128845, 'Preview', 'en-US', 'ui_i18n', 'langmap-web:translate.preview', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.preview', 4039259327128845, '[]', '4039259327128845', 'active');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039299601179530, 'Reference language', 'en-US', 'ui_i18n', 'langmap-web:translate.reference', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.reference', 4039299601179530, '[]', '4039299601179530', 'active');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039252284218610, 'Search key or source text…', 'en-US', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.searchPlaceholder', 4039252284218610, '[]', '4039252284218610', 'active');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039327112090503, 'Choose translation language', 'en-US', 'ui_i18n', 'langmap-web:translate.selectLocale', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.selectLocale', 4039327112090503, '[]', '4039327112090503', 'active');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039304389733603, 'EN source', 'en-US', 'ui_i18n', 'langmap-web:translate.source', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.source', 4039304389733603, '[]', '4039304389733603', 'active');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039325838792223, 'Start', 'en-US', 'ui_i18n', 'langmap-web:translate.start', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.start', 4039325838792223, '[]', '4039325838792223', 'active');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039220418642934, 'Submission failed', 'en-US', 'ui_i18n', 'langmap-web:translate.submitFailed', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitFailed', 4039220418642934, '[]', '4039220418642934', 'active');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039227663321003, 'Submit mapping', 'en-US', 'ui_i18n', 'langmap-web:translate.submitMapping', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitMapping', 4039227663321003, '[]', '4039227663321003', 'active');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039196288099856, 'Submitted', 'en-US', 'ui_i18n', 'langmap-web:translate.submitted', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.submitted', 4039196288099856, '[]', '4039196288099856', 'active');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039258395876255, 'Help make LangMap interface text natural and useful.', 'en-US', 'ui_i18n', 'langmap-web:translate.subtitle', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.subtitle', 4039258395876255, '[]', '4039258395876255', 'active');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039292410329094, 'Translation workbench', 'en-US', 'ui_i18n', 'langmap-web:translate.title', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.title', 4039292410329094, '[]', '4039292410329094', 'active');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039226075472990, 'Translate {key}', 'en-US', 'ui_i18n', 'langmap-web:translate.translateKey', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translateKey', 4039226075472990, '[]', '4039226075472990', 'active');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039206423275507, 'translated', 'en-US', 'ui_i18n', 'langmap-web:translate.translated', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translated', 4039206423275507, '[]', '4039206423275507', 'active');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4039241150478337, 'Translation', 'en-US', 'ui_i18n', 'langmap-web:translate.translation', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('langmap-web', 'translate.translation', 4039241150478337, '[]', '4039241150478337', 'active');

-- 3. Translation expressions and edges (1228 rows)
-- Locale es-ES
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238849669395633, 'Correo electrónico', 'es-ES', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-8238849669395633', 4039278566303563, 8238849669395633, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238895139342736, '¿Ya tienes cuenta?', 'es-ES', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-8238895139342736', 4039276962119789, 8238895139342736, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238874217048889, 'Iniciar sesión', 'es-ES', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-8238874217048889', 4039274956726587, 8238874217048889, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238805651509552, '¿No tienes cuenta?', 'es-ES', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-8238805651509552', 4039210512038996, 8238805651509552, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238787804410475, 'Operación fallida', 'es-ES', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-8238787804410475', 4039224592934601, 8238787804410475, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238884968165994, 'Contraseña', 'es-ES', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-8238884968165994', 4039283475919761, 8238884968165994, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238782021267674, 'Procesando…', 'es-ES', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-8238782021267674', 4039290683252068, 8238782021267674, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238860302125171, 'Crear cuenta', 'es-ES', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-8238860302125171', 4039254012036431, 8238860302125171, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238784722779881, 'Nombre de usuario', 'es-ES', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-8238784722779881', 4039318948959047, 8238784722779881, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780006318847, 'Cancelar', 'es-ES', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-8238780006318847', 4039291340498970, 8238780006318847, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238864833590809, 'Cerrar', 'es-ES', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-8238864833590809', 4039247982696992, 8238864833590809, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882102609984, 'Idioma', 'es-ES', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-8238882102609984', 4039220584763101, 8238882102609984, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238810134661069, 'Idiomas', 'es-ES', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-8238810134661069', 4039256322954053, 8238810134661069, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840499744940, 'Cargando…', 'es-ES', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-8238840499744940', 4039198023470406, 8238840499744940, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238885499047810, 'Buscar', 'es-ES', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-8238885499047810', 4039307974483127, 8238885499047810, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238890552263785, 'Enviar', 'es-ES', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-8238890552263785', 4039245021981976, 8238890552263785, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238881627136393, 'Tamaño real 100%', 'es-ES', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-8238881627136393', 4039203196919686, 8238881627136393, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238859911787876, 'Anónimo', 'es-ES', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-8238859911787876', 4039253518652932, 8238859911787876, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238793109572080, '{count} nodos hijos; haz clic para colapsar', 'es-ES', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-8238793109572080', 4039322475101146, 8238793109572080, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238833858905131, 'Cada arista es una relación directa independiente que se puede votar a favor o en contra; las relaciones con baja puntuación se colapsan.', 'es-ES', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-8238833858905131', 4039318570928695, 8238833858905131, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238900715798727, 'Grafo de relaciones a crear', 'es-ES', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-8238900715798727', 4039280324996322, 8238900715798727, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238797386026516, 'Cerrar panel de información', 'es-ES', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-8238797386026516', 4039213218065468, 8238797386026516, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238895572493231, 'Colapsar', 'es-ES', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-8238895572493231', 4039314752746797, 8238895572493231, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238784952325990, 'Colapsar rama hija', 'es-ES', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-8238784952325990', 4039311612904008, 8238784952325990, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238841041674710, 'Colapsar al primer nivel', 'es-ES', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-8238841041674710', 4039252699292725, 8238841041674710, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238901197004102, 'Hace {count} días', 'es-ES', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-8238901197004102', 4039305722497088, 8238901197004102, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238824300291769, 'Profundidad {depth}', 'es-ES', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-8238824300291769', 4039308224575343, 8238824300291769, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238796417810315, 'Expresiones con relación directa', 'es-ES', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-8238796417810315', 4039211316535202, 8238796417810315, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238871293772929, 'Votar en contra', 'es-ES', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-8238871293772929', 4039281764373654, 8238871293772929, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238886734993297, '{count} aristas', 'es-ES', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-8238886734993297', 4039196655494558, 8238886734993297, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238793948624030, 'Aún no hay datos', 'es-ES', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-8238793948624030', 4039290061486601, 8238793948624030, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238880247450899, 'Salir de pantalla completa', 'es-ES', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-8238880247450899', 4039285164681796, 8238880247450899, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238869873931783, 'Expandir', 'es-ES', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-8238869873931783', 4039246642706739, 8238869873931783, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836495241583, 'Expandir todo', 'es-ES', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-8238836495241583', 4039323395460079, 8238836495241583, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238886513437110, 'Expandir rama hija', 'es-ES', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-8238886513437110', 4039227367141393, 8238886513437110, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238812749931415, 'Expresión', 'es-ES', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-8238812749931415', 4039318048221959, 8238812749931415, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840126844546, 'Filtrar idiomas…', 'es-ES', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-8238840126844546', 4039264822897467, 8238840126844546, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238852085276403, 'Pantalla completa', 'es-ES', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-8238852085276403', 4039273948571546, 8238852085276403, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238847134119575, 'Grafo de relaciones de expresiones', 'es-ES', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-8238847134119575', 4039229813257256, 8238847134119575, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840092287319, 'Cargando grafo…', 'es-ES', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-8238840092287319', 4039220553457070, 8238840092287319, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238822519704549, 'Modo grafo', 'es-ES', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-8238822519704549', 4039307692947617, 8238822519704549, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238845355058933, '{nodes} nodos mapeados · {edges} relaciones', 'es-ES', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-8238845355058933', 4039220204112184, 8238845355058933, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238804274190432, 'Barra de herramientas del grafo', 'es-ES', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-8238804274190432', 4039247632198973, 8238804274190432, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238851074702269, 'Lista jerárquica de relaciones', 'es-ES', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-8238851074702269', 4039262167197365, 8238851074702269, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238816622468834, 'Saltos', 'es-ES', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-8238816622468834', 4039218745350539, 8238816622468834, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238896045727870, 'Hace {count} horas', 'es-ES', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-8238896045727870', 4039261676051383, 8238896045727870, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238839515251943, 'Ahora mismo', 'es-ES', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-8238839515251943', 4039295793832731, 8238839515251943, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238878744396003, 'No se pudieron cargar los idiomas', 'es-ES', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-8238878744396003', 4039196867547046, 8238878744396003, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238911148591803, 'Modo lista', 'es-ES', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-8238911148591803', 4039267846517304, 8238911148591803, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238790926251827, 'Cargar más', 'es-ES', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-8238790926251827', 4039257935440261, 8238790926251827, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238872207465670, 'Cargando expresiones relacionadas', 'es-ES', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-8238872207465670', 4039208559662390, 8238872207465670, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238820875663841, 'Relación', 'es-ES', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-8238820875663841', 4039299531874366, 8238820875663841, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238871747595702, 'Puntuación de la relación', 'es-ES', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-8238871747595702', 4039291250524588, 8238871747595702, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238799039719397, 'Hace {count} minutos', 'es-ES', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-8238799039719397', 4039319528355130, 8238799039719397, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238800970609989, 'Más acciones', 'es-ES', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-8238800970609989', 4039216903072408, 8238800970609989, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238884492478703, '{count} relaciones más disponibles en el grafo completo', 'es-ES', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-8238884492478703', 4039267933793525, 8238884492478703, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836082266248, 'Aún no hay relaciones directas', 'es-ES', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-8238836082266248', 4039206484078170, 8238836082266248, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238865590196980, 'No se encontraron expresiones', 'es-ES', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-8238865590196980', 4039240488727553, 8238865590196980, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238895459380928, '{count} nodos', 'es-ES', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-8238895459380928', 4039205391794884, 8238895459380928, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835080268064, 'Información del nodo', 'es-ES', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-8238835080268064', 4039321854954979, 8238835080268064, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238791364727685, 'Otras relaciones', 'es-ES', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-8238791364727685', 4039301412743754, 8238791364727685, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912667779257, 'Expresiones relacionadas', 'es-ES', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-8238912667779257', 4039285912508809, 8238912667779257, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882886770166, '{count} relaciones', 'es-ES', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-8238882886770166', 4039195207546455, 8238882886770166, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238852872147235, 'Eliminar {code}', 'es-ES', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-8238852872147235', 4039257785545173, 8238852872147235, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238806109422151, 'Restablecer diseño', 'es-ES', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-8238806109422151', 4039213227329958, 8238806109422151, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238886927774843, 'Nodo raíz', 'es-ES', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-8238886927774843', 4039280733662867, 8238886927774843, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238885499047810, 'Buscar', 'es-ES', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-8238885499047810', 4039307974483127, 8238885499047810, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238801560991616, 'Buscar expresiones…', 'es-ES', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-8238801560991616', 4039223809446541, 8238801560991616, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238820593493778, 'Buscando…', 'es-ES', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-8238820593493778', 4039241606316828, 8238820593493778, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238778988336027, 'Selecciona un nodo en el grafo para ver detalles', 'es-ES', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-8238778988336027', 4039258954601880, 8238778988336027, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836573682464, 'Ruta de origen', 'es-ES', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-8238836573682464', 4039267388033524, 8238836573682464, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238830054796897, 'Votar a favor', 'es-ES', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-8238830054796897', 4039305875761888, 8238830054796897, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238863749066389, 'Ver detalles de la expresión', 'es-ES', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-8238863749066389', 4039285357620964, 8238863749066389, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238824029846981, 'Voto fallido; revertido', 'es-ES', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-8238824029846981', 4039310388216878, 8238824029846981, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836172727774, 'Acercar', 'es-ES', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-8238836172727774', 4039307035795639, 8238836172727774, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238867348095171, 'Alejar', 'es-ES', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-8238867348095171', 4039306926563555, 8238867348095171, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832489828210, '+ Añadir expresión', 'es-ES', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-8238832489828210', 4039234711174892, 8238832489828210, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238908312625574, 'Grafo completo', 'es-ES', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-8238908312625574', 4039210891494791, 8238908312625574, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238846940894776, 'Eliminar', 'es-ES', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-8238846940894776', 4039233937430393, 8238846940894776, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238818070092434, '{count} relaciones directas', 'es-ES', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-8238818070092434', 4039258582305025, 8238818070092434, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238812749931415, 'Expresión', 'es-ES', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-8238812749931415', 4039318048221959, 8238812749931415, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238857557072334, '{count} expresiones', 'es-ES', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-8238857557072334', 4039208226237843, 8238857557072334, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238880450897786, 'Introduce una expresión…', 'es-ES', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-8238880450897786', 4039264797643778, 8238880450897786, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882102609984, 'Idioma', 'es-ES', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-8238882102609984', 4039220584763101, 8238882102609984, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238851692554612, 'Envía un grupo de expresiones que significan lo mismo. El sistema crea relaciones directas entre cada par. Las expresiones existentes se vinculan automáticamente sin duplicados.', 'es-ES', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-8238851692554612', 4039228008118707, 8238851692554612, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238855136774365, 'Se requieren al menos 2 filas con idioma y expresión', 'es-ES', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-8238855136774365', 4039286212175439, 8238855136774365, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238890552263785, 'Enviar', 'es-ES', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-8238890552263785', 4039245021981976, 8238890552263785, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238779504812185, 'Error al enviar', 'es-ES', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-8238779504812185', 4039220418642934, 8238779504812185, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238795705425663, 'Enviando…', 'es-ES', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-8238795705425663', 4039286291917398, 8238795705425663, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238798563596493, 'Etiquetas', 'es-ES', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-8238798563596493', 4039312686530045, 8238798563596493, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238911838955710, 'Contribución por lotes', 'es-ES', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-8238911838955710', 4039256753970050, 8238911838955710, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238808791770593, 'Volver al inicio', 'es-ES', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-8238808791770593', 4039244552136331, 8238808791770593, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912795486222, 'No se pudo cargar', 'es-ES', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-8238912795486222', 4039226239864187, 8238912795486222, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238865178829181, 'Página no encontrada', 'es-ES', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-8238865178829181', 4039247795890512, 8238865178829181, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238878639042713, 'Todo', 'es-ES', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-8238878639042713', 4039202333969475, 8238878639042713, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238905578948853, 'Contribuir una relación →', 'es-ES', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-8238905578948853', 4039241704787781, 8238905578948853, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832266064986, 'Popular', 'es-ES', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-8238832266064986', 4039247603774554, 8238832266064986, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238893631572381, 'Relaciones + nuevas expresiones', 'es-ES', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-8238893631572381', 4039260809744465, 8238893631572381, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238866625347894, '¿No encuentras lo que buscas?', 'es-ES', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-8238866625347894', 4039254190870260, 8238866625347894, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238884641155270, 'Nuevas contribuciones', 'es-ES', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-8238884641155270', 4039302900266643, 8238884641155270, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835683799526, 'Más reciente', 'es-ES', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-8238835683799526', 4039202100757950, 8238835683799526, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238857423194603, 'Relaciones populares', 'es-ES', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-8238857423194603', 4039245957647571, 8238857423194603, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238856200312777, 'Por puntuación · esta semana', 'es-ES', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-8238856200312777', 4039291578874799, 8238856200312777, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238860646565259, 'El pulso más reciente del grafo semántico: relaciones populares y nuevas contribuciones.', 'es-ES', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-8238860646565259', 4039275101235147, 8238860646565259, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832721073078, 'Actividad', 'es-ES', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-8238832721073078', 4039218305844177, 8238832721073078, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238877520869535, 'Añadir expresión', 'es-ES', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-8238877520869535', 4039323156297807, 8238877520869535, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238888929387672, 'Añadir sección', 'es-ES', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-8238888929387672', 4039302981121903, 8238888929387672, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238868800316102, 'Lista de manuales', 'es-ES', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-8238868800316102', 4039275162095516, 8238868800316102, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238890592441544, 'Capítulo {number}', 'es-ES', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-8238890592441544', 4039264579862218, 8238890592441544, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238783765196032, 'Cerrar información de la expresión', 'es-ES', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-8238783765196032', 4039238473169231, 8238783765196032, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238895572493231, 'Colapsar', 'es-ES', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-8238895572493231', 4039314752746797, 8238895572493231, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238828737293145, 'Eliminar sección', 'es-ES', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-8238828737293145', 4039212000754015, 8238828737293145, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238884346579588, 'Editar manual', 'es-ES', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-8238884346579588', 4039244157921703, 8238884346579588, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238852801852264, 'Información de la expresión', 'es-ES', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-8238852801852264', 4039248386595592, 8238852801852264, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238899882539201, 'El idioma, la región y la fuente de la expresión aparecerán aquí.', 'es-ES', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-8238899882539201', 4039258685413951, 8238899882539201, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238846678080757, '¿Te resultó útil este manual?', 'es-ES', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-8238846678080757', 4039208667474251, 8238846678080757, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238852870259674, 'No se pudo cargar la expresión', 'es-ES', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-8238852870259674', 4039291593337392, 8238852870259674, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912795486222, 'No se pudo cargar', 'es-ES', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-8238912795486222', 4039226239864187, 8238912795486222, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882102609984, 'Idioma', 'es-ES', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-8238882102609984', 4039220584763101, 8238882102609984, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238801930458853, 'Mover abajo', 'es-ES', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-8238801930458853', 4039305476617896, 8238801930458853, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238822095893750, 'Mover sección abajo', 'es-ES', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-8238822095893750', 4039264378315169, 8238822095893750, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238834972423104, 'Mover sección arriba', 'es-ES', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-8238834972423104', 4039263980419517, 8238834972423104, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238782417329210, 'Mover arriba', 'es-ES', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-8238782417329210', 4039325459519266, 8238782417329210, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238904416630665, 'Privado', 'es-ES', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-8238904416630665', 4039271025507837, 8238904416630665, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238891441221059, 'Público', 'es-ES', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-8238891441221059', 4039267993342608, 8238891441221059, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238894501639782, 'Publicar', 'es-ES', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-8238894501639782', 4039241948973877, 8238894501639782, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238871699308094, 'Región', 'es-ES', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-8238871699308094', 4039258261318005, 8238871699308094, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238911933591516, 'No se pudieron cargar las expresiones relacionadas', 'es-ES', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-8238911933591516', 4039281597988534, 8238911933591516, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238827523948408, 'Eliminar {text}', 'es-ES', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-8238827523948408', 4039238014424846, 8238827523948408, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882771230227, 'Guardar borrador', 'es-ES', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-8238882771230227', 4039263998176559, 8238882771230227, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238900412173140, 'Guardando…', 'es-ES', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-8238900412173140', 4039270028440745, 8238900412173140, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238864957935661, 'Título de la sección', 'es-ES', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-8238864957935661', 4039225159134159, 8238864957935661, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238829070174365, 'Seleccionar una expresión', 'es-ES', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-8238829070174365', 4039264953167344, 8238829070174365, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238873506529657, 'Fuente', 'es-ES', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-8238873506529657', 4039223387675999, 8238873506529657, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238914054042293, 'IA', 'es-ES', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-8238914054042293', 4039244426247807, 8238914054042293, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238854937147215, 'Autoridad', 'es-ES', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-8238854937147215', 4039318696248928, 8238854937147215, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238906477534047, 'Usuario', 'es-ES', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-8238906477534047', 4039324440473230, 8238906477534047, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238890221641097, 'Título del manual', 'es-ES', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-8238890221641097', 4039208338888027, 8238890221641097, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238800925163598, 'Contenido', 'es-ES', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-8238800925163598', 4039204809556520, 8238800925163598, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238837351416157, 'Ver grafo completo de relaciones', 'es-ES', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-8238837351416157', 4039218586424477, 8238837351416157, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238866587935018, 'Visibilidad', 'es-ES', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-8238866587935018', 4039319622118803, 8238866587935018, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238821959610875, 'Nuevo manual', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-8238821959610875', 4039273991762691, 8238821959610875, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238809670897836, 'No se pudieron cargar los manuales', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-8238809670897836', 4039205037236353, 8238809670897836, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835683799526, 'Más reciente', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-8238835683799526', 4039202100757950, 8238835683799526, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238795710218586, 'No se encontraron manuales', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-8238795710218586', 4039297167533555, 8238795710218586, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832266064986, 'Popular', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-8238832266064986', 4039247603774554, 8238832266064986, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238827204107786, 'Buscar manuales…', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-8238827204107786', 4039321109759665, 8238827204107786, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238802330612358, 'secciones', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-8238802330612358', 4039271506815244, 8238802330612358, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238902491232675, 'Manuales', 'es-ES', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-8238902491232675', 4039234820809009, 8238902491232675, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238862670828078, 'Atrás', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-8238862670828078', 4039313675995469, 8238862670828078, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780006318847, 'Cancelar', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-8238780006318847', 4039291340498970, 8238780006318847, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238864833590809, 'Cerrar', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-8238864833590809', 4039247982696992, 8238864833590809, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238886230801407, 'Crear idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-8238886230801407', 4039261792696368, 8238886230801407, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238874885739510, 'Error al crear el idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-8238874885739510', 4039298612922394, 8238874885739510, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238808158649083, 'Creando…', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-8238808158649083', 4039232938642916, 8238808158649083, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238813334569961, 'Introduce una descripción', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-8238813334569961', 4039276426027002, 8238813334569961, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912762814084, 'Elige una coincidencia Glottolog o selecciona «sin coincidencia»', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-8238912762814084', 4039271782430821, 8238912762814084, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238795685136050, 'Introduce un nombre de idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-8238795685136050', 4039210698010944, 8238795685136050, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238898674626309, 'Selecciona un motivo para la creación solo comunitaria', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-8238898674626309', 4039216473655312, 8238898674626309, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238806971692450, 'Introduce una subetiqueta de idioma para continuar', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-8238806971692450', 4039316213234006, 8238806971692450, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238781276989229, '{count} candidato(s) encontrado(s)', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-8238781276989229', 4039246098211492, 8238781276989229, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238850975028484, 'Elige una coincidencia o indica que no hay entrada adecuada', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-8238850975028484', 4039323364172038, 8238850975028484, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238896525723843, 'Elegir este candidato', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-8238896525723843', 4039325854259152, 8238896525723843, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238877297412990, 'dialecto', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-8238877297412990', 4039249282401723, 8238877297412990, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238805602015380, 'idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-8238805602015380', 4039243488926094, 8238805602015380, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238795263430967, 'Glottolog no tiene una entrada adecuada', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-8238795263430967', 4039197295194771, 8238795263430967, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912605862171, 'Buscar en Glottolog…', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-8238912605862171', 4039262313884420, 8238912605862171, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238846895879598, 'Descripción', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-8238846895879598', 4039226938266962, 8238846895879598, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238845549661689, 'Describe este idioma o variedad…', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-8238845549661689', 4039218699342636, 8238845549661689, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238878365979422, 'Nombre', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-8238878365979422', 4039203173843539, 8238878365979422, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238860185758575, 'Nombre en inglés', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-8238860185758575', 4039325286054403, 8238860185758575, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238816080288306, '¿Por qué falta este idioma en Glottolog?', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-8238816080288306', 4039255034745478, 8238816080288306, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238809766592183, 'Uso específico de la comunidad', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-8238809766592183', 4039318758556549, 8238809766592183, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238850713868198, 'Variante emergente', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-8238850713868198', 4039201401042810, 8238850713868198, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238853221425114, 'Falta en Glottolog', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-8238853221425114', 4039317085985011, 8238853221425114, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238817477969711, 'Otro', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-8238817477969711', 4039197354913502, 8238817477969711, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238808418576206, 'Selecciona un motivo…', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-8238808418576206', 4039198381390937, 8238808418576206, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238854452033278, 'Siguiente', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-8238854452033278', 4039235695377645, 8238854452033278, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238837578499693, 'Código canónico', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-8238837578499693', 4039275920750884, 8238837578499693, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238782474492950, 'Este idioma ya existe', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-8238782474492950', 4039252684783738, 8238782474492950, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238812185711908, 'Usar idioma existente', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-8238812185711908', 4039201624757562, 8238812185711908, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238886230801407, 'Crear idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-8238886230801407', 4039261792696368, 8238886230801407, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238819359270191, 'Advertencias', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-8238819359270191', 4039266319466062, 8238819359270191, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238788994026444, 'Etiqueta provisional', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-8238788994026444', 4039258938883345, 8238788994026444, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238906971709410, 'Coincidencia Glottolog', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-8238906971709410', 4039216090040527, 8238906971709410, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238857735504777, 'Metadatos', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-8238857735504777', 4039278502317771, 8238857735504777, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238823188519655, 'Vista previa y crear', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-8238823188519655', 4039292079507095, 8238823188519655, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835646300812, 'Etiqueta de idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-8238835646300812', 4039271969593143, 8238835646300812, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882102609984, 'Idioma', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-8238882102609984', 4039220584763101, 8238882102609984, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238871699308094, 'Región', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-8238871699308094', 4039258261318005, 8238871699308094, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238837058364075, 'Escritura', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-8238837058364075', 4039265998307294, 8238837058364075, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238914981866256, 'Buscar subetiquetas…', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-8238914981866256', 4039305028592078, 8238914981866256, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238796736386013, 'Variante', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-8238796736386013', 4039213349000445, 8238796736386013, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238896387707498, '1 variante eliminada', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-8238896387707498', 4039300854350766, 8238896387707498, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238797307483757, '{count} variante(s) eliminada(s)', 'es-ES', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-8238797307483757', 4039288165772049, 8238797307483757, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840052438546, 'Alfabético', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-8238840052438546', 4039328989831700, 8238840052438546, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238810134661069, 'Idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-8238810134661069', 4039256322954053, 8238810134661069, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238839612608480, 'Expresiones', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-8238839612608480', 4039294118562578, 8238839612608480, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835683799526, 'Más reciente', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-8238835683799526', 4039202100757950, 8238835683799526, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912795486222, 'No se pudo cargar', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-8238912795486222', 4039226239864187, 8238912795486222, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238806148360412, 'Mapeado', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-8238806148360412', 4039236848299860, 8238806148360412, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238865590196980, 'No se encontraron expresiones', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-8238865590196980', 4039240488727553, 8238865590196980, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832266064986, 'Popular', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-8238832266064986', 4039247603774554, 8238832266064986, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238801560991616, 'Buscar expresiones…', 'es-ES', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-8238801560991616', 4039223809446541, 8238801560991616, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238867634203859, 'Limpiar selección', 'es-ES', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-8238867634203859', 4039193792488426, 8238867634203859, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238855306041384, 'Crear nuevo idioma o variedad', 'es-ES', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-8238855306041384', 4039299846909774, 8238855306041384, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238870651976798, 'No hay idiomas coincidentes', 'es-ES', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-8238870651976798', 4039195104624261, 8238870651976798, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780453157725, 'Buscar idiomas…', 'es-ES', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-8238780453157725', 4039246945260645, 8238780453157725, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238862477225135, 'Sugerido por tu navegador', 'es-ES', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-8238862477225135', 4039233498620681, 8238862477225135, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836288158517, 'Ayuda a traducir LangMap', 'es-ES', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-8238836288158517', 4039251841046235, 8238836288158517, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238870651976798, 'No hay idiomas coincidentes', 'es-ES', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-8238870651976798', 4039195104624261, 8238870651976798, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238798150059717, 'Idiomas recientes', 'es-ES', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-8238798150059717', 4039306795492531, 8238798150059717, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238839612608480, 'Expresiones', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-8238839612608480', 4039294118562578, 8238839612608480, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238810134661069, 'Idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-8238810134661069', 4039256322954053, 8238810134661069, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238878744396003, 'No se pudieron cargar los idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-8238878744396003', 4039196867547046, 8238878744396003, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238898482639128, 'No se encontraron idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-8238898482639128', 4039305123930385, 8238898482639128, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780453157725, 'Buscar idiomas…', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-8238780453157725', 4039246945260645, 8238780453157725, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238847699758348, 'A–Z', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-8238847699758348', 4039263037467916, 8238847699758348, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238845988639107, 'Cantidad', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-8238845988639107', 4039284364068927, 8238845988639107, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238834674079251, 'Explorar expresiones y relaciones entre todos los idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-8238834674079251', 4039317622660080, 8238834674079251, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238810134661069, 'Idiomas', 'es-ES', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-8238810134661069', 4039256322954053, 8238810134661069, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238893518568861, 'Ancla', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-8238893518568861', 4039242362911495, 8238893518568861, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238853432649362, 'Volver a la relación', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-8238853432649362', 4039274630245077, 8238853432649362, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238849135448939, '{count} idiomas', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-8238849135448939', 4039285488213874, 8238849135448939, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912795486222, 'No se pudo cargar', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-8238912795486222', 4039226239864187, 8238912795486222, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238851642125198, 'Miembros de la relación', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-8238851642125198', 4039240565339731, 8238851642125198, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238809114800664, 'No hay datos de distribución geográfica para este concepto', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-8238809114800664', 4039279250603930, 8238809114800664, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238902061247622, '{count} regiones', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-8238902061247622', 4039302107835931, 8238902061247622, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238874315301724, 'Distribución del concepto', 'es-ES', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-8238874315301724', 4039208466994401, 8238874315301724, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238823809814577, 'Añadir y crear relación', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-8238823809814577', 4039259535351101, 8238823809814577, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238877520869535, 'Añadir expresión', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-8238877520869535', 4039323156297807, 8238877520869535, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238824569172355, 'No se pudo añadir la expresión', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-8238824569172355', 4039198581489142, 8238824569172355, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238786528132206, 'Añadiendo…', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-8238786528132206', 4039218340751327, 8238786528132206, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238854937147215, 'Autoridad', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-8238854937147215', 4039318696248928, 8238854937147215, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238855320271357, 'Ruta de navegación', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-8238855320271357', 4039291257989597, 8238855320271357, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238781057298035, 'Cerrar adición rápida', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-8238781057298035', 4039267828069642, 8238781057298035, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238839158559148, 'Contribuir relación', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-8238839158559148', 4039295569136473, 8238839158559148, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238834855469326, 'relaciones directas', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-8238834855469326', 4039246116479366, 8238834855469326, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238796731410706, 'Introduce expresión y código de idioma', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-8238796731410706', 4039246255388206, 8238796731410706, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238812749931415, 'Expresión', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-8238812749931415', 4039318048221959, 8238812749931415, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238880450897786, 'Introduce una expresión…', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-8238880450897786', 4039242456703266, 8238880450897786, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840189380932, 'Grafo', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-8238840189380932', 4039261403730767, 8238840189380932, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238806296288338, 'Inicio', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-8238806296288338', 4039277332090535, 8238806296288338, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238811841340105, 'saltos', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-8238811841340105', 4039277202124053, 8238811841340105, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238825240641880, 'indirecta', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-8238825240641880', 4039318157522164, 8238825240641880, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238808680624233, 'Código de idioma', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-8238808680624233', 4039210176324565, 8238808680624233, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780004879692, 'ej. en / zh-Hant', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-8238780004879692', 4039209337204607, 8238780004879692, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882760625831, 'Lista', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-8238882760625831', 4039282174712441, 8238882760625831, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238912795486222, 'No se pudo cargar', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-8238912795486222', 4039226239864187, 8238912795486222, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238786419361877, 'Conjunto de relaciones', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-8238786419361877', 4039300809727185, 8238786419361877, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238827466143615, 'Aún no hay relaciones', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-8238827466143615', 4039325677769541, 8238827466143615, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238866609132340, 'Opcional', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-8238866609132340', 4039276071486298, 8238866609132340, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238793558043215, 'Añadir expresión rápidamente', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-8238793558043215', 4039324958036767, 8238793558043215, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238869207637580, 'Añade una expresión y relaciónala directamente con la expresión actual.', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-8238869207637580', 4039212842396077, 8238869207637580, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238871699308094, 'Región', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-8238871699308094', 4039258261318005, 8238871699308094, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238906477534047, 'Usuario', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-8238906477534047', 4039324440473230, 8238906477534047, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238884256695145, 'Ver este concepto en el mapa', 'es-ES', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-8238884256695145', 4039311455815203, 8238884256695145, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238892960991980, 'Cerrar menú', 'es-ES', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-8238892960991980', 4039297982961690, 8238892960991980, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238780110547387, 'Contribuir', 'es-ES', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-8238780110547387', 4039312030295503, 8238780110547387, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238902491232675, 'Manuales', 'es-ES', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-8238902491232675', 4039234820809009, 8238902491232675, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238806296288338, 'Inicio', 'es-ES', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-8238806296288338', 4039277332090535, 8238806296288338, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238810134661069, 'Idiomas', 'es-ES', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-8238810134661069', 4039256322954053, 8238810134661069, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238849585422174, 'Menú', 'es-ES', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-8238849585422174', 4039223542474758, 8238849585422174, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238899564576241, 'Abrir menú', 'es-ES', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-8238899564576241', 4039278126309563, 8238899564576241, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238803627225871, 'Buscar expresiones', 'es-ES', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-8238803627225871', 4039289790753346, 8238803627225871, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238874217048889, 'Iniciar sesión', 'es-ES', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-8238874217048889', 4039274956726587, 8238874217048889, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238793570897913, 'Cerrar sesión', 'es-ES', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-8238793570897913', 4039277593503154, 8238793570897913, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238854695208587, 'Enviar búsqueda', 'es-ES', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-8238854695208587', 4039323364353816, 8238854695208587, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238877016816557, 'Cambiar idioma de la interfaz', 'es-ES', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-8238877016816557', 4039195322568967, 8238877016816557, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840052438546, 'Alfabético', 'es-ES', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-8238840052438546', 4039328989831700, 8238840052438546, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238895244952104, 'Consejo: la búsqueda actual coincide con el texto de la expresión. La búsqueda semántica llegará más adelante.', 'es-ES', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-8238895244952104', 4039199272982370, 8238895244952104, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238874932696484, 'Error al buscar', 'es-ES', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-8238874932696484', 4039218663313831, 8238874932696484, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238835683799526, 'Más reciente', 'es-ES', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-8238835683799526', 4039202100757950, 8238835683799526, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882318939726, 'Sin resultados', 'es-ES', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-8238882318939726', 4039217192958680, 8238882318939726, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238801560991616, 'Buscar expresiones…', 'es-ES', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-8238801560991616', 4039223809446541, 8238801560991616, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832266064986, 'Popular', 'es-ES', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-8238832266064986', 4039247603774554, 8238832266064986, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238882193151525, '{count} resultado | {count} resultados', 'es-ES', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-8238882193151525', 4039304070680160, 8238882193151525, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238855108461340, 'Ordenar', 'es-ES', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-8238855108461340', 4039290847632508, 8238855108461340, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238803627225871, 'Buscar expresiones', 'es-ES', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-8238803627225871', 4039289790753346, 8238803627225871, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238836164016786, 'Añadir un idioma para traducir', 'es-ES', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-8238836164016786', 4039262743786868, 8238836164016786, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238896532657339, 'Enviar {count} traducciones', 'es-ES', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-8238896532657339', 4039232809480299, 8238896532657339, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238832603619392, 'Traducción actual', 'es-ES', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-8238832603619392', 4039272108076077, 8238832603619392, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238820131736527, 'Elige un idioma registrado', 'es-ES', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-8238820131736527', 4039307820065458, 8238820131736527, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238869725119666, 'Cobertura de traducción', 'es-ES', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-8238869725119666', 4039302750746982, 8238869725119666, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238906585616090, '{count} mostrados', 'es-ES', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-8238906585616090', 4039330567083979, 8238906585616090, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238812926291383, 'LOCALIZACIÓN COMUNITARIA', 'es-ES', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-8238812926291383', 4039263180329406, 8238812926291383, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238905717834066, 'Introduce la traducción…', 'es-ES', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-8238905717834066', 4039280361786422, 8238905717834066, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238868680399926, 'No se pudo cargar el área de trabajo de traducción', 'es-ES', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-8238868680399926', 4039210189975752, 8238868680399926, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238840499744940, 'Cargando…', 'es-ES', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-8238840499744940', 4039198023470406, 8238840499744940, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238787132779165, 'Idioma de destino', 'es-ES', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-8238787132779165', 4039286503270980, 8238787132779165, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238883359824684, 'No se pudo cargar la lista de idiomas', 'es-ES', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-8238883359824684', 4039255464963972, 8238883359824684, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238815579718982, 'Inicia sesión para enviar traducciones; los candidatos se seleccionan por puntuación de relación y se usa el texto de respaldo cuando no hay un candidato positivo.', 'es-ES', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-8238815579718982', 4039285344096668, 8238815579718982, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238869973740298, 'No se encontraron textos coincidentes.', 'es-ES', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-8238869973740298', 4039194547587951, 8238869973740298, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238887955371505, 'Vista previa', 'es-ES', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-8238887955371505', 4039259327128845, 8238887955371505, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238844471154664, 'Idioma de referencia', 'es-ES', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-8238844471154664', 4039299601179530, 8238844471154664, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238870458703960, 'Buscar clave o texto original…', 'es-ES', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-8238870458703960', 4039252284218610, 8238870458703960, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238847020367471, 'Elegir idioma de traducción', 'es-ES', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-8238847020367471', 4039327112090503, 8238847020367471, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238852341074397, 'Original en inglés', 'es-ES', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-8238852341074397', 4039304389733603, 8238852341074397, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238804158474279, 'Comenzar', 'es-ES', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-8238804158474279', 4039325838792223, 8238804158474279, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238779504812185, 'Error al enviar', 'es-ES', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-8238779504812185', 4039220418642934, 8238779504812185, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238883451661411, 'Enviar relación', 'es-ES', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-8238883451661411', 4039227663321003, 8238883451661411, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238813335657184, 'Enviado', 'es-ES', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-8238813335657184', 4039196288099856, 8238813335657184, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238910623484386, 'Ayuda a que el texto de la interfaz de LangMap sea natural y útil.', 'es-ES', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-8238910623484386', 4039258395876255, 8238910623484386, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238796538286121, 'Área de trabajo de traducción', 'es-ES', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-8238796538286121', 4039292410329094, 8238796538286121, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238807041768384, 'Traducir {key}', 'es-ES', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-8238807041768384', 4039226075472990, 8238807041768384, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238828513158823, 'traducido', 'es-ES', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-8238828513158823', 4039206423275507, 8238828513158823, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (8238802281990239, 'Traducción', 'es-ES', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-8238802281990239', 4039241150478337, 8238802281990239, 0, 'ui_i18n');

-- Locale ja-JP
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234532063977, 'メールアドレス', 'ja-JP', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-4721234532063977', 4039278566303563, 4721234532063977, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721238966446827, 'すでにアカウントをお持ちですか？', 'ja-JP', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-4721238966446827', 4039276962119789, 4721238966446827, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721232504519321, 'ログイン', 'ja-JP', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4721232504519321', 4039274956726587, 4721232504519321, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721277221303681, 'アカウントをお持ちでないですか？', 'ja-JP', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-4721277221303681', 4039210512038996, 4721277221303681, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721282761005444, '操作に失敗しました', 'ja-JP', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-4721282761005444', 4039224592934601, 4721282761005444, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721253862154574, 'パスワード', 'ja-JP', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-4721253862154574', 4039283475919761, 4721253862154574, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721172019310179, '処理中…', 'ja-JP', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-4721172019310179', 4039290683252068, 4721172019310179, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721257637148187, 'アカウント作成', 'ja-JP', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-4721257637148187', 4039254012036431, 4721257637148187, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721287230738619, 'ユーザー名', 'ja-JP', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-4721287230738619', 4039318948959047, 4721287230738619, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721190392639620, 'キャンセル', 'ja-JP', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4721190392639620', 4039291340498970, 4721190392639620, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721275285659581, '閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4721275285659581', 4039247982696992, 4721275285659581, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4721283999448883', 4039220584763101, 4721283999448883, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4721283999448883', 4039256322954053, 4721283999448883, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721275798880032, '読み込み中…', 'ja-JP', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4721275798880032', 4039198023470406, 4721275798880032, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721232231315522, '検索', 'ja-JP', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4721232231315522', 4039307974483127, 4721232231315522, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721231276549519, '送信', 'ja-JP', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4721231276549519', 4039245021981976, 4721231276549519, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300443771052, '実際のサイズ 100%', 'ja-JP', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-4721300443771052', 4039203196919686, 4721300443771052, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721222505288796, '匿名', 'ja-JP', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-4721222505288796', 4039253518652932, 4721222505288796, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721299491525551, '{count} 個の子ノード；クリックして折りたたむ', 'ja-JP', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-4721299491525551', 4039322475101146, 4721299491525551, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721290582352214, '各エッジは独立した直接関係で、賛成・反対の投票が可能です。低スコアの関係は自動的に折りたたまれます。', 'ja-JP', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-4721290582352214', 4039318570928695, 4721290582352214, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721261259999746, '作成する関係グラフ', 'ja-JP', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-4721261259999746', 4039280324996322, 4721261259999746, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721217512970103, '情報パネルを閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-4721217512970103', 4039213218065468, 4721217512970103, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721242780622600, '折りたたむ', 'ja-JP', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4721242780622600', 4039314752746797, 4721242780622600, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721190833580284, '子ノードを折りたたむ', 'ja-JP', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-4721190833580284', 4039311612904008, 4721190833580284, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721198201920567, '最初の階層に折りたたむ', 'ja-JP', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-4721198201920567', 4039252699292725, 4721198201920567, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721255995955747, '{count} 日前', 'ja-JP', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-4721255995955747', 4039305722497088, 4721255995955747, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721194729734374, '深さ {depth}', 'ja-JP', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-4721194729734374', 4039308224575343, 4721194729734374, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721216817371158, '直接関係のある表現', 'ja-JP', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-4721216817371158', 4039211316535202, 4721216817371158, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721237030474795, '反対', 'ja-JP', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-4721237030474795', 4039281764373654, 4721237030474795, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721207722080148, '{count} エッジ', 'ja-JP', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-4721207722080148', 4039196655494558, 4721207722080148, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721222272106924, 'データはまだありません', 'ja-JP', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-4721222272106924', 4039290061486601, 4721222272106924, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721239197036931, '全画面を終了', 'ja-JP', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-4721239197036931', 4039285164681796, 4721239197036931, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721182664440172, '展開', 'ja-JP', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-4721182664440172', 4039246642706739, 4721182664440172, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721183473996773, 'すべて展開', 'ja-JP', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-4721183473996773', 4039323395460079, 4721183473996773, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721268051065606, '子ノードを展開', 'ja-JP', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-4721268051065606', 4039227367141393, 4721268051065606, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240407128943, '表現', 'ja-JP', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4721240407128943', 4039318048221959, 4721240407128943, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721285593051700, '言語をフィルター…', 'ja-JP', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-4721285593051700', 4039264822897467, 4721285593051700, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721198220569859, '全画面', 'ja-JP', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-4721198220569859', 4039273948571546, 4721198220569859, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721278478089414, '表現関係グラフ', 'ja-JP', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-4721278478089414', 4039229813257256, 4721278478089414, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195574029748, 'グラフを読み込み中…', 'ja-JP', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-4721195574029748', 4039220553457070, 4721195574029748, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721274926565836, 'グラフモード', 'ja-JP', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-4721274926565836', 4039307692947617, 4721274926565836, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721233927760225, '{nodes} 個のマッピングノード · {edges} 件の関係', 'ja-JP', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-4721233927760225', 4039220204112184, 4721233927760225, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721189354190628, 'グラフツールバー', 'ja-JP', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-4721189354190628', 4039247632198973, 4721189354190628, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721219166940153, '関係階層リスト', 'ja-JP', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-4721219166940153', 4039262167197365, 4721219166940153, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721178232274912, 'ホップ数', 'ja-JP', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-4721178232274912', 4039218745350539, 4721178232274912, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721200319873057, '{count} 時間前', 'ja-JP', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-4721200319873057', 4039261676051383, 4721200319873057, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721187077481355, 'たった今', 'ja-JP', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-4721187077481355', 4039295793832731, 4721187077481355, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721205688403582, '言語を読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4721205688403582', 4039196867547046, 4721205688403582, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721173022472207, 'リストモード', 'ja-JP', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-4721173022472207', 4039267846517304, 4721173022472207, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721186534333566, 'さらに読み込む', 'ja-JP', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-4721186534333566', 4039257935440261, 4721186534333566, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721233654037398, '関連表現を読み込み中', 'ja-JP', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-4721233654037398', 4039208559662390, 4721233654037398, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721172917518608, '関係', 'ja-JP', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-4721172917518608', 4039299531874366, 4721172917518608, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721272440092167, '関係スコア', 'ja-JP', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-4721272440092167', 4039291250524588, 4721272440092167, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185409235028, '{count} 分前', 'ja-JP', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-4721185409235028', 4039319528355130, 4721185409235028, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174061109653, 'その他の操作', 'ja-JP', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-4721174061109653', 4039216903072408, 4721174061109653, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721191395188723, '完全なグラフにはさらに {count} 件の関係があります', 'ja-JP', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-4721191395188723', 4039267933793525, 4721191395188723, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721235307660176, '直接関係はまだありません', 'ja-JP', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-4721235307660176', 4039206484078170, 4721235307660176, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289428769574, '表現が見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4721289428769574', 4039240488727553, 4721289428769574, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721259822508065, '{count} ノード', 'ja-JP', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-4721259822508065', 4039205391794884, 4721259822508065, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300180126819, 'ノード情報', 'ja-JP', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-4721300180126819', 4039321854954979, 4721300180126819, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721182556188079, 'その他の関係', 'ja-JP', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-4721182556188079', 4039301412743754, 4721182556188079, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721228721143611, '関連表現', 'ja-JP', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-4721228721143611', 4039285912508809, 4721228721143611, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721290125045074, '{count} 件の関係', 'ja-JP', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-4721290125045074', 4039195207546455, 4721290125045074, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721181057507321, '{code} を削除', 'ja-JP', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-4721181057507321', 4039257785545173, 4721181057507321, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721231257215201, 'レイアウトをリセット', 'ja-JP', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-4721231257215201', 4039213227329958, 4721231257215201, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721258604206697, 'ルートノード', 'ja-JP', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-4721258604206697', 4039280733662867, 4721258604206697, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721232231315522, '検索', 'ja-JP', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4721232231315522', 4039307974483127, 4721232231315522, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721197367426547, '表現を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4721197367426547', 4039223809446541, 4721197367426547, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721272200707864, '検索中…', 'ja-JP', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-4721272200707864', 4039241606316828, 4721272200707864, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721218994925040, 'グラフ内のノードを選択して詳細を表示', 'ja-JP', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-4721218994925040', 4039258954601880, 4721218994925040, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721255617963023, '元の経路', 'ja-JP', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-4721255617963023', 4039267388033524, 4721255617963023, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721253738178015, '賛成', 'ja-JP', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-4721253738178015', 4039305875761888, 4721253738178015, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195147177467, '表現の詳細を表示', 'ja-JP', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-4721195147177467', 4039285357620964, 4721195147177467, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721302347283528, '投票に失敗しました。元に戻しました', 'ja-JP', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-4721302347283528', 4039310388216878, 4721302347283528, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721255729105244, '拡大', 'ja-JP', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-4721255729105244', 4039307035795639, 4721255729105244, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721215513664604, '縮小', 'ja-JP', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-4721215513664604', 4039306926563555, 4721215513664604, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721209407930418, '+ 表現を追加', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-4721209407930418', 4039234711174892, 4721209407930418, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721243715178879, '完全グラフ', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-4721243715178879', 4039210891494791, 4721243715178879, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721182487538273, '削除', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-4721182487538273', 4039233937430393, 4721182487538273, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721179733774986, '{count} 件の直接関係', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-4721179733774986', 4039258582305025, 4721179733774986, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240407128943, '表現', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4721240407128943', 4039318048221959, 4721240407128943, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721260139483302, '{count} 件の表現', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-4721260139483302', 4039208226237843, 4721260139483302, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721224629072264, '表現を入力…', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-4721224629072264', 4039264797643778, 4721224629072264, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4721283999448883', 4039220584763101, 4721283999448883, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721215081514558, '同じ意味を持つ表現のグループを送信します。システムは各ペア間に直接関係を作成します。既存の表現は重複なく自動的にリンクされます。', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-4721215081514558', 4039228008118707, 4721215081514558, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721258470055297, '言語と表現を入力した行が少なくとも2行必要です', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-4721258470055297', 4039286212175439, 4721258470055297, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721231276549519, '送信', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4721231276549519', 4039245021981976, 4721231276549519, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185123396885, '送信に失敗しました', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4721185123396885', 4039220418642934, 4721185123396885, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721194726808130, '送信中…', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-4721194726808130', 4039286291917398, 4721194726808130, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721196077587045, 'タグ', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-4721196077587045', 4039312686530045, 4721196077587045, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240692642437, '一括投稿', 'ja-JP', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-4721240692642437', 4039256753970050, 4721240692642437, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721179140446533, 'ホームに戻る', 'ja-JP', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-4721179140446533', 4039244552136331, 4721179140446533, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174434559900, '読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4721174434559900', 4039226239864187, 4721174434559900, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721272808096020, 'ページが見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-4721272808096020', 4039247795890512, 4721272808096020, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721222055903162, 'すべて', 'ja-JP', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-4721222055903162', 4039202333969475, 4721222055903162, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721222284809655, '関係を投稿する →', 'ja-JP', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-4721222284809655', 4039241704787781, 4721222284809655, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195555085164, '人気', 'ja-JP', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4721195555085164', 4039247603774554, 4721195555085164, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721293595704752, '関係 + 新しい表現', 'ja-JP', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-4721293595704752', 4039260809744465, 4721293595704752, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721171579270645, '必要なものが見つかりませんか？', 'ja-JP', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-4721171579270645', 4039254190870260, 4721171579270645, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721227211013178, '新しい貢献', 'ja-JP', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-4721227211013178', 4039302900266643, 4721227211013178, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721184825591777, '最新', 'ja-JP', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4721184825591777', 4039202100757950, 4721184825591777, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721176580015181, '人気の関係', 'ja-JP', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-4721176580015181', 4039245957647571, 4721176580015181, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721202673665557, 'スコア順 · 今週', 'ja-JP', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-4721202673665557', 4039291578874799, 4721202673665557, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721182892577781, '意味グラフの最新情報 — 人気の関係と新しい貢献。', 'ja-JP', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-4721182892577781', 4039275101235147, 4721182892577781, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721259556632681, 'アクティビティ', 'ja-JP', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-4721259556632681', 4039218305844177, 4721259556632681, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252797655279, '表現を追加', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4721252797655279', 4039323156297807, 4721252797655279, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185311948000, 'セクションを追加', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-4721185311948000', 4039302981121903, 4721185311948000, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721242669715252, 'ハンドブック一覧', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-4721242669715252', 4039275162095516, 4721242669715252, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721302767123477, '第 {number} 章', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-4721302767123477', 4039264579862218, 4721302767123477, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721227600896069, '表現情報を閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-4721227600896069', 4039238473169231, 4721227600896069, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721242780622600, '折りたたむ', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4721242780622600', 4039314752746797, 4721242780622600, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721241079877563, 'セクションを削除', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-4721241079877563', 4039212000754015, 4721241079877563, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721179566815673, 'ハンドブックを編集', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-4721179566815673', 4039244157921703, 4721179566815673, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721203653492026, '表現情報', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-4721203653492026', 4039248386595592, 4721203653492026, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721292759625248, '表現の言語、地域、ソースがここに表示されます。', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-4721292759625248', 4039258685413951, 4721292759625248, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721186228601006, 'このハンドブックは役に立ちましたか？', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-4721186228601006', 4039208667474251, 4721186228601006, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185499254642, '表現を読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-4721185499254642', 4039291593337392, 4721185499254642, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174434559900, '読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4721174434559900', 4039226239864187, 4721174434559900, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4721283999448883', 4039220584763101, 4721283999448883, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721188297200167, '下に移動', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-4721188297200167', 4039305476617896, 4721188297200167, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721281403798668, 'セクションを下に移動', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-4721281403798668', 4039264378315169, 4721281403798668, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721223585392250, 'セクションを上に移動', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-4721223585392250', 4039263980419517, 4721223585392250, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721215026114110, '上に移動', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-4721215026114110', 4039325459519266, 4721215026114110, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721284008047227, '非公開', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-4721284008047227', 4039271025507837, 4721284008047227, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721192529867460, '公開', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-4721192529867460', 4039267993342608, 4721192529867460, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721192529867460, '公開', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-4721192529867460', 4039241948973877, 4721192529867460, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721290517941662, '地域', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4721290517941662', 4039258261318005, 4721290517941662, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721179151858758, '関連表現を読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-4721179151858758', 4039281597988534, 4721179151858758, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721254462609050, '{text} を削除', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-4721254462609050', 4039238014424846, 4721254462609050, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721167602264713, '下書きを保存', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-4721167602264713', 4039263998176559, 4721167602264713, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721284278462209, '保存中…', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-4721284278462209', 4039270028440745, 4721284278462209, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721211512445854, 'セクションタイトル', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-4721211512445854', 4039225159134159, 4721211512445854, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721267416035926, '表現を選択', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-4721267416035926', 4039264953167344, 4721267416035926, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721189501697442, 'ソース', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-4721189501697442', 4039223387675999, 4721189501697442, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721216513375871, 'AI', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-4721216513375871', 4039244426247807, 4721216513375871, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721238010484275, '権威', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4721238010484275', 4039318696248928, 4721238010484275, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721188715088515, 'ユーザー', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4721188715088515', 4039324440473230, 4721188715088515, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721277559169621, 'ハンドブックのタイトル', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-4721277559169621', 4039208338888027, 4721277559169621, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174690292214, '目次', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-4721174690292214', 4039204809556520, 4721174690292214, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721287679131766, '完全な関係グラフを表示', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-4721287679131766', 4039218586424477, 4721287679131766, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721208028078697, '公開設定', 'ja-JP', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-4721208028078697', 4039319622118803, 4721208028078697, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721272661601604, '新しいハンドブック', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-4721272661601604', 4039273991762691, 4721272661601604, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721255506189756, 'ハンドブックを読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-4721255506189756', 4039205037236353, 4721255506189756, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721184825591777, '最新', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4721184825591777', 4039202100757950, 4721184825591777, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721169543491407, 'ハンドブックが見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-4721169543491407', 4039297167533555, 4721169543491407, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195555085164, '人気', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4721195555085164', 4039247603774554, 4721195555085164, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300846558318, 'ハンドブックを検索…', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-4721300846558318', 4039321109759665, 4721300846558318, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721243178271307, 'セクション', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-4721243178271307', 4039271506815244, 4721243178271307, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300481275844, 'ハンドブック', 'ja-JP', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4721300481275844', 4039234820809009, 4721300481275844, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721273311158331, '戻る', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-4721273311158331', 4039313675995469, 4721273311158331, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721190392639620, 'キャンセル', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4721190392639620', 4039291340498970, 4721190392639620, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721275285659581, '閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4721275285659581', 4039247982696992, 4721275285659581, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721207810989352, '言語を作成', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4721207810989352', 4039261792696368, 4721207810989352, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721285873110242, '言語の作成に失敗しました', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-4721285873110242', 4039298612922394, 4721285873110242, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721288788456036, '作成中…', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-4721288788456036', 4039232938642916, 4721288788456036, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721186911819666, '説明を入力してください', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-4721186911819666', 4039276426027002, 4721186911819666, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721257957996839, 'Glottolog の一致を選択するか、「一致なし」を選択', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-4721257957996839', 4039271782430821, 4721257957996839, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252265786700, '言語名を入力してください', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-4721252265786700', 4039210698010944, 4721252265786700, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721226723860487, 'コミュニティのみ作成の理由を選択してください', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-4721226723860487', 4039216473655312, 4721226723860487, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721167069031920, '続行するには言語サブタグを入力してください', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-4721167069031920', 4039316213234006, 4721167069031920, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721243643430545, '{count} 件の候補が見つかりました', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-4721243643430545', 4039246098211492, 4721243643430545, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289733920456, '一致を選択するか、適切な項目がないことを指定', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-4721289733920456', 4039323364172038, 4721289733920456, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721187556659928, 'この候補に一致', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-4721187556659928', 4039325854259152, 4721187556659928, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721205948412196, '方言', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-4721205948412196', 4039249282401723, 4721205948412196, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-4721283999448883', 4039243488926094, 4721283999448883, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721286358743914, 'Glottolog に適切な項目がありません', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-4721286358743914', 4039197295194771, 4721286358743914, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721295303500933, 'Glottolog を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-4721295303500933', 4039262313884420, 4721295303500933, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721279457332353, '説明', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-4721279457332353', 4039226938266962, 4721279457332353, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721171233651064, 'この言語または変種を説明…', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-4721171233651064', 4039218699342636, 4721171233651064, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721243962073092, '名前', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-4721243962073092', 4039203173843539, 4721243962073092, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721217274551345, '英語名', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-4721217274551345', 4039325286054403, 4721217274551345, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721279231585338, 'この言語が Glottolog にない理由は？', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-4721279231585338', 4039255034745478, 4721279231585338, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721206041675600, 'コミュニティ固有の用法', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-4721206041675600', 4039318758556549, 4721206041675600, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721220434349525, '新しい変種', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-4721220434349525', 4039201401042810, 4721220434349525, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721238955950926, 'Glottolog に未収録', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-4721238955950926', 4039317085985011, 4721238955950926, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721187337644252, 'その他', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-4721187337644252', 4039197354913502, 4721187337644252, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721199246269248, '理由を選択…', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-4721199246269248', 4039198381390937, 4721199246269248, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721178977091492, '次へ', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-4721178977091492', 4039235695377645, 4721178977091492, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721301882339522, '正規コード', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-4721301882339522', 4039275920750884, 4721301882339522, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721295870157505, 'この言語はすでに存在します', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-4721295870157505', 4039252684783738, 4721295870157505, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721166812261680, '既存の言語を使用', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-4721166812261680', 4039201624757562, 4721166812261680, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721207810989352, '言語を作成', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4721207810989352', 4039261792696368, 4721207810989352, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721200006523309, '警告', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-4721200006523309', 4039266319466062, 4721200006523309, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721201145519356, '暫定タグ', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-4721201145519356', 4039258938883345, 4721201145519356, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721278806009625, 'Glottolog マッチ', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-4721278806009625', 4039216090040527, 4721278806009625, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721167740486409, 'メタデータ', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-4721167740486409', 4039278502317771, 4721167740486409, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721190474034001, 'プレビューと作成', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-4721190474034001', 4039292079507095, 4721190474034001, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721216172763552, '言語タグ', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-4721216172763552', 4039271969593143, 4721216172763552, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4721283999448883', 4039220584763101, 4721283999448883, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721290517941662, '地域', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4721290517941662', 4039258261318005, 4721290517941662, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721263995402362, '文字', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-4721263995402362', 4039265998307294, 4721263995402362, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721226270939430, 'サブタグを検索…', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-4721226270939430', 4039305028592078, 4721226270939430, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721275958661281, '変種', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-4721275958661281', 4039213349000445, 4721275958661281, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234888291150, '1 件の変種を削除', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-4721234888291150', 4039300854350766, 4721234888291150, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721224512568001, '{count} 件の変種を削除', 'ja-JP', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-4721224512568001', 4039288165772049, 4721224512568001, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721230569673826, 'アルファベット順', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4721230569673826', 4039328989831700, 4721230569673826, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4721283999448883', 4039256322954053, 4721283999448883, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240407128943, '表現', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4721240407128943', 4039294118562578, 4721240407128943, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721184825591777, '最新', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4721184825591777', 4039202100757950, 4721184825591777, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174434559900, '読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4721174434559900', 4039226239864187, 4721174434559900, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721259446006891, 'マッピング済み', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-4721259446006891', 4039236848299860, 4721259446006891, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289428769574, '表現が見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4721289428769574', 4039240488727553, 4721289428769574, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195555085164, '人気', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4721195555085164', 4039247603774554, 4721195555085164, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721197367426547, '表現を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4721197367426547', 4039223809446541, 4721197367426547, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721292573546286, '選択をクリア', 'ja-JP', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-4721292573546286', 4039193792488426, 4721292573546286, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721246477349882, '新しい言語または変種を作成', 'ja-JP', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-4721246477349882', 4039299846909774, 4721246477349882, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234035892380, '一致する言語がありません', 'ja-JP', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4721234035892380', 4039195104624261, 4721234035892380, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721301557627223, '言語を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4721301557627223', 4039246945260645, 4721301557627223, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721175390282830, 'ブラウザの推奨', 'ja-JP', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-4721175390282830', 4039233498620681, 4721175390282830, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721261130019741, 'LangMap の翻訳に協力する', 'ja-JP', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-4721261130019741', 4039251841046235, 4721261130019741, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234035892380, '一致する言語がありません', 'ja-JP', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4721234035892380', 4039195104624261, 4721234035892380, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721248078054408, '最近使用した言語', 'ja-JP', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-4721248078054408', 4039306795492531, 4721248078054408, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240407128943, '表現', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4721240407128943', 4039294118562578, 4721240407128943, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4721283999448883', 4039256322954053, 4721283999448883, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721205688403582, '言語を読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4721205688403582', 4039196867547046, 4721205688403582, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721278116527488, '言語が見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-4721278116527488', 4039305123930385, 4721278116527488, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721301557627223, '言語を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4721301557627223', 4039246945260645, 4721301557627223, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721235124595980, 'A–Z', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-4721235124595980', 4039263037467916, 4721235124595980, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721239333438692, '件数', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-4721239333438692', 4039284364068927, 4721239333438692, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721214630873413, 'すべての言語の表現と関係を探索', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-4721214630873413', 4039317622660080, 4721214630873413, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4721283999448883', 4039256322954053, 4721283999448883, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721261031750481, 'アンカー', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-4721261031750481', 4039242362911495, 4721261031750481, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721264493119649, '関係に戻る', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-4721264493119649', 4039274630245077, 4721264493119649, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289976458874, '{count} 言語', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-4721289976458874', 4039285488213874, 4721289976458874, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174434559900, '読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4721174434559900', 4039226239864187, 4721174434559900, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721280106497330, '関係メンバー', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-4721280106497330', 4039240565339731, 4721280106497330, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721179172041630, 'この概念の地理的分布データはありません', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-4721179172041630', 4039279250603930, 4721179172041630, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721242992291955, '{count} 地域', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-4721242992291955', 4039302107835931, 4721242992291955, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240518759262, '概念の分布', 'ja-JP', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-4721240518759262', 4039208466994401, 4721240518759262, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252385386042, '追加して関係を作成', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-4721252385386042', 4039259535351101, 4721252385386042, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252797655279, '表現を追加', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4721252797655279', 4039323156297807, 4721252797655279, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721285296597296, '表現を追加できませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-4721285296597296', 4039198581489142, 4721285296597296, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185720987649, '追加中…', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-4721185720987649', 4039218340751327, 4721185720987649, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721238010484275, '権威', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4721238010484275', 4039318696248928, 4721238010484275, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721202609539577, 'パンくず', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-4721202609539577', 4039291257989597, 4721202609539577, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721255775457727, 'クイック追加を閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-4721255775457727', 4039267828069642, 4721255775457727, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252828161999, '関係を投稿', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-4721252828161999', 4039295569136473, 4721252828161999, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721254007031667, '直接関係', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-4721254007031667', 4039246116479366, 4721254007031667, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721224652084401, '表現と言語コードを入力してください', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-4721224652084401', 4039246255388206, 4721224652084401, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721240407128943, '表現', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4721240407128943', 4039318048221959, 4721240407128943, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721224629072264, '表現を入力…', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-4721224629072264', 4039242456703266, 4721224629072264, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721193519608681, 'グラフ', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-4721193519608681', 4039261403730767, 4721193519608681, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234822885550, 'ホーム', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4721234822885550', 4039277332090535, 4721234822885550, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721178232274912, 'ホップ数', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-4721178232274912', 4039277202124053, 4721178232274912, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721209585406848, '間接', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-4721209585406848', 4039318157522164, 4721209585406848, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721292669052894, '言語コード', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-4721292669052894', 4039210176324565, 4721292669052894, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721252849114623, '例：en / zh-Hant', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-4721252849114623', 4039209337204607, 4721252849114623, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721287778505987, 'リスト', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-4721287778505987', 4039282174712441, 4721287778505987, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721174434559900, '読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4721174434559900', 4039226239864187, 4721174434559900, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721265013506425, '関係セット', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-4721265013506425', 4039300809727185, 4721265013506425, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721295319650549, 'まだ関係がありません', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-4721295319650549', 4039325677769541, 4721295319650549, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721258674411610, '任意', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-4721258674411610', 4039276071486298, 4721258674411610, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721223210175474, '表現をすばやく追加', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-4721223210175474', 4039324958036767, 4721223210175474, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721295288218634, '表現を追加し、現在の表現に直接マップします。', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-4721295288218634', 4039212842396077, 4721295288218634, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721290517941662, '地域', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4721290517941662', 4039258261318005, 4721290517941662, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721188715088515, 'ユーザー', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4721188715088515', 4039324440473230, 4721188715088515, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721263680185232, 'この概念を地図で表示', 'ja-JP', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-4721263680185232', 4039311455815203, 4721263680185232, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721214944487970, 'メニューを閉じる', 'ja-JP', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-4721214944487970', 4039297982961690, 4721214944487970, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721168090934160, '貢献', 'ja-JP', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-4721168090934160', 4039312030295503, 4721168090934160, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300481275844, 'ハンドブック', 'ja-JP', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4721300481275844', 4039234820809009, 4721300481275844, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721234822885550, 'ホーム', 'ja-JP', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4721234822885550', 4039277332090535, 4721234822885550, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721283999448883, '言語', 'ja-JP', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4721283999448883', 4039256322954053, 4721283999448883, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721209348130481, 'メニュー', 'ja-JP', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-4721209348130481', 4039223542474758, 4721209348130481, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721227253318425, 'メニューを開く', 'ja-JP', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-4721227253318425', 4039278126309563, 4721227253318425, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721248838865086, '表現を検索', 'ja-JP', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4721248838865086', 4039289790753346, 4721248838865086, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721232504519321, 'ログイン', 'ja-JP', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4721232504519321', 4039274956726587, 4721232504519321, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721281281159530, 'ログアウト', 'ja-JP', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-4721281281159530', 4039277593503154, 4721281281159530, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721278915996358, '検索を実行', 'ja-JP', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-4721278915996358', 4039323364353816, 4721278915996358, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721264451049930, 'インターフェース言語を切り替え', 'ja-JP', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-4721264451049930', 4039195322568967, 4721264451049930, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721230569673826, 'アルファベット順', 'ja-JP', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4721230569673826', 4039328989831700, 4721230569673826, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289389102291, 'ヒント：現在の検索は表現テキストに一致します。意味検索は後日提供予定です。', 'ja-JP', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-4721289389102291', 4039199272982370, 4721289389102291, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721300853875897, '検索に失敗しました', 'ja-JP', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-4721300853875897', 4039218663313831, 4721300853875897, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721184825591777, '最新', 'ja-JP', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4721184825591777', 4039202100757950, 4721184825591777, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721273048500131, '結果が見つかりません', 'ja-JP', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-4721273048500131', 4039217192958680, 4721273048500131, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721197367426547, '表現を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4721197367426547', 4039223809446541, 4721197367426547, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721195555085164, '人気', 'ja-JP', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4721195555085164', 4039247603774554, 4721195555085164, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721293752598530, '{count} 件の結果', 'ja-JP', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-4721293752598530', 4039304070680160, 4721293752598530, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721165983536921, '並び替え', 'ja-JP', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-4721165983536921', 4039290847632508, 4721165983536921, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721248838865086, '表現を検索', 'ja-JP', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4721248838865086', 4039289790753346, 4721248838865086, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721289823723986, '翻訳する言語を追加', 'ja-JP', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-4721289823723986', 4039262743786868, 4721289823723986, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721167817145218, '{count} 件の翻訳を送信', 'ja-JP', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-4721167817145218', 4039232809480299, 4721167817145218, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721264535134652, '現在の翻訳', 'ja-JP', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-4721264535134652', 4039272108076077, 4721264535134652, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721217796915558, '登録済みの言語を選択', 'ja-JP', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-4721217796915558', 4039307820065458, 4721217796915558, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721191799910120, '翻訳カバレッジ', 'ja-JP', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-4721191799910120', 4039302750746982, 4721191799910120, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721177482525803, '{count} 件表示', 'ja-JP', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-4721177482525803', 4039330567083979, 4721177482525803, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721217707882634, 'コミュニティ翻訳', 'ja-JP', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-4721217707882634', 4039263180329406, 4721217707882634, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721249742339901, '翻訳を入力…', 'ja-JP', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-4721249742339901', 4039280361786422, 4721249742339901, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721192196457495, '翻訳ワークベンチを読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-4721192196457495', 4039210189975752, 4721192196457495, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721275798880032, '読み込み中…', 'ja-JP', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4721275798880032', 4039198023470406, 4721275798880032, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721235941953802, '対象言語', 'ja-JP', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-4721235941953802', 4039286503270980, 4721235941953802, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721291655913952, '言語リストを読み込めませんでした', 'ja-JP', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-4721291655913952', 4039255464963972, 4721291655913952, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721214460191148, 'ログインして翻訳を送信。候補は関係スコアで選択され、適切な候補がない場合はフォールバックが使用されます。', 'ja-JP', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-4721214460191148', 4039285344096668, 4721214460191148, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721203624683452, '一致するテキストが見つかりません。', 'ja-JP', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-4721203624683452', 4039194547587951, 4721203624683452, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721233416843169, 'プレビュー', 'ja-JP', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-4721233416843169', 4039259327128845, 4721233416843169, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721211604587044, '参照言語', 'ja-JP', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-4721211604587044', 4039299601179530, 4721211604587044, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721236293240260, 'キーまたは原文を検索…', 'ja-JP', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-4721236293240260', 4039252284218610, 4721236293240260, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721256749241556, '翻訳言語を選択', 'ja-JP', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-4721256749241556', 4039327112090503, 4721256749241556, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721263880176227, '英語原文', 'ja-JP', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-4721263880176227', 4039304389733603, 4721263880176227, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721260833759160, '開始', 'ja-JP', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-4721260833759160', 4039325838792223, 4721260833759160, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185123396885, '送信に失敗しました', 'ja-JP', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4721185123396885', 4039220418642934, 4721185123396885, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721185188179114, '関係を送信', 'ja-JP', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-4721185188179114', 4039227663321003, 4721185188179114, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721281359506236, '送信済み', 'ja-JP', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-4721281359506236', 4039196288099856, 4721281359506236, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721167539484150, 'LangMap のインターフェース文言を自然で使いやすくするお手伝いをします。', 'ja-JP', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-4721167539484150', 4039258395876255, 4721167539484150, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721244496575071, '翻訳ワークベンチ', 'ja-JP', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-4721244496575071', 4039292410329094, 4721244496575071, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721219286037906, '{key} を翻訳', 'ja-JP', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-4721219286037906', 4039226075472990, 4721219286037906, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721196772562647, '翻訳済み', 'ja-JP', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-4721196772562647', 4039206423275507, 4721196772562647, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4721196663970382, '翻訳', 'ja-JP', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-4721196663970382', 4039241150478337, 4721196663970382, 0, 'ui_i18n');

-- Locale zh-Hans-CN
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732950891937922, '邮箱', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-4732950891937922', 4039278566303563, 4732950891937922, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732937571915359, '已有账号？', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-4732937571915359', 4039276962119789, 4732937571915359, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860825885107, '登录', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4732860825885107', 4039274956726587, 4732860825885107, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732931767066969, '还没有账号？', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-4732931767066969', 4039210512038996, 4732931767066969, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732949447014723, '操作失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-4732949447014723', 4039224592934601, 4732949447014723, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732849729285755, '密码', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-4732849729285755', 4039283475919761, 4732849729285755, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925007170098, '处理中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-4732925007170098', 4039290683252068, 4732925007170098, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732913747683473, '创建账号', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-4732913747683473', 4039254012036431, 4732913747683473, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732950204679811, '用户名', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-4732950204679811', 4039318948959047, 4732950204679811, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732978942914570, '取消', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4732978942914570', 4039291340498970, 4732978942914570, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732971925494266, '关闭', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4732971925494266', 4039247982696992, 4732971925494266, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4732962676614358', 4039220584763101, 4732962676614358, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4732962676614358', 4039256322954053, 4732962676614358, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732967235725349, '加载中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4732967235725349', 4039198023470406, 4732967235725349, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732886655837795, '搜索', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4732886655837795', 4039307974483127, 4732886655837795, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732893788110021, '提交', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4732893788110021', 4039245021981976, 4732893788110021, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732929254422456, '实际尺寸 100%', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-4732929254422456', 4039203196919686, 4732929254422456, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732904816333916, '匿名', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-4732904816333916', 4039253518652932, 4732904816333916, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732916654065474, '{count} 个子节点；点击收起', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-4732916654065474', 4039322475101146, 4732916654065474, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732971820303065, '每条边皆为可投票的独立直接映射；低分映射自动收起', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-4732971820303065', 4039318570928695, 4732971820303065, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732983636832759, '待建立的映射图谱', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-4732983636832759', 4039280324996322, 4732983636832759, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732933654894127, '关闭信息面板', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-4732933654894127', 4039213218065468, 4732933654894127, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732862178404436, '收起', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4732862178404436', 4039314752746797, 4732862178404436, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732979783281563, '收起子分支', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-4732979783281563', 4039311612904008, 4732979783281563, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732970175263873, '收起至第一层', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-4732970175263873', 4039252699292725, 4732970175263873, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732913139607060, '{count} 天前', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-4732913139607060', 4039305722497088, 4732913139607060, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732972828831384, '深度 {depth}', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-4732972828831384', 4039308224575343, 4732972828831384, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732948919760248, '直接映射词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-4732948919760248', 4039211316535202, 4732948919760248, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732893775350395, '踩', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-4732893775350395', 4039281764373654, 4732893775350395, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860063138598, '{count} 条边', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-4732860063138598', 4039196655494558, 4732860063138598, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732886701352232, '暂无数据', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-4732886701352232', 4039290061486601, 4732886701352232, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732945205581842, '退出全屏', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-4732945205581842', 4039285164681796, 4732945205581842, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732852074632292, '展开', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-4732852074632292', 4039246642706739, 4732852074632292, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732929879001684, '全部展开', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-4732929879001684', 4039323395460079, 4732929879001684, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732876077524934, '展开子分支', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-4732876077524934', 4039227367141393, 4732876077524934, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732961335886977, '词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4732961335886977', 4039318048221959, 4732961335886977, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732884908370378, '筛选语言…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-4732884908370378', 4039264822897467, 4732884908370378, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882161456945, '全屏', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-4732882161456945', 4039273948571546, 4732882161456945, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732931434534618, '词句映射图谱', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-4732931434534618', 4039229813257256, 4732931434534618, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732927576814046, '加载图谱…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-4732927576814046', 4039220553457070, 4732927576814046, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732957244227040, '图谱模式', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-4732957244227040', 4039307692947617, 4732957244227040, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732856203457656, '{nodes} 个映射节点 · {edges} 个关系', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-4732856203457656', 4039220204112184, 4732856203457656, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732950139360165, '图谱工具栏', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-4732950139360165', 4039247632198973, 4732950139360165, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732870979658093, '映射层级列表', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-4732870979658093', 4039262167197365, 4732870979658093, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732869036383207, '跳数', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-4732869036383207', 4039218745350539, 4732869036383207, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732936701622158, '{count} 小时前', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-4732936701622158', 4039261676051383, 4732936701622158, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732957943514528, '刚刚', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-4732957943514528', 4039295793832731, 4732957943514528, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732978254610146, '无法加载语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4732978254610146', 4039196867547046, 4732978254610146, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732919266091786, '列表模式', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-4732919266091786', 4039267846517304, 4732919266091786, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732916287104914, '加载更多', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-4732916287104914', 4039257935440261, 4732916287104914, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732950897902970, '加载相关词句中', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-4732950897902970', 4039208559662390, 4732950897902970, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732884330125143, '映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-4732884330125143', 4039299531874366, 4732884330125143, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732983514829172, '映射评分', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-4732983514829172', 4039291250524588, 4732983514829172, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732856334129839, '{count} 分钟前', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-4732856334129839', 4039319528355130, 4732856334129839, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732909106639884, '更多操作', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-4732909106639884', 4039216903072408, 4732909106639884, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882561598202, '完整图谱中还有 {count} 个映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-4732882561598202', 4039267933793525, 4732882561598202, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732859404022322, '暂无直接映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-4732859404022322', 4039206484078170, 4732859404022322, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732869555104368, '找不到相符词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4732869555104368', 4039240488727553, 4732869555104368, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732881378153083, '{count} 个节点', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-4732881378153083', 4039205391794884, 4732881378153083, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732966131581895, '节点信息', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-4732966131581895', 4039321854954979, 4732966131581895, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732948553368912, '其他关系', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-4732948553368912', 4039301412743754, 4732948553368912, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732854072623365, '相关词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-4732854072623365', 4039285912508809, 4732854072623365, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732979836990803, '{count} 个关系', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-4732979836990803', 4039195207546455, 4732979836990803, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732855550804511, '移除 {code}', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-4732855550804511', 4039257785545173, 4732855550804511, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925467148862, '重置布局', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-4732925467148862', 4039213227329958, 4732925467148862, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867991835243, '根节点', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-4732867991835243', 4039280733662867, 4732867991835243, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732886655837795, '搜索', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4732886655837795', 4039307974483127, 4732886655837795, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879769563383, '搜索词句…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4732879769563383', 4039223809446541, 4732879769563383, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732980459536265, '搜索中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-4732980459536265', 4039241606316828, 4732980459536265, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732918362592000, '在图谱中选取节点以查看详情', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-4732918362592000', 4039258954601880, 4732918362592000, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732862539852335, '来源路径', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-4732862539852335', 4039267388033524, 4732862539852335, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732948422132252, '赞', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-4732948422132252', 4039305875761888, 4732948422132252, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732954584902567, '查看词句详情', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-4732954584902567', 4039285357620964, 4732954584902567, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882713994959, '投票失败，已撤销', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-4732882713994959', 4039310388216878, 4732882713994959, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732914979388946, '放大', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-4732914979388946', 4039307035795639, 4732914979388946, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860792195293, '缩小', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-4732860792195293', 4039306926563555, 4732860792195293, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867941937033, '+ 添加词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-4732867941937033', 4039234711174892, 4732867941937033, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732926220457935, '完全图', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-4732926220457935', 4039210891494791, 4732926220457935, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732858715645588, '删除', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-4732858715645588', 4039233937430393, 4732858715645588, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732948413504489, '{count} 个直接映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-4732948413504489', 4039258582305025, 4732948413504489, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732961335886977, '词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4732961335886977', 4039318048221959, 4732961335886977, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732912901584307, '{count} 个词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-4732912901584307', 4039208226237843, 4732912901584307, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732981996449790, '输入词句…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-4732981996449790', 4039264797643778, 4732981996449790, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4732962676614358', 4039220584763101, 4732962676614358, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732968501125262, '提交一组含义相同的词句。系统会在每对之间创建直接映射。已有词句会自动关联，不会产生重复。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-4732968501125262', 4039228008118707, 4732968501125262, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732943527283828, '至少需要 2 行，每行需填写语言和词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-4732943527283828', 4039286212175439, 4732943527283828, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732893788110021, '提交', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4732893788110021', 4039245021981976, 4732893788110021, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732857348512231, '提交失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4732857348512231', 4039220418642934, 4732857348512231, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732850722537148, '提交中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-4732850722537148', 4039286291917398, 4732850722537148, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732956053999539, '标签', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-4732956053999539', 4039312686530045, 4732956053999539, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732947536607852, '批量提交', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-4732947536607852', 4039256753970050, 4732947536607852, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732958960708395, '返回首页', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-4732958960708395', 4039244552136331, 4732958960708395, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851559156278, '无法加载', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4732851559156278', 4039226239864187, 4732851559156278, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732871748277643, '页面未找到', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-4732871748277643', 4039247795890512, 4732871748277643, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732956125052025, '全部', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-4732956125052025', 4039202333969475, 4732956125052025, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732977585032318, '提交映射 →', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-4732977585032318', 4039241704787781, 4732977585032318, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860261262561, '热门', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4732860261262561', 4039247603774554, 4732860261262561, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732900400760361, '映射 + 新词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-4732900400760361', 4039260809744465, 4732900400760361, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732917962103151, '找不到所需内容？', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-4732917962103151', 4039254190870260, 4732917962103151, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732869424627537, '新贡献', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-4732869424627537', 4039302900266643, 4732869424627537, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867136636897, '最新', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4732867136636897', 4039202100757950, 4732867136636897, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732958766478114, '热门映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-4732958766478114', 4039245957647571, 4732958766478114, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732915063995311, '按评分 · 本周', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-4732915063995311', 4039291578874799, 4732915063995311, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732924519574590, '语义图的最新脉动——热门映射和新贡献。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-4732924519574590', 4039275101235147, 4732924519574590, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732872119881544, '动态', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-4732872119881544', 4039218305844177, 4732872119881544, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732981769296702, '新增词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4732981769296702', 4039323156297807, 4732981769296702, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732904341512343, '新增章节', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-4732904341512343', 4039302981121903, 4732904341512343, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732965340679649, '手册列表', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-4732965340679649', 4039275162095516, 4732965340679649, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732985078168597, '第 {number} 章', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-4732985078168597', 4039264579862218, 4732985078168597, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732914665271005, '关闭词句信息', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-4732914665271005', 4039238473169231, 4732914665271005, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732862178404436, '收起', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4732862178404436', 4039314752746797, 4732862178404436, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732852224239293, '删除章节', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-4732852224239293', 4039212000754015, 4732852224239293, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732955528992726, '编辑手册', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-4732955528992726', 4039244157921703, 4732955528992726, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732853379033491, '词句信息', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-4732853379033491', 4039248386595592, 4732853379033491, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925169160889, '词句的语言、地区和来源将显示在此处。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-4732925169160889', 4039258685413951, 4732925169160889, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732939380126043, '这本手册有帮助吗？', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-4732939380126043', 4039208667474251, 4732939380126043, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732894556584801, '无法加载词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-4732894556584801', 4039291593337392, 4732894556584801, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851559156278, '无法加载', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4732851559156278', 4039226239864187, 4732851559156278, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4732962676614358', 4039220584763101, 4732962676614358, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732909606012546, '下移', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-4732909606012546', 4039305476617896, 4732909606012546, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732901689906125, '下移章节', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-4732901689906125', 4039264378315169, 4732901689906125, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732941825441639, '上移章节', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-4732941825441639', 4039263980419517, 4732941825441639, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732895478855159, '上移', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-4732895478855159', 4039325459519266, 4732895478855159, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732941105705268, '私密', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-4732941105705268', 4039271025507837, 4732941105705268, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732920051686444, '公开', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-4732920051686444', 4039267993342608, 4732920051686444, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732966305732883, '发布', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-4732966305732883', 4039241948973877, 4732966305732883, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732927105357240, '地区', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4732927105357240', 4039258261318005, 4732927105357240, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732911880814392, '无法加载相关词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-4732911880814392', 4039281597988534, 4732911880814392, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732894447577844, '移除 {text}', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-4732894447577844', 4039238014424846, 4732894447577844, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732920562421013, '保存草稿', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-4732920562421013', 4039263998176559, 4732920562421013, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732966589507329, '保存中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-4732966589507329', 4039270028440745, 4732966589507329, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732952889297006, '章节标题', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-4732952889297006', 4039225159134159, 4732952889297006, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732896806574173, '选择词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-4732896806574173', 4039264953167344, 4732896806574173, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974217058784, '来源', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-4732974217058784', 4039223387675999, 4732974217058784, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898824420991, 'AI', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-4732898824420991', 4039244426247807, 4732898824420991, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732897084453648, '权威', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4732897084453648', 4039318696248928, 4732897084453648, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732876592703820, '用户', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4732876592703820', 4039324440473230, 4732876592703820, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732972705340906, '手册标题', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-4732972705340906', 4039208338888027, 4732972705340906, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732979851549370, '目录', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-4732979851549370', 4039204809556520, 4732979851549370, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732938515945303, '查看完整关系图', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-4732938515945303', 4039218586424477, 4732938515945303, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732875930039614, '可见性', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-4732875930039614', 4039319622118803, 4732875930039614, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732856369317315, '新建手册', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-4732856369317315', 4039273991762691, 4732856369317315, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732868693488413, '加载手册失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-4732868693488413', 4039205037236353, 4732868693488413, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867136636897, '最新', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4732867136636897', 4039202100757950, 4732867136636897, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732859037180806, '未找到手册', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-4732859037180806', 4039297167533555, 4732859037180806, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860261262561, '热门', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4732860261262561', 4039247603774554, 4732860261262561, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732911768082393, '搜索手册…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-4732911768082393', 4039321109759665, 4732911768082393, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732920394107997, '章节', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-4732920394107997', 4039271506815244, 4732920394107997, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974875277185, '手册', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4732974875277185', 4039234820809009, 4732974875277185, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732968405742487, '上一步', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-4732968405742487', 4039313675995469, 4732968405742487, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732978942914570, '取消', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4732978942914570', 4039291340498970, 4732978942914570, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732971925494266, '关闭', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4732971925494266', 4039247982696992, 4732971925494266, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732906091511882, '创建语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4732906091511882', 4039261792696368, 4732906091511882, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882484748244, '语言创建失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-4732882484748244', 4039298612922394, 4732882484748244, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732912509319794, '创建中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-4732912509319794', 4039232938642916, 4732912509319794, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732888290481243, '请输入描述', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-4732888290481243', 4039276426027002, 4732888290481243, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732919840561836, '请选择 Glottolog 匹配或选择「无匹配」', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-4732919840561836', 4039271782430821, 4732919840561836, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732890562615746, '请输入语言名称', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-4732890562615746', 4039210698010944, 4732890562615746, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732852447186000, '请选择仅限社区创建的原因', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-4732852447186000', 4039216473655312, 4732852447186000, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732873661066150, '请输入语言子标签以继续', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-4732873661066150', 4039316213234006, 4732873661066150, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860837059744, '找到 {count} 个候选', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-4732860837059744', 4039246098211492, 4732860837059744, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732956224327086, '选择匹配或标明无合适条目', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-4732956224327086', 4039323364172038, 4732956224327086, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732859482729873, '匹配此候选', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-4732859482729873', 4039325854259152, 4732859482729873, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732888259457316, '方言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-4732888259457316', 4039249282401723, 4732888259457316, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-4732962676614358', 4039243488926094, 4732962676614358, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732885668885445, 'Glottolog 无合适条目', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-4732885668885445', 4039197295194771, 4732885668885445, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732940683972767, '搜索 Glottolog…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-4732940683972767', 4039262313884420, 4732940683972767, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882217870982, '描述', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-4732882217870982', 4039226938266962, 4732882217870982, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732884903174596, '描述此语言或变体…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-4732884903174596', 4039218699342636, 4732884903174596, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732973460244565, '名称', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-4732973460244565', 4039203173843539, 4732973460244565, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860318197751, '英文名称', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-4732860318197751', 4039325286054403, 4732860318197751, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898749691350, '为何此语言未收录于 Glottolog？', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-4732898749691350', 4039255034745478, 4732898749691350, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732881149086117, '社区特定用法', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-4732881149086117', 4039318758556549, 4732881149086117, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974833650181, '新兴变体', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-4732974833650181', 4039201401042810, 4732974833650181, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732922622945667, 'Glottolog 未收录', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-4732922622945667', 4039317085985011, 4732922622945667, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732943607811466, '其他', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-4732943607811466', 4039197354913502, 4732943607811466, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732902008479937, '选择原因…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-4732902008479937', 4039198381390937, 4732902008479937, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732936582122067, '下一步', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-4732936582122067', 4039235695377645, 4732936582122067, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962021251928, '规范代码', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-4732962021251928', 4039275920750884, 4732962021251928, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732859573972271, '此语言已存在', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-4732859573972271', 4039252684783738, 4732859573972271, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732870001876057, '使用现有语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-4732870001876057', 4039201624757562, 4732870001876057, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732906091511882, '创建语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4732906091511882', 4039261792696368, 4732906091511882, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732882317568429, '警告', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-4732882317568429', 4039266319466062, 4732882317568429, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879774152847, '临时标签', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-4732879774152847', 4039258938883345, 4732879774152847, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732894026182703, 'Glottolog 匹配', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-4732894026182703', 4039216090040527, 4732894026182703, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732957894487501, '元数据', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-4732957894487501', 4039278502317771, 4732957894487501, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732866373657696, '预览并创建', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-4732866373657696', 4039292079507095, 4732866373657696, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732972986017179, '语言标签', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-4732972986017179', 4039271969593143, 4732972986017179, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4732962676614358', 4039220584763101, 4732962676614358, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732927105357240, '地区', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4732927105357240', 4039258261318005, 4732927105357240, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732946306447482, '文字', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-4732946306447482', 4039265998307294, 4732946306447482, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732861678468569, '搜索子标签…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-4732861678468569', 4039305028592078, 4732861678468569, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732976367122942, '变体', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-4732976367122942', 4039213349000445, 4732976367122942, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732890213929364, '已移除 1 个变体', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-4732890213929364', 4039300854350766, 4732890213929364, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732875718622151, '已移除 {count} 个变体', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-4732875718622151', 4039288165772049, 4732875718622151, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732868465065051, '按字母排序', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4732868465065051', 4039328989831700, 4732868465065051, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4732962676614358', 4039256322954053, 4732962676614358, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732961335886977, '词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4732961335886977', 4039294118562578, 4732961335886977, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867136636897, '最新', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4732867136636897', 4039202100757950, 4732867136636897, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851559156278, '无法加载', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4732851559156278', 4039226239864187, 4732851559156278, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732921974718441, '已映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-4732921974718441', 4039236848299860, 4732921974718441, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732941375833924, '没有找到词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4732941375833924', 4039240488727553, 4732941375833924, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860261262561, '热门', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4732860261262561', 4039247603774554, 4732860261262561, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879769563383, '搜索词句…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4732879769563383', 4039223809446541, 4732879769563383, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974637662720, '清除选择', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-4732974637662720', 4039193792488426, 4732974637662720, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732892525607033, '创建新语言或变体', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-4732892525607033', 4039299846909774, 4732892525607033, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732983766202846, '无匹配语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4732983766202846', 4039195104624261, 4732983766202846, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732873876986176, '搜索语言…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4732873876986176', 4039246945260645, 4732873876986176, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732853694793670, '浏览器推荐', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-4732853694793670', 4039233498620681, 4732853694793670, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732955461729247, '协助翻译 LangMap', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-4732955461729247', 4039251841046235, 4732955461729247, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732930749302969, '无匹配的语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4732930749302969', 4039195104624261, 4732930749302969, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732942068723022, '最近使用的语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-4732942068723022', 4039306795492531, 4732942068723022, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732961335886977, '词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4732961335886977', 4039294118562578, 4732961335886977, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4732962676614358', 4039256322954053, 4732962676614358, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732978254610146, '无法加载语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4732978254610146', 4039196867547046, 4732978254610146, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732946081141874, '未找到语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-4732946081141874', 4039305123930385, 4732946081141874, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732873876986176, '搜索语言…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4732873876986176', 4039246945260645, 4732873876986176, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732917435641100, 'A–Z', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-4732917435641100', 4039263037467916, 4732917435641100, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898771716122, '按数量', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-4732898771716122', 4039284364068927, 4732898771716122, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732947659797805, '浏览所有语言的词句与映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-4732947659797805', 4039317622660080, 4732947659797805, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4732962676614358', 4039256322954053, 4732962676614358, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732955915662595, '锚点', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-4732955915662595', 4039242362911495, 4732955915662595, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732869335683946, '返回映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-4732869335683946', 4039274630245077, 4732869335683946, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732889063201620, '{count} 种语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-4732889063201620', 4039285488213874, 4732889063201620, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851559156278, '无法加载', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4732851559156278', 4039226239864187, 4732851559156278, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732876898193442, '映射成员', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-4732876898193442', 4039240565339731, 4732876898193442, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732932978160595, '此概念无地理分布数据', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-4732932978160595', 4039279250603930, 4732932978160595, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732916971682988, '{count} 个地区', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-4732916971682988', 4039302107835931, 4732916971682988, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898695263534, '概念分布', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-4732898695263534', 4039208466994401, 4732898695263534, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974562097005, '新增并建立映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-4732974562097005', 4039259535351101, 4732974562097005, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732981769296702, '新增词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4732981769296702', 4039323156297807, 4732981769296702, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732873603341836, '无法新增词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-4732873603341836', 4039198581489142, 4732873603341836, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732914357318360, '新增中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-4732914357318360', 4039218340751327, 4732914357318360, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732897084453648, '权威', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4732897084453648', 4039318696248928, 4732897084453648, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732978803606901, '面包屑', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-4732978803606901', 4039291257989597, 4732978803606901, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732943582125798, '关闭快速新增', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-4732943582125798', 4039267828069642, 4732943582125798, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732917746442477, '贡献映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-4732917746442477', 4039295569136473, 4732917746442477, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732881510118202, '直接映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-4732881510118202', 4039246116479366, 4732881510118202, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974185844390, '请输入词句与语言代码', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-4732974185844390', 4039246255388206, 4732974185844390, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732961335886977, '词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4732961335886977', 4039318048221959, 4732961335886977, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732981996449790, '输入词句…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-4732981996449790', 4039242456703266, 4732981996449790, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732887361502868, '图谱', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-4732887361502868', 4039261403730767, 4732887361502868, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851380331453, '首页', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4732851380331453', 4039277332090535, 4732851380331453, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732869036383207, '跳数', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-4732869036383207', 4039277202124053, 4732869036383207, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732875667194305, '间接', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-4732875667194305', 4039318157522164, 4732875667194305, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732854317060398, '语言代码', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-4732854317060398', 4039210176324565, 4732854317060398, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879446741323, '例如 en / zh-Hant', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-4732879446741323', 4039209337204607, 4732879446741323, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732938080173229, '列表', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-4732938080173229', 4039282174712441, 4732938080173229, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851559156278, '无法加载', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4732851559156278', 4039226239864187, 4732851559156278, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732905770728032, '映射集合', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-4732905770728032', 4039300809727185, 4732905770728032, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925137835302, '尚无映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-4732925137835302', 4039325677769541, 4732925137835302, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732914977239905, '选填', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-4732914977239905', 4039276071486298, 4732914977239905, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732885625319342, '快速新增词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-4732885625319342', 4039324958036767, 4732885625319342, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732897835702266, '新增词句并直接映射到当前词句。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-4732897835702266', 4039212842396077, 4732897835702266, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732927105357240, '地区', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4732927105357240', 4039258261318005, 4732927105357240, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732876592703820, '用户', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4732876592703820', 4039324440473230, 4732876592703820, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732952224270838, '在地图上查看此概念', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-4732952224270838', 4039311455815203, 4732952224270838, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732877002860753, '关闭菜单', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-4732877002860753', 4039297982961690, 4732877002860753, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732967025729950, '贡献', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-4732967025729950', 4039312030295503, 4732967025729950, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732974875277185, '手册', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4732974875277185', 4039234820809009, 4732974875277185, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732851380331453, '首页', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4732851380331453', 4039277332090535, 4732851380331453, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962676614358, '语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4732962676614358', 4039256322954053, 4732962676614358, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732975891429592, '菜单', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-4732975891429592', 4039223542474758, 4732975891429592, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732854424204330, '打开菜单', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-4732854424204330', 4039278126309563, 4732854424204330, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925254141339, '搜索词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4732925254141339', 4039289790753346, 4732925254141339, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860825885107, '登录', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4732860825885107', 4039274956726587, 4732860825885107, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732940503548349, '退出登录', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-4732940503548349', 4039277593503154, 4732940503548349, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732983508898154, '提交搜索', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-4732983508898154', 4039323364353816, 4732983508898154, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732931534300520, '切换界面语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-4732931534300520', 4039195322568967, 4732931534300520, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732880458483410, '按字母顺序', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4732880458483410', 4039328989831700, 4732880458483410, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732912782054918, '提示：目前搜索匹配词句原文。翻译（语义）搜索即将推出。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-4732912782054918', 4039199272982370, 4732912782054918, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732908966545765, '搜索失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-4732908966545765', 4039218663313831, 4732908966545765, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732867136636897, '最新', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4732867136636897', 4039202100757950, 4732867136636897, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732958470510066, '未找到结果', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-4732958470510066', 4039217192958680, 4732958470510066, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879769563383, '搜索词句…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4732879769563383', 4039223809446541, 4732879769563383, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732860261262561, '热门', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4732860261262561', 4039247603774554, 4732860261262561, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732910295591635, '{count} 个结果', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-4732910295591635', 4039304070680160, 4732910295591635, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732870465416226, '排序', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-4732870465416226', 4039290847632508, 4732870465416226, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732925254141339, '搜索词句', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4732925254141339', 4039289790753346, 4732925254141339, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732963835842286, '添加要翻译的语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-4732963835842286', 4039262743786868, 4732963835842286, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732921953038119, '提交 {count} 条翻译', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-4732921953038119', 4039232809480299, 4732921953038119, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732923200186855, '当前翻译', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-4732923200186855', 4039272108076077, 4732923200186855, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732866981816143, '选择已注册的语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-4732866981816143', 4039307820065458, 4732866981816143, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879765246296, '翻译覆盖率', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-4732879765246296', 4039302750746982, 4732879765246296, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732967716079594, '显示 {count} 条', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-4732967716079594', 4039330567083979, 4732967716079594, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898451311877, '社区本地化', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-4732898451311877', 4039263180329406, 4732898451311877, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732898967647787, '输入翻译…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-4732898967647787', 4039280361786422, 4732898967647787, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732923086511452, '无法加载翻译工作台', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-4732923086511452', 4039210189975752, 4732923086511452, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732967235725349, '加载中…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4732967235725349', 4039198023470406, 4732967235725349, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732883497467845, '目标语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-4732883497467845', 4039286503270980, 4732883497467845, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732932964278872, '无法加载语言列表', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-4732932964278872', 4039255464963972, 4732932964278872, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732937860881232, '登录后可提交翻译；候选翻译按映射分数排序，无正分候选时使用回退文本。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-4732937860881232', 4039285344096668, 4732937860881232, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732907027614980, '未找到匹配文本。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-4732907027614980', 4039194547587951, 4732907027614980, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732893430938117, '预览', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-4732893430938117', 4039259327128845, 4732893430938117, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732968947828432, '参考语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-4732968947828432', 4039299601179530, 4732968947828432, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732955802681137, '搜索键名或原文…', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-4732955802681137', 4039252284218610, 4732955802681137, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732962854405133, '选择翻译语言', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-4732962854405133', 4039327112090503, 4732962854405133, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732983772998181, '英文原文', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-4732983772998181', 4039304389733603, 4732983772998181, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732960358505507, '开始', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-4732960358505507', 4039325838792223, 4732960358505507, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732857348512231, '提交失败', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4732857348512231', 4039220418642934, 4732857348512231, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732972836244376, '提交映射', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-4732972836244376', 4039227663321003, 4732972836244376, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732921083135600, '已提交', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-4732921083135600', 4039196288099856, 4732921083135600, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732944141530546, '帮助让 LangMap 界面文本更自然、更实用。', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-4732944141530546', 4039258395876255, 4732944141530546, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732940177067606, '翻译工作台', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-4732940177067606', 4039292410329094, 4732940177067606, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732879657711382, '翻译 {key}', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-4732879657711382', 4039226075472990, 4732879657711382, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732914061336203, '已翻译', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-4732914061336203', 4039206423275507, 4732914061336203, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4732930860466314, '翻译', 'zh-Hans-CN', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-4732930860466314', 4039241150478337, 4732930860466314, 0, 'ui_i18n');

-- Locale zh-Hant-TW
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099005422299412, '電子郵件', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-4099005422299412', 4039278566303563, 4099005422299412, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099012558162962, '已經有帳號了？', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-4099012558162962', 4039276962119789, 4099012558162962, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030668892229, '登入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4099030668892229', 4039274956726587, 4099030668892229, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018782623214, '還沒有帳號？', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-4099018782623214', 4039210512038996, 4099018782623214, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099005501785599, '操作失敗', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-4099005501785599', 4039224592934601, 4099005501785599, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003298959524, '密碼', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-4099003298959524', 4039283475919761, 4099003298959524, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099116690396452, '處理中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-4099116690396452', 4039290683252068, 4099116690396452, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099062286144799, '建立帳號', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-4099062286144799', 4039254012036431, 4099062286144799, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099071525241736, '使用者名稱', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-4099071525241736', 4039318948959047, 4099071525241736, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110489501706, '取消', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4099110489501706', 4039291340498970, 4099110489501706, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099080899427135, '關閉', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4099080899427135', 4039247982696992, 4099080899427135, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4099077128932029', 4039220584763101, 4099077128932029, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4099077128932029', 4039256322954053, 4099077128932029, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099105870896489, '載入中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4099105870896489', 4039198023470406, 4099105870896489, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007997798171, '搜尋', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4099007997798171', 4039307974483127, 4099007997798171, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099025334697157, '提交', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4099025334697157', 4039245021981976, 4099025334697157, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099055158394072, '實際尺寸 100%', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-4099055158394072', 4039203196919686, 4099055158394072, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099036362921052, '匿名', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-4099036362921052', 4039253518652932, 4099036362921052, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099093660575493, '{count} 個子節點；點選收合', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-4099093660575493', 4039322475101146, 4099093660575493, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110956140596, '每條邊皆為可投票的獨立直接對應；低分對應自動收合', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-4099110956140596', 4039318570928695, 4099110956140596, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099095252090684, '待建立的對應圖譜', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-4099095252090684', 4039280324996322, 4099095252090684, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099080510298682, '關閉資訊面板', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-4099080510298682', 4039213218065468, 4099080510298682, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099091035217473, '收合', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4099091035217473', 4039314752746797, 4099091035217473, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099036094363789, '收合子分支', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-4099036094363789', 4039311612904008, 4099036094363789, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098987039829796, '收合至第一層', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-4098987039829796', 4039252699292725, 4098987039829796, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099044686194196, '{count} 天前', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-4099044686194196', 4039305722497088, 4099044686194196, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099104375418520, '深度 {depth}', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-4099104375418520', 4039308224575343, 4099104375418520, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099023578399737, '直接對應詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-4099023578399737', 4039211316535202, 4099023578399737, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099067381370531, '倒讚', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-4099067381370531', 4039281764373654, 4099067381370531, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099001950880517, '{count} 條邊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-4099001950880517', 4039196655494558, 4099001950880517, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099109236775292, '目前沒有資料', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-4099109236775292', 4039290061486601, 4099109236775292, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099021356489314, '退出全螢幕', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-4099021356489314', 4039285164681796, 4099021356489314, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098996522072428, '展開', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-4098996522072428', 4039246642706739, 4098996522072428, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099005481212994, '全部展開', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-4099005481212994', 4039323395460079, 4099005481212994, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099057577057700, '展開子分支', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-4099057577057700', 4039227367141393, 4099057577057700, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068446418894, '詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4099068446418894', 4039318048221959, 4099068446418894, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099010124205419, '篩選語言…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-4099010124205419', 4039264822897467, 4099010124205419, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099006726790571, '全螢幕', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-4099006726790571', 4039273948571546, 4099006726790571, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098985008416130, '詞句對應圖譜', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-4098985008416130', 4039229813257256, 4098985008416130, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099039580110610, '載入圖譜…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-4099039580110610', 4039220553457070, 4099039580110610, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099044478005136, '圖譜模式', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-4099044478005136', 4039307692947617, 4099044478005136, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099064986672982, '{nodes} 個對應節點 · {edges} 個關係', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-4099064986672982', 4039220204112184, 4099064986672982, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098985671835572, '圖譜工具列', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-4098985671835572', 4039247632198973, 4098985671835572, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099083504933979, '對應階層列表', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-4099083504933979', 4039262167197365, 4099083504933979, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099033866043148, '跳數', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-4099033866043148', 4039218745350539, 4099033866043148, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099112715555931, '{count} 小時前', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-4099112715555931', 4039261676051383, 4099112715555931, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099037794911534, '剛剛', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-4099037794911534', 4039295793832731, 4099037794911534, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099088696191607, '無法載入語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4099088696191607', 4039196867547046, 4099088696191607, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099050812678922, '列表模式', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-4099050812678922', 4039267846517304, 4099050812678922, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099076257139496, '載入更多', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-4099076257139496', 4039257935440261, 4099076257139496, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099107363559833, '載入相關詞句中', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-4099107363559833', 4039208559662390, 4099107363559833, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099107811646234, '對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-4099107811646234', 4039299531874366, 4099107811646234, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003731979781, '對應評分', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-4099003731979781', 4039291250524588, 4099003731979781, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099069980774017, '{count} 分鐘前', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-4099069980774017', 4039319528355130, 4099069980774017, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099040653227020, '更多操作', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-4099040653227020', 4039216903072408, 4099040653227020, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099094714643978, '完整圖譜中還有 {count} 個對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-4099094714643978', 4039267933793525, 4099094714643978, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099095640105230, '尚無直接對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-4099095640105230', 4039206484078170, 4099095640105230, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099022567344333, '找不到相符詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4099022567344333', 4039240488727553, 4099022567344333, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099006563381347, '{count} 個節點', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-4099006563381347', 4039205391794884, 4099006563381347, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099054321012886, '節點資訊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-4099054321012886', 4039321854954979, 4099054321012886, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099108039341807, '其他關係', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-4099108039341807', 4039301412743754, 4099108039341807, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099109341204046, '相關詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-4099109341204046', 4039285912508809, 4099109341204046, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098983986587268, '{count} 個關係', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-4098983986587268', 4039195207546455, 4098983986587268, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098987097391647, '移除 {code}', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-4098987097391647', 4039257785545173, 4098987097391647, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077755507257, '重設版面配置', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-4099077755507257', 4039213227329958, 4099077755507257, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099022767289189, '根節點', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-4099022767289189', 4039280733662867, 4099022767289189, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007997798171, '搜尋', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-4099007997798171', 4039307974483127, 4099007997798171, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110324557071, '搜尋詞句…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4099110324557071', 4039223809446541, 4099110324557071, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007436716220, '搜尋中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-4099007436716220', 4039241606316828, 4099007436716220, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099097144200750, '在圖譜中選取節點以檢視詳情', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-4099097144200750', 4039258954601880, 4099097144200750, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098993305742625, '來源路徑', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-4098993305742625', 4039267388033524, 4098993305742625, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099050854987344, '讚', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-4099050854987344', 4039305875761888, 4099050854987344, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099047112837450, '檢視詞句詳情', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-4099047112837450', 4039285357620964, 4099047112837450, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099009023136325, '投票失敗，已復原', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-4099009023136325', 4039310388216878, 4099009023136325, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099046525976082, '放大', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-4099046525976082', 4039307035795639, 4099046525976082, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099029371296860, '縮小', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-4099029371296860', 4039306926563555, 4099029371296860, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099079042684680, '+ 新增詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-4099079042684680', 4039234711174892, 4099079042684680, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099023782700559, '完全圖', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-4099023782700559', 4039210891494791, 4099023782700559, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099074854233573, '刪除', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-4099074854233573', 4039233937430393, 4099074854233573, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099103237227738, '{count} 個直接對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-4099103237227738', 4039258582305025, 4099103237227738, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068446418894, '詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4099068446418894', 4039318048221959, 4099068446418894, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099079989310188, '{count} 個詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-4099079989310188', 4039208226237843, 4099079989310188, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099103904496863, '輸入詞句…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-4099103904496863', 4039264797643778, 4099103904496863, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4099077128932029', 4039220584763101, 4099077128932029, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099015784624069, '提交一組意義相同的詞句。系統會在每對之間建立直接對應。已有詞句會自動關聯，不會重複。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-4099015784624069', 4039228008118707, 4099015784624069, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099048568718230, '至少需要 2 行，每行需填寫語言和詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-4099048568718230', 4039286212175439, 4099048568718230, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099025334697157, '提交', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-4099025334697157', 4039245021981976, 4099025334697157, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099059650179566, '提交失敗', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4099059650179566', 4039220418642934, 4099059650179566, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098982269124284, '提交中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-4098982269124284', 4039286291917398, 4098982269124284, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099115312211369, '標籤', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-4099115312211369', 4039312686530045, 4099115312211369, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099001399967997, '批次提交', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-4099001399967997', 4039256753970050, 4099001399967997, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099019132825307, '回首頁', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-4099019132825307', 4039244552136331, 4099019132825307, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003644392598, '無法載入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4099003644392598', 4039226239864187, 4099003644392598, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099091740103659, '找不到頁面', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-4099091740103659', 4039247795890512, 4099091740103659, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099087671639161, '全部', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-4099087671639161', 4039202333969475, 4099087671639161, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099088732860844, '提交對應 →', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-4099088732860844', 4039241704787781, 4099088732860844, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099114253260592, '熱門', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4099114253260592', 4039247603774554, 4099114253260592, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099095913578856, '對應 + 新詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-4099095913578856', 4039260809744465, 4099095913578856, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099042534801001, '找不到所需內容？', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-4099042534801001', 4039254190870260, 4099042534801001, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099083160437177, '新貢獻', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-4099083160437177', 4039302900266643, 4099083160437177, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998683224033, '最新', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4098998683224033', 4039202100757950, 4098998683224033, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099042366588258, '熱門對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-4099042366588258', 4039245957647571, 4099042366588258, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099074813464022, '依評分 · 本週', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-4099074813464022', 4039291578874799, 4099074813464022, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998631493385, '語意圖的最新脈動——熱門對應與新貢獻。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-4098998631493385', 4039275101235147, 4098998631493385, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099035794755287, '動態', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-4099035794755287', 4039218305844177, 4099035794755287, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098984879859310, '新增詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4098984879859310', 4039323156297807, 4098984879859310, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099012302032703, '新增章節', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-4099012302032703', 4039302981121903, 4099012302032703, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099096566292924, '手冊列表', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-4099096566292924', 4039275162095516, 4099096566292924, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099116624755733, '第 {number} 章', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-4099116624755733', 4039264579862218, 4099116624755733, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099075714701066, '關閉詞句資訊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-4099075714701066', 4039238473169231, 4099075714701066, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099091035217473, '收合', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-4099091035217473', 4039314752746797, 4099091035217473, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099045423580109, '刪除章節', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-4099045423580109', 4039212000754015, 4099045423580109, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099083679584270, '編輯手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-4099083679584270', 4039244157921703, 4099083679584270, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098980855208965, '詞句資訊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-4098980855208965', 4039248386595592, 4098980855208965, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099106176452180, '詞句的語言、地區和來源將顯示在此處。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-4099106176452180', 4039258685413951, 4099106176452180, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099052458730485, '這本手冊有幫助嗎？', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-4099052458730485', 4039208667474251, 4099052458730485, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099074671700117, '無法載入詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-4099074671700117', 4039291593337392, 4099074671700117, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003644392598, '無法載入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4099003644392598', 4039226239864187, 4099003644392598, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4099077128932029', 4039220584763101, 4099077128932029, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099041152599682, '下移', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-4099041152599682', 4039305476617896, 4099041152599682, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099034893603042, '下移章節', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-4099034893603042', 4039264378315169, 4099034893603042, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099020598874480, '上移章節', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-4099020598874480', 4039263980419517, 4099020598874480, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099027025442295, '上移', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-4099027025442295', 4039325459519266, 4099027025442295, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099072652292404, '私密', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-4099072652292404', 4039271025507837, 4099072652292404, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099006387499716, '公開', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-4099006387499716', 4039267993342608, 4099006387499716, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099106582143333, '發布', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-4099106582143333', 4039241948973877, 4099106582143333, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098997526155790, '地區', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4098997526155790', 4039258261318005, 4098997526155790, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099038854800273, '無法載入相關詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-4099038854800273', 4039281597988534, 4099038854800273, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099025994164980, '移除 {text}', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-4099025994164980', 4039238014424846, 4099025994164980, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099091059689121, '儲存草稿', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-4099091059689121', 4039263998176559, 4099091059689121, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099063429773012, '儲存中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-4099063429773012', 4039270028440745, 4099063429773012, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099052035806315, '章節標題', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-4099052035806315', 4039225159134159, 4099052035806315, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099100359973958, '選擇詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-4099100359973958', 4039264953167344, 4099100359973958, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099031095859327, '來源', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-4099031095859327', 4039223387675999, 4099031095859327, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030371008127, 'AI', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-4099030371008127', 4039244426247807, 4099030371008127, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099044233145859, '權威', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4099044233145859', 4039318696248928, 4099044233145859, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099089093036643, '使用者', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4099089093036643', 4039324440473230, 4099089093036643, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099112954990434, '手冊標題', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-4099112954990434', 4039208338888027, 4099112954990434, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099064547651075, '目錄', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-4099064547651075', 4039204809556520, 4099064547651075, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099017881519819, '檢視完整關係圖', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-4099017881519819', 4039218586424477, 4099017881519819, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099055203358616, '可見性', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-4099055203358616', 4039319622118803, 4099055203358616, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099065339446529, '新增手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-4099065339446529', 4039273991762691, 4099065339446529, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099088301910465, '無法載入手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-4099088301910465', 4039205037236353, 4099088301910465, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998683224033, '最新', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4098998683224033', 4039202100757950, 4098998683224033, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099042525962164, '找不到手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-4099042525962164', 4039297167533555, 4099042525962164, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099114253260592, '熱門', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4099114253260592', 4039247603774554, 4099114253260592, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099001283668971, '搜尋手冊…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-4099001283668971', 4039321109759665, 4099001283668971, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099087352754608, '章節', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-4099087352754608', 4039271506815244, 4099087352754608, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007576448337, '手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4099007576448337', 4039234820809009, 4099007576448337, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099099952329623, '上一步', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-4099099952329623', 4039313675995469, 4099099952329623, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110489501706, '取消', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-4099110489501706', 4039291340498970, 4099110489501706, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099080899427135, '關閉', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-4099080899427135', 4039247982696992, 4099080899427135, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099105989846935, '建立語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4099105989846935', 4039261792696368, 4099105989846935, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098988276964653, '語言建立失敗', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-4098988276964653', 4039298612922394, 4098988276964653, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099100521594671, '建立中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-4099100521594671', 4039232938642916, 4099100521594671, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099017921697502, '請輸入描述', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-4099017921697502', 4039276426027002, 4099017921697502, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099078705976307, '請選擇 Glottolog 比對或選擇「無比對」', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-4099078705976307', 4039271782430821, 4099078705976307, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099039168744747, '請輸入語言名稱', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-4099039168744747', 4039210698010944, 4099039168744747, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068027558449, '請選擇僅限社群建立的原因', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-4099068027558449', 4039216473655312, 4099068027558449, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099060633113605, '請輸入語言子標籤以繼續', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-4099060633113605', 4039316213234006, 4099060633113605, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099009127051420, '找到 {count} 個候選', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-4099009127051420', 4039246098211492, 4099009127051420, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018122710228, '選擇比對或標示無合適條目', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-4099018122710228', 4039323364172038, 4099018122710228, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018324893514, '比對此候選', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-4099018324893514', 4039325854259152, 4099018324893514, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099019806044452, '方言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-4099019806044452', 4039249282401723, 4099019806044452, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-4099077128932029', 4039243488926094, 4099077128932029, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099009445612111, 'Glottolog 無合適條目', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-4099009445612111', 4039197295194771, 4099009445612111, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098990910137011, '搜尋 Glottolog…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-4098990910137011', 4039262313884420, 4098990910137011, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099013764458118, '描述', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-4099013764458118', 4039226938266962, 4099013764458118, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099088170045927, '描述此語言或變體…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-4099088170045927', 4039218699342636, 4099088170045927, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099082833252665, '名稱', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-4099082833252665', 4039203173843539, 4099082833252665, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077475406115, '英文名稱', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-4099077475406115', 4039325286054403, 4099077475406115, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099057815623178, '為何此語言未收錄於 Glottolog？', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-4099057815623178', 4039255034745478, 4099057815623178, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099109834322759, '社群特定用法', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-4099109834322759', 4039318758556549, 4099109834322759, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099066819121755, '新興變體', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-4099066819121755', 4039201401042810, 4099066819121755, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099055582276461, 'Glottolog 未收錄', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-4099055582276461', 4039317085985011, 4099055582276461, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099075154398602, '其他', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-4099075154398602', 4039197354913502, 4099075154398602, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099114698407062, '選擇原因…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-4099114698407062', 4039198381390937, 4099114698407062, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068128709203, '下一步', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-4099068128709203', 4039235695377645, 4099068128709203, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099073518291537, '標準代碼', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-4099073518291537', 4039275920750884, 4099073518291537, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099008484095454, '此語言已存在', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-4099008484095454', 4039252684783738, 4099008484095454, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099044865993034, '使用現有語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-4099044865993034', 4039201624757562, 4099044865993034, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099105989846935, '建立語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-4099105989846935', 4039261792696368, 4099105989846935, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099013864155565, '警告', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-4099013864155565', 4039266319466062, 4099013864155565, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098979456369176, '暫時標籤', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-4098979456369176', 4039258938883345, 4098979456369176, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018689014136, 'Glottolog 比對', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-4099018689014136', 4039216090040527, 4099018689014136, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099091735365047, '中繼資料', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-4099091735365047', 4039278502317771, 4099091735365047, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099057561152209, '預覽並建立', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-4099057561152209', 4039292079507095, 4099057561152209, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098981323982819, '語言標籤', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-4098981323982819', 4039271969593143, 4098981323982819, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-4099077128932029', 4039220584763101, 4099077128932029, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098997526155790, '地區', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4098997526155790', 4039258261318005, 4098997526155790, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077853034618, '文字', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-4099077853034618', 4039265998307294, 4099077853034618, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099076049142802, '搜尋子標籤…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-4099076049142802', 4039305028592078, 4099076049142802, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098983307107131, '變體', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-4098983307107131', 4039213349000445, 4098983307107131, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098981392534341, '已移除 1 個變體', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-4098981392534341', 4039300854350766, 4098981392534341, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098979499141341, '已移除 {count} 個變體', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-4098979499141341', 4039288165772049, 4098979499141341, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099090870259409, '依字母排序', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4099090870259409', 4039328989831700, 4099090870259409, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4099077128932029', 4039256322954053, 4099077128932029, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068446418894, '詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4099068446418894', 4039294118562578, 4099068446418894, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998683224033, '最新', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4098998683224033', 4039202100757950, 4098998683224033, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003644392598, '無法載入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4099003644392598', 4039226239864187, 4099003644392598, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098984386773176, '已對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-4098984386773176', 4039236848299860, 4098984386773176, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098989256287679, '找不到詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-4098989256287679', 4039240488727553, 4098989256287679, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099114253260592, '熱門', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4099114253260592', 4039247603774554, 4099114253260592, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110324557071, '搜尋詞句…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4099110324557071', 4039223809446541, 4099110324557071, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099027264897142, '清除選擇', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-4099027264897142', 4039193792488426, 4099027264897142, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099082779040322, '建立新語言或變體', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-4099082779040322', 4039299846909774, 4099082779040322, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099074243529122, '無符合語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4099074243529122', 4039195104624261, 4099074243529122, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018494294818, '搜尋語言…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4099018494294818', 4039246945260645, 4099018494294818, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098997764090305, '瀏覽器推薦', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-4098997764090305', 4039233498620681, 4098997764090305, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099009640974647, '協助翻譯 LangMap', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-4099009640974647', 4039251841046235, 4099009640974647, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099024342705939, '無符合的語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-4099024342705939', 4039195104624261, 4099024342705939, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099038494733326, '最近使用的語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-4099038494733326', 4039306795492531, 4099038494733326, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068446418894, '詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-4099068446418894', 4039294118562578, 4099068446418894, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4099077128932029', 4039256322954053, 4099077128932029, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099088696191607, '無法載入語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-4099088696191607', 4039196867547046, 4099088696191607, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099002348874703, '找不到語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-4099002348874703', 4039305123930385, 4099002348874703, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018494294818, '搜尋語言…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-4099018494294818', 4039246945260645, 4099018494294818, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099048982228236, 'A–Z', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-4099048982228236', 4039263037467916, 4099048982228236, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099027061960817, '依數量', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-4099027061960817', 4039284364068927, 4099027061960817, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099089362276526, '瀏覽所有語言的詞句與對應關係', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-4099089362276526', 4039317622660080, 4099089362276526, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4099077128932029', 4039256322954053, 4099077128932029, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007538692033, '錨點', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-4099007538692033', 4039242362911495, 4099007538692033, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099035670573144, '回到對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-4099035670573144', 4039274630245077, 4099035670573144, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099015600516417, '{count} 種語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-4099015600516417', 4039285488213874, 4099015600516417, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003644392598, '無法載入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4099003644392598', 4039226239864187, 4099003644392598, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099028457215805, '對應成員', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-4099028457215805', 4039240565339731, 4099028457215805, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099027667678454, '此概念無地理分佈資料', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-4099027667678454', 4039279250603930, 4099027667678454, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099021459039179, '{count} 個地區', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-4099021459039179', 4039302107835931, 4099021459039179, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099052536144516, '概念分佈', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-4099052536144516', 4039208466994401, 4099052536144516, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099010040195913, '新增並建立對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-4099010040195913', 4039259535351101, 4099010040195913, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098984879859310, '新增詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-4098984879859310', 4039323156297807, 4098984879859310, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099039162871168, '無法新增詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-4099039162871168', 4039198581489142, 4099039162871168, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099045903905496, '新增中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-4099045903905496', 4039218340751327, 4099045903905496, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099044233145859, '權威', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-4099044233145859', 4039318696248928, 4099044233145859, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098995833223777, '麵包屑', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-4098995833223777', 4039291257989597, 4098995833223777, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099050418905677, '關閉快速新增', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-4099050418905677', 4039267828069642, 4099050418905677, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030724393162, '貢獻對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-4099030724393162', 4039295569136473, 4099030724393162, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099075123451818, '直接對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-4099075123451818', 4039246116479366, 4099075123451818, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099105742129750, '請輸入詞句與語言代碼', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-4099105742129750', 4039246255388206, 4099105742129750, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099068446418894, '詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-4099068446418894', 4039318048221959, 4099068446418894, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099103904496863, '輸入詞句…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-4099103904496863', 4039242456703266, 4099103904496863, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099013810341513, '圖譜', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-4099013810341513', 4039261403730767, 4099013810341513, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099070914153256, '首頁', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4099070914153256', 4039277332090535, 4099070914153256, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099033866043148, '跳數', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-4099033866043148', 4039277202124053, 4099033866043148, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099023443039104, '間接', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-4099023443039104', 4039318157522164, 4099023443039104, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998351345348, '語言代碼', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-4098998351345348', 4039210176324565, 4098998351345348, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099010993328459, '例如 en / zh-Hant', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-4099010993328459', 4039209337204607, 4099010993328459, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099069626760365, '列表', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-4099069626760365', 4039282174712441, 4099069626760365, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003644392598, '無法載入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-4099003644392598', 4039226239864187, 4099003644392598, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099078334720024, '對應集合', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-4099078334720024', 4039300809727185, 4099078334720024, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099083287941846, '尚無對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-4099083287941846', 4039325677769541, 4099083287941846, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099009075637478, '選填', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-4099009075637478', 4039276071486298, 4099009075637478, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098987050061798, '快速新增詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-4098987050061798', 4039324958036767, 4098987050061798, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098985801608001, '新增詞句並直接對應到目前詞句。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-4098985801608001', 4039212842396077, 4098985801608001, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098997526155790, '地區', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-4098997526155790', 4039258261318005, 4098997526155790, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099089093036643, '使用者', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-4099089093036643', 4039324440473230, 4099089093036643, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099031940928113, '在地圖上檢視此概念', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-4099031940928113', 4039311455815203, 4099031940928113, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099085017788647, '關閉選單', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-4099085017788647', 4039297982961690, 4099085017788647, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099050390728930, '貢獻', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-4099050390728930', 4039312030295503, 4099050390728930, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099007576448337, '手冊', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-4099007576448337', 4039234820809009, 4099007576448337, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099070914153256, '首頁', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-4099070914153256', 4039277332090535, 4099070914153256, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099077128932029, '語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-4099077128932029', 4039256322954053, 4099077128932029, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099027345282225, '選單', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-4099027345282225', 4039223542474758, 4099027345282225, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099000589138705, '開啟選單', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-4099000589138705', 4039278126309563, 4099000589138705, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099011650842915, '搜尋詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4099011650842915', 4039289790753346, 4099011650842915, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030668892229, '登入', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-4099030668892229', 4039274956726587, 4099030668892229, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099099992561461, '登出', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-4099099992561461', 4039277593503154, 4099099992561461, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099003620355992, '送出搜尋', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-4099003620355992', 4039323364353816, 4099003620355992, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098995705350438, '切換介面語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-4098995705350438', 4039195322568967, 4098995705350438, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099002160843279, '依字母順序', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-4099002160843279', 4039328989831700, 4099002160843279, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099018197509151, '提示：目前搜尋比對詞句原文。語意搜尋即將推出。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-4099018197509151', 4039199272982370, 4099018197509151, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099066295824878, '搜尋失敗', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-4099066295824878', 4039218663313831, 4099066295824878, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098998683224033, '最新', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-4098998683224033', 4039202100757950, 4098998683224033, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099019935867249, '找不到結果', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-4099019935867249', 4039217192958680, 4099019935867249, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099110324557071, '搜尋詞句…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-4099110324557071', 4039223809446541, 4099110324557071, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099114253260592, '熱門', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-4099114253260592', 4039247603774554, 4099114253260592, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098992877618180, '{count} 個結果', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-4098992877618180', 4039304070680160, 4098992877618180, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099002012003362, '排序', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-4099002012003362', 4039290847632508, 4099002012003362, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099011650842915, '搜尋詞句', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-4099011650842915', 4039289790753346, 4099011650842915, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099092190540092, '新增要翻譯的語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-4099092190540092', 4039262743786868, 4099092190540092, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099076355299837, '提交 {count} 筆翻譯', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-4099076355299837', 4039232809480299, 4099076355299837, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099029847640278, '目前翻譯', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-4099029847640278', 4039272108076077, 4099029847640278, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099023798400894, '選擇已註冊的語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-4099023798400894', 4039307820065458, 4099023798400894, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099113364972698, '翻譯涵蓋率', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-4099113364972698', 4039302750746982, 4099113364972698, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099060561542046, '顯示 {count} 筆', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-4099060561542046', 4039330567083979, 4099060561542046, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099040258519968, '社群本地化', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-4099040258519968', 4039263180329406, 4099040258519968, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099096407873565, '輸入翻譯…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-4099096407873565', 4039280361786422, 4099096407873565, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4098981694440642, '無法載入翻譯工作台', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-4098981694440642', 4039210189975752, 4098981694440642, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099105870896489, '載入中…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-4099105870896489', 4039198023470406, 4099105870896489, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030413149592, '目標語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-4099030413149592', 4039286503270980, 4099030413149592, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099064215591724, '無法載入語言列表', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-4099064215591724', 4039255464963972, 4099064215591724, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099069931029805, '登入後可提交翻譯；候選翻譯依對應分數排序，無正分候選時使用備用文字。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-4099069931029805', 4039285344096668, 4099069931029805, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099033738578126, '找不到相符文字。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-4099033738578126', 4039194547587951, 4099033738578126, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099113830519682, '預覽', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-4099113830519682', 4039259327128845, 4099113830519682, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099020890920960, '參考語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-4099020890920960', 4039299601179530, 4099020890920960, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099102290049465, '搜尋鍵名或原文…', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-4099102290049465', 4039252284218610, 4099102290049465, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099031212571979, '選擇翻譯語言', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-4099031212571979', 4039327112090503, 4099031212571979, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099115319585317, '英文原文', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-4099115319585317', 4039304389733603, 4099115319585317, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099074691391416, '開始', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-4099074691391416', 4039325838792223, 4099074691391416, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099059650179566, '提交失敗', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-4099059650179566', 4039220418642934, 4099059650179566, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099030537545497, '提交對應', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-4099030537545497', 4039227663321003, 4099030537545497, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099052629722736, '已提交', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-4099052629722736', 4039196288099856, 4099052629722736, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099001262423208, '幫助讓 LangMap 介面文字更自然、更實用。', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-4099001262423208', 4039258395876255, 4099001262423208, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099050004222831, '翻譯工作台', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-4099050004222831', 4039292410329094, 4099050004222831, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099075258254677, '翻譯 {key}', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-4099075258254677', 4039226075472990, 4099075258254677, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099083094937134, '已翻譯', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-4099083094937134', 4039206423275507, 4099083094937134, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (4099033115453003, '翻譯', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-4099033115453003', 4039241150478337, 4099033115453003, 0, 'ui_i18n');

-- Done