import { Hono } from 'hono';
import { cors } from 'hono/cors';
import api from './routes';
import type { Bindings, Variables } from './types';

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

app.use('*', cors());
app.route('/api/v2', api);

export default app;
