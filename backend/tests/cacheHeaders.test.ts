import { Hono } from 'hono';
import { describe, expect, it } from 'vitest';
import { addCacheHeaders, getCachePolicy } from '../src/middleware/cacheHeaders';

describe('API cache policy', () => {
  it('uses longer TTLs for public feed and expression reads', () => {
    expect(getCachePolicy('https://langmap.io/api/v2/feed/hot')?.browserSeconds).toBe(30);
    expect(getCachePolicy('https://langmap.io/api/v2/feed/hot')?.edgeSeconds).toBe(120);
    expect(getCachePolicy('https://langmap.io/api/v2/expressions/example/mappings')?.browserSeconds).toBe(120);
    expect(getCachePolicy('https://langmap.io/api/v2/expressions/example/mappings')?.edgeSeconds).toBe(600);
  });

  it('uses short content TTLs for localization reads', () => {
    expect(getCachePolicy('https://langmap.io/api/v2/localization/projects/langmap-web/messages?primary=cmn-Hant-TW')?.edgeSeconds).toBe(60);
    expect(getCachePolicy('https://langmap.io/api/v2/language-locales')?.staleSeconds).toBe(0);
  });

  it('caches the languages list with stale-while-revalidate', () => {
    const policy = getCachePolicy('https://langmap.io/api/v2/languages?ui_locale=cmn-Hant-TW');
    expect(policy?.browserSeconds).toBe(120);
    expect(policy?.edgeSeconds).toBe(900);
    expect(policy?.staleSeconds).toBe(3600);
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
    expect(success.headers.get('cache-control')).toContain('max-age=120');
    expect(success.headers.get('cache-control')).toContain('s-maxage=900');
    expect(success.headers.get('cache-control')).toContain('stale-while-revalidate=3600');

    const missing = await app.request('https://langmap.io/api/v2/language-locales/missing');
    expect(missing.headers.get('cache-control')).toBeNull();
  });
});
