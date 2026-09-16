import { describe, expect, it, beforeEach } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { useContributePrefillStore, type ContributePrefill } from './contributePrefill'

const value: ContributePrefill = {
  sourceLangCode: 'yue',
  sourceLocaleCode: 'yue-Hant-CN-x-hegusan',
  sourceText: 'hello',
  targetLangCode: 'cmn',
  targetLocaleCode: 'cmn-Hans',
  targetText: '你好',
  aiAssisted: true,
}

describe('contributePrefill store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('stores a pair and consumes it exactly once', () => {
    const store = useContributePrefillStore()
    store.set(value)
    expect(store.prefill).toEqual(value)
    expect(store.consume()).toEqual(value)
    expect(store.prefill).toBeNull()
    expect(store.consume()).toBeNull()
  })
})
