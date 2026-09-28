import { beforeEach, describe, expect, it, vi } from 'vitest'
import { defineComponent } from 'vue'
import { flushPromises, mount } from '@vue/test-utils'
import { useTranslationReference } from './useTranslationReference'
import { getExpression, getMappingGraph, type ExpressionDetail } from '@/api/expressions'
import { getLanguageLocale, type LanguageLocale } from '@/api/languageIdentity'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'
import type { TranslationTerm } from '@/utils/translationTerms'

vi.mock('@/api/expressions', () => ({ getExpression: vi.fn(), getMappingGraph: vi.fn() }))
vi.mock('@/api/languageIdentity', () => ({ getLanguageLocale: vi.fn() }))
const term = (text: string, start = 0): TranslationTerm => ({ text, start, end: start + text.length, interactive: true })
const detail = (text: string): ExpressionDetail => ({ expression: { id: text, text, lang_code: 'eng', homograph_index: 1, source_type: null, source_name: null }, locales: [], attestations: [], readings: [] })
const graph: MappingGraphResponse = { root_id: '1', requested_hops: 1, resolved_hops: 1, nodes: [], edges: [], layer_counts: {}, truncated: false, omitted_count: 0 }
function setup() {
  let lookup!: ReturnType<typeof useTranslationReference>
  const wrapper = mount(defineComponent({ setup() { lookup = useTranslationReference(); return () => null } }))
  return { lookup, wrapper }
}
beforeEach(() => {
  vi.clearAllMocks()
  vi.mocked(getLanguageLocale).mockResolvedValue({ lang_code: 'eng' } as LanguageLocale)
  vi.mocked(getExpression).mockImplementation(async target => detail(typeof target === 'object' ? target.text : String(target)))
  vi.mocked(getMappingGraph).mockResolvedValue(graph)
})
describe('useTranslationReference', () => {
  it('uses the current evidence without any lookup or invented source alignment', async () => {
    const { lookup, wrapper } = setup()
    await lookup.select(term('station'), [{ source_text: '車站', target_text: 'station', target_locale_code: 'eng-Latn-US', path_type: 'direct', match_type: 'fuzzy', source_markers: ['source:1'] }], 'eng-Latn-US', 'cmn')
    expect(lookup.reference.value?.evidence[0]?.source_text).toBe('車站')
    expect(getExpression).not.toHaveBeenCalled()
    expect(getLanguageLocale).not.toHaveBeenCalled()
    wrapper.unmount()
  })
  it('deduplicates in-flight occurrences and caches completed natural-key lookups', async () => {
    const { lookup, wrapper } = setup()
    let resolve!: (value: ExpressionDetail) => void
    vi.mocked(getExpression).mockReturnValue(new Promise(done => { resolve = done }))
    const first = lookup.select(term('station'), [], 'eng-Latn-US', 'cmn')
    await flushPromises()
    const second = lookup.select(term('station', 10), [], 'eng-Latn-US', 'cmn')
    await flushPromises()
    expect(getExpression).toHaveBeenCalledTimes(1)
    expect(getMappingGraph).toHaveBeenCalledWith({ lang_code: 'eng', text: 'station' }, 1, undefined, 'cmn', expect.any(AbortSignal))
    resolve(detail('station'))
    await Promise.all([first, second])
    expect(lookup.selected.value?.start).toBe(10)
    lookup.close()
    await lookup.select(term('station'), [], 'eng-Latn-US', 'cmn')
    expect(getExpression).toHaveBeenCalledTimes(1)
    wrapper.unmount()
  })
  it('aborts a stale lookup and ignores its late response after another term is selected', async () => {
    const { lookup, wrapper } = setup()
    let resolve!: (value: ExpressionDetail) => void
    vi.mocked(getExpression).mockReturnValueOnce(new Promise(done => { resolve = done }))
    const old = lookup.select(term('old'), [], 'eng-Latn-US', 'cmn')
    await flushPromises()
    const signal = vi.mocked(getExpression).mock.calls[0][2]
    await lookup.select(term('new'), [], 'eng-Latn-US', 'cmn')
    expect(signal?.aborted).toBe(true)
    resolve(detail('old'))
    await old
    expect(lookup.reference.value?.detail?.expression.text).toBe('new')
    wrapper.unmount()
  })
  it('clears cached results when locale changes and reports a missing expression as empty', async () => {
    const { lookup, wrapper } = setup()
    await lookup.select(term('station'), [], 'eng-Latn-US', 'cmn')
    vi.mocked(getExpression).mockRejectedValueOnce({ response: { status: 404 } })
    await lookup.select(term('station'), [], 'eng-Latn-GB', 'cmn')
    expect(getExpression).toHaveBeenCalledTimes(2)
    expect(lookup.failed.value).toBe(false)
    expect(lookup.reference.value?.detail).toBeNull()
    wrapper.unmount()
  })
})
