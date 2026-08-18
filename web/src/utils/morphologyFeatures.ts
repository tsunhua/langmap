export type MorphologyWordClass = 'noun' | 'verb' | 'adjective'

const LANGUAGE_CLASS_FEATURES: Record<string, Record<MorphologyWordClass, readonly string[]>> = {
  spa: {
    noun: ['masculine', 'feminine', 'singular', 'plural'],
    adjective: ['masculine', 'feminine', 'singular', 'plural', 'comparative', 'superlative'],
    verb: [
      'person-1', 'person-2', 'person-3',
      'singular', 'plural',
      'present', 'past', 'imperfect', 'future',
      'indicative', 'subjunctive', 'imperative', 'conditional',
      'infinitive', 'gerund', 'past-participle',
      'negative', 'positive', 'passive', 'perfect', 'voseo',
    ],
  },
  eng: {
    noun: ['singular', 'plural'],
    adjective: ['comparative', 'superlative'],
    verb: [
      'person-3', 'singular',
      'present', 'past',
      'infinitive', 'gerund', 'past-participle',
      'negative', 'positive', 'progressive', 'perfect',
    ],
  },
  jpn: {
    noun: ['plural'],
    adjective: ['past', 'negative', 'positive', 'polite'],
    verb: [
      'present', 'past', 'imperative',
      'negative', 'positive', 'polite',
      'passive', 'causative',
      'te-form', 'potential', 'volitional', 'desiderative', 'progressive',
      'perfect',
    ],
  },
}

export const WORD_CLASSES: readonly MorphologyWordClass[] = ['noun', 'verb', 'adjective']

export function featureCodesForSelection(
  langCode: string,
  wordClass: MorphologyWordClass | null,
  showAll = false,
): ReadonlySet<string> | null {
  if (showAll) return null
  if (!wordClass) return new Set()
  const byClass = LANGUAGE_CLASS_FEATURES[langCode.trim().toLowerCase()]
  if (!byClass) return new Set()
  return new Set(byClass[wordClass] ?? [])
}

export function hasClassPreset(langCode: string, wordClass: MorphologyWordClass): boolean {
  return Boolean(LANGUAGE_CLASS_FEATURES[langCode.trim().toLowerCase()]?.[wordClass])
}
