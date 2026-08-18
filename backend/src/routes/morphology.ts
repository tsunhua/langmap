import { Hono } from 'hono';
import { listMorphologicalFeatures } from '../services/morphology';
import { parseLocaleHints } from '../services/localizedName';
import type { Bindings, Variables } from '../types';
import { success } from '../utils/response';

const morphology = new Hono<{ Bindings: Bindings; Variables: Variables }>();

morphology.get('/', async (c) => {
  const data = await listMorphologicalFeatures(
    c.env.DB,
    parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale')),
  );
  return success(c, data);
});

export default morphology;
