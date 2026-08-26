import { Hono } from 'hono';
import type { D1Database } from '@cloudflare/workers-types';
import { requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, notFound, success } from '../utils/response';
import { parseIntegerId, serializeIntegerId } from '../utils/ids';
import { createEdge, MappingError } from '../services/mappings';
import type { Bindings, Variables } from '../types';

const localization = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const localeRows = (db: D1Database, projectId: string) => db.prepare("SELECT ll.code AS language_locale_code,ll.name,ll.name_en,s.direction,u.status,u.mapping_revision,u.activation_source FROM ui_locales u JOIN language_locales ll ON ll.id=u.locale_id LEFT JOIN scripts s ON s.code=ll.script_code WHERE u.project_id=? ORDER BY ll.code").bind(projectId).all();

localization.get('/projects/:projectId/locales', async (c) => success(c, await localeRows(c.env.DB,c.req.param('projectId')).then((x)=>x.results)));
localization.get('/projects/:projectId/messages', async (c) => {
  const rows=await c.env.DB.prepare("SELECT message_key AS key,source_text AS text,'source' AS resolved_from FROM ui_messages WHERE project_id=? AND status='active' ORDER BY message_key").bind(c.req.param('projectId')).all(); return success(c,{messages:rows.results});
});
localization.post('/projects/:projectId/locales', requireAuth, async (c) => {
  const body=await c.req.json<Record<string,unknown>>().catch(()=>({}));const code=typeof body.language_locale_code==='string'?body.language_locale_code.trim():'';if(!code)return badRequest(c,'INVALID_LANGUAGE_LOCALE_CODE');const locale=await c.env.DB.prepare('SELECT id FROM language_locales WHERE code=?').bind(code).first<{id:number}>();if(!locale)return badRequest(c,'INVALID_LANGUAGE_LOCALE_CODE');await c.env.DB.prepare("INSERT OR IGNORE INTO ui_locales(project_id,locale_id,status,created_by) VALUES(?,?,'draft',?)").bind(c.req.param('projectId'),locale.id,c.get('user')!.id).run();const rows=await localeRows(c.env.DB,c.req.param('projectId'));const row=rows.results.find((item:any)=>item.language_locale_code===code);return created(c,row);
});
localization.post('/projects/:projectId/mappings', requireAuth, async (c) => {
  const body=await c.req.json<Record<string,unknown>>().catch(()=>({}));const key=typeof body.message_key==='string'?body.message_key:'';const target=typeof body.target_expression_id==='string'?parseIntegerId(body.target_expression_id):null;if(!key||!target)return badRequest(c,'VALIDATION_FAILED');const source=await c.env.DB.prepare('SELECT source_expression_id FROM ui_messages WHERE project_id=? AND message_key=? AND status=\'active\'').bind(c.req.param('projectId'),key).first<{source_expression_id:number}>();if(!source)return notFound(c,'Message');try{const result=await createEdge(c.env.DB,{expression_a_id:source.source_expression_id,expression_b_id:target,relation_mask:1,created_by:c.get('user')!.id});return success(c,{...result,edge:{...result.edge,id:serializeIntegerId(result.edge.id)}})}catch(error){return error instanceof MappingError?badRequest(c,error.code):badRequest(c,'MAPPING_FAILED')}
});
localization.post('/projects/:projectId/locales/:code/activate',requireAuth,async(c)=>{if(c.get('user')!.role!=='admin')return forbidden(c);const row=await c.env.DB.prepare("UPDATE ui_locales SET status='active',activation_source='manual',activated_at=CURRENT_TIMESTAMP,activated_by=? WHERE project_id=? AND locale_id=(SELECT id FROM language_locales WHERE code=?) RETURNING locale_id").bind(c.get('user')!.id,c.req.param('projectId'),c.req.param('code')).first();if(!row)return notFound(c,'UI locale');return success(c,{activated:true})});
localization.post('/projects/:projectId/locales/:code/archive',requireAuth,async(c)=>{if(c.get('user')!.role!=='admin')return forbidden(c);const row=await c.env.DB.prepare("UPDATE ui_locales SET status='archived' WHERE project_id=? AND locale_id=(SELECT id FROM language_locales WHERE code=?) RETURNING locale_id").bind(c.req.param('projectId'),c.req.param('code')).first();if(!row)return notFound(c,'UI locale');return success(c,{archived:true})});
export default localization;
