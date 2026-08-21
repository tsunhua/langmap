import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, internalError, unauthorized } from '../utils/response';
import type { Bindings, Variables } from '../types';

const images = new Hono<{ Bindings: Bindings; Variables: Variables }>();
const MAX_BYTES = 100 * 1024;

images.post('/', requireAuth, async (c) => {
  try {
    if (!c.get('user')) return unauthorized(c);
    if (!(c.req.header('content-type') ?? '').startsWith('image/webp')) return badRequest(c, 'IMAGE_FORMAT_UNSUPPORTED', 'Only WebP images are supported');
    const body = await c.req.arrayBuffer();
    if (body.byteLength === 0 || body.byteLength > MAX_BYTES) return badRequest(c, 'IMAGE_TOO_LARGE', 'Image must be no larger than 100KB');
    const key = `expressions/${crypto.randomUUID()}.webp`;
    await c.env.IMAGE_BUCKET.put(key, body, { httpMetadata: { contentType: 'image/webp', cacheControl: 'public, max-age=31536000, immutable' } });
    return c.json({ success: true, data: { key, url: `/api/v2/images/${encodeURIComponent(key)}` } }, 201);
  } catch (error) {
    console.error('Image upload error:', error);
    return internalError(c);
  }
});

images.get('/:key{.+}', async (c) => {
  const object = await c.env.IMAGE_BUCKET.get(c.req.param('key'));
  if (!object?.body) return c.notFound();
  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  return new Response(object.body, { headers });
});

export default images;
