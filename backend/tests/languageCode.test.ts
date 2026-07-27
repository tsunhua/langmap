import { describe, expect, it } from 'vitest';
import { isLanguageCode, parseLanguageCode } from '../src/utils/languageCode';

describe('language code registry syntax', () => {
  it('accepts canonical BCP 47 and Glottocode private use', () => {
    expect(isLanguageCode('en')).toBe(true);
    expect(isLanguageCode('zh-Hant-TW')).toBe(true);
    expect(parseLanguageCode('nan-Hant-x-chao1238')).toEqual({ code: 'nan-Hant-x-chao1238', glottocode: 'chao1238' });
  });

  it('accepts only the allowlisted private-use content codes', () => {
    expect(parseLanguageCode('x-emoji')).toEqual({ code: 'x-emoji' });
    expect(parseLanguageCode('X-IMAGE')).toEqual({ code: 'x-image' });
    expect(parseLanguageCode('x-arbitrary')).toBeNull();
  });

  it('rejects malformed or non-Glottocode private use', () => {
    expect(isLanguageCode('')).toBe(false);
    expect(isLanguageCode('nan-x-cha')).toBe(false);
    expect(isLanguageCode('en-x-too-many-terms')).toBe(false);
    expect(isLanguageCode('EN')).toBe(true);
    expect(parseLanguageCode('EN')?.code).toBe('en');
  });
});
