import { describe, expect, it } from 'vitest';
import {
  canonicalizeExpressionText,
  expressionPrefixUpperBound,
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
