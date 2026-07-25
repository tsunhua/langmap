import { Hono } from 'hono';
import stub from './_stub';
import languages from './languages';
import expressions from './expressions';
import mappings from './mappings';
import contributions from './contributions';
import handbooks from './handbooks';

const api = new Hono();
api.route('/', stub);
api.route('/languages', languages);
api.route('/expressions', expressions);
api.route('/mappings', mappings);
api.route('/contributions', contributions);
api.route('/handbooks', handbooks);
export default api;
