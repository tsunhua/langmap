// The managed-dictionary release/eligibility predicates this suite covered were
// removed with the canonical dictionary storage refactor. Dictionary ownership
// now lives only as per-object source markers in `expression_sources` /
// `expression_edge_sources`, surfaced by the mapping graph as `edge.sources`.
import { describe, expect, it } from 'vitest';
import { getMappingGraph } from '../src/services/mappingGraph';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

const ROOT_SQL = 'SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?';
const EDGE_SQL = 'SELECT id,expression_a_id,expression_b_id,relation_mask,score FROM expression_edges WHERE (expression_a_id IN (?) OR expression_b_id IN (?)) AND (relation_mask & 3) <> 0 ORDER BY id';
const NODE_SQL = 'SELECT e.id,e.text,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id IN (?)';
const EDGE_SOURCES_SQL = 'SELECT edge_id,source_id,source_marker FROM expression_edge_sources WHERE edge_id IN (?) ORDER BY edge_id,source_id,source_marker';

describe('dictionary edge provenance', () => {
  it('attaches dictionary source markers to edges instead of release predicates', async () => {
    const db = fakeD1({
      [ROOT_SQL]: () => ({ id: 1, text: '食', lang_code: 'nan' }),
      [EDGE_SQL]: () => ({ results: [{ id: 10, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 3 }] }),
      [NODE_SQL]: () => ({ results: [{ id: 2, text: 'eat', lang_code: 'eng' }] }),
      [EDGE_SOURCES_SQL]: () => ({
        results: [
          { edge_id: 10, source_id: 5, source_marker: '1' },
          { edge_id: 10, source_id: 6, source_marker: '2' },
        ],
      }),
    });

    const graph = await getMappingGraph(db, 1, 1);

    expect(graph?.edges[0].sources).toEqual([
      { source_id: 5, marker: '1' },
      { source_id: 6, marker: '2' },
    ]);
  });

  it('keeps edge sources empty when the provenance table is unavailable', async () => {
    const db = fakeD1({
      [ROOT_SQL]: () => ({ id: 1, text: '食', lang_code: 'nan' }),
      [EDGE_SQL]: () => ({ results: [{ id: 10, expression_a_id: 1, expression_b_id: 2, relation_mask: 1, score: 3 }] }),
      [NODE_SQL]: () => ({ results: [{ id: 2, text: 'eat', lang_code: 'eng' }] }),
      [EDGE_SOURCES_SQL]: () => { throw new Error('no such table: expression_edge_sources'); },
    });

    const graph = await getMappingGraph(db, 1, 1);

    expect(graph?.edges[0].sources).toEqual([]);
  });
});
