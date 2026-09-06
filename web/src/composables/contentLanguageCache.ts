import { contentRevision } from '@/utils/contentRevision'
import {
  listContentLanguages,
  type ContentLanguage,
  type ContentLanguagePageQuery,
  type Page,
} from '@/api/languageIdentity'

interface ContentLanguageAggregate {
  items: Map<string, ContentLanguage>
  total: number | undefined
  complete: boolean
}

const pageCache = new Map<string, Page<ContentLanguage>>()
const pendingPages = new Map<string, Promise<Page<ContentLanguage>>>()
const aggregateCache = new Map<string, ContentLanguageAggregate>()
const pendingAggregates = new Map<string, Promise<ContentLanguage[]>>()
const MAX_PAGES = 100

function localeKey(query: Pick<ContentLanguagePageQuery, 'ui_locale' | 'secondary_ui_locale'>): string {
  return [
    contentRevision.value,
    query.ui_locale ?? '',
    query.secondary_ui_locale ?? '',
  ].join('|')
}

function pageKey(query: ContentLanguagePageQuery): string {
  return JSON.stringify([
    contentRevision.value,
    query.q ?? '',
    query.sort ?? 'count',
    query.limit ?? 20,
    query.offset ?? 0,
    query.ui_locale ?? '',
    query.secondary_ui_locale ?? '',
  ])
}

function mergePage(query: ContentLanguagePageQuery, page: Page<ContentLanguage>): void {
  if (query.q) return

  const key = localeKey(query)
  const aggregate = aggregateCache.get(key) ?? {
    items: new Map<string, ContentLanguage>(),
    total: undefined,
    complete: false,
  }
  for (const item of page.items) aggregate.items.set(item.code, item)
  aggregate.total = page.total ?? aggregate.total
  aggregate.complete = aggregate.total !== undefined && aggregate.items.size >= aggregate.total
  aggregateCache.set(key, aggregate)
}

export async function loadContentLanguagePage(
  query: ContentLanguagePageQuery = {},
): Promise<Page<ContentLanguage>> {
  const key = pageKey(query)
  const cached = pageCache.get(key)
  if (cached) return cached

  const pending = pendingPages.get(key)
  if (pending) return pending

  const request = listContentLanguages(query)
  pendingPages.set(key, request)
  try {
    const page = await request
    pageCache.set(key, page)
    mergePage(query, page)
    return page
  } finally {
    if (pendingPages.get(key) === request) pendingPages.delete(key)
  }
}

async function fetchAllContentLanguages(
  hints: Pick<ContentLanguagePageQuery, 'ui_locale' | 'secondary_ui_locale'>,
  pageSize: number,
): Promise<ContentLanguage[]> {
  const key = localeKey(hints)
  const aggregate = aggregateCache.get(key)
  if (aggregate?.complete) return [...aggregate.items.values()]

  let offset = 0
  for (let pageNumber = 0; pageNumber < MAX_PAGES; pageNumber += 1) {
    const page = await loadContentLanguagePage({
      ...hints,
      sort: 'alpha',
      limit: pageSize,
      offset,
    })
    const current = aggregateCache.get(key)
    if (current?.complete || page.items.length === 0 || !(page.hasMore ?? page.has_more)) break
    offset += page.items.length
  }

  return [...(aggregateCache.get(key)?.items.values() ?? [])]
}

export async function loadAllContentLanguages(
  hints: Pick<ContentLanguagePageQuery, 'ui_locale' | 'secondary_ui_locale'> = {},
  options: { pageSize?: number } = {},
): Promise<ContentLanguage[]> {
  const key = localeKey(hints)
  const cached = aggregateCache.get(key)
  if (cached?.complete) return [...cached.items.values()]

  const pending = pendingAggregates.get(key)
  if (pending) return pending

  const pageSize = Math.max(1, Math.min(Math.trunc(options.pageSize ?? 100), 100))
  const request = fetchAllContentLanguages(hints, pageSize)
  pendingAggregates.set(key, request)
  try {
    return await request
  } finally {
    if (pendingAggregates.get(key) === request) pendingAggregates.delete(key)
  }
}

export function clearContentLanguageCache(): void {
  pageCache.clear()
  pendingPages.clear()
  aggregateCache.clear()
  pendingAggregates.clear()
}
