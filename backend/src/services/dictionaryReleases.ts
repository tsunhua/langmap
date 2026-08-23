import type { D1Database } from '@cloudflare/workers-types';
import type { PartOfSpeechDto } from '../types/dictionaryRelease';
import { activeReleasePredicate } from './dictionaryReleaseEligibility';

export async function listExpressionPartsOfSpeech(
  db: D1Database,
  expressionId: string,
): Promise<PartOfSpeechDto[]> {
  const { results } = await db.prepare(
    `SELECT pos.code, pos.name_en, pos.sort_order
     FROM expression_pos_attestations pa
     JOIN parts_of_speech pos ON pos.code = pa.pos_code
     WHERE pa.expression_id = ?
       AND ${activeReleasePredicate('pa.release_id')}
     GROUP BY pos.code, pos.name_en, pos.sort_order
     ORDER BY pos.sort_order ASC, pos.code ASC`,
  ).bind(expressionId).all<PartOfSpeechDto & { sort_order: number }>();
  return results.map(({ code, name_en }) => ({ code, name_en }));
}
