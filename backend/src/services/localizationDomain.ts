import type { D1Database } from '@cloudflare/workers-types';

export interface BundleEntry {
  key: string;
  text: string;
  resolved_from: 'primary' | 'secondary' | 'source';
}

interface CandidateRow {
  message_key: string;
  placeholders_json: string;
  target_id: number;
  target_text: string;
  score: number;
}

const ACTIVE_MESSAGES_SQL = 'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC';

// A UI translation is an expression linked directly to its English source and
// attested in the requested full locale. Both edge orientations are possible.
export const CANDIDATE_SQL = `WITH candidate_rows AS (
  SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.score
  FROM ui_messages m
  JOIN expression_edges e ON e.expression_a_id = m.source_expression_id
  JOIN expressions t ON t.id = e.expression_b_id
  WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND (e.relation_mask & 3) <> 0
    AND t.language_id = (SELECT language_id FROM language_locales WHERE code = ?)
    AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id = x.locale_id WHERE x.expression_id = t.id AND l.code = ?)
  UNION ALL
  SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.score
  FROM ui_messages m
  JOIN expression_edges e ON e.expression_b_id = m.source_expression_id
  JOIN expressions t ON t.id = e.expression_a_id
  WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND (e.relation_mask & 3) <> 0
    AND t.language_id = (SELECT language_id FROM language_locales WHERE code = ?)
    AND EXISTS (SELECT 1 FROM expression_locale_links x JOIN language_locales l ON l.id = x.locale_id WHERE x.expression_id = t.id AND l.code = ?)
) SELECT message_key, placeholders_json, target_id, target_text, score
  FROM candidate_rows
  ORDER BY message_key ASC, score DESC, target_id ASC`;

function placeholdersMatch(placeholdersJson: string, targetText: string): boolean {
  try {
    const source = JSON.parse(placeholdersJson);
    const expected = Array.isArray(source) ? [...source].sort() : [];
    const actual = Array.from(targetText.matchAll(/\{(\w+)\}/g), match => match[1]).sort();
    return JSON.stringify(expected) === JSON.stringify(actual);
  } catch {
    return false;
  }
}

async function loadCandidates(db: D1Database, projectId: string, localeCode: string): Promise<Map<string, string>> {
  const { results } = await db.prepare(CANDIDATE_SQL)
    .bind(projectId, 'active', localeCode, localeCode, projectId, 'active', localeCode, localeCode)
    .all<CandidateRow>();
  const selected = new Map<string, string>();
  for (const row of results) {
    if (!selected.has(row.message_key) && placeholdersMatch(row.placeholders_json, row.target_text)) {
      selected.set(row.message_key, row.target_text);
    }
  }
  return selected;
}

async function activeCandidates(db: D1Database, projectId: string, localeCode: string): Promise<Map<string, string>> {
  const locale = await db.prepare(
    'SELECT status FROM ui_locales WHERE project_id = ? AND locale_id = (SELECT id FROM language_locales WHERE code = ?)',
  ).bind(projectId, localeCode).first<{ status: string }>();
  return locale?.status === 'active' ? loadCandidates(db, projectId, localeCode) : new Map();
}

export async function resolveBundle(
  db: D1Database,
  projectId: string,
  primary?: string,
  secondary?: string,
): Promise<BundleEntry[]> {
  const { results: messages } = await db.prepare(ACTIVE_MESSAGES_SQL).bind(projectId, 'active')
    .all<{ message_key: string; source_text: string; placeholders_json: string }>();
  const [primaryCandidates, secondaryCandidates] = await Promise.all([
    primary ? activeCandidates(db, projectId, primary) : new Map<string, string>(),
    secondary && secondary !== primary ? activeCandidates(db, projectId, secondary) : new Map<string, string>(),
  ]);
  return messages.map((message) => {
    const primaryText = primaryCandidates.get(message.message_key);
    if (primaryText !== undefined) return { key: message.message_key, text: primaryText, resolved_from: 'primary' as const };
    const secondaryText = secondaryCandidates.get(message.message_key);
    if (secondaryText !== undefined) return { key: message.message_key, text: secondaryText, resolved_from: 'secondary' as const };
    return { key: message.message_key, text: message.source_text, resolved_from: 'source' as const };
  });
}
