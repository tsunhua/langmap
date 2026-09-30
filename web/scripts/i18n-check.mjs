#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { catalogManifest, root } from './i18n-lib.mjs'

function parseCsv(input) {
  const rows = []
  let row = []
  let value = ''
  let quoted = false
  let offset = input.charCodeAt(0) === 0xfeff ? 1 : 0

  while (offset < input.length) {
    const character = input[offset]
    if (quoted) {
      if (character === '"') {
        if (input[offset + 1] === '"') {
          value += '"'
          offset += 2
          continue
        }
        quoted = false
      } else {
        value += character
      }
      offset += 1
      continue
    }
    if (character === '"' && value.length === 0) {
      quoted = true
    } else if (character === ',') {
      row.push(value)
      value = ''
    } else if (character === '\n' || character === '\r') {
      row.push(value)
      if (row.some(Boolean)) rows.push(row)
      row = []
      value = ''
      if (character === '\r' && input[offset + 1] === '\n') offset += 1
    } else {
      value += character
    }
    offset += 1
  }
  if (value.length || row.length) {
    row.push(value)
    rows.push(row)
  }
  if (quoted) throw new Error('Unterminated quote in UI locale CSV')
  return rows
}

const manifest = catalogManifest()
const keys = new Set()
const errors = []
for (const entry of manifest) {
  if (keys.has(entry.key)) errors.push(`duplicate key: ${entry.key}`)
  keys.add(entry.key)
  if (!entry.message.trim()) errors.push(`empty message: ${entry.key}`)
  if (/<!--[\s\S]*?-->|<\/?[A-Za-z][^>]*>/.test(entry.message)) errors.push(`HTML is not allowed: ${entry.key}`)
  if (/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/.test(entry.message)) errors.push(`control character: ${entry.key}`)
  if ([...entry.message].length > 4000) errors.push(`message exceeds 4000 code points: ${entry.key}`)
}

const csvPath = path.join(root, '../scripts/i18n/ui-locales.csv')
const csvRows = parseCsv(fs.readFileSync(csvPath, 'utf8'))
const headers = csvRows.shift() ?? []
if (headers[0] !== 'ENTRY_ID' || headers[1] !== 'NOTE') {
  errors.push('UI locale CSV must start with ENTRY_ID,NOTE')
}
const localeNames = headers.slice(2).map((header) => header.startsWith('LOCALE_') ? header.slice(7) : '')
if (localeNames.length < 2 || localeNames.some((locale) => !locale)) {
  errors.push('UI locale CSV must declare at least two valid locale columns')
}
const localeRows = new Map()
for (const [index, row] of csvRows.entries()) {
  if (row.length !== headers.length || !row[0]) {
    errors.push(`invalid UI locale CSV row ${index + 2}`)
    continue
  }
  if (localeRows.has(row[0])) {
    errors.push(`duplicate UI locale CSV key: ${row[0]}`)
    continue
  }
  localeRows.set(row[0], Object.fromEntries(localeNames.map((locale, column) => [locale, row[column + 2]])))
}

for (const entry of manifest) {
  const row = localeRows.get(entry.key)
  if (!row) {
    errors.push(`missing UI locale CSV row: ${entry.key}`)
    continue
  }
  for (const locale of localeNames) {
    if (!row[locale]?.trim()) errors.push(`missing ${locale} translation: ${entry.key}`)
  }
  if (row['eng-Latn-US'] !== entry.message) {
    errors.push(`English source mismatch in UI locale CSV: ${entry.key}`)
  }
}

if (errors.length) {
  console.error(errors.map(error => `✗ ${error}`).join('\n'))
  process.exitCode = 1
} else {
  console.log(`i18n:check passed — ${manifest.length} keys, ${localeNames.length} complete locales, project_id=langmap-web`)
}
