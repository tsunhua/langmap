import type { UiLocale } from '@/api/localization'

export interface LocaleCodeParts {
  base: string
  script?: string
  region?: string
}

export interface LocaleVarietyItem {
  code: string
  varietyLabel: string
  scriptLabel?: string
  direction?: 'ltr' | 'rtl'
}

export interface LocaleVarietyGroup {
  base: string
  varietyLabel: string
  items: LocaleVarietyItem[]
}

export function parseLocaleCode(code: string): LocaleCodeParts {
  const parts = code.split('-')
  const result: LocaleCodeParts = { base: parts[0] }
  for (let i = 1; i < parts.length; i++) {
    const sub = parts[i]
    if (/^[A-Za-z]{4}$/.test(sub)) {
      result.script = sub
    } else if (/^[A-Za-z]{2}$/.test(sub) && sub === sub.toUpperCase()) {
      result.region = sub
    }
  }
  return result
}

export function splitVarietyAndScript(nativeName: string): { variety: string; scriptLabel?: string } {
  const m = nativeName.match(/^(.*)（([^（）]+)）$/)
  if (m) return { variety: m[1], scriptLabel: m[2] }
  return { variety: nativeName }
}

export function groupLocalesByVariety(locales: UiLocale[]): LocaleVarietyGroup[] {
  const groups = new Map<string, LocaleVarietyGroup>()
  for (const loc of locales) {
    const { base } = parseLocaleCode(loc.code)
    const native = loc.native_name || loc.name || loc.code
    const { variety, scriptLabel } = splitVarietyAndScript(native)
    let group = groups.get(base)
    if (!group) {
      group = { base, varietyLabel: variety, items: [] }
      groups.set(base, group)
    }
    if (!group.varietyLabel && variety) group.varietyLabel = variety
    group.items.push({ code: loc.code, varietyLabel: variety, scriptLabel, direction: loc.direction })
  }
  const list = [...groups.values()]
  list.sort((a, b) => {
    if (a.base === 'en') return -1
    if (b.base === 'en') return 1
    return a.varietyLabel.localeCompare(b.varietyLabel) || a.base.localeCompare(b.base)
  })
  for (const g of list) {
    g.items.sort((a, b) => (a.code < b.code ? -1 : a.code > b.code ? 1 : 0))
  }
  return list
}
