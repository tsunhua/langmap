import { MAX_PLANNER_SPANS } from '../../utils/limits';
import type { PlannerSpan } from './types';

// These aliases select segmentation rules only; the request's source identity
// stays in ISO 639-3, including varieties that share writing conventions.
const SEGMENTER_LOCALES: Readonly<Record<string, string>> = {
  eng: 'en', cmn: 'zh', nan: 'zh', jpn: 'ja', arb: 'ar',
};

function segmenterLocale(code: string): string {
  const candidate = SEGMENTER_LOCALES[code] ?? Intl.getCanonicalLocales(code)[0];
  const supported = Intl.Segmenter.supportedLocalesOf(candidate);
  // Use fixed generic word boundaries when ICU lacks this language rather than
  // inheriting the host's locale. This fallback never changes source identity.
  return supported[0] ?? 'en';
}

function spread<T>(items: T[], count: number): T[] {
  if (count <= 0) return [];
  if (items.length <= count) return items;
  if (count === 1) return [items[0]];
  return Array.from({ length: count }, (_, index) => items[Math.round(index * (items.length - 1) / (count - 1))]);
}

export function localRetrievalSpans(text: string, sourceLangCode: string, maxSpans: number): PlannerSpan[] {
  const cap = Math.min(MAX_PLANNER_SPANS, Math.max(0, Math.floor(maxSpans)));
  if (cap === 0 || text.length === 0) return [];
  const segmenter = new Intl.Segmenter(segmenterLocale(sourceLangCode), { granularity: 'word' });
  const words: PlannerSpan[] = [];
  for (const segment of segmenter.segment(text)) {
    if (!segment.isWordLike) continue;
    const start = Array.from(text.slice(0, segment.index)).length;
    words.push({ start, end: start + Array.from(segment.segment).length, text: segment.segment, reason: 'keyword', confidence: 0.5 });
  }
  const chars = Array.from(text);
  const phrases: PlannerSpan[] = [];
  for (let index = 1; index < words.length; index += 1) {
    const previous = words[index - 1];
    const word = words[index];
    const gap = chars.slice(previous.end, word.start).join('');
    if (!/^[\t ]*$/u.test(gap) || word.end - previous.start > 64) continue;
    phrases.push({ start: previous.start, end: word.end, text: chars.slice(previous.start, word.end).join(''), reason: 'phrase', confidence: 0.5 });
  }
  const unique = (spans: PlannerSpan[]): PlannerSpan[] => {
    const seen = new Set<string>();
    return spans.filter(span => {
      if (seen.has(span.text)) return false;
      seen.add(span.text);
      return true;
    });
  };
  const uniqueWords = unique(words);
  const uniquePhrases = unique(phrases).filter(phrase => !uniqueWords.some(word => word.text === phrase.text));
  // Reserve roots for both lexical precision and phrase context, while sampling
  // the full sentence so a long input's tail is not lost to the query budget.
  const wordBudget = uniquePhrases.length > 0 ? Math.min(uniqueWords.length, Math.max(1, Math.ceil(cap * 2 / 3))) : cap;
  const selectedWords = spread(uniqueWords, wordBudget);
  const selectedPhrases = spread(uniquePhrases, cap - selectedWords.length);
  return [...selectedWords, ...selectedPhrases].sort((a, b) => a.start - b.start || a.end - b.end);
}
