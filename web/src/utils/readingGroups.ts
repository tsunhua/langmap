import type { ExpressionReading } from '@/api/expressions'
import { regionFromLocale } from '@/utils/localeRegion'

export interface ReadingGroup {
  scheme: string
  value: string
  readings: ExpressionReading[]
}

function readingKey(reading: ExpressionReading): string {
  return `${reading.language_locale_code}\u0000${reading.scheme}\u0000${reading.value}`
}

function comparableReadingValue(value: string): string {
  return value.replace(/\s+/g, '')
}

function whitespaceCount(value: string): number {
  return value.match(/\s/g)?.length ?? 0
}

/** Group identical values within a reading scheme while keeping stable locale order. */
export function groupReadings(readings: readonly ExpressionReading[]): ReadingGroup[] {
  const groups = new Map<string, ReadingGroup>()
  const sorted = [...readings].sort((a, b) =>
    a.language_locale_code.localeCompare(b.language_locale_code)
    || a.scheme.localeCompare(b.scheme)
    || a.value.localeCompare(b.value),
  )

  for (const reading of sorted) {
    const groupKey = `${reading.scheme}\u0000${comparableReadingValue(reading.value)}`
    const group = groups.get(groupKey)
    if (group) {
      if (whitespaceCount(reading.value) > whitespaceCount(group.value)) {
        group.value = reading.value
      }
      if (!group.readings.some((item) => readingKey(item) === readingKey(reading))) {
        group.readings.push(reading)
      }
      continue
    }
    groups.set(groupKey, { scheme: reading.scheme, value: reading.value, readings: [reading] })
  }

  return [...groups.values()]
}

export function hasMultipleReadingSchemes(readings: readonly ReadingGroup[]): boolean {
  return new Set(readings.map((reading) => reading.scheme)).size > 1
}

/** Prefer the place name inside locale labels such as「客語（大埔腔）」. */
export function readingLocaleLabel(reading: ExpressionReading): string {
  const displayName = reading.locale_display_name?.trim()
  const placeName = displayName?.match(/[（(]([^）)]*)[）)]$/)?.[1]?.replace(/腔\s*$/, '').trim()
  if (placeName) return placeName

  const region = regionFromLocale(reading.language_locale_code)
  if (displayName) return region ? `${region} · ${displayName}` : displayName
  return region ?? reading.language_locale_code
}

export function uniqueReadingLocaleLabels(readings: readonly ExpressionReading[]): string[] {
  return [...new Set(readings.map(readingLocaleLabel))]
}

export function uniqueReadingLocaleCodes(readings: readonly ExpressionReading[]): string[] {
  return [...new Set(readings.map((reading) => reading.language_locale_code))]
}
