import type { D1Database } from '@cloudflare/workers-types';
import { APPROVED_PIVOT_LANGUAGES, MAX_ALTERNATIVES, MAX_DIRECT_PATHS_PER_ROOT } from '../../utils/limits';
import type {
  SourceLanguageResult,
  TranslationEvidence,
  TranslationLanguageCandidate,
  TranslationResult,
} from './types';

// Every stored translation edge is a mapping; keep all currently valid bits
// visible so paraphrases and examples participate like any other expression.
const RELATION_MASK = 1 | 2 | 4;
const MAX_MARKERS_PER_EDGE = 4;

export interface ExactMatchLimits {
  approvedPivotLanguages: readonly string[];
  maxPathsPerRoot: number;
  maxAlternatives: number;
}

export const DEFAULT_EXACT_MATCH_LIMITS: ExactMatchLimits = {
  approvedPivotLanguages: APPROVED_PIVOT_LANGUAGES,
  maxPathsPerRoot: MAX_DIRECT_PATHS_PER_ROOT,
  maxAlternatives: MAX_ALTERNATIVES,
};

export interface ExactMatchInput {
  canonicalText: string;
  sourceLangCode?: string | null;
  targetLocaleCode: string;
  limits: ExactMatchLimits;
}

export type ExactMatchResult =
  | {
      status: 'exact_match';
      source: SourceLanguageResult;
      evidence: TranslationEvidence[];
      result: TranslationResult;
    }
  | { status: 'ambiguous'; candidates: TranslationLanguageCandidate[] }
  | { status: 'no_match' };

export function hasPassingEdge(edge: { score: number; markerCount: number }): boolean {
  return edge.score > 0 || edge.markerCount >= 1;
}

interface LocaleResolution {
  localeId: number;
  langCode: string;
}

interface DirectRow {
  edge_id: number;
  source_expr_id: number;
  source_text: string;
  source_lang_code: string;
  target_expr_id: number;
  target_text: string;
  score: number;
  marker_count: number;
}

interface TwoHopRow {
  source_expr_id: number;
  source_text: string;
  source_lang_code: string;
  pivot_expr_id: number;
  pivot_text: string;
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

interface ExactHit {
  sourceLangCode: string;
  sourceText: string;
  pathType: 'direct' | 'two_hop';
  pivotLangCode?: string;
  targetText: string;
  score: number;
  markerCount: number;
  firstEdgeId: number;
  secondEdgeId: number;
  targetExprId: number;
  edgeIds: number[];
}

interface EdgeMarkerRow {
  source_name: string;
  marker: string;
}

const LOCALE_SQL = `SELECT ll.id AS locale_id, l.code AS lang_code
FROM language_locales ll
JOIN languages l ON l.id = ll.language_id
WHERE ll.code = ?`;

const EDGE_MARKERS_SQL = `SELECT s.name AS source_name, es.source_marker AS marker
FROM expression_edge_sources es
JOIN sources s ON s.id = es.source_id
WHERE es.edge_id = ?
ORDER BY es.source_id ASC, es.source_marker ASC
LIMIT ?`;

function directSql(sourceLangCode: string | null): string {
  return `SELECT edge.id AS edge_id, e.id AS source_expr_id, e.text AS source_text, sl.code AS source_lang_code,
  tgt.id AS target_expr_id, tgt.text AS target_text, edge.score AS score,
  (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge.id) AS marker_count
 FROM expressions e
 JOIN languages sl ON sl.id = e.language_id
 JOIN expression_edges edge ON (edge.expression_a_id = e.id OR edge.expression_b_id = e.id)
 JOIN expressions tgt ON tgt.id = CASE WHEN edge.expression_a_id = e.id THEN edge.expression_b_id ELSE edge.expression_a_id END
 JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?
 WHERE e.text = ?${sourceLangCode ? ' AND sl.code = ?' : ''}
   AND tgt.id <> e.id
   AND (edge.relation_mask & ${RELATION_MASK}) <> 0
   AND (edge.score > 0 OR EXISTS (SELECT 1 FROM expression_edge_sources es WHERE es.edge_id = edge.id))
 ORDER BY edge.score DESC, marker_count DESC, LENGTH(tgt.text) ASC, edge.id ASC, tgt.id ASC
 LIMIT ?`;
}

function twoHopSql(sourceLangCode: string | null, pivotMarks: string): string {
  return `SELECT e.id AS source_expr_id, e.text AS source_text, sl.code AS source_lang_code,
  piv.id AS pivot_expr_id, piv.text AS pivot_text, pl.code AS pivot_lang_code,
  edge1.id AS edge1_id, edge1.score AS edge1_score,
  (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge1.id) AS edge1_markers,
  edge2.id AS edge2_id, edge2.score AS edge2_score,
  (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge2.id) AS edge2_markers,
  tgt.id AS target_expr_id, tgt.text AS target_text
 FROM expressions e
 JOIN languages sl ON sl.id = e.language_id
 JOIN expression_edges edge1 ON (edge1.expression_a_id = e.id OR edge1.expression_b_id = e.id)
 JOIN expressions piv ON piv.id = CASE WHEN edge1.expression_a_id = e.id THEN edge1.expression_b_id ELSE edge1.expression_a_id END
 JOIN languages pl ON pl.id = piv.language_id
 JOIN expression_edges edge2 ON (edge2.expression_a_id = piv.id OR edge2.expression_b_id = piv.id)
 JOIN expressions tgt ON tgt.id = CASE WHEN edge2.expression_a_id = piv.id THEN edge2.expression_b_id ELSE edge2.expression_a_id END
 JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?
 WHERE e.text = ?${sourceLangCode ? ' AND sl.code = ?' : ''}
   AND pl.code IN (${pivotMarks})
   AND pl.code <> ?
   ${sourceLangCode ? 'AND pl.code <> ?' : ''}
   AND tgt.id <> e.id
   AND (edge1.relation_mask & ${RELATION_MASK}) <> 0
   AND (edge2.relation_mask & ${RELATION_MASK}) <> 0
   AND (edge1.score > 0 OR EXISTS (SELECT 1 FROM expression_edge_sources es WHERE es.edge_id = edge1.id))
   AND (edge2.score > 0 OR EXISTS (SELECT 1 FROM expression_edge_sources es WHERE es.edge_id = edge2.id))
 ORDER BY edge1.score + edge2.score DESC,
   (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge1.id)
     + (SELECT COUNT(*) FROM expression_edge_sources es WHERE es.edge_id = edge2.id) DESC,
   LENGTH(tgt.text) ASC,
   edge1.id ASC, edge2.id ASC, tgt.id ASC
 LIMIT ?`;
}

async function resolveTargetLocale(db: D1Database, targetLocaleCode: string): Promise<LocaleResolution | null> {
  const row = await db
    .prepare(LOCALE_SQL)
    .bind(targetLocaleCode)
    .first<{ locale_id: number; lang_code: string }>();
  return row ? { localeId: row.locale_id, langCode: row.lang_code } : null;
}

async function queryDirect(
  db: D1Database,
  canonicalText: string,
  sourceLangCode: string | null,
  localeId: number,
  limits: ExactMatchLimits,
): Promise<DirectRow[]> {
  const binds: unknown[] = [localeId, canonicalText];
  if (sourceLangCode) binds.push(sourceLangCode);
  binds.push(maxRows(limits));
  const { results } = await db.prepare(directSql(sourceLangCode)).bind(...binds).all<DirectRow>();
  return results;
}

async function queryTwoHop(
  db: D1Database,
  canonicalText: string,
  sourceLangCode: string | null,
  locale: LocaleResolution,
  limits: ExactMatchLimits,
): Promise<TwoHopRow[]> {
  const pivotCodes = limits.approvedPivotLanguages;
  const marks = pivotCodes.map(() => '?').join(',');
  const binds: unknown[] = [locale.localeId, canonicalText];
  if (sourceLangCode) binds.push(sourceLangCode);
  binds.push(...pivotCodes, locale.langCode);
  if (sourceLangCode) binds.push(sourceLangCode);
  binds.push(maxRows(limits));
  const { results } = await db.prepare(twoHopSql(sourceLangCode, marks)).bind(...binds).all<TwoHopRow>();
  return results;
}

function maxRows(limits: ExactMatchLimits): number {
  return limits.maxPathsPerRoot * (limits.maxAlternatives + 1);
}

function directHits(rows: DirectRow[]): ExactHit[] {
  const hits: ExactHit[] = [];
  for (const row of rows) {
    // SQL already enforces quality; re-check so the predicate stays a single
    // source of truth that a fake or future caller cannot bypass.
    if (!hasPassingEdge({ score: row.score, markerCount: row.marker_count })) continue;
    hits.push({
      sourceLangCode: row.source_lang_code,
      sourceText: row.source_text,
      pathType: 'direct',
      targetText: row.target_text,
      score: row.score,
      markerCount: row.marker_count,
      firstEdgeId: row.edge_id,
      secondEdgeId: row.edge_id,
      targetExprId: row.target_expr_id,
      edgeIds: [row.edge_id],
    });
  }
  return hits;
}

function twoHopHits(
  rows: TwoHopRow[],
  sourceLangCode: string | null,
  targetLangCode: string,
  limits: ExactMatchLimits,
): ExactHit[] {
  const approved = new Set(limits.approvedPivotLanguages);
  const hits: ExactHit[] = [];
  for (const row of rows) {
    if (!approved.has(row.pivot_lang_code)) continue;
    if (row.pivot_lang_code === targetLangCode) continue;
    if (sourceLangCode && row.pivot_lang_code === sourceLangCode) continue;
    if (!hasPassingEdge({ score: row.edge1_score, markerCount: row.edge1_markers })) continue;
    if (!hasPassingEdge({ score: row.edge2_score, markerCount: row.edge2_markers })) continue;
    hits.push({
      sourceLangCode: row.source_lang_code,
      sourceText: row.source_text,
      pathType: 'two_hop',
      pivotLangCode: row.pivot_lang_code,
      targetText: row.target_text,
      score: row.edge1_score + row.edge2_score,
      markerCount: row.edge1_markers + row.edge2_markers,
      firstEdgeId: row.edge1_id,
      secondEdgeId: row.edge2_id,
      targetExprId: row.target_expr_id,
      edgeIds: [row.edge1_id, row.edge2_id],
    });
  }
  return hits;
}

function rankHits(hits: ExactHit[]): ExactHit[] {
  return [...hits].sort((a, b) => {
    if (a.pathType !== b.pathType) return a.pathType === 'direct' ? -1 : 1;
    if (a.score !== b.score) return b.score - a.score;
    if (a.markerCount !== b.markerCount) return b.markerCount - a.markerCount;
    if (a.targetText.length !== b.targetText.length) return a.targetText.length - b.targetText.length;
    if (a.firstEdgeId !== b.firstEdgeId) return a.firstEdgeId - b.firstEdgeId;
    if (a.secondEdgeId !== b.secondEdgeId) return a.secondEdgeId - b.secondEdgeId;
    return a.targetExprId - b.targetExprId;
  });
}

function distinctTargets(hits: ExactHit[]): ExactHit[] {
  const seen = new Set<string>();
  const distinct: ExactHit[] = [];
  for (const hit of hits) {
    if (seen.has(hit.targetText)) continue;
    seen.add(hit.targetText);
    distinct.push(hit);
  }
  return distinct;
}

function ambiguousCandidates(hits: ExactHit[]): TranslationLanguageCandidate[] {
  const counts = new Map<string, number>();
  for (const hit of hits) counts.set(hit.sourceLangCode, (counts.get(hit.sourceLangCode) ?? 0) + 1);
  const total = hits.length || 1;
  return [...counts.entries()]
    .map(([code, count]) => ({ code, confidence: count / total }))
    .sort((a, b) => b.confidence - a.confidence || a.code.localeCompare(b.code));
}

async function fetchEdgeMarkers(db: D1Database, edgeIds: number[]): Promise<string[]> {
  const markers: string[] = [];
  for (const edgeId of edgeIds) {
    const { results } = await db.prepare(EDGE_MARKERS_SQL).bind(edgeId, MAX_MARKERS_PER_EDGE).all<EdgeMarkerRow>();
    for (const row of results) {
      markers.push(row.marker ? `${row.source_name}#${row.marker}` : row.source_name);
    }
  }
  return markers;
}

async function buildEvidence(db: D1Database, hits: ExactHit[], targetLocaleCode: string): Promise<TranslationEvidence[]> {
  const evidence: TranslationEvidence[] = [];
  for (const hit of hits) {
    evidence.push({
      source_text: hit.sourceText,
      target_text: hit.targetText,
      target_locale_code: targetLocaleCode,
      path_type: hit.pathType,
      pivot_lang_code: hit.pivotLangCode,
      match_type: 'exact',
      source_markers: await fetchEdgeMarkers(db, hit.edgeIds),
    });
  }
  return evidence;
}

export async function findExactTranslation(
  db: D1Database,
  input: ExactMatchInput,
): Promise<ExactMatchResult> {
  const canonicalText = input.canonicalText.trim();
  if (!canonicalText) return { status: 'no_match' };
  // Callers pass the source code already lowercased; normalize defensively so
  // pivot comparisons stay stable.
  const sourceLangCode = input.sourceLangCode ? input.sourceLangCode.trim().toLowerCase() : null;
  const locale = await resolveTargetLocale(db, input.targetLocaleCode);
  if (!locale) return { status: 'no_match' };

  const directRows = await queryDirect(db, canonicalText, sourceLangCode, locale.localeId, input.limits);
  let hits = directHits(directRows);

  if (hits.length === 0) {
    const twoHopRows = await queryTwoHop(db, canonicalText, sourceLangCode, locale, input.limits);
    hits = twoHopHits(twoHopRows, sourceLangCode, locale.langCode, input.limits);
  }

  if (hits.length === 0) return { status: 'no_match' };

  const ranked = rankHits(hits);

  if (!sourceLangCode) {
    const languages = new Set(ranked.map((hit) => hit.sourceLangCode));
    if (languages.size > 1) return { status: 'ambiguous', candidates: ambiguousCandidates(ranked) };
  }

  const chosen = distinctTargets(ranked);
  const main = chosen[0];
  const alternatives = chosen.slice(1, input.limits.maxAlternatives + 1);

  const source: SourceLanguageResult = { code: sourceLangCode ?? main.sourceLangCode, confidence: 1 };
  const result: TranslationResult = {
    translation: main.targetText,
    alternatives: alternatives.map((hit) => hit.targetText),
    source_lang_code: source.code,
    target_locale_code: input.targetLocaleCode,
    evidence_present: true,
    model_only: false,
    resolution: 'exact_lookup',
    generation_skipped: true,
  };
  return {
    status: 'exact_match',
    source,
    evidence: await buildEvidence(db, [main, ...alternatives], input.targetLocaleCode),
    result,
  };
}