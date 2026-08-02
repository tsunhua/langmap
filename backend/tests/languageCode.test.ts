import { describe, expect, it } from 'vitest';
import { canonicalizeLanguageTag, parseStoredLanguageCode } from '../src/utils/languageCode';

describe('language code registry syntax', () => {
  it('parseStoredLanguageCode accepts canonical BCP 47 and Glottocode private use', () => {
    const en = parseStoredLanguageCode('en');
    expect(en).toEqual({ code: 'en', language: 'en', script: null, region: null, variants: [], private_use: [] });
    const cmnHant = parseStoredLanguageCode('cmn-Hant-TW');
    expect(cmnHant).toEqual({ code: 'cmn-Hant-TW', language: 'cmn', script: 'Hant', region: 'TW', variants: [], private_use: [] });
  });

  it('parseStoredLanguageCode accepts system codes', () => {
    expect(parseStoredLanguageCode('x-emoji')).toEqual({ code: 'x-emoji' });
    expect(parseStoredLanguageCode('X-IMAGE')).toEqual({ code: 'x-image' });
  });

  it('parseStoredLanguageCode rejects invalid tags', () => {
    expect(parseStoredLanguageCode('')).toBeNull();
    expect(parseStoredLanguageCode('x-arbitrary')).toBeNull();
    expect(parseStoredLanguageCode('123')).toBeNull();
  });
});

describe('canonicalizeLanguageTag', () => {
  it('normalizes case for all subtags', () => {
    expect(canonicalizeLanguageTag({
      language: 'YUE',
      script: 'hant',
      region: 'cn',
      variants: [],
      private_use: ['HeguSan'],
    })).toEqual({
      code: 'yue-Hant-CN-x-hegusan',
      language: 'yue',
      script: 'Hant',
      region: 'CN',
      variants: [],
      private_use: ['hegusan'],
    });
  });

  it('returns null for private use tags longer than 8 characters', () => {
    expect(canonicalizeLanguageTag({
      language: 'en',
      script: null,
      region: null,
      variants: [],
      private_use: ['too-long-raw'],
    })).toBeNull();
  });

  it('returns null for invalid language subtag', () => {
    expect(canonicalizeLanguageTag({
      language: '123',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    })).toBeNull();
  });

  it('returns null for invalid script subtag', () => {
    expect(canonicalizeLanguageTag({
      language: 'en',
      script: 'Toolongscript',
      region: null,
      variants: [],
      private_use: [],
    })).toBeNull();
  });

  it('returns null for invalid region subtag', () => {
    expect(canonicalizeLanguageTag({
      language: 'en',
      script: null,
      region: 'USA',
      variants: [],
      private_use: [],
    })).toBeNull();
  });

  it('handles null optional subtags', () => {
    expect(canonicalizeLanguageTag({
      language: 'en',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    })).toEqual({
      code: 'en',
      language: 'en',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    });
  });

  it('builds code with multiple variants', () => {
    expect(canonicalizeLanguageTag({
      language: 'sl',
      script: null,
      region: 'RO',
      variants: ['nedis', 'baku1926'],
      private_use: [],
    })).toEqual({
      code: 'sl-RO-nedis-baku1926',
      language: 'sl',
      script: null,
      region: 'RO',
      variants: ['nedis', 'baku1926'],
      private_use: [],
    });
  });
});
