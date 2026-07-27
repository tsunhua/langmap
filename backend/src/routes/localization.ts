import { Hono } from 'hono';
import { success, notFound, badRequest, created, forbidden } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';
import { expressionId, stableEdgeId } from '../utils/ids';
import { requireRegisteredLanguage } from '../services/languageRegistry';

const localization = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const PROJECT_ID = 'langmap-web';
const MAX_BATCH = 100;
const MAX_TEXT_CODEPOINTS = 4000;
const FIRST_PARTY_LOCALES = [
  { code: 'en-US', native_name: 'English (United States)', direction: 'ltr', fallback_code: null, status: 'active' },
] as const;

function validProject(c: any, projectId: string) {
  return projectId === PROJECT_ID || notFound(c, 'PROJECT_NOT_FOUND');
}

async function projectLocale(c: any, projectId: string, code?: string) {
  const sql = code
    ? 'SELECT * FROM ui_locales WHERE project_id = ? AND code = ?'
    : `SELECT * FROM ui_locales WHERE project_id = ? AND status = 'active'
        ORDER BY CASE WHEN code = 'en-US' THEN 0 ELSE 1 END, native_name, code`;
  if (code) {
    const row = await c.env.DB.prepare(sql).bind(projectId, code).first();
    return row || FIRST_PARTY_LOCALES.find(locale => locale.code === code) || null;
  }
  const result = await c.env.DB.prepare(sql).bind(projectId).all();
  const byCode = new Map((result.results ?? []).map((row: any) => [row.code, row]));
  for (const locale of FIRST_PARTY_LOCALES) if (!byCode.has(locale.code)) byCode.set(locale.code, { project_id: projectId, ...locale, mapping_revision: 0 });
  return { results: [...byCode.values()].sort((a: any, b: any) => (a.code === 'en-US' ? -1 : b.code === 'en-US' ? 1 : String(a.native_name).localeCompare(String(b.native_name)) || a.code.localeCompare(b.code)) ) };
}

export function parentLocaleCodes(code: string): string[] {
  const parts = code.split('-');
  const parents: string[] = [];
  while (parts.length > 1) {
    parts.pop();
    parents.push(parts.join('-'));
  }
  return parents;
}

async function fallbackChain(c: any, projectId: string, locale: any): Promise<string[]> {
  const chain: string[] = [];
  const add = (code: string | null | undefined) => {
    if (code && !chain.includes(code) && chain.length < 5) chain.push(code);
  };
  add(locale?.code);
  if (locale?.fallback_code) add(locale.fallback_code);
  for (const parent of parentLocaleCodes(locale?.code || '')) {
    if (chain.length >= 5) break;
    const row = await projectLocale(c, projectId, parent) as any;
    if (row && row.status !== 'archived') add(parent);
  }
  add('en-US');
  return chain.slice(0, 5);
}

function textCodePoints(value: string): number { return [...value].length; }
function isPlainText(value: string): boolean {
  // UI translations are text expressions; HTML and control characters are not accepted.
  return !/[<>]/u.test(value) && !/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/u.test(value);
}
export function placeholders(value: string): string[] {
  return [...value.matchAll(/\{([A-Za-z_][A-Za-z0-9_.-]*)\}/g)].map((m) => m[1]).sort();
}
export function samePlaceholders(source: string, target: string, expected?: string | null): boolean {
  const sourceKeys = expected ? (() => {
    try {
      const parsed = JSON.parse(expected) as string[] | Record<string, unknown>;
      return Array.isArray(parsed) ? parsed : Object.keys(parsed);
    } catch { return placeholders(source); }
  })() : placeholders(source);
  return JSON.stringify([...sourceKeys].sort()) === JSON.stringify(placeholders(target));
}
export function validText(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0 && textCodePoints(value.trim()) <= MAX_TEXT_CODEPOINTS && isPlainText(value.trim());
}

/** Pick one candidate per message key using the documented deterministic order. */
export function selectLocalizedRows(rows: Array<{
  key: string;
  locale_code: string;
  text: string;
  score: number;
  edge_created_at?: string | null;
  target_id?: number | null;
}>, chain: string[]): Record<string, string> {
  const selected = new Set<string>();
  const messages: Record<string, string> = {};
  const rank = new Map(chain.map((code, index) => [code, index]));
  const ordered = [...rows].sort((a, b) =>
    (rank.get(a.locale_code) ?? 99) - (rank.get(b.locale_code) ?? 99) ||
    b.score - a.score ||
    String(a.edge_created_at ?? '').localeCompare(String(b.edge_created_at ?? '')) ||
    Number(a.target_id ?? 0) - Number(b.target_id ?? 0));
  for (const row of ordered) {
    if (!selected.has(row.key)) {
      selected.add(row.key);
      messages[row.key] = row.text;
    }
  }
  return messages;
}
async function sourceMessage(c: any, projectId: string, key: string) {
  return c.env.DB.prepare(
    `SELECT m.key, m.description, m.scope, m.message_format, m.source_expression_id,
       m.placeholders_json, m.source_hash, e.text AS source_text
     FROM ui_messages m JOIN expressions e ON e.id = m.source_expression_id
     WHERE m.project_id = ? AND m.key = ? AND m.status = 'active'`
  ).bind(projectId, key).first();
}
async function createMapping(c: any, projectId: string, body: any) {
  if (typeof body?.key !== 'string' || !body.key.trim() || typeof body?.locale_code !== 'string' || !validText(body?.text)) return badRequest(c, 'invalid_mapping');
  const key = body.key.trim();
  const localeCode = body.locale_code.trim();
  const lang = await requireRegisteredLanguage(c.env.DB, localeCode);
  if (!lang) return badRequest(c, 'invalid_locale_code');
  const locale = await projectLocale(c, projectId, localeCode) as any;
  if (!locale) return badRequest(c, 'invalid_locale_code');
  if (locale.status === 'archived') return badRequest(c, 'locale_not_translatable');
  let message = await sourceMessage(c, projectId, key) as any;
  if (!message && validText(body?.source_text)) {
    const sourceText = body.source_text.trim();
    const sourceId = await expressionId('en-US', sourceText);
    await c.env.DB.prepare(
      `INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status, created_by)
       VALUES (?, ?, 'en-US', 'ui_i18n', ?, 'approved', ?)`
    ).bind(sourceId, sourceText, `${projectId}:${key}`, c.get('user')?.username ?? null).run();
    await c.env.DB.prepare(
      `INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
       VALUES (?, ?, ?, ?, ?, 'active')`
    ).bind(projectId, key, sourceId, JSON.stringify(placeholders(sourceText)), String(sourceId)).run();
    message = await sourceMessage(c, projectId, key) as any;
  }
  if (!message) return badRequest(c, 'ui_message_create_failed');
  const text = body.text.trim();
  if (!samePlaceholders(message.source_text, text, message.placeholders_json)) return badRequest(c, 'placeholder_mismatch');
  let target = await c.env.DB.prepare(
    'SELECT id FROM expressions WHERE language_code = ? AND text = ? ORDER BY id LIMIT 1'
  ).bind(localeCode, text).first<{ id: number }>();
  if (!target) {
    const id = await expressionId(localeCode, text);
    await c.env.DB.prepare(
      `INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status, created_by)
       VALUES (?, ?, ?, 'ui_i18n', ?, 'pending', ?)`
    ).bind(id, text, localeCode, `${projectId}:${key}`, c.get('user')?.username ?? null).run();
    target = await c.env.DB.prepare('SELECT id FROM expressions WHERE id = ?').bind(id).first<{ id: number }>();
  }
  if (!target) return badRequest(c, 'expression_create_failed');
  const edgeId = await stableEdgeId(message.source_expression_id, target.id);
  await c.env.DB.prepare(
    `INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by)
     VALUES (?, ?, ?, 0, 'ui_i18n', ?)`
  ).bind(edgeId, Math.min(message.source_expression_id, target.id), Math.max(message.source_expression_id, target.id), c.get('user')?.id).run();
  await c.env.DB.prepare('UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND code = ?').bind(projectId, localeCode).run();
  return { edge_id: edgeId, key, locale_code: localeCode, target_expression_id: target.id, score: 0 };
}

localization.get('/projects/:projectId/locales', async (c) => {
  const projectId = c.req.param('projectId');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  const result = await projectLocale(c, projectId);
  return success(c, { project_id: projectId, source_locale: 'en-US', locales: result.results ?? [] });
});

localization.get('/projects/:projectId/locales/:code/messages', async (c) => {
  const projectId = c.req.param('projectId');
  const code = c.req.param('code');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  const locale = await projectLocale(c, projectId, code) as any;
  if (!locale || locale.status === 'archived') return notFound(c, 'Locale');

  const chain = await fallbackChain(c, projectId, locale);
  const revision = await c.env.DB.prepare(
    `SELECT COALESCE(MAX(mapping_revision), 0) AS revision FROM ui_locales
     WHERE project_id = ? AND code IN (${chain.map(() => '?').join(',')})`
  ).bind(projectId, ...chain).first<{ revision: number }>();
  const etag = `"loc-${projectId}-${code}-r${revision?.revision ?? 0}"`;
  if (c.req.header('If-None-Match') === etag) return c.body(null, 304);

  const rows = await c.env.DB.prepare(
    `SELECT m.key, m.source_expression_id, m.message_format,
       e.text AS source_text,
       te.id AS target_id, te.text AS text, te.language_code AS locale_code,
       ed.score, ed.created_at AS edge_created_at
     FROM ui_messages m
     JOIN expressions e ON e.id = m.source_expression_id
     LEFT JOIN expression_edges ed ON ed.expression_a_id = m.source_expression_id OR ed.expression_b_id = m.source_expression_id
     LEFT JOIN expressions te ON te.id = CASE WHEN ed.expression_a_id = m.source_expression_id THEN ed.expression_b_id ELSE ed.expression_a_id END
     WHERE m.project_id = ? AND m.status = 'active'
       AND te.language_code IN (${chain.map(() => '?').join(',')})`
  ).bind(projectId, ...chain).all<any>();

  const messages = selectLocalizedRows(rows.results ?? [], chain);
  return c.header('ETag', etag), c.header('Cache-Control', 'public, max-age=300, stale-while-revalidate=86400'), success(c, {
    project_id: projectId, locale: code, fallback_chain: chain, revision: revision?.revision ?? 0, messages
  });
});

localization.get('/projects/:projectId/workbench/:code', async (c) => {
  const projectId = c.req.param('projectId');
  const code = c.req.param('code');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  const locale = await projectLocale(c, projectId, code) as any;
  if (!locale || locale.status === 'archived') return notFound(c, 'Locale');
  const rows = await c.env.DB.prepare(
    `SELECT m.key, m.description, m.scope, m.message_format, m.source_expression_id,
       m.placeholders_json, e.text AS source_text, te.id AS target_id, te.text AS target_text,
       ed.id AS edge_id, ed.score, ed.created_at
     FROM ui_messages m JOIN expressions e ON e.id = m.source_expression_id
     LEFT JOIN expression_edges ed ON (ed.expression_a_id = m.source_expression_id OR ed.expression_b_id = m.source_expression_id)
       AND EXISTS (SELECT 1 FROM expressions candidate WHERE candidate.id = CASE WHEN ed.expression_a_id = m.source_expression_id THEN ed.expression_b_id ELSE ed.expression_a_id END AND candidate.language_code = ?)
     LEFT JOIN expressions te ON te.id = CASE WHEN ed.expression_a_id = m.source_expression_id THEN ed.expression_b_id ELSE ed.expression_a_id END
     WHERE m.project_id = ? AND m.status = 'active'
     ORDER BY m.key, ed.score DESC, ed.created_at ASC, te.id ASC`
  ).bind(code, projectId).all<any>();
  const messages: Record<string, any> = {};
  for (const row of rows.results ?? []) {
    const item = messages[row.key] ??= { key: row.key, description: row.description, scope: row.scope, message_format: row.message_format, source_expression_id: row.source_expression_id, source_text: row.source_text, placeholders_json: row.placeholders_json, candidates: [] };
    if (row.target_id != null) item.candidates.push({ edge_id: row.edge_id, expression_id: row.target_id, text: row.target_text, score: row.score, created_at: row.created_at });
  }
  const keys = Object.keys(messages);
  const translated = keys.filter((key) => messages[key].candidates.length > 0 && messages[key].candidates[0].score >= 0).length;
  return success(c, { project_id: projectId, locale: code, coverage: keys.length ? translated / keys.length : 1, total_keys: keys.length, translated_keys: translated, messages: keys.sort().map((key) => messages[key]) });
});

localization.post('/projects/:projectId/mappings', requireAuth, async (c) => {
  const projectId = c.req.param('projectId');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  let body: any; try { body = await c.req.json(); } catch { return badRequest(c, 'invalid_json'); }
  const result = await createMapping(c, projectId, body);
  return result instanceof Response ? result : created(c, result);
});

localization.post('/projects/:projectId/locales', requireAuth, async (c) => {
  const projectId = c.req.param('projectId');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  let body: any; try { body = await c.req.json(); } catch { return badRequest(c, 'invalid_json'); }
  const code = typeof body?.code === 'string' ? body.code.trim() : '';
  if (!/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(code) || code === 'en-US') return badRequest(c, 'invalid_locale_code');
  const language = await requireRegisteredLanguage(c.env.DB, code);
  if (!language) return badRequest(c, 'INVALID_LANGUAGE_CODE', 'language_code must reference a registered language');
  await c.env.DB.prepare(`INSERT OR IGNORE INTO ui_locales (project_id, code, native_name, direction, fallback_code, status) VALUES (?, ?, ?, ?, 'en-US', 'draft')`).bind(projectId, code, language.name || language.name_en || code, language.direction || 'ltr').run();
  const locale = await projectLocale(c, projectId, code);
  return created(c, locale);
});

localization.post('/projects/:projectId/mappings/batch', requireAuth, async (c) => {
  const projectId = c.req.param('projectId');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  let body: any; try { body = await c.req.json(); } catch { return badRequest(c, 'invalid_json'); }
  const items = Array.isArray(body) ? body : (body?.mappings ?? body?.items);
  if (!Array.isArray(items) || items.length === 0) return badRequest(c, 'invalid_batch');
  if (items.length > MAX_BATCH) return badRequest(c, 'too_many_mappings');
  const results: any[] = [];
  for (const item of items) {
    const result = await createMapping(c, projectId, item);
    if (result instanceof Response) return result;
    results.push(result);
  }
  return created(c, { count: results.length, mappings: results });
});

localization.post('/projects/:projectId/locales/:code/archive', requireAuth, async (c) => {
  const projectId = c.req.param('projectId');
  const projectError = validProject(c, projectId);
  if (projectError !== true) return projectError;
  if (c.get('user')?.role !== 'admin') return forbidden(c);
  const code = c.req.param('code');
  const locale = await projectLocale(c, projectId, code) as any;
  if (!locale) return notFound(c, 'Locale');
  if (code === 'en-US') return badRequest(c, 'cannot_archive_source_locale');
  await c.env.DB.prepare("UPDATE ui_locales SET status = 'archived', updated_at = CURRENT_TIMESTAMP, updated_by = ? WHERE project_id = ? AND code = ?").bind(c.get('user')?.username, projectId, code).run();
  return success(c, { project_id: projectId, locale: code, status: 'archived' });
});

export default localization;
