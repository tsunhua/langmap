export interface HandbookItem { text: string; lang: string; }
export interface HandbookSection { title: string; items: HandbookItem[]; }

const TAG_RE = /\{\{(?:text:)?([^|}]+)((?:\|[^}]+)*)\}\}/g;
const HEADING_RE = /^(#{1,6})\s+(.+?)\s*$/;

function parseParams(params: string, sourceLang: string): string {
  const parts = params.split('|').map(s => s.trim()).filter(Boolean);
  for (const p of parts) {
    if (p.startsWith('lang:')) return p.slice(5).trim();
  }
  return sourceLang;
}

export function parseHandbook(markdown: string, sourceLang: string, leadTitle: string): HandbookSection[] {
  const sections: HandbookSection[] = [{ title: leadTitle, items: [] }];
  let cur = sections[0];
  const seen = new Set<string>();

  const pushTag = (text: string, lang: string) => {
    const key = `${text}|${lang}`;
    if (seen.has(key)) return;
    seen.add(key);
    cur.items.push({ text, lang });
  };

  for (const line of markdown.split(/\r?\n/)) {
    const h = line.match(HEADING_RE);
    if (h) {
      cur = { title: h[2], items: [] };
      sections.push(cur);
      seen.clear();
      continue;
    }
    let m: RegExpExecArray | null;
    TAG_RE.lastIndex = 0;
    while ((m = TAG_RE.exec(line)) !== null) {
      const text = m[1].trim();
      const lang = parseParams(m[2] || '', sourceLang);
      pushTag(text, lang);
    }
  }
  return sections;
}
