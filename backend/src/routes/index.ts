import { Hono } from 'hono';
import auth from './auth';
import expressions from './expressions';
import languageLocales from './languageLocales';
import languageRegistry from './languageRegistry';
import localization from './localization';
import preferences from './preferences';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);
api.route('/language-locales', languageLocales);
api.route('/expressions', expressions);
api.route('/preferences', preferences);
api.route('/localization', localization);

export default api;
