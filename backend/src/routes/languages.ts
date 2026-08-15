import { Hono } from 'hono';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../services/languageContent';
import { parseReferenceQuery } from '../services/languageIdentity';
import { parseLocaleHints } from '../services/localizedName';
import type { Bindings, Variables } from '../types';
import { notFound, paginated, success } from '../utils/response';

const languages = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function parseQuery(c: { req: { query: (key: string) => string | undefined } }) {
  return parseReferenceQuery({ q: c.req.query('q') ?? '', limit: c.req.query('limit'), offset: c.req.query('skip') ?? c.req.query('offset') });
}

function parseExpressionSort(value: string | undefined): 'hot' | 'new' | 'alpha' {
  return value === 'new' || value === 'alpha' ? value : 'hot';
}

languages.get('/', async (c) => {
  const query = parseQuery(c);
  const sort = c.req.query('sort') === 'alpha' ? 'alpha' : 'count';
  const result = await listLanguagesWithContent(c.env.DB, {
    ...query,
    sort,
    uiLocale: c.req.query('ui_locale') ?? '',
    secondaryUiLocale: c.req.query('secondary_ui_locale') ?? '',
  });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languages.get('/:code/expressions', async (c) => {
  const code = (c.req.param('code') ?? '').toLowerCase();
  const query = parseQuery(c);
  const result = await listLanguageExpressions(c.env.DB, code, {
    ...query,
    locale: c.req.query('locale') ?? '',
    sort: parseExpressionSort(c.req.query('sort')),
    uiLocale: c.req.query('ui_locale') ?? '',
    secondaryUiLocale: c.req.query('secondary_ui_locale') ?? '',
  });
  if (!result) return notFound(c, 'Language');
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languages.get('/:code', async (c) => {
  const detail = await getLanguageDetail(
    c.env.DB,
    (c.req.param('code') ?? '').toLowerCase(),
    parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale')),
  );
  if (!detail) return notFound(c, 'Language');
  return success(c, detail);
});

export default languages;
