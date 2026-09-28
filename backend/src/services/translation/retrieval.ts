import type { Database } from '../../db/database';
import {
  APPROVED_PIVOT_LANGUAGES, MAX_DIRECT_PATHS_PER_ROOT, MAX_EVIDENCE_SERIALIZED_BYTES,
  MAX_EVIDENCE_TOTAL, MAX_PLANNER_SPANS, MAX_PREFIX_CANDIDATES_PER_ROOT, RETRIEVAL_TIMEOUT_MS,
} from '../../utils/limits';
import { canonicalizeExpressionText, expressionPrefixUpperBound } from '../expressionIdentity';
import { edgePassesSql, hasPassingEdge } from './exactMatch';
import { fetchExpressionLocaleCodes } from './localeMetadata';
import { localeRankSql } from './localeRanking';
import { resolveTargetLocale, utf8ByteLength, type TargetLocaleResolution } from './validation';
import type { PlannerSpan, RetrievalOutput, TranslationEvidence, EvidenceMatchType } from './types';

export interface RetrievalLimits {
  maxPlannerSpans: number;
  maxPrefixCandidatesPerRoot: number;
  maxPathsPerRoot: number;
  maxEvidenceTotal: number;
  maxEvidenceSerializedBytes: number;
  timeoutMs: number;
  approvedPivotLanguages: readonly string[];
}
export const DEFAULT_RETRIEVAL_LIMITS: RetrievalLimits = {
  maxPlannerSpans: MAX_PLANNER_SPANS, maxPrefixCandidatesPerRoot: MAX_PREFIX_CANDIDATES_PER_ROOT,
  maxPathsPerRoot: MAX_DIRECT_PATHS_PER_ROOT, maxEvidenceTotal: MAX_EVIDENCE_TOTAL,
  maxEvidenceSerializedBytes: MAX_EVIDENCE_SERIALIZED_BYTES, timeoutMs: RETRIEVAL_TIMEOUT_MS,
  approvedPivotLanguages: APPROVED_PIVOT_LANGUAGES,
};
export interface RetrievalRequest {
  fullText: string;
  spans: PlannerSpan[];
  sourceLangCode: string;
  targetLocaleCode: string;
  targetLocale?: TargetLocaleResolution;
  limits?: RetrievalLimits;
  signal?: AbortSignal;
}
interface Candidate {
  root_index: number;
  expression_id: number;
  expression_text: string;
  match_type: EvidenceMatchType;
  similarity: number;
}
interface PathRow {
  root_index: number;
  source_text: string;
  match_type: EvidenceMatchType;
  similarity: number;
  locale_rank: number;
  target_expr_id: number;
  target_text: string;
  edge1_id: number;
  edge1_score: number;
  edge1_markers: number;
  edge2_id: number | null;
  edge2_score: number;
  edge2_markers: number;
  pivot_lang_code?: string;
}
interface MarkerRow { edge_id: number; source_name: string; marker: string }
const empty = (failed = false): RetrievalOutput => ({
  items: [], omitted_count: 0, degraded: failed, retrieval_status: failed ? 'failed' : 'no_match',
});
const MATCH_RANK: Record<EvidenceMatchType, number> = { exact: 0, prefix: 1, fuzzy: 2 };
const RELATION_MASK = 1 | 2 | 4;
const MAX_FUZZY_ROOTS = 3;
const MIN_FUZZY_SIMILARITY = 0.55;

function rootsFor(input: RetrievalRequest, limits: RetrievalLimits): string[] {
  return [...new Set([input.fullText, ...input.spans.slice(0, limits.maxPlannerSpans).map((span) => span.text)]
    .map(canonicalizeExpressionText).filter(Boolean))];
}
function rootsSql(roots: Array<{ index: number; text: string }>): { sql: string; args: unknown[] } {
  return {
    sql: `WITH roots(root_index, root_text) AS (VALUES ${roots.map(() => '(?::int, ?::text)').join(',')})`,
    args: roots.flatMap((root) => [root.index, root.text]),
  };
}
async function candidatesFor(
  db: Database, roots: string[], sourceLangCode: string, limits: RetrievalLimits,
  check: () => void,
): Promise<Candidate[]> {
  const batch = rootsSql(roots.map((text, index) => ({ index, text })));
  const exact = await db.prepare(`${batch.sql}
    SELECT r.root_index, e.id AS expression_id, e.text AS expression_text,
      'exact'::text AS match_type, 1.0::real AS similarity
    FROM roots r JOIN expressions e ON e.text = r.root_text
    JOIN languages sl ON sl.id = e.language_id WHERE sl.code = ?
    ORDER BY r.root_index, e.id`).bind(...batch.args, sourceLangCode).all<Candidate>();
  check();
  const matched = new Set(exact.results.map((row) => row.root_index));
  const missing = roots.map((text, index) => ({ index, text })).filter((root) => !matched.has(root.index));
  if (!missing.length || limits.maxPrefixCandidatesPerRoot <= 0) return exact.results;

  // Only a few short failed roots receive spelling tolerance. The full sentence
  // is not a fuzzy dictionary needle unless it is itself a single word.
  const fuzzyRoots = new Set(missing.filter((root) => {
    const chars = Array.from(root.text);
    return chars.length >= 3 && chars.length <= 64 &&
      (root.index !== 0 || !/\s/u.test(root.text)) &&
      chars.filter((char) => /[\p{L}\p{N}]/u.test(char)).length >= 3;
  }).slice(0, MAX_FUZZY_ROOTS).map((root) => root.index));
  const values = missing.map(() => '(?::int, ?::text, ?::text, ?::boolean)').join(',');
  const args = missing.flatMap((root) => [root.index, root.text, expressionPrefixUpperBound(root.text), fuzzyRoots.has(root.index)]);
  const fallback = await db.prepare(`WITH roots(root_index, root_text, upper_bound, fuzzy_allowed) AS (VALUES ${values})
    SELECT r.root_index, candidate.* FROM roots r CROSS JOIN LATERAL (
      SELECT found.* FROM (
        SELECT e.id AS expression_id, e.text AS expression_text, 'prefix'::text AS match_type,
          similarity(e.text, r.root_text) AS similarity
        FROM expressions e JOIN languages sl ON sl.id = e.language_id
        WHERE sl.code = ? AND char_length(e.text) <= char_length(r.root_text) + 8
          AND e.text >= r.root_text AND (r.upper_bound IS NULL OR e.text < r.upper_bound)
        UNION ALL
        SELECT e.id AS expression_id, e.text AS expression_text, 'fuzzy'::text AS match_type,
          similarity(e.text, r.root_text) AS similarity
        FROM expressions e JOIN languages sl ON sl.id = e.language_id
        WHERE sl.code = ? AND r.fuzzy_allowed
          AND char_length(e.text) <= char_length(r.root_text) + 8
          AND e.text % r.root_text AND similarity(e.text, r.root_text) >= ${MIN_FUZZY_SIMILARITY}
          AND NOT (e.text >= r.root_text AND (r.upper_bound IS NULL OR e.text < r.upper_bound))
      ) found
      ORDER BY CASE WHEN found.match_type = 'prefix' THEN 0 ELSE 1 END,
        found.similarity DESC, char_length(found.expression_text), found.expression_text, found.expression_id LIMIT ?
    ) candidate ORDER BY r.root_index, candidate.match_type, candidate.similarity DESC, candidate.expression_id`)
    .bind(...args, sourceLangCode, sourceLangCode, limits.maxPrefixCandidatesPerRoot).all<Candidate>();
  check();
  return [...exact.results, ...fallback.results];
}
function candidateTable(candidates: Candidate[]): { sql: string; args: unknown[] } {
  return {
    sql: `WITH candidates(root_index, expression_id, source_text, match_type, similarity) AS (VALUES ${candidates.map(() => '(?::int, ?::bigint, ?::text, ?::text, ?::real)').join(',')})`,
    args: candidates.flatMap((row) => [row.root_index, row.expression_id, row.expression_text, row.match_type, row.similarity]),
  };
}
async function directPaths(db: Database, candidates: Candidate[], locale: TargetLocaleResolution, limits: RetrievalLimits): Promise<PathRow[]> {
  const batch = candidateTable(candidates);
  const { results } = await db.prepare(`${batch.sql}
    SELECT c.root_index, c.source_text, c.match_type, c.similarity, path.*
    FROM candidates c CROSS JOIN language_locales requested CROSS JOIN LATERAL (
      SELECT tgt.id AS target_expr_id, tgt.text AS target_text, ${localeRankSql('tgt')} AS locale_rank,
        edge.id AS edge1_id, edge.score AS edge1_score,
        (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge.id) AS edge1_markers,
        NULL::bigint AS edge2_id, 0::bigint AS edge2_score, 0::bigint AS edge2_markers
      FROM expressions e JOIN expression_edges edge ON (edge.expression_a_id = e.id OR edge.expression_b_id = e.id)
      JOIN expressions tgt ON tgt.id = CASE WHEN edge.expression_a_id = e.id THEN edge.expression_b_id ELSE edge.expression_a_id END
      WHERE e.id = c.expression_id AND tgt.language_id = ? AND tgt.id <> e.id
        AND (edge.relation_mask & ${RELATION_MASK}) <> 0 AND ${edgePassesSql('edge')}
      ORDER BY locale_rank, edge.score DESC, edge1_markers DESC, char_length(tgt.text), edge.id, tgt.id LIMIT ?
    ) path WHERE requested.id = ? ORDER BY c.root_index, path.locale_rank, path.edge1_id, path.target_expr_id`)
    .bind(...batch.args, locale.language_id, limits.maxPathsPerRoot, locale.locale_id).all<PathRow>();
  return results;
}
async function twoHopPaths(db: Database, candidates: Candidate[], locale: TargetLocaleResolution, source: string, limits: RetrievalLimits): Promise<PathRow[]> {
  if (!candidates.length || !limits.approvedPivotLanguages.length) return [];
  const batch = candidateTable(candidates);
  const { results } = await db.prepare(`${batch.sql}
    SELECT c.root_index, c.source_text, c.match_type, c.similarity, path.*
    FROM candidates c CROSS JOIN language_locales requested CROSS JOIN LATERAL (
      SELECT tgt.id AS target_expr_id, tgt.text AS target_text, ${localeRankSql('tgt')} AS locale_rank,
        edge1.id AS edge1_id, edge1.score AS edge1_score,
        (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge1.id) AS edge1_markers,
        edge2.id AS edge2_id, edge2.score AS edge2_score,
        (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge2.id) AS edge2_markers,
        pl.code AS pivot_lang_code
      FROM expressions e JOIN expression_edges edge1 ON (edge1.expression_a_id = e.id OR edge1.expression_b_id = e.id)
      JOIN expressions piv ON piv.id = CASE WHEN edge1.expression_a_id = e.id THEN edge1.expression_b_id ELSE edge1.expression_a_id END
      JOIN languages pl ON pl.id = piv.language_id
      JOIN expression_edges edge2 ON (edge2.expression_a_id = piv.id OR edge2.expression_b_id = piv.id)
      JOIN expressions tgt ON tgt.id = CASE WHEN edge2.expression_a_id = piv.id THEN edge2.expression_b_id ELSE edge2.expression_a_id END
      WHERE e.id = c.expression_id AND tgt.language_id = ? AND tgt.id <> e.id
        AND pl.code IN (${limits.approvedPivotLanguages.map(() => '?').join(',')}) AND pl.code <> ? AND pl.code <> ?
        AND (edge1.relation_mask & ${RELATION_MASK}) <> 0 AND (edge2.relation_mask & ${RELATION_MASK}) <> 0
        AND ${edgePassesSql('edge1')} AND ${edgePassesSql('edge2')}
      ORDER BY locale_rank, edge1.score + edge2.score DESC,
        ((SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge1.id) +
         (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge2.id)) DESC,
        char_length(tgt.text), edge1.id, edge2.id, tgt.id LIMIT ?
    ) path WHERE requested.id = ? ORDER BY c.root_index, path.locale_rank, path.edge1_id, path.edge2_id, path.target_expr_id`)
    .bind(...batch.args, locale.language_id, ...limits.approvedPivotLanguages, source, locale.lang_code, limits.maxPathsPerRoot, locale.locale_id).all<PathRow>();
  return results;
}
function comparePaths(a: PathRow, b: PathRow): number {
  return MATCH_RANK[a.match_type] - MATCH_RANK[b.match_type] || a.locale_rank - b.locale_rank ||
    Number(Boolean(a.edge2_id)) - Number(Boolean(b.edge2_id)) || b.similarity - a.similarity ||
    (b.edge1_score + b.edge2_score) - (a.edge1_score + a.edge2_score) ||
    (b.edge1_markers + b.edge2_markers) - (a.edge1_markers + a.edge2_markers) ||
    a.target_text.length - b.target_text.length || a.root_index - b.root_index ||
    a.edge1_id - b.edge1_id || (a.edge2_id ?? 0) - (b.edge2_id ?? 0) || a.target_expr_id - b.target_expr_id;
}
function passing(row: PathRow, source: string, target: string, limits: RetrievalLimits): boolean {
  if (!hasPassingEdge({ score: row.edge1_score, markerCount: row.edge1_markers })) return false;
  return !row.edge2_id || (hasPassingEdge({ score: row.edge2_score, markerCount: row.edge2_markers }) &&
    Boolean(row.pivot_lang_code && row.pivot_lang_code !== source && row.pivot_lang_code !== target && limits.approvedPivotLanguages.includes(row.pivot_lang_code)));
}
async function retrieve(db: Database, input: RetrievalRequest, check: () => void): Promise<RetrievalOutput> {
  const limits = { ...DEFAULT_RETRIEVAL_LIMITS, ...input.limits };
  const source = input.sourceLangCode?.trim().toLowerCase();
  check();
  if (!source || limits.maxPathsPerRoot <= 0 || limits.maxEvidenceTotal <= 0) return empty();
  const locale = input.targetLocale ?? await resolveTargetLocale(db, input.targetLocaleCode);
  check();
  const roots = rootsFor(input, limits);
  if (!roots.length) return empty();
  const candidates = await candidatesFor(db, roots, source, limits, check);
  if (!candidates.length) return empty();
  const direct = (await directPaths(db, candidates, locale, limits)).filter((row) => passing(row, source, locale.lang_code, limits));
  check();
  const completeRoots = new Set(roots.map((_, index) => index).filter((index) =>
    new Set(direct.filter((row) => row.root_index === index && row.locale_rank === 0).map((row) => row.target_expr_id)).size >= limits.maxPathsPerRoot));
  const twoHop = await twoHopPaths(db, candidates.filter((row) => !completeRoots.has(row.root_index)), locale, source, limits);
  check();
  const seen = new Set<string>();
  const byRoot = new Map<number, number>();
  const ranked = [...direct, ...twoHop].filter((row) => passing(row, source, locale.lang_code, limits)).sort(comparePaths).filter((row) => {
    const key = `${row.source_text}\u0000${row.target_expr_id}\u0000${row.edge1_id}\u0000${row.edge2_id ?? ''}`;
    const count = byRoot.get(row.root_index) ?? 0;
    if (seen.has(key) || count >= limits.maxPathsPerRoot) return false;
    seen.add(key); byRoot.set(row.root_index, count + 1); return true;
  });
  const retained = ranked.slice(0, limits.maxEvidenceTotal);
  if (!retained.length) return empty();
  const ids = [...new Set(retained.flatMap((row) => row.edge2_id ? [row.edge1_id, row.edge2_id] : [row.edge1_id]))];
  const { results } = await db.prepare(`SELECT es.edge_id, s.name AS source_name, es.source_marker AS marker
    FROM expression_edge_sources es JOIN sources s ON s.id = es.source_id
    WHERE es.edge_id IN (${ids.map(() => '?').join(',')}) ORDER BY es.edge_id, es.source_id, es.source_marker`).bind(...ids).all<MarkerRow>();
  check();
  const markers = new Map<number, string[]>();
  for (const row of results) {
    const list = markers.get(row.edge_id) ?? [];
    if (list.length < 4) list.push(row.marker ? `${row.source_name}#${row.marker}` : row.source_name);
    markers.set(row.edge_id, list);
  }
  const locales = await fetchExpressionLocaleCodes(db, retained.map((row) => row.target_expr_id));
  check();
  const items: TranslationEvidence[] = [];
  for (const row of retained) {
    const item: TranslationEvidence = {
      source_text: row.source_text, target_text: row.target_text, target_locale_code: input.targetLocaleCode,
      reference_locale_codes: locales.get(row.target_expr_id) ?? [],
      path_type: row.edge2_id ? 'two_hop' : 'direct', match_type: row.match_type,
      ...(row.pivot_lang_code ? { pivot_lang_code: row.pivot_lang_code } : {}),
      source_markers: [...(markers.get(row.edge1_id) ?? []), ...(row.edge2_id ? markers.get(row.edge2_id) ?? [] : [])],
    };
    if (utf8ByteLength(JSON.stringify([...items, item])) <= limits.maxEvidenceSerializedBytes) items.push(item);
  }
  return { items, omitted_count: ranked.length - items.length, degraded: false, retrieval_status: items.length ? 'matched' : 'no_match' };
}

export async function retrieveEvidence(db: Database, input: RetrievalRequest): Promise<RetrievalOutput> {
  const timeoutMs = input.limits?.timeoutMs ?? DEFAULT_RETRIEVAL_LIMITS.timeoutMs;
  const controller = new AbortController();
  const abort = () => controller.abort();
  input.signal?.addEventListener('abort', abort, { once: true });
  if (input.signal?.aborted) abort();
  const check = () => {
    if (controller.signal.aborted) throw new DOMException('Retrieval interrupted', 'AbortError');
  };
  let onInterrupt: () => void = () => {};
  const interrupted = new Promise<never>((_, reject) => {
    onInterrupt = () => reject(new DOMException('Retrieval interrupted', 'AbortError'));
    controller.signal.addEventListener('abort', onInterrupt, { once: true });
  });
  const timer = setTimeout(abort, Math.max(0, timeoutMs));
  try {
    check();
    // race also observes late rejection; check() prevents expired work from
    // starting another query after an already submitted statement settles.
    return await Promise.race([retrieve(db, input, check), interrupted]);
  } catch {
    if (input.signal?.aborted) throw new DOMException('The operation was aborted.', 'AbortError');
    return empty(true);
  } finally {
    clearTimeout(timer);
    controller.signal.removeEventListener('abort', onInterrupt);
    input.signal?.removeEventListener('abort', abort);
  }
}
