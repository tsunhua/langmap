import { describe, it, expect } from 'vitest';
import { parseHandbook } from './handbook';

describe('parseHandbook', () => {
  it('heading → section, tags → ordered items, lang default/explicit', () => {
    const md = [
      '前言 {{foo}} 結束',
      '',
      '# 問候',
      '',
      '{{text:你好|lang:cmn}} 和 {{text:Hello|lang:en}}',
    ].join('\n');
    const s = parseHandbook(md, 'en', 'My Handbook');
    expect(s).toEqual([
      { title: 'My Handbook', items: [{ text: 'foo', lang: 'en' }] },
      { title: '問候', items: [
        { text: '你好', lang: 'cmn' },
        { text: 'Hello', lang: 'en' },
      ] },
    ]);
  });
  it('same section deduplicates (text,lang)', () => {
    const s = parseHandbook('{{a}} {{a}}', 'en', 'T');
    expect(s[0].items).toEqual([{ text: 'a', lang: 'en' }]);
  });
  it('mid param is ignored', () => {
    const s = parseHandbook('{{text:x|mid:123}}', 'en', 'T');
    expect(s[0].items).toEqual([{ text: 'x', lang: 'en' }]);
  });
  it('section with no tags preserved as empty items', () => {
    const s = parseHandbook('# 空\n\n只有 prose', 'en', 'T');
    expect(s[0]).toEqual({ title: 'T', items: [] });
    expect(s[1]).toEqual({ title: '空', items: [] });
  });
});
