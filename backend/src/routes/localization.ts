import { Hono } from 'hono';
import { requireAuth, optionalAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFound, success, unauthorized } from '../utils/response';
import {
  LocalizationError,
  activateLocale,
  archiveLocale,
  computeCoverage,
  recalculateForExpressions,
  recalculateLocale,
  resolveBundle,
} from '../services/localizationDomain';
import { MappingError, createEdge } from '../services/mappings';
import { VoteError, castVote } from '../services/votes';
import { getPreferences } from '../services/preferences';
import { parseLanguageLocaleCode } from '../services/languageIdentity';
import { loadWorkbenchMessages } from '../services/workbench';
import type { Bindings, Variables } from '../types';

const LOCALE_LIST_LIMIT = 200;
const WORKBENCH_PAGE_LIMIT = 100;
const WORKBENCH_MAX_LIMIT = 200;
const WORKBENCH_MAX_Q = 80;

function parseWorkbenchQuery(c: { req: { query: (key: string) => string | undefined } }): { q: string; limit: number; offset: number } {
  const limitRaw = Number(c.req.query('limit') ?? String(WORKBENCH_PAGE_LIMIT));
  const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? Math.trunc(limitRaw) : WORKBENCH_PAGE_LIMIT, 1), WORKBENCH_MAX_LIMIT);
  const offset = Math.max(parseInt(c.req.query('skip') ?? c.req.query('offset') ?? '0') || 0, 0);
  return { q: (c.req.query('q') ?? '').slice(0, WORKBENCH_MAX_Q), limit, offset };
}

const localization = new Hono<{ Bindings: Bindings; Variables: Variables }>();

async function localesForLang(db: Bindings['DB'], projectId: string, langCode: string): Promise<string[]> {
  const { results } = await db
    .prepare('SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ? ORDER BY language_locale_code ASC LIMIT ?')
    .bind(projectId, `${langCode}-%`, LOCALE_LIST_LIMIT)
    .all<{ language_locale_code: string }>();
  return results.map((row) => row.language_locale_code);
}

localization.get('/projects/:projectId/locales', async (c) => {
  const projectId = c.req.param('projectId') ?? '';
  const { results } = await c.env.DB
    .prepare('SELECT project_id, language_locale_code, status, mapping_revision, activation_source, activated_at, activated_by, created_at FROM ui_locales WHERE project_id = ? ORDER BY language_locale_code ASC LIMIT ?')
    .bind(projectId, LOCALE_LIST_LIMIT)
    .all();
  return success(c, results);
});

localization.post('/projects/:projectId/locales', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const code = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    if (!code || !parseLanguageLocaleCode(code)) {
      return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Valid language_locale_code is required');
    }
    try {
      await c.env.DB
        .prepare('INSERT INTO ui_locales (project_id, language_locale_code, status, created_by) VALUES (?, ?, ?, ?)')
        .bind(projectId, code, 'draft', user?.id ?? null)
        .run();
    } catch (error) {
      const msg = String((error as { message?: string })?.message ?? '');
      if (msg.includes('UNIQUE constraint failed') || msg.includes('PRIMARY KEY')) {
        return badRequest(c, 'UI_LOCALE_EXISTS', 'UI locale already exists for this project');
      }
      throw error;
    }
    const row = await c.env.DB
      .prepare('SELECT project_id, language_locale_code, status, mapping_revision, activation_source, created_at FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code)
      .first();
    return created(c, row, 'UI locale created');
  } catch (error) {
    console.error('Create UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create UI locale');
  }
});

localization.post('/projects/:projectId/locales/:code/activate', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    if (user?.role !== 'admin') return forbidden(c, 'FORBIDDEN', 'Activate requires admin role');
    try {
      await activateLocale(c.env.DB, projectId, code, 'manual', user.id);
      return success(c, { activated: true }, 'UI locale activated');
    } catch (error) {
      if (error instanceof LocalizationError) {
        if (error.code === 'UI_LOCALE_NOT_FOUND') return notFound(c, 'UI locale');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Activate UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to activate UI locale');
  }
});

localization.post('/projects/:projectId/locales/:code/archive', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    if (user?.role !== 'admin') return forbidden(c, 'FORBIDDEN', 'Archive requires admin role');
    try {
      await archiveLocale(c.env.DB, projectId, code, user.id);
      return success(c, { archived: true }, 'UI locale archived');
    } catch (error) {
      if (error instanceof LocalizationError) {
        if (error.code === 'UI_LOCALE_NOT_FOUND') return notFound(c, 'UI locale');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Archive UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to archive UI locale');
  }
});

localization.get('/projects/:projectId/workbench/:code', requireAuth, async (c) => {
  try {
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    const locale = await c.env.DB
      .prepare('SELECT status, mapping_revision, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code)
      .first<{ status: string; mapping_revision: number; activation_source: string | null }>();
    if (!locale) return notFound(c, 'UI locale');
    const coverage = await computeCoverage(c.env.DB, projectId, code);
    const query = parseWorkbenchQuery(c);
    const messages = await loadWorkbenchMessages(c.env.DB, projectId, code, {
      limit: query.limit,
      offset: query.offset,
      q: query.q,
    });
    return success(c, {
      locale,
      coverage,
      messages: messages.items,
      total: messages.total,
      skip: query.offset,
      limit: query.limit,
    });
  } catch (error) {
    console.error('Workbench error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to load workbench');
  }
});

localization.post('/projects/:projectId/mappings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const messageKey = typeof body?.message_key === 'string' ? body.message_key.trim() : '';
    const targetExpressionId = typeof body?.target_expression_id === 'string' ? body.target_expression_id.trim() : '';
    if (!messageKey || !targetExpressionId) {
      return badRequest(c, 'VALIDATION_FAILED', 'message_key and target_expression_id are required');
    }
    const msg = await c.env.DB
      .prepare('SELECT source_expression_id FROM ui_messages WHERE project_id = ? AND message_key = ?')
      .bind(projectId, messageKey)
      .first<{ source_expression_id: string }>();
    if (!msg) return badRequest(c, 'MESSAGE_KEY_NOT_FOUND', 'Unknown message key');

    try {
      const result = await createEdge(c.env.DB, {
        expression_a_id: msg.source_expression_id,
        expression_b_id: targetExpressionId,
        source: 'translation',
        created_by: user?.id ?? 0,
      });
      const targetExpr = await c.env.DB
        .prepare('SELECT lang_code FROM expressions WHERE id = ?')
        .bind(targetExpressionId)
        .first<{ lang_code: string }>();
      if (targetExpr) {
        for (const localeCode of await localesForLang(c.env.DB, projectId, targetExpr.lang_code)) {
          await recalculateLocale(c.env.DB, projectId, localeCode);
        }
      }
      return result.created ? created(c, result, 'Translation mapping created') : success(c, result, 'Translation mapping already exists');
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Create translation mapping error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create translation mapping');
  }
});

localization.post('/projects/:projectId/mappings/batch', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const mappings: unknown[] = Array.isArray(body?.mappings) ? body.mappings : [];
    if (mappings.length === 0) return badRequest(c, 'VALIDATION_FAILED', 'mappings array is required');
    const results: Array<{ message_key: string; created: boolean }> = [];
    const affectedLangs = new Set<string>();
    for (const entry of mappings) {
      const m = entry as { message_key?: unknown; target_expression_id?: unknown };
      const messageKey = typeof m?.message_key === 'string' ? m.message_key.trim() : '';
      const targetExpressionId = typeof m?.target_expression_id === 'string' ? m.target_expression_id.trim() : '';
      if (!messageKey || !targetExpressionId) continue;
      const msg = await c.env.DB
        .prepare('SELECT source_expression_id FROM ui_messages WHERE project_id = ? AND message_key = ?')
        .bind(projectId, messageKey)
        .first<{ source_expression_id: string }>();
      if (!msg) continue;
      const result = await createEdge(c.env.DB, {
        expression_a_id: msg.source_expression_id,
        expression_b_id: targetExpressionId,
        source: 'translation',
        created_by: user?.id ?? 0,
      });
      results.push({ message_key: messageKey, created: result.created });
      const targetExpr = await c.env.DB
        .prepare('SELECT lang_code FROM expressions WHERE id = ?')
        .bind(targetExpressionId)
        .first<{ lang_code: string }>();
      if (targetExpr) affectedLangs.add(targetExpr.lang_code);
    }
    for (const langCode of Array.from(affectedLangs).sort()) {
      for (const localeCode of await localesForLang(c.env.DB, projectId, langCode)) {
        await recalculateLocale(c.env.DB, projectId, localeCode);
      }
    }
    return success(c, { results, count: results.length }, 'Batch translation mappings processed');
  } catch (error) {
    console.error('Batch translation mapping error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to process batch mappings');
  }
});

localization.get('/projects/:projectId/messages', optionalAuth, async (c) => {
  try {
    const projectId = c.req.param('projectId') ?? '';
    let primary = c.req.query('primary') ?? '';
    let secondary = c.req.query('secondary') ?? '';

    if (!primary && !secondary) {
      const user = c.get('user');
      if (user) {
        const prefs = await getPreferences(c.env.DB, user.id);
        const langPrefs = prefs['language.locales'] as { primary?: string; secondary?: string } | undefined;
        if (langPrefs) {
          primary = langPrefs.primary ?? '';
          secondary = langPrefs.secondary ?? '';
        }
      }
    }

    if (primary && !parseLanguageLocaleCode(primary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Invalid primary locale');
    if (secondary && !parseLanguageLocaleCode(secondary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Invalid secondary locale');

    const bundle = await resolveBundle(c.env.DB, projectId, primary || undefined, secondary || undefined);
    return success(c, { messages: bundle });
  } catch (error) {
    console.error('Get messages error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to get messages');
  }
});

localization.post('/projects/:projectId/votes', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const edgeId = typeof (body as { edge_id?: unknown })?.edge_id === 'string' ? (body as { edge_id: string }).edge_id.trim() : '';
    const voteRaw = (body as { vote?: unknown })?.vote;
    const vote = typeof voteRaw === 'number' ? voteRaw : Number(voteRaw);

    if (!edgeId) return badRequest(c, 'VALIDATION_FAILED', 'edge_id is required');

    try {
      const result = await castVote(c.env.DB, {
        target_type: 'edge',
        target_id: edgeId,
        vote,
        user_id: user.id,
      });

      const edge = await c.env.DB
        .prepare('SELECT expression_a_id, expression_b_id FROM expression_edges WHERE id = ?')
        .bind(edgeId)
        .first<{ expression_a_id: string; expression_b_id: string }>();
      if (edge) {
        await recalculateForExpressions(c.env.DB, projectId, [edge.expression_a_id, edge.expression_b_id]);
      }

      return success(c, result, 'Vote recorded');
    } catch (error) {
      if (error instanceof VoteError) {
        if (error.code === 'VOTE_TARGET_NOT_FOUND') return notFound(c, 'Edge');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Vote error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to record vote');
  }
});

export default localization;
