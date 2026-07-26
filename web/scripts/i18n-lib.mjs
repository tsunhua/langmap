import fs from 'node:fs'
import path from 'node:path'
import vm from 'node:vm'

export const root = path.resolve(import.meta.dirname, '..')
export const sourcePath = path.join(root, 'src/locales/en.ts')

export function readCatalog(file = sourcePath) {
  const source = fs.readFileSync(file, 'utf8')
  const match = source.match(/export const en\s*=\s*([\s\S]*?)\s*as const\s*$/m)
  if (!match) throw new Error(`Cannot find source catalog in ${file}`)
  return vm.runInNewContext(`(${match[1]})`, Object.create(null))
}

export function flattenCatalog(value, prefix = '', result = new Map()) {
  if (typeof value === 'string') {
    result.set(prefix, value)
    return result
  }
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`Catalog value at ${prefix || '<root>'} must be an object or string`)
  }
  for (const key of Object.keys(value)) {
    if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(key)) throw new Error(`Invalid catalog key: ${key}`)
    flattenCatalog(value[key], prefix ? `${prefix}.${key}` : key, result)
  }
  return result
}

export function placeholders(message) {
  return [...message.matchAll(/\{([A-Za-z][A-Za-z0-9_]*)\}/g)].map(match => match[1]).sort()
}

export function pluralForms(message) {
  return message.split('|').map(value => value.trim())
}

export function catalogManifest() {
  const flat = flattenCatalog(readCatalog())
  return [...flat.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([key, message]) => ({
    key,
    message,
    placeholders: placeholders(message),
    plural_forms: pluralForms(message).length,
  }))
}
