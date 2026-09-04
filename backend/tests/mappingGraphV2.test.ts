import { describe, expect, it } from 'vitest';
import { getMappingGraph } from '../src/services/mappingGraph';

type Edge = { id: number; expression_a_id: number; expression_b_id: number; relation_mask: number; score: number };
type NodeSeed = Record<number, { text: string; lang_code: string }>;

/**
 * Emulates the three query shapes the service issues:
 * 1. root lookup  SELECT ... FROM expressions e JOIN languages l ... WHERE e.id=?
 * 2. edge lookup  SELECT id,expression_a_id,expression_b_id,relation_mask,score FROM expression_edges WHERE ... IN (...)
 * 3. node lookup  SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ... WHERE e.id IN (...)
 */
function fakeD1(nodes: NodeSeed, edges: Edge[], maxBindVariables?: number) {
  return {
    prepare(sql: string) {
      return {
        bind(...args: number[]) {
          if (maxBindVariables && sql.includes('FROM expression_edges') && args.length > maxBindVariables) {
            throw new Error('too many SQL variables');
          }
          return {
            first: async <T>() => {
              // Root lookup is the only query without an e.id IN (...)
              if (sql.includes('FROM expressions') && !sql.includes('e.id IN')) {
                const row = nodes[args[0]];
                return row ? { id: args[0], ...row } as T : null;
              }
              return null as T;
            },
            all: async <T>() => {
              let results: unknown[] = [];
              if (sql.includes('FROM expression_edges')) {
                results = edges.filter((edge) => args.includes(edge.expression_a_id) || args.includes(edge.expression_b_id));
              } else if (sql.includes('FROM expressions')) {
                results = args
                  .filter((id) => nodes[id])
                  .map((id) => ({ id, ...nodes[id] }));
              }
              return { results: results as T[] };
            },
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

describe('getMappingGraph', () => {
  it('traverses a cycle once and returns depth-stable integer ids', async () => {
    const nodes: NodeSeed = {
      1: { text: '食', lang_code: 'nan' },
      2: { text: 'rice', lang_code: 'eng' },
      3: { text: '米', lang_code: 'jpn' },
    };
    const edges: Edge[] = [
      { id: 1, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 2 },
      // a ↔ b cycle: single traversal, no duplicate nodes or re-expansion.
      { id: 2, expression_a_id: 2, expression_b_id: 3, relation_mask: 1, score: 1 },
      { id: 3, expression_a_id: 3, expression_b_id: 2, relation_mask: 1, score: 0 },
    ];

    const graph = await getMappingGraph(fakeD1(nodes, edges), 1, 3);

    expect(graph?.nodes.map((node) => node.expression_id)).toEqual([1, 2, 3]);
    expect(graph?.nodes.map((node) => node.depth)).toEqual([0, 1, 2]);
    // Unresolved registry names fall back to the language code.
    expect(graph?.nodes[0]).toMatchObject({ lang_code: 'nan', language_name: 'nan' });
    expect(new Set(graph?.edges.map((edge) => edge.edge_id)).size).toBe(graph?.edges.length);
  });

  it('filters nodes at every hop so traversal never hops through excluded languages', async () => {
    const nodes: NodeSeed = {
      1: { text: 'український', lang_code: 'ukr' },
      2: { text: 'rice', lang_code: 'eng' },
      3: { text: 'рис', lang_code: 'rus' },
      4: { text: 'first eng hop', lang_code: 'eng' },
      5: { text: 'eng only reachable via rus', lang_code: 'eng' },
    };
    const edges: Edge[] = [
      { id: 1, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 2 },
      { id: 2, expression_a_id: 1, expression_b_id: 3, relation_mask: 1, score: 2 },
      { id: 3, expression_a_id: 2, expression_b_id: 4, relation_mask: 1, score: 1 },
      // Only reachable through the excluded rus node.
      { id: 4, expression_a_id: 3, expression_b_id: 5, relation_mask: 1, score: 0 },
    ];

    const graph = await getMappingGraph(fakeD1(nodes, edges), 1, 2, 'eng');

    expect(graph?.nodes.map((node) => node.expression_id).sort()).toEqual([1, 2, 4]);
    expect(graph?.layer_counts).toEqual({ 0: 1, 1: 1, 2: 1, 3: 0 });
    // Edges to/from excluded languages are dropped; only edges between kept nodes remain.
    expect(graph?.edges.map((edge) => edge.edge_id).sort()).toEqual([1, 3]);
  });

  it('supports a comma-separated multi-language filter', async () => {
    const nodes: NodeSeed = {
      1: { text: 'український', lang_code: 'ukr' },
      2: { text: 'rice', lang_code: 'eng' },
      3: { text: 'рис', lang_code: 'rus' },
      4: { text: 'first eng hop', lang_code: 'eng' },
      5: { text: 'first rus hop', lang_code: 'rus' },
    };
    const edges: Edge[] = [
      { id: 1, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 2 },
      { id: 2, expression_a_id: 1, expression_b_id: 3, relation_mask: 1, score: 2 },
      { id: 3, expression_a_id: 2, expression_b_id: 4, relation_mask: 1, score: 1 },
      { id: 4, expression_a_id: 3, expression_b_id: 5, relation_mask: 1, score: 1 },
    ];

    const graph = await getMappingGraph(fakeD1(nodes, edges), 1, 2, 'enG, rus');

    expect(graph?.nodes.map((node) => node.expression_id).sort()).toEqual([1, 2, 3, 4, 5]);
    expect(graph?.nodes.map((node) => node.lang_code).sort()).toEqual(['eng', 'eng', 'rus', 'rus', 'ukr']);
  });

  it('keeps only the root when the filter matches no reachable language', async () => {
    const nodes: NodeSeed = {
      1: { text: 'український', lang_code: 'ukr' },
      2: { text: 'rice', lang_code: 'eng' },
    };
    const edges: Edge[] = [
      { id: 1, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 2 },
    ];

    const graph = await getMappingGraph(fakeD1(nodes, edges), 1, 2, 'zsm');

    expect(graph?.nodes.map((node) => node.expression_id)).toEqual([1]);
    expect(graph?.edges).toEqual([]);
    expect(graph?.resolved_hops).toBe(1);
  });

  it('sets truncated and omitted_count at the node limit', async () => {
    const nodes: NodeSeed = { 1: { text: '食', lang_code: 'nan' } };
    const edges: Edge[] = [];
    for (let index = 0; index < 201; index += 1) {
      const id = 2 + index;
      nodes[id] = { text: `hop ${id}`, lang_code: 'eng' };
      edges.push({ id: index + 1, expression_a_id: 1, expression_b_id: id, relation_mask: 1, score: 2 });
    }

    const graph = await getMappingGraph(fakeD1(nodes, edges), 1, 1);

    // Root already counts toward the limit, so 199 of the 201 candidates fit.
    expect(graph).toMatchObject({ truncated: true, omitted_count: 2, layer_counts: { 0: 1, 1: 199, 2: 0, 3: 0 } });
    expect(graph?.edges.every((edge) =>
      graph.nodes.some((node) => node.expression_id === edge.source_id)
      && graph.nodes.some((node) => node.expression_id === edge.target_id),
    )).toBe(true);
  });

  it('keeps three-hop traversal within the D1 bind-variable limit', async () => {
    const nodes: NodeSeed = { 1: { text: 'root', lang_code: 'eng' } };
    const edges: Edge[] = [];
    for (let index = 0; index < 51; index += 1) {
      const firstHopId = 2 + index;
      const secondHopId = 53 + index;
      nodes[firstHopId] = { text: `first ${firstHopId}`, lang_code: 'cmn' };
      nodes[secondHopId] = { text: `second ${secondHopId}`, lang_code: 'jpn' };
      edges.push(
        { id: index + 1, expression_a_id: 1, expression_b_id: firstHopId, relation_mask: 1, score: 1 },
        { id: index + 52, expression_a_id: firstHopId, expression_b_id: secondHopId, relation_mask: 1, score: 1 },
      );
    }

    const graph = await getMappingGraph(fakeD1(nodes, edges, 100), 1, 3);

    expect(graph).toMatchObject({ resolved_hops: 3, truncated: false });
    expect(graph?.nodes).toHaveLength(103);
  });
});
