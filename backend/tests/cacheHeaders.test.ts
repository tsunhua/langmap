import { Hono } from 'hono';
import { describe, expect, it } from 'vitest';
import { addCacheHeaders, getCachePolicy } from '../src/middleware/cacheHeaders';

describe('API cache policy', () => {
  it('caches public content endpoints for a short period', () => {
    expect(getCachePolicy('https://langmap.io/api/v2/languages?ui_locale=cmn-Hant-TW')?.browserSeconds).toBe(30);
    expect(getCachePolicy('https://langmap.io/api/v2/localization/projects/langmap-web/messages?primary=cmn-Hant-TW')?.edgeSeconds).toBe(60);
  });

  it('does not cache user-specific endpoints', () => {
    expect(getCachePolicy('https://langmap.io/api/v2/preferences')).toBeNull();
    expect(getCachePolicy('https://langmap.io/api/v2/localization/projects/langmap-web/workbench/cmn-Hant-TW')).toBeNull();
    expect(getCachePolicy('https://langmap.io/api/v2/localization/projects/langmap-web/messages')).toBeNull();
  });

  it('uses immutable caching for generated image keys', () => {
    const policy = getCachePolicy('https://langmap.io/api/v2/images/expressions/example.webp');
    expect(policy?.browserSeconds).toBe(31536000);
  });

  it('only adds public cache headers to successful responses', async () => {
    const app = new Hono();
    app.use('*', addCacheHeaders);
    app.get('/api/v2/languages', (c) => c.json({ ok: true }));
    app.get('/api/v2/language-locales/missing', (c) => c.notFound());

    const success = await app.request('https://langmap.io/api/v2/languages');
    expect(success.headers.get('cache-control')).toContain('max-age=30');

    const missing = await app.request('https://langmap.io/api/v2/language-locales/missing');
    expect(missing.headers.get('cache-control')).toBeNull();
  });
});
