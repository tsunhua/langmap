import { Hono } from 'hono';
import { optionalAuth, requireAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFound, paginated, success } from '../utils/response';
import { parseIntegerId, serializeIntegerId } from '../utils/ids';
import type { Bindings, Variables } from '../types';

const handbooks = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const page = (value: string | undefined) => Math.min(Math.max(Number.parseInt(value ?? '20', 10) || 20, 1), 100);
const numberId = (value: string) => parseIntegerId(value);

handbooks.get('/', optionalAuth, async (c) => {
  const limit=page(c.req.query('limit')); const skip=Math.max(Number.parseInt(c.req.query('offset') ?? c.req.query('skip') ?? '0',10)||0,0); const hot=c.req.query('sort')==='hot';
  const count=await c.env.DB.prepare("SELECT COUNT(*) AS total FROM handbooks WHERE visibility='public'").first<{total:number}>(); const rows=await c.env.DB.prepare(`SELECT h.id,h.title,h.visibility,h.status,h.score,h.created_at,h.updated_at,u.username AS author_username,(SELECT COUNT(*) FROM handbook_sections s WHERE s.handbook_id=h.id) AS section_count,(SELECT COUNT(*) FROM handbook_section_items i JOIN handbook_sections s ON s.id=i.section_id WHERE s.handbook_id=h.id) AS expression_count FROM handbooks h JOIN users u ON u.id=h.user_id WHERE h.visibility='public' ORDER BY ${hot?'h.score DESC,h.created_at DESC,h.id':'h.created_at DESC,h.id'} LIMIT ? OFFSET ?`).bind(limit,skip).all<any>();
  return paginated(c,rows.results.map((row) => ({...row,id:serializeIntegerId(row.id)})),count?.total ?? 0,skip,limit);
});

handbooks.get('/:id', optionalAuth, async (c) => {
  const id=numberId(c.req.param('id')); if(!id)return badRequest(c,'INVALID_HANDBOOK_ID'); const handbook=await c.env.DB.prepare('SELECT h.*,u.username AS author_username FROM handbooks h JOIN users u ON u.id=h.user_id WHERE h.id=?').bind(id).first<any>(); if(!handbook)return notFound(c,'Handbook'); const user=c.get('user'); if(handbook.visibility==='private'&&user?.id!==handbook.user_id&&user?.role!=='admin')return notFound(c,'Handbook');
  const sections=await c.env.DB.prepare('SELECT id,title,position,parent_section_id FROM handbook_sections WHERE handbook_id=? ORDER BY position,id').bind(id).all<any>(); const items=await c.env.DB.prepare('SELECT i.section_id,i.position,e.id,e.text,l.code AS lang_code FROM handbook_section_items i JOIN handbook_sections s ON s.id=i.section_id JOIN expressions e ON e.id=i.expression_id JOIN languages l ON l.id=e.language_id WHERE s.handbook_id=? ORDER BY i.section_id,i.position').bind(id).all<any>();
  return success(c,{...handbook,id:serializeIntegerId(handbook.id),sections:sections.results.map((section)=>({...section,id:serializeIntegerId(section.id),parent_section_id:section.parent_section_id===null?null:serializeIntegerId(section.parent_section_id),items:items.results.filter((item)=>item.section_id===section.id).map((item)=>({...item,id:serializeIntegerId(item.id),section_id:serializeIntegerId(item.section_id),language_name:item.lang_code}))}))});
});

handbooks.post('/', requireAuth, async (c) => {
  try { const body=await c.req.json<Record<string,unknown>>().catch(()=>({})); const title=typeof body.title==='string'?body.title.trim():''; if(!title)return badRequest(c,'VALIDATION_FAILED'); const handbook=await c.env.DB.prepare("INSERT INTO handbooks(user_id,title,visibility,status) VALUES(?,?,?,?) RETURNING id").bind(c.get('user')!.id,title,body.visibility==='private'?'private':'public',body.status==='draft'?'draft':'published').first<{id:number}>(); if(!handbook)throw new Error('HANDBOOK_CREATE_FAILED'); return created(c,{id:serializeIntegerId(handbook.id)}); } catch(error){console.error(error);return internalError(c);}
});

handbooks.put('/:id', requireAuth, async (c) => {
  const id=numberId(c.req.param('id'));if(!id)return badRequest(c,'INVALID_HANDBOOK_ID');const current=await c.env.DB.prepare('SELECT user_id FROM handbooks WHERE id=?').bind(id).first<{user_id:number}>();if(!current)return notFound(c,'Handbook');if(current.user_id!==c.get('user')!.id&&c.get('user')!.role!=='admin')return forbidden(c);const body=await c.req.json<Record<string,unknown>>().catch(()=>({}));const title=typeof body.title==='string'?body.title.trim():null;if(title==='')return badRequest(c,'VALIDATION_FAILED');await c.env.DB.prepare('UPDATE handbooks SET title=COALESCE(?,title),visibility=COALESCE(?,visibility),status=COALESCE(?,status),updated_at=CURRENT_TIMESTAMP WHERE id=?').bind(title,body.visibility===undefined?null:body.visibility==='private'?'private':'public',body.status===undefined?null:body.status==='draft'?'draft':'published',id).run();return success(c,{id:serializeIntegerId(id)});
});

handbooks.post('/:id/vote', requireAuth, async (c) => {
  const id=numberId(c.req.param('id'));if(!id)return badRequest(c,'INVALID_HANDBOOK_ID'); const body=await c.req.json<Record<string,unknown>>().catch(()=>({})); const vote=body.vote;if(vote!==1&&vote!==-1)return badRequest(c,'VOTE_INVALID_VALUE'); const exists=await c.env.DB.prepare('SELECT 1 FROM handbooks WHERE id=?').bind(id).first();if(!exists)return notFound(c,'Handbook'); await c.env.DB.batch([c.env.DB.prepare('INSERT INTO handbook_votes(user_id,handbook_id,vote) VALUES(?,?,?) ON CONFLICT(user_id,handbook_id) DO UPDATE SET vote=excluded.vote').bind(c.get('user')!.id,id,vote),c.env.DB.prepare('UPDATE handbooks SET score=(SELECT COALESCE(SUM(vote),0) FROM handbook_votes WHERE handbook_id=?) WHERE id=?').bind(id,id)]); const score=await c.env.DB.prepare('SELECT score FROM handbooks WHERE id=?').bind(id).first<{score:number}>();return success(c,{score:score?.score ?? 0,user_vote:vote});
});

handbooks.delete('/:id', requireAuth, async (c) => { const id=numberId(c.req.param('id'));if(!id)return badRequest(c,'INVALID_HANDBOOK_ID');const current=await c.env.DB.prepare('SELECT user_id FROM handbooks WHERE id=?').bind(id).first<{user_id:number}>();if(!current)return notFound(c,'Handbook');if(current.user_id!==c.get('user')!.id&&c.get('user')!.role!=='admin')return forbidden(c);await c.env.DB.prepare('DELETE FROM handbooks WHERE id=?').bind(id).run();return success(c,{deleted:true}); });
export default handbooks;
