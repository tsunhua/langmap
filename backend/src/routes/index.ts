import { Hono } from 'hono';
import auth from './auth';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);

export default api;
