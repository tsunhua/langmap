const BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567';

export function canonicalizeExpressionText(input: string): string {
  return input.trim().normalize('NFC');
}

export async function computeTextHash(canonicalText: string): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(canonicalText)));
  const bytes = digest.slice(0, 16);
  let bits = '';
  for (const byte of bytes) bits += byte.toString(2).padStart(8, '0');
  let out = '';
  for (let i = 0; i < bits.length; i += 5) {
    out += BASE32_ALPHABET[parseInt(bits.slice(i, i + 5).padEnd(5, '0'), 2)];
  }
  return out;
}

export function buildExpressionId(langCode: string, textHash: string, homographIndex = 1): string {
  return homographIndex > 1 ? `${langCode}:${textHash}.${homographIndex}` : `${langCode}:${textHash}`;
}
