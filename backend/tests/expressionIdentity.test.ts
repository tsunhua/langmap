import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  canonicalizeExpressionText,
  ExpressionIdentityError,
  expressionPrefixUpperBound,
} from '../src/services/expressionIdentity';

type IdentityCase = { name: string; input: string; output?: string; error?: string };
const sharedCases = JSON.parse(
  readFileSync(new URL('../../scripts/dictionary/tests/fixtures/expression_identity_cases.json', import.meta.url), 'utf8'),
) as IdentityCase[];

describe('canonicalizeExpressionText', () => {
  for (const testCase of sharedCases) {
    it(`matches shared case: ${testCase.name}`, () => {
      if (testCase.error) {
        expect(() => canonicalizeExpressionText(testCase.input)).toThrowError(
          expect.objectContaining({ code: testCase.error }),
        );
      } else {
        expect(canonicalizeExpressionText(testCase.input)).toBe(testCase.output);
      }
    });
  }

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
  it('returns the next bytewise text text range boundary', () => {
    expect(expressionPrefixUpperBound('ca')).toBe('cb');
    expect(expressionPrefixUpperBound('食')).toBe('飠');
    expect(expressionPrefixUpperBound('a\u{10ffff}')).toBe('b');
  });

  it('returns null when no finite non-empty range exists', () => {
    expect(expressionPrefixUpperBound('')).toBeNull();
    expect(expressionPrefixUpperBound('\u{10ffff}')).toBeNull();
  });
});
