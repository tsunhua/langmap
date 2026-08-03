import { describe, expect, it } from 'vitest';
import {
  buildMappingGraph,
  parseMappingHops,
} from '../src/utils/mappingGraph';
import type {
  ExpressionRow,
  NeighborRow,
} from '../src/utils/mappingGraph';

interface Fixture {
  expressions: Map<number, ExpressionRow>;
  edges: NeighborRow[];
}

function expr(id: number, text = `t${id}`, lang = 'en'): ExpressionRow {
  return {
    expression_id: id,
    text,
    language_profile_code: lang,
    language_name: `Lang ${lang}`,
  };
}

function exprMap(...rows: ExpressionRow[]): Map<number, ExpressionRow> {
  const m = new Map<number, ExpressionRow>();
  for (const r of rows) m.set(r.expression_id, r);
  return m;
}

function edge(id: string, a: number, b: number, score = 0): NeighborRow {
  return { edge_id: id, expression_a_id: a, expression_b_id: b, score };
}

function makeLoaders(fixture: Fixture) {
  const loadExpressions = async (ids: number[]): Promise<ExpressionRow[]> => {
    const seen = new Set<number>();
    const out: ExpressionRow[] = [];
    for (const id of ids) {
      if (seen.has(id)) continue;
      seen.add(id);
      const row = fixture.expressions.get(id);
      if (row) out.push(row);
    }
    out.sort((a, b) => a.expression_id - b.expression_id);
    return out;
  };

  const loadEdges = async (frontierIds: number[]): Promise<NeighborRow[]> => {
    const frontier = new Set(frontierIds);
    const out = fixture.edges.filter(
      (e) => frontier.has(e.expression_a_id) || frontier.has(e.expression_b_id),
    );
    out.sort((a, b) => {
      if (a.score !== b.score) return b.score - a.score;
      return a.edge_id.localeCompare(b.edge_id);
    });
    return out;
  };

  return { loadExpressions, loadEdges };
}

async function run(fixture: Fixture, rootId: number, requestedHops: 1 | 2 | 3) {
  const { loadExpressions, loadEdges } = makeLoaders(fixture);
  return buildMappingGraph(rootId, requestedHops, loadEdges, loadExpressions);
}

describe('buildMappingGraph', () => {
  it('hops=1 returns only root and direct neighbors', async () => {
    const fixture: Fixture = {
      expressions: exprMap(
        expr(1, 'root'),
        expr(2, 'a'),
        expr(3, 'b'),
        expr(4, 'c-deep'),
      ),
      edges: [
        edge('e1-2', 1, 2, 5),
        edge('e1-3', 1, 3, 3),
        edge('e2-4', 2, 4, 1),
      ],
    };

    const graph = await run(fixture, 1, 1);

    expect(graph.root_id).toBe(1);
    expect(graph.requested_hops).toBe(1);
    expect(graph.resolved_hops).toBe(1);
    expect(graph.nodes.map((n) => n.expression_id).sort((a, b) => a - b))
      .toEqual([1, 2, 3]);
    expect(graph.nodes.find((n) => n.expression_id === 1)?.depth).toBe(0);
    expect(graph.nodes.find((n) => n.expression_id === 2)?.depth).toBe(1);
    expect(graph.nodes.find((n) => n.expression_id === 3)?.depth).toBe(1);
    expect(graph.nodes.find((n) => n.expression_id === 4)).toBeUndefined();
    expect(graph.truncated).toBe(false);
    expect(graph.omitted_count).toBe(0);
    expect(graph.layer_counts).toEqual({ 0: 1, 1: 2 });
  });

  it('hops=3 truly reaches depth 3', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1), expr(2), expr(3), expr(4)),
      edges: [
        edge('e1-2', 1, 2),
        edge('e2-3', 2, 3),
        edge('e3-4', 3, 4),
      ],
    };

    const graph = await run(fixture, 1, 3);

    expect(graph.resolved_hops).toBe(3);
    expect(graph.nodes.find((n) => n.expression_id === 4)?.depth).toBe(3);
    expect(graph.layer_counts).toEqual({ 0: 1, 1: 1, 2: 1, 3: 1 });
  });

  it('A-B-C-A cycle does not duplicate nodes or loop forever', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1, 'A'), expr(2, 'B'), expr(3, 'C')),
      edges: [
        edge('e1-2', 1, 2),
        edge('e2-3', 2, 3),
        edge('e3-1', 3, 1),
      ],
    };

    const graph = await run(fixture, 1, 3);

    const ids = graph.nodes.map((n) => n.expression_id).sort((a, b) => a - b);
    expect(ids).toEqual([1, 2, 3]);
    expect(graph.nodes.find((n) => n.expression_id === 1)?.depth).toBe(0);
    expect(graph.nodes.find((n) => n.expression_id === 2)?.depth).toBe(1);
    expect(graph.nodes.find((n) => n.expression_id === 3)?.depth).toBe(1);
    expect(new Set(graph.edges.map((e) => e.edge_id)).size).toBe(graph.edges.length);
  });

  it('node with two parents appears once but keeps both edges', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1), expr(2, 'B'), expr(3, 'C'), expr(4, 'D')),
      edges: [
        edge('e1-2', 1, 2, 10),
        edge('e1-3', 1, 3, 8),
        edge('e2-4', 2, 4, 4),
        edge('e3-4', 3, 4, 2),
      ],
    };

    const graph = await run(fixture, 1, 2);

    const d = graph.nodes.find((n) => n.expression_id === 4);
    expect(d).toBeDefined();
    expect(d?.depth).toBe(2);
    expect(graph.nodes.filter((n) => n.expression_id === 4)).toHaveLength(1);

    const dEdges = graph.edges.filter(
      (e) => e.source_id === 4 || e.target_id === 4,
    );
    expect(dEdges.map((e) => e.edge_id).sort()).toEqual(['e2-4', 'e3-4']);
  });

  it('directs edges from shallow to deep', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1), expr(2), expr(3)),
      edges: [
        edge('e1-2', 2, 1, 5),
        edge('e2-3', 2, 3, 2),
      ],
    };

    const graph = await run(fixture, 1, 2);

    const e12 = graph.edges.find((e) => e.edge_id === 'e1-2')!;
    expect(e12.source_id).toBe(1);
    expect(e12.target_id).toBe(2);
    expect(e12.depth).toBe(1);

    const e23 = graph.edges.find((e) => e.edge_id === 'e2-3')!;
    expect(e23.source_id).toBe(2);
    expect(e23.target_id).toBe(3);
    expect(e23.depth).toBe(2);
  });

  it('keeps same-depth cross edge direction stable (smaller id as source)', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1), expr(20), expr(30)),
      edges: [
        edge('e1-20', 1, 20),
        edge('e1-30', 1, 30),
        edge('e20-30', 30, 20),
      ],
    };

    const graph = await run(fixture, 1, 2);

    const cross = graph.edges.find((e) => e.edge_id === 'e20-30')!;
    expect(cross.source_id).toBe(20);
    expect(cross.target_id).toBe(30);
    expect(cross.depth).toBe(1);
  });

  it('produces identical output regardless of neighbor input order', async () => {
    const buildFixture = (): Fixture => ({
      expressions: exprMap(expr(1), expr(2), expr(3), expr(4), expr(5)),
      edges: [
        edge('e1-2', 1, 2, 9),
        edge('e1-3', 1, 3, 7),
        edge('e1-4', 1, 4, 5),
        edge('e3-5', 3, 5, 3),
        edge('e2-5', 2, 5, 1),
      ],
    });

    const base = await run(buildFixture(), 1, 2);

    const shuffled: Fixture = {
      expressions: base.nodes.reduce((m, n) => {
        m.set(n.expression_id, expr(n.expression_id, n.text, n.language_profile_code));
        return m;
      }, new Map<number, ExpressionRow>()),
      edges: [...buildFixture().edges].reverse(),
    };
    const again = await run(shuffled, 1, 2);

    expect(again.nodes).toEqual(base.nodes);
    expect(again.edges).toEqual(base.edges);
    expect(again.layer_counts).toEqual(base.layer_counts);
  });

  it('respects node cap and reports truncated + omitted_count', async () => {
    const expressions = exprMap(expr(1, 'root'));
    const edges: NeighborRow[] = [];
    for (let i = 2; i <= 12; i++) {
      expressions.set(i, expr(i));
      edges.push(edge(`e1-${i}`, 1, i, 10 - i));
    }

    const fixture: Fixture = { expressions, edges };
    const { loadExpressions, loadEdges } = makeLoaders(fixture);
    const graph = await buildMappingGraph(1, 1, loadEdges, loadExpressions, 5);

    expect(graph.nodes.length).toBeLessThanOrEqual(5);
    expect(graph.truncated).toBe(true);
    expect(graph.omitted_count).toBeGreaterThan(0);
    const included = new Set(graph.nodes.map((n) => n.expression_id));
    for (const e of graph.edges) {
      expect(included.has(e.source_id)).toBe(true);
      expect(included.has(e.target_id)).toBe(true);
    }
  });

  it('root with no neighbors resolves to hops 0 with single node', async () => {
    const fixture: Fixture = {
      expressions: exprMap(expr(1, 'lonely')),
      edges: [],
    };

    const graph = await run(fixture, 1, 3);

    expect(graph.resolved_hops).toBe(0);
    expect(graph.nodes).toHaveLength(1);
    expect(graph.edges).toHaveLength(0);
    expect(graph.layer_counts).toEqual({ 0: 1 });
    expect(graph.truncated).toBe(false);
  });
});

describe('parseMappingHops', () => {
  it('defaults to 1 when missing', () => {
    expect(parseMappingHops(undefined)).toBe(1);
    expect(parseMappingHops('')).toBe(1);
  });
  it('clamps below 1 up to 1', () => {
    expect(parseMappingHops('0')).toBe(1);
    expect(parseMappingHops('-3')).toBe(1);
  });
  it('clamps above 3 down to 3', () => {
    expect(parseMappingHops('4')).toBe(3);
    expect(parseMappingHops('99')).toBe(3);
  });
  it('falls back to 1 on non-numeric', () => {
    expect(parseMappingHops('abc')).toBe(1);
    expect(parseMappingHops('NaN')).toBe(1);
  });
  it('passes through valid 1/2/3', () => {
    expect(parseMappingHops('1')).toBe(1);
    expect(parseMappingHops('2')).toBe(2);
    expect(parseMappingHops('3')).toBe(3);
  });
});
