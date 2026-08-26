import type { D1Database } from '@cloudflare/workers-types';
import type { PartOfSpeechDto } from '../types/dictionaryRelease';
import { activeReleasePredicate } from './dictionaryReleaseEligibility';

const PACKED_ID_PATTERN = /^d(\d{8})$/;

function packedTermId(expressionId: string): number | null {
  const match = PACKED_ID_PATTERN.exec(expressionId);
  if (!match) return null;
  const termId = Number.parseInt(match[1], 10);
  return Number.isSafeInteger(termId) && termId > 0 ? termId : null;
}

export async function listExpressionPartsOfSpeech(
  db: D1Database,
  expressionId: string,
): Promise<PartOfSpeechDto[]> {
  const termId = packedTermId(expressionId);
  const packedTermPredicate = termId === null
    ? "('d' || printf('%08d', dt.term_id)) = ?"
    : 'dt.term_id = ?';
  const { results } = await db.prepare(
    `SELECT pos.code, pos.name_en, pos.sort_order
     FROM parts_of_speech pos
     WHERE EXISTS (
       SELECT 1
       FROM expression_pos_attestations pa
       WHERE pa.expression_id = ?
         AND pa.pos_code = pos.code
         AND ${activeReleasePredicate('pa.release_id')}
     )
       OR EXISTS (
         SELECT 1
         FROM dictionary_terms dt
          WHERE ${packedTermPredicate}
            AND ((dt.pos_mask >> (pos.sort_order - 1)) & 1) = 1
       )
     ORDER BY pos.sort_order ASC, pos.code ASC`,
  ).bind(expressionId, termId ?? expressionId).all<PartOfSpeechDto & { sort_order: number }>();
  return results.map(({ code, name_en }) => ({ code, name_en }));
}
