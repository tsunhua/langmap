import { describe, expect, it } from 'vitest';
import type { D1Database } from '@cloudflare/workers-types';
import {
  MAX_TRANSLATION_BODY_BYTES,
  MAX_TRANSLATION_GRAPHEMES,
  MAX_TRANSLATION_TEXT_BYTES,
} from '../src/utils/limits';
import {
  TranslationValidationError,
  countGraphemes,
  resolveSourceLanguage,
  resolveTargetLocale,
  utf8ByteLength,
  validateTranslationText,
} from '../src/services/translation/validation';

type Handler = (args: unknown[]) => unknown;

function fakeD1(handlers: Record<string, Handler>): D1Database {
  const prepare = (sql: string) => ({
    bind: (...args: unknown[]) => {
      for (const arg of args) {
        if (!(arg === null || typeof arg === 'string' || typeof arg === 'number' || typeof arg === 'boolean' || arg instanceof ArrayBuffer)) {
          throw new TypeError(`D1 bind: unsupported value type ${typeof arg}`);
        }
      }
      return {
        async first<T>() {
          return (handlers[sql]?.(args) ?? null) as T;
        },
      };
    },
  });
  return { prepare } as unknown as D1Database;
}

const LANG_SQL = 'SELECT id FROM languages WHERE code=?';
const LOCALE_SQL = `SELECT ll.id AS id, ll.language_id AS language_id, l.code AS lang_code,
ll.name AS locale_name, ll.name_en AS locale_name_en
FROM language_locales ll
JOIN languages l ON l.id = ll.language_id
WHERE ll.code = ?`;

function errorCodeOf(text: string): string | null {
  try {
    validateTranslationText(text);
    return null;
  } catch (error) {
    return error instanceof TranslationValidationError ? error.code : null;
  }
}

function byteBoundText(bytes: number): string {
  const asciiCount = 401;
  const markCount = (bytes - asciiCount - 1) / 2;
  return 'a'.repeat(asciiCount) + 'e' + '\u0301'.repeat(markCount);
}

describe('countGraphemes', () => {
  it('counts unicode text by grapheme cluster', () => {
    expect(countGraphemes('hello')).toBe(5);
    expect(countGraphemes('你好，世界')).toBe(5);
  });

  it('counts combining and emoji sequences as a single grapheme', () => {
    expect(countGraphemes('e\u0301')).toBe(1);
    expect(countGraphemes('👨‍👩‍👧‍👦')).toBe(1);
  });
});

describe('utf8ByteLength', () => {
  it('measures text in UTF-8 bytes', () => {
    expect(utf8ByteLength('abc')).toBe(3);
    expect(utf8ByteLength('日本語')).toBe(9);
    expect(utf8ByteLength('😀')).toBe(4);
    expect(utf8ByteLength('')).toBe(0);
  });

  it('keeps the text byte budget inside the request body budget', () => {
    expect(MAX_TRANSLATION_TEXT_BYTES).toBeLessThan(MAX_TRANSLATION_BODY_BYTES);
  });
});

describe('validateTranslationText', () => {
  it('accepts plain unicode text', () => {
    expect(errorCodeOf('hello')).toBeNull();
    expect(errorCodeOf('你好，世界')).toBeNull();
  });

  it('accepts text at the exact grapheme and UTF-8 byte bounds', () => {
    expect(utf8ByteLength(byteBoundText(MAX_TRANSLATION_TEXT_BYTES))).toBe(MAX_TRANSLATION_TEXT_BYTES);
    expect(countGraphemes(byteBoundText(MAX_TRANSLATION_TEXT_BYTES))).toBeLessThanOrEqual(MAX_TRANSLATION_GRAPHEMES);
    expect(errorCodeOf('a'.repeat(MAX_TRANSLATION_GRAPHEMES))).toBeNull();
    expect(errorCodeOf(byteBoundText(MAX_TRANSLATION_TEXT_BYTES))).toBeNull();
  });

  it('rejects text over the grapheme limit', () => {
    expect(errorCodeOf('a'.repeat(MAX_TRANSLATION_GRAPHEMES + 1))).toBe('VALIDATION_FAILED');
  });

  it('rejects text over the UTF-8 byte limit even with few graphemes', () => {
    expect(errorCodeOf(byteBoundText(MAX_TRANSLATION_TEXT_BYTES + 2))).toBe('VALIDATION_FAILED');
  });

  it('rejects empty and whitespace-only text', () => {
    expect(errorCodeOf('')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('   ')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('\n')).toBe('VALIDATION_FAILED');
  });

  it('rejects non-string text', () => {
    expect(errorCodeOf(null as unknown as string)).toBe('VALIDATION_FAILED');
  });

  it('rejects NUL and C0/C1 control characters', () => {
    expect(errorCodeOf('a\u0000b')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u0001b')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u000Bb')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u000Cb')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u001Fb')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u007Fb')).toBe('VALIDATION_FAILED');
    expect(errorCodeOf('a\u0085b')).toBe('VALIDATION_FAILED');
  });

  it('allows newlines, CRLF and tabs', () => {
    expect(errorCodeOf('line one\nline two')).toBeNull();
    expect(errorCodeOf('line one\r\nline two')).toBeNull();
    expect(errorCodeOf('col one\tcol two')).toBeNull();
  });

  it('rejects HTML tags without attempting to clean them', () => {
    expect(errorCodeOf('<b>bold</b>')).toBe('PLAIN_TEXT_ONLY');
    expect(errorCodeOf('<br/>line')).toBe('PLAIN_TEXT_ONLY');
    expect(errorCodeOf('start <div> inner')).toBe('PLAIN_TEXT_ONLY');
  });

  it('rejects fenced Markdown', () => {
    expect(errorCodeOf('```\nfenced\n```')).toBe('PLAIN_TEXT_ONLY');
    expect(errorCodeOf('~~~md')).toBe('PLAIN_TEXT_ONLY');
    expect(errorCodeOf('text\n~~~\nfence')).toBe('PLAIN_TEXT_ONLY');
  });

  it('does not reject plain punctuation or inline emphasis', () => {
    expect(errorCodeOf('3 < 5 and 5 > 3')).toBeNull();
    expect(errorCodeOf('**emphasis** and `code`')).toBeNull();
  });

  it('throws TranslationValidationError carrying a structured code', () => {
    try {
      validateTranslationText('\u0000');
      expect.unreachable();
    } catch (error) {
      expect(error).toBeInstanceOf(TranslationValidationError);
      expect((error as TranslationValidationError).code).toBe('VALIDATION_FAILED');
    }
  });
});

describe('resolveSourceLanguage', () => {
  it('resolves an existing source language code', async () => {
    const db = fakeD1({ [LANG_SQL]: () => ({ id: 7 }) });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: null }))
      .resolves.toEqual({ source_lang_code: 'cmn', source_language_id: 7 });
  });

  it('looks up the source language by lowercased code', async () => {
    let bound: unknown = null;
    const db = fakeD1({ [LANG_SQL]: (args) => { bound = args[0]; return { id: 7 }; } });
    await resolveSourceLanguage(db, { source_lang_code: 'CMN', source_locale_code: null });
    expect(bound).toBe('cmn');
  });

  it('rejects an unknown source language code', async () => {
    const db = fakeD1({ [LANG_SQL]: () => null });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'zzz', source_locale_code: null }))
      .rejects.toMatchObject({ code: 'INVALID_LANG_CODE' });
  });

  it('rejects a non-string source language code', async () => {
    const db = fakeD1({});
    await expect(resolveSourceLanguage(db, { source_lang_code: 123 as unknown as string, source_locale_code: null }))
      .rejects.toMatchObject({ code: 'INVALID_LANG_CODE' });
    await expect(resolveSourceLanguage(db, { source_lang_code: { code: 'cmn' } as unknown as string, source_locale_code: null }))
      .rejects.toMatchObject({ code: 'INVALID_LANG_CODE' });
  });

  it('returns a null resolution when the source is auto-detected', async () => {
    const db = fakeD1({});
    await expect(resolveSourceLanguage(db, { source_lang_code: null, source_locale_code: null }))
      .resolves.toEqual({ source_lang_code: null, source_language_id: null });
  });

  it('accepts a source locale whose language matches', async () => {
    const db = fakeD1({
      [LANG_SQL]: () => ({ id: 7 }),
      [LOCALE_SQL]: () => ({ id: 12, language_id: 7 }),
    });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: 'cmn-Hans-CN' }))
      .resolves.toEqual({ source_lang_code: 'cmn', source_language_id: 7 });
  });

  it('rejects a source locale whose language differs from the source language', async () => {
    const db = fakeD1({
      [LANG_SQL]: () => ({ id: 7 }),
      [LOCALE_SQL]: () => ({ id: 12, language_id: 99 }),
    });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: 'cmn-Hans-CN' }))
      .rejects.toMatchObject({ code: 'INVALID_LANGUAGE_LOCALE_CODE' });
  });

  it('rejects a missing source locale', async () => {
    const db = fakeD1({
      [LANG_SQL]: () => ({ id: 7 }),
      [LOCALE_SQL]: () => null,
    });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: 'cmn-Hans-CN' }))
      .rejects.toMatchObject({ code: 'INVALID_LANGUAGE_LOCALE_CODE' });
  });

  it('rejects a non-string source locale code', async () => {
    const db = fakeD1({ [LANG_SQL]: () => ({ id: 7 }) });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: 123 as unknown as string }))
      .rejects.toMatchObject({ code: 'INVALID_LANGUAGE_LOCALE_CODE' });
    await expect(resolveSourceLanguage(db, { source_lang_code: 'cmn', source_locale_code: {} as unknown as string }))
      .rejects.toMatchObject({ code: 'INVALID_LANGUAGE_LOCALE_CODE' });
  });

  it('rejects a source locale without a source language', async () => {
    const db = fakeD1({ [LOCALE_SQL]: () => ({ id: 12, language_id: 7 }) });
    await expect(resolveSourceLanguage(db, { source_lang_code: null, source_locale_code: 'cmn-Hans-CN' }))
      .rejects.toMatchObject({ code: 'INVALID_LANGUAGE_LOCALE_CODE' });
  });
});

describe('resolveTargetLocale', () => {
  it('resolves an existing target locale with its language id and code', async () => {
    const db = fakeD1({ [LOCALE_SQL]: () => ({
      id: 12,
      language_id: 7,
      lang_code: 'jpn',
      locale_name: '日語',
      locale_name_en: 'Japanese',
    }) });
    await expect(resolveTargetLocale(db, 'jpn-Jpan-JP'))
      .resolves.toEqual({
        locale_id: 12,
        language_id: 7,
        lang_code: 'jpn',
        name: '日語',
        nameEn: 'Japanese',
      });
  });

  it('looks up the target locale by exact code', async () => {
    let bound: unknown = null;
    const db = fakeD1({ [LOCALE_SQL]: (args) => { bound = args[0]; return { id: 12, language_id: 7, lang_code: 'jpn' }; } });
    await resolveTargetLocale(db, 'jpn-Jpan-JP');
    expect(bound).toBe('jpn-Jpan-JP');
  });

  it('rejects an unknown target locale', async () => {
    const db = fakeD1({ [LOCALE_SQL]: () => null });
    await expect(resolveTargetLocale(db, 'nope')).rejects.toMatchObject({ code: 'TARGET_LOCALE_NOT_FOUND' });
  });

  it('rejects a non-string target locale code', async () => {
    const db = fakeD1({});
    await expect(resolveTargetLocale(db, 123 as unknown as string)).rejects.toMatchObject({ code: 'TARGET_LOCALE_NOT_FOUND' });
    await expect(resolveTargetLocale(db, null as unknown as string)).rejects.toMatchObject({ code: 'TARGET_LOCALE_NOT_FOUND' });
    await expect(resolveTargetLocale(db, {} as unknown as string)).rejects.toMatchObject({ code: 'TARGET_LOCALE_NOT_FOUND' });
  });
});
