import type { D1Database } from '@cloudflare/workers-types';
import { resolveLanguageNames, resolveNamesByExpressionIds, type LocaleHints } from './localizedName';
import { ulid } from '../utils/ulid';
import type {
  CreateFormEdgeResult,
  ExpressionFormEdgesDto,
  FormEdgeAsFormDto,
  FormEdgeAsLemmaDto,
  FormEdgeExpressionSummary,
  FormEdgeFeatureDto,
  MorphologicalDimensionDto,
  MorphologicalFeatureDto,
  MorphologicalFeaturesResponse,
  SearchFormOfDto,
} from '../types/morphology';

interface DimensionRow {
  code: string;
  name_expression_id: string;
  sort_order: number;
}

interface FeatureRow {
  code: string;
  dimension_code: string;
  name_expression_id: string;
  sort_order: number;
}

const DIMENSIONS_SQL =
  'SELECT code, name_expression_id, sort_order FROM morphological_dimensions ORDER BY sort_order ASC, code ASC';
const FEATURES_SQL =
  'SELECT f.code, f.dimension_code, f.name_expression_id, f.sort_order FROM morphological_features f JOIN morphological_dimensions d ON d.code = f.dimension_code ORDER BY d.sort_order ASC, f.sort_order ASC, f.code ASC';

function displayName(
  resolved: { name: string; name_en: string } | undefined,
  code: string,
): Pick<MorphologicalFeatureDto, 'name' | 'name_en'> {
  return {
    name: resolved?.name || code,
    name_en: resolved?.name_en || code,
  };
}

export async function listMorphologicalFeatures(
  db: D1Database,
  hints: LocaleHints,
): Promise<MorphologicalFeaturesResponse> {
  const { results: dimensionRows } = await db.prepare(DIMENSIONS_SQL).all<DimensionRow>();
  const { results: featureRows } = await db.prepare(FEATURES_SQL).all<FeatureRow>();
  const nameIds = [
    ...new Set([...dimensionRows, ...featureRows].map((row) => row.name_expression_id).filter(Boolean)),
  ];
  const names = await resolveNamesByExpressionIds(db, nameIds, hints);

  const grouped = new Map<string, MorphologicalFeatureDto[]>();
  for (const row of featureRows) {
    const features = grouped.get(row.dimension_code) ?? [];
    features.push({
      code: row.code,
      sort_order: row.sort_order,
      ...displayName(names.get(row.name_expression_id), row.code),
    });
    grouped.set(row.dimension_code, features);
  }

  const dimensions: MorphologicalDimensionDto[] = dimensionRows.map((row) => ({
    code: row.code,
    sort_order: row.sort_order,
    features: grouped.get(row.code) ?? [],
    ...displayName(names.get(row.name_expression_id), row.code),
  }));

  return { dimensions };
}

export class MorphologyError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'MorphologyError';
  }
}

interface ExpressionRef {
  id: string;
  lang_code: string;
  text: string;
}

interface FormEdgeRow {
  id: string;
  form_id: string;
  lemma_id: string;
}

interface NeighborEdgeRow {
  edge_id: string;
  neighbor_id: string;
  neighbor_text: string;
  neighbor_lang_code: string;
}

interface EdgeFeatureRow {
  edge_id: string;
  code: string;
  dimension_code: string;
  name_expression_id: string;
  feature_sort: number;
  dimension_sort: number;
}

const EXPRESSION_REF_SQL = 'SELECT id, lang_code, text FROM all_expression_rows WHERE id = ?';
const FORM_EDGE_PAIR_SQL = 'SELECT id FROM expression_form_edges WHERE form_id = ? AND lemma_id = ?';
const INSERT_FORM_EDGE_SQL =
  'INSERT INTO expression_form_edges (id, form_id, lemma_id, pair_low, pair_high, source, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)';
const INSERT_FORM_EDGE_FEATURE_SQL =
  'INSERT OR IGNORE INTO expression_form_edge_features (edge_id, feature_code) VALUES (?, ?)';
const FEATURE_CODES_SQL =
  'SELECT code FROM morphological_features WHERE code IN (SELECT value FROM json_each(?))';
const AS_FORM_EDGES_SQL =
  'SELECT e.id AS edge_id, l.id AS neighbor_id, l.text AS neighbor_text, l.lang_code AS neighbor_lang_code FROM expression_form_edges e JOIN all_expression_rows l ON l.id = e.lemma_id WHERE e.form_id = ? ORDER BY l.id ASC';
const AS_LEMMA_EDGES_SQL =
  'SELECT e.id AS edge_id, f.id AS neighbor_id, f.text AS neighbor_text, f.lang_code AS neighbor_lang_code FROM expression_form_edges e JOIN all_expression_rows f ON f.id = e.form_id WHERE e.lemma_id = ?';
const EDGE_FEATURES_SQL =
  'SELECT ef.edge_id, mf.code, mf.dimension_code, mf.name_expression_id, mf.sort_order AS feature_sort, d.sort_order AS dimension_sort FROM expression_form_edge_features ef JOIN morphological_features mf ON mf.code = ef.feature_code JOIN morphological_dimensions d ON d.code = mf.dimension_code WHERE ef.edge_id IN (SELECT value FROM json_each(?)) ORDER BY d.sort_order ASC, mf.sort_order ASC, mf.code ASC';
const FORM_OF_LIMIT = 3;
const FORM_OF_EDGES_SQL =
  'SELECT e.id AS edge_id, e.form_id, l.id AS lemma_id, l.text AS lemma_text, l.lang_code AS lemma_lang_code FROM expression_form_edges e JOIN all_expression_rows l ON l.id = e.lemma_id WHERE e.form_id IN (SELECT value FROM json_each(?)) ORDER BY e.form_id ASC, e.lemma_id ASC';

interface FormOfEdgeRow {
  edge_id: string;
  form_id: string;
  lemma_id: string;
  lemma_text: string;
  lemma_lang_code: string;
}

function pairBounds(formId: string, lemmaId: string): [string, string] {
  return formId < lemmaId ? [formId, lemmaId] : [lemmaId, formId];
}

function dedupeStrings(values: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const value of values) {
    if (seen.has(value)) continue;
    seen.add(value);
    out.push(value);
  }
  return out;
}

function compareFormId(a: string, b: string): number {
  if (a < b) return -1;
  if (a > b) return 1;
  return 0;
}

function lemmaSortKey(features: EdgeFeatureRow[]): [number, number, number] {
  if (features.length === 0) return [1, 0, 0];
  let dimensionSort = features[0].dimension_sort;
  let featureSort = features[0].feature_sort;
  for (const row of features) {
    if (row.dimension_sort < dimensionSort || (row.dimension_sort === dimensionSort && row.feature_sort < featureSort)) {
      dimensionSort = row.dimension_sort;
      featureSort = row.feature_sort;
    }
  }
  return [0, dimensionSort, featureSort];
}

async function loadExpression(db: D1Database, id: string): Promise<ExpressionRef | null> {
  return db.prepare(EXPRESSION_REF_SQL).bind(id).first<ExpressionRef>();
}

async function assertKnownFeatures(db: D1Database, codes: readonly string[]): Promise<void> {
  if (codes.length === 0) return;
  const { results } = await db.prepare(FEATURE_CODES_SQL).bind(JSON.stringify(codes)).all<{ code: string }>();
  const found = new Set(results.map((row) => row.code));
  if (codes.some((code) => !found.has(code))) {
    throw new MorphologyError('FORM_FEATURE_UNKNOWN');
  }
}

async function loadEdgeFeatures(
  db: D1Database,
  edgeIds: readonly string[],
): Promise<Map<string, EdgeFeatureRow[]>> {
  const grouped = new Map<string, EdgeFeatureRow[]>();
  if (edgeIds.length === 0) return grouped;
  const { results } = await db.prepare(EDGE_FEATURES_SQL).bind(JSON.stringify(edgeIds)).all<EdgeFeatureRow>();
  for (const row of results) {
    const list = grouped.get(row.edge_id) ?? [];
    list.push(row);
    grouped.set(row.edge_id, list);
  }
  return grouped;
}

async function toFeatureDtos(
  db: D1Database,
  rows: EdgeFeatureRow[],
  hints: LocaleHints,
): Promise<FormEdgeFeatureDto[]> {
  const names = await resolveNamesByExpressionIds(
    db,
    rows.map((row) => row.name_expression_id),
    hints,
  );
  return rows.map((row) => ({
    code: row.code,
    name: names.get(row.name_expression_id)?.name || row.code,
    dimension_code: row.dimension_code,
  }));
}

async function toFeatureDtoMap(
  db: D1Database,
  grouped: Map<string, EdgeFeatureRow[]>,
  hints: LocaleHints,
): Promise<Map<string, FormEdgeFeatureDto[]>> {
  const nameIds = [...grouped.values()].flat().map((row) => row.name_expression_id);
  const names = await resolveNamesByExpressionIds(db, nameIds, hints);
  const mapped = new Map<string, FormEdgeFeatureDto[]>();
  for (const [edgeId, rows] of grouped) {
    mapped.set(
      edgeId,
      rows.map((row) => ({
        code: row.code,
        name: names.get(row.name_expression_id)?.name || row.code,
        dimension_code: row.dimension_code,
      })),
    );
  }
  return mapped;
}

function toSummary(
  neighbor: Pick<NeighborEdgeRow, 'neighbor_id' | 'neighbor_text' | 'neighbor_lang_code'>,
  languageName: string,
): FormEdgeExpressionSummary {
  return {
    id: neighbor.neighbor_id,
    text: neighbor.neighbor_text,
    lang_code: neighbor.neighbor_lang_code,
    language_name: languageName,
  };
}

function truncateSide<T>(items: T[], limit: number): { items: T[]; truncated: boolean; omitted_count: number } {
  if (items.length <= limit) {
    return { items, truncated: false, omitted_count: 0 };
  }
  return { items: items.slice(0, limit), truncated: true, omitted_count: items.length - limit };
}

export async function createFormEdge(
  db: D1Database,
  input: {
    formId: string;
    lemmaId: string;
    features?: string[];
    source: string;
    createdBy: number;
    hints: LocaleHints;
  },
): Promise<CreateFormEdgeResult> {
  const formId = input.formId.trim();
  const lemmaId = input.lemmaId.trim();
  if (!formId || !lemmaId) throw new MorphologyError('VALIDATION_FAILED');

  const form = await loadExpression(db, formId);
  const lemma = await loadExpression(db, lemmaId);
  if (!form || !lemma) throw new MorphologyError('EXPRESSION_NOT_FOUND');
  if (form.lang_code !== lemma.lang_code) throw new MorphologyError('FORM_EDGE_CROSS_LANGUAGE');
  if (formId === lemmaId) throw new MorphologyError('FORM_EDGE_SELF');

  const reverse = await db.prepare(FORM_EDGE_PAIR_SQL).bind(lemmaId, formId).first<FormEdgeRow>();
  if (reverse) throw new MorphologyError('FORM_EDGE_MUTUAL');

  const requested = input.features === undefined ? undefined : dedupeStrings(input.features);
  if (requested) await assertKnownFeatures(db, requested);

  const existing = await db.prepare(FORM_EDGE_PAIR_SQL).bind(formId, lemmaId).first<FormEdgeRow>();
  let edgeId: string;
  let created = false;
  if (existing) {
    edgeId = existing.id;
  } else {
    edgeId = ulid();
    const [pairLow, pairHigh] = pairBounds(formId, lemmaId);
    const statements = [
      db.prepare(INSERT_FORM_EDGE_SQL).bind(edgeId, formId, lemmaId, pairLow, pairHigh, input.source, input.createdBy),
    ];
    for (const code of requested ?? []) {
      statements.push(db.prepare(INSERT_FORM_EDGE_FEATURE_SQL).bind(edgeId, code));
    }
    await db.batch(statements);
    created = true;
  }

  if (!created && requested && requested.length > 0) {
    await db.batch(requested.map((code) => db.prepare(INSERT_FORM_EDGE_FEATURE_SQL).bind(edgeId, code)));
  }

  const featureRows = (await loadEdgeFeatures(db, [edgeId])).get(edgeId) ?? [];
  const languageNames = await resolveLanguageNames(db, [lemma.lang_code], input.hints);
  return {
    created,
    edge_id: edgeId,
    lemma: {
      id: lemma.id,
      text: lemma.text,
      lang_code: lemma.lang_code,
      language_name: languageNames.get(lemma.lang_code) ?? lemma.lang_code,
    },
    features: await toFeatureDtos(db, featureRows, input.hints),
  };
}

export async function getExpressionFormEdges(
  db: D1Database,
  expressionId: string,
  query: { limit: number; hints: LocaleHints },
): Promise<ExpressionFormEdgesDto> {
  const id = expressionId.trim();
  if (!id) throw new MorphologyError('VALIDATION_FAILED');
  const expression = await loadExpression(db, id);
  if (!expression) throw new MorphologyError('EXPRESSION_NOT_FOUND');

  const { results: asFormRows } = await db.prepare(AS_FORM_EDGES_SQL).bind(id).all<NeighborEdgeRow>();
  const { results: asLemmaRows } = await db.prepare(AS_LEMMA_EDGES_SQL).bind(id).all<NeighborEdgeRow>();
  const featureMap = await loadEdgeFeatures(db, [
    ...asFormRows.map((row) => row.edge_id),
    ...asLemmaRows.map((row) => row.edge_id),
  ]);
  const featureDtos = await toFeatureDtoMap(db, featureMap, query.hints);
  const languageNames = await resolveLanguageNames(
    db,
    [...asFormRows, ...asLemmaRows].map((row) => row.neighbor_lang_code),
    query.hints,
  );

  const asFormAll: FormEdgeAsFormDto[] = asFormRows.map((row) => ({
    edge_id: row.edge_id,
    lemma: toSummary(row, languageNames.get(row.neighbor_lang_code) ?? row.neighbor_lang_code),
    features: featureDtos.get(row.edge_id) ?? [],
  }));

  const asLemmaSorted = [...asLemmaRows].sort((left, right) => {
    const leftKey = lemmaSortKey(featureMap.get(left.edge_id) ?? []);
    const rightKey = lemmaSortKey(featureMap.get(right.edge_id) ?? []);
    for (let i = 0; i < leftKey.length; i++) {
      if (leftKey[i] !== rightKey[i]) return leftKey[i] - rightKey[i];
    }
    return compareFormId(left.neighbor_id, right.neighbor_id);
  });
  const asLemmaAll: FormEdgeAsLemmaDto[] = asLemmaSorted.map((row) => ({
    edge_id: row.edge_id,
    form: toSummary(row, languageNames.get(row.neighbor_lang_code) ?? row.neighbor_lang_code),
    features: featureDtos.get(row.edge_id) ?? [],
  }));

  const asForm = truncateSide(asFormAll, query.limit);
  const asLemma = truncateSide(asLemmaAll, query.limit);
  return {
    as_form: asForm.items,
    as_lemma: asLemma.items,
    as_form_truncated: asForm.truncated,
    as_form_omitted_count: asForm.omitted_count,
    as_lemma_truncated: asLemma.truncated,
    as_lemma_omitted_count: asLemma.omitted_count,
  };
}

export async function attachFormOf(
  db: D1Database,
  expressionIds: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, SearchFormOfDto[]>> {
  const attached = new Map<string, SearchFormOfDto[]>();
  for (const id of expressionIds) attached.set(id, []);
  if (expressionIds.length === 0) return attached;

  const { results } = await db.prepare(FORM_OF_EDGES_SQL).bind(JSON.stringify(expressionIds)).all<FormOfEdgeRow>();
  const kept: FormOfEdgeRow[] = [];
  const counts = new Map<string, number>();
  for (const row of results) {
    const count = counts.get(row.form_id) ?? 0;
    if (count >= FORM_OF_LIMIT) continue;
    counts.set(row.form_id, count + 1);
    kept.push(row);
  }

  const featureMap = await loadEdgeFeatures(db, kept.map((row) => row.edge_id));
  const nameIds = [...featureMap.values()].flat().map((row) => row.name_expression_id);
  const names = await resolveNamesByExpressionIds(db, nameIds, hints);

  for (const row of kept) {
    const features = (featureMap.get(row.edge_id) ?? []).map((feature) => ({
      code: feature.code,
      name: names.get(feature.name_expression_id)?.name || feature.code,
    }));
    const list = attached.get(row.form_id) ?? [];
    list.push({
      lemma: { id: row.lemma_id, text: row.lemma_text, lang_code: row.lemma_lang_code },
      features,
    });
    attached.set(row.form_id, list);
  }
  return attached;
}
