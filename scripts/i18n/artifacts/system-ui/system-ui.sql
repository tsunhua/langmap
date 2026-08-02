-- Generated managed system UI translation bundle
-- Project: langmap-web
-- Ownership scope: managed-system-ui

-- 1. Upsert locale metadata
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
-- Locale es
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682868324365489, 'Correo electrónico', 'es', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682868324365489-4039278566303563', 4039278566303563, 682868324365489, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913794312592, '¿Ya tienes cuenta?', 'es', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913794312592-4039276962119789', 4039276962119789, 682913794312592, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892872018745, 'Iniciar sesión', 'es', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892872018745-4039274956726587', 4039274956726587, 682892872018745, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824306479408, '¿No tienes cuenta?', 'es', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824306479408-4039210512038996', 4039210512038996, 682824306479408, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682806459380331, 'Operación fallida', 'es', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682806459380331-4039224592934601', 4039224592934601, 682806459380331, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903623135850, 'Contraseña', 'es', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903623135850-4039283475919761', 4039283475919761, 682903623135850, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682800676237530, 'Procesando…', 'es', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682800676237530-4039290683252068', 4039290683252068, 682800676237530, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878957095027, 'Crear cuenta', 'es', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878957095027-4039254012036431', 4039254012036431, 682878957095027, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682803377749737, 'Nombre de usuario', 'es', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682803377749737-4039318948959047', 4039318948959047, 682803377749737, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798661288703, 'Cancelar', 'es', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798661288703-4039291340498970', 4039291340498970, 682798661288703, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883488560665, 'Cerrar', 'es', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883488560665-4039247982696992', 4039247982696992, 682883488560665, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-4039220584763101', 4039220584763101, 682900757579840, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-4039256322954053', 4039256322954053, 682828789630925, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859154714796, 'Cargando…', 'es', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859154714796-4039198023470406', 4039198023470406, 682859154714796, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904154017666, 'Buscar', 'es', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904154017666-4039307974483127', 4039307974483127, 682904154017666, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909207233641, 'Enviar', 'es', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909207233641-4039245021981976', 4039245021981976, 682909207233641, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900282106249, 'Tamaño real 100%', 'es', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900282106249-4039203196919686', 4039203196919686, 682900282106249, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878566757732, 'Anónimo', 'es', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878566757732-4039253518652932', 4039253518652932, 682878566757732, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682811764541936, '{count} nodos hijos; haz clic para colapsar', 'es', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682811764541936-4039322475101146', 4039322475101146, 682811764541936, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682852513874987, 'Cada arista es una relación directa independiente que se puede votar a favor o en contra; las relaciones con baja puntuación se colapsan.', 'es', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682852513874987-4039318570928695', 4039318570928695, 682852513874987, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919370768583, 'Grafo de relaciones a crear', 'es', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919370768583-4039280324996322', 4039280324996322, 682919370768583, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682816040996372, 'Cerrar panel de información', 'es', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682816040996372-4039213218065468', 4039213218065468, 682816040996372, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914227463087, 'Colapsar', 'es', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914227463087-4039314752746797', 4039314752746797, 682914227463087, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682803607295846, 'Colapsar rama hija', 'es', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682803607295846-4039311612904008', 4039311612904008, 682803607295846, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859696644566, 'Colapsar al primer nivel', 'es', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859696644566-4039252699292725', 4039252699292725, 682859696644566, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919851973958, 'Hace {count} días', 'es', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919851973958-4039305722497088', 4039305722497088, 682919851973958, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842955261625, 'Profundidad {depth}', 'es', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842955261625-4039308224575343', 4039308224575343, 682842955261625, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815072780171, 'Expresiones con relación directa', 'es', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815072780171-4039211316535202', 4039211316535202, 682815072780171, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889948742785, 'Votar en contra', 'es', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889948742785-4039281764373654', 4039281764373654, 682889948742785, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905389963153, '{count} aristas', 'es', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905389963153-4039196655494558', 4039196655494558, 682905389963153, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812603593886, 'Aún no hay datos', 'es', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812603593886-4039290061486601', 4039290061486601, 682812603593886, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682898902420755, 'Salir de pantalla completa', 'es', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682898902420755-4039285164681796', 4039285164681796, 682898902420755, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888528901639, 'Expandir', 'es', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888528901639-4039246642706739', 4039246642706739, 682888528901639, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855150211439, 'Expandir todo', 'es', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855150211439-4039323395460079', 4039323395460079, 682855150211439, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905168406966, 'Expandir rama hija', 'es', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905168406966-4039227367141393', 4039227367141393, 682905168406966, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-4039318048221959', 4039318048221959, 682831404901271, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858781814402, 'Filtrar idiomas…', 'es', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858781814402-4039264822897467', 4039264822897467, 682858781814402, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870740246259, 'Pantalla completa', 'es', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870740246259-4039273948571546', 4039273948571546, 682870740246259, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865789089431, 'Grafo de relaciones de expresiones', 'es', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865789089431-4039229813257256', 4039229813257256, 682865789089431, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858747257175, 'Cargando grafo…', 'es', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858747257175-4039220553457070', 4039220553457070, 682858747257175, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682841174674405, 'Modo grafo', 'es', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682841174674405-4039307692947617', 4039307692947617, 682841174674405, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864010028789, '{nodes} nodos mapeados · {edges} relaciones', 'es', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864010028789-4039220204112184', 4039220204112184, 682864010028789, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822929160288, 'Barra de herramientas del grafo', 'es', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822929160288-4039247632198973', 4039247632198973, 682822929160288, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869729672125, 'Lista jerárquica de relaciones', 'es', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869729672125-4039262167197365', 4039262167197365, 682869729672125, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682835277438690, 'Saltos', 'es', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682835277438690-4039218745350539', 4039218745350539, 682835277438690, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914700697726, 'Hace {count} horas', 'es', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914700697726-4039261676051383', 4039261676051383, 682914700697726, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858170221799, 'Ahora mismo', 'es', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858170221799-4039295793832731', 4039295793832731, 682858170221799, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897399365859, 'No se pudieron cargar los idiomas', 'es', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897399365859-4039196867547046', 4039196867547046, 682897399365859, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682929803561659, 'Modo lista', 'es', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682929803561659-4039267846517304', 4039267846517304, 682929803561659, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682809581221683, 'Cargar más', 'es', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682809581221683-4039257935440261', 4039257935440261, 682809581221683, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890862435526, 'Cargando expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890862435526-4039208559662390', 4039208559662390, 682890862435526, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682839530633697, 'Relación', 'es', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682839530633697-4039299531874366', 4039299531874366, 682839530633697, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890402565558, 'Puntuación de la relación', 'es', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890402565558-4039291250524588', 4039291250524588, 682890402565558, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682817694689253, 'Hace {count} minutos', 'es', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682817694689253-4039319528355130', 4039319528355130, 682817694689253, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682819625579845, 'Más acciones', 'es', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682819625579845-4039216903072408', 4039216903072408, 682819625579845, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903147448559, '{count} relaciones más disponibles en el grafo completo', 'es', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903147448559-4039267933793525', 4039267933793525, 682903147448559, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854737236104, 'Aún no hay relaciones directas', 'es', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854737236104-4039206484078170', 4039206484078170, 682854737236104, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682884245166836, 'No se encontraron expresiones', 'es', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682884245166836-4039240488727553', 4039240488727553, 682884245166836, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914114350784, '{count} nodos', 'es', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914114350784-4039205391794884', 4039205391794884, 682914114350784, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853735237920, 'Información del nodo', 'es', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853735237920-4039321854954979', 4039321854954979, 682853735237920, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682810019697541, 'Otras relaciones', 'es', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682810019697541-4039301412743754', 4039301412743754, 682810019697541, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931322749113, 'Expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931322749113-4039285912508809', 4039285912508809, 682931322749113, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901541740022, '{count} relaciones', 'es', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901541740022-4039195207546455', 4039195207546455, 682901541740022, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871527117091, 'Eliminar {code}', 'es', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871527117091-4039257785545173', 4039257785545173, 682871527117091, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824764392007, 'Restablecer diseño', 'es', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824764392007-4039213227329958', 4039213227329958, 682824764392007, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682905582744699, 'Nodo raíz', 'es', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682905582744699-4039280733662867', 4039280733662867, 682905582744699, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904154017666, 'Buscar', 'es', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904154017666-4039307974483127', 4039307974483127, 682904154017666, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-4039223809446541', 4039223809446541, 682820215961472, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682839248463634, 'Buscando…', 'es', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682839248463634-4039241606316828', 4039241606316828, 682839248463634, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682797643305883, 'Selecciona un nodo en el grafo para ver detalles', 'es', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682797643305883-4039258954601880', 4039258954601880, 682797643305883, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855228652320, 'Ruta de origen', 'es', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855228652320-4039267388033524', 4039267388033524, 682855228652320, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682848709766753, 'Votar a favor', 'es', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682848709766753-4039305875761888', 4039305875761888, 682848709766753, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682882404036245, 'Ver detalles de la expresión', 'es', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682882404036245-4039285357620964', 4039285357620964, 682882404036245, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842684816837, 'Voto fallido; revertido', 'es', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842684816837-4039310388216878', 4039310388216878, 682842684816837, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854827697630, 'Acercar', 'es', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854827697630-4039307035795639', 4039307035795639, 682854827697630, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682886003065027, 'Alejar', 'es', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682886003065027-4039306926563555', 4039306926563555, 682886003065027, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851144798066, '+ Añadir expresión', 'es', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851144798066-4039234711174892', 4039234711174892, 682851144798066, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682926967595430, 'Grafo completo', 'es', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682926967595430-4039210891494791', 4039210891494791, 682926967595430, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865595864632, 'Eliminar', 'es', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865595864632-4039233937430393', 4039233937430393, 682865595864632, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682836725062290, '{count} relaciones directas', 'es', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682836725062290-4039258582305025', 4039258582305025, 682836725062290, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-4039318048221959', 4039318048221959, 682831404901271, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876212042190, '{count} expresiones', 'es', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876212042190-4039208226237843', 4039208226237843, 682876212042190, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682899105867642, 'Introduce una expresión…', 'es', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682899105867642-4039264797643778', 4039264797643778, 682899105867642, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-4039220584763101', 4039220584763101, 682900757579840, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870347524468, 'Envía un grupo de expresiones que significan lo mismo. El sistema crea relaciones directas entre cada par. Las expresiones existentes se vinculan automáticamente sin duplicados.', 'es', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870347524468-4039228008118707', 4039228008118707, 682870347524468, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873791744221, 'Se requieren al menos 2 filas con idioma y expresión', 'es', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873791744221-4039286212175439', 4039286212175439, 682873791744221, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909207233641, 'Enviar', 'es', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909207233641-4039245021981976', 4039245021981976, 682909207233641, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798159782041, 'Error al enviar', 'es', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798159782041-4039220418642934', 4039220418642934, 682798159782041, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814360395519, 'Enviando…', 'es', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814360395519-4039286291917398', 4039286291917398, 682814360395519, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682817218566349, 'Etiquetas', 'es', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682817218566349-4039312686530045', 4039312686530045, 682817218566349, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682930493925566, 'Contribución por lotes', 'es', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682930493925566-4039256753970050', 4039256753970050, 682930493925566, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827446740449, 'Volver al inicio', 'es', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827446740449-4039244552136331', 4039244552136331, 682827446740449, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-4039226239864187', 4039226239864187, 682931450456078, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883833799037, 'Página no encontrada', 'es', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883833799037-4039247795890512', 4039247795890512, 682883833799037, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897294012569, 'Todo', 'es', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897294012569-4039202333969475', 4039202333969475, 682897294012569, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682924233918709, 'Contribuir una relación →', 'es', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682924233918709-4039241704787781', 4039241704787781, 682924233918709, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-4039247603774554', 4039247603774554, 682850921034842, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682912286542237, 'Relaciones + nuevas expresiones', 'es', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682912286542237-4039260809744465', 4039260809744465, 682912286542237, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885280317750, '¿No encuentras lo que buscas?', 'es', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885280317750-4039254190870260', 4039254190870260, 682885280317750, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903296125126, 'Nuevas contribuciones', 'es', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903296125126-4039302900266643', 4039302900266643, 682903296125126, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-4039202100757950', 4039202100757950, 682854338769382, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876078164459, 'Relaciones populares', 'es', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876078164459-4039245957647571', 4039245957647571, 682876078164459, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682874855282633, 'Por puntuación · esta semana', 'es', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682874855282633-4039291578874799', 4039291578874799, 682874855282633, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682879301535115, 'El pulso más reciente del grafo semántico: relaciones populares y nuevas contribuciones.', 'es', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682879301535115-4039275101235147', 4039275101235147, 682879301535115, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851376042934, 'Actividad', 'es', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851376042934-4039218305844177', 4039218305844177, 682851376042934, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682896175839391, 'Añadir expresión', 'es', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682896175839391-4039323156297807', 4039323156297807, 682896175839391, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682907584357528, 'Añadir sección', 'es', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682907584357528-4039302981121903', 4039302981121903, 682907584357528, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887455285958, 'Lista de manuales', 'es', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887455285958-4039275162095516', 4039275162095516, 682887455285958, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682909247411400, 'Capítulo {number}', 'es', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682909247411400-4039264579862218', 4039264579862218, 682909247411400, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682802420165888, 'Cerrar información de la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682802420165888-4039238473169231', 4039238473169231, 682802420165888, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682914227463087, 'Colapsar', 'es', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682914227463087-4039314752746797', 4039314752746797, 682914227463087, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847392263001, 'Eliminar sección', 'es', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847392263001-4039212000754015', 4039212000754015, 682847392263001, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682903001549444, 'Editar manual', 'es', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682903001549444-4039244157921703', 4039244157921703, 682903001549444, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871456822120, 'Información de la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871456822120-4039248386595592', 4039248386595592, 682871456822120, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682918537509057, 'El idioma, la región y la fuente de la expresión aparecerán aquí.', 'es', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682918537509057-4039258685413951', 4039258685413951, 682918537509057, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865333050613, '¿Te resultó útil este manual?', 'es', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865333050613-4039208667474251', 4039208667474251, 682865333050613, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871525229530, 'No se pudo cargar la expresión', 'es', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871525229530-4039291593337392', 4039291593337392, 682871525229530, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-4039226239864187', 4039226239864187, 682931450456078, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-4039220584763101', 4039220584763101, 682900757579840, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820585428709, 'Mover abajo', 'es', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820585428709-4039305476617896', 4039305476617896, 682820585428709, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682840750863606, 'Mover sección abajo', 'es', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682840750863606-4039264378315169', 4039264378315169, 682840750863606, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853627392960, 'Mover sección arriba', 'es', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853627392960-4039263980419517', 4039263980419517, 682853627392960, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682801072299066, 'Mover arriba', 'es', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682801072299066-4039325459519266', 4039325459519266, 682801072299066, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682923071600521, 'Privado', 'es', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682923071600521-4039271025507837', 4039271025507837, 682923071600521, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682910096190915, 'Público', 'es', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682910096190915-4039267993342608', 4039267993342608, 682910096190915, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913156609638, 'Publicar', 'es', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913156609638-4039241948973877', 4039241948973877, 682913156609638, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-4039258261318005', 4039258261318005, 682890354277950, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682930588561372, 'No se pudieron cargar las expresiones relacionadas', 'es', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682930588561372-4039281597988534', 4039281597988534, 682930588561372, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682846178918264, 'Eliminar {text}', 'es', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682846178918264-4039238014424846', 4039238014424846, 682846178918264, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901426200083, 'Guardar borrador', 'es', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901426200083-4039263998176559', 4039263998176559, 682901426200083, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682919067142996, 'Guardando…', 'es', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682919067142996-4039270028440745', 4039270028440745, 682919067142996, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883612905517, 'Título de la sección', 'es', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883612905517-4039225159134159', 4039225159134159, 682883612905517, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847725144221, 'Seleccionar una expresión', 'es', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847725144221-4039264953167344', 4039264953167344, 682847725144221, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892161499513, 'Fuente', 'es', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892161499513-4039223387675999', 4039223387675999, 682892161499513, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682932709012149, 'IA', 'es', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682932709012149-4039244426247807', 4039244426247807, 682932709012149, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873592117071, 'Autoridad', 'es', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873592117071-4039318696248928', 4039318696248928, 682873592117071, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925132503903, 'Usuario', 'es', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925132503903-4039324440473230', 4039324440473230, 682925132503903, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682908876610953, 'Título del manual', 'es', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682908876610953-4039208338888027', 4039208338888027, 682908876610953, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682819580133454, 'Contenido', 'es', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682819580133454-4039204809556520', 4039204809556520, 682819580133454, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682856006386013, 'Ver grafo completo de relaciones', 'es', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682856006386013-4039218586424477', 4039218586424477, 682856006386013, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885242904874, 'Visibilidad', 'es', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885242904874-4039319622118803', 4039319622118803, 682885242904874, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682840614580731, 'Nuevo manual', 'es', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682840614580731-4039273991762691', 4039273991762691, 682840614580731, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828325867692, 'No se pudieron cargar los manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828325867692-4039205037236353', 4039205037236353, 682828325867692, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-4039202100757950', 4039202100757950, 682854338769382, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814365188442, 'No se encontraron manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814365188442-4039297167533555', 4039297167533555, 682814365188442, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-4039247603774554', 4039247603774554, 682850921034842, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682845859077642, 'Buscar manuales…', 'es', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682845859077642-4039321109759665', 4039321109759665, 682845859077642, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820985582214, 'secciones', 'es', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820985582214-4039271506815244', 4039271506815244, 682820985582214, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682921146202531, 'Manuales', 'es', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682921146202531-4039234820809009', 4039234820809009, 682921146202531, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682881325797934, 'Atrás', 'es', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682881325797934-4039313675995469', 4039313675995469, 682881325797934, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798661288703, 'Cancelar', 'es', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798661288703-4039291340498970', 4039291340498970, 682798661288703, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682883488560665, 'Cerrar', 'es', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682883488560665-4039247982696992', 4039247982696992, 682883488560665, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904885771263, 'Crear idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904885771263-4039261792696368', 4039261792696368, 682904885771263, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682893540709366, 'Error al crear el idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682893540709366-4039298612922394', 4039298612922394, 682893540709366, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682826813618939, 'Creando…', 'es', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682826813618939-4039232938642916', 4039232938642916, 682826813618939, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831989539817, 'Introduce una descripción', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831989539817-4039276426027002', 4039276426027002, 682831989539817, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931417783940, 'Elige una coincidencia Glottolog o selecciona «sin coincidencia»', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931417783940-4039271782430821', 4039271782430821, 682931417783940, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682814340105906, 'Introduce un nombre de idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682814340105906-4039210698010944', 4039210698010944, 682814340105906, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682917329596165, 'Selecciona un motivo para la creación solo comunitaria', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682917329596165-4039216473655312', 4039216473655312, 682917329596165, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682825626662306, 'Introduce una subetiqueta de idioma para continuar', 'es', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682825626662306-4039316213234006', 4039316213234006, 682825626662306, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799931959085, '{count} candidato(s) encontrado(s)', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799931959085-4039246098211492', 4039246098211492, 682799931959085, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869629998340, 'Elige una coincidencia o indica que no hay entrada adecuada', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869629998340-4039323364172038', 4039323364172038, 682869629998340, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915180693699, 'Elegir este candidato', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915180693699-4039325854259152', 4039325854259152, 682915180693699, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682895952382846, 'dialecto', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682895952382846-4039249282401723', 4039249282401723, 682895952382846, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824256985236, 'idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824256985236-4039243488926094', 4039243488926094, 682824256985236, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682813918400823, 'Glottolog no tiene una entrada adecuada', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682813918400823-4039197295194771', 4039197295194771, 682813918400823, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931260832027, 'Buscar en Glottolog…', 'es', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931260832027-4039262313884420', 4039262313884420, 682931260832027, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865550849454, 'Descripción', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865550849454-4039226938266962', 4039226938266962, 682865550849454, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864204631545, 'Describe este idioma o variedad…', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864204631545-4039218699342636', 4039218699342636, 682864204631545, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897020949278, 'Nombre', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897020949278-4039203173843539', 4039203173843539, 682897020949278, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682878840728431, 'Nombre en inglés', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682878840728431-4039325286054403', 4039325286054403, 682878840728431, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682834735258162, '¿Por qué falta este idioma en Glottolog?', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682834735258162-4039255034745478', 4039255034745478, 682834735258162, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828421562039, 'Uso específico de la comunidad', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828421562039-4039318758556549', 4039318758556549, 682828421562039, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682869368838054, 'Variante emergente', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682869368838054-4039201401042810', 4039201401042810, 682869368838054, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682871876394970, 'Falta en Glottolog', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682871876394970-4039317085985011', 4039317085985011, 682871876394970, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682836132939567, 'Otro', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682836132939567-4039197354913502', 4039197354913502, 682836132939567, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827073546062, 'Selecciona un motivo…', 'es', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827073546062-4039198381390937', 4039198381390937, 682827073546062, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873107003134, 'Siguiente', 'es', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873107003134-4039235695377645', 4039235695377645, 682873107003134, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682856233469549, 'Código canónico', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682856233469549-4039275920750884', 4039275920750884, 682856233469549, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682801129462806, 'Este idioma ya existe', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682801129462806-4039252684783738', 4039252684783738, 682801129462806, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682830840681764, 'Usar idioma existente', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682830840681764-4039201624757562', 4039201624757562, 682830840681764, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682904885771263, 'Crear idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682904885771263-4039261792696368', 4039261792696368, 682904885771263, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682838014240047, 'Advertencias', 'es', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682838014240047-4039266319466062', 4039266319466062, 682838014240047, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682807648996300, 'Etiqueta provisional', 'es', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682807648996300-4039258938883345', 4039258938883345, 682807648996300, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925626679266, 'Coincidencia Glottolog', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925626679266-4039216090040527', 4039216090040527, 682925626679266, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682876390474633, 'Metadatos', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682876390474633-4039278502317771', 4039278502317771, 682876390474633, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682841843489511, 'Vista previa y crear', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682841843489511-4039292079507095', 4039292079507095, 682841843489511, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854301270668, 'Etiqueta de idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854301270668-4039271969593143', 4039271969593143, 682854301270668, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900757579840, 'Idioma', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900757579840-4039220584763101', 4039220584763101, 682900757579840, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-4039258261318005', 4039258261318005, 682890354277950, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682855713333931, 'Escritura', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682855713333931-4039265998307294', 4039265998307294, 682855713333931, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682933636836112, 'Buscar subetiquetas…', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682933636836112-4039305028592078', 4039305028592078, 682933636836112, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815391355869, 'Variante', 'es', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815391355869-4039213349000445', 4039213349000445, 682815391355869, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915042677354, '1 variante eliminada', 'es', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915042677354-4039300854350766', 4039300854350766, 682915042677354, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815962453613, '{count} variante(s) eliminada(s)', 'es', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815962453613-4039288165772049', 4039288165772049, 682815962453613, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858707408402, 'Alfabético', 'es', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858707408402-4039328989831700', 4039328989831700, 682858707408402, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-4039256322954053', 4039256322954053, 682828789630925, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858267578336, 'Expresiones', 'es', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858267578336-4039294118562578', 4039294118562578, 682858267578336, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-4039202100757950', 4039202100757950, 682854338769382, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-4039226239864187', 4039226239864187, 682931450456078, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824803330268, 'Mapeado', 'es', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824803330268-4039236848299860', 4039236848299860, 682824803330268, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682884245166836, 'No se encontraron expresiones', 'es', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682884245166836-4039240488727553', 4039240488727553, 682884245166836, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-4039247603774554', 4039247603774554, 682850921034842, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-4039223809446541', 4039223809446541, 682820215961472, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682886289173715, 'Limpiar selección', 'es', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682886289173715-4039193792488426', 4039193792488426, 682886289173715, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873961011240, 'Crear nuevo idioma o variedad', 'es', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873961011240-4039299846909774', 4039299846909774, 682873961011240, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889306946654, 'No hay idiomas coincidentes', 'es', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889306946654-4039195104624261', 4039195104624261, 682889306946654, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799108127581, 'Buscar idiomas…', 'es', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799108127581-4039246945260645', 4039246945260645, 682799108127581, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682881132194991, 'Sugerido por tu navegador', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682881132194991-4039233498620681', 4039233498620681, 682881132194991, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854943128373, 'Ayuda a traducir LangMap', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854943128373-4039251841046235', 4039251841046235, 682854943128373, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889306946654, 'No hay idiomas coincidentes', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889306946654-4039195104624261', 4039195104624261, 682889306946654, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682816805029573, 'Idiomas recientes', 'es', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682816805029573-4039306795492531', 4039306795492531, 682816805029573, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858267578336, 'Expresiones', 'es', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858267578336-4039294118562578', 4039294118562578, 682858267578336, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-4039256322954053', 4039256322954053, 682828789630925, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682897399365859, 'No se pudieron cargar los idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682897399365859-4039196867547046', 4039196867547046, 682897399365859, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682917137608984, 'No se encontraron idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682917137608984-4039305123930385', 4039305123930385, 682917137608984, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799108127581, 'Buscar idiomas…', 'es', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799108127581-4039246945260645', 4039246945260645, 682799108127581, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682866354728204, 'A–Z', 'es', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682866354728204-4039263037467916', 4039263037467916, 682866354728204, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682864643608963, 'Cantidad', 'es', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682864643608963-4039284364068927', 4039284364068927, 682864643608963, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853329049107, 'Explorar expresiones y relaciones entre todos los idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853329049107-4039317622660080', 4039317622660080, 682853329049107, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-4039256322954053', 4039256322954053, 682828789630925, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682912173538717, 'Ancla', 'es', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682912173538717-4039242362911495', 4039242362911495, 682912173538717, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682872087619218, 'Volver a la relación', 'es', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682872087619218-4039274630245077', 4039274630245077, 682872087619218, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682867790418795, '{count} idiomas', 'es', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682867790418795-4039285488213874', 4039285488213874, 682867790418795, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-4039226239864187', 4039226239864187, 682931450456078, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870297095054, 'Miembros de la relación', 'es', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870297095054-4039240565339731', 4039240565339731, 682870297095054, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827769770520, 'No hay datos de distribución geográfica para este concepto', 'es', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827769770520-4039279250603930', 4039279250603930, 682827769770520, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682920716217478, '{count} regiones', 'es', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682920716217478-4039302107835931', 4039302107835931, 682920716217478, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892970271580, 'Distribución del concepto', 'es', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892970271580-4039208466994401', 4039208466994401, 682892970271580, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682842464784433, 'Añadir y crear relación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682842464784433-4039259535351101', 4039259535351101, 682842464784433, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682896175839391, 'Añadir expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682896175839391-4039323156297807', 4039323156297807, 682896175839391, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682843224142211, 'No se pudo añadir la expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682843224142211-4039198581489142', 4039198581489142, 682843224142211, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805183102062, 'Añadiendo…', 'es', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805183102062-4039218340751327', 4039218340751327, 682805183102062, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873592117071, 'Autoridad', 'es', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873592117071-4039318696248928', 4039318696248928, 682873592117071, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873975241213, 'Ruta de navegación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873975241213-4039291257989597', 4039291257989597, 682873975241213, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682799712267891, 'Cerrar adición rápida', 'es', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682799712267891-4039267828069642', 4039267828069642, 682799712267891, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682857813529004, 'Contribuir relación', 'es', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682857813529004-4039295569136473', 4039295569136473, 682857813529004, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682853510439182, 'relaciones directas', 'es', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682853510439182-4039246116479366', 4039246116479366, 682853510439182, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815386380562, 'Introduce expresión y código de idioma', 'es', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815386380562-4039246255388206', 4039246255388206, 682815386380562, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831404901271, 'Expresión', 'es', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831404901271-4039318048221959', 4039318048221959, 682831404901271, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682899105867642, 'Introduce una expresión…', 'es', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682899105867642-4039242456703266', 4039242456703266, 682899105867642, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858844350788, 'Grafo', 'es', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858844350788-4039261403730767', 4039261403730767, 682858844350788, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824951258194, 'Inicio', 'es', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824951258194-4039277332090535', 4039277332090535, 682824951258194, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682830496309961, 'saltos', 'es', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682830496309961-4039277202124053', 4039277202124053, 682830496309961, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682843895611736, 'indirecta', 'es', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682843895611736-4039318157522164', 4039318157522164, 682843895611736, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682827335594089, 'Código de idioma', 'es', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682827335594089-4039210176324565', 4039210176324565, 682827335594089, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798659849548, 'ej. en / zh-Hant', 'es', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798659849548-4039209337204607', 4039209337204607, 682798659849548, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682901415595687, 'Lista', 'es', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682901415595687-4039282174712441', 4039282174712441, 682901415595687, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682931450456078, 'No se pudo cargar', 'es', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682931450456078-4039226239864187', 4039226239864187, 682931450456078, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805074331733, 'Conjunto de relaciones', 'es', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805074331733-4039300809727185', 4039300809727185, 682805074331733, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682846121113471, 'Aún no hay relaciones', 'es', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682846121113471-4039325677769541', 4039325677769541, 682846121113471, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682885264102196, 'Opcional', 'es', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682885264102196-4039276071486298', 4039276071486298, 682885264102196, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812213013071, 'Añadir expresión rápidamente', 'es', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812213013071-4039324958036767', 4039324958036767, 682812213013071, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887862607436, 'Añade una expresión y relaciónala directamente con la expresión actual.', 'es', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887862607436-4039212842396077', 4039212842396077, 682887862607436, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682890354277950, 'Región', 'es', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682890354277950-4039258261318005', 4039258261318005, 682890354277950, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925132503903, 'Usuario', 'es', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925132503903-4039324440473230', 4039324440473230, 682925132503903, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902911665001, 'Ver este concepto en el mapa', 'es', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902911665001-4039311455815203', 4039311455815203, 682902911665001, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682911615961836, 'Cerrar menú', 'es', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682911615961836-4039297982961690', 4039297982961690, 682911615961836, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798765517243, 'Contribuir', 'es', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798765517243-4039312030295503', 4039312030295503, 682798765517243, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682921146202531, 'Manuales', 'es', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682921146202531-4039234820809009', 4039234820809009, 682921146202531, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682824951258194, 'Inicio', 'es', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682824951258194-4039277332090535', 4039277332090535, 682824951258194, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682828789630925, 'Idiomas', 'es', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682828789630925-4039256322954053', 4039256322954053, 682828789630925, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682868240392030, 'Menú', 'es', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682868240392030-4039223542474758', 4039223542474758, 682868240392030, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682918219546097, 'Abrir menú', 'es', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682918219546097-4039278126309563', 4039278126309563, 682918219546097, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822282195727, 'Buscar expresiones', 'es', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822282195727-4039289790753346', 4039289790753346, 682822282195727, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682892872018745, 'Iniciar sesión', 'es', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682892872018745-4039274956726587', 4039274956726587, 682892872018745, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682812225867769, 'Cerrar sesión', 'es', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682812225867769-4039277593503154', 4039277593503154, 682812225867769, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873350178443, 'Enviar búsqueda', 'es', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873350178443-4039323364353816', 4039323364353816, 682873350178443, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682895671786413, 'Cambiar idioma de la interfaz', 'es', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682895671786413-4039195322568967', 4039195322568967, 682895671786413, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682858707408402, 'Alfabético', 'es', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682858707408402-4039328989831700', 4039328989831700, 682858707408402, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682913899921960, 'Consejo: la búsqueda actual coincide con el texto de la expresión. La búsqueda semántica llegará más adelante.', 'es', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682913899921960-4039199272982370', 4039199272982370, 682913899921960, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682893587666340, 'Error al buscar', 'es', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682893587666340-4039218663313831', 4039218663313831, 682893587666340, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854338769382, 'Más reciente', 'es', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854338769382-4039202100757950', 4039202100757950, 682854338769382, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900973909582, 'Sin resultados', 'es', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900973909582-4039217192958680', 4039217192958680, 682900973909582, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820215961472, 'Buscar expresiones…', 'es', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820215961472-4039223809446541', 4039223809446541, 682820215961472, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682850921034842, 'Popular', 'es', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682850921034842-4039247603774554', 4039247603774554, 682850921034842, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682900848121381, '{count} resultado | {count} resultados', 'es', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682900848121381-4039304070680160', 4039304070680160, 682900848121381, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682873763431196, 'Ordenar', 'es', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682873763431196-4039290847632508', 4039290847632508, 682873763431196, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822282195727, 'Buscar expresiones', 'es', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822282195727-4039289790753346', 4039289790753346, 682822282195727, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682854818986642, 'Añadir un idioma para traducir', 'es', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682854818986642-4039262743786868', 4039262743786868, 682854818986642, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682915187627195, 'Enviar {count} traducciones', 'es', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682915187627195-4039232809480299', 4039232809480299, 682915187627195, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682851258589248, 'Traducción actual', 'es', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682851258589248-4039272108076077', 4039272108076077, 682851258589248, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682838786706383, 'Elige un idioma registrado', 'es', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682838786706383-4039307820065458', 4039307820065458, 682838786706383, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888380089522, 'Cobertura de traducción', 'es', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888380089522-4039302750746982', 4039302750746982, 682888380089522, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682925240585946, '{count} mostrados', 'es', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682925240585946-4039330567083979', 4039330567083979, 682925240585946, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831581261239, 'LOCALIZACIÓN COMUNITARIA', 'es', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831581261239-4039263180329406', 4039263180329406, 682831581261239, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682924372803922, 'Introduce la traducción…', 'es', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682924372803922-4039280361786422', 4039280361786422, 682924372803922, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682887335369782, 'No se pudo cargar el área de trabajo de traducción', 'es', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682887335369782-4039210189975752', 4039210189975752, 682887335369782, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682859154714796, 'Cargando…', 'es', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682859154714796-4039198023470406', 4039198023470406, 682859154714796, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682805787749021, 'Idioma de destino', 'es', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682805787749021-4039286503270980', 4039286503270980, 682805787749021, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902014794540, 'No se pudo cargar la lista de idiomas', 'es', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902014794540-4039255464963972', 4039255464963972, 682902014794540, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682834234688838, 'Inicia sesión para enviar traducciones; los candidatos se seleccionan por puntuación de relación y se usa el texto de respaldo cuando no hay un candidato positivo.', 'es', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682834234688838-4039285344096668', 4039285344096668, 682834234688838, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682888628710154, 'No se encontraron textos coincidentes.', 'es', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682888628710154-4039194547587951', 4039194547587951, 682888628710154, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682906610341361, 'Vista previa', 'es', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682906610341361-4039259327128845', 4039259327128845, 682906610341361, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682863126124520, 'Idioma de referencia', 'es', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682863126124520-4039299601179530', 4039299601179530, 682863126124520, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682889113673816, 'Buscar clave o texto original…', 'es', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682889113673816-4039252284218610', 4039252284218610, 682889113673816, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682865675337327, 'Elegir idioma de traducción', 'es', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682865675337327-4039327112090503', 4039327112090503, 682865675337327, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682870996044253, 'Original en inglés', 'es', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682870996044253-4039304389733603', 4039304389733603, 682870996044253, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682822813444135, 'Comenzar', 'es', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682822813444135-4039325838792223', 4039325838792223, 682822813444135, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682798159782041, 'Error al enviar', 'es', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682798159782041-4039220418642934', 4039220418642934, 682798159782041, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682902106631267, 'Enviar relación', 'es', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682902106631267-4039227663321003', 4039227663321003, 682902106631267, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682831990627040, 'Enviado', 'es', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682831990627040-4039196288099856', 4039196288099856, 682831990627040, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682929278454242, 'Ayuda a que el texto de la interfaz de LangMap sea natural y útil.', 'es', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682929278454242-4039258395876255', 4039258395876255, 682929278454242, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682815193255977, 'Área de trabajo de traducción', 'es', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682815193255977-4039292410329094', 4039292410329094, 682815193255977, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682825696738240, 'Traducir {key}', 'es', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682825696738240-4039226075472990', 4039226075472990, 682825696738240, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682847168128679, 'traducido', 'es', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682847168128679-4039206423275507', 4039206423275507, 682847168128679, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (682820936960095, 'Traducción', 'es', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('682820936960095-4039241150478337', 4039241150478337, 682820936960095, 0, 'ui_i18n');

-- Locale ja
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639165672169, 'メールアドレス', 'ja', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-5667639165672169', 4039278566303563, 5667639165672169, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643600055019, 'すでにアカウントをお持ちですか？', 'ja', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-5667643600055019', 4039276962119789, 5667643600055019, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667637138127513, 'ログイン', 'ja', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-5667637138127513', 4039274956726587, 5667637138127513, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667681854911873, 'アカウントをお持ちでないですか？', 'ja', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-5667681854911873', 4039210512038996, 5667681854911873, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667687394613636, '操作に失敗しました', 'ja', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-5667687394613636', 4039224592934601, 5667687394613636, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658495762766, 'パスワード', 'ja', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-5667658495762766', 4039283475919761, 5667658495762766, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667576652918371, '処理中…', 'ja', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-5667576652918371', 4039290683252068, 5667576652918371, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667662270756379, 'アカウント作成', 'ja', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-5667662270756379', 4039254012036431, 5667662270756379, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667691864346811, 'ユーザー名', 'ja', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-5667691864346811', 4039318948959047, 5667691864346811, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595026247812, 'キャンセル', 'ja', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-5667595026247812', 4039291340498970, 5667595026247812, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679919267773, '閉じる', 'ja', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-5667679919267773', 4039247982696992, 5667679919267773, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5667688633057075', 4039220584763101, 5667688633057075, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5667688633057075', 4039256322954053, 5667688633057075, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680432488224, '読み込み中…', 'ja', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-5667680432488224', 4039198023470406, 5667680432488224, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667636864923714, '検索', 'ja', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-5667636864923714', 4039307974483127, 5667636864923714, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635910157711, '送信', 'ja', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-5667635910157711', 4039245021981976, 5667635910157711, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705077379244, '実際のサイズ 100%', 'ja', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-5667705077379244', 4039203196919686, 5667705077379244, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667627138896988, '匿名', 'ja', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-5667627138896988', 4039253518652932, 5667627138896988, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667704125133743, '{count} 個の子ノード；クリックして折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-5667704125133743', 4039322475101146, 5667704125133743, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695215960406, '各エッジは独立した直接関係で、賛成・反対の投票が可能です。低スコアの関係は自動的に折りたたまれます。', 'ja', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-5667695215960406', 4039318570928695, 5667695215960406, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665893607938, '作成する関係グラフ', 'ja', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-5667665893607938', 4039280324996322, 5667665893607938, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622146578295, '情報パネルを閉じる', 'ja', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-5667622146578295', 4039213218065468, 5667622146578295, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647414230792, '折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-5667647414230792', 4039314752746797, 5667647414230792, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595467188476, '子ノードを折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-5667595467188476', 4039311612904008, 5667595467188476, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602835528759, '最初の階層に折りたたむ', 'ja', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-5667602835528759', 4039252699292725, 5667602835528759, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660629563939, '{count} 日前', 'ja', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-5667660629563939', 4039305722497088, 5667660629563939, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599363342566, '深さ {depth}', 'ja', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-5667599363342566', 4039308224575343, 5667599363342566, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621450979350, '直接関係のある表現', 'ja', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-5667621450979350', 4039211316535202, 5667621450979350, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667641664082987, '反対', 'ja', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-5667641664082987', 4039281764373654, 5667641664082987, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612355688340, '{count} エッジ', 'ja', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-5667612355688340', 4039196655494558, 5667612355688340, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626905715116, 'データはまだありません', 'ja', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-5667626905715116', 4039290061486601, 5667626905715116, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643830645123, '全画面を終了', 'ja', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-5667643830645123', 4039285164681796, 5667643830645123, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587298048364, '展開', 'ja', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-5667587298048364', 4039246642706739, 5667587298048364, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667588107604965, 'すべて展開', 'ja', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-5667588107604965', 4039323395460079, 5667588107604965, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667672684673798, '子ノードを展開', 'ja', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-5667672684673798', 4039227367141393, 5667672684673798, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5667645040737135', 4039318048221959, 5667645040737135, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690226659892, '言語をフィルター…', 'ja', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-5667690226659892', 4039264822897467, 5667690226659892, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602854178051, '全画面', 'ja', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-5667602854178051', 4039273948571546, 5667602854178051, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683111697606, '表現関係グラフ', 'ja', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-5667683111697606', 4039229813257256, 5667683111697606, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600207637940, 'グラフを読み込み中…', 'ja', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-5667600207637940', 4039220553457070, 5667600207637940, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679560174028, 'グラフモード', 'ja', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-5667679560174028', 4039307692947617, 5667679560174028, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638561368417, '{nodes} 個のマッピングノード · {edges} 件の関係', 'ja', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-5667638561368417', 4039220204112184, 5667638561368417, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593987798820, 'グラフツールバー', 'ja', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-5667593987798820', 4039247632198973, 5667593987798820, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623800548345, '関係階層リスト', 'ja', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-5667623800548345', 4039262167197365, 5667623800548345, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582865883104, 'ホップ数', 'ja', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-5667582865883104', 4039218745350539, 5667582865883104, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667604953481249, '{count} 時間前', 'ja', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-5667604953481249', 4039261676051383, 5667604953481249, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591711089547, 'たった今', 'ja', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-5667591711089547', 4039295793832731, 5667591711089547, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610322011774, '言語を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-5667610322011774', 4039196867547046, 5667610322011774, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667577656080399, 'リストモード', 'ja', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-5667577656080399', 4039267846517304, 5667577656080399, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591167941758, 'さらに読み込む', 'ja', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-5667591167941758', 4039257935440261, 5667591167941758, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638287645590, '関連表現を読み込み中', 'ja', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-5667638287645590', 4039208559662390, 5667638287645590, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667577551126800, '関係', 'ja', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-5667577551126800', 4039299531874366, 5667577551126800, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677073700359, '関係スコア', 'ja', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-5667677073700359', 4039291250524588, 5667677073700359, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590042843220, '{count} 分前', 'ja', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-5667590042843220', 4039319528355130, 5667590042843220, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667578694717845, 'その他の操作', 'ja', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-5667578694717845', 4039216903072408, 5667578694717845, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596028796915, '完全なグラフにはさらに {count} 件の関係があります', 'ja', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-5667596028796915', 4039267933793525, 5667596028796915, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639941268368, '直接関係はまだありません', 'ja', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-5667639941268368', 4039206484078170, 5667639941268368, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694062377766, '表現が見つかりません', 'ja', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-5667694062377766', 4039240488727553, 5667694062377766, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664456116257, '{count} ノード', 'ja', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-5667664456116257', 4039205391794884, 5667664456116257, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667704813735011, 'ノード情報', 'ja', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-5667704813735011', 4039321854954979, 5667704813735011, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587189796271, 'その他の関係', 'ja', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-5667587189796271', 4039301412743754, 5667587189796271, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667633354751803, '関連表現', 'ja', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-5667633354751803', 4039285912508809, 5667633354751803, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694758653266, '{count} 件の関係', 'ja', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-5667694758653266', 4039195207546455, 5667694758653266, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667585691115513, '{code} を削除', 'ja', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-5667585691115513', 4039257785545173, 5667585691115513, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635890823393, 'レイアウトをリセット', 'ja', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-5667635890823393', 4039213227329958, 5667635890823393, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663237814889, 'ルートノード', 'ja', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-5667663237814889', 4039280733662867, 5667663237814889, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667636864923714, '検索', 'ja', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-5667636864923714', 4039307974483127, 5667636864923714, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5667602001034739', 4039223809446541, 5667602001034739, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667676834316056, '検索中…', 'ja', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-5667676834316056', 4039241606316828, 5667676834316056, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623628533232, 'グラフ内のノードを選択して詳細を表示', 'ja', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-5667623628533232', 4039258954601880, 5667623628533232, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660251571215, '元の経路', 'ja', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-5667660251571215', 4039267388033524, 5667660251571215, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658371786207, '賛成', 'ja', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-5667658371786207', 4039305875761888, 5667658371786207, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599780785659, '表現の詳細を表示', 'ja', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-5667599780785659', 4039285357620964, 5667599780785659, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706980891720, '投票に失敗しました。元に戻しました', 'ja', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-5667706980891720', 4039310388216878, 5667706980891720, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660362713436, '拡大', 'ja', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-5667660362713436', 4039307035795639, 5667660362713436, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667620147272796, '縮小', 'ja', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-5667620147272796', 4039306926563555, 5667620147272796, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667614041538610, '+ 表現を追加', 'ja', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-5667614041538610', 4039234711174892, 5667614041538610, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648348787071, '完全グラフ', 'ja', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-5667648348787071', 4039210891494791, 5667648348787071, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587121146465, '削除', 'ja', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-5667587121146465', 4039233937430393, 5667587121146465, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667584367383178, '{count} 件の直接関係', 'ja', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-5667584367383178', 4039258582305025, 5667584367383178, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5667645040737135', 4039318048221959, 5667645040737135, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664773091494, '{count} 件の表現', 'ja', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-5667664773091494', 4039208226237843, 5667664773091494, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629262680456, '表現を入力…', 'ja', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-5667629262680456', 4039264797643778, 5667629262680456, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5667688633057075', 4039220584763101, 5667688633057075, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619715122750, '同じ意味を持つ表現のグループを送信します。システムは各ペア間に直接関係を作成します。既存の表現は重複なく自動的にリンクされます。', 'ja', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-5667619715122750', 4039228008118707, 5667619715122750, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663103663489, '言語と表現を入力した行が少なくとも2行必要です', 'ja', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-5667663103663489', 4039286212175439, 5667663103663489, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635910157711, '送信', 'ja', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-5667635910157711', 4039245021981976, 5667635910157711, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589757005077, '送信に失敗しました', 'ja', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-5667589757005077', 4039220418642934, 5667589757005077, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667599360416322, '送信中…', 'ja', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-5667599360416322', 4039286291917398, 5667599360416322, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600711195237, 'タグ', 'ja', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-5667600711195237', 4039312686530045, 5667600711195237, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645326250629, '一括投稿', 'ja', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-5667645326250629', 4039256753970050, 5667645326250629, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583774054725, 'ホームに戻る', 'ja', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-5667583774054725', 4039244552136331, 5667583774054725, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5667579068168092', 4039226239864187, 5667579068168092, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677441704212, 'ページが見つかりません', 'ja', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-5667677441704212', 4039247795890512, 5667677441704212, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626689511354, 'すべて', 'ja', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-5667626689511354', 4039202333969475, 5667626689511354, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667626918417847, '関係を投稿する →', 'ja', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-5667626918417847', 4039241704787781, 5667626918417847, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5667600188693356', 4039247603774554, 5667600188693356, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667698229312944, '関係 + 新しい表現', 'ja', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-5667698229312944', 4039260809744465, 5667698229312944, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667576212878837, '必要なものが見つかりませんか？', 'ja', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-5667576212878837', 4039254190870260, 5667576212878837, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631844621370, '新しい貢献', 'ja', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-5667631844621370', 4039302900266643, 5667631844621370, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5667589459199969', 4039202100757950, 5667589459199969, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667581213623373, '人気の関係', 'ja', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-5667581213623373', 4039245957647571, 5667581213623373, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667607307273749, 'スコア順 · 今週', 'ja', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-5667607307273749', 4039291578874799, 5667607307273749, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667587526185973, '意味グラフの最新情報 — 人気の関係と新しい貢献。', 'ja', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-5667587526185973', 4039275101235147, 5667587526185973, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664190240873, 'アクティビティ', 'ja', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-5667664190240873', 4039218305844177, 5667664190240873, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657431263471, '表現を追加', 'ja', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-5667657431263471', 4039323156297807, 5667657431263471, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589945556192, 'セクションを追加', 'ja', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-5667589945556192', 4039302981121903, 5667589945556192, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647303323444, 'ハンドブック一覧', 'ja', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-5667647303323444', 4039275162095516, 5667647303323444, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667707400731669, '第 {number} 章', 'ja', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-5667707400731669', 4039264579862218, 5667707400731669, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667632234504261, '表現情報を閉じる', 'ja', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-5667632234504261', 4039238473169231, 5667632234504261, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647414230792, '折りたたむ', 'ja', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-5667647414230792', 4039314752746797, 5667647414230792, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645713485755, 'セクションを削除', 'ja', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-5667645713485755', 4039212000754015, 5667645713485755, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667584200423865, 'ハンドブックを編集', 'ja', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-5667584200423865', 4039244157921703, 5667584200423865, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667608287100218, '表現情報', 'ja', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-5667608287100218', 4039248386595592, 5667608287100218, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697393233440, '表現の言語、地域、ソースがここに表示されます。', 'ja', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-5667697393233440', 4039258685413951, 5667697393233440, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590862209198, 'このハンドブックは役に立ちましたか？', 'ja', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-5667590862209198', 4039208667474251, 5667590862209198, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590132862834, '表現を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-5667590132862834', 4039291593337392, 5667590132862834, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5667579068168092', 4039226239864187, 5667579068168092, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5667688633057075', 4039220584763101, 5667688633057075, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667592930808359, '下に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-5667592930808359', 4039305476617896, 5667592930808359, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667686037406860, 'セクションを下に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-5667686037406860', 4039264378315169, 5667686037406860, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667628219000442, 'セクションを上に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-5667628219000442', 4039263980419517, 5667628219000442, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619659722302, '上に移動', 'ja', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-5667619659722302', 4039325459519266, 5667619659722302, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688641655419, '非公開', 'ja', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-5667688641655419', 4039271025507837, 5667688641655419, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667597163475652, '公開', 'ja', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-5667597163475652', 4039267993342608, 5667597163475652, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667597163475652, '公開', 'ja', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-5667597163475652', 4039241948973877, 5667597163475652, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5667695151549854', 4039258261318005, 5667695151549854, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583785466950, '関連表現を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-5667583785466950', 4039281597988534, 5667583785466950, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667659096217242, '{text} を削除', 'ja', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-5667659096217242', 4039238014424846, 5667659096217242, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572235872905, '下書きを保存', 'ja', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-5667572235872905', 4039263998176559, 5667572235872905, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688912070401, '保存中…', 'ja', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-5667688912070401', 4039270028440745, 5667688912070401, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667616146054046, 'セクションタイトル', 'ja', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-5667616146054046', 4039225159134159, 5667616146054046, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667672049644118, '表現を選択', 'ja', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-5667672049644118', 4039264953167344, 5667672049644118, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667594135305634, 'ソース', 'ja', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-5667594135305634', 4039223387675999, 5667594135305634, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621146984063, 'AI', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-5667621146984063', 4039244426247807, 5667621146984063, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667642644092467, '権威', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-5667642644092467', 4039318696248928, 5667642644092467, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593348696707, 'ユーザー', 'ja', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-5667593348696707', 4039324440473230, 5667593348696707, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667682192777813, 'ハンドブックのタイトル', 'ja', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-5667682192777813', 4039208338888027, 5667682192777813, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579323900406, '目次', 'ja', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-5667579323900406', 4039204809556520, 5667579323900406, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667692312739958, '完全な関係グラフを表示', 'ja', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-5667692312739958', 4039218586424477, 5667692312739958, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612661686889, '公開設定', 'ja', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-5667612661686889', 4039319622118803, 5667612661686889, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677295209796, '新しいハンドブック', 'ja', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-5667677295209796', 4039273991762691, 5667677295209796, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660139797948, 'ハンドブックを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-5667660139797948', 4039205037236353, 5667660139797948, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5667589459199969', 4039202100757950, 5667589459199969, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667574177099599, 'ハンドブックが見つかりません', 'ja', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-5667574177099599', 4039297167533555, 5667574177099599, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5667600188693356', 4039247603774554, 5667600188693356, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705480166510, 'ハンドブックを検索…', 'ja', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-5667705480166510', 4039321109759665, 5667705480166510, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647811879499, 'セクション', 'ja', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-5667647811879499', 4039271506815244, 5667647811879499, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705114884036, 'ハンドブック', 'ja', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-5667705114884036', 4039234820809009, 5667705114884036, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677944766523, '戻る', 'ja', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-5667677944766523', 4039313675995469, 5667677944766523, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595026247812, 'キャンセル', 'ja', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-5667595026247812', 4039291340498970, 5667595026247812, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667679919267773, '閉じる', 'ja', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-5667679919267773', 4039247982696992, 5667679919267773, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612444597544, '言語を作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-5667612444597544', 4039261792696368, 5667612444597544, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690506718434, '言語の作成に失敗しました', 'ja', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-5667690506718434', 4039298612922394, 5667690506718434, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667693422064228, '作成中…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-5667693422064228', 4039232938642916, 5667693422064228, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591545427858, '説明を入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-5667591545427858', 4039276426027002, 5667591545427858, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667662591605031, 'Glottolog の一致を選択するか、「一致なし」を選択', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-5667662591605031', 4039271782430821, 5667662591605031, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667656899394892, '言語名を入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-5667656899394892', 4039210698010944, 5667656899394892, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631357468679, 'コミュニティのみ作成の理由を選択してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-5667631357468679', 4039216473655312, 5667631357468679, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667571702640112, '続行するには言語サブタグを入力してください', 'ja', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-5667571702640112', 4039316213234006, 5667571702640112, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648277038737, '{count} 件の候補が見つかりました', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-5667648277038737', 4039246098211492, 5667648277038737, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694367528648, '一致を選択するか、適切な項目がないことを指定', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-5667694367528648', 4039323364172038, 5667694367528648, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667592190268120, 'この候補に一致', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-5667592190268120', 4039325854259152, 5667592190268120, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610582020388, '方言', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-5667610582020388', 4039249282401723, 5667610582020388, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-5667688633057075', 4039243488926094, 5667688633057075, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667690992352106, 'Glottolog に適切な項目がありません', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-5667690992352106', 4039197295194771, 5667690992352106, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699937109125, 'Glottolog を検索…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-5667699937109125', 4039262313884420, 5667699937109125, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667684090940545, '説明', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-5667684090940545', 4039226938266962, 5667684090940545, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667575867259256, 'この言語または変種を説明…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-5667575867259256', 4039218699342636, 5667575867259256, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667648595681284, '名前', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-5667648595681284', 4039203173843539, 5667648595681284, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667621908159537, '英語名', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-5667621908159537', 4039325286054403, 5667621908159537, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683865193530, 'この言語が Glottolog にない理由は？', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-5667683865193530', 4039255034745478, 5667683865193530, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610675283792, 'コミュニティ固有の用法', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-5667610675283792', 4039318758556549, 5667610675283792, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667625067957717, '新しい変種', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-5667625067957717', 4039201401042810, 5667625067957717, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643589559118, 'Glottolog に未収録', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-5667643589559118', 4039317085985011, 5667643589559118, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667591971252444, 'その他', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-5667591971252444', 4039197354913502, 5667591971252444, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667603879877440, '理由を選択…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-5667603879877440', 4039198381390937, 5667603879877440, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583610699684, '次へ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-5667583610699684', 4039235695377645, 5667583610699684, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706515947714, '正規コード', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-5667706515947714', 4039275920750884, 5667706515947714, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667700503765697, 'この言語はすでに存在します', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-5667700503765697', 4039252684783738, 5667700503765697, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667571445869872, '既存の言語を使用', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-5667571445869872', 4039201624757562, 5667571445869872, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667612444597544, '言語を作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-5667612444597544', 4039261792696368, 5667612444597544, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667604640131501, '警告', 'ja', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-5667604640131501', 4039266319466062, 5667604640131501, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667605779127548, '暫定タグ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-5667605779127548', 4039258938883345, 5667605779127548, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683439617817, 'Glottolog マッチ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-5667683439617817', 4039216090040527, 5667683439617817, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572374094601, 'メタデータ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-5667572374094601', 4039278502317771, 5667572374094601, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667595107642193, 'プレビューと作成', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-5667595107642193', 4039292079507095, 5667595107642193, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667620806371744, '言語タグ', 'ja', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-5667620806371744', 4039271969593143, 5667620806371744, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5667688633057075', 4039220584763101, 5667688633057075, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5667695151549854', 4039258261318005, 5667695151549854, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668629010554, '文字', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-5667668629010554', 4039265998307294, 5667668629010554, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667630904547622, 'サブタグを検索…', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-5667630904547622', 4039305028592078, 5667630904547622, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680592269473, '変種', 'ja', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-5667680592269473', 4039213349000445, 5667680592269473, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639521899342, '1 件の変種を削除', 'ja', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-5667639521899342', 4039300854350766, 5667639521899342, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629146176193, '{count} 件の変種を削除', 'ja', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-5667629146176193', 4039288165772049, 5667629146176193, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635203282018, 'アルファベット順', 'ja', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-5667635203282018', 4039328989831700, 5667635203282018, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5667688633057075', 4039256322954053, 5667688633057075, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-5667645040737135', 4039294118562578, 5667645040737135, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5667589459199969', 4039202100757950, 5667589459199969, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5667579068168092', 4039226239864187, 5667579068168092, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667664079615083, 'マッピング済み', 'ja', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-5667664079615083', 4039236848299860, 5667664079615083, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694062377766, '表現が見つかりません', 'ja', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-5667694062377766', 4039240488727553, 5667694062377766, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5667600188693356', 4039247603774554, 5667600188693356, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5667602001034739', 4039223809446541, 5667602001034739, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697207154478, '選択をクリア', 'ja', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-5667697207154478', 4039193792488426, 5667697207154478, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667651110958074, '新しい言語または変種を作成', 'ja', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-5667651110958074', 4039299846909774, 5667651110958074, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638669500572, '一致する言語がありません', 'ja', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-5667638669500572', 4039195104624261, 5667638669500572, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706191235415, '言語を検索…', 'ja', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-5667706191235415', 4039246945260645, 5667706191235415, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667580023891022, 'ブラウザの推奨', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-5667580023891022', 4039233498620681, 5667580023891022, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665763627933, 'LangMap の翻訳に協力する', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-5667665763627933', 4039251841046235, 5667665763627933, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638669500572, '一致する言語がありません', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-5667638669500572', 4039195104624261, 5667638669500572, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667652711662600, '最近使用した言語', 'ja', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-5667652711662600', 4039306795492531, 5667652711662600, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-5667645040737135', 4039294118562578, 5667645040737135, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5667688633057075', 4039256322954053, 5667688633057075, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667610322011774, '言語を読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-5667610322011774', 4039196867547046, 5667610322011774, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667682750135680, '言語が見つかりません', 'ja', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-5667682750135680', 4039305123930385, 5667682750135680, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667706191235415, '言語を検索…', 'ja', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-5667706191235415', 4039246945260645, 5667706191235415, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639758204172, 'A–Z', 'ja', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-5667639758204172', 4039263037467916, 5667639758204172, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667643967046884, '件数', 'ja', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-5667643967046884', 4039284364068927, 5667643967046884, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619264481605, 'すべての言語の表現と関係を探索', 'ja', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-5667619264481605', 4039317622660080, 5667619264481605, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5667688633057075', 4039256322954053, 5667688633057075, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665665358673, 'アンカー', 'ja', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-5667665665358673', 4039242362911495, 5667665665358673, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669126727841, '関係に戻る', 'ja', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-5667669126727841', 4039274630245077, 5667669126727841, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694610067066, '{count} 言語', 'ja', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-5667694610067066', 4039285488213874, 5667694610067066, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5667579068168092', 4039226239864187, 5667579068168092, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667684740105522, '関係メンバー', 'ja', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-5667684740105522', 4039240565339731, 5667684740105522, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667583805649822, 'この概念の地理的分布データはありません', 'ja', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-5667583805649822', 4039279250603930, 5667583805649822, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667647625900147, '{count} 地域', 'ja', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-5667647625900147', 4039302107835931, 5667647625900147, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645152367454, '概念の分布', 'ja', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-5667645152367454', 4039208466994401, 5667645152367454, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657018994234, '追加して関係を作成', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-5667657018994234', 4039259535351101, 5667657018994234, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657431263471, '表現を追加', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-5667657431263471', 4039323156297807, 5667657431263471, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667689930205488, '表現を追加できませんでした', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-5667689930205488', 4039198581489142, 5667689930205488, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667590354595841, '追加中…', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-5667590354595841', 4039218340751327, 5667590354595841, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667642644092467, '権威', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-5667642644092467', 4039318696248928, 5667642644092467, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667607243147769, 'パンくず', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-5667607243147769', 4039291257989597, 5667607243147769, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667660409065919, 'クイック追加を閉じる', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-5667660409065919', 4039267828069642, 5667660409065919, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657461770191, '関係を投稿', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-5667657461770191', 4039295569136473, 5667657461770191, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667658640639859, '直接関係', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-5667658640639859', 4039246116479366, 5667658640639859, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629285692593, '表現と言語コードを入力してください', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-5667629285692593', 4039246255388206, 5667629285692593, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667645040737135, '表現', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5667645040737135', 4039318048221959, 5667645040737135, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667629262680456, '表現を入力…', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-5667629262680456', 4039242456703266, 5667629262680456, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667598153216873, 'グラフ', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-5667598153216873', 4039261403730767, 5667598153216873, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639456493742, 'ホーム', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-5667639456493742', 4039277332090535, 5667639456493742, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582865883104, 'ホップ数', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-5667582865883104', 4039277202124053, 5667582865883104, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667614219015040, '間接', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-5667614219015040', 4039318157522164, 5667614219015040, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667697302661086, '言語コード', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-5667697302661086', 4039210176324565, 5667697302661086, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667657482722815, '例：en / zh-Hant', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-5667657482722815', 4039209337204607, 5667657482722815, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667692412114179, 'リスト', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-5667692412114179', 4039282174712441, 5667692412114179, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667579068168092, '読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5667579068168092', 4039226239864187, 5667579068168092, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669647114617, '関係セット', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-5667669647114617', 4039300809727185, 5667669647114617, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699953258741, 'まだ関係がありません', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-5667699953258741', 4039325677769541, 5667699953258741, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667663308019802, '任意', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-5667663308019802', 4039276071486298, 5667663308019802, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667627843783666, '表現をすばやく追加', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-5667627843783666', 4039324958036767, 5667627843783666, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667699921826826, '表現を追加し、現在の表現に直接マップします。', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-5667699921826826', 4039212842396077, 5667699921826826, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667695151549854, '地域', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5667695151549854', 4039258261318005, 5667695151549854, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667593348696707, 'ユーザー', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-5667593348696707', 4039324440473230, 5667593348696707, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668313793424, 'この概念を地図で表示', 'ja', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-5667668313793424', 4039311455815203, 5667668313793424, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619578096162, 'メニューを閉じる', 'ja', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-5667619578096162', 4039297982961690, 5667619578096162, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572724542352, '貢献', 'ja', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-5667572724542352', 4039312030295503, 5667572724542352, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705114884036, 'ハンドブック', 'ja', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-5667705114884036', 4039234820809009, 5667705114884036, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667639456493742, 'ホーム', 'ja', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-5667639456493742', 4039277332090535, 5667639456493742, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667688633057075, '言語', 'ja', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5667688633057075', 4039256322954053, 5667688633057075, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667613981738673, 'メニュー', 'ja', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-5667613981738673', 4039223542474758, 5667613981738673, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667631886926617, 'メニューを開く', 'ja', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-5667631886926617', 4039278126309563, 5667631886926617, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667653472473278, '表現を検索', 'ja', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-5667653472473278', 4039289790753346, 5667653472473278, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667637138127513, 'ログイン', 'ja', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-5667637138127513', 4039274956726587, 5667637138127513, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667685914767722, 'ログアウト', 'ja', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-5667685914767722', 4039277593503154, 5667685914767722, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667683549604550, '検索を実行', 'ja', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-5667683549604550', 4039323364353816, 5667683549604550, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669084658122, 'インターフェース言語を切り替え', 'ja', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-5667669084658122', 4039195322568967, 5667669084658122, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667635203282018, 'アルファベット順', 'ja', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-5667635203282018', 4039328989831700, 5667635203282018, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694022710483, 'ヒント：現在の検索は表現テキストに一致します。意味検索は後日提供予定です。', 'ja', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-5667694022710483', 4039199272982370, 5667694022710483, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667705487484089, '検索に失敗しました', 'ja', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-5667705487484089', 4039218663313831, 5667705487484089, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589459199969, '最新', 'ja', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5667589459199969', 4039202100757950, 5667589459199969, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667677682108323, '結果が見つかりません', 'ja', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-5667677682108323', 4039217192958680, 5667677682108323, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667602001034739, '表現を検索…', 'ja', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5667602001034739', 4039223809446541, 5667602001034739, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667600188693356, '人気', 'ja', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5667600188693356', 4039247603774554, 5667600188693356, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667698386206722, '{count} 件の結果', 'ja', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-5667698386206722', 4039304070680160, 5667698386206722, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667570617145113, '並び替え', 'ja', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-5667570617145113', 4039290847632508, 5667570617145113, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667653472473278, '表現を検索', 'ja', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-5667653472473278', 4039289790753346, 5667653472473278, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667694457332178, '翻訳する言語を追加', 'ja', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-5667694457332178', 4039262743786868, 5667694457332178, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572450753410, '{count} 件の翻訳を送信', 'ja', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-5667572450753410', 4039232809480299, 5667572450753410, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667669168742844, '現在の翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-5667669168742844', 4039272108076077, 5667669168742844, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622430523750, '登録済みの言語を選択', 'ja', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-5667622430523750', 4039307820065458, 5667622430523750, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596433518312, '翻訳カバレッジ', 'ja', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-5667596433518312', 4039302750746982, 5667596433518312, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667582116133995, '{count} 件表示', 'ja', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-5667582116133995', 4039330567083979, 5667582116133995, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667622341490826, 'コミュニティ翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-5667622341490826', 4039263180329406, 5667622341490826, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667654375948093, '翻訳を入力…', 'ja', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-5667654375948093', 4039280361786422, 5667654375948093, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667596830065687, '翻訳ワークベンチを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-5667596830065687', 4039210189975752, 5667596830065687, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667680432488224, '読み込み中…', 'ja', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-5667680432488224', 4039198023470406, 5667680432488224, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667640575561994, '対象言語', 'ja', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-5667640575561994', 4039286503270980, 5667640575561994, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667696289522144, '言語リストを読み込めませんでした', 'ja', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-5667696289522144', 4039255464963972, 5667696289522144, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667619093799340, 'ログインして翻訳を送信。候補は関係スコアで選択され、適切な候補がない場合はフォールバックが使用されます。', 'ja', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-5667619093799340', 4039285344096668, 5667619093799340, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667608258291644, '一致するテキストが見つかりません。', 'ja', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-5667608258291644', 4039194547587951, 5667608258291644, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667638050451361, 'プレビュー', 'ja', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-5667638050451361', 4039259327128845, 5667638050451361, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667616238195236, '参照言語', 'ja', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-5667616238195236', 4039299601179530, 5667616238195236, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667640926848452, 'キーまたは原文を検索…', 'ja', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-5667640926848452', 4039252284218610, 5667640926848452, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667661382849748, '翻訳言語を選択', 'ja', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-5667661382849748', 4039327112090503, 5667661382849748, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667668513784419, '英語原文', 'ja', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-5667668513784419', 4039304389733603, 5667668513784419, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667665467367352, '開始', 'ja', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-5667665467367352', 4039325838792223, 5667665467367352, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589757005077, '送信に失敗しました', 'ja', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-5667589757005077', 4039220418642934, 5667589757005077, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667589821787306, '関係を送信', 'ja', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-5667589821787306', 4039227663321003, 5667589821787306, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667685993114428, '送信済み', 'ja', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-5667685993114428', 4039196288099856, 5667685993114428, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667572173092342, 'LangMap のインターフェース文言を自然で使いやすくするお手伝いをします。', 'ja', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-5667572173092342', 4039258395876255, 5667572173092342, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667649130183263, '翻訳ワークベンチ', 'ja', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-5667649130183263', 4039292410329094, 5667649130183263, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667623919646098, '{key} を翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-5667623919646098', 4039226075472990, 5667623919646098, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667601406170839, '翻訳済み', 'ja', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-5667601406170839', 4039206423275507, 5667601406170839, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5667601297578574, '翻訳', 'ja', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-5667601297578574', 4039241150478337, 5667601297578574, 0, 'ui_i18n');

-- Locale zh-Hans
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642115394617474, '邮箱', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-6642115394617474', 4039278566303563, 6642115394617474, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102074594911, '已有账号？', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-6642102074594911', 4039276962119789, 6642102074594911, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025328564659, '登录', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-6642025328564659', 4039274956726587, 6642025328564659, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642096269746521, '还没有账号？', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-6642096269746521', 4039210512038996, 6642096269746521, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113949694275, '操作失败', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-6642113949694275', 4039224592934601, 6642113949694275, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642014231965307, '密码', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-6642014231965307', 4039283475919761, 6642014231965307, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089509849650, '处理中…', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-6642089509849650', 4039290683252068, 6642089509849650, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078250363025, '创建账号', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-6642078250363025', 4039254012036431, 6642078250363025, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642114707359363, '用户名', 'zh-Hans', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-6642114707359363', 4039318948959047, 6642114707359363, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143445594122, '取消', 'zh-Hans', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-6642143445594122', 4039291340498970, 6642143445594122, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136428173818, '关闭', 'zh-Hans', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-6642136428173818', 4039247982696992, 6642136428173818, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-6642127179293910', 4039220584763101, 6642127179293910, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-6642127179293910', 4039256322954053, 6642127179293910, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131738404901, '加载中…', 'zh-Hans', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-6642131738404901', 4039198023470406, 6642131738404901, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051158517347, '搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-6642051158517347', 4039307974483127, 6642051158517347, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058290789573, '提交', 'zh-Hans', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-6642058290789573', 4039245021981976, 6642058290789573, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642093757102008, '实际尺寸 100%', 'zh-Hans', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-6642093757102008', 4039203196919686, 6642093757102008, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642069319013468, '匿名', 'zh-Hans', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-6642069319013468', 4039253518652932, 6642069319013468, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081156745026, '{count} 个子节点；点击收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-6642081156745026', 4039322475101146, 6642081156745026, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136322982617, '每条边皆为可投票的独立直接映射；低分映射自动收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-6642136322982617', 4039318570928695, 6642136322982617, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148139512311, '待建立的映射图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-6642148139512311', 4039280324996322, 6642148139512311, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642098157573679, '关闭信息面板', 'zh-Hans', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-6642098157573679', 4039213218065468, 6642098157573679, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026681083988, '收起', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-6642026681083988', 4039314752746797, 6642026681083988, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144285961115, '收起子分支', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-6642144285961115', 4039311612904008, 6642144285961115, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642134677943425, '收起至第一层', 'zh-Hans', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-6642134677943425', 4039252699292725, 6642134677943425, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077642286612, '{count} 天前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-6642077642286612', 4039305722497088, 6642077642286612, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137331510936, '深度 {depth}', 'zh-Hans', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-6642137331510936', 4039308224575343, 6642137331510936, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113422439800, '直接映射词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-6642113422439800', 4039211316535202, 6642113422439800, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058278029947, '踩', 'zh-Hans', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-6642058278029947', 4039281764373654, 6642058278029947, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024565818150, '{count} 条边', 'zh-Hans', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-6642024565818150', 4039196655494558, 6642024565818150, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051204031784, '暂无数据', 'zh-Hans', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-6642051204031784', 4039290061486601, 6642051204031784, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642109708261394, '退出全屏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-6642109708261394', 4039285164681796, 6642109708261394, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016577311844, '展开', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-6642016577311844', 4039246642706739, 6642016577311844, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642094381681236, '全部展开', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-6642094381681236', 4039323395460079, 6642094381681236, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040580204486, '展开子分支', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-6642040580204486', 4039227367141393, 6642040580204486, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-6642125838566529', 4039318048221959, 6642125838566529, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642049411049930, '筛选语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-6642049411049930', 4039264822897467, 6642049411049930, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046664136497, '全屏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-6642046664136497', 4039273948571546, 6642046664136497, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095937214170, '词句映射图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-6642095937214170', 4039229813257256, 6642095937214170, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642092079493598, '加载图谱…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-6642092079493598', 4039220553457070, 6642092079493598, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642121746906592, '图谱模式', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-6642121746906592', 4039307692947617, 6642121746906592, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020706137208, '{nodes} 个映射节点 · {edges} 个关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-6642020706137208', 4039220204112184, 6642020706137208, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642114642039717, '图谱工具栏', 'zh-Hans', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-6642114642039717', 4039247632198973, 6642114642039717, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642035482337645, '映射层级列表', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-6642035482337645', 4039262167197365, 6642035482337645, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033539062759, '跳数', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-6642033539062759', 4039218745350539, 6642033539062759, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642101204301710, '{count} 小时前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-6642101204301710', 4039261676051383, 6642101204301710, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122446194080, '刚刚', 'zh-Hans', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-6642122446194080', 4039295793832731, 6642122446194080, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142757289698, '无法加载语言', 'zh-Hans', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-6642142757289698', 4039196867547046, 6642142757289698, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642083768771338, '列表模式', 'zh-Hans', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-6642083768771338', 4039267846517304, 6642083768771338, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642080789784466, '加载更多', 'zh-Hans', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-6642080789784466', 4039257935440261, 6642080789784466, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642115400582522, '加载相关词句中', 'zh-Hans', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-6642115400582522', 4039208559662390, 6642115400582522, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642048832804695, '映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-6642048832804695', 4039299531874366, 6642048832804695, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148017508724, '映射评分', 'zh-Hans', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-6642148017508724', 4039291250524588, 6642148017508724, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020836809391, '{count} 分钟前', 'zh-Hans', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-6642020836809391', 4039319528355130, 6642020836809391, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642073609319436, '更多操作', 'zh-Hans', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-6642073609319436', 4039216903072408, 6642073609319436, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642047064277754, '完整图谱中还有 {count} 个映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-6642047064277754', 4039267933793525, 6642047064277754, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023906701874, '暂无直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-6642023906701874', 4039206484078170, 6642023906701874, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034057783920, '找不到相符词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-6642034057783920', 4039240488727553, 6642034057783920, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642045880832635, '{count} 个节点', 'zh-Hans', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-6642045880832635', 4039205391794884, 6642045880832635, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642130634261447, '节点信息', 'zh-Hans', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-6642130634261447', 4039321854954979, 6642130634261447, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642113056048464, '其他关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-6642113056048464', 4039301412743754, 6642113056048464, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018575302917, '相关词句', 'zh-Hans', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-6642018575302917', 4039285912508809, 6642018575302917, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144339670355, '{count} 个关系', 'zh-Hans', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-6642144339670355', 4039195207546455, 6642144339670355, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020053484063, '移除 {code}', 'zh-Hans', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-6642020053484063', 4039257785545173, 6642020053484063, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089969828414, '重置布局', 'zh-Hans', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-6642089969828414', 4039213227329958, 6642089969828414, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032494514795, '根节点', 'zh-Hans', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-6642032494514795', 4039280733662867, 6642032494514795, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051158517347, '搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-6642051158517347', 4039307974483127, 6642051158517347, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-6642044272242935', 4039223809446541, 6642044272242935, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144962215817, '搜索中…', 'zh-Hans', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-6642144962215817', 4039241606316828, 6642144962215817, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082865271552, '在图谱中选取节点以查看详情', 'zh-Hans', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-6642082865271552', 4039258954601880, 6642082865271552, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642027042531887, '来源路径', 'zh-Hans', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-6642027042531887', 4039267388033524, 6642027042531887, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112924811804, '赞', 'zh-Hans', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-6642112924811804', 4039305875761888, 6642112924811804, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642119087582119, '查看词句详情', 'zh-Hans', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-6642119087582119', 4039285357620964, 6642119087582119, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642047216674511, '投票失败，已撤销', 'zh-Hans', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-6642047216674511', 4039310388216878, 6642047216674511, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079482068498, '放大', 'zh-Hans', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-6642079482068498', 4039307035795639, 6642079482068498, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025294874845, '缩小', 'zh-Hans', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-6642025294874845', 4039306926563555, 6642025294874845, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032444616585, '+ 添加词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-6642032444616585', 4039234711174892, 6642032444616585, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642090723137487, '完全图', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-6642090723137487', 4039210891494791, 6642090723137487, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023218325140, '删除', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-6642023218325140', 4039233937430393, 6642023218325140, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112916184041, '{count} 个直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-6642112916184041', 4039258582305025, 6642112916184041, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-6642125838566529', 4039318048221959, 6642125838566529, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077404263859, '{count} 个词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-6642077404263859', 4039208226237843, 6642077404263859, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146499129342, '输入词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-6642146499129342', 4039264797643778, 6642146499129342, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-6642127179293910', 4039220584763101, 6642127179293910, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642133003804814, '提交一组含义相同的词句。系统会在每对之间创建直接映射。已有词句会自动关联，不会产生重复。', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-6642133003804814', 4039228008118707, 6642133003804814, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108029963380, '至少需要 2 行，每行需填写语言和词句', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-6642108029963380', 4039286212175439, 6642108029963380, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058290789573, '提交', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-6642058290789573', 4039245021981976, 6642058290789573, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642021851191783, '提交失败', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-6642021851191783', 4039220418642934, 6642021851191783, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015225216700, '提交中…', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-6642015225216700', 4039286291917398, 6642015225216700, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120556679091, '标签', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-6642120556679091', 4039312686530045, 6642120556679091, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112039287404, '批量提交', 'zh-Hans', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-6642112039287404', 4039256753970050, 6642112039287404, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642123463387947, '返回首页', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-6642123463387947', 4039244552136331, 6642123463387947, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-6642016061835830', 4039226239864187, 6642016061835830, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642036250957195, '页面未找到', 'zh-Hans', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-6642036250957195', 4039247795890512, 6642036250957195, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120627731577, '全部', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-6642120627731577', 4039202333969475, 6642120627731577, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142087711870, '提交映射 →', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-6642142087711870', 4039241704787781, 6642142087711870, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-6642024763942113', 4039247603774554, 6642024763942113, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642064903439913, '映射 + 新词句', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-6642064903439913', 4039260809744465, 6642064903439913, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082464782703, '找不到所需内容？', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-6642082464782703', 4039254190870260, 6642082464782703, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033927307089, '新贡献', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-6642033927307089', 4039302900266643, 6642033927307089, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-6642031639316449', 4039202100757950, 6642031639316449, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642123269157666, '热门映射', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-6642123269157666', 4039245957647571, 6642123269157666, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079566674863, '按评分 · 本周', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-6642079566674863', 4039291578874799, 6642079566674863, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089022254142, '语义图的最新脉动——热门映射和新贡献。', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-6642089022254142', 4039275101235147, 6642089022254142, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642036622561096, '动态', 'zh-Hans', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-6642036622561096', 4039218305844177, 6642036622561096, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146271976254, '新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-6642146271976254', 4039323156297807, 6642146271976254, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642068844191895, '新增章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-6642068844191895', 4039302981121903, 6642068844191895, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642129843359201, '手册列表', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-6642129843359201', 4039275162095516, 6642129843359201, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642149580848149, '第 {number} 章', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-6642149580848149', 4039264579862218, 6642149580848149, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079167950557, '关闭词句信息', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-6642079167950557', 4039238473169231, 6642079167950557, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026681083988, '收起', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-6642026681083988', 4039314752746797, 6642026681083988, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016726918845, '删除章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-6642016726918845', 4039212000754015, 6642016726918845, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120031672278, '编辑手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-6642120031672278', 4039244157921703, 6642120031672278, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642017881713043, '词句信息', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-6642017881713043', 4039248386595592, 6642017881713043, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089671840441, '词句的语言、地区和来源将显示在此处。', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-6642089671840441', 4039258685413951, 6642089671840441, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642103882805595, '这本手册有帮助吗？', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-6642103882805595', 4039208667474251, 6642103882805595, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642059059264353, '无法加载词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-6642059059264353', 4039291593337392, 6642059059264353, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-6642016061835830', 4039226239864187, 6642016061835830, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-6642127179293910', 4039220584763101, 6642127179293910, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642074108692098, '下移', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-6642074108692098', 4039305476617896, 6642074108692098, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642066192585677, '下移章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-6642066192585677', 4039264378315169, 6642066192585677, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642106328121191, '上移章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-6642106328121191', 4039263980419517, 6642106328121191, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642059981534711, '上移', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-6642059981534711', 4039325459519266, 6642059981534711, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105608384820, '私密', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-6642105608384820', 4039271025507837, 6642105608384820, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084554365996, '公开', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-6642084554365996', 4039267993342608, 6642084554365996, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642130808412435, '发布', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-6642130808412435', 4039241948973877, 6642130808412435, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-6642091608036792', 4039258261318005, 6642091608036792, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642076383493944, '无法加载相关词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-6642076383493944', 4039281597988534, 6642076383493944, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058950257396, '移除 {text}', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-6642058950257396', 4039238014424846, 6642058950257396, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642085065100565, '保存草稿', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-6642085065100565', 4039263998176559, 6642085065100565, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131092186881, '保存中…', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-6642131092186881', 4039270028440745, 6642131092186881, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642117391976558, '章节标题', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-6642117391976558', 4039225159134159, 6642117391976558, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061309253725, '选择词句', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-6642061309253725', 4039264953167344, 6642061309253725, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642138719738336, '来源', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-6642138719738336', 4039223387675999, 6642138719738336, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063327100543, 'AI', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-6642063327100543', 4039244426247807, 6642063327100543, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061587133200, '权威', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-6642061587133200', 4039318696248928, 6642061587133200, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041095383372, '用户', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-6642041095383372', 4039324440473230, 6642041095383372, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137208020458, '手册标题', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-6642137208020458', 4039208338888027, 6642137208020458, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642144354228922, '目录', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-6642144354228922', 4039204809556520, 6642144354228922, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642103018624855, '查看完整关系图', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-6642103018624855', 4039218586424477, 6642103018624855, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040432719166, '可见性', 'zh-Hans', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-6642040432719166', 4039319622118803, 6642040432719166, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642020871996867, '新建手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-6642020871996867', 4039273991762691, 6642020871996867, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033196167965, '加载手册失败', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-6642033196167965', 4039205037236353, 6642033196167965, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-6642031639316449', 4039202100757950, 6642031639316449, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023539860358, '未找到手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-6642023539860358', 4039297167533555, 6642023539860358, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-6642024763942113', 4039247603774554, 6642024763942113, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642076270761945, '搜索手册…', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-6642076270761945', 4039321109759665, 6642076270761945, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084896787549, '章节', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-6642084896787549', 4039271506815244, 6642084896787549, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139377956737, '手册', 'zh-Hans', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-6642139377956737', 4039234820809009, 6642139377956737, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642132908422039, '上一步', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-6642132908422039', 4039313675995469, 6642132908422039, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143445594122, '取消', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-6642143445594122', 4039291340498970, 6642143445594122, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642136428173818, '关闭', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-6642136428173818', 4039247982696992, 6642136428173818, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070594191434, '创建语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-6642070594191434', 4039261792696368, 6642070594191434, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046987427796, '语言创建失败', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-6642046987427796', 4039298612922394, 6642046987427796, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077011999346, '创建中…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-6642077011999346', 4039232938642916, 6642077011999346, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642052793160795, '请输入描述', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-6642052793160795', 4039276426027002, 6642052793160795, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642084343241388, '请选择 Glottolog 匹配或选择「无匹配」', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-6642084343241388', 4039271782430821, 6642084343241388, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642055065295298, '请输入语言名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-6642055065295298', 4039210698010944, 6642055065295298, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016949865552, '请选择仅限社区创建的原因', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-6642016949865552', 4039216473655312, 6642016949865552, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038163745702, '请输入语言子标签以继续', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-6642038163745702', 4039316213234006, 6642038163745702, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025339739296, '找到 {count} 个候选', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-6642025339739296', 4039246098211492, 6642025339739296, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120727006638, '选择匹配或标明无合适条目', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-6642120727006638', 4039323364172038, 6642120727006638, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642023985409425, '匹配此候选', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-6642023985409425', 4039325854259152, 6642023985409425, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642052762136868, '方言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-6642052762136868', 4039249282401723, 6642052762136868, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-6642127179293910', 4039243488926094, 6642127179293910, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642050171564997, 'Glottolog 无合适条目', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-6642050171564997', 4039197295194771, 6642050171564997, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105186652319, '搜索 Glottolog…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-6642105186652319', 4039262313884420, 6642105186652319, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046720550534, '描述', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-6642046720550534', 4039226938266962, 6642046720550534, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642049405854148, '描述此语言或变体…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-6642049405854148', 4039218699342636, 6642049405854148, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137962924117, '名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-6642137962924117', 4039203173843539, 6642137962924117, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024820877303, '英文名称', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-6642024820877303', 4039325286054403, 6642024820877303, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063252370902, '为何此语言未收录于 Glottolog？', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-6642063252370902', 4039255034745478, 6642063252370902, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642045651765669, '社区特定用法', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-6642045651765669', 4039318758556549, 6642045651765669, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139336329733, '新兴变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-6642139336329733', 4039201401042810, 6642139336329733, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087125625219, 'Glottolog 未收录', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-6642087125625219', 4039317085985011, 6642087125625219, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108110491018, '其他', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-6642108110491018', 4039197354913502, 6642108110491018, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642066511159489, '选择原因…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-6642066511159489', 4039198381390937, 6642066511159489, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642101084801619, '下一步', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-6642101084801619', 4039235695377645, 6642101084801619, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642126523931480, '规范代码', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-6642126523931480', 4039275920750884, 6642126523931480, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024076651823, '此语言已存在', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-6642024076651823', 4039252684783738, 6642024076651823, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034504555609, '使用现有语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-6642034504555609', 4039201624757562, 6642034504555609, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070594191434, '创建语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-6642070594191434', 4039261792696368, 6642070594191434, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046820247981, '警告', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-6642046820247981', 4039266319466062, 6642046820247981, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044276832399, '临时标签', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-6642044276832399', 4039258938883345, 6642044276832399, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642058528862255, 'Glottolog 匹配', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-6642058528862255', 4039216090040527, 6642058528862255, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122397167053, '元数据', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-6642122397167053', 4039278502317771, 6642122397167053, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642030876337248, '预览并创建', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-6642030876337248', 4039292079507095, 6642030876337248, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137488696731, '语言标签', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-6642137488696731', 4039271969593143, 6642137488696731, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-6642127179293910', 4039220584763101, 6642127179293910, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-6642091608036792', 4039258261318005, 6642091608036792, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642110809127034, '文字', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-6642110809127034', 4039265998307294, 6642110809127034, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642026181148121, '搜索子标签…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-6642026181148121', 4039305028592078, 6642026181148121, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642140869802494, '变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-6642140869802494', 4039213349000445, 6642140869802494, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642054716608916, '已移除 1 个变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-6642054716608916', 4039300854350766, 6642054716608916, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040221301703, '已移除 {count} 个变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-6642040221301703', 4039288165772049, 6642040221301703, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642032967744603, '按字母排序', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-6642032967744603', 4039328989831700, 6642032967744603, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-6642127179293910', 4039256322954053, 6642127179293910, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-6642125838566529', 4039294118562578, 6642125838566529, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-6642031639316449', 4039202100757950, 6642031639316449, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-6642016061835830', 4039226239864187, 6642016061835830, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642086477397993, '已映射', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-6642086477397993', 4039236848299860, 6642086477397993, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105878513476, '没有找到词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-6642105878513476', 4039240488727553, 6642105878513476, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-6642024763942113', 4039247603774554, 6642024763942113, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-6642044272242935', 4039223809446541, 6642044272242935, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139140342272, '清除选择', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-6642139140342272', 4039193792488426, 6642139140342272, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642057028286585, '创建新语言或变体', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-6642057028286585', 4039299846909774, 6642057028286585, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148268882398, '无匹配语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-6642148268882398', 4039195104624261, 6642148268882398, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038379665728, '搜索语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-6642038379665728', 4039246945260645, 6642038379665728, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018197473222, '浏览器推荐', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-6642018197473222', 4039233498620681, 6642018197473222, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642119964408799, '协助翻译 LangMap', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-6642119964408799', 4039251841046235, 6642119964408799, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095251982521, '无匹配的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-6642095251982521', 4039195104624261, 6642095251982521, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642106571402574, '最近使用的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-6642106571402574', 4039306795492531, 6642106571402574, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-6642125838566529', 4039294118562578, 6642125838566529, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-6642127179293910', 4039256322954053, 6642127179293910, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642142757289698, '无法加载语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-6642142757289698', 4039196867547046, 6642142757289698, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642110583821426, '未找到语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-6642110583821426', 4039305123930385, 6642110583821426, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038379665728, '搜索语言…', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-6642038379665728', 4039246945260645, 6642038379665728, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081938320652, 'A–Z', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-6642081938320652', 4039263037467916, 6642081938320652, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063274395674, '按数量', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-6642063274395674', 4039284364068927, 6642063274395674, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642112162477357, '浏览所有语言的词句与映射', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-6642112162477357', 4039317622660080, 6642112162477357, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-6642127179293910', 4039256322954053, 6642127179293910, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120418342147, '锚点', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-6642120418342147', 4039242362911495, 6642120418342147, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033838363498, '返回映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-6642033838363498', 4039274630245077, 6642033838363498, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642053565881172, '{count} 种语言', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-6642053565881172', 4039285488213874, 6642053565881172, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-6642016061835830', 4039226239864187, 6642016061835830, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041400872994, '映射成员', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-6642041400872994', 4039240565339731, 6642041400872994, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642097480840147, '此概念无地理分布数据', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-6642097480840147', 4039279250603930, 6642097480840147, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642081474362540, '{count} 个地区', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-6642081474362540', 4039302107835931, 6642081474362540, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063197943086, '概念分布', 'zh-Hans', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-6642063197943086', 4039208466994401, 6642063197943086, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139064776557, '新增并建立映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-6642139064776557', 4039259535351101, 6642139064776557, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146271976254, '新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-6642146271976254', 4039323156297807, 6642146271976254, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642038106021388, '无法新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-6642038106021388', 4039198581489142, 6642038106021388, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078859997912, '新增中…', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-6642078859997912', 4039218340751327, 6642078859997912, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642061587133200, '权威', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-6642061587133200', 4039318696248928, 6642061587133200, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642143306286453, '面包屑', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-6642143306286453', 4039291257989597, 6642143306286453, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108084805350, '关闭快速新增', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-6642108084805350', 4039267828069642, 6642108084805350, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642082249122029, '贡献映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-6642082249122029', 4039295569136473, 6642082249122029, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642046012797754, '直接映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-6642046012797754', 4039246116479366, 6642046012797754, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642138688523942, '请输入词句与语言代码', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-6642138688523942', 4039246255388206, 6642138688523942, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642125838566529, '词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-6642125838566529', 4039318048221959, 6642125838566529, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642146499129342, '输入词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-6642146499129342', 4039242456703266, 6642146499129342, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642051864182420, '图谱', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-6642051864182420', 4039261403730767, 6642051864182420, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015883011005, '首页', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-6642015883011005', 4039277332090535, 6642015883011005, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642033539062759, '跳数', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-6642033539062759', 4039277202124053, 6642033539062759, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642040169873857, '间接', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-6642040169873857', 4039318157522164, 6642040169873857, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018819739950, '语言代码', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-6642018819739950', 4039210176324565, 6642018819739950, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642043949420875, '例如 en / zh-Hant', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-6642043949420875', 4039209337204607, 6642043949420875, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102582852781, '列表', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-6642102582852781', 4039282174712441, 6642102582852781, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642016061835830, '无法加载', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-6642016061835830', 4039226239864187, 6642016061835830, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642070273407584, '映射集合', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-6642070273407584', 4039300809727185, 6642070273407584, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089640514854, '尚无映射', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-6642089640514854', 4039325677769541, 6642089640514854, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642079479919457, '选填', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-6642079479919457', 4039276071486298, 6642079479919457, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642050127998894, '快速新增词句', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-6642050127998894', 4039324958036767, 6642050127998894, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642062338381818, '新增词句并直接映射到当前词句。', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-6642062338381818', 4039212842396077, 6642062338381818, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642091608036792, '地区', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-6642091608036792', 4039258261318005, 6642091608036792, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041095383372, '用户', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-6642041095383372', 4039324440473230, 6642041095383372, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642116726950390, '在地图上查看此概念', 'zh-Hans', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-6642116726950390', 4039311455815203, 6642116726950390, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642041505540305, '关闭菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-6642041505540305', 4039297982961690, 6642041505540305, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131528409502, '贡献', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-6642131528409502', 4039312030295503, 6642131528409502, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642139377956737, '手册', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-6642139377956737', 4039234820809009, 6642139377956737, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642015883011005, '首页', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-6642015883011005', 4039277332090535, 6642015883011005, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127179293910, '语言', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-6642127179293910', 4039256322954053, 6642127179293910, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642140394109144, '菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-6642140394109144', 4039223542474758, 6642140394109144, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642018926883882, '打开菜单', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-6642018926883882', 4039278126309563, 6642018926883882, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089756820891, '搜索词句', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-6642089756820891', 4039289790753346, 6642089756820891, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642025328564659, '登录', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-6642025328564659', 4039274956726587, 6642025328564659, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642105006227901, '退出登录', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-6642105006227901', 4039277593503154, 6642105006227901, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148011577706, '提交搜索', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-6642148011577706', 4039323364353816, 6642148011577706, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642096036980072, '切换界面语言', 'zh-Hans', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-6642096036980072', 4039195322568967, 6642096036980072, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044961162962, '按字母顺序', 'zh-Hans', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-6642044961162962', 4039328989831700, 6642044961162962, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642077284734470, '提示：目前搜索匹配词句原文。翻译（语义）搜索即将推出。', 'zh-Hans', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-6642077284734470', 4039199272982370, 6642077284734470, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642073469225317, '搜索失败', 'zh-Hans', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-6642073469225317', 4039218663313831, 6642073469225317, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031639316449, '最新', 'zh-Hans', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-6642031639316449', 4039202100757950, 6642031639316449, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642122973189618, '未找到结果', 'zh-Hans', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-6642122973189618', 4039217192958680, 6642122973189618, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044272242935, '搜索词句…', 'zh-Hans', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-6642044272242935', 4039223809446541, 6642044272242935, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642024763942113, '热门', 'zh-Hans', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-6642024763942113', 4039247603774554, 6642024763942113, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642074798271187, '{count} 个结果', 'zh-Hans', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-6642074798271187', 4039304070680160, 6642074798271187, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642034968095778, '排序', 'zh-Hans', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-6642034968095778', 4039290847632508, 6642034968095778, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642089756820891, '搜索词句', 'zh-Hans', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-6642089756820891', 4039289790753346, 6642089756820891, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642128338521838, '添加要翻译的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-6642128338521838', 4039262743786868, 6642128338521838, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642086455717671, '提交 {count} 条翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-6642086455717671', 4039232809480299, 6642086455717671, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087702866407, '当前翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-6642087702866407', 4039272108076077, 6642087702866407, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642031484495695, '选择已注册的语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-6642031484495695', 4039307820065458, 6642031484495695, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044267925848, '翻译覆盖率', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-6642044267925848', 4039302750746982, 6642044267925848, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642132218759146, '显示 {count} 条', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-6642132218759146', 4039330567083979, 6642132218759146, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642062953991429, '社区本地化', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-6642062953991429', 4039263180329406, 6642062953991429, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642063470327339, '输入翻译…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-6642063470327339', 4039280361786422, 6642063470327339, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642087589191004, '无法加载翻译工作台', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-6642087589191004', 4039210189975752, 6642087589191004, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642131738404901, '加载中…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-6642131738404901', 4039198023470406, 6642131738404901, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642048000147397, '目标语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-6642048000147397', 4039286503270980, 6642048000147397, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642097466958424, '无法加载语言列表', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-6642097466958424', 4039255464963972, 6642097466958424, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642102363560784, '登录后可提交翻译；候选翻译按映射分数排序，无正分候选时使用回退文本。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-6642102363560784', 4039285344096668, 6642102363560784, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642071530294532, '未找到匹配文本。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-6642071530294532', 4039194547587951, 6642071530294532, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642057933617669, '预览', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-6642057933617669', 4039259327128845, 6642057933617669, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642133450507984, '参考语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-6642133450507984', 4039299601179530, 6642133450507984, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642120305360689, '搜索键名或原文…', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-6642120305360689', 4039252284218610, 6642120305360689, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642127357084685, '选择翻译语言', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-6642127357084685', 4039327112090503, 6642127357084685, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642148275677733, '英文原文', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-6642148275677733', 4039304389733603, 6642148275677733, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642124861185059, '开始', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-6642124861185059', 4039325838792223, 6642124861185059, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642021851191783, '提交失败', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-6642021851191783', 4039220418642934, 6642021851191783, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642137338923928, '提交映射', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-6642137338923928', 4039227663321003, 6642137338923928, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642085585815152, '已提交', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-6642085585815152', 4039196288099856, 6642085585815152, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642108644210098, '帮助让 LangMap 界面文本更自然、更实用。', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-6642108644210098', 4039258395876255, 6642108644210098, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642104679747158, '翻译工作台', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-6642104679747158', 4039292410329094, 6642104679747158, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642044160390934, '翻译 {key}', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-6642044160390934', 4039226075472990, 6642044160390934, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642078564015755, '已翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-6642078564015755', 4039206423275507, 6642078564015755, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (6642095363145866, '翻译', 'zh-Hans', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-6642095363145866', 4039241150478337, 6642095363145866, 0, 'ui_i18n');

-- Locale zh-Hant
-- auth.email
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323672176916, '電子郵件', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.email', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278566303563-5127323672176916', 4039278566303563, 5127323672176916, 0, 'ui_i18n');

-- auth.haveAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127330808040466, '已經有帳號了？', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.haveAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276962119789-5127330808040466', 4039276962119789, 5127330808040466, 0, 'ui_i18n');

-- auth.login
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348918769733, '登入', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.login', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-5127348918769733', 4039274956726587, 5127348918769733, 0, 'ui_i18n');

-- auth.noAccount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127337032500718, '還沒有帳號？', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.noAccount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210512038996-5127337032500718', 4039210512038996, 5127337032500718, 0, 'ui_i18n');

-- auth.operationFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323751663103, '操作失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.operationFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039224592934601-5127323751663103', 4039224592934601, 5127323751663103, 0, 'ui_i18n');

-- auth.password
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321548837028, '密碼', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.password', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039283475919761-5127321548837028', 4039283475919761, 5127321548837028, 0, 'ui_i18n');

-- auth.processing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127434940273956, '處理中…', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.processing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290683252068-5127434940273956', 4039290683252068, 5127434940273956, 0, 'ui_i18n');

-- auth.register
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127380536022303, '建立帳號', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.register', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254012036431-5127380536022303', 4039254012036431, 5127380536022303, 0, 'ui_i18n');

-- auth.username
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389775119240, '使用者名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:auth.username', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318948959047-5127389775119240', 4039318948959047, 5127389775119240, 0, 'ui_i18n');

-- common.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428739379210, '取消', 'zh-Hant', 'ui_i18n', 'langmap-web:common.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-5127428739379210', 4039291340498970, 5127428739379210, 0, 'ui_i18n');

-- common.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127399149304639, '關閉', 'zh-Hant', 'ui_i18n', 'langmap-web:common.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-5127399149304639', 4039247982696992, 5127399149304639, 0, 'ui_i18n');

-- common.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:common.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5127395378809533', 4039220584763101, 5127395378809533, 0, 'ui_i18n');

-- common.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:common.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5127395378809533', 4039256322954053, 5127395378809533, 0, 'ui_i18n');

-- common.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424120773993, '載入中…', 'zh-Hant', 'ui_i18n', 'langmap-web:common.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-5127424120773993', 4039198023470406, 5127424120773993, 0, 'ui_i18n');

-- common.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326247675675, '搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:common.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-5127326247675675', 4039307974483127, 5127326247675675, 0, 'ui_i18n');

-- common.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127343584574661, '提交', 'zh-Hant', 'ui_i18n', 'langmap-web:common.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-5127343584574661', 4039245021981976, 5127343584574661, 0, 'ui_i18n');

-- components.actualSize
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373408271576, '實際尺寸 100%', 'zh-Hant', 'ui_i18n', 'langmap-web:components.actualSize', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203196919686-5127373408271576', 4039203196919686, 5127373408271576, 0, 'ui_i18n');

-- components.anonymous
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354612798556, '匿名', 'zh-Hant', 'ui_i18n', 'langmap-web:components.anonymous', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039253518652932-5127354612798556', 4039253518652932, 5127354612798556, 0, 'ui_i18n');

-- components.childNodes
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127411910452997, '{count} 個子節點；點選收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.childNodes', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039322475101146-5127411910452997', 4039322475101146, 5127411910452997, 0, 'ui_i18n');

-- components.cliqueNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127429206018100, '每條邊皆為可投票的獨立直接對應；低分對應自動收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.cliqueNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318570928695-5127429206018100', 4039318570928695, 5127429206018100, 0, 'ui_i18n');

-- components.cliqueTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127413501968188, '待建立的對應圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:components.cliqueTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280324996322-5127413501968188', 4039280324996322, 5127413501968188, 0, 'ui_i18n');

-- components.closeInfoPanel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127398760176186, '關閉資訊面板', 'zh-Hant', 'ui_i18n', 'langmap-web:components.closeInfoPanel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213218065468-5127398760176186', 4039213218065468, 5127398760176186, 0, 'ui_i18n');

-- components.collapse
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409285094977, '收合', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapse', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-5127409285094977', 4039314752746797, 5127409285094977, 0, 'ui_i18n');

-- components.collapseBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354344241293, '收合子分支', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapseBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311612904008-5127354344241293', 4039311612904008, 5127354344241293, 0, 'ui_i18n');

-- components.collapseToFirst
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305289707300, '收合至第一層', 'zh-Hant', 'ui_i18n', 'langmap-web:components.collapseToFirst', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252699292725-5127305289707300', 4039252699292725, 5127305289707300, 0, 'ui_i18n');

-- components.daysAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362936071700, '{count} 天前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.daysAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305722497088-5127362936071700', 4039305722497088, 5127362936071700, 0, 'ui_i18n');

-- components.depth
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422625296024, '深度 {depth}', 'zh-Hant', 'ui_i18n', 'langmap-web:components.depth', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039308224575343-5127422625296024', 4039308224575343, 5127422625296024, 0, 'ui_i18n');

-- components.directMappingList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341828277241, '直接對應詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.directMappingList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039211316535202-5127341828277241', 4039211316535202, 5127341828277241, 0, 'ui_i18n');

-- components.downvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127385631248035, '倒讚', 'zh-Hant', 'ui_i18n', 'langmap-web:components.downvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281764373654-5127385631248035', 4039281764373654, 5127385631248035, 0, 'ui_i18n');

-- components.edgeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320200758021, '{count} 條邊', 'zh-Hant', 'ui_i18n', 'langmap-web:components.edgeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196655494558-5127320200758021', 4039196655494558, 5127320200758021, 0, 'ui_i18n');

-- components.empty
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127427486652796, '目前沒有資料', 'zh-Hant', 'ui_i18n', 'langmap-web:components.empty', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290061486601-5127427486652796', 4039290061486601, 5127427486652796, 0, 'ui_i18n');

-- components.exitFullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339606366818, '退出全螢幕', 'zh-Hant', 'ui_i18n', 'langmap-web:components.exitFullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285164681796-5127339606366818', 4039285164681796, 5127339606366818, 0, 'ui_i18n');

-- components.expand
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127314771949932, '展開', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expand', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246642706739-5127314771949932', 4039246642706739, 5127314771949932, 0, 'ui_i18n');

-- components.expandAll
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127323731090498, '全部展開', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expandAll', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323395460079-5127323731090498', 4039323395460079, 5127323731090498, 0, 'ui_i18n');

-- components.expandBranch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127375826935204, '展開子分支', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expandBranch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227367141393-5127375826935204', 4039227367141393, 5127375826935204, 0, 'ui_i18n');

-- components.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5127386696296398', 4039318048221959, 5127386696296398, 0, 'ui_i18n');

-- components.filterLanguages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127328374082923, '篩選語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.filterLanguages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264822897467-5127328374082923', 4039264822897467, 5127328374082923, 0, 'ui_i18n');

-- components.fullscreen
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324976668075, '全螢幕', 'zh-Hant', 'ui_i18n', 'langmap-web:components.fullscreen', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273948571546-5127324976668075', 4039273948571546, 5127324976668075, 0, 'ui_i18n');

-- components.graphLabel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303258293634, '詞句對應圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphLabel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039229813257256-5127303258293634', 4039229813257256, 5127303258293634, 0, 'ui_i18n');

-- components.graphLoading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357829988114, '載入圖譜…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphLoading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220553457070-5127357829988114', 4039220553457070, 5127357829988114, 0, 'ui_i18n');

-- components.graphMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362727882640, '圖譜模式', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307692947617-5127362727882640', 4039307692947617, 5127362727882640, 0, 'ui_i18n');

-- components.graphStats
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127383236550486, '{nodes} 個對應節點 · {edges} 個關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphStats', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220204112184-5127383236550486', 4039220204112184, 5127383236550486, 0, 'ui_i18n');

-- components.graphToolbar
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303921713076, '圖譜工具列', 'zh-Hant', 'ui_i18n', 'langmap-web:components.graphToolbar', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247632198973-5127303921713076', 4039247632198973, 5127303921713076, 0, 'ui_i18n');

-- components.hierarchyList
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401754811483, '對應階層列表', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hierarchyList', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262167197365-5127401754811483', 4039262167197365, 5127401754811483, 0, 'ui_i18n');

-- components.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127352115920652, '跳數', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218745350539-5127352115920652', 4039218745350539, 5127352115920652, 0, 'ui_i18n');

-- components.hoursAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127430965433435, '{count} 小時前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.hoursAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261676051383-5127430965433435', 4039261676051383, 5127430965433435, 0, 'ui_i18n');

-- components.justNow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127356044789038, '剛剛', 'zh-Hant', 'ui_i18n', 'langmap-web:components.justNow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295793832731-5127356044789038', 4039295793832731, 5127356044789038, 0, 'ui_i18n');

-- components.languageLoadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406946069111, '無法載入語言', 'zh-Hant', 'ui_i18n', 'langmap-web:components.languageLoadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-5127406946069111', 4039196867547046, 5127406946069111, 0, 'ui_i18n');

-- components.listMode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127369062556426, '列表模式', 'zh-Hant', 'ui_i18n', 'langmap-web:components.listMode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267846517304-5127369062556426', 4039267846517304, 5127369062556426, 0, 'ui_i18n');

-- components.loadMore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394507017000, '載入更多', 'zh-Hant', 'ui_i18n', 'langmap-web:components.loadMore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257935440261-5127394507017000', 4039257935440261, 5127394507017000, 0, 'ui_i18n');

-- components.loadingRelated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127425613437337, '載入相關詞句中', 'zh-Hant', 'ui_i18n', 'langmap-web:components.loadingRelated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208559662390-5127425613437337', 4039208559662390, 5127425613437337, 0, 'ui_i18n');

-- components.mapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127426061523738, '對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.mapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299531874366-5127426061523738', 4039299531874366, 5127426061523738, 0, 'ui_i18n');

-- components.mappingScore
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321981857285, '對應評分', 'zh-Hant', 'ui_i18n', 'langmap-web:components.mappingScore', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291250524588-5127321981857285', 4039291250524588, 5127321981857285, 0, 'ui_i18n');

-- components.minutesAgo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127388230651521, '{count} 分鐘前', 'zh-Hant', 'ui_i18n', 'langmap-web:components.minutesAgo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319528355130-5127388230651521', 4039319528355130, 5127388230651521, 0, 'ui_i18n');

-- components.moreActions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127358903104524, '更多操作', 'zh-Hant', 'ui_i18n', 'langmap-web:components.moreActions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216903072408-5127358903104524', 4039216903072408, 5127358903104524, 0, 'ui_i18n');

-- components.moreMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127412964521482, '完整圖譜中還有 {count} 個對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.moreMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267933793525-5127412964521482', 4039267933793525, 5127412964521482, 0, 'ui_i18n');

-- components.noDirectMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127413889982734, '尚無直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:components.noDirectMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206484078170-5127413889982734', 4039206484078170, 5127413889982734, 0, 'ui_i18n');

-- components.noExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127340817221837, '找不到相符詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.noExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-5127340817221837', 4039240488727553, 5127340817221837, 0, 'ui_i18n');

-- components.nodeCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324813258851, '{count} 個節點', 'zh-Hant', 'ui_i18n', 'langmap-web:components.nodeCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205391794884-5127324813258851', 4039205391794884, 5127324813258851, 0, 'ui_i18n');

-- components.nodeInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127372570890390, '節點資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:components.nodeInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321854954979-5127372570890390', 4039321854954979, 5127372570890390, 0, 'ui_i18n');

-- components.otherRelations
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127426289219311, '其他關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.otherRelations', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039301412743754-5127426289219311', 4039301412743754, 5127426289219311, 0, 'ui_i18n');

-- components.relatedExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127427591081550, '相關詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:components.relatedExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285912508809-5127427591081550', 4039285912508809, 5127427591081550, 0, 'ui_i18n');

-- components.relationCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127302236464772, '{count} 個關係', 'zh-Hant', 'ui_i18n', 'langmap-web:components.relationCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195207546455-5127302236464772', 4039195207546455, 5127302236464772, 0, 'ui_i18n');

-- components.removeLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305347269151, '移除 {code}', 'zh-Hant', 'ui_i18n', 'langmap-web:components.removeLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039257785545173-5127305347269151', 4039257785545173, 5127305347269151, 0, 'ui_i18n');

-- components.resetLayout
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396005384761, '重設版面配置', 'zh-Hant', 'ui_i18n', 'langmap-web:components.resetLayout', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213227329958-5127396005384761', 4039213227329958, 5127396005384761, 0, 'ui_i18n');

-- components.rootNode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341017166693, '根節點', 'zh-Hant', 'ui_i18n', 'langmap-web:components.rootNode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280733662867-5127341017166693', 4039280733662867, 5127341017166693, 0, 'ui_i18n');

-- components.search
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326247675675, '搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:components.search', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307974483127-5127326247675675', 4039307974483127, 5127326247675675, 0, 'ui_i18n');

-- components.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5127428574434575', 4039223809446541, 5127428574434575, 0, 'ui_i18n');

-- components.searching
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325686593724, '搜尋中…', 'zh-Hant', 'ui_i18n', 'langmap-web:components.searching', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241606316828-5127325686593724', 4039241606316828, 5127325686593724, 0, 'ui_i18n');

-- components.selectNodeHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127415394078254, '在圖譜中選取節點以檢視詳情', 'zh-Hant', 'ui_i18n', 'langmap-web:components.selectNodeHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258954601880-5127415394078254', 4039258954601880, 5127415394078254, 0, 'ui_i18n');

-- components.sourcePath
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127311555620129, '來源路徑', 'zh-Hant', 'ui_i18n', 'langmap-web:components.sourcePath', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267388033524-5127311555620129', 4039267388033524, 5127311555620129, 0, 'ui_i18n');

-- components.upvote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127369104864848, '讚', 'zh-Hant', 'ui_i18n', 'langmap-web:components.upvote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305875761888-5127369104864848', 4039305875761888, 5127369104864848, 0, 'ui_i18n');

-- components.viewExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127365362714954, '檢視詞句詳情', 'zh-Hant', 'ui_i18n', 'langmap-web:components.viewExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285357620964-5127365362714954', 4039285357620964, 5127365362714954, 0, 'ui_i18n');

-- components.voteFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327273013829, '投票失敗，已復原', 'zh-Hant', 'ui_i18n', 'langmap-web:components.voteFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039310388216878-5127327273013829', 4039310388216878, 5127327273013829, 0, 'ui_i18n');

-- components.zoomIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127364775853586, '放大', 'zh-Hant', 'ui_i18n', 'langmap-web:components.zoomIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307035795639-5127364775853586', 4039307035795639, 5127364775853586, 0, 'ui_i18n');

-- components.zoomOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127347621174364, '縮小', 'zh-Hant', 'ui_i18n', 'langmap-web:components.zoomOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306926563555-5127347621174364', 4039306926563555, 5127347621174364, 0, 'ui_i18n');

-- contribute.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127397292562184, '+ 新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234711174892-5127397292562184', 4039234711174892, 5127397292562184, 0, 'ui_i18n');

-- contribute.completeGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342032578063, '完全圖', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.completeGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210891494791-5127342032578063', 4039210891494791, 5127342032578063, 0, 'ui_i18n');

-- contribute.delete
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393104111077, '刪除', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.delete', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233937430393-5127393104111077', 4039233937430393, 5127393104111077, 0, 'ui_i18n');

-- contribute.directMappingCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127421487105242, '{count} 個直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.directMappingCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258582305025-5127421487105242', 4039258582305025, 5127421487105242, 0, 'ui_i18n');

-- contribute.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5127386696296398', 4039318048221959, 5127386696296398, 0, 'ui_i18n');

-- contribute.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127398239187692, '{count} 個詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208226237843-5127398239187692', 4039208226237843, 5127398239187692, 0, 'ui_i18n');

-- contribute.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422154374367, '輸入詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264797643778-5127422154374367', 4039264797643778, 5127422154374367, 0, 'ui_i18n');

-- contribute.language
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.language', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5127395378809533', 4039220584763101, 5127395378809533, 0, 'ui_i18n');

-- contribute.lead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127334034501573, '提交一組意義相同的詞句。系統會在每對之間建立直接對應。已有詞句會自動關聯，不會重複。', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.lead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039228008118707-5127334034501573', 4039228008118707, 5127334034501573, 0, 'ui_i18n');

-- contribute.minRows
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127366818595734, '至少需要 2 行，每行需填寫語言和詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.minRows', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286212175439-5127366818595734', 4039286212175439, 5127366818595734, 0, 'ui_i18n');

-- contribute.submit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127343584574661, '提交', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245021981976-5127343584574661', 4039245021981976, 5127343584574661, 0, 'ui_i18n');

-- contribute.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127377900057070, '提交失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-5127377900057070', 4039220418642934, 5127377900057070, 0, 'ui_i18n');

-- contribute.submitting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127300519001788, '提交中…', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.submitting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286291917398-5127300519001788', 4039286291917398, 5127300519001788, 0, 'ui_i18n');

-- contribute.tags
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127433562088873, '標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.tags', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312686530045-5127433562088873', 4039312686530045, 5127433562088873, 0, 'ui_i18n');

-- contribute.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319649845501, '批次提交', 'zh-Hant', 'ui_i18n', 'langmap-web:contribute.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256753970050-5127319649845501', 4039256753970050, 5127319649845501, 0, 'ui_i18n');

-- errors.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127337382702811, '回首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244552136331-5127337382702811', 4039244552136331, 5127337382702811, 0, 'ui_i18n');

-- errors.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5127321894270102', 4039226239864187, 5127321894270102, 0, 'ui_i18n');

-- errors.pageMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409989981163, '找不到頁面', 'zh-Hant', 'ui_i18n', 'langmap-web:errors.pageMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247795890512-5127409989981163', 4039247795890512, 5127409989981163, 0, 'ui_i18n');

-- feed.all
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127405921516665, '全部', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.all', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202333969475-5127405921516665', 4039202333969475, 5127405921516665, 0, 'ui_i18n');

-- feed.contributeMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406982738348, '提交對應 →', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.contributeMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241704787781-5127406982738348', 4039241704787781, 5127406982738348, 0, 'ui_i18n');

-- feed.hot
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.hot', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5127432503138096', 4039247603774554, 5127432503138096, 0, 'ui_i18n');

-- feed.mappingsAndExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414163456360, '對應 + 新詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.mappingsAndExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039260809744465-5127414163456360', 4039260809744465, 5127414163456360, 0, 'ui_i18n');

-- feed.missing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360784678505, '找不到所需內容？', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.missing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039254190870260-5127360784678505', 4039254190870260, 5127360784678505, 0, 'ui_i18n');

-- feed.newContributions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401410314681, '新貢獻', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.newContributions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302900266643-5127401410314681', 4039302900266643, 5127401410314681, 0, 'ui_i18n');

-- feed.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5127316933101537', 4039202100757950, 5127316933101537, 0, 'ui_i18n');

-- feed.popularMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360616465762, '熱門對應', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.popularMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039245957647571-5127360616465762', 4039245957647571, 5127360616465762, 0, 'ui_i18n');

-- feed.ratedThisWeek
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393063341526, '依評分 · 本週', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.ratedThisWeek', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291578874799-5127393063341526', 4039291578874799, 5127393063341526, 0, 'ui_i18n');

-- feed.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316881370889, '語意圖的最新脈動——熱門對應與新貢獻。', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275101235147-5127316881370889', 4039275101235147, 5127316881370889, 0, 'ui_i18n');

-- feed.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127354044632791, '動態', 'zh-Hant', 'ui_i18n', 'langmap-web:feed.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218305844177-5127354044632791', 4039218305844177, 5127354044632791, 0, 'ui_i18n');

-- handbook.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303129736814, '新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-5127303129736814', 4039323156297807, 5127303129736814, 0, 'ui_i18n');

-- handbook.addSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127330551910207, '新增章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.addSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302981121903-5127330551910207', 4039302981121903, 5127330551910207, 0, 'ui_i18n');

-- handbook.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414816170428, '手冊列表', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275162095516-5127414816170428', 4039275162095516, 5127414816170428, 0, 'ui_i18n');

-- handbook.chapter
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127434874633237, '第 {number} 章', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.chapter', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264579862218-5127434874633237', 4039264579862218, 5127434874633237, 0, 'ui_i18n');

-- handbook.closeExpressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393964578570, '關閉詞句資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.closeExpressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238473169231-5127393964578570', 4039238473169231, 5127393964578570, 0, 'ui_i18n');

-- handbook.collapsePicker
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409285094977, '收合', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.collapsePicker', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039314752746797-5127409285094977', 4039314752746797, 5127409285094977, 0, 'ui_i18n');

-- handbook.deleteSection
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127363673457613, '刪除章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.deleteSection', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212000754015-5127363673457613', 4039212000754015, 5127363673457613, 0, 'ui_i18n');

-- handbook.edit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401929461774, '編輯手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.edit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244157921703-5127401929461774', 4039244157921703, 5127401929461774, 0, 'ui_i18n');

-- handbook.expressionInfo
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299105086469, '詞句資訊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfo', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039248386595592-5127299105086469', 4039248386595592, 5127299105086469, 0, 'ui_i18n');

-- handbook.expressionInfoHint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424426329684, '詞句的語言、地區和來源將顯示在此處。', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.expressionInfoHint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258685413951-5127424426329684', 4039258685413951, 5127424426329684, 0, 'ui_i18n');

-- handbook.helpful
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370708607989, '這本手冊有幫助嗎？', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.helpful', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208667474251-5127370708607989', 4039208667474251, 5127370708607989, 0, 'ui_i18n');

-- handbook.inspectorFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392921577621, '無法載入詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.inspectorFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291593337392-5127392921577621', 4039291593337392, 5127392921577621, 0, 'ui_i18n');

-- handbook.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5127321894270102', 4039226239864187, 5127321894270102, 0, 'ui_i18n');

-- handbook.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5127395378809533', 4039220584763101, 5127395378809533, 0, 'ui_i18n');

-- handbook.moveDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127359402477186, '下移', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305476617896-5127359402477186', 4039305476617896, 5127359402477186, 0, 'ui_i18n');

-- handbook.moveSectionDown
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127353143480546, '下移章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionDown', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264378315169-5127353143480546', 4039264378315169, 5127353143480546, 0, 'ui_i18n');

-- handbook.moveSectionUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338848751984, '上移章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveSectionUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263980419517-5127338848751984', 4039263980419517, 5127338848751984, 0, 'ui_i18n');

-- handbook.moveUp
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345275319799, '上移', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.moveUp', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325459519266-5127345275319799', 4039325459519266, 5127345275319799, 0, 'ui_i18n');

-- handbook.private
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127390902169908, '私密', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.private', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271025507837-5127390902169908', 4039271025507837, 5127390902169908, 0, 'ui_i18n');

-- handbook.public
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127324637377220, '公開', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.public', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267993342608-5127324637377220', 4039267993342608, 5127324637377220, 0, 'ui_i18n');

-- handbook.publish
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424832020837, '發布', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.publish', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241948973877-5127424832020837', 4039241948973877, 5127424832020837, 0, 'ui_i18n');

-- handbook.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5127315776033294', 4039258261318005, 5127315776033294, 0, 'ui_i18n');

-- handbook.relationsFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357104677777, '無法載入相關詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.relationsFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039281597988534-5127357104677777', 4039281597988534, 5127357104677777, 0, 'ui_i18n');

-- handbook.removeExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127344244042484, '移除 {text}', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.removeExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039238014424846-5127344244042484', 4039238014424846, 5127344244042484, 0, 'ui_i18n');

-- handbook.saveDraft
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409309566625, '儲存草稿', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.saveDraft', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263998176559-5127409309566625', 4039263998176559, 5127409309566625, 0, 'ui_i18n');

-- handbook.saving
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127381679650516, '儲存中…', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.saving', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039270028440745-5127381679650516', 4039270028440745, 5127381679650516, 0, 'ui_i18n');

-- handbook.sectionTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370285683819, '章節標題', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sectionTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039225159134159-5127370285683819', 4039225159134159, 5127370285683819, 0, 'ui_i18n');

-- handbook.selectExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418609851462, '選擇詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.selectExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039264953167344-5127418609851462', 4039264953167344, 5127418609851462, 0, 'ui_i18n');

-- handbook.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127349345736831, '來源', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223387675999-5127349345736831', 4039223387675999, 5127349345736831, 0, 'ui_i18n');

-- handbook.sourceAi
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348620885631, 'AI', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAi', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039244426247807-5127348620885631', 4039244426247807, 5127348620885631, 0, 'ui_i18n');

-- handbook.sourceAuthority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362483023363, '權威', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceAuthority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-5127362483023363', 4039318696248928, 5127362483023363, 0, 'ui_i18n');

-- handbook.sourceUser
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407342914147, '使用者', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.sourceUser', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-5127407342914147', 4039324440473230, 5127407342914147, 0, 'ui_i18n');

-- handbook.titlePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127431204867938, '手冊標題', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.titlePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208338888027-5127431204867938', 4039208338888027, 5127431204867938, 0, 'ui_i18n');

-- handbook.toc
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127382797528579, '目錄', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.toc', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039204809556520-5127382797528579', 4039204809556520, 5127382797528579, 0, 'ui_i18n');

-- handbook.viewFullGraph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336131397323, '檢視完整關係圖', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.viewFullGraph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218586424477-5127336131397323', 4039218586424477, 5127336131397323, 0, 'ui_i18n');

-- handbook.visibility
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373453236120, '可見性', 'zh-Hant', 'ui_i18n', 'langmap-web:handbook.visibility', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039319622118803-5127373453236120', 4039319622118803, 5127373453236120, 0, 'ui_i18n');

-- handbooks.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127383589324033, '新增手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039273991762691-5127383589324033', 4039273991762691, 5127383589324033, 0, 'ui_i18n');

-- handbooks.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406551787969, '無法載入手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039205037236353-5127406551787969', 4039205037236353, 5127406551787969, 0, 'ui_i18n');

-- handbooks.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5127316933101537', 4039202100757950, 5127316933101537, 0, 'ui_i18n');

-- handbooks.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127360775839668, '找不到手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297167533555-5127360775839668', 4039297167533555, 5127360775839668, 0, 'ui_i18n');

-- handbooks.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5127432503138096', 4039247603774554, 5127432503138096, 0, 'ui_i18n');

-- handbooks.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319533546475, '搜尋手冊…', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039321109759665-5127319533546475', 4039321109759665, 5127319533546475, 0, 'ui_i18n');

-- handbooks.sections
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127405602632112, '章節', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.sections', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271506815244-5127405602632112', 4039271506815244, 5127405602632112, 0, 'ui_i18n');

-- handbooks.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325826325841, '手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:handbooks.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-5127325826325841', 4039234820809009, 5127325826325841, 0, 'ui_i18n');

-- languageCreate.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418202207127, '上一步', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039313675995469-5127418202207127', 4039313675995469, 5127418202207127, 0, 'ui_i18n');

-- languageCreate.cancel
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428739379210, '取消', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.cancel', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291340498970-5127428739379210', 4039291340498970, 5127428739379210, 0, 'ui_i18n');

-- languageCreate.close
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127399149304639, '關閉', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.close', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247982696992-5127399149304639', 4039247982696992, 5127399149304639, 0, 'ui_i18n');

-- languageCreate.create
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424239724439, '建立語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.create', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-5127424239724439', 4039261792696368, 5127424239724439, 0, 'ui_i18n');

-- languageCreate.createFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127306526842157, '語言建立失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.createFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039298612922394-5127306526842157', 4039298612922394, 5127306526842157, 0, 'ui_i18n');

-- languageCreate.creating
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418771472175, '建立中…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.creating', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232938642916-5127418771472175', 4039232938642916, 5127418771472175, 0, 'ui_i18n');

-- languageCreate.errorDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336171575006, '請輸入描述', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276426027002-5127336171575006', 4039276426027002, 5127336171575006, 0, 'ui_i18n');

-- languageCreate.errorGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396955853811, '請選擇 Glottolog 比對或選擇「無比對」', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271782430821-5127396955853811', 4039271782430821, 5127396955853811, 0, 'ui_i18n');

-- languageCreate.errorName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357418622251, '請輸入語言名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210698010944-5127357418622251', 4039210698010944, 5127357418622251, 0, 'ui_i18n');

-- languageCreate.errorReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386277435953, '請選擇僅限社群建立的原因', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216473655312-5127386277435953', 4039216473655312, 5127386277435953, 0, 'ui_i18n');

-- languageCreate.errorTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127378882991109, '請輸入語言子標籤以繼續', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.errorTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039316213234006-5127378882991109', 4039316213234006, 5127378882991109, 0, 'ui_i18n');

-- languageCreate.glottologCandidates
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327376928924, '找到 {count} 個候選', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologCandidates', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246098211492-5127327376928924', 4039246098211492, 5127327376928924, 0, 'ui_i18n');

-- languageCreate.glottologChoose
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336372587732, '選擇比對或標示無合適條目', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologChoose', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364172038-5127336372587732', 4039323364172038, 5127336372587732, 0, 'ui_i18n');

-- languageCreate.glottologExactMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336574771018, '比對此候選', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologExactMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325854259152-5127336574771018', 4039325854259152, 5127336574771018, 0, 'ui_i18n');

-- languageCreate.glottologLevelDialect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338055921956, '方言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelDialect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039249282401723-5127338055921956', 4039249282401723, 5127338055921956, 0, 'ui_i18n');

-- languageCreate.glottologLevelLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologLevelLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039243488926094-5127395378809533', 4039243488926094, 5127395378809533, 0, 'ui_i18n');

-- languageCreate.glottologNoMatch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327695489615, 'Glottolog 無合適條目', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologNoMatch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197295194771-5127327695489615', 4039197295194771, 5127327695489615, 0, 'ui_i18n');

-- languageCreate.glottologSearchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127309160014515, '搜尋 Glottolog…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.glottologSearchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262313884420-5127309160014515', 4039262313884420, 5127309160014515, 0, 'ui_i18n');

-- languageCreate.metadataDescription
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332014335622, '描述', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescription', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226938266962-5127332014335622', 4039226938266962, 5127332014335622, 0, 'ui_i18n');

-- languageCreate.metadataDescriptionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406419923431, '描述此語言或變體…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataDescriptionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218699342636-5127406419923431', 4039218699342636, 5127406419923431, 0, 'ui_i18n');

-- languageCreate.metadataName
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401083130169, '名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataName', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039203173843539-5127401083130169', 4039203173843539, 5127401083130169, 0, 'ui_i18n');

-- languageCreate.metadataNameEn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395725283619, '英文名稱', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataNameEn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325286054403-5127395725283619', 4039325286054403, 5127395725283619, 0, 'ui_i18n');

-- languageCreate.metadataReason
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127376065500682, '為何此語言未收錄於 Glottolog？', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReason', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255034745478-5127376065500682', 4039255034745478, 5127376065500682, 0, 'ui_i18n');

-- languageCreate.metadataReasonCommunity
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428084200263, '社群特定用法', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonCommunity', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318758556549-5127428084200263', 4039318758556549, 5127428084200263, 0, 'ui_i18n');

-- languageCreate.metadataReasonEmerging
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127385068999259, '新興變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonEmerging', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201401042810-5127385068999259', 4039201401042810, 5127385068999259, 0, 'ui_i18n');

-- languageCreate.metadataReasonMissing
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127373832153965, 'Glottolog 未收錄', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonMissing', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317085985011-5127373832153965', 4039317085985011, 5127373832153965, 0, 'ui_i18n');

-- languageCreate.metadataReasonOther
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393404276106, '其他', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonOther', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039197354913502-5127393404276106', 4039197354913502, 5127393404276106, 0, 'ui_i18n');

-- languageCreate.metadataReasonPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432948284566, '選擇原因…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.metadataReasonPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198381390937-5127432948284566', 4039198381390937, 5127432948284566, 0, 'ui_i18n');

-- languageCreate.next
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386378586707, '下一步', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.next', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039235695377645-5127386378586707', 4039235695377645, 5127386378586707, 0, 'ui_i18n');

-- languageCreate.previewCanonicalCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127391768169041, '標準代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewCanonicalCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039275920750884-5127391768169041', 4039275920750884, 5127391768169041, 0, 'ui_i18n');

-- languageCreate.previewExisting
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127326733972958, '此語言已存在', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExisting', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252684783738-5127326733972958', 4039252684783738, 5127326733972958, 0, 'ui_i18n');

-- languageCreate.previewExistingAction
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127363115870538, '使用現有語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewExistingAction', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039201624757562-5127363115870538', 4039201624757562, 5127363115870538, 0, 'ui_i18n');

-- languageCreate.previewTitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424239724439, '建立語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewTitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261792696368-5127424239724439', 4039261792696368, 5127424239724439, 0, 'ui_i18n');

-- languageCreate.previewWarnings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332114033069, '警告', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.previewWarnings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039266319466062-5127332114033069', 4039266319466062, 5127332114033069, 0, 'ui_i18n');

-- languageCreate.provisionalTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127297706246680, '暫時標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.provisionalTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258938883345-5127297706246680', 4039258938883345, 5127297706246680, 0, 'ui_i18n');

-- languageCreate.stepGlottolog
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336938891640, 'Glottolog 比對', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepGlottolog', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039216090040527-5127336938891640', 4039216090040527, 5127336938891640, 0, 'ui_i18n');

-- languageCreate.stepMetadata
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409985242551, '中繼資料', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepMetadata', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278502317771-5127409985242551', 4039278502317771, 5127409985242551, 0, 'ui_i18n');

-- languageCreate.stepPreview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127375811029713, '預覽並建立', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepPreview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292079507095-5127375811029713', 4039292079507095, 5127375811029713, 0, 'ui_i18n');

-- languageCreate.stepTag
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299573860323, '語言標籤', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.stepTag', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039271969593143-5127299573860323', 4039271969593143, 5127299573860323, 0, 'ui_i18n');

-- languageCreate.subtagLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220584763101-5127395378809533', 4039220584763101, 5127395378809533, 0, 'ui_i18n');

-- languageCreate.subtagRegion
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagRegion', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5127315776033294', 4039258261318005, 5127315776033294, 0, 'ui_i18n');

-- languageCreate.subtagScript
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396102912122, '文字', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagScript', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039265998307294-5127396102912122', 4039265998307294, 5127396102912122, 0, 'ui_i18n');

-- languageCreate.subtagSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394299020306, '搜尋子標籤…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305028592078-5127394299020306', 4039305028592078, 5127394299020306, 0, 'ui_i18n');

-- languageCreate.subtagVariant
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127301556984635, '變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.subtagVariant', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039213349000445-5127301556984635', 4039213349000445, 5127301556984635, 0, 'ui_i18n');

-- languageCreate.variantRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299642411845, '已移除 1 個變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300854350766-5127299642411845', 4039300854350766, 5127299642411845, 0, 'ui_i18n');

-- languageCreate.variantsRemoved
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127297749018845, '已移除 {count} 個變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languageCreate.variantsRemoved', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039288165772049-5127297749018845', 4039288165772049, 5127297749018845, 0, 'ui_i18n');

-- languageDetail.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127409120136913, '依字母排序', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-5127409120136913', 4039328989831700, 5127409120136913, 0, 'ui_i18n');

-- languageDetail.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5127395378809533', 4039256322954053, 5127395378809533, 0, 'ui_i18n');

-- languageDetail.expressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.expressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-5127386696296398', 4039294118562578, 5127386696296398, 0, 'ui_i18n');

-- languageDetail.latest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.latest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5127316933101537', 4039202100757950, 5127316933101537, 0, 'ui_i18n');

-- languageDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5127321894270102', 4039226239864187, 5127321894270102, 0, 'ui_i18n');

-- languageDetail.mapped
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127302636650680, '已對應', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.mapped', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039236848299860-5127302636650680', 4039236848299860, 5127302636650680, 0, 'ui_i18n');

-- languageDetail.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127307506165183, '找不到詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240488727553-5127307506165183', 4039240488727553, 5127307506165183, 0, 'ui_i18n');

-- languageDetail.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5127432503138096', 4039247603774554, 5127432503138096, 0, 'ui_i18n');

-- languageDetail.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:languageDetail.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5127428574434575', 4039223809446541, 5127428574434575, 0, 'ui_i18n');

-- languagePicker.clear
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345514774646, '清除選擇', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.clear', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039193792488426-5127345514774646', 4039193792488426, 5127345514774646, 0, 'ui_i18n');

-- languagePicker.createLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401028917826, '建立新語言或變體', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.createLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299846909774-5127401028917826', 4039299846909774, 5127401028917826, 0, 'ui_i18n');

-- languagePicker.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392493406626, '無符合語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-5127392493406626', 4039195104624261, 5127392493406626, 0, 'ui_i18n');

-- languagePicker.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336744172322, '搜尋語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:languagePicker.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-5127336744172322', 4039246945260645, 5127336744172322, 0, 'ui_i18n');

-- languageSwitcher.browserSuggested
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316013967809, '瀏覽器推薦', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.browserSuggested', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039233498620681-5127316013967809', 4039233498620681, 5127316013967809, 0, 'ui_i18n');

-- languageSwitcher.helpTranslate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327890852151, '協助翻譯 LangMap', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.helpTranslate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039251841046235-5127327890852151', 4039251841046235, 5127327890852151, 0, 'ui_i18n');

-- languageSwitcher.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342592583443, '無符合的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195104624261-5127342592583443', 4039195104624261, 5127342592583443, 0, 'ui_i18n');

-- languageSwitcher.recent
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127356744610830, '最近使用的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languageSwitcher.recent', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039306795492531-5127356744610830', 4039306795492531, 5127356744610830, 0, 'ui_i18n');

-- languagesPage.expressionCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.expressionCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039294118562578-5127386696296398', 4039294118562578, 5127386696296398, 0, 'ui_i18n');

-- languagesPage.languageCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.languageCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5127395378809533', 4039256322954053, 5127395378809533, 0, 'ui_i18n');

-- languagesPage.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127406946069111, '無法載入語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196867547046-5127406946069111', 4039196867547046, 5127406946069111, 0, 'ui_i18n');

-- languagesPage.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320598752207, '找不到語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039305123930385-5127320598752207', 4039305123930385, 5127320598752207, 0, 'ui_i18n');

-- languagesPage.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336744172322, '搜尋語言…', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246945260645-5127336744172322', 4039246945260645, 5127336744172322, 0, 'ui_i18n');

-- languagesPage.sortAlphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127367232105740, 'A–Z', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortAlphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263037467916-5127367232105740', 4039263037467916, 5127367232105740, 0, 'ui_i18n');

-- languagesPage.sortCount
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345311838321, '依數量', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.sortCount', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039284364068927-5127345311838321', 4039284364068927, 5127345311838321, 0, 'ui_i18n');

-- languagesPage.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407612154030, '瀏覽所有語言的詞句與對應關係', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039317622660080-5127407612154030', 4039317622660080, 5127407612154030, 0, 'ui_i18n');

-- languagesPage.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:languagesPage.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5127395378809533', 4039256322954053, 5127395378809533, 0, 'ui_i18n');

-- mapLens.anchor
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325788569537, '錨點', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.anchor', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242362911495-5127325788569537', 4039242362911495, 5127325788569537, 0, 'ui_i18n');

-- mapLens.back
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127353920450648, '回到對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.back', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274630245077-5127353920450648', 4039274630245077, 5127353920450648, 0, 'ui_i18n');

-- mapLens.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127333850393921, '{count} 種語言', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285488213874-5127333850393921', 4039285488213874, 5127333850393921, 0, 'ui_i18n');

-- mapLens.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5127321894270102', 4039226239864187, 5127321894270102, 0, 'ui_i18n');

-- mapLens.members
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127346707093309, '對應成員', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.members', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039240565339731-5127346707093309', 4039240565339731, 5127346707093309, 0, 'ui_i18n');

-- mapLens.noData
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345917555958, '此概念無地理分佈資料', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.noData', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039279250603930-5127345917555958', 4039279250603930, 5127345917555958, 0, 'ui_i18n');

-- mapLens.regions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339708916683, '{count} 個地區', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.regions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302107835931-5127339708916683', 4039302107835931, 5127339708916683, 0, 'ui_i18n');

-- mapLens.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370786022020, '概念分佈', 'zh-Hant', 'ui_i18n', 'langmap-web:mapLens.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039208466994401-5127370786022020', 4039208466994401, 5127370786022020, 0, 'ui_i18n');

-- mappingDetail.addAndMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127328290073417, '新增並建立對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addAndMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259535351101-5127328290073417', 4039259535351101, 5127328290073417, 0, 'ui_i18n');

-- mappingDetail.addExpression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127303129736814, '新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addExpression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323156297807-5127303129736814', 4039323156297807, 5127303129736814, 0, 'ui_i18n');

-- mappingDetail.addFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127357412748672, '無法新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.addFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198581489142-5127357412748672', 4039198581489142, 5127357412748672, 0, 'ui_i18n');

-- mappingDetail.adding
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127364153783000, '新增中…', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.adding', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218340751327-5127364153783000', 4039218340751327, 5127364153783000, 0, 'ui_i18n');

-- mappingDetail.authority
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127362483023363, '權威', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.authority', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318696248928-5127362483023363', 4039318696248928, 5127362483023363, 0, 'ui_i18n');

-- mappingDetail.breadcrumb
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127314083101281, '麵包屑', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.breadcrumb', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039291257989597-5127314083101281', 4039291257989597, 5127314083101281, 0, 'ui_i18n');

-- mappingDetail.closeQuickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368668783181, '關閉快速新增', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.closeQuickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039267828069642-5127368668783181', 4039267828069642, 5127368668783181, 0, 'ui_i18n');

-- mappingDetail.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348974270666, '貢獻對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039295569136473-5127348974270666', 4039295569136473, 5127348974270666, 0, 'ui_i18n');

-- mappingDetail.direct
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393373329322, '直接對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.direct', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246116479366-5127393373329322', 4039246116479366, 5127393373329322, 0, 'ui_i18n');

-- mappingDetail.enterRequired
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127423992007254, '請輸入詞句與語言代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.enterRequired', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039246255388206-5127423992007254', 4039246255388206, 5127423992007254, 0, 'ui_i18n');

-- mappingDetail.expression
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127386696296398, '詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expression', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318048221959-5127386696296398', 4039318048221959, 5127386696296398, 0, 'ui_i18n');

-- mappingDetail.expressionPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127422154374367, '輸入詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.expressionPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039242456703266-5127422154374367', 4039242456703266, 5127422154374367, 0, 'ui_i18n');

-- mappingDetail.graph
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127332060219017, '圖譜', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.graph', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039261403730767-5127332060219017', 4039261403730767, 5127332060219017, 0, 'ui_i18n');

-- mappingDetail.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389164030760, '首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-5127389164030760', 4039277332090535, 5127389164030760, 0, 'ui_i18n');

-- mappingDetail.hops
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127352115920652, '跳數', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.hops', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277202124053-5127352115920652', 4039277202124053, 5127352115920652, 0, 'ui_i18n');

-- mappingDetail.indirect
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127341692916608, '間接', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.indirect', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039318157522164-5127341692916608', 4039318157522164, 5127341692916608, 0, 'ui_i18n');

-- mappingDetail.languageCode
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316601222852, '語言代碼', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCode', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210176324565-5127316601222852', 4039210176324565, 5127316601222852, 0, 'ui_i18n');

-- mappingDetail.languageCodePlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329243205963, '例如 en / zh-Hant', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.languageCodePlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039209337204607-5127329243205963', 4039209337204607, 5127329243205963, 0, 'ui_i18n');

-- mappingDetail.list
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127387876637869, '列表', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.list', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039282174712441-5127387876637869', 4039282174712441, 5127387876637869, 0, 'ui_i18n');

-- mappingDetail.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321894270102, '無法載入', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226239864187-5127321894270102', 4039226239864187, 5127321894270102, 0, 'ui_i18n');

-- mappingDetail.mappingSet
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127396584597528, '對應集合', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.mappingSet', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039300809727185-5127396584597528', 4039300809727185, 5127396584597528, 0, 'ui_i18n');

-- mappingDetail.noMappings
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401537819350, '尚無對應', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.noMappings', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325677769541-5127401537819350', 4039325677769541, 5127401537819350, 0, 'ui_i18n');

-- mappingDetail.optional
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127327325514982, '選填', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.optional', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039276071486298-5127327325514982', 4039276071486298, 5127327325514982, 0, 'ui_i18n');

-- mappingDetail.quickAdd
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127305299939302, '快速新增詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAdd', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324958036767-5127305299939302', 4039324958036767, 5127305299939302, 0, 'ui_i18n');

-- mappingDetail.quickAddLead
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127304051485505, '新增詞句並直接對應到目前詞句。', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.quickAddLead', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039212842396077-5127304051485505', 4039212842396077, 5127304051485505, 0, 'ui_i18n');

-- mappingDetail.region
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127315776033294, '地區', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.region', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258261318005-5127315776033294', 4039258261318005, 5127315776033294, 0, 'ui_i18n');

-- mappingDetail.user
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127407342914147, '使用者', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.user', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039324440473230-5127407342914147', 4039324440473230, 5127407342914147, 0, 'ui_i18n');

-- mappingDetail.viewMap
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127350190805617, '在地圖上檢視此概念', 'zh-Hant', 'ui_i18n', 'langmap-web:mappingDetail.viewMap', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039311455815203-5127350190805617', 4039311455815203, 5127350190805617, 0, 'ui_i18n');

-- nav.closeMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127403267666151, '關閉選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.closeMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039297982961690-5127403267666151', 4039297982961690, 5127403267666151, 0, 'ui_i18n');

-- nav.contribute
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368640606434, '貢獻', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.contribute', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039312030295503-5127368640606434', 4039312030295503, 5127368640606434, 0, 'ui_i18n');

-- nav.handbooks
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127325826325841, '手冊', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.handbooks', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039234820809009-5127325826325841', 4039234820809009, 5127325826325841, 0, 'ui_i18n');

-- nav.home
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127389164030760, '首頁', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.home', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277332090535-5127389164030760', 4039277332090535, 5127389164030760, 0, 'ui_i18n');

-- nav.languages
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127395378809533, '語言', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.languages', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039256322954053-5127395378809533', 4039256322954053, 5127395378809533, 0, 'ui_i18n');

-- nav.menu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127345595159729, '選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.menu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223542474758-5127345595159729', 4039223542474758, 5127345595159729, 0, 'ui_i18n');

-- nav.openMenu
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127318839016209, '開啟選單', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.openMenu', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039278126309563-5127318839016209', 4039278126309563, 5127318839016209, 0, 'ui_i18n');

-- nav.searchExpressions
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329900720419, '搜尋詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.searchExpressions', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-5127329900720419', 4039289790753346, 5127329900720419, 0, 'ui_i18n');

-- nav.signIn
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348918769733, '登入', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.signIn', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039274956726587-5127348918769733', 4039274956726587, 5127348918769733, 0, 'ui_i18n');

-- nav.signOut
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127418242438965, '登出', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.signOut', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039277593503154-5127418242438965', 4039277593503154, 5127418242438965, 0, 'ui_i18n');

-- nav.submitSearch
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127321870233496, '送出搜尋', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.submitSearch', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039323364353816-5127321870233496', 4039323364353816, 5127321870233496, 0, 'ui_i18n');

-- nav.switchLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127313955227942, '切換介面語言', 'zh-Hant', 'ui_i18n', 'langmap-web:nav.switchLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039195322568967-5127313955227942', 4039195322568967, 5127313955227942, 0, 'ui_i18n');

-- search.alphabetical
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320410720783, '依字母順序', 'zh-Hant', 'ui_i18n', 'langmap-web:search.alphabetical', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039328989831700-5127320410720783', 4039328989831700, 5127320410720783, 0, 'ui_i18n');

-- search.hint
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127336447386655, '提示：目前搜尋比對詞句原文。語意搜尋即將推出。', 'zh-Hant', 'ui_i18n', 'langmap-web:search.hint', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039199272982370-5127336447386655', 4039199272982370, 5127336447386655, 0, 'ui_i18n');

-- search.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127384545702382, '搜尋失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:search.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039218663313831-5127384545702382', 4039218663313831, 5127384545702382, 0, 'ui_i18n');

-- search.newest
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127316933101537, '最新', 'zh-Hant', 'ui_i18n', 'langmap-web:search.newest', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039202100757950-5127316933101537', 4039202100757950, 5127316933101537, 0, 'ui_i18n');

-- search.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127338185744753, '找不到結果', 'zh-Hant', 'ui_i18n', 'langmap-web:search.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039217192958680-5127338185744753', 4039217192958680, 5127338185744753, 0, 'ui_i18n');

-- search.placeholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127428574434575, '搜尋詞句…', 'zh-Hant', 'ui_i18n', 'langmap-web:search.placeholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039223809446541-5127428574434575', 4039223809446541, 5127428574434575, 0, 'ui_i18n');

-- search.popular
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432503138096, '熱門', 'zh-Hant', 'ui_i18n', 'langmap-web:search.popular', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039247603774554-5127432503138096', 4039247603774554, 5127432503138096, 0, 'ui_i18n');

-- search.results
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127311127495684, '{count} 個結果', 'zh-Hant', 'ui_i18n', 'langmap-web:search.results', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304070680160-5127311127495684', 4039304070680160, 5127311127495684, 0, 'ui_i18n');

-- search.sort
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127320261880866, '排序', 'zh-Hant', 'ui_i18n', 'langmap-web:search.sort', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039290847632508-5127320261880866', 4039290847632508, 5127320261880866, 0, 'ui_i18n');

-- search.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127329900720419, '搜尋詞句', 'zh-Hant', 'ui_i18n', 'langmap-web:search.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039289790753346-5127329900720419', 4039289790753346, 5127329900720419, 0, 'ui_i18n');

-- translate.addLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127410440417596, '新增要翻譯的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.addLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039262743786868-5127410440417596', 4039262743786868, 5127410440417596, 0, 'ui_i18n');

-- translate.batchSubmit
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127394605177341, '提交 {count} 筆翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.batchSubmit', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039232809480299-5127394605177341', 4039232809480299, 5127394605177341, 0, 'ui_i18n');

-- translate.candidate
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348097517782, '目前翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.candidate', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039272108076077-5127348097517782', 4039272108076077, 5127348097517782, 0, 'ui_i18n');

-- translate.chooseRegistryLanguage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127342048278398, '選擇已註冊的語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.chooseRegistryLanguage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039307820065458-5127342048278398', 4039307820065458, 5127342048278398, 0, 'ui_i18n');

-- translate.coverage
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127431614850202, '翻譯涵蓋率', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.coverage', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039302750746982-5127431614850202', 4039302750746982, 5127431614850202, 0, 'ui_i18n');

-- translate.displayed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127378811419550, '顯示 {count} 筆', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.displayed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039330567083979-5127378811419550', 4039330567083979, 5127378811419550, 0, 'ui_i18n');

-- translate.eyebrow
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127358508397472, '社群本地化', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.eyebrow', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039263180329406-5127358508397472', 4039263180329406, 5127358508397472, 0, 'ui_i18n');

-- translate.inputPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127414657751069, '輸入翻譯…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.inputPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039280361786422-5127414657751069', 4039280361786422, 5127414657751069, 0, 'ui_i18n');

-- translate.loadFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127299944318146, '無法載入翻譯工作台', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loadFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039210189975752-5127299944318146', 4039210189975752, 5127299944318146, 0, 'ui_i18n');

-- translate.loading
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127424120773993, '載入中…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loading', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039198023470406-5127424120773993', 4039198023470406, 5127424120773993, 0, 'ui_i18n');

-- translate.locale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348663027096, '目標語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.locale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039286503270980-5127348663027096', 4039286503270980, 5127348663027096, 0, 'ui_i18n');

-- translate.localesFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127382465469228, '無法載入語言列表', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.localesFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039255464963972-5127382465469228', 4039255464963972, 5127382465469228, 0, 'ui_i18n');

-- translate.loginNote
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127388180907309, '登入後可提交翻譯；候選翻譯依對應分數排序，無正分候選時使用備用文字。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.loginNote', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039285344096668-5127388180907309', 4039285344096668, 5127388180907309, 0, 'ui_i18n');

-- translate.noResults
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127351988455630, '找不到相符文字。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.noResults', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039194547587951-5127351988455630', 4039194547587951, 5127351988455630, 0, 'ui_i18n');

-- translate.preview
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127432080397186, '預覽', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.preview', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039259327128845-5127432080397186', 4039259327128845, 5127432080397186, 0, 'ui_i18n');

-- translate.reference
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127339140798464, '參考語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.reference', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039299601179530-5127339140798464', 4039299601179530, 5127339140798464, 0, 'ui_i18n');

-- translate.searchPlaceholder
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127420539926969, '搜尋鍵名或原文…', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.searchPlaceholder', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039252284218610-5127420539926969', 4039252284218610, 5127420539926969, 0, 'ui_i18n');

-- translate.selectLocale
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127349462449483, '選擇翻譯語言', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.selectLocale', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039327112090503-5127349462449483', 4039327112090503, 5127349462449483, 0, 'ui_i18n');

-- translate.source
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127433569462821, '英文原文', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.source', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039304389733603-5127433569462821', 4039304389733603, 5127433569462821, 0, 'ui_i18n');

-- translate.start
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127392941268920, '開始', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.start', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039325838792223-5127392941268920', 4039325838792223, 5127392941268920, 0, 'ui_i18n');

-- translate.submitFailed
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127377900057070, '提交失敗', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitFailed', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039220418642934-5127377900057070', 4039220418642934, 5127377900057070, 0, 'ui_i18n');

-- translate.submitMapping
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127348787423001, '提交對應', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitMapping', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039227663321003-5127348787423001', 4039227663321003, 5127348787423001, 0, 'ui_i18n');

-- translate.submitted
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127370879600240, '已提交', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.submitted', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039196288099856-5127370879600240', 4039196288099856, 5127370879600240, 0, 'ui_i18n');

-- translate.subtitle
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127319512300712, '幫助讓 LangMap 介面文字更自然、更實用。', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.subtitle', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039258395876255-5127319512300712', 4039258395876255, 5127319512300712, 0, 'ui_i18n');

-- translate.title
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127368254100335, '翻譯工作台', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.title', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039292410329094-5127368254100335', 4039292410329094, 5127368254100335, 0, 'ui_i18n');

-- translate.translateKey
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127393508132181, '翻譯 {key}', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translateKey', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039226075472990-5127393508132181', 4039226075472990, 5127393508132181, 0, 'ui_i18n');

-- translate.translated
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127401344814638, '已翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translated', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039206423275507-5127401344814638', 4039206423275507, 5127401344814638, 0, 'ui_i18n');

-- translate.translation
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES (5127351365330507, '翻譯', 'zh-Hant', 'ui_i18n', 'langmap-web:translate.translation', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('4039241150478337-5127351365330507', 4039241150478337, 5127351365330507, 0, 'ui_i18n');

-- Done