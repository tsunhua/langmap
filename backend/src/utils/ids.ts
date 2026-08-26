const CANONICAL_INTEGER_ID = /^[1-9]\d*$/;

export function parseIntegerId(value: string): number | null {
  if (!CANONICAL_INTEGER_ID.test(value)) return null;
  const id = Number(value);
  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

export function serializeIntegerId(value: number): string {
  if (!Number.isSafeInteger(value) || value <= 0) throw new Error('INVALID_INTEGER_ID');
  return String(value);
}
