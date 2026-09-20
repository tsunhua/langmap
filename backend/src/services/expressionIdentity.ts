export class ExpressionIdentityError extends Error {
  readonly code = 'UNBALANCED_DELIMITER' as const;

  constructor() {
    super('UNBALANCED_DELIMITER');
    this.name = 'ExpressionIdentityError';
  }
}

type DelimiterFamily = {
  name: string;
  opening: string;
  closing: string;
  symmetric?: boolean;
};

type DelimiterScan = {
  matched: Array<[number, number, string]>;
  unmatched: Array<[number, string]>;
};

const delimiterFamilies: DelimiterFamily[] = [
  { name: 'double_quote', opening: '"', closing: '"', symmetric: true },
  { name: 'ascii_apostrophe_quote', opening: "'", closing: "'", symmetric: true },
  { name: 'curly_double_quote', opening: '“', closing: '”' },
  { name: 'curly_single_quote', opening: '‘', closing: '’' },
  { name: 'cjk_corner_quote', opening: '「', closing: '」' },
  { name: 'cjk_double_corner_quote', opening: '『', closing: '』' },
  { name: 'parenthesis', opening: '(', closing: ')' },
  { name: 'fullwidth_parenthesis', opening: '（', closing: '）' },
  { name: 'square_bracket', opening: '[', closing: ']' },
  { name: 'fullwidth_square_bracket', opening: '【', closing: '】' },
  { name: 'brace', opening: '{', closing: '}' },
  { name: 'angle_bracket', opening: '〈', closing: '〉' },
  { name: 'double_angle_bracket', opening: '《', closing: '》' },
  { name: 'tortoise_bracket', opening: '〔', closing: '〕' },
];
const openingFamilies = new Map(delimiterFamilies.filter((family) => !family.symmetric).map((family) => [family.opening, family]));
const closingFamilies = new Map(delimiterFamilies.filter((family) => !family.symmetric).map((family) => [family.closing, family]));
const symmetricFamilies = new Map(delimiterFamilies.filter((family) => family.symmetric).map((family) => [family.opening, family]));
const periods = new Set(['.', '．', '。', '｡']);
const boundaryMarks = new Set(['.', '．', '。', '｡', ',', '，', '､', '!', '！', '?', '？', '、']);

function isAlphanumeric(character: string): boolean {
  return /[\p{L}\p{N}]/u.test(character);
}

function isLexicalApostrophe(characters: string[], index: number): boolean {
  const character = characters[index];
  if (character !== "'" && character !== '’') return false;
  if (index === 0 || index + 1 === characters.length) return false;
  return isAlphanumeric(characters[index - 1]) || isAlphanumeric(characters[index + 1]);
}

function scanDelimiters(characters: string[]): DelimiterScan {
  const stack: Array<[string, number]> = [];
  const matched: Array<[number, number, string]> = [];
  const unmatched: Array<[number, string]> = [];
  characters.forEach((character, index) => {
    if (isLexicalApostrophe(characters, index)) return;
    const symmetric = symmetricFamilies.get(character);
    if (symmetric) {
      if (stack.at(-1)?.[0] === symmetric.name) {
        const [, openingIndex] = stack.pop()!;
        matched.push([openingIndex, index, symmetric.name]);
      } else {
        stack.push([symmetric.name, index]);
      }
      return;
    }
    const opening = openingFamilies.get(character);
    if (opening) {
      stack.push([opening.name, index]);
      return;
    }
    const closing = closingFamilies.get(character);
    if (!closing) return;
    if (stack.at(-1)?.[0] === closing.name) {
      const [, openingIndex] = stack.pop()!;
      matched.push([openingIndex, index, closing.name]);
    } else {
      unmatched.push([index, closing.name]);
    }
  });
  unmatched.push(...stack.map(([name, index]) => [index, name] as [number, string]));
  unmatched.sort((left, right) => left[0] - right[0]);
  matched.sort((left, right) => left[0] - right[0]);
  return { matched, unmatched };
}

function allCasedUpper(characters: string[]): boolean {
  const cased = characters.filter((character) => character.toLowerCase() !== character.toUpperCase());
  return cased.length > 0 && cased.every((character) => character === character.toUpperCase());
}

function asciiPeriodRunLength(characters: string[], index: number): number {
  if (characters[index] !== '.') return 0;
  let start = index;
  while (start > 0 && characters[start - 1] === '.') start -= 1;
  let end = index + 1;
  while (end < characters.length && characters[end] === '.') end += 1;
  return end - start;
}

function stripBoundaryMarks(characters: string[]): boolean {
  let changed = false;
  const preservePeriods = allCasedUpper(characters);
  while (characters.length > 0) {
    const character = characters[0];
    if (!boundaryMarks.has(character)) break;
    if (periods.has(character) && (preservePeriods || (character === '.' && asciiPeriodRunLength(characters, 0) >= 3))) break;
    characters.shift();
    changed = true;
  }
  while (characters.length > 0) {
    const index = characters.length - 1;
    const character = characters[index];
    if (!boundaryMarks.has(character)) break;
    if (periods.has(character) && (preservePeriods || (character === '.' && asciiPeriodRunLength(characters, index) >= 3))) break;
    characters.pop();
    changed = true;
  }
  return changed;
}

function removeOuterPair(characters: string[], scan: DelimiterScan): boolean {
  if (characters.length === 0) return false;
  const outer = scan.matched.find(([, closingIndex]) => closingIndex === characters.length - 1);
  if (!outer || outer[0] !== 0) return false;
  characters.pop();
  characters.shift();
  return true;
}

function removeBoundaryOrphan(characters: string[], scan: DelimiterScan): boolean {
  const orphan = scan.unmatched.find(([index]) => index === 0 || index === characters.length - 1);
  if (!orphan) return false;
  characters.splice(orphan[0], 1);
  return true;
}

function sentenceCase(normalized: string): string {
  if (!normalized) return normalized;
  const cased = Array.from(normalized).filter((character) => character.toLowerCase() !== character.toUpperCase());
  if (cased.length > 0 && cased.every((character) => character === character.toUpperCase())) return normalized;
  const characters = Array.from(normalized.toLowerCase());
  const firstCased = characters.findIndex((character) => character.toLowerCase() !== character.toUpperCase());
  if (firstCased < 0) return normalized;
  characters[firstCased] = characters[firstCased].toUpperCase();
  return characters.join('');
}

export function canonicalizeExpressionText(input: string): string {
  const normalized = input.trim().normalize('NFC');
  if (!normalized) return normalized;
  const characters = Array.from(normalized);
  while (characters.length > 0) {
    let changed = stripBoundaryMarks(characters);
    if (characters.length === 0) return '';
    const scan = scanDelimiters(characters);
    if (removeOuterPair(characters, scan) || removeBoundaryOrphan(characters, scan)) changed = true;
    if (!changed) break;
    while (characters[0]?.trim() === '') characters.shift();
    while (characters.at(-1)?.trim() === '') characters.pop();
  }
  if (characters.length === 0) return '';
  if (scanDelimiters(characters).unmatched.length > 0) throw new ExpressionIdentityError();
  const result = characters.join('').trim();
  if (!result) return '';
  return sentenceCase(result).normalize('NFC');
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
