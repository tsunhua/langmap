import { describe, expect, it } from 'vitest';
import { ulid, isUlid, seedVarietyId } from './ulid';

describe('ulid', () => {
  it('produces 26-char crockford-base32 strings', () => {
    const id = ulid(0);
    expect(id).toMatch(/^[0-9A-HJKMNP-TV-Z]{26}$/);
    expect(isUlid(id)).toBe(true);
  });

  it('is monotonically ordered by timestamp', () => {
    expect(ulid(1_700_000_000_000) < ulid(1_700_000_001_000)).toBe(true);
  });

  it('seedVarietyId is deterministic and distinct per code', () => {
    expect(seedVarietyId('cmn')).toBe(seedVarietyId('cmn'));
    expect(seedVarietyId('cmn')).not.toBe(seedVarietyId('yue'));
    expect(isUlid(seedVarietyId('cmn'))).toBe(true);
  });

  it('isUlid rejects malformed input', () => {
    expect(isUlid('not-a-ulid')).toBe(false);
    expect(isUlid('')).toBe(false);
  });
});
