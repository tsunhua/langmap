export type TranslationCatalog = Readonly<Record<string, string>>
export type TranslationCatalogs = Readonly<Record<string, TranslationCatalog>>

function parseRow(input: string, start: number): { row: string[]; next: number } {
  const row: string[] = []
  let value = ''
  let quoted = false
  let index = start
  while (index < input.length) {
    const character = input[index]
    if (quoted) {
      if (character === '"') {
        if (input[index + 1] === '"') {
          value += '"'
          index += 2
          continue
        }
        quoted = false
        index += 1
        continue
      }
      value += character
      index += 1
      continue
    }
    if (character === '"' && value.length === 0) {
      quoted = true
      index += 1
      continue
    }
    if (character === ',') {
      row.push(value)
      value = ''
      index += 1
      continue
    }
    if (character === '\n' || character === '\r') {
      row.push(value)
      if (character === '\r' && input[index + 1] === '\n') index += 1
      return { row, next: index + 1 }
    }
    value += character
    index += 1
  }
  if (quoted) throw new Error('unterminated CSV quote')
  if (value.length > 0 || row.length > 0) row.push(value)
  return { row, next: index }
}

export function parseTranslationWideCsv(input: string): TranslationCatalogs {
  const rows: string[][] = []
  let offset = input.charCodeAt(0) === 0xfeff ? 1 : 0
  while (offset < input.length) {
    const parsed = parseRow(input, offset)
    offset = parsed.next
    if (parsed.row.length === 1 && parsed.row[0] === '') continue
    rows.push(parsed.row)
  }
  if (rows.length === 0 || rows[0][0] !== 'ENTRY_ID' || rows[0][1] !== 'NOTE') {
    throw new Error('translation CSV must start with ENTRY_ID,NOTE')
  }
  const localeColumns = rows[0].slice(2).map((header) => {
    if (!header.startsWith('LOCALE_') || header.length <= 'LOCALE_'.length) {
      throw new Error(`invalid translation locale column: ${header}`)
    }
    return header.slice('LOCALE_'.length)
  })
  if (localeColumns.length < 2 || new Set(localeColumns).size !== localeColumns.length) {
    throw new Error('translation CSV needs at least two unique locale columns')
  }
  const result: Record<string, Record<string, string>> = Object.fromEntries(
    localeColumns.map((locale) => [locale, {}]),
  )
  const entryIds = new Set<string>()
  for (const [index, row] of rows.slice(1).entries()) {
    if (row.length !== rows[0].length || !row[0].trim() || entryIds.has(row[0])) {
      throw new Error(`invalid translation CSV row ${index + 2}`)
    }
    entryIds.add(row[0])
    for (const [column, locale] of localeColumns.entries()) {
      const value = row[column + 2]
      if (value) result[locale][row[0]] = value
    }
  }
  return Object.freeze(
    Object.fromEntries(
      localeColumns.map((locale) => [locale, Object.freeze(result[locale])]),
    ),
  )
}
