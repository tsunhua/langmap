import { describe, expect, it } from 'vitest';
import {
  canonicalizeExpressionText,
  expressionPrefixUpperBound,
} from '../src/services/expressionIdentity';

describe('canonicalizeExpressionText', () => {
  it('trims surrounding whitespace', () => {
    expect(canonicalizeExpressionText('  食  ')).toBe('食');
  });

  it('NFC-normalizes and applies sentence case to Latin expressions', () => {
    expect(canonicalizeExpressionText('  cafe\u0301  ')).toBe('Café');
    expect(canonicalizeExpressionText('CLOSED')).toBe('CLOSED');
    expect(canonicalizeExpressionText('UFO')).toBe('UFO');
    expect(canonicalizeExpressionText('Closed')).toBe('Closed');
    expect(canonicalizeExpressionText('i only eat Halal food')).toBe('I only eat halal food');
    expect(canonicalizeExpressionText('廁所')).toBe('廁所');
  });

  it('preserves inner whitespace while normalizing case', () => {
    expect(canonicalizeExpressionText('A  B\tc')).toBe('A  b\tc');
  });
});

describe('expressionPrefixUpperBound', () => {
  it('returns the next SQLite BINARY text range boundary', () => {
    expect(expressionPrefixUpperBound('ca')).toBe('cb');
    expect(expressionPrefixUpperBound('食')).toBe('飠');
    expect(expressionPrefixUpperBound('a\u{10ffff}')).toBe('b');
  });

  it('returns null when no finite non-empty range exists', () => {
    expect(expressionPrefixUpperBound('')).toBeNull();
    expect(expressionPrefixUpperBound('\u{10ffff}')).toBeNull();
  });
});
