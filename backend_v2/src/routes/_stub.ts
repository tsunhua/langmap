import { Hono } from 'hono';
import { success } from '../utils/response';

const stub = new Hono();
stub.get('/health', (c) => success(c, { status: 'ok', version: 'v2' }));
export default stub;
