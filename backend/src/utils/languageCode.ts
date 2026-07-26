/** Small, dependency-free BCP 47 guard used at API boundaries.
 * It intentionally validates syntax and private-use Glottocode shape; the
 * registry/database remains the authority for whether a tag is registered.
 */
const SUBTAG = /^[A-Za-z0-9]{1,8}$/;
const PRIMARY = /^[A-Za-z]{2,8}$/;
const GLOTTOCODE = /^[a-z0-9]{8}$/;

export function parseLanguageCode(value: string): { code: string; glottocode?: string } | null {
  const code = value.trim();
  if (!code || code.length > 255) return null;
  const parts = code.split('-');
  if (!PRIMARY.test(parts[0])) return null;
  let privateIndex = parts.findIndex((part) => part.toLowerCase() === 'x');
  if (privateIndex >= 0) {
    if (privateIndex === parts.length - 1) return null;
    for (const part of parts.slice(privateIndex + 1)) if (!SUBTAG.test(part)) return null;
    if (parts.length - privateIndex - 1 !== 1 || !GLOTTOCODE.test(parts[privateIndex + 1].toLowerCase())) return null;
  } else {
    privateIndex = parts.length;
  }
  for (const part of parts.slice(1, privateIndex)) if (!SUBTAG.test(part)) return null;
  return { code: parts.map((part, i) => i === 0 ? part.toLowerCase() : part).join('-'), glottocode: privateIndex < parts.length ? parts[privateIndex + 1].toLowerCase() : undefined };
}

export function isLanguageCode(value: string): boolean {
  return parseLanguageCode(value) !== null;
}
