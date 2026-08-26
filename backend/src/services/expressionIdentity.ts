export function canonicalizeExpressionText(input: string): string {
  return input.trim().normalize('NFC');
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
