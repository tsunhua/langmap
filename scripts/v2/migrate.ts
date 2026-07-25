import Database from 'better-sqlite3';
import { writeFileSync } from 'node:fs';
import { edgesForGroup } from './lib/edges';
import { parseHandbook } from './lib/handbook';

const [oldPath, outPath = './v2-data.sql'] = process.argv.slice(2);
if (!oldPath) { console.error('用法: tsx migrate.ts <舊 sqlite 路徑> [輸出 sql]'); process.exit(1); }

const old = new Database(oldPath, { readonly: true });
const lines: string[] = [];
const emit = (s: string) => lines.push(s);
const sqlStr = (v: unknown): string => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);

const COPY_TABLES = ['languages', 'expressions', 'expression_versions', 'users', 'email_verification_tokens', 'language_stats', 'ui_locales'];
let copyCounts: Record<string, number> = {};

function copyTable(table: string) {
  const cols = (old.prepare(`PRAGMA table_info(${table})`).all() as any[]).map(c => c.name);
  const rows = old.prepare(`SELECT * FROM ${table}`).all() as any[];
  copyCounts[table] = rows.length;
  for (const row of rows) {
    const vals = cols.map(c => sqlStr(row[c])).join(', ');
    emit(`INSERT INTO ${table} (${cols.join(', ')}) VALUES (${vals});`);
  }
}

// 1. Copy kept tables
emit('-- copied tables');
for (const t of COPY_TABLES) {
  try { copyTable(t); } catch (e) { console.warn(`  跳過 ${t}:${(e as Error).message}`); }
}

// 2. meanings → edges (dedup across groups)
emit('-- edges (from meanings)');
const groups = old.prepare(`SELECT meaning_id, expression_id FROM expression_meaning ORDER BY meaning_id, expression_id`).all() as any[];
const byMeaning = new Map<number, number[]>();
for (const r of groups) {
  if (!byMeaning.has(r.meaning_id)) byMeaning.set(r.meaning_id, []);
  byMeaning.get(r.meaning_id)!.push(r.expression_id);
}
const seenEdge = new Set<string>();
let edgeCount = 0;
for (const members of byMeaning.values()) {
  for (const e of edgesForGroup(members)) {
    if (seenEdge.has(e.id)) continue;
    seenEdge.add(e.id);
    emit(`INSERT INTO expression_edges (id, expression_a_id, expression_b_id, score, source) VALUES ('${e.id}', ${e.a}, ${e.b}, 0, 'migration');`);
    edgeCount++;
  }
}

// 3. handbooks → simplified
emit('-- handbooks (simplified)');
const exprLookup = new Map<string, number>();
(old.prepare(`SELECT id, text, language_code FROM expressions`).all() as any[]).forEach(r => exprLookup.set(`${r.text}|${r.language_code}`, r.id));
const lookupExpr = (text: string, lang: string): number | null => exprLookup.has(`${text}|${lang}`) ? exprLookup.get(`${text}|${lang}`)! : null;

const handbooks = old.prepare(`SELECT * FROM handbooks ORDER BY id`).all() as any[];
let sectionId = 1, itemId = 1;
let hbCount = 0, secCount = 0, itemCount = 0, missingExpr = 0;
for (const hb of handbooks) {
  const vis = hb.is_public ? 'public' : 'private';
  emit(`INSERT INTO handbooks (id, user_id, title, visibility, score, created_at, updated_at) VALUES (${hb.id}, ${hb.user_id}, ${sqlStr(hb.title)}, '${vis}', 0, ${sqlStr(hb.created_at)}, ${sqlStr(hb.updated_at)});`);
  hbCount++;
  let sections;
  if (hb.has_pages) {
    const pages = old.prepare(`SELECT * FROM handbook_pages WHERE handbook_id = ? ORDER BY sort_order, id`).all(hb.id) as any[];
    sections = [];
    for (const p of pages) sections.push(...parseHandbook(p.content || '', hb.source_lang || 'en', p.title));
  } else {
    sections = parseHandbook(hb.content || '', hb.source_lang || 'en', hb.title);
  }
  sections.forEach((sec, si) => {
    emit(`INSERT INTO handbook_sections (id, handbook_id, title, position) VALUES (${sectionId}, ${hb.id}, ${sqlStr(sec.title)}, ${si});`);
    secCount++;
    sec.items.forEach((it, ii) => {
      const eid = lookupExpr(it.text, it.lang);
      if (eid === null) { missingExpr++; return; }
      emit(`INSERT INTO handbook_section_items (id, section_id, expression_id, position) VALUES (${itemId}, ${sectionId}, ${eid}, ${ii});`);
      itemId++; itemCount++;
    });
    sectionId++;
  });
}

old.close();
writeFileSync(outPath, lines.join('\n'));
console.log('── 遷移摘要 ──');
console.log('copied:', copyCounts);
console.log('edges:', edgeCount);
console.log('handbooks:', hbCount, '/ sections:', secCount, '/ items:', itemCount, '/ missing-tags-skipped:', missingExpr);
console.log('輸出:', outPath);
