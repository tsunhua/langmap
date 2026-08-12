import { z } from 'zod';
import type { D1Database } from '@cloudflare/workers-types';

const PREFERENCE_SCHEMAS: Record<string, z.ZodType> = {
  'language.locales': z
    .object({
      primary: z.string().min(1),
      secondary: z.string().min(1).optional(),
    })
    .refine((data) => !data.secondary || data.secondary !== data.primary, {
      message: 'secondary must differ from primary',
    }),
};

export class PreferenceError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'PreferenceError';
  }
}

export async function getPreferences(
  db: D1Database,
  userId: number,
): Promise<Record<string, unknown>> {
  const { results } = await db
    .prepare('SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?')
    .bind(userId)
    .all<{ preference_key: string; value_json: string }>();
  const out: Record<string, unknown> = {};
  for (const row of results) {
    try {
      out[row.preference_key] = JSON.parse(row.value_json);
    } catch {
      // skip malformed json
    }
  }
  return out;
}

export async function putPreference(
  db: D1Database,
  userId: number,
  key: string,
  value: unknown,
): Promise<{ key: string; value: unknown }> {
  const schema = PREFERENCE_SCHEMAS[key];
  if (!schema) throw new PreferenceError('UNKNOWN_PREFERENCE_KEY');

  const parsed = schema.safeParse(value);
  if (!parsed.success) throw new PreferenceError('INVALID_LANGUAGE_PREFERENCE');
  const validated = parsed.data as { primary: string; secondary?: string };

  if (key === 'language.locales') {
    const locales = [validated.primary, ...(validated.secondary ? [validated.secondary] : [])];
    for (const code of locales) {
      const row = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(code).first();
      if (!row) throw new PreferenceError('INVALID_LANGUAGE_PREFERENCE');
    }
  }

  const json = JSON.stringify(validated);
  await db
    .prepare(
      'INSERT INTO user_preferences (user_id, preference_key, value_json) VALUES (?, ?, ?) ON CONFLICT(user_id, preference_key) DO UPDATE SET value_json = excluded.value_json, updated_at = CURRENT_TIMESTAMP',
    )
    .bind(userId, key, json)
    .run();

  return { key, value: validated };
}
