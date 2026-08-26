import { Hono } from 'hono';
import type { Bindings, Variables } from '../types';
import { success } from '../utils/response';

const morphology = new Hono<{ Bindings: Bindings; Variables: Variables }>();

morphology.get('/', async (c) => {
  const dimensions = await c.env.DB.prepare('SELECT code,sort_order FROM morphological_dimensions ORDER BY sort_order,code').all<{code:string;sort_order:number}>();
  const features = await c.env.DB.prepare('SELECT code,dimension_code,sort_order FROM morphological_features ORDER BY dimension_code,sort_order,code').all<{code:string;dimension_code:string;sort_order:number}>();
  return success(c, dimensions.results.map((dimension) => ({ ...dimension, features: features.results.filter((feature) => feature.dimension_code === dimension.code) })));
});

export default morphology;
