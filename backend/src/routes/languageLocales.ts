import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, conflict, created, internalError, notFound, paginated, success } from '../utils/response';
import { LanguageLocaleError, assertReferenceCodesExist, buildLanguageLocaleCode, canonicalEnglishLanguageMatches, canonicalEnglishLanguageName, escapeLike, parseLanguageLocaleCode, parseReferenceQuery } from '../services/languageIdentity';
import { parseLocaleHints, resolveLanguageNames, resolveLocaleNames } from '../services/localizedName';
import type { Bindings, Variables } from '../types';

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const COLUMNS = 'll.id,ll.code,l.code AS lang_code,ll.script_code,ll.orthography,ll.region_code,ll.place_path,ll.name,ll.name_en,ll.latitude,ll.longitude';
const LOCALE_COLUMNS = `${COLUMNS},l.name_en AS language_name_en`;

function localeDisplayName(row: Record<string, unknown>): string {
  const code = String(row.code ?? '');
  const languageCode = String(row.lang_code ?? '');
  const localeName = String(row.name_en ?? '').trim();
  if (localeName && localeName !== code && localeName !== languageCode) return localeName;
  const languageName = String(row.language_name_en ?? (localeName || languageCode));
  return canonicalEnglishLanguageName(languageCode, languageName);
}

function localizedLocaleDisplayName(
  row: Record<string, unknown>,
  localeName: string | undefined,
  languageName: string | undefined,
  uiLocale: string | undefined,
): string {
  const code = String(row.code ?? '');
  const languageCode = String(row.lang_code ?? '');
  const scriptCode = String(row.script_code ?? '');
  const regionCode = String(row.region_code ?? '');
  const orthography = String(row.orthography ?? '').trim();
  const placePath = String(row.place_path ?? '').trim();
  const localized = localeName?.trim();
  const usefulLocaleName = localized && localized !== code && localized !== languageCode;
  const normalizeName = (name: string) => name.normalize('NFKC').toLowerCase();
  const matchesEnglishName = localized && normalizeName(localized) === normalizeName(String(row.name_en ?? '').trim());
  const matchesLanguageName = localized && languageName && normalizeName(localized) === normalizeName(languageName);
  if (languageCode !== 'eng' && usefulLocaleName && !matchesLanguageName && (!matchesEnglishName || !languageName)) return localized;

  const languageNameEn = canonicalEnglishLanguageName(
    languageCode,
    String(row.language_name_en ?? row.name_en ?? languageCode),
  );
  const displayLanguageName = languageCode === 'eng'
    ? languageNameEn
    : languageName?.trim() && languageName !== languageCode ? languageName.trim() : languageNameEn;
  const profileParts: string[] = [];
  if (orthography) {
    profileParts.push(orthography.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/\b[a-z]/g, (letter) => letter.toUpperCase()));
  } else if (scriptCode && scriptCode !== 'Latn') {
    profileParts.push(scriptCode);
  }
  if (regionCode) profileParts.push(regionCode);
  if (placePath) {
    profileParts.push(...placePath.split('_').map((part) => part.replace(/([a-z])([A-Z])/g, '$1 $2')));
  }
  if (profileParts.length) {
    const suffix = profileParts.join('-');
    const chineseUi = uiLocale?.startsWith('cmn-') ?? false;
    if (languageCode === 'eng') return `${displayLanguageName} (${suffix})`;
    return `${displayLanguageName}${chineseUi ? `（${suffix}）` : ` (${suffix})`}`;
  }
  if (usefulLocaleName) return localized;
  if (languageName?.trim() && languageName !== languageCode) return languageName.trim();
  return localeDisplayName(row);
}

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const body = await c.req.json<Record<string, unknown>>().catch(() => ({})); const lang = typeof body.lang_code === 'string' ? body.lang_code.trim().toLowerCase() : ''; const script = typeof body.script_code === 'string' ? body.script_code.trim() : ''; const region = typeof body.region_code === 'string' ? body.region_code.trim() : ''; const name = typeof body.name === 'string' ? body.name.trim() : ''; const nameEn = typeof body.name_en === 'string' ? body.name_en.trim() : ''; const segments = Array.isArray(body.place_segments) && body.place_segments.every((x) => typeof x === 'string') ? body.place_segments : [];
    if (!lang || !script || !region || !name || !nameEn) return badRequest(c, 'VALIDATION_FAILED');
    const latitude = typeof body.latitude === 'number' && Number.isFinite(body.latitude) ? body.latitude : null; const longitude = typeof body.longitude === 'number' && Number.isFinite(body.longitude) ? body.longitude : null; if ((latitude === null) !== (longitude === null)) return badRequest(c, 'VALIDATION_FAILED');
    let code: string; try { code = buildLanguageLocaleCode({ lang_code: lang, script_code: script, region_code: region, place_segments: segments }); await assertReferenceCodesExist(c.env.DB, lang, script, region); } catch (error) { return error instanceof LanguageLocaleError ? badRequest(c, error.code) : internalError(c); }
    const language = await c.env.DB.prepare('SELECT id FROM languages WHERE code=?').bind(lang).first<{id:number}>(); if (!language) return badRequest(c, 'INVALID_LANG_CODE');
    try { await c.env.DB.prepare('INSERT INTO language_locales(code,language_id,script_code,region_code,place_path,name,name_en,latitude,longitude) VALUES(?,?,?,?,?,?,?,?,?)').bind(code,language.id,script,region,segments.join('_'),name,nameEn,latitude,longitude).run(); } catch (error) { if ((error as { code?: string })?.code === '23505') return conflict(c, 'LANGUAGE_LOCALE_EXISTS'); throw error; }
    const row = await c.env.DB.prepare(`SELECT ${COLUMNS} FROM language_locales ll JOIN languages l ON l.id=ll.language_id WHERE ll.code=?`).bind(code).first(); return created(c,row);
  } catch (error) { console.error('Create language locale error:', error); return internalError(c); }
});

languageLocales.get('/', async (c) => {
  const localeHints = parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale'));
  const query = parseReferenceQuery({
    q: c.req.query('q'),
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
  const where: string[] = [];
  const args: Array<string | number> = [];
  for (const [column, value] of [
    ['l.code', (c.req.query('lang_code') ?? '').toLowerCase()],
    ['ll.script_code', c.req.query('script_code') ?? ''],
    ['ll.region_code', (c.req.query('region_code') ?? '').toUpperCase()],
  ] as const) {
    if (value) {
      where.push(`${column}=?`);
      args.push(value);
    }
  }
  if (query.q) {
    const like = `%${escapeLike(query.q)}%`;
    const canonicalMatches = canonicalEnglishLanguageMatches(query.q);
    const canonicalMatchSql = canonicalMatches.length
      ? ` OR l.code IN (${canonicalMatches.map(() => '?').join(', ')})`
      : '';
    where.push(`(ll.code LIKE ? ESCAPE '\\' OR ll.name LIKE ? ESCAPE '\\' OR ll.name_en LIKE ? ESCAPE '\\' OR l.name_en LIKE ? ESCAPE '\\'${canonicalMatchSql})`);
    args.push(like, like, like, like, ...canonicalMatches);
  }

  const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const count = await c.env.DB
    .prepare(`SELECT COUNT(*) AS total FROM language_locales ll JOIN languages l ON l.id=ll.language_id ${clause}`)
    .bind(...args)
    .first<{ total: number }>();
  const rows = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales ll JOIN languages l ON l.id=ll.language_id ${clause} ORDER BY ll.code LIMIT ? OFFSET ?`)
    .bind(...args, query.limit, query.offset)
    .all();
  const codes = rows.results.map((row) => String(row.code ?? ''));
  const languageCodes = [...new Set(rows.results.map((row) => String(row.lang_code ?? '')))];
  const [localizedNames, localizedLanguageNames] = localeHints.primary || localeHints.secondary
    ? await Promise.all([
      resolveLocaleNames(c.env.DB, codes, localeHints),
      resolveLanguageNames(c.env.DB, languageCodes, localeHints),
    ])
    : [new Map<string, string>(), new Map<string, string>()];
  const items = rows.results.map((row) => {
    const code = String(row.code ?? '');
    const languageCode = String(row.lang_code ?? '');
    return {
      ...row,
      display_name: localizedLocaleDisplayName(
        row,
        localizedNames.get(code),
        localizedLanguageNames.get(languageCode),
        localeHints.primary ?? localeHints.secondary,
      ),
    };
  });

  return paginated(c, items, count?.total ?? 0, query.offset, query.limit);
});

languageLocales.get('/:code', async (c) => {
  const code = c.req.param('code');
  if (!parseLanguageLocaleCode(code)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE');
  const localeHints = parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale'));
  const row = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS},COALESCE(ll.latitude,r.latitude) AS resolved_latitude,COALESCE(ll.longitude,r.longitude) AS resolved_longitude,CASE WHEN ll.latitude IS NOT NULL THEN 'locale' WHEN r.latitude IS NOT NULL THEN 'region' ELSE NULL END AS coordinate_source FROM language_locales ll JOIN languages l ON l.id=ll.language_id LEFT JOIN regions r ON r.code=ll.region_code WHERE ll.code=?`)
    .bind(code)
    .first<Record<string, unknown>>();
  if (!row) return notFound(c, 'Language locale');
  const languageCode = String(row.lang_code ?? '');
  const [localizedName, localizedLanguageName] = localeHints.primary || localeHints.secondary
    ? await Promise.all([
      resolveLocaleNames(c.env.DB, [code], localeHints).then((names) => names.get(code)),
      resolveLanguageNames(c.env.DB, [languageCode], localeHints).then((names) => names.get(languageCode)),
    ])
    : [undefined, undefined];
  return success(c, {
    ...row,
    display_name: localizedLocaleDisplayName(
      row,
      localizedName,
      localizedLanguageName,
      localeHints.primary ?? localeHints.secondary,
    ),
  });
});
export default languageLocales;
