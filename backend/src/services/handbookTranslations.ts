import type { D1Database } from '@cloudflare/workers-types';

const MAX_ITEMS = 5000;
const MAX_TRANSLATIONS = 10000;

export interface HandbookTranslationReading {
  scheme: string;
  value: string;
}

export interface HandbookTranslation {
  id: number;
  text: string;
  lang_code: string;
  language_locale_code: string;
  language_name: string;
  readings: HandbookTranslationReading[];
}

export interface HandbookTranslationItem {
  source_expression_id: number;
  translations: HandbookTranslation[];
}

export interface HandbookTranslationsResponse {
  target_locale: string;
  items: HandbookTranslationItem[];
}

export class HandbookTranslationError extends Error {
  constructor(readonly code: 'HANDBOOK_NOT_FOUND' | 'HANDBOOK_PRIVATE' | 'INVALID_TARGET_LOCALE') {
    super(code);
  }
}

interface HandbookRow { visibility: string; user_id: number }
interface EdgeTranslationRow {
  source_expression_id: number;
  target_expression_id: number;
  target_text: string;
  target_lang_code: string;
  target_language_name: string;
  target_locale_code: string;
  section_position: number;
  item_position: number;
}
interface ReadingRow { expression_id: number; scheme: string; value: string }

const SOURCE_ITEMS = `
  SELECT i.expression_id, MIN(s.position) AS section_position, MIN(i.position) AS item_position
  FROM handbook_section_items i
  JOIN handbook_sections s ON s.id=i.section_id
  JOIN expressions source_expression ON source_expression.id=i.expression_id
  JOIN languages source_language ON source_language.id=source_expression.language_id
  WHERE s.handbook_id=? AND source_language.code='eng'
  GROUP BY i.expression_id
`;

const TARGET_EDGES = `
  SELECT source_items.expression_id AS source_expression_id,
         edge.expression_b_id AS target_expression_id,
         target_expression.text AS target_text,
         target_language.code AS target_lang_code,
         target_language.name_en AS target_language_name,
         target_locale.code AS target_locale_code,
         source_items.section_position,
         source_items.item_position
  FROM source_items
  JOIN expression_edges edge ON edge.expression_a_id=source_items.expression_id
  JOIN expressions target_expression ON target_expression.id=edge.expression_b_id
  JOIN languages target_language ON target_language.id=target_expression.language_id
  JOIN expression_locale_links target_link ON target_link.expression_id=target_expression.id
  JOIN language_locales target_locale ON target_locale.id=target_link.locale_id
  WHERE target_language.code<>'eng' AND edge.score>=0 AND target_locale.code=?
`;

const TARGET_EDGES_REVERSE = `
  SELECT source_items.expression_id AS source_expression_id,
         edge.expression_a_id AS target_expression_id,
         target_expression.text AS target_text,
         target_language.code AS target_lang_code,
         target_language.name_en AS target_language_name,
         target_locale.code AS target_locale_code,
         source_items.section_position,
         source_items.item_position
  FROM source_items
  JOIN expression_edges edge ON edge.expression_b_id=source_items.expression_id
  JOIN expressions target_expression ON target_expression.id=edge.expression_a_id
  JOIN languages target_language ON target_language.id=target_expression.language_id
  JOIN expression_locale_links target_link ON target_link.expression_id=target_expression.id
  JOIN language_locales target_locale ON target_locale.id=target_link.locale_id
  WHERE target_language.code<>'eng' AND edge.score>=0 AND target_locale.code=?
`;

function readingKey(row: ReadingRow): string {
  return `${row.expression_id}\u0000${row.scheme}\u0000${row.value}`;
}

export async function getHandbookTranslations(
  db: D1Database,
  handbookId: number,
  targetLocale: string,
  options: { allowPrivate?: boolean; viewerId?: number } = {},
): Promise<HandbookTranslationsResponse> {
  const normalizedLocale = targetLocale.trim();
  if (!normalizedLocale || normalizedLocale.length > 128) {
    throw new HandbookTranslationError('INVALID_TARGET_LOCALE');
  }
  const handbook = await db.prepare('SELECT visibility,user_id FROM handbooks WHERE id=?').bind(handbookId).first<HandbookRow>();
  if (!handbook) throw new HandbookTranslationError('HANDBOOK_NOT_FOUND');
  if (handbook.visibility === 'private' && !options.allowPrivate && handbook.user_id !== options.viewerId) {
    throw new HandbookTranslationError('HANDBOOK_PRIVATE');
  }
  const locale = await db.prepare('SELECT code FROM language_locales WHERE code=?').bind(normalizedLocale).first<{ code: string }>();
  if (!locale) throw new HandbookTranslationError('INVALID_TARGET_LOCALE');

  const sourceItems = `WITH source_items AS (${SOURCE_ITEMS})`;
  const edgeSql = `${sourceItems}
    SELECT * FROM (${TARGET_EDGES}
      UNION ALL
      ${TARGET_EDGES_REVERSE}
    )
    ORDER BY section_position,item_position,target_text,target_expression_id
    LIMIT ?`;
  const edgeRows = await db.prepare(edgeSql).bind(handbookId, normalizedLocale, handbookId, normalizedLocale, MAX_TRANSLATIONS).all<EdgeTranslationRow>();

  const readingSql = `WITH source_items AS (${SOURCE_ITEMS}), target_expressions AS (
      ${TARGET_EDGES}
      UNION
      ${TARGET_EDGES_REVERSE}
    )
    SELECT DISTINCT readings.expression_id, readings.scheme, readings.value
    FROM expression_readings readings
    JOIN target_expressions targets ON targets.target_expression_id=readings.expression_id
    JOIN language_locales reading_locale ON reading_locale.id=readings.locale_id AND reading_locale.code=?
    ORDER BY readings.expression_id, readings.scheme, readings.value
    LIMIT ?`;
  const readingRows = await db.prepare(readingSql).bind(handbookId, normalizedLocale, handbookId, normalizedLocale, normalizedLocale, MAX_TRANSLATIONS).all<ReadingRow>();

  const readingsByExpression = new Map<number, HandbookTranslationReading[]>();
  const seenReadings = new Set<string>();
  for (const row of readingRows.results) {
    if (seenReadings.has(readingKey(row))) continue;
    seenReadings.add(readingKey(row));
    const values = readingsByExpression.get(row.expression_id) ?? [];
    values.push({ scheme: row.scheme, value: row.value });
    readingsByExpression.set(row.expression_id, values);
  }
  const itemsBySource = new Map<number, HandbookTranslationItem>();
  for (const row of edgeRows.results) {
    let item = itemsBySource.get(row.source_expression_id);
    if (!item) {
      if (itemsBySource.size >= MAX_ITEMS) continue;
      item = { source_expression_id: row.source_expression_id, translations: [] };
      itemsBySource.set(row.source_expression_id, item);
    }
    if (item.translations.some((translation) => translation.id === row.target_expression_id)) continue;
    item.translations.push({
      id: row.target_expression_id,
      text: row.target_text,
      lang_code: row.target_lang_code,
      language_locale_code: row.target_locale_code,
      language_name: row.target_language_name,
      readings: readingsByExpression.get(row.target_expression_id) ?? [],
    });
  }
  return { target_locale: normalizedLocale, items: [...itemsBySource.values()] };
}
