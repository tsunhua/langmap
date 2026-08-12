import { Hono } from 'hono';
import auth from './auth';
import expressions from './expressions';
import languageLocales from './languageLocales';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);
api.route('/language-locales', languageLocales);
api.route('/expressions', expressions);

export default api;
