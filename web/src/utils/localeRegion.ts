export function regionFromLocale(code: string): string | null {
  const parts = code.split('-')
  const last = parts[parts.length - 1] ?? ''
  return /^[A-Za-z]{2}$/.test(last) ? last.toUpperCase() : null
}