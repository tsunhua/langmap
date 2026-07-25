import { Hono } from 'hono';
import stub from './_stub';
import languages from './languages';
import expressions from './expressions';

const api = new Hono();
api.route('/', stub);
api.route('/languages', languages);
api.route('/expressions', expressions);
export default api;
