import { describe, expect, it } from 'vitest';
import { MorphologyError, attachFormOf, createFormEdge, getExpressionFormEdges, listMorphologicalFeatures } from '../src/services/morphology';
import { parseLocaleHints } from '../src/services/localizedName';

type Handler = (params: unknown[]) => unknown;

function fakeD1(matchers: Array<{ sql: string; match?: (params: unknown[]) => boolean; handler: Handler }>) {
  return {
    prepare(sql: string) {
      const entries = matchers.filter((m) => sql.includes(m.sql));
      const exec = (params: unknown[]) => {
        const entry = entries.find((m) => !m.match || m.match(params));
        return {
          async first<T>() { return (entry ? await entry.handler(params) : null) as T; },
          async all<T>() { const result = (entry ? await entry.handler(params) : { results: [] }) as { results?: unknown }; return { results: (result.results ?? []) as T[] }; },
        };
      };
      return {
        ...exec([]),
        bind(...params: unknown[]) { return exec(params); },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

const NUMBER_EN = 'eng:number-name';
const PLURAL_EN = 'eng:plural-name';
const SINGULAR_EN = 'eng:singular-name';
const GENDER_EN = 'eng:gender-name';
const MASCULINE_EN = 'eng:masculine-name';
const ORPHAN_EN = 'eng:orphan-name';

describe('listMorphologicalFeatures', () => {
  it('orders dimensions and nested features by sort_order then code', async () => {
    const db = fakeD1([
      {
        sql: 'FROM morphological_dimensions ORDER BY',
        handler: () => ({ results: [
          { code: 'gender', name_expression_id: GENDER_EN, sort_order: 10 },
          { code: 'number', name_expression_id: NUMBER_EN, sort_order: 20 },
        ] }),
      },
      {
        sql: 'FROM morphological_features',
        handler: () => ({ results: [
          { code: 'masculine', dimension_code: 'gender', name_expression_id: MASCULINE_EN, sort_order: 1 },
          { code: 'singular', dimension_code: 'number', name_expression_id: SINGULAR_EN, sort_order: 1 },
          { code: 'plural', dimension_code: 'number', name_expression_id: PLURAL_EN, sort_order: 2 },
        ] }),
      },
      { sql: 'FROM all_expression_rows WHERE id IN', handler: () => ({ results: [
        { id: GENDER_EN, text: 'gender' },
        { id: NUMBER_EN, text: 'number' },
        { id: MASCULINE_EN, text: 'masculine' },
        { id: SINGULAR_EN, text: 'singular' },
        { id: PLURAL_EN, text: 'plural' },
      ] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [
        { source_id: NUMBER_EN, target_id: 'cmn:number', target_text: '数', score: 0, created_at: '2026-08-01' },
        { source_id: PLURAL_EN, target_id: 'cmn:plural', target_text: '复数', score: 0, created_at: '2026-08-01' },
        { source_id: SINGULAR_EN, target_id: 'cmn:singular', target_text: '单数', score: 0, created_at: '2026-08-01' },
        { source_id: GENDER_EN, target_id: 'cmn:gender', target_text: '性', score: 0, created_at: '2026-08-01' },
        { source_id: MASCULINE_EN, target_id: 'cmn:masculine', target_text: '阳性', score: 0, created_at: '2026-08-01' },
      ] }) },
    ]);
    const result = await listMorphologicalFeatures(db, parseLocaleHints('cmn-Hans-CN', undefined));
    expect(result.dimensions.map((d) => d.code)).toEqual(['gender', 'number']);
    expect(result.dimensions[1]?.features.map((f) => f.code)).toEqual(['singular', 'plural']);
    expect(result.dimensions[1]?.name).toBe('数');
    expect(result.dimensions[1]?.name_en).toBe('number');
    expect(result.dimensions[1]?.features[1]).toEqual({
      code: 'plural',
      name: '复数',
      name_en: 'plural',
      sort_order: 2,
    });
  });

  it('falls back to English text when the translation is missing', async () => {
    const db = fakeD1([
      {
        sql: 'FROM morphological_dimensions ORDER BY',
        handler: () => ({ results: [{ code: 'number', name_expression_id: NUMBER_EN, sort_order: 20 }] }),
      },
      {
        sql: 'FROM morphological_features',
        handler: () => ({ results: [{ code: 'plural', dimension_code: 'number', name_expression_id: PLURAL_EN, sort_order: 2 }] }),
      },
      { sql: 'FROM all_expression_rows WHERE id IN', handler: () => ({ results: [
        { id: NUMBER_EN, text: 'number' },
        { id: PLURAL_EN, text: 'plural' },
      ] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [] }) },
    ]);
    const result = await listMorphologicalFeatures(db, parseLocaleHints('cmn-Hans-CN', undefined));
    expect(result.dimensions[0]?.name).toBe('number');
    expect(result.dimensions[0]?.name_en).toBe('number');
    expect(result.dimensions[0]?.features[0]).toMatchObject({ name: 'plural', name_en: 'plural' });
  });

  it('falls back to code when the name expression is missing', async () => {
    const db = fakeD1([
      {
        sql: 'FROM morphological_dimensions ORDER BY',
        handler: () => ({ results: [{ code: 'aspect', name_expression_id: ORPHAN_EN, sort_order: 120 }] }),
      },
      {
        sql: 'FROM morphological_features',
        handler: () => ({ results: [{ code: 'perfect', dimension_code: 'aspect', name_expression_id: 'eng:missing', sort_order: 1 }] }),
      },
      { sql: 'FROM all_expression_rows WHERE id IN', handler: () => ({ results: [] }) },
    ]);
    const result = await listMorphologicalFeatures(db, {});
    expect(result.dimensions[0]?.name).toBe('aspect');
    expect(result.dimensions[0]?.name_en).toBe('aspect');
    expect(result.dimensions[0]?.features[0]).toMatchObject({ name: 'perfect', name_en: 'perfect' });
  });
});

interface StoredExpression {
  id: string;
  lang_code: string;
  text: string;
}

interface StoredFormEdge {
  id: string;
  form_id: string;
  lemma_id: string;
}

interface StoredFeature {
  code: string;
  dimension_code: string;
  name_expression_id: string;
  sort_order: number;
}

interface StoredDimension {
  code: string;
  sort_order: number;
}

interface MorphologyStore {
  expressions: Map<string, StoredExpression>;
  formEdges: StoredFormEdge[];
  formEdgeFeatures: Array<{ edge_id: string; feature_code: string }>;
  features: StoredFeature[];
  dimensions: StoredDimension[];
}

function morphologyStore(extra: StoredExpression[] = []): MorphologyStore {
  const catalogExpressions: StoredExpression[] = [
    { id: 'eng:feminine-name', lang_code: 'eng', text: 'feminine' },
    { id: 'eng:plural-name', lang_code: 'eng', text: 'plural' },
    { id: 'eng:masculine-name', lang_code: 'eng', text: 'masculine' },
    { id: 'eng:past-name', lang_code: 'eng', text: 'past' },
  ];
  const expressions = new Map<string, StoredExpression>();
  for (const row of [...catalogExpressions, ...extra]) expressions.set(row.id, row);
  return {
    expressions,
    formEdges: [],
    formEdgeFeatures: [],
    features: [
      { code: 'masculine', dimension_code: 'gender', name_expression_id: 'eng:masculine-name', sort_order: 1 },
      { code: 'feminine', dimension_code: 'gender', name_expression_id: 'eng:feminine-name', sort_order: 2 },
      { code: 'plural', dimension_code: 'number', name_expression_id: 'eng:plural-name', sort_order: 2 },
      { code: 'past', dimension_code: 'tense', name_expression_id: 'eng:past-name', sort_order: 2 },
    ],
    dimensions: [
      { code: 'gender', sort_order: 10 },
      { code: 'number', sort_order: 20 },
      { code: 'tense', sort_order: 40 },
    ],
  };
}

function storeD1(store: MorphologyStore) {
  const exec = (sql: string, params: unknown[]) => {
    if (sql.includes('e.form_id IN')) {
      const ids = new Set(JSON.parse(String(params[0] ?? '[]')) as string[]);
      const results = store.formEdges
        .filter((edge) => ids.has(edge.form_id))
        .map((edge) => {
          const lemma = store.expressions.get(edge.lemma_id);
          return {
            edge_id: edge.id,
            form_id: edge.form_id,
            lemma_id: lemma?.id ?? edge.lemma_id,
            lemma_text: lemma?.text ?? '',
            lemma_lang_code: lemma?.lang_code ?? '',
          };
        })
        .sort((a, b) => (a.form_id < b.form_id ? -1 : a.form_id > b.form_id ? 1 : a.lemma_id < b.lemma_id ? -1 : a.lemma_id > b.lemma_id ? 1 : 0));
      return { results };
    }
    if (sql.includes('FROM all_expression_rows WHERE id IN')) {
      const ids = JSON.parse(String(params[0] ?? '[]')) as string[];
      return { results: ids.map((id) => store.expressions.get(id)).filter((row): row is StoredExpression => Boolean(row)) };
    }
    if (sql.includes('FROM all_expression_rows WHERE id = ?')) {
      return store.expressions.get(String(params[0])) ?? null;
    }
    if (sql.includes('FROM expression_form_edges WHERE form_id = ? AND lemma_id = ?')) {
      return store.formEdges.find((edge) => edge.form_id === params[0] && edge.lemma_id === params[1]) ?? null;
    }
    if (sql.includes('INSERT INTO expression_form_edges')) {
      store.formEdges.push({
        id: String(params[0]),
        form_id: String(params[1]),
        lemma_id: String(params[2]),
      });
      return { success: true };
    }
    if (sql.includes('INSERT OR IGNORE INTO expression_form_edge_features')) {
      const edgeId = String(params[0]);
      const code = String(params[1]);
      if (!store.formEdgeFeatures.some((row) => row.edge_id === edgeId && row.feature_code === code)) {
        store.formEdgeFeatures.push({ edge_id: edgeId, feature_code: code });
      }
      return { success: true };
    }
    if (sql.includes('FROM morphological_features WHERE code IN')) {
      const codes = new Set(JSON.parse(String(params[0] ?? '[]')) as string[]);
      return { results: store.features.filter((row) => codes.has(row.code)).map((row) => ({ code: row.code })) };
    }
    if (sql.includes('FROM expression_form_edge_features')) {
      const edgeIds = new Set(JSON.parse(String(params[0] ?? '[]')) as string[]);
      const results = store.formEdgeFeatures
        .filter((row) => edgeIds.has(row.edge_id))
        .map((row) => {
          const feature = store.features.find((item) => item.code === row.feature_code);
          const dimension = store.dimensions.find((item) => item.code === feature?.dimension_code);
          return {
            edge_id: row.edge_id,
            code: row.feature_code,
            dimension_code: feature?.dimension_code ?? '',
            name_expression_id: feature?.name_expression_id ?? '',
            feature_sort: feature?.sort_order ?? 0,
            dimension_sort: dimension?.sort_order ?? 0,
          };
        })
        .sort((a, b) => a.dimension_sort - b.dimension_sort || a.feature_sort - b.feature_sort || a.code.localeCompare(b.code));
      return { results };
    }
    if (sql.includes('WHERE e.form_id = ?')) {
      const results = store.formEdges
        .filter((edge) => edge.form_id === params[0])
        .map((edge) => {
          const lemma = store.expressions.get(edge.lemma_id);
          return {
            edge_id: edge.id,
            neighbor_id: lemma?.id ?? edge.lemma_id,
            neighbor_text: lemma?.text ?? '',
            neighbor_lang_code: lemma?.lang_code ?? '',
          };
        })
        .sort((a, b) => (a.neighbor_id < b.neighbor_id ? -1 : a.neighbor_id > b.neighbor_id ? 1 : 0));
      return { results };
    }
    if (sql.includes('WHERE e.lemma_id = ?')) {
      const results = store.formEdges
        .filter((edge) => edge.lemma_id === params[0])
        .map((edge) => {
          const form = store.expressions.get(edge.form_id);
          return {
            edge_id: edge.id,
            neighbor_id: form?.id ?? edge.form_id,
            neighbor_text: form?.text ?? '',
            neighbor_lang_code: form?.lang_code ?? '',
          };
        });
      return { results };
    }
    if (sql.includes('FROM languages WHERE code IN')) {
      return { results: [] };
    }
    return { results: [] };
  };

  const bound = (sql: string, params: unknown[]) => ({
    async first<T>() {
      const result = exec(sql, params);
      if (result && typeof result === 'object' && 'results' in result) return ((result.results as T[])[0] ?? null) as T;
      return result as T;
    },
    async all<T>() {
      const result = exec(sql, params);
      return { results: (result && typeof result === 'object' && 'results' in result ? result.results : []) as T[] };
    },
    async run() {
      exec(sql, params);
      return { success: true };
    },
  });

  return {
    prepare(sql: string) {
      return {
        ...bound(sql, []),
        bind(...params: unknown[]) {
          return bound(sql, params);
        },
      };
    },
    async batch(statements: Array<{ run: () => Promise<unknown> }>) {
      for (const statement of statements) await statement.run();
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

const GATO = { id: 'spa:gato', lang_code: 'spa', text: 'gato' };
const GATAS = { id: 'spa:gatas', lang_code: 'spa', text: 'gatas' };
const GATOS = { id: 'spa:gatos', lang_code: 'spa', text: 'gatos' };
const CAT = { id: 'eng:cat', lang_code: 'eng', text: 'cat' };
const HINTS = parseLocaleHints(undefined, undefined);

function captureCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => (error instanceof MorphologyError ? error.code : String((error as { code?: string }).code ?? '')),
  );
}

describe('createFormEdge', () => {
  it('creates an edge between same-language expressions', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const result = await createFormEdge(storeD1(store), {
      formId: GATAS.id,
      lemmaId: GATO.id,
      features: ['feminine', 'plural'],
      source: 'contribution',
      createdBy: 1,
      hints: HINTS,
    });
    expect(result.created).toBe(true);
    expect(result.lemma).toMatchObject({ id: GATO.id, text: 'gato', lang_code: 'spa' });
    expect(result.features.map((item) => item.code)).toEqual(['feminine', 'plural']);
    expect(result.features[0]).toMatchObject({ name: 'feminine', dimension_code: 'gender' });
    expect(store.formEdges).toHaveLength(1);
    expect(store.formEdges[0]?.form_id < store.formEdges[0]?.lemma_id || store.formEdges[0]?.form_id > store.formEdges[0]?.lemma_id).toBe(true);
  });

  it('rejects a cross-language pair', async () => {
    const store = morphologyStore([GATO, CAT]);
    expect(await captureCode(() => createFormEdge(storeD1(store), {
      formId: CAT.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('FORM_EDGE_CROSS_LANGUAGE');
    expect(store.formEdges).toHaveLength(0);
  });

  it('rejects a self edge', async () => {
    const store = morphologyStore([GATO]);
    expect(await captureCode(() => createFormEdge(storeD1(store), {
      formId: GATO.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('FORM_EDGE_SELF');
  });

  it('rejects a mutual reverse edge', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const db = storeD1(store);
    await createFormEdge(db, { formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS });
    expect(await captureCode(() => createFormEdge(db, {
      formId: GATO.id, lemmaId: GATAS.id, source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('FORM_EDGE_MUTUAL');
    expect(store.formEdges).toHaveLength(1);
  });

  it('find-or-creates the same pair', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const db = storeD1(store);
    const first = await createFormEdge(db, { formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS });
    const second = await createFormEdge(db, { formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS });
    expect(first.created).toBe(true);
    expect(second.created).toBe(false);
    expect(second.edge_id).toBe(first.edge_id);
    expect(store.formEdges).toHaveLength(1);
  });

  it('unions features onto an existing edge', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const db = storeD1(store);
    await createFormEdge(db, {
      formId: GATAS.id, lemmaId: GATO.id, features: ['feminine'], source: 'contribution', createdBy: 1, hints: HINTS,
    });
    const again = await createFormEdge(db, {
      formId: GATAS.id, lemmaId: GATO.id, features: ['plural', 'feminine'], source: 'contribution', createdBy: 1, hints: HINTS,
    });
    expect(again.created).toBe(false);
    expect(again.features.map((item) => item.code)).toEqual(['feminine', 'plural']);
  });

  it('rejects an unknown feature and inserts nothing', async () => {
    const store = morphologyStore([GATO, GATAS]);
    expect(await captureCode(() => createFormEdge(storeD1(store), {
      formId: GATAS.id, lemmaId: GATO.id, features: ['feminine', 'not-a-feature'], source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('FORM_FEATURE_UNKNOWN');
    expect(store.formEdges).toHaveLength(0);
    expect(store.formEdgeFeatures).toHaveLength(0);
  });

  it('allows an empty feature list on a new edge', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const result = await createFormEdge(storeD1(store), {
      formId: GATAS.id, lemmaId: GATO.id, features: [], source: 'contribution', createdBy: 1, hints: HINTS,
    });
    expect(result.created).toBe(true);
    expect(result.features).toEqual([]);
  });

  it('leaves existing features unchanged when features is omitted', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const db = storeD1(store);
    await createFormEdge(db, {
      formId: GATAS.id, lemmaId: GATO.id, features: ['plural'], source: 'contribution', createdBy: 1, hints: HINTS,
    });
    const again = await createFormEdge(db, {
      formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS,
    });
    expect(again.created).toBe(false);
    expect(again.features.map((item) => item.code)).toEqual(['plural']);
  });

  it('allows one form to point at two lemmas', async () => {
    const store = morphologyStore([GATO, GATAS, GATOS]);
    const db = storeD1(store);
    await createFormEdge(db, { formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: GATAS.id, lemmaId: GATOS.id, source: 'contribution', createdBy: 1, hints: HINTS });
    expect(store.formEdges).toHaveLength(2);
  });

  it('allows the same node to be both form and lemma', async () => {
    const found = { id: 'spa:found', lang_code: 'spa', text: 'found' };
    const find = { id: 'spa:find', lang_code: 'spa', text: 'find' };
    const founded = { id: 'spa:founded', lang_code: 'spa', text: 'founded' };
    const store = morphologyStore([found, find, founded]);
    const db = storeD1(store);
    await createFormEdge(db, { formId: found.id, lemmaId: find.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: founded.id, lemmaId: found.id, source: 'contribution', createdBy: 1, hints: HINTS });
    const asBoth = await getExpressionFormEdges(db, found.id, { limit: 20, hints: HINTS });
    expect(asBoth.as_form.map((item) => item.lemma.id)).toEqual([find.id]);
    expect(asBoth.as_lemma.map((item) => item.form.id)).toEqual([founded.id]);
  });

  it('rejects empty ids', async () => {
    const store = morphologyStore([GATO]);
    expect(await captureCode(() => createFormEdge(storeD1(store), {
      formId: '   ', lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('VALIDATION_FAILED');
  });

  it('rejects a missing expression', async () => {
    const store = morphologyStore([GATO]);
    expect(await captureCode(() => createFormEdge(storeD1(store), {
      formId: GATAS.id, lemmaId: GATO.id, source: 'contribution', createdBy: 1, hints: HINTS,
    }))).toBe('EXPRESSION_NOT_FOUND');
  });
});

describe('getExpressionFormEdges', () => {
  it('sorts as_form by lemma id and as_lemma by feature key then form id, truncating per direction', async () => {
    const center = { id: 'spa:center', lang_code: 'spa', text: 'center' };
    const lemmaA = { id: 'spa:lemma-a', lang_code: 'spa', text: 'lemma-a' };
    const lemmaZ = { id: 'spa:lemma-z', lang_code: 'spa', text: 'lemma-z' };
    const formFem = { id: 'spa:form-fem', lang_code: 'spa', text: 'form-fem' };
    const formPlu = { id: 'spa:form-plu', lang_code: 'spa', text: 'form-plu' };
    const formNone = { id: 'spa:form-none', lang_code: 'spa', text: 'form-none' };
    const formPast = { id: 'spa:form-past', lang_code: 'spa', text: 'form-past' };
    const store = morphologyStore([center, lemmaA, lemmaZ, formFem, formPlu, formNone, formPast]);
    const db = storeD1(store);
    await createFormEdge(db, { formId: center.id, lemmaId: lemmaZ.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: center.id, lemmaId: lemmaA.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: formPlu.id, lemmaId: center.id, features: ['plural'], source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: formNone.id, lemmaId: center.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: formFem.id, lemmaId: center.id, features: ['feminine'], source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: formPast.id, lemmaId: center.id, features: ['past'], source: 'contribution', createdBy: 1, hints: HINTS });

    const full = await getExpressionFormEdges(db, center.id, { limit: 20, hints: HINTS });
    expect(full.as_form.map((item) => item.lemma.id)).toEqual([lemmaA.id, lemmaZ.id]);
    expect(full.as_lemma.map((item) => item.form.id)).toEqual([formFem.id, formPlu.id, formPast.id, formNone.id]);
    expect(full.as_form_truncated).toBe(false);
    expect(full.as_lemma_truncated).toBe(false);

    const limited = await getExpressionFormEdges(db, center.id, { limit: 1, hints: HINTS });
    expect(limited.as_form.map((item) => item.lemma.id)).toEqual([lemmaA.id]);
    expect(limited.as_lemma.map((item) => item.form.id)).toEqual([formFem.id]);
    expect(limited.as_form_truncated).toBe(true);
    expect(limited.as_form_omitted_count).toBe(1);
    expect(limited.as_lemma_truncated).toBe(true);
    expect(limited.as_lemma_omitted_count).toBe(3);
  });

  it('throws EXPRESSION_NOT_FOUND when the expression is missing', async () => {
    const store = morphologyStore();
    expect(await captureCode(() => getExpressionFormEdges(storeD1(store), 'spa:missing', { limit: 20, hints: HINTS }))).toBe('EXPRESSION_NOT_FOUND');
  });
});

describe('attachFormOf', () => {
  it('returns empty arrays when there are no form edges', async () => {
    const store = morphologyStore([GATO, GATAS]);
    const attached = await attachFormOf(storeD1(store), [GATAS.id, GATO.id], HINTS);
    expect(attached.get(GATAS.id)).toEqual([]);
    expect(attached.get(GATO.id)).toEqual([]);
  });

  it('keeps at most 3 lemmas per form, ordered by lemma_id ASC', async () => {
    const lemmaB = { id: 'spa:lemma-b', lang_code: 'spa', text: 'lemma-b' };
    const lemmaC = { id: 'spa:lemma-c', lang_code: 'spa', text: 'lemma-c' };
    const lemmaD = { id: 'spa:lemma-d', lang_code: 'spa', text: 'lemma-d' };
    const store = morphologyStore([GATAS, GATO, lemmaB, lemmaC, lemmaD]);
    const db = storeD1(store);
    await createFormEdge(db, { formId: GATAS.id, lemmaId: lemmaD.id, features: ['plural'], source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: GATAS.id, lemmaId: GATO.id, features: ['feminine', 'plural'], source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: GATAS.id, lemmaId: lemmaC.id, source: 'contribution', createdBy: 1, hints: HINTS });
    await createFormEdge(db, { formId: GATAS.id, lemmaId: lemmaB.id, source: 'contribution', createdBy: 1, hints: HINTS });

    const attached = await attachFormOf(db, [GATAS.id], HINTS);
    const formOf = attached.get(GATAS.id) ?? [];
    expect(formOf.map((item) => item.lemma.id)).toEqual([GATO.id, lemmaB.id, lemmaC.id]);
    expect(formOf[0]?.features.map((item) => item.code)).toEqual(['feminine', 'plural']);
    expect(formOf[0]?.features[1]).toEqual({ code: 'plural', name: 'plural' });
    expect(formOf[0]?.lemma).toEqual({ id: GATO.id, text: 'gato', lang_code: 'spa' });
  });
});
