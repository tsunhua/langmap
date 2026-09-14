import type { D1Database } from '@cloudflare/workers-types';
import {
  APPROVED_PIVOT_LANGUAGES,
  MAX_DIRECT_PATHS_PER_ROOT,
  MAX_EVIDENCE_SERIALIZED_BYTES,
  MAX_EVIDENCE_TOTAL,
  MAX_PLANNER_SPANS,
  MAX_PREFIX_CANDIDATES_PER_ROOT,
  RETRIEVAL_TIMEOUT_MS,
} from '../../utils/limits';
import { canonicalizeExpressionText, expressionPrefixUpperBound } from '../expressionIdentity';
import { edgePassesSql, hasPassingEdge } from './exactMatch';
import { resolveTargetLocale, utf8ByteLength } from './validation';
import type { PlannerSpan, RetrievalOutput, TranslationEvidence } from './types';

// Translation edges are mappings; every currently valid relation bit stays
// visible so paraphrase and example edges participate like any other pair.
const RELATION_MASK = 1 | 2 | 4;
// Marker summaries stay bounded per edge; the serialized evidence cap covers the rest.
const MAX_MARKERS_PER_EDGE = 4;

const DEGRADED: RetrievalOutput = { items: [], omitted_count: 0, degraded: true };

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
  maxPlannerSpans: MAX_PLANNER_SPANS,
  maxPrefixCandidatesPerRoot: MAX_PREFIX_CANDIDATES_PER_ROOT,
  maxPathsPerRoot: MAX_DIRECT_PATHS_PER_ROOT,
  maxEvidenceTotal: MAX_EVIDENCE_TOTAL,
  maxEvidenceSerializedBytes: MAX_EVIDENCE_SERIALIZED_BYTES,
  timeoutMs: RETRIEVAL_TIMEOUT_MS,
  approvedPivotLanguages: APPROVED_PIVOT_LANGUAGES,
};

export interface RetrievalRequest {
  fullText: string;
  spans: PlannerSpan[];
  sourceLangCode: string;
  targetLocaleCode: string;
  limits?: RetrievalLimits;
  signal?: AbortSignal;
}

interface CandidateRow {
  expression_id: number;
  expression_text: string;
}

interface RootCandidate {
  id: number;
  text: string;
  matchType: 'exact' | 'prefix';
}

interface DirectRow {
  edge_id: number;
  score: number;
  marker_count: number;
  target_expr_id: number;
  target_text: string;
}

interface TwoHopRow {
  pivot_lang_code: string;
  edge1_id: number;
  edge1_score: number;
  edge1_markers: number;
  edge2_id: number;
  edge2_score: number;
  edge2_markers: number;
  target_expr_id: number;
  target_text: string;
}

interface EdgeMarkerRow {
  edge_id: number;
  source_name: string;
  marker: string;
}

interface InternalHit {
  matchType: 'exact' | 'prefix';
  sourceText: string;
  targetText: string;
  pathType: 'direct' | 'two_hop';
  pivotLangCode?: string;
  score: number;
  markerCount: number;
  firstEdgeId: number;
  secondEdgeId: number;
  targetExprId: number;
}

const EXACT_CANDIDATE_SQL = `SELECT e.id AS expression_id, e.text AS expression_text
FROM expressions e
JOIN languages sl ON sl.id = e.language_id
WHERE e.text = ? AND sl.code = ?
ORDER BY e.id ASC`;

const PREFIX_CANDIDATE_SQL = `SELECT e.id AS expression_id, e.text AS expression_text
FROM expressions e
JOIN languages sl ON sl.id = e.language_id
WHERE e.text >= ? AND e.text < ? AND sl.code = ?
ORDER BY e.text ASC, e.id ASC
LIMIT ?`;

const PREFIX_CANDIDATE_OPEN_ENDED_SQL = `SELECT e.id AS expression_id, e.text AS expression_text
FROM expressions e
JOIN languages sl ON sl.id = e.language_id
WHERE e.text >= ? AND sl.code = ?
ORDER BY e.text ASC, e.id ASC
LIMIT ?`;

const MARKER_COUNT = (alias: string) =>
  `(SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = ${alias}.id)`;

const DIRECT_SQL = `SELECT edge.id AS edge_id, edge.score AS score,
  tgt.id AS target_expr_id, tgt.text AS target_text,
  ${MARKER_COUNT('edge')} AS marker_count
 FROM expressions e
 JOIN expression_edges edge ON (edge.expression_a_id = e.id OR edge.expression_b_id = e.id)
 JOIN expressions tgt ON tgt.id = CASE WHEN edge.expression_a_id = e.id THEN edge.expression_b_id ELSE edge.expression_a_id END
 JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?
 WHERE e.id = ?
   AND tgt.id <> e.id
   AND (edge.relation_mask & ${RELATION_MASK}) <> 0
   AND ${edgePassesSql('edge')}
 ORDER BY edge.score DESC, marker_count DESC, LENGTH(tgt.text) ASC, edge.id ASC, tgt.id ASC
 LIMIT ?`;

function twoHopSql(pivotMarks: string): string {
  return `SELECT piv.id AS pivot_expr_id, piv.text AS pivot_text, pl.code AS pivot_lang_code,
  edge1.id AS edge1_id, edge1.score AS edge1_score, ${MARKER_COUNT('edge1')} AS edge1_markers,
  edge2.id AS edge2_id, edge2.score AS edge2_score, ${MARKER_COUNT('edge2')} AS edge2_markers,
  tgt.id AS target_expr_id, tgt.text AS target_text
 FROM expressions e
 JOIN expression_edges edge1 ON (edge1.expression_a_id = e.id OR edge1.expression_b_id = e.id)
 JOIN expressions piv ON piv.id = CASE WHEN edge1.expression_a_id = e.id THEN edge1.expression_b_id ELSE edge1.expression_a_id END
 JOIN languages pl ON pl.id = piv.language_id
 JOIN expression_edges edge2 ON (edge2.expression_a_id = piv.id OR edge2.expression_b_id = piv.id)
 JOIN expressions tgt ON tgt.id = CASE WHEN edge2.expression_a_id = piv.id THEN edge2.expression_b_id ELSE edge2.expression_a_id END
 JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?
 WHERE e.id = ?
   AND pl.code IN (${pivotMarks})
   AND pl.code <> ?
   AND pl.code <> ?
   AND tgt.id <> e.id
   AND (edge1.relation_mask & ${RELATION_MASK}) <> 0
   AND (edge2.relation_mask & ${RELATION_MASK}) <> 0
   AND ${edgePassesSql('edge1')}
   AND ${edgePassesSql('edge2')}
 ORDER BY edge1.score + edge2.score DESC,
   ${MARKER_COUNT('edge1')} + ${MARKER_COUNT('edge2')} DESC,
   LENGTH(tgt.text) ASC, edge1.id ASC, edge2.id ASC, tgt.id ASC
 LIMIT ?`;
}

function edgeMarkersSql(edgeMarks: string): string {
  return `SELECT es.edge_id AS edge_id, s.name AS source_name, es.source_marker AS marker
FROM expression_edge_sources es
JOIN sources s ON s.id = es.source_id
WHERE es.edge_id IN (${edgeMarks})
ORDER BY es.edge_id ASC, es.source_id ASC, es.source_marker ASC`;
}

function buildRoots(fullText: string, spans: PlannerSpan[], maxPlannerSpans: number): string[] {
  const roots: string[] = [];
  const seen = new Set<string>();
  const add = (raw: string) => {
    const canonical = canonicalizeExpressionText(raw);
    if (!canonical || seen.has(canonical)) return;
    seen.add(canonical);
    roots.push(canonical);
  };
  add(fullText);
  for (const span of spans) {
    if (roots.length >= maxPlannerSpans + 1) break;
    add(span.text);
  }
  return roots;
}

async function findRootCandidates(
  db: D1Database,
  canonical: string,
  sourceLangCode: string,
  limits: RetrievalLimits,
): Promise<RootCandidate[]> {
  const exact = await db.prepare(EXACT_CANDIDATE_SQL).bind(canonical, sourceLangCode).all<CandidateRow>();
  if (exact.results.length > 0) {
    return exact.results.map((row) => ({ id: row.expression_id, text: row.expression_text, matchType: 'exact' }));
  }
  const upper = expressionPrefixUpperBound(canonical);
  const statement =
    upper === null
      ? db.prepare(PREFIX_CANDIDATE_OPEN_ENDED_SQL).bind(canonical, sourceLangCode, limits.maxPrefixCandidatesPerRoot)
      : db.prepare(PREFIX_CANDIDATE_SQL).bind(canonical, upper, sourceLangCode, limits.maxPrefixCandidatesPerRoot);
  const rows = await statement.all<CandidateRow>();
  return rows.results.map((row) => ({ id: row.expression_id, text: row.expression_text, matchType: 'prefix' }));
}

async function queryDirect(
  db: D1Database,
  expressionId: number,
  localeId: number,
  limits: RetrievalLimits,
): Promise<DirectRow[]> {
  const { results } = await db
    .prepare(DIRECT_SQL)
    .bind(localeId, expressionId, limits.maxPathsPerRoot)
    .all<DirectRow>();
  return results;
}

async function queryTwoHop(
  db: D1Database,
  expressionId: number,
  localeId: number,
  targetLangCode: string,
  sourceLangCode: string,
  limits: RetrievalLimits,
): Promise<TwoHopRow[]> {
  const pivots = limits.approvedPivotLanguages;
  const marks = pivots.map(() => '?').join(',');
  const { results } = await db
    .prepare(twoHopSql(marks))
    .bind(localeId, expressionId, ...pivots, targetLangCode, sourceLangCode, limits.maxPathsPerRoot)
    .all<TwoHopRow>();
  return results;
}

function passingDirectHits(candidate: RootCandidate, rows: DirectRow[]): InternalHit[] {
  const hits: InternalHit[] = [];
  for (const row of rows) {
    // SQL enforces the same predicate via edgePassesSql; re-check in JS with
    // hasPassingEdge so a fake or future caller cannot bypass the quality gate.
    if (!hasPassingEdge({ score: row.score, markerCount: row.marker_count })) continue;
    hits.push({
      matchType: candidate.matchType,
      sourceText: candidate.text,
      targetText: row.target_text,
      pathType: 'direct',
      score: row.score,
      markerCount: row.marker_count,
      firstEdgeId: row.edge_id,
      secondEdgeId: row.edge_id,
      targetExprId: row.target_expr_id,
    });
  }
  return hits;
}

function passingTwoHopHits(
  candidate: RootCandidate,
  rows: TwoHopRow[],
  sourceLangCode: string,
  targetLangCode: string,
  limits: RetrievalLimits,
): InternalHit[] {
  const approved = new Set(limits.approvedPivotLanguages);
  const hits: InternalHit[] = [];
  for (const row of rows) {
    if (!approved.has(row.pivot_lang_code)) continue;
    if (row.pivot_lang_code === targetLangCode) continue;
    if (row.pivot_lang_code === sourceLangCode) continue;
    if (!hasPassingEdge({ score: row.edge1_score, markerCount: row.edge1_markers })) continue;
    if (!hasPassingEdge({ score: row.edge2_score, markerCount: row.edge2_markers })) continue;
    hits.push({
      matchType: candidate.matchType,
      sourceText: candidate.text,
      targetText: row.target_text,
      pathType: 'two_hop',
      pivotLangCode: row.pivot_lang_code,
      score: row.edge1_score + row.edge2_score,
      markerCount: row.edge1_markers + row.edge2_markers,
      firstEdgeId: row.edge1_id,
      secondEdgeId: row.edge2_id,
      targetExprId: row.target_expr_id,
    });
  }
  return hits;
}

function compareHits(a: InternalHit, b: InternalHit): number {
  if (a.matchType !== b.matchType) return a.matchType === 'exact' ? -1 : 1;
  if (a.pathType !== b.pathType) return a.pathType === 'direct' ? -1 : 1;
  if (a.score !== b.score) return b.score - a.score;
  if (a.markerCount !== b.markerCount) return b.markerCount - a.markerCount;
  if (a.targetText.length !== b.targetText.length) return a.targetText.length - b.targetText.length;
  if (a.firstEdgeId !== b.firstEdgeId) return a.firstEdgeId - b.firstEdgeId;
  if (a.secondEdgeId !== b.secondEdgeId) return a.secondEdgeId - b.secondEdgeId;
  return a.targetExprId - b.targetExprId;
}

function hitKey(hit: InternalHit): string {
  return `${hit.sourceText}\u0000${hit.targetText}\u0000${hit.pathType}\u0000${hit.pivotLangCode ?? ''}`;
}

function dedupeHits(hits: InternalHit[]): InternalHit[] {
  const seen = new Set<string>();
  const deduped: InternalHit[] = [];
  for (const hit of hits) {
    const key = hitKey(hit);
    if (seen.has(key)) continue;
    seen.add(key);
    deduped.push(hit);
  }
  return deduped;
}

function uniqueEdgeIds(hits: InternalHit[]): number[] {
  return [...new Set(hits.flatMap((hit) => [hit.firstEdgeId, hit.secondEdgeId]))];
}

async function fetchEdgeMarkers(db: D1Database, edgeIds: number[]): Promise<Map<number, string[]>> {
  const byEdge = new Map<number, string[]>();
  if (edgeIds.length === 0) return byEdge;
  // At most MAX_EVIDENCE_TOTAL hits with two edges each stays well under D1's
  // SQLite variable limit, so one batched query covers every evidence edge.
  const marks = edgeIds.map(() => '?').join(',');
  const { results } = await db.prepare(edgeMarkersSql(marks)).bind(...edgeIds).all<EdgeMarkerRow>();
  for (const row of results) {
    const markers = byEdge.get(row.edge_id) ?? [];
    markers.push(row.marker ? `${row.source_name}#${row.marker}` : row.source_name);
    byEdge.set(row.edge_id, markers);
  }
  for (const markers of byEdge.values()) {
    if (markers.length > MAX_MARKERS_PER_EDGE) markers.length = MAX_MARKERS_PER_EDGE;
  }
  return byEdge;
}

function buildEvidence(
  hit: InternalHit,
  targetLocaleCode: string,
  markersByEdge: Map<number, string[]>,
): TranslationEvidence {
  const sourceMarkers =
    hit.pathType === 'two_hop'
      ? [...(markersByEdge.get(hit.firstEdgeId) ?? []), ...(markersByEdge.get(hit.secondEdgeId) ?? [])]
      : markersByEdge.get(hit.firstEdgeId) ?? [];
  const item: TranslationEvidence = {
    source_text: hit.sourceText,
    target_text: hit.targetText,
    target_locale_code: targetLocaleCode,
    path_type: hit.pathType,
    match_type: hit.matchType,
    source_markers: sourceMarkers,
  };
  if (hit.pivotLangCode) item.pivot_lang_code = hit.pivotLangCode;
  return item;
}

function capSerializedBytes(
  items: TranslationEvidence[],
  maxBytes: number,
): { selected: TranslationEvidence[]; omitted: number } {
  const selected: TranslationEvidence[] = [];
  let omitted = 0;
  for (const item of items) {
    if (utf8ByteLength(JSON.stringify([...selected, item])) <= maxBytes) selected.push(item);
    else omitted += 1;
  }
  return { selected, omitted };
}

export async function retrieveEvidence(db: D1Database, input: RetrievalRequest): Promise<RetrievalOutput> {
  const limits: RetrievalLimits = { ...DEFAULT_RETRIEVAL_LIMITS, ...input.limits };
  const sourceLangCode = typeof input.sourceLangCode === 'string' ? input.sourceLangCode.trim().toLowerCase() : '';

  const callerSignal = input.signal;
  const controller = new AbortController();
  let timedOut = false;
  const onAbort = () => controller.abort();
  if (callerSignal) {
    if (callerSignal.aborted) onAbort();
    else callerSignal.addEventListener('abort', onAbort, { once: true });
  }
  // D1 queries cannot be cancelled mid-flight, so the timeout only stops new
  // work between awaits; the finally block always releases timer and listener.
  const timer = setTimeout(() => {
    timedOut = true;
    controller.abort();
  }, limits.timeoutMs);
  const interrupted = (): boolean => {
    if (!controller.signal.aborted) return false;
    if (callerSignal?.aborted) throw new DOMException('The operation was aborted.', 'AbortError');
    timedOut = true;
    return true;
  };

  try {
    if (callerSignal?.aborted) throw new DOMException('The operation was aborted.', 'AbortError');
    if (!sourceLangCode) return DEGRADED;
    const locale = await resolveTargetLocale(db, input.targetLocaleCode);
    if (interrupted()) return DEGRADED;

    const roots = buildRoots(input.fullText, input.spans ?? [], limits.maxPlannerSpans);
    const allRootHits: InternalHit[] = [];
    for (const root of roots) {
      const rootHits: InternalHit[] = [];
      const candidates = await findRootCandidates(db, root, sourceLangCode, limits);
      if (interrupted()) return DEGRADED;
      for (const candidate of candidates) {
        const directRows = await queryDirect(db, candidate.id, locale.locale_id, limits);
        if (interrupted()) return DEGRADED;
        const directHits = passingDirectHits(candidate, directRows);
        rootHits.push(...directHits);
        // Two-hop only fills the slots direct paths left open; each hop is one
        // bounded SQL statement, so cycles cannot expand across revisited nodes.
        if (directHits.length < limits.maxPathsPerRoot) {
          const twoHopRows = await queryTwoHop(
            db,
            candidate.id,
            locale.locale_id,
            locale.lang_code,
            sourceLangCode,
            limits,
          );
          if (interrupted()) return DEGRADED;
          rootHits.push(...passingTwoHopHits(candidate, twoHopRows, sourceLangCode, locale.lang_code, limits));
        }
      }
      const ordered = dedupeHits(rootHits.sort(compareHits)).slice(0, limits.maxPathsPerRoot);
      allRootHits.push(...ordered);
    }

    const ranked = dedupeHits(allRootHits.sort(compareHits));
    const retained = ranked.slice(0, limits.maxEvidenceTotal);
    const omittedByCount = ranked.length - retained.length;
    if (retained.length === 0) return DEGRADED;

    const markersByEdge = await fetchEdgeMarkers(db, uniqueEdgeIds(retained));
    if (interrupted()) return DEGRADED;

    const evidence = retained.map((hit) => buildEvidence(hit, input.targetLocaleCode, markersByEdge));
    const { selected, omitted: omittedByBytes } = capSerializedBytes(evidence, limits.maxEvidenceSerializedBytes);
    if (selected.length === 0) return DEGRADED;
    return { items: selected, omitted_count: omittedByCount + omittedByBytes, degraded: false };
  } catch {
    // A caller abort must stop the request instead of degrading; every other
    // failure (deadline or a single failed query) degrades the search so the
    // translation can still fall back to model-only generation.
    if (callerSignal?.aborted) throw new DOMException('The operation was aborted.', 'AbortError');
    return DEGRADED;
  } finally {
    clearTimeout(timer);
    callerSignal?.removeEventListener('abort', onAbort);
  }
}