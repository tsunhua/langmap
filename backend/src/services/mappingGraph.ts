import type { D1Database } from '@cloudflare/workers-types';
import type { MappingGraphEdge, MappingGraphNode, MappingGraphResponse } from '../types/mapping';
import { resolveLanguageNames, type LocaleHints } from './localizedName';
import { dictionaryPackedSchemaAvailable, dictionaryReleaseSchemaAvailable, edgeEligibilityPredicate, releaseObjectEligibilityPredicate } from './dictionaryReleaseEligibility';

const DEFAULT_NODE_LIMIT = 200;
// D1 binds the frontier twice in the edge query, so keep each batch below
// SQLite's 100-variable limit.
const FRONTIER_BATCH_SIZE = 50;
const PACKED_ID_PATTERN = /^d(\d{8})$/;

interface GraphEdgeRow {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  created_at: string;
  expression_a_text: string;
  expression_a_lang_code: string;
  expression_a_language_profile_code: string | null;
  expression_b_text: string;
  expression_b_lang_code: string;
  expression_b_language_profile_code: string | null;
}

function packedTermId(expressionId: string): number | null {
  const match = PACKED_ID_PATTERN.exec(expressionId);
  if (!match) return null;
  const termId = Number.parseInt(match[1], 10);
  return Number.isSafeInteger(termId) && termId > 0 ? termId : null;
}

function toNode(row: GraphEdgeRow, expressionId: string, depth: number, nameMap: ReadonlyMap<string, string>): MappingGraphNode {
  const isA = row.expression_a_id === expressionId;
  const langCode = isA ? row.expression_a_lang_code : row.expression_b_lang_code;
  const languageProfileCode = isA ? row.expression_a_language_profile_code : row.expression_b_language_profile_code;
  return {
    expression_id: expressionId,
    text: isA ? row.expression_a_text : row.expression_b_text,
    lang_code: langCode,
    language_profile_code: languageProfileCode,
    language_name: nameMap.get(langCode) ?? langCode,
    depth,
  };
}

async function loadEdgesForFrontierBatch(db: D1Database, frontier: readonly string[], releaseTablesReady: boolean): Promise<GraphEdgeRow[]> {
  const placeholders = frontier.map(() => '?').join(', ');
  const edgeEligibility = releaseTablesReady ? ` AND ${edgeEligibilityPredicate('e')}` : '';
  const aProfile = releaseTablesReady
    ? `(SELECT language_locale_code FROM expression_locale_attestations a_att WHERE a_att.expression_id = a.id AND ${releaseObjectEligibilityPredicate('locale_attestation', 'a_att.id')} ORDER BY language_locale_code ASC, id ASC LIMIT 1)`
    : '(SELECT language_locale_code FROM expression_locale_attestations WHERE expression_id = a.id ORDER BY language_locale_code ASC, id ASC LIMIT 1)';
  const bProfile = releaseTablesReady
    ? `(SELECT language_locale_code FROM expression_locale_attestations b_att WHERE b_att.expression_id = b.id AND ${releaseObjectEligibilityPredicate('locale_attestation', 'b_att.id')} ORDER BY language_locale_code ASC, id ASC LIMIT 1)`
    : '(SELECT language_locale_code FROM expression_locale_attestations WHERE expression_id = b.id ORDER BY language_locale_code ASC, id ASC LIMIT 1)';
  const { results } = await db.prepare(
    `SELECT e.id, e.expression_a_id, e.expression_b_id, e.score, e.created_at,
      a.text AS expression_a_text, a.lang_code AS expression_a_lang_code,
      ${aProfile} AS expression_a_language_profile_code,
      b.text AS expression_b_text, b.lang_code AS expression_b_lang_code,
      ${bProfile} AS expression_b_language_profile_code
     FROM all_expression_edges e
     JOIN all_expression_rows a ON a.id = e.expression_a_id
     JOIN all_expression_rows b ON b.id = e.expression_b_id
     WHERE (e.expression_a_id IN (${placeholders}) OR e.expression_b_id IN (${placeholders}))${edgeEligibility}
     ORDER BY e.score DESC, e.created_at ASC, e.id ASC`,
  ).bind(...frontier, ...frontier).all<GraphEdgeRow>();
  return results;
}

async function loadEdgesForFrontier(db: D1Database, frontier: readonly string[], releaseTablesReady: boolean): Promise<GraphEdgeRow[]> {
  const batches: string[][] = [];
  for (let start = 0; start < frontier.length; start += FRONTIER_BATCH_SIZE) {
    batches.push(frontier.slice(start, start + FRONTIER_BATCH_SIZE));
  }

  const rowsById = new Map<string, GraphEdgeRow>();
  const batchRows = await Promise.all(batches.map((batch) => loadEdgesForFrontierBatch(db, batch, releaseTablesReady)));
  for (const rows of batchRows) {
    for (const row of rows) {
      rowsById.set(row.id, row);
    }
  }

  return [...rowsById.values()].sort((left, right) =>
    right.score - left.score
    || left.created_at.localeCompare(right.created_at)
    || left.id.localeCompare(right.id),
  );
}

interface GraphEdgeQueryRow extends Omit<GraphEdgeRow,
  'expression_a_text' | 'expression_a_lang_code' | 'expression_a_language_profile_code'
  | 'expression_b_text' | 'expression_b_lang_code' | 'expression_b_language_profile_code'> {
  expression_a_text: string | null;
  expression_a_lang_code: string | null;
  expression_a_language_profile_code: string | null;
  expression_b_text: string | null;
  expression_b_lang_code: string | null;
  expression_b_language_profile_code: string | null;
}

async function loadPackedEdgesForFrontierBatch(
  db: D1Database,
  frontier: readonly string[],
): Promise<GraphEdgeRow[]> {
  const placeholders = frontier.map(() => '?').join(', ');
  const packedIds = frontier.map(packedTermId).filter((id): id is number => id !== null);
  const packedPlaceholders = packedIds.map(() => '?').join(', ');
  const edgeEligibility = ` AND ${edgeEligibilityPredicate('e')}`;
  const aProfile = `(SELECT language_locale_code FROM expression_locale_attestations a_att
    WHERE a_att.expression_id = a.id ORDER BY language_locale_code ASC, id ASC LIMIT 1)`;
  const bProfile = `(SELECT language_locale_code FROM expression_locale_attestations b_att
    WHERE b_att.expression_id = b.id ORDER BY language_locale_code ASC, id ASC LIMIT 1)`;
  const basePromise = db.prepare(
    `SELECT e.id, e.expression_a_id, e.expression_b_id, e.score, e.created_at,
      a.text AS expression_a_text, a.lang_code AS expression_a_lang_code,
      ${aProfile} AS expression_a_language_profile_code,
      b.text AS expression_b_text, b.lang_code AS expression_b_lang_code,
      ${bProfile} AS expression_b_language_profile_code
     FROM expression_edges e
     LEFT JOIN expressions a ON a.id = e.expression_a_id
     LEFT JOIN expressions b ON b.id = e.expression_b_id
     WHERE (e.expression_a_id IN (${placeholders}) OR e.expression_b_id IN (${placeholders}))${edgeEligibility}
     ORDER BY e.score DESC, e.created_at ASC, e.id ASC`,
  ).bind(...frontier, ...frontier).all<GraphEdgeQueryRow>();
  const packedPromise = packedIds.length === 0
    ? Promise.resolve({ results: [] as GraphEdgeQueryRow[] })
    : db.prepare(
      `SELECT 'e' || printf('%08d', de.edge_id) AS id,
        'd' || printf('%08d', de.expression_a_id) AS expression_a_id,
        'd' || printf('%08d', de.expression_b_id) AS expression_b_id,
        0 AS score, dr.created_at,
        ta.text AS expression_a_text, la.code AS expression_a_lang_code,
        NULL AS expression_a_language_profile_code,
        tb.text AS expression_b_text, lb.code AS expression_b_lang_code,
        NULL AS expression_b_language_profile_code
       FROM dictionary_edges de
       JOIN dictionary_terms ta ON ta.term_id = de.expression_a_id
       JOIN dictionary_languages la ON la.language_id = ta.language_id
       JOIN dictionary_terms tb ON tb.term_id = de.expression_b_id
       JOIN dictionary_languages lb ON lb.language_id = tb.language_id
       JOIN dictionary_dataset_state ds
         ON ds.dataset_key = 'managed-dictionaries' AND ds.active_release_id IS NOT NULL
       JOIN dictionary_dataset_releases dr ON dr.id = ds.active_release_id
       WHERE de.expression_a_id IN (${packedPlaceholders})
          OR de.expression_b_id IN (${packedPlaceholders})
       ORDER BY de.edge_id ASC`,
    ).bind(...packedIds, ...packedIds).all<GraphEdgeQueryRow>();
  const [{ results: baseRows }, { results: packedRows }] = await Promise.all([basePromise, packedPromise]);
  const rows = [...baseRows, ...packedRows];
  const missingTermIds = [...new Set(rows.flatMap((row) => {
    const ids: number[] = [];
    if (row.expression_a_text === null) {
      const id = packedTermId(row.expression_a_id);
      if (id !== null) ids.push(id);
    }
    if (row.expression_b_text === null) {
      const id = packedTermId(row.expression_b_id);
      if (id !== null) ids.push(id);
    }
    return ids;
  }))];
  const terms = new Map<number, { text: string; lang_code: string }>();
  for (let start = 0; start < missingTermIds.length; start += FRONTIER_BATCH_SIZE) {
    const chunk = missingTermIds.slice(start, start + FRONTIER_BATCH_SIZE);
    const termPlaceholders = chunk.map(() => '?').join(', ');
    const { results } = await db.prepare(
      `SELECT t.term_id, t.text, l.code AS lang_code
       FROM dictionary_terms t JOIN dictionary_languages l ON l.language_id = t.language_id
       WHERE t.term_id IN (${termPlaceholders})`,
    ).bind(...chunk).all<{ term_id: number; text: string; lang_code: string }>();
    for (const term of results) terms.set(term.term_id, term);
  }
  return rows
    .map((row) => {
      const a = row.expression_a_text === null ? terms.get(packedTermId(row.expression_a_id) ?? -1) : null;
      const b = row.expression_b_text === null ? terms.get(packedTermId(row.expression_b_id) ?? -1) : null;
      return {
        ...row,
        expression_a_text: row.expression_a_text ?? a?.text ?? '',
        expression_a_lang_code: row.expression_a_lang_code ?? a?.lang_code ?? '',
        expression_b_text: row.expression_b_text ?? b?.text ?? '',
        expression_b_lang_code: row.expression_b_lang_code ?? b?.lang_code ?? '',
      };
    })
    .filter((row) => row.expression_a_text !== '' && row.expression_b_text !== '')
    .sort((left, right) => right.score - left.score
      || left.created_at.localeCompare(right.created_at)
      || left.id.localeCompare(right.id));
}

async function loadPackedEdgesForFrontier(db: D1Database, frontier: readonly string[]): Promise<GraphEdgeRow[]> {
  const batches: string[][] = [];
  for (let start = 0; start < frontier.length; start += FRONTIER_BATCH_SIZE) {
    batches.push(frontier.slice(start, start + FRONTIER_BATCH_SIZE));
  }
  const rowsById = new Map<string, GraphEdgeRow>();
  const batchRows = await Promise.all(batches.map((batch) => loadPackedEdgesForFrontierBatch(db, batch)));
  for (const rows of batchRows) for (const row of rows) rowsById.set(row.id, row);
  return [...rowsById.values()].sort((left, right) => right.score - left.score
    || left.created_at.localeCompare(right.created_at)
    || left.id.localeCompare(right.id));
}

async function loadPackedRoot(db: D1Database, rootId: string): Promise<{
  id: string; text: string; lang_code: string; language_profile_code: string | null;
} | null> {
  const termId = packedTermId(rootId);
  if (termId === null) {
    return db.prepare(
      `SELECT e.id, e.text, e.lang_code,
        (SELECT language_locale_code FROM expression_locale_attestations a
         WHERE a.expression_id = e.id ORDER BY language_locale_code ASC, id ASC LIMIT 1) AS language_profile_code
       FROM expressions e WHERE e.id = ?`,
    ).bind(rootId).first();
  }
  return db.prepare(
    `SELECT 'd' || printf('%08d', t.term_id) AS id, t.text, l.code AS lang_code,
      NULL AS language_profile_code
     FROM dictionary_terms t JOIN dictionary_languages l ON l.language_id = t.language_id
     WHERE t.term_id = ?`,
  ).bind(termId).first();
}

export async function getMappingGraph(
  db: D1Database,
  rootId: string,
  hops: 1 | 2 | 3,
  nodeLimit = DEFAULT_NODE_LIMIT,
  locales: LocaleHints = {},
): Promise<MappingGraphResponse | null> {
  const [releaseTablesReady, packedSchemaReady] = await Promise.all([
    dictionaryReleaseSchemaAvailable(db),
    dictionaryPackedSchemaAvailable(db),
  ]);
  const packedPathReady = releaseTablesReady && packedSchemaReady;
  const compatibilityRootQuery = releaseTablesReady
    ? `SELECT id, text, lang_code,
        (SELECT language_locale_code FROM expression_locale_attestations a
         WHERE a.expression_id = expressions.id AND ${releaseObjectEligibilityPredicate('locale_attestation', 'a.id')}
         ORDER BY language_locale_code ASC, id ASC LIMIT 1) AS language_profile_code
       FROM expressions WHERE id = ?`
    : `SELECT id, text, lang_code,
        (SELECT language_locale_code FROM expression_locale_attestations
         WHERE expression_id = all_expression_rows.id ORDER BY language_locale_code ASC, id ASC LIMIT 1) AS language_profile_code
       FROM all_expression_rows WHERE id = ?`;
  const root = packedPathReady
    ? await loadPackedRoot(db, rootId)
    : await db.prepare(compatibilityRootQuery).bind(rootId).first<{
      id: string;
      text: string;
      lang_code: string;
      language_profile_code: string | null;
    }>();
  if (!root) return null;

  const limit = Math.max(1, Math.min(nodeLimit, DEFAULT_NODE_LIMIT));
  const visited = new Set<string>([rootId]);
  const rootNames = await resolveLanguageNames(db, [root.lang_code], locales);
  const nodes: MappingGraphNode[] = [{
    expression_id: root.id,
    text: root.text,
    lang_code: root.lang_code,
    language_profile_code: root.language_profile_code,
    language_name: rootNames.get(root.lang_code) ?? root.lang_code,
    depth: 0,
  }];
  const edges: MappingGraphEdge[] = [];
  const edgeIds = new Set<string>();
  const omitted = new Set<string>();
  const layerCounts: Record<number, number> = { 0: 1 };
  let frontier = [rootId];
  let resolvedHops: 0 | 1 | 2 | 3 = 0;

  for (let depth = 1; depth <= hops && frontier.length > 0; depth++) {
    const rows = packedPathReady
      ? await loadPackedEdgesForFrontier(db, frontier)
      : await loadEdgesForFrontier(db, frontier, releaseTablesReady);
    const langCodes = [...new Set(rows.flatMap((row) => [row.expression_a_lang_code, row.expression_b_lang_code]))];
    const nameMap = await resolveLanguageNames(db, langCodes, locales);
    const next = new Set<string>();
    const frontierIds = new Set(frontier);
    for (const row of rows) {
      const touchesA = frontierIds.has(row.expression_a_id);
      const touchesB = frontierIds.has(row.expression_b_id);
      if (!touchesA && !touchesB) continue;
      if (!edgeIds.has(row.id)) {
        edgeIds.add(row.id);
        edges.push({
          edge_id: row.id,
          source_id: row.expression_a_id,
          target_id: row.expression_b_id,
          score: row.score,
          depth,
        });
      }
      const neighbors = touchesA && touchesB
        ? []
        : [touchesA ? row.expression_b_id : row.expression_a_id];
      for (const endpoint of neighbors) {
        if (visited.has(endpoint)) continue;
        if (visited.size >= limit) {
          omitted.add(endpoint);
          continue;
        }
        visited.add(endpoint);
        next.add(endpoint);
        nodes.push(toNode(row, endpoint, depth, nameMap));
      }
    }
    if (rows.length > 0) resolvedHops = depth as 1 | 2 | 3;
    layerCounts[depth] = next.size;
    frontier = [...next].sort();
  }

  return {
    root_id: rootId,
    requested_hops: hops,
    resolved_hops: resolvedHops,
    nodes,
    // Edges to omitted nodes are not renderable and would let clients create
    // phantom layout nodes. Keep the graph response internally consistent.
    edges: edges.filter((edge) => visited.has(edge.source_id) && visited.has(edge.target_id)),
    layer_counts: layerCounts,
    truncated: omitted.size > 0,
    omitted_count: omitted.size,
  };
}
