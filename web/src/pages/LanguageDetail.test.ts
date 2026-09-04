import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { createPinia } from 'pinia'
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

function mountDetail() {
  return mount(LanguageDetail, {
    global: { plugins: [createPinia(), i18n], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
  })
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
        { code: 'cmn-Hans-CN', name: '普通话', name_en: 'Simplified Chinese', display_name: '简体中文', script_code: 'Hans', region_code: 'CN', place_path: '', latitude: null, longitude: null },
        { code: 'cmn-Hant-TW', name: '華語', name_en: 'Taiwan Mandarin', display_name: '台灣華語', script_code: 'Hant', region_code: 'TW', place_path: '', latitude: null, longitude: null },
        { code: 'cmn-Hant-HK', name: '廣東話', name_en: 'Hong Kong Mandarin', display_name: '香港華語', script_code: 'Hant', region_code: 'HK', place_path: '', latitude: null, longitude: null },
      ],
    })
    expressions.mockResolvedValue(page)
  })

  it('syncs the linked selects from the deep-linked locale and forwards it to expression paging', async () => {
    const wrapper = mountDetail()
    await flushPromises()

    expect(expressions).toHaveBeenCalledWith('cmn', {
      q: '', locale: 'cmn-Hant-TW', sort: 'new', limit: 20, offset: 0, ui_locale: 'eng-Latn-US',
    })
    expect(wrapper.find('.ld-sort').exists()).toBe(false)
    expect(detail).toHaveBeenCalledWith('cmn', { ui_locale: 'eng-Latn-US' }, 'cmn-Hant-TW')
    const selects = wrapper.findAll('.ld-select')
    expect(selects).toHaveLength(2)
    expect((selects[0].element as HTMLSelectElement).value).toBe('Hant')
    expect((selects[1].element as HTMLSelectElement).value).toBe('TW')
    expect(wrapper.find('h1').text()).toBe('台灣華語')
    expect(wrapper.find('.ld-sub').text()).toBe('華語')
    expect(wrapper.find('.lang-badge').text()).toBe('cmn-Hant-TW')
  })

  it('shows only the newest 20 expressions without sorting or load-more controls', async () => {
    expressions.mockResolvedValue({
      ...page,
      items: Array.from({ length: 20 }, (_, index) => ({
        id: `cmn:${index}`,
        lang_code: 'cmn',
        text: `詞語${index}`,
        description: '',
        homograph_index: 1,
        created_at: '',
        reading_count: 0,
        mapping_count: 0,
      })),
      total: 21,
    })
    const wrapper = mountDetail()
    await flushPromises()

    expect(wrapper.findAll('.ex-row')).toHaveLength(20)
    expect(wrapper.find('.ld-sort').exists()).toBe(false)
    expect(wrapper.find('.pag').exists()).toBe(false)
  })

  it('picking a single-region variant hides the region select and auto-selects it', async () => {
    const wrapper = mountDetail()
    await flushPromises()

    const variant = wrapper.findAll('.ld-select')[0]
    await variant.setValue('Hans')
    await flushPromises()

    expect(replace).toHaveBeenCalledWith({ query: { locale: 'cmn-Hans-CN' } })
    // Hans has a single region, so the region select is hidden after narrowing
    expect(wrapper.findAll('.ld-select')).toHaveLength(1)

    route.query.locale = 'cmn-Hans-CN'
    await flushPromises()
    expect(wrapper.find('h1').text()).toBe('简体中文')
    expect(wrapper.find('.ld-sub').text()).toBe('普通话')
  })

  it('refetches locale-aware detail and shows filtered counts when locale changes', async () => {
    route.query.locale = undefined
    detail.mockImplementation((_code: string, _hints: unknown, locale?: string) => Promise.resolve({
      code: 'cmn', name: 'Mandarin Chinese', name_en: 'Mandarin Chinese',
      expression_count: locale === 'cmn-Hans-CN' ? 2 : 19,
      locale_count: 2, active_ui_locale_count: 0, reading_count: 0,
      mapped_expression_count: locale === 'cmn-Hans-CN' ? 1 : 7,
      locales: [
        { code: 'cmn-Hans-CN', name: '普通话', name_en: 'Simplified Chinese', display_name: '简体中文', script_code: 'Hans', region_code: 'CN', place_path: '', latitude: null, longitude: null },
        { code: 'cmn-Hant-TW', name: '華語', name_en: 'Taiwan Mandarin', display_name: '台灣華語', script_code: 'Hant', region_code: 'TW', place_path: '', latitude: null, longitude: null },
      ],
    }))
    const wrapper = mountDetail()
    await flushPromises()
    expect(wrapper.find('.ld-stats').text()).toContain('19')

    route.query.locale = 'cmn-Hans-CN'
    await flushPromises()
    expect(wrapper.find('.ld-stats').text()).toContain('2')
    expect(wrapper.find('.ld-stats').text()).not.toContain('19')
  })

  it('falls back to the bare language when no locale is selected', async () => {
    route.query.locale = undefined
    const wrapper = mountDetail()
    await flushPromises()

    expect(detail).toHaveBeenCalledWith('cmn', { ui_locale: 'eng-Latn-US' }, '')
    expect(wrapper.find('h1').text()).toBe('Mandarin Chinese')
    expect(wrapper.find('.ld-sub').exists()).toBe(false)
    expect(wrapper.find('.lang-badge').text()).toBe('cmn')
    const selects = wrapper.findAll('.ld-select')
    expect((selects[0].element as HTMLSelectElement).value).toBe('')
    expect((selects[1].element as HTMLSelectElement).value).toBe('')
  })

  it('hides the variant select when the language has a single script', async () => {
    route.params.code = 'nan'
    detail.mockResolvedValue({
      code: 'nan', name: 'Min Nan Chinese', name_en: 'Min Nan Chinese', expression_count: 0,
      locale_count: 2, active_ui_locale_count: 0, reading_count: 0, mapped_expression_count: 0,
      locales: [
        { code: 'nan-Hant-CN', name: '閩南語', name_en: 'Min Nan Chinese (China)', script_code: 'Hant', region_code: 'CN', place_path: '', latitude: null, longitude: null },
        { code: 'nan-Hant-TW', name: '閩南語', name_en: 'Min Nan Chinese (Taiwan)', script_code: 'Hant', region_code: 'TW', place_path: '', latitude: null, longitude: null },
      ],
    })
    const wrapper = mountDetail()
    await flushPromises()

    const selects = wrapper.findAll('.ld-select')
    expect(selects).toHaveLength(1)
    const options = wrapper.findAll('#locale-other option').map((option) => option.text())
    expect(options).toEqual(['All', '閩南語 (CN)', '閩南語 (TW)'])
  })

  it('hides all locale selects when the language has a single script and region', async () => {
    route.params.code = 'eng'
    route.query.locale = undefined
    detail.mockResolvedValue({
      code: 'eng', name: 'English', name_en: 'English', expression_count: 1,
      locale_count: 1, active_ui_locale_count: 0, reading_count: 0, mapped_expression_count: 0,
      locales: [
        { code: 'eng-Latn-US', name: 'English', name_en: 'English (US)', display_name: 'English (US)', script_code: 'Latn', region_code: 'US', place_path: '', latitude: null, longitude: null },
      ],
    })
    const wrapper = mountDetail()
    await flushPromises()

    expect(wrapper.findAll('.ld-select')).toHaveLength(0)
    expect(wrapper.find('.ld-locales').exists()).toBe(false)
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

    const wrapper = mountDetail()
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
    const wrapper = mountDetail()
    await flushPromises()

    expect(replace).toHaveBeenCalledWith({ query: {} })
    expect(expressions).toHaveBeenCalledWith('cmn', {
      q: '', locale: '', sort: 'new', limit: 20, offset: 0, ui_locale: 'eng-Latn-US',
    })
    const selects = wrapper.findAll('.ld-select')
    expect((selects[0].element as HTMLSelectElement).value).toBe('')
    expect((selects[1].element as HTMLSelectElement).value).toBe('')
  })
})
