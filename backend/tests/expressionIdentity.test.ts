import { describe, expect, it } from 'vitest';
import {
  buildExpressionId,
  canonicalizeExpressionText,
  computeTextHash,
} from '../src/services/expressionIdentity';

describe('canonicalizeExpressionText', () => {
  it('trims surrounding whitespace', () => {
    expect(canonicalizeExpressionText('  食  ')).toBe('食');
  });

  it('NFC-normalizes without case folding', () => {
    expect(canonicalizeExpressionText('  cafe\u0301  ')).toBe('caf\u00e9');
  });

  it('preserves inner whitespace and case', () => {
    expect(canonicalizeExpressionText('A  B\tC')).toBe('A  B\tC');
  });
});

describe('computeTextHash', () => {
  it('matches the spec vector for hello', async () => {
    expect(await computeTextHash('hello')).toBe('ftze3os7wcrq4jxihmvmlopcty');
  });

  it('emits 26 lowercase RFC4648 base32 chars', async () => {
    const hash = await computeTextHash('食');
    expect(hash).toMatch(/^[a-z2-7]{26}$/);
  });

  it('is sensitive to canonical text changes', async () => {
    expect(await computeTextHash('A')).not.toBe(await computeTextHash('a'));
  });
});

describe('buildExpressionId', () => {
  it('builds the base id', () => {
    expect(buildExpressionId('eng', 'ftze3os7wcrq4jxihmvmlopcty')).toBe('eng:ftze3os7wcrq4jxihmvmlopcty');
  });

  it('appends homograph index when greater than one', () => {
    expect(buildExpressionId('eng', 'ftze3os7wcrq4jxihmvmlopcty', 2)).toBe('eng:ftze3os7wcrq4jxihmvmlopcty.2');
  });

  it('defaults to index one', () => {
    expect(buildExpressionId('nan', 'aaaa')).toBe('nan:aaaa');
  });
});
