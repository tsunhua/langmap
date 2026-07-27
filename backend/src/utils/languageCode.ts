import type { LanguageSubtags, CanonicalLanguageTag } from '../types/language';

const PRIMARY_LANG = /^[A-Za-z]{2,8}$/;
const SCRIPT = /^[A-Za-z]{4}$/;
const REGION = /^[A-Za-z]{2}$/;
const VARIANT = /^[A-Za-z0-9]{5,8}$/;
const PRIVATE_SUBTAG = /^[A-Za-z0-9]{1,8}$/;

export function canonicalizeLanguageTag(input: LanguageSubtags): CanonicalLanguageTag | null {
  const language = input.language.toLowerCase();
  if (!PRIMARY_LANG.test(language)) return null;

  const script = input.script ? input.script.charAt(0).toUpperCase() + input.script.slice(1).toLowerCase() : null;
  if (script && !SCRIPT.test(script)) return null;

  const region = input.region ? input.region.toUpperCase() : null;
  if (region && !REGION.test(region)) return null;

  const variants = input.variants.map(v => v.toLowerCase());
  for (const v of variants) {
    if (!VARIANT.test(v)) return null;
  }

  const private_use = input.private_use.map(p => p.toLowerCase());
  for (const p of private_use) {
    if (!PRIVATE_SUBTAG.test(p)) return null;
  }

  const parts: string[] = [language];
  if (script) parts.push(script);
  if (region) parts.push(region);
  if (variants.length) parts.push(...variants);
  if (private_use.length) parts.push('x', ...private_use);

  return {
    code: parts.join('-'),
    language,
    script,
    region,
    variants,
    private_use,
  };
}

export function parseStoredLanguageCode(
  value: string,
): CanonicalLanguageTag | { code: 'x-emoji' | 'x-image' } | null {
  const code = value.trim();
  if (!code || code.length > 255) return null;

  const lower = code.toLowerCase();
  if (lower === 'x-emoji') return { code: 'x-emoji' };
  if (lower === 'x-image') return { code: 'x-image' };

  const parts = code.split('-');
  if (!PRIMARY_LANG.test(parts[0])) return null;

  const language = parts[0].toLowerCase();
  let script: string | null = null;
  let region: string | null = null;
  const variants: string[] = [];
  const private_use: string[] = [];
  let inPrivate = false;

  for (let i = 1; i < parts.length; i++) {
    const p = parts[i];
    if (p.toLowerCase() === 'x') {
      inPrivate = true;
      continue;
    }
    if (inPrivate) {
      if (!PRIVATE_SUBTAG.test(p)) return null;
      private_use.push(p.toLowerCase());
      continue;
    }
    if (SCRIPT.test(p)) {
      if (script) return null;
      script = p.charAt(0).toUpperCase() + p.slice(1).toLowerCase();
    } else if (REGION.test(p)) {
      if (region) return null;
      region = p.toUpperCase();
    } else if (VARIANT.test(p)) {
      variants.push(p.toLowerCase());
    } else {
      return null;
    }
  }

  const xIndex = parts.findIndex(p => p.toLowerCase() === 'x');
  const canonicalCode = parts.map((p, i) => {
    if (i === 0) return p.toLowerCase();
    if (inPrivate || (xIndex >= 0 && i >= xIndex)) return p.toLowerCase();
    return p;
  }).join('-');

  return { code: canonicalCode, language, script, region, variants, private_use };
}

export function isLanguageCode(value: string): boolean {
  return parseStoredLanguageCode(value) !== null;
}
