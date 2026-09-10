export function canonicalizeExpressionText(input: string): string {
  const normalized = input.trim().normalize('NFC');
  if (!normalized) return normalized;

  // Expression identity is sentence-case for cased scripts. Lowercasing the
  // remainder collapses `closed`, `Closed`, and `CLOSED` into one node while
  // leaving scripts without case (Chinese, Japanese, Thai, etc.) unchanged.
  const lowered = normalized.toLowerCase();
  const characters = Array.from(lowered);
  const firstCased = characters.findIndex((character) => character.toLowerCase() !== character.toUpperCase());
  if (firstCased < 0) return normalized;
  characters[firstCased] = characters[firstCased].toUpperCase();
  return characters.join('').normalize('NFC');
}

export function expressionPrefixUpperBound(prefix: string): string | null {
  const codePoints = Array.from(prefix);
  for (let index = codePoints.length - 1; index >= 0; index -= 1) {
    const value = codePoints[index].codePointAt(0);
    if (value !== undefined && value < 0x10ffff) {
      return `${codePoints.slice(0, index).join('')}${String.fromCodePoint(value + 1)}`;
    }
  }
  return null;
}
