import type { Context, Next } from 'hono';

export interface CachePolicy {
  browserSeconds: number;
  edgeSeconds: number;
  staleSeconds: number;
  authIndependent: boolean;
}

const SHORT_PUBLIC_CACHE: CachePolicy = {
  browserSeconds: 15,
  edgeSeconds: 30,
  staleSeconds: 60,
  authIndependent: true,
};

const CONTENT_CACHE: CachePolicy = {
  browserSeconds: 30,
  edgeSeconds: 60,
  staleSeconds: 120,
  authIndependent: true,
};

const REFERENCE_CACHE: CachePolicy = {
  browserSeconds: 300,
  edgeSeconds: 900,
  staleSeconds: 1800,
  authIndependent: true,
};

const IMAGE_CACHE: CachePolicy = {
  browserSeconds: 31536000,
  edgeSeconds: 31536000,
  staleSeconds: 0,
  authIndependent: true,
};

function matchesExpressionRead(pathname: string): boolean {
  return pathname === '/api/v2/expressions/search' || /^\/api\/v2\/expressions\/[^/]+(?:\/mappings|\/edges|\/form-edges)?$/.test(pathname);
}

export function getCachePolicy(url: string): CachePolicy | null {
  const requestUrl = new URL(url);
  const { pathname, searchParams } = requestUrl;

  if (pathname === '/api/v2/auth/health') return SHORT_PUBLIC_CACHE;
  if (pathname === '/api/v2/feed' || pathname === '/api/v2/feed/hot' || pathname === '/api/v2/feed/new') return SHORT_PUBLIC_CACHE;
  if (matchesExpressionRead(pathname)) return SHORT_PUBLIC_CACHE;
  if (pathname === '/api/v2/languages' || pathname.startsWith('/api/v2/languages/')) return CONTENT_CACHE;
  if (pathname === '/api/v2/language-locales' || pathname.startsWith('/api/v2/language-locales/')) return CONTENT_CACHE;
  if (pathname === '/api/v2/morphological-features') return REFERENCE_CACHE;
  if (pathname.startsWith('/api/v2/language-registry/')) return REFERENCE_CACHE;
  if (pathname === '/api/v2/images' || pathname.startsWith('/api/v2/images/')) return IMAGE_CACHE;
  if (pathname.endsWith('/locales') && pathname.startsWith('/api/v2/localization/projects/')) return CONTENT_CACHE;
  if (pathname.endsWith('/messages') && pathname.startsWith('/api/v2/localization/projects/')) {
    return searchParams.has('primary') || searchParams.has('secondary') ? CONTENT_CACHE : null;
  }
  if (pathname === '/api/v2/handbooks' || /^\/api\/v2\/handbooks\/[^/]+$/.test(pathname)) {
    return { ...CONTENT_CACHE, authIndependent: false };
  }
  return null;
}

function cacheControl(policy: CachePolicy): string {
  const directives = [`public`, `max-age=${policy.browserSeconds}`, `s-maxage=${policy.edgeSeconds}`];
  if (policy.staleSeconds > 0) directives.push(`stale-while-revalidate=${policy.staleSeconds}`);
  return directives.join(', ');
}

export async function addCacheHeaders(c: Context, next: Next): Promise<void> {
  if (c.req.method !== 'GET' && c.req.method !== 'HEAD') {
    await next();
    return;
  }

  const policy = getCachePolicy(c.req.url);
  const hasAuthorization = Boolean(c.req.header('Authorization'));
  const cacheable = Boolean(policy && (!hasAuthorization || policy.authIndependent));
  const edgeCache = cacheable && c.req.method === 'GET' && typeof caches !== 'undefined' ? caches.default : undefined;
  const cacheKey = edgeCache ? new Request(c.req.url, { method: 'GET' }) : undefined;

  if (edgeCache && cacheKey) {
    const cached = await edgeCache.match(cacheKey).catch(() => undefined);
    if (cached) {
      c.res = cached;
      return;
    }
  }

  if (!cacheable && hasAuthorization) {
    c.header('Cache-Control', 'private, no-store');
  }

  await next();

  if (cacheable && policy && c.res.status >= 200 && c.res.status < 300) {
    const value = cacheControl(policy);
    const headers = new Headers(c.res.headers);
    headers.set('Cache-Control', value);
    headers.set('CDN-Cache-Control', value);
    c.res = new Response(c.res.body, {
      status: c.res.status,
      statusText: c.res.statusText,
      headers,
    });
    if (edgeCache && cacheKey) {
      c.executionCtx.waitUntil(edgeCache.put(cacheKey, c.res.clone()).catch(() => undefined));
    }
  }
}
