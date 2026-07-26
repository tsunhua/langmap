#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { catalogManifest } from './i18n-lib.mjs'

const args = new Set(process.argv.slice(2))
const dryRun = args.has('--dry-run') || !args.has('--write-manifest')
const manifest = catalogManifest()
const output = {
  project_id: 'langmap-web',
  source_locale: 'en-US',
  generated_at: new Date().toISOString(),
  messages: manifest,
}

if (dryRun) {
  console.log(`i18n:sync dry-run — ${manifest.length} messages would be synchronized for ${output.project_id}`)
  console.log(JSON.stringify({ project_id: output.project_id, source_locale: output.source_locale, keys: manifest.map(item => item.key) }, null, 2))
  process.exit(0)
}

const target = path.resolve(import.meta.dirname, '../src/locales/ui-messages.manifest.json')
fs.writeFileSync(target, `${JSON.stringify(output, null, 2)}\n`)
console.log(`i18n:sync wrote ${manifest.length} messages to ${target}`)
