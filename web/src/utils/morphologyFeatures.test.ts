import { describe, expect, it } from 'vitest'
import { featureCodesForSelection, hasClassPreset } from './morphologyFeatures'

describe('featureCodesForSelection', () => {
  it('keeps Spanish noun gender and drops verb mood', () => {
    const codes = featureCodesForSelection('spa', 'noun')
    expect(codes?.has('feminine')).toBe(true)
    expect(codes?.has('plural')).toBe(true)
    expect(codes?.has('subjunctive')).toBe(false)
    expect(codes?.has('te-form')).toBe(false)
  })

  it('keeps Japanese verb te-form and drops gender', () => {
    const codes = featureCodesForSelection('jpn', 'verb')
    expect(codes?.has('te-form')).toBe(true)
    expect(codes?.has('feminine')).toBe(false)
  })

  it('hides features until a word class is chosen', () => {
    expect(featureCodesForSelection('spa', null)?.size).toBe(0)
  })

  it('returns an empty set for languages without a preset', () => {
    expect(hasClassPreset('nan', 'noun')).toBe(false)
    expect(featureCodesForSelection('nan', 'noun')?.size).toBe(0)
  })

  it('returns null when showing the full registry', () => {
    expect(featureCodesForSelection('spa', 'noun', true)).toBeNull()
  })
})
