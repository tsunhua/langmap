import type { D1Database } from '@cloudflare/workers-types';
import { escapeLike } from './languageIdentity';

export interface WorkbenchCandidate {
  edge_id: string;
  target_expression_id: string;
  text: string;
  score: number;
  created_at: string;
  placeholders_ok: boolean;
}

export interface WorkbenchMessage {
  key: string;
  source_expression_id: string;
  source_text: string;
  placeholders: string[];
  candidates: WorkbenchCandidate[];
}

interface MessageRow {
  message_key: string;
  source_expression_id: string;
  source_text: string;
  placeholders_json: string;
}

interface CandidateRow {
  message_key: string;
  placeholders_json: string;
  target_id: string;
  target_text: string;
  edge_id: string;
  score: number;
  created_at: string;
}

const CANDIDATES_PER_PAGE_LIMIT = 500;
const CANDIDATES_PER_KEY_LIMIT = 5;

const COUNT_SQL = "SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ? AND (? = '' OR message_key LIKE ? ESCAPE '\\' OR source_text LIKE ? ESCAPE '\\')";

const PAGE_SQL = "SELECT message_key, source_expression_id, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? AND (? = '' OR message_key LIKE ? ESCAPE '\\' OR source_text LIKE ? ESCAPE '\\') ORDER BY message_key ASC LIMIT ? OFFSET ?";

const LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';

const CANDIDATES_SQL = `SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND m.message_key IN (SELECT value FROM json_each(?)) AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC LIMIT ${CANDIDATES_PER_PAGE_LIMIT}`;

function parsePlaceholders(placeholdersJson: string): string[] {
  try {
    const parsed: unknown = JSON.parse(placeholdersJson);
    return Array.isArray(parsed) ? (parsed as string[]).slice().sort() : [];
  } catch {
    return [];
  }
}

function extractPlaceholders(text: string): string[] {
  return Array.from(text.matchAll(/\{(\w+)\}/g)).map((match) => match[1]).sort();
}

export async function loadWorkbenchMessages(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
  options: { limit: number; offset: number; q?: string },
): Promise<{ items: WorkbenchMessage[]; total: number }> {
  const q = (options.q ?? '').trim();
  const like = q ? `%${escapeLike(q)}%` : '';

  const totalRow = await db
    .prepare(COUNT_SQL)
    .bind(projectId, 'active', q, like, like)
    .first<{ total: number }>();
  const total = totalRow?.total ?? 0;

  const { results: messageRows } = await db
    .prepare(PAGE_SQL)
    .bind(projectId, 'active', q, like, like, options.limit, options.offset)
    .all<MessageRow>();

  const items: WorkbenchMessage[] = messageRows.map((row) => ({
    key: row.message_key,
    source_expression_id: row.source_expression_id,
    source_text: row.source_text,
    placeholders: parsePlaceholders(row.placeholders_json),
    candidates: [],
  }));

  if (items.length === 0) return { items, total };

  const langRow = await db
    .prepare(LANG_SQL)
    .bind(languageLocaleCode)
    .first<{ lang_code: string }>();
  if (!langRow) return { items, total };

  const keys = items.map((item) => item.key);
  const { results: candidateRows } = await db
    .prepare(CANDIDATES_SQL)
    .bind(projectId, 'active', JSON.stringify(keys), langRow.lang_code, languageLocaleCode)
    .all<CandidateRow>();

  const byKey = new Map(items.map((item) => [item.key, item]));
  for (const row of candidateRows) {
    const item = byKey.get(row.message_key);
    if (!item) continue;
    if (item.candidates.length >= CANDIDATES_PER_KEY_LIMIT) continue;
    item.candidates.push({
      edge_id: row.edge_id,
      target_expression_id: row.target_id,
      text: row.target_text,
      score: row.score,
      created_at: row.created_at,
      placeholders_ok:
        JSON.stringify(parsePlaceholders(row.placeholders_json)) === JSON.stringify(extractPlaceholders(row.target_text)),
    });
  }

  return { items, total };
}
