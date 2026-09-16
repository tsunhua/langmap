import type { D1Database } from '@cloudflare/workers-types';
import { MAX_TRANSLATION_GRAPHEMES, MAX_TRANSLATION_TEXT_BYTES } from '../../utils/limits';
import type { TranslationRequest } from './types';

export class TranslationValidationError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'TranslationValidationError';
  }
}

export type TranslationValidationErrorCode =
  | 'VALIDATION_FAILED'
  | 'PLAIN_TEXT_ONLY'
  | 'INVALID_LANG_CODE'
  | 'INVALID_LANGUAGE_LOCALE_CODE'
  | 'TARGET_LOCALE_NOT_FOUND';

const graphemeSegmenter = new Intl.Segmenter('en', { granularity: 'grapheme' });

export function countGraphemes(text: string): number {
  return Array.from(graphemeSegmenter.segment(text)).length;
}

// Shared byte meter for the route's bounded body reader (MAX_TRANSLATION_BODY_BYTES).
export function utf8ByteLength(text: string): number {
  return new TextEncoder().encode(text).length;
}

const TRANSLATION_CONTROL_CHARS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/;
const HTML_TAG = /<\/?[a-zA-Z][^>]*>/;
const FENCED_MARKDOWN = /^[ \t]*(?:`{3,}|~{3,})/m;

export function validateTranslationText(text: string): void {
  if (typeof text !== 'string' || text.trim().length === 0) throw new TranslationValidationError('VALIDATION_FAILED');
  if (HTML_TAG.test(text) || FENCED_MARKDOWN.test(text)) throw new TranslationValidationError('PLAIN_TEXT_ONLY');
  if (TRANSLATION_CONTROL_CHARS.test(text)) throw new TranslationValidationError('VALIDATION_FAILED');
  if (countGraphemes(text) > MAX_TRANSLATION_GRAPHEMES) throw new TranslationValidationError('VALIDATION_FAILED');
  if (utf8ByteLength(text) > MAX_TRANSLATION_TEXT_BYTES) throw new TranslationValidationError('VALIDATION_FAILED');
}

export interface SourceLanguageResolution {
  source_lang_code: string | null;
  source_language_id: number | null;
}

const SOURCE_LANGUAGE_SQL = 'SELECT id FROM languages WHERE code=?';
const LOCALE_SQL = `SELECT ll.id AS id, ll.language_id AS language_id, l.code AS lang_code,
ll.name AS locale_name, ll.name_en AS locale_name_en
FROM language_locales ll
JOIN languages l ON l.id = ll.language_id
WHERE ll.code = ?`;

export async function resolveSourceLanguage(
  db: D1Database,
  input: Pick<TranslationRequest, 'source_lang_code' | 'source_locale_code'>,
): Promise<SourceLanguageResolution> {
  if (input.source_lang_code !== null && typeof input.source_lang_code !== 'string') throw new TranslationValidationError('INVALID_LANG_CODE');
  if (input.source_locale_code !== null && typeof input.source_locale_code !== 'string') throw new TranslationValidationError('INVALID_LANGUAGE_LOCALE_CODE');
  if (input.source_lang_code === null && input.source_locale_code === null) {
    return { source_lang_code: null, source_language_id: null };
  }
  let source_language_id: number | null = null;
  if (input.source_lang_code !== null) {
    const language = await db.prepare(SOURCE_LANGUAGE_SQL).bind(input.source_lang_code.toLowerCase()).first<{ id: number }>();
    if (!language) throw new TranslationValidationError('INVALID_LANG_CODE');
    source_language_id = language.id;
  }
  if (input.source_locale_code !== null) {
    if (source_language_id === null) throw new TranslationValidationError('INVALID_LANGUAGE_LOCALE_CODE');
    const locale = await db.prepare(LOCALE_SQL).bind(input.source_locale_code).first<{ id: number; language_id: number }>();
    if (!locale || locale.language_id !== source_language_id) throw new TranslationValidationError('INVALID_LANGUAGE_LOCALE_CODE');
  }
  return { source_lang_code: input.source_lang_code === null ? null : input.source_lang_code.toLowerCase(), source_language_id };
}

export interface TargetLocaleResolution {
  locale_id: number;
  language_id: number;
  lang_code: string;
  name?: string;
  nameEn?: string;
}

export async function resolveTargetLocale(db: D1Database, target_locale_code: string): Promise<TargetLocaleResolution> {
  if (typeof target_locale_code !== 'string') throw new TranslationValidationError('TARGET_LOCALE_NOT_FOUND');
  const locale = await db
    .prepare(LOCALE_SQL)
    .bind(target_locale_code)
    .first<{
      id: number;
      language_id: number;
      lang_code: string;
      locale_name?: string | null;
      locale_name_en?: string | null;
    }>();
  if (!locale) throw new TranslationValidationError('TARGET_LOCALE_NOT_FOUND');
  const result: TargetLocaleResolution = {
    locale_id: locale.id,
    language_id: locale.language_id,
    lang_code: locale.lang_code,
  };
  if (locale.locale_name) result.name = locale.locale_name;
  if (locale.locale_name_en) result.nameEn = locale.locale_name_en;
  return result;
}
