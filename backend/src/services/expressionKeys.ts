import type { D1Database } from '@cloudflare/workers-types';
import { EXPRESSION_COLUMNS } from './expressions';
import type { ExpressionRow } from '../types/expression';

export interface ExpressionKey { lang_code: string; text: string; homograph_index: number }

const LANG_CODE_PATTERN = /^[A-Za-z0-9-]+$/;

/**
 * Parses the decoded path segments of an expression key. The homograph suffix
 * is the LAST `~<digits>` run in the text segment, so texts that literally end
 * in `~2` are addressed as `~2~1` (see the spec's suffix disambiguation rule).
 */
export function parseExpressionKey(lang: string, text: string): ExpressionKey | null {
  if (!LANG_CODE_PATTERN.test(lang)) return null;
  const match = /^(.*)~(\d+)$/s.exec(text);
  if (!match) return { lang_code: lang.toLowerCase(), text, homograph_index: 1 };
  const homographIndex = Number(match[2]);
  if (!Number.isSafeInteger(homographIndex) || homographIndex < 1) return null;
  return { lang_code: lang.toLowerCase(), text: match[1], homograph_index: homographIndex };
}

export async function resolveExpressionKey(db: D1Database, key: ExpressionKey): Promise<ExpressionRow | null> {
  const row = await db.prepare(
    `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`,
  ).bind(key.lang_code, key.text, key.homograph_index).first<ExpressionRow>();
  return row ?? null;
}
