import { describe, it, expect } from 'vitest';
import { edgesForGroup } from './edges';

describe('edgesForGroup', () => {
  it('3 members → 3 edges', () => {
    expect(edgesForGroup([1, 2, 3])).toEqual([
      { id: '1-2', a: 1, b: 2 },
      { id: '1-3', a: 1, b: 3 },
      { id: '2-3', a: 2, b: 3 },
    ]);
  });
  it('排序後產 id,小 id 在前(無向)', () => {
    const e = edgesForGroup([30, 5]);
    expect(e).toEqual([{ id: '5-30', a: 5, b: 30 }]);
  });
  it('0 或 1 個成員 → 無邊', () => {
    expect(edgesForGroup([])).toEqual([]);
    expect(edgesForGroup([7])).toEqual([]);
  });
});
