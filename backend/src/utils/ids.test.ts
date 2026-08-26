import { describe, expect, it } from 'vitest';
import { parseIntegerId, serializeIntegerId } from './ids';

describe('numeric API IDs', () => {
  it('accepts canonical positive decimal strings', () => {
    expect(parseIntegerId('1')).toBe(1);
    expect(parseIntegerId('2056')).toBe(2056);
    expect(parseIntegerId(String(Number.MAX_SAFE_INTEGER))).toBe(Number.MAX_SAFE_INTEGER);
  });

  it('rejects non-canonical or unsafe route IDs', () => {
    for (const value of ['', '0', '-1', '+1', '01', '1.0', '1e3', 'abc', '9007199254740992']) {
      expect(parseIntegerId(value)).toBeNull();
    }
  });

  it('serializes safe positive D1 IDs without changing their value', () => {
    expect(serializeIntegerId(2056)).toBe('2056');
    expect(() => serializeIntegerId(0)).toThrow('INVALID_INTEGER_ID');
    expect(() => serializeIntegerId(Number.MAX_SAFE_INTEGER + 1)).toThrow('INVALID_INTEGER_ID');
  });
});
