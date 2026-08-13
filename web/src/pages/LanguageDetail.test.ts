import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { i18n } from '@/locales'
import type { LanguageExpressionSummary, Page } from '@/api/languageIdentity'
import LanguageDetail from './LanguageDetail.vue'

const { detail, expressions, replace } = vi.hoisted(() => ({
  detail: vi.fn(),
  expressions: vi.fn(),
  replace: vi.fn(),
}))
const route = reactive({ params: { code: 'cmn' }, query: { locale: 'cmn-Hant-TW' as string | undefined, script: undefined as string | undefined } })

vi.mock('@/composables/useLanguages', () => ({ useLanguages: () => ({ detail, expressions }) }))
vi.mock('vue-router', () => ({
  useRoute: () => route,
  useRouter: () => ({ replace }),
}))

const page: Page<LanguageExpressionSummary> = { items: [], total: 0, skip: 0, limit: 20, hasMore: false }

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((done) => { resolve = done })
  return { promise, resolve }
}

describe('LanguageDetail', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    route.params.code = 'cmn'
    route.query.locale = 'cmn-Hant-TW'
    route.query.script = undefined
    detail.mockResolvedValue({
      code: 'cmn', name: 'Mandarin Chinese', name_en: 'Mandarin Chinese', expression_count: 2,
      locale_count: 2, active_ui_locale_count: 0, reading_count: 0, mapped_expression_count: 0,
      locales: [
        { code: 'cmn-Hans-CN', name: '普通话(CN)', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', latitude: null, longitude: null },
        { code: 'cmn-Hant-TW', name: '華語(TW)', name_en: 'Taiwan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: '', latitude: null, longitude: null },
      ],
    })
    expressions.mockResolvedValue(page)
  })

  it('uses locale forms as controls and forwards the selected locale and sort to expression paging', async () => {
    const wrapper = mount(LanguageDetail, { global: { plugins: [i18n] } })
    await flushPromises()

    expect(expressions).toHaveBeenCalledWith('cmn', {
      q: '', locale: 'cmn-Hant-TW', sort: 'hot', limit: 20, offset: 0,
    })
    const localeButtons = wrapper.findAll('.ld-locales button').map((button) => button.text())
    expect(localeButtons).toContain('Allcmn')
    expect(localeButtons).toContain('普通话(CN)cmn-Hans-CN')
    expect(localeButtons).toContain('華語(TW)cmn-Hant-TW')
    expect(wrapper.find('h1').text()).toBe('華語(TW)')
    expect(wrapper.text()).toContain('cmn-Hans-CN')
    expect(wrapper.text()).toContain('cmn-Hant-TW')

    const latest = wrapper.findAll('button').find((button) => button.text() === 'Latest')
    expect(latest).toBeDefined()
    await latest!.trigger('click')
    await flushPromises()
    expect(expressions).toHaveBeenLastCalledWith('cmn', {
      q: '', locale: 'cmn-Hant-TW', sort: 'new', limit: 20, offset: 0,
    })
  })

  it('keeps the newest locale page when an older request completes later', async () => {
    const hant = deferred<Page<LanguageExpressionSummary>>()
    expressions.mockImplementation((_code: string, query: { locale: string }) => query.locale === 'cmn-Hant-TW'
      ? hant.promise
      : Promise.resolve({
        ...page,
        items: [{ id: 'cmn:new', lang_code: 'cmn', text: '最新腳本', description: '', homograph_index: 1, review_status: 'approved', created_at: '', reading_count: 0, mapping_count: 0 }],
        total: 1,
      }))

    const wrapper = mount(LanguageDetail, { global: { plugins: [i18n], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } } })
    await flushPromises()
    route.query.locale = 'cmn-Hans-CN'
    await flushPromises()
    expect(wrapper.text()).toContain('最新腳本')

    hant.resolve({
      ...page,
      items: [{ id: 'cmn:old', lang_code: 'cmn', text: '過時腳本', description: '', homograph_index: 1, review_status: 'approved', created_at: '', reading_count: 0, mapping_count: 0 }],
      total: 1,
    })
    await flushPromises()
    expect(wrapper.text()).toContain('最新腳本')
    expect(wrapper.text()).not.toContain('過時腳本')
  })

  it('clears an unknown locale query and falls back to all forms', async () => {
    route.query.locale = 'cmn-Zzzz-XX'
    mount(LanguageDetail, { global: { plugins: [i18n], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } } })
    await flushPromises()

    expect(replace).toHaveBeenCalledWith({ query: {} })
    expect(expressions).toHaveBeenCalledWith('cmn', {
      q: '', locale: '', sort: 'hot', limit: 20, offset: 0,
    })
  })
})
