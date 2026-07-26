#!/usr/bin/env node
import { catalogManifest } from './i18n-lib.mjs'

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

if (errors.length) {
  console.error(errors.map(error => `✗ ${error}`).join('\n'))
  process.exitCode = 1
} else {
  console.log(`i18n:check passed — ${manifest.length} keys, project_id=langmap-web, source_locale=en-US`)
}
