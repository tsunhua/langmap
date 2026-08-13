import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const config = JSON.parse(readFileSync(new URL('../wrangler.jsonc', import.meta.url), 'utf8')) as {
  compatibility_date?: string;
  compatibility_flags?: string[];
  vars?: Record<string, unknown>;
  observability?: {
    logs?: { enabled?: boolean };
    traces?: { enabled?: boolean; head_sampling_rate?: number };
  };
};

describe('Wrangler production configuration', () => {
  it('keeps secrets out of versioned vars', () => {
    expect(config.vars?.SECRET_KEY).toBeUndefined();
  });

  it('uses the reviewed Workers compatibility baseline', () => {
    // Newest date supported by the local workerd binary shipped with wrangler.
    // Bump only when a newer wrangler release ships a binary that supports a later date.
    expect(config.compatibility_date).toBe('2026-07-29');
    expect(config.compatibility_flags).toContain('nodejs_compat');
  });

  it('enables sampled logs and traces', () => {
    expect(config.observability?.logs?.enabled).toBe(true);
    expect(config.observability?.traces?.enabled).toBe(true);
    expect(config.observability?.traces?.head_sampling_rate).toBeGreaterThan(0);
    expect(config.observability?.traces?.head_sampling_rate).toBeLessThanOrEqual(1);
  });
});
