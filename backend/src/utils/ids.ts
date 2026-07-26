const LANGUAGE_ID_BITS = 16;
const TEXT_ID_BITS = 37;

async function sha256Bytes(input: string): Promise<Uint8Array> {
  const buffer = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(input));
  return new Uint8Array(buffer);
}

function bytesToBigInt(bytes: Uint8Array, length: number): bigint {
  let value = 0n;
  for (let i = 0; i < length; i++) {
    value = (value << 8n) | BigInt(bytes[i]);
  }
  return value;
}

async function hashSegment(content: string, bits: number): Promise<number> {
  const bytes = await sha256Bytes(content);
  const head = bytesToBigInt(bytes, 8);
  const modulus = (1n << BigInt(bits)) - 1n;
  return Number((head % modulus) + 1n);
}

export async function expressionId(languageCode: string, text: string): Promise<number> {
  const langPrefix = await hashSegment(languageCode, LANGUAGE_ID_BITS);
  const textSegment = await hashSegment(text, TEXT_ID_BITS);
  return langPrefix * 2 ** TEXT_ID_BITS + textSegment;
}

export async function stableEdgeId(a: number, b: number): Promise<string> {
  const [left, right] = a <= b ? [a, b] : [b, a];
  return `${left}-${right}`;
}
