import { Hono } from 'hono';
import auth from './auth';
import languageLocales from './languageLocales';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);
api.route('/language-locales', languageLocales);

export default api;
