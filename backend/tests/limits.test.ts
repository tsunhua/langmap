import { describe, expect, it } from 'vitest';
import {
  D1_WRITE_CHUNK_SIZE,
  MAX_CONTRIBUTION_EXPRESSIONS,
  MAX_HANDBOOK_ITEMS,
  MAX_HANDBOOK_SECTIONS,
  MAX_LOCALIZATION_MAPPINGS,
  MAX_SPLIT_EDGE_IDS,
  exceedsLimit,
} from '../src/utils/limits';

describe('performance workload limits', () => {
  it('keeps mutation and write chunk limits explicit', () => {
    expect({
      contributions: MAX_CONTRIBUTION_EXPRESSIONS,
      localization: MAX_LOCALIZATION_MAPPINGS,
      sections: MAX_HANDBOOK_SECTIONS,
      items: MAX_HANDBOOK_ITEMS,
      edges: MAX_SPLIT_EDGE_IDS,
      chunk: D1_WRITE_CHUNK_SIZE,
    }).toEqual({ contributions: 50, localization: 100, sections: 50, items: 500, edges: 100, chunk: 50 });
  });

  it('only rejects integer values over the configured maximum', () => {
    expect(exceedsLimit(50, 50)).toBe(false);
    expect(exceedsLimit(51, 50)).toBe(true);
    expect(exceedsLimit(Number.NaN, 50)).toBe(true);
  });
});
