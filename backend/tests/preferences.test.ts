import { describe, expect, it } from 'vitest';
import { PreferenceError, getPreferences, putPreference } from '../src/services/preferences';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler() : { success: true }; },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(() => '', (e: unknown) => String((e as { code?: string }).code ?? ''));
}

describe('getPreferences', () => {
  it('returns an empty object for a user with no preferences', async () => {
    const db = fakeD1({
      'SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?': () => ({ results: [] }),
    });
    const result = await getPreferences(db, 1);
    expect(result).toEqual({});
  });

  it('returns parsed preference values', async () => {
    const db = fakeD1({
      'SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?': () => ({
        results: [
          { preference_key: 'language.locales', value_json: '{"primary":"cmn-Hant-TW"}' },
        ],
      }),
    });
    const result = await getPreferences(db, 1);
    expect(result['language.locales']).toEqual({ primary: 'cmn-Hant-TW' });
  });
});

describe('putPreference', () => {
  it('upserts a valid language.locales preference', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'INSERT INTO user_preferences (user_id, preference_key, value_json) VALUES (?, ?, ?) ON CONFLICT(user_id, preference_key) DO UPDATE SET value_json = excluded.value_json, updated_at = CURRENT_TIMESTAMP':
        () => { inserted = true; return { success: true }; },
    });
    const result = await putPreference(db, 1, 'language.locales', { primary: 'cmn-Hant-TW' });
    expect(result.key).toBe('language.locales');
    expect(result.value).toEqual({ primary: 'cmn-Hant-TW' });
    expect(inserted).toBe(true);
  });

  it('rejects an unknown key with UNKNOWN_PREFERENCE_KEY', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => putPreference(db, 1, 'unknown.key', {}))).toBe('UNKNOWN_PREFERENCE_KEY');
  });

  it('rejects when primary locale does not exist', async () => {
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => null,
    });
    expect(await captureAsyncCode(() => putPreference(db, 1, 'language.locales', { primary: 'zzz-Zzz-ZZ' }))).toBe('INVALID_LANGUAGE_PREFERENCE');
  });

  it('rejects when secondary equals primary', async () => {
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => putPreference(db, 1, 'language.locales', { primary: 'cmn-Hant-TW', secondary: 'cmn-Hant-TW' }))).toBe('INVALID_LANGUAGE_PREFERENCE');
  });
});
