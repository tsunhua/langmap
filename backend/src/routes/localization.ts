import { Hono } from 'hono';
import type { D1Database } from '@cloudflare/workers-types';
import { requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, notFound, success } from '../utils/response';
import { parseIntegerId, serializeIntegerId } from '../utils/ids';
import { createEdge, MappingError } from '../services/mappings';
import { parseLanguageLocaleCode } from '../services/languageIdentity';
import { resolveBundle } from '../services/localizationDomain';
import type { Bindings, Variables } from '../types';

const localization = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const localeRows = (db: D1Database, projectId: string) => db.prepare("SELECT ll.code AS language_locale_code,ll.name,ll.name_en,s.direction,u.status,u.mapping_revision,u.activation_source FROM ui_locales u JOIN language_locales ll ON ll.id=u.locale_id LEFT JOIN scripts s ON s.code=ll.script_code WHERE u.project_id=? ORDER BY ll.code").bind(projectId).all();

localization.get('/projects/:projectId/locales', async (c) => success(c, await localeRows(c.env.DB,c.req.param('projectId')).then((x)=>x.results)));
localization.get('/projects/:projectId/messages', async (c) => {
  const primary = c.req.query('primary')?.trim() ?? '';
  const secondary = c.req.query('secondary')?.trim() ?? '';
  if (primary && !parseLanguageLocaleCode(primary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE');
  if (secondary && !parseLanguageLocaleCode(secondary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE');
  return success(c, { messages: await resolveBundle(c.env.DB, c.req.param('projectId'), primary || undefined, secondary || undefined) });
});
localization.post('/projects/:projectId/locales', requireAuth, async (c) => {
  const body=await c.req.json<Record<string,unknown>>().catch(()=>({}));const code=typeof body.language_locale_code==='string'?body.language_locale_code.trim():'';if(!code)return badRequest(c,'INVALID_LANGUAGE_LOCALE_CODE');const locale=await c.env.DB.prepare('SELECT id FROM language_locales WHERE code=?').bind(code).first<{id:number}>();if(!locale)return badRequest(c,'INVALID_LANGUAGE_LOCALE_CODE');await c.env.DB.prepare("INSERT OR IGNORE INTO ui_locales(project_id,locale_id,status,created_by) VALUES(?,?,'draft',?)").bind(c.req.param('projectId'),locale.id,c.get('user')!.id).run();const rows=await localeRows(c.env.DB,c.req.param('projectId'));const row=rows.results.find((item:any)=>item.language_locale_code===code);return created(c,row);
});
localization.post('/projects/:projectId/mappings', requireAuth, async (c) => {
  const body=await c.req.json<Record<string,unknown>>().catch(()=>({}));const key=typeof body.message_key==='string'?body.message_key:'';const target=typeof body.target_expression_id==='string'?parseIntegerId(body.target_expression_id):null;if(!key||!target)return badRequest(c,'VALIDATION_FAILED');const source=await c.env.DB.prepare('SELECT source_expression_id FROM ui_messages WHERE project_id=? AND message_key=? AND status=\'active\'').bind(c.req.param('projectId'),key).first<{source_expression_id:number}>();if(!source)return notFound(c,'Message');try{const result=await createEdge(c.env.DB,{expression_a_id:source.source_expression_id,expression_b_id:target,relation_mask:1,created_by:c.get('user')!.id});return success(c,{...result,edge:{...result.edge,id:serializeIntegerId(result.edge.id)}})}catch(error){return error instanceof MappingError?badRequest(c,error.code):badRequest(c,'MAPPING_FAILED')}
});
localization.post('/projects/:projectId/locales/:code/activate',requireAuth,async(c)=>{if(c.get('user')!.role!=='admin')return forbidden(c);const row=await c.env.DB.prepare("UPDATE ui_locales SET status='active',activation_source='manual',activated_at=CURRENT_TIMESTAMP,activated_by=? WHERE project_id=? AND locale_id=(SELECT id FROM language_locales WHERE code=?) RETURNING locale_id").bind(c.get('user')!.id,c.req.param('projectId'),c.req.param('code')).first();if(!row)return notFound(c,'UI locale');return success(c,{activated:true})});
localization.post('/projects/:projectId/locales/:code/archive',requireAuth,async(c)=>{if(c.get('user')!.role!=='admin')return forbidden(c);const row=await c.env.DB.prepare("UPDATE ui_locales SET status='archived' WHERE project_id=? AND locale_id=(SELECT id FROM language_locales WHERE code=?) RETURNING locale_id").bind(c.req.param('projectId'),c.req.param('code')).first();if(!row)return notFound(c,'UI locale');return success(c,{archived:true})});
localization.get('/projects/:projectId/workbench/:code', requireAuth, async (c) => {
  const projectId = c.req.param('projectId');
  const code = c.req.param('code') ?? '';
  if (!parseLanguageLocaleCode(code)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE');
  const limit = Math.min(Math.max(Number(c.req.query('limit') ?? 20) || 20, 1), 100);
  const offset = Math.max(Number.parseInt(c.req.query('offset') ?? '0', 10) || 0, 0);
  const q = (c.req.query('q') ?? '').trim();
  const locale = await c.env.DB.prepare("SELECT ll.code AS language_locale_code,ll.name,ll.name_en,s.direction,u.status,u.mapping_revision,u.activation_source FROM ui_locales u JOIN language_locales ll ON ll.id=u.locale_id LEFT JOIN scripts s ON s.code=ll.script_code WHERE u.project_id=? AND ll.code=?").bind(projectId, code).first();
  if (!locale) return notFound(c, 'UI locale');
  const filter = q ? "AND (m.message_key LIKE ? ESCAPE '\\' OR m.source_text LIKE ? ESCAPE '\\')" : '';
  const baseParams: Array<string | number> = [projectId, 'active'];
  const likeParams: Array<string | number> = q ? [`%${q}%`, `%${q}%`] : [];
  const total = await c.env.DB.prepare(`SELECT COUNT(*) AS total FROM ui_messages m WHERE m.project_id=? AND m.status=? ${filter}`).bind(...baseParams, ...likeParams).first<{ total: number }>();
  const translated = await c.env.DB.prepare(
    "SELECT COUNT(*) AS translated FROM ui_messages m WHERE m.project_id=? AND m.status='active' AND EXISTS (SELECT 1 FROM expression_edges e JOIN expressions t ON t.id=CASE WHEN e.expression_a_id=m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE (e.expression_a_id=m.source_expression_id OR e.expression_b_id=m.source_expression_id) AND t.language_id=(SELECT language_id FROM language_locales WHERE code=?) AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=t.id AND l.code=?))",
  ).bind(projectId, code, code).first<{ translated: number }>();
  const page = await c.env.DB.prepare(`SELECT m.message_key AS key, m.source_text FROM ui_messages m WHERE m.project_id=? AND m.status=? ${filter} ORDER BY m.message_key ASC LIMIT ? OFFSET ?`).bind(...baseParams, ...likeParams, limit, offset).all<{ key: string; source_text: string }>();
  const keys = page.results.map((row) => row.key);
  const candidates = new Map<string, Array<{ edge_id: number; expression_id: number; text: string; score: number }>>();
  if (keys.length) {
    const marks = keys.map(() => '?').join(',');
    const rows = await c.env.DB.prepare(
      `SELECT key, edge_id, expression_id, text, score FROM (
        SELECT m.message_key AS key, e.id AS edge_id, t.id AS expression_id, t.text AS text, e.score
        FROM ui_messages m JOIN expression_edges e ON e.expression_a_id=m.source_expression_id JOIN expressions t ON t.id=e.expression_b_id
        WHERE m.project_id=? AND m.status='active' AND m.message_key IN (${marks}) AND t.language_id=(SELECT language_id FROM language_locales WHERE code=?)
          AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=t.id AND l.code=?)
        UNION ALL
        SELECT m.message_key AS key, e.id AS edge_id, t.id AS expression_id, t.text AS text, e.score
        FROM ui_messages m JOIN expression_edges e ON e.expression_b_id=m.source_expression_id JOIN expressions t ON t.id=e.expression_a_id
        WHERE m.project_id=? AND m.status='active' AND m.message_key IN (${marks}) AND t.language_id=(SELECT language_id FROM language_locales WHERE code=?)
          AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=t.id AND l.code=?)
      ) ORDER BY key, score DESC, expression_id`,
    ).bind(projectId, ...keys, code, code, projectId, ...keys, code, code).all();
    for (const row of rows.results) {
      const list = candidates.get(row.key) ?? [];
      list.push({ edge_id: row.edge_id, expression_id: row.expression_id, text: row.text, score: row.score });
      candidates.set(row.key, list);
    }
  }
  const totalCount = total?.total ?? 0;
  const translatedCount = translated?.translated ?? 0;
  return success(c, {
    locale,
    coverage: { coverage: totalCount ? Math.round((10000 * translatedCount) / totalCount) / 100 : 0, translated: translatedCount, total: totalCount },
    messages: page.results.map((row) => ({ ...row, candidates: (candidates.get(row.key) ?? []).map((item) => ({ edge_id: serializeIntegerId(item.edge_id), expression_id: serializeIntegerId(item.expression_id), text: item.text, score: item.score })) })),
    total: totalCount,
    skip: offset,
    limit,
  });
});
localization.post('/projects/:projectId/mappings/batch', requireAuth, async (c) => {
  const body = await c.req.json<Record<string, unknown>>().catch(() => ({}));
  const mappings = Array.isArray(body.mappings) ? body.mappings : [];
  if (mappings.length === 0) return badRequest(c, 'VALIDATION_FAILED');
  if (mappings.length > 100) return badRequest(c, 'BATCH_TOO_LARGE');
  let processed = 0;
  for (const item of mappings) {
    if (typeof item !== 'object' || item === null) continue;
    const key = typeof (item as Record<string, unknown>).message_key === 'string' ? (item as Record<string, unknown>).message_key as string : '';
    const target = typeof (item as Record<string, unknown>).target_expression_id === 'string' ? parseIntegerId((item as Record<string, unknown>).target_expression_id as string) : null;
    if (!key || !target) continue;
    const source = await c.env.DB.prepare("SELECT source_expression_id FROM ui_messages WHERE project_id=? AND message_key=? AND status='active'").bind(c.req.param('projectId'), key).first<{ source_expression_id: number }>();
    if (!source) continue;
    try {
      await createEdge(c.env.DB, { expression_a_id: source.source_expression_id, expression_b_id: target, relation_mask: 1, created_by: c.get('user')?.id ?? 0 });
      processed += 1;
    } catch { /* skip conflicting or self edges */ }
  }
  const skipped = mappings.length - processed;
  return success(c, { processed, skipped });
});
localization.post('/projects/:projectId/votes', requireAuth, async (c) => {
  const body = await c.req.json<Record<string, unknown>>().catch(() => ({}));
  const value = typeof body.vote === 'number' ? body.vote : NaN;
  if (value !== 1 && value !== -1) return badRequest(c, 'VOTE_INVALID_VALUE');
  const edgeId = typeof body.edge_id === 'string' ? parseIntegerId(body.edge_id) : null;
  const edge = edgeId !== null ? await c.env.DB.prepare('SELECT id FROM expression_edges WHERE id=?').bind(edgeId).first<{ id: number }>() : null;
  if (!edge) return notFound(c, 'Edge');
  await c.env.DB.prepare('INSERT INTO edge_votes(user_id, edge_id, vote) VALUES(?,?,?) ON CONFLICT(user_id, edge_id) DO UPDATE SET vote=excluded.vote').bind(c.get('user')?.id ?? 0, edge.id, value).run();
  await c.env.DB.prepare('UPDATE expression_edges SET score=(SELECT COALESCE(SUM(vote),0) FROM edge_votes WHERE edge_id=?) WHERE id=?').bind(edge.id, edge.id).run();
  const score = (await c.env.DB.prepare('SELECT score FROM expression_edges WHERE id=?').bind(edge.id).first<{ score: number }>())?.score ?? 0;
  return success(c, { edge_id: serializeIntegerId(edge.id), vote: value, score });
});
export default localization;
