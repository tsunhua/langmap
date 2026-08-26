import { describe, expect, it } from 'vitest';
import { getMappingGraph } from '../src/services/mappingGraph';
import { parseLocaleHints } from '../src/services/localizedName';

type Edge = {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  created_at: string;
  expression_a_text: string;
  expression_a_lang_code: string;
  expression_b_text: string;
  expression_b_lang_code: string;
};

function fakeD1(edges: Edge[], maxBindVariables = Number.POSITIVE_INFINITY, filterByArgs = false) {
  return {
    prepare(sql: string) {
      return {
        bind(...args: unknown[]) {
          if (sql.includes('FROM all_expression_edges') && args.length > maxBindVariables) {
            throw new Error('too many SQL variables');
          }
          return {
            first: async <T>() => (sql.includes('FROM all_expression_rows') ? { id: args[0], text: '食', lang_code: 'nan', language_name: 'Minnan' } : null) as T,
            all: async <T>() => ({
              results: (sql.includes('FROM all_expression_edges')
                ? (filterByArgs ? edges.filter((edge) => args.includes(edge.expression_a_id) || args.includes(edge.expression_b_id)) : edges)
                : []) as T[],
            }),
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

describe('getMappingGraph', () => {
  it('traverses a cycle once and returns stable TEXT ids', async () => {
    const graph = await getMappingGraph(fakeD1([
      { id: 'e1', expression_a_id: 'eng:a', expression_b_id: 'nan:root', score: 2, created_at: '2026-08-01', expression_a_text: 'rice', expression_a_lang_code: 'eng', expression_b_text: '食', expression_b_lang_code: 'nan' },
      { id: 'e2', expression_a_id: 'eng:a', expression_b_id: 'jpn:b', score: 1, created_at: '2026-08-02', expression_a_text: 'rice', expression_a_lang_code: 'eng', expression_b_text: '米', expression_b_lang_code: 'jpn' },
      { id: 'e3', expression_a_id: 'jpn:b', expression_b_id: 'nan:root', score: 0, created_at: '2026-08-03', expression_a_text: '米', expression_a_lang_code: 'jpn', expression_b_text: '食', expression_b_lang_code: 'nan' },
    ]), 'nan:root', 3, 200);

    expect(graph?.nodes.map((node) => node.expression_id)).toEqual(['nan:root', 'eng:a', 'jpn:b']);
    expect(new Set(graph?.edges.map((edge) => edge.edge_id)).size).toBe(graph?.edges.length);
  });

  it('sets truncated and omitted_count at the node limit', async () => {
    const graph = await getMappingGraph(fakeD1([
      { id: 'e1', expression_a_id: 'eng:a', expression_b_id: 'nan:root', score: 2, created_at: '2026-08-01', expression_a_text: 'rice', expression_a_lang_code: 'eng', expression_b_text: '食', expression_b_lang_code: 'nan' },
      { id: 'e2', expression_a_id: 'jpn:b', expression_b_id: 'nan:root', score: 1, created_at: '2026-08-02', expression_a_text: '米', expression_a_lang_code: 'jpn', expression_b_text: '食', expression_b_lang_code: 'nan' },
    ]), 'nan:root', 3, 2);

    expect(graph).toMatchObject({ truncated: true, omitted_count: 1 });
    expect(graph?.edges.every((edge) =>
      graph.nodes.some((node) => node.expression_id === edge.source_id)
      && graph.nodes.some((node) => node.expression_id === edge.target_id),
    )).toBe(true);
  });

  it('resolves node language names via the shared resolver', async () => {
    const graph = await getMappingGraph(
      fakeD1([
        { id: 'e1', expression_a_id: 'eng:a', expression_b_id: 'nan:root', score: 2, created_at: '2026-08-01', expression_a_text: 'rice', expression_a_lang_code: 'eng', expression_b_text: '食', expression_b_lang_code: 'nan' },
      ]),
      'nan:root', 1, 200, parseLocaleHints('cmn-Hans-CN', undefined),
    );
    // nan has an explicit UI-locale override; unknown eng falls back to its code.
    expect(graph?.nodes.map((node) => node.language_name)).toEqual(['闽南语', 'eng']);
  });

  it('batches large frontiers before querying a three-hop graph', async () => {
    const edges: Edge[] = [];
    for (let index = 0; index < 60; index += 1) {
      const suffix = String(index).padStart(2, '0');
      edges.push(
        { id: `root-${suffix}`, expression_a_id: `eng:hop-${suffix}`, expression_b_id: 'nan:root', score: 2, created_at: `2026-08-01T00:00:${suffix}`, expression_a_text: `hop ${suffix}`, expression_a_lang_code: 'eng', expression_b_text: '食', expression_b_lang_code: 'nan' },
        { id: `middle-${suffix}`, expression_a_id: `eng:hop-${suffix}`, expression_b_id: `jpn:next-${suffix}`, score: 1, created_at: `2026-08-02T00:00:${suffix}`, expression_a_text: `hop ${suffix}`, expression_a_lang_code: 'eng', expression_b_text: `next ${suffix}`, expression_b_lang_code: 'jpn' },
        { id: `final-${suffix}`, expression_a_id: `jpn:next-${suffix}`, expression_b_id: `yue:final-${suffix}`, score: 0, created_at: `2026-08-03T00:00:${suffix}`, expression_a_text: `next ${suffix}`, expression_a_lang_code: 'jpn', expression_b_text: `final ${suffix}`, expression_b_lang_code: 'yue' },
      );
    }

    const graph = await getMappingGraph(fakeD1(edges, 100, true), 'nan:root', 3, 200);

    expect(graph).toMatchObject({
      resolved_hops: 3,
      layer_counts: { 0: 1, 1: 60, 2: 60, 3: 60 },
      truncated: false,
    });
    expect(graph?.nodes).toHaveLength(181);
  });
});
