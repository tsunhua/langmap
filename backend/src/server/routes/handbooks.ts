import { Hono, Context } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import MarkdownIt from 'markdown-it'
import anchor from 'markdown-it-anchor'
import { success, created, badRequest, forbidden, notFound, internalError } from '../utils/response.js'

const handbookRoutes = new Hono<{ Bindings: Bindings, Variables: { user?: JWTPayload } }>()

// Helper: Generate stable color from language code
function generateLanguageColor(langCode: string): string {
  let hash = 5381
  for (let i = 0; i < langCode.length; i++) {
    hash = ((hash << 5) + hash) + langCode.charCodeAt(i)
    hash = hash >>> 0
  }

  const hue = hash % 360
  const saturation = 60 + (hash % 20)
  const lightness = 45 + (hash % 10)

  const s = saturation / 100
  const l = lightness / 100
  const a = s * Math.min(l, 1 - l)
  const f = (n: number) => {
    const k = (n + hue / 30) % 12
    const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1)
    return Math.round(255 * color)
      .toString(16)
      .padStart(2, '0')
  }
  return `#${f(0)}${f(8)}${f(4)}`
}

// Helper: Get language color with custom color support
function getLanguageColor(langCode: string, handbook: any): string {
  if (handbook.lang_colors) {
    try {
      const colors = JSON.parse(handbook.lang_colors)
      if (colors[langCode]) {
        return colors[langCode]
      }
    } catch (e) {}
  }
  return generateLanguageColor(langCode)
}

// Helper for handbook rendering
async function renderHandbookInternal(c: Context, handbook: any, targetLangs: string[]) {
  console.log('[renderHandbookInternal] START', { handbookId: handbook.id, targetLangs })

  const md = new MarkdownIt({
    html: true,
    breaks: true,
    linkify: false
  }).use(anchor, {
    level: [1, 2, 3],
    slugify: (s) => s
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim(),
    permalink: false
  })
  const db = createDatabaseService(c.env)

  const content = handbook.content || ''
  const title = handbook.title || ''
  const description = handbook.description || ''

  console.log('[renderHandbookInternal] Content preview:', content.substring(0, 100))

  const TEXT_LANG_REGEX = /\{\{(?:text:)?([^\}|}]+)(?:\|([^}]+))?(?:\|([^}]+))?\}\}/g

  let titleToExtract = title
  TEXT_LANG_REGEX.lastIndex = 0
  const hasTags = TEXT_LANG_REGEX.test(title)
  if (!hasTags && handbook.source_lang) {
    titleToExtract = `{{text:${title.replace(/\{/g, '\\{').replace(/\}/g, '\\}')}|lang:${handbook.source_lang}}}`
  }

  const expressionsToFetch: { text: string, lang: string, id: number }[] = []
  const meaningIdsToFetch: Set<number> = new Set()
  const midTags: Map<string, {text: string, mid: number, lang: string}> = new Map()
  const fullText = `${titleToExtract}\n${description}\n${content}`

  console.log('[renderHandbookInternal] Extracting tags from content...')
  TEXT_LANG_REGEX.lastIndex = 0
  let tlMatch
  let tagIndex = 0
  while ((tlMatch = TEXT_LANG_REGEX.exec(fullText)) !== null) {
    const text = tlMatch[1]
    const param1 = tlMatch[2]
    const param2 = tlMatch[3]

    let lang = handbook.source_lang || 'en'
    let mid: number | undefined

    if (param1) {
      if (param1.startsWith('mid:')) {
        mid = parseInt(param1.substring(4))
      } else if (param1.startsWith('lang:')) {
        lang = param1.substring(5)
      }
    }
    if (param2) {
      if (param2.startsWith('mid:')) {
        mid = parseInt(param2.substring(4))
      } else if (param2.startsWith('lang:')) {
        lang = param2.substring(5)
      }
    }

    console.log('[renderHandbookInternal] Tag found:', { text, param1, param2, lang, mid })

    if (mid) {
      const key = `tag_${tagIndex++}`
      midTags.set(key, { text, mid, lang })
      meaningIdsToFetch.add(mid)
    } else {
      try {
        const id = db.stableExpressionId(text, lang)
        if (!expressionsToFetch.some(e => e.id === id)) {
          expressionsToFetch.push({ text, lang, id })
        }
      } catch (err) {
        console.error('[renderHandbookInternal] Error getting stableExpressionId:', err)
      }
    }
  }

  console.log('[renderHandbookInternal] Tags summary:', {
    totalTags: tagIndex,
    meaningIdsToFetch: Array.from(meaningIdsToFetch),
    expressionsToFetch: expressionsToFetch.length
  })

  const expressionMap: Record<string, any> = {}
  const allMids: number[] = []

  console.log('[renderHandbookInternal] Fetching expressions by ID...')
  if (expressionsToFetch.length > 0) {
    try {
      const ids = expressionsToFetch.map(e => e.id)
      console.log('[renderHandbookInternal] Expression IDs to fetch:', ids)
      const expressions = await db.getExpressionsByIds(ids)
      console.log('[renderHandbookInternal] Fetched expressions:', expressions.length)

      const meaningIdsMap = await db.getExpressionMeaningIds(ids)
      console.log('[renderHandbookInternal] Meaning IDs map:', meaningIdsMap)

      expressions.forEach(expr => {
        expressionMap[expr.id] = expr
        const mids = meaningIdsMap.get(expr.id) || []
        expr.meanings = mids.map(mid => ({ id: mid })) as any[]
        mids.forEach(mid => {
          if (!allMids.includes(mid)) allMids.push(mid)
        })
      })
    } catch (err) {
      console.error('[renderHandbookInternal] Error fetching expressions:', err)
      throw err
    }
  }

  console.log('[renderHandbookInternal] Fetching expressions by meaning_id...')
  if (meaningIdsToFetch.size > 0) {
    try {
      const midArray = Array.from(meaningIdsToFetch)
      midArray.forEach(mid => {
        if (!allMids.includes(mid)) allMids.push(mid)
      })

      for (const mid of midArray) {
        console.log('[renderHandbookInternal] Fetching for mid:', mid)
        const midExpressions = await db.getExpressions(0, 1000, undefined, mid, undefined, undefined, true)
        console.log('[renderHandbookInternal] Mid expressions found:', midExpressions.length)

        midExpressions.forEach(expr => {
          if (expr.language_code) {
            const key = `mid_${mid}_${expr.language_code}`
            const filteredExpr = {
              ...expr,
              meanings: expr.meanings?.filter((m: any) => m.id === mid) || [{ id: mid }]
            }
            expressionMap[key] = filteredExpr
            expressionMap[expr.id] = filteredExpr
          }
        })
      }
    } catch (err) {
      console.error('[renderHandbookInternal] Error fetching mid expressions:', err)
      throw err
    }
  }

  console.log('[renderHandbookInternal] ExpressionMap keys:', Object.keys(expressionMap))
  console.log('[renderHandbookInternal] All MIDs:', allMids)

  const translationsByLang: Record<string, any[]> = {}

  console.log('[renderHandbookInternal] Fetching translations for target languages:', targetLangs)
  if (allMids.length > 0) {
    for (const targetLang of targetLangs) {
      if (!targetLang) continue

      console.log('[renderHandbookInternal] Fetching translations for lang:', targetLang, 'mids:', allMids)
      try {
        const translations: any[] = await db.getExpressions(0, 1000, [targetLang], allMids, undefined, undefined, true)
        translationsByLang[targetLang] = translations
        console.log('[renderHandbookInternal] Translations found for', targetLang, ':', translations.length)
      } catch (err) {
        console.error('[renderHandbookInternal] Error fetching translations for', targetLang, ':', err)
        throw err
      }
    }
  }

  console.log('[renderHandbookInternal] Processing translations...')
  Object.entries(translationsByLang).forEach(([langCode, translations]) => {
    const transByMeaning: Record<number, {text: string, audio_url: string}> = {}

    translations.forEach((trans: any) => {
      if (trans.meanings && trans.meanings.length > 0) {
        trans.meanings.forEach((m: any) => {
          if (allMids.includes(m.id)) {
            const mid = m.id
            if (!transByMeaning[mid]) {
              transByMeaning[mid] = { text: '', audio_url: trans.audio_url || '' }
            }
            transByMeaning[mid].text = transByMeaning[mid].text
                ? `${transByMeaning[mid].text} | ${trans.text}`
                : trans.text
          }
        })
      } else if (trans.meaning_id) {
        const mid = trans.meaning_id
        if (!transByMeaning[mid]) {
          transByMeaning[mid] = { text: '', audio_url: trans.audio_url || '' }
        }
        transByMeaning[mid].text = transByMeaning[mid].text
            ? `${transByMeaning[mid].text} | ${trans.text}`
            : trans.text
      }
    })

    Object.entries(transByMeaning).forEach(([mid, merged]) => {
      const key = `trans_${mid}_${langCode}`
      expressionMap[key] = {
        text: merged.text,
        audio_url: merged.audio_url
      }
      console.log('[renderHandbookInternal] Translation stored:', key, merged.text)
    })
  })

  const renderItem = (id: number, text: string, audioUrl: string, isTitle: boolean, meaningId?: number) => {
    console.log('[renderItem] START', { id, text, isTitle, meaningId, targetLangs })

    const translationsByTargetLang: Record<string, string[]> = {}

    const meaningsToUse = meaningId ? [{ id: meaningId }] : (expressionMap[id]?.meanings || [])
    console.log('[renderItem] Meanings to use:', meaningsToUse)

    targetLangs.forEach(targetLang => {
      if (!targetLang) return

      const transList: string[] = []

      meaningsToUse.forEach((m: any) => {
        const transKey = `trans_${m.id}_${targetLang}`
        console.log('[renderItem] Looking for transKey:', transKey, 'found:', !!expressionMap[transKey])
        if (expressionMap[transKey]) {
          transList.push(expressionMap[transKey].text)
        }
      })

      if (transList.length > 0) {
        translationsByTargetLang[targetLang] = transList
        console.log('[renderItem] Translations for', targetLang, ':', transList)
      }
    })

    const hasTranslations = Object.keys(translationsByTargetLang).length > 0
    console.log('[renderItem] Has translations:', hasTranslations, 'data:', translationsByTargetLang)

    let meaningsHtml = ''
    if (hasTranslations) {
      if (isTitle) {
        meaningsHtml = ` <span class="handbook-meaning-title">
          ${Object.entries(translationsByTargetLang).map(([langCode, texts]) => {
            const color = getLanguageColor(langCode, handbook)
            const langClass = langCode.replace('.', '-')
            return `<span class="lang-${langClass}" style="color: ${color}">${texts.join(' / ')}</span>`
          }).join(' ')}
        </span>`
      } else {
        meaningsHtml = ` <span class="handbook-meaning-content">
          ${Object.entries(translationsByTargetLang).map(([langCode, texts]) => {
            const color = getLanguageColor(langCode, handbook)
            const langClass = langCode.replace('.', '-')
            return `<span class="lang-${langClass}" style="color: ${color}">${texts.join(', ')}</span>`
          }).join(' ')}
        </span>`
      }
    }

    const audioIcon = audioUrl ? ` <span class="handbook-audio-icon">🔊</span>` : ''
    const audioHandler = audioUrl ? `window.playHandbookAudio('${audioUrl}')` : ''

    const meaningIdValue = meaningId !== undefined ? meaningId : 'null'

    const result = isTitle
      ? `<span class="handbook-item" data-type="title" data-expression-id="${id}" data-meaning-id="${meaningId || ''}" onclick="event.stopPropagation(); window.dispatchEvent(new CustomEvent('handbook-expression-click', { detail: { id: ${id}, meaningId: ${meaningIdValue} } })); ${audioHandler}">${text}${meaningsHtml}${audioIcon}</span>`
      : `<span class="handbook-item" data-type="content" data-expression-id="${id}" data-meaning-id="${meaningId || ''}" onclick="event.stopPropagation(); window.dispatchEvent(new CustomEvent('handbook-expression-click', { detail: { id: ${id}, meaningId: ${meaningIdValue} } })); ${audioHandler}">${text}${meaningsHtml}${audioIcon}</span>`

    console.log('[renderItem] Result length:', result.length)
    return result
  }

  const renderTextWithTags = (text: string, isTitle: boolean) => {
    console.log('[renderTextWithTags] START', { isTitle, textLength: text?.length })
    if (!text) return ''
    const textToRender = text

    let matchCount = 0
    TEXT_LANG_REGEX.lastIndex = 0
    const result = textToRender.replace(TEXT_LANG_REGEX, (match, term, param1, param2) => {
      matchCount++
      console.log('[renderTextWithTags] Match', matchCount, ':', match, { term, param1, param2 })

      let lang = handbook.source_lang || 'en'
      let mid: number | undefined

      if (param1) {
        if (param1.startsWith('mid:')) {
          mid = parseInt(param1.substring(4))
        } else if (param1.startsWith('lang:')) {
          lang = param1.substring(5)
        }
      }
      if (param2) {
        if (param2.startsWith('mid:')) {
          mid = parseInt(param2.substring(4))
        } else if (param2.startsWith('lang:')) {
          lang = param2.substring(5)
        }
      }

      console.log('[renderTextWithTags] Parsed:', { lang, mid })

      if (mid) {
        const key = `mid_${mid}_${lang}`
        const expr = expressionMap[key]
        console.log('[renderTextWithTags] Looking for mid key:', key, 'found:', !!expr)

        if (expr) {
          let audioUrl = ''
          if (expr.audio_url) {
            try {
              const parsed = JSON.parse(expr.audio_url)
              audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
            } catch { }
          }

          return renderItem(expr.id, term, audioUrl, isTitle, mid)
        }

        console.log('[renderTextWithTags] Expression not found for mid:', mid)
        return `<span class="handbook-item-undefined">${term}</span>`
      }

      try {
        const id = db.stableExpressionId(term, lang)
        const expr = expressionMap[id]
        console.log('[renderTextWithTags] Looking for id:', id, 'found:', !!expr)

        if (expr) {
          let audioUrl = ''
          if (expr.audio_url) {
            try {
              const parsed = JSON.parse(expr.audio_url)
              audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
            } catch { }
          }

          const meaningId = expr.meanings?.[0]?.id
          return renderItem(id, term, audioUrl, isTitle, meaningId)
        }

        console.log('[renderTextWithTags] Expression not found for id:', id)
        return `<span class="handbook-item-undefined">${term}</span>`
      } catch (err) {
        console.error('[renderTextWithTags] Error in renderTextWithTags:', err)
        return `<span class="handbook-item-undefined">${term}</span>`
      }
    })

    console.log('[renderTextWithTags] Total matches:', matchCount, 'result length:', result.length)
    return result
  }

  console.log('[renderHandbookInternal] Rendering title...')
  let rendered_title = renderTextWithTags(titleToExtract, true)
  console.log('[renderHandbookInternal] Rendered title length:', rendered_title.length)
  if (!rendered_title.includes('handbook-meaning-title')) {
    console.log('[renderHandbookInternal] Title has no translations, using empty string')
    rendered_title = ''
  }

  console.log('[renderHandbookInternal] Rendering description...')
  const rendered_description = renderTextWithTags(description, false)
  console.log('[renderHandbookInternal] Rendered description length:', rendered_description.length)

  console.log('[renderHandbookInternal] Creating placeholders for content...')
  const htmlPlaceholders: Record<string, string> = {}

  TEXT_LANG_REGEX.lastIndex = 0
  const contentWithPlaceholders = content.replace(TEXT_LANG_REGEX, (match: string) => {
    const index = Object.keys(htmlPlaceholders).length
    const placeholder = `HANDBOOK_ITEM_${index}`
    htmlPlaceholders[placeholder] = match
    return placeholder
  })
  console.log('[renderHandbookInternal] Placeholders created:', Object.keys(htmlPlaceholders).length)

  console.log('[renderHandbookInternal] Rendering markdown...')
  const renderedMarkdown = md.render(contentWithPlaceholders)
  console.log('[renderHandbookInternal] Markdown rendered, length:', renderedMarkdown.length)

  console.log('[renderHandbookInternal] Substituting placeholders...')
  const finalContent = renderedMarkdown.replace(/HANDBOOK_ITEM_\d+/g, (match) => {
    const originalTag = htmlPlaceholders[match]
    if (originalTag) {
      console.log('[renderHandbookInternal] Substituting placeholder:', match)
      TEXT_LANG_REGEX.lastIndex = 0
      return originalTag.replace(TEXT_LANG_REGEX, (m, term, param1, param2) => {
        let lang = handbook.source_lang || 'en'
        let mid: number | undefined

        if (param1) {
          if (param1.startsWith('mid:')) {
            mid = parseInt(param1.substring(4))
          } else if (param1.startsWith('lang:')) {
            lang = param1.substring(5)
          }
        }
        if (param2) {
          if (param2.startsWith('mid:')) {
            mid = parseInt(param2.substring(4))
          } else if (param2.startsWith('lang:')) {
            lang = param2.substring(5)
          }
        }

        if (mid) {
          const key = `mid_${mid}_${lang}`
          const expr = expressionMap[key]
          console.log('[renderHandbookInternal] Placeholder substitution - mid key:', key, 'found:', !!expr)

          if (expr) {
            let audioUrl = ''
            if (expr.audio_url) {
              try {
                const parsed = JSON.parse(expr.audio_url)
                audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
              } catch { }
            }

            return renderItem(expr.id, term, audioUrl, false, mid)
          }

          console.log('[renderHandbookInternal] Expression not found for mid:', mid)
          return `<span class="handbook-item-undefined">${term}</span>`
        }

        try {
          const id = db.stableExpressionId(term, lang)
          const expr = expressionMap[id]
          console.log('[renderHandbookInternal] Placeholder substitution - id:', id, 'found:', !!expr)

          if (expr) {
            let audioUrl = ''
            if (expr.audio_url) {
              try {
                const parsed = JSON.parse(expr.audio_url)
                audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
              } catch { }
            }

            const meaningId = expr.meanings?.[0]?.id
            return renderItem(id, term, audioUrl, false, meaningId)
          }

          console.log('[renderHandbookInternal] Expression not found for id:', id)
          return `<span class="handbook-item-undefined">${term}</span>`
        } catch (err) {
          console.error('[renderHandbookInternal] Error in placeholder substitution:', err)
          return `<span class="handbook-item-undefined">${term}</span>`
        }
      })
    }
    console.log('[renderHandbookInternal] No original tag found for placeholder:', match)
    return match
  })

  console.log('[renderHandbookInternal] COMPLETE', {
    titleLength: rendered_title.length,
    descriptionLength: rendered_description.length,
    contentLength: finalContent.length
  })
  return { rendered_title, rendered_description, rendered_content: finalContent }
}

handbookRoutes.get('/', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const isPublicParam = c.req.query('is_public')
    const isPublic = isPublicParam !== undefined ? isPublicParam === '1' : undefined
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    let userId: number | undefined
    if (isPublic) {
      userId = undefined
    } else if (user) {
      userId = user.id
    }

    const handbooks = await db.getHandbooks(userId, isPublic, skip, limit)
    return success(c, handbooks)
  } catch (error: any) {
    console.error('Error in GET /handbooks:', error)
    return internalError(c, 'Failed to fetch handbooks')
  }
})

// GET /:id/:target_lang? - Get handbook with optional rendering
handbookRoutes.get('/:id/:target_lang?', optionalAuth, async (c) => {
  console.log('[GET /:id/:target_lang?] START')
  try {
    const db = createDatabaseService(c.env)
    const id = parseInt(c.req.param('id'))
    const user = c.get('user')

    console.log('[GET] Params:', { id, user: user?.id, queryTargetLang: c.req.query('target_lang'), queryTargetLangs: c.req.query('target_langs'), paramTargetLang: c.req.param('target_lang') })

    const targetLangsParam = c.req.query('target_langs') || c.req.query('target_lang') || c.req.param('target_lang')
    let targetLangs: string[] = []

    if (targetLangsParam) {
      targetLangs = targetLangsParam.split(',').map(l => l.trim()).filter(Boolean)
    }

    console.log('[GET] Parsed targetLangs:', targetLangs)

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    console.log('[GET] Fetching handbook...')
    const handbook = await db.getHandbookById(id)
    if (!handbook) return notFound(c, 'Handbook')

    console.log('[GET] Handbook fetched:', { id: handbook.id, title: handbook.title, target_lang: handbook.target_lang, source_lang: handbook.source_lang })

    if (targetLangs.length === 0) {
      if (handbook.target_lang) {
        targetLangs = [handbook.target_lang]
        console.log('[GET] Using handbook target_lang:', handbook.target_lang)
      }
    }

    if (!handbook.is_public && (!user || user.id !== handbook.user_id)) {
      console.log('[GET] Access denied')
      return forbidden(c, 'Access denied')
    }

    if (targetLangs.length > 0) {
      const cacheKey = [...targetLangs].sort().join('|')
      console.log('[GET] Checking cache for key:', cacheKey)

      try {
        const cachedRender = await db.getHandbookRender(id, cacheKey)
        if (cachedRender) {
          console.log('[GET] Cache hit!')
          const result = success(c, {
            ...handbook,
            rendered_title: cachedRender.rendered_title,
            rendered_description: cachedRender.rendered_description,
            rendered_content: cachedRender.rendered_content,
            is_cached: true
          })
          result.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0')
          return result
        }
        console.log('[GET] Cache miss, rendering...')
      } catch (cacheErr) {
        console.error('[GET] Error checking cache:', cacheErr)
      }

      try {
        console.log('[GET] Calling renderHandbookInternal...')
        const renders = await renderHandbookInternal(c, handbook, targetLangs)
        console.log('[GET] Renders received:', Object.keys(renders))

        await db.saveHandbookRender({
          handbook_id: id,
          target_lang: cacheKey,
          ...renders
        })
        console.log('[GET] Saved to cache')

        return c.json({
          success: true,
          data: {
            ...handbook,
            ...renders,
            is_cached: false
          }
        }, {
          headers: {
            'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'
          }
        })
      } catch (renderError) {
        console.error('[GET] Render error:', renderError)
        console.error('[GET] Render error stack:', renderError instanceof Error ? renderError.stack : 'No stack')
        return c.json({
          success: true,
          data: handbook
        }, {
          headers: {
            'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'
          }
        })
      }
    }

    console.log('[GET] No target langs, returning handbook as-is')
    return c.json({
      success: true,
      data: handbook
    }, {
      headers: {
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0'
      }
    })
  } catch (error: any) {
    console.error('[GET] Error in GET /handbooks/:id:', error)
    console.error('[GET] Error stack:', error instanceof Error ? error.stack : 'No stack')
    return internalError(c, 'Failed to fetch handbook')
  }
})

// POST /preview - Preview handbook rendering
handbookRoutes.post('/preview', requireAuth, async (c) => {
  console.log('[POST /preview] START')
  try {
    const db = createDatabaseService(c.env)
    const body = await c.req.json()

    console.log('[POST /preview] Body:', body)

    if (!body.content) {
      return badRequest(c, 'Content is required')
    }

    const tempHandbook = {
      id: 0,
      title: body.title || '',
      description: body.description || '',
      content: body.content,
      source_lang: body.source_lang || 'en',
      target_lang: body.target_lang || ''
    }

    const targetLangs = body.target_lang ? [body.target_lang] : []
    console.log('[POST /preview] Target langs:', targetLangs)

    const renders = await renderHandbookInternal(c, tempHandbook, targetLangs)
    console.log('[POST /preview] Renders:', Object.keys(renders))

    return success(c, {
      ...tempHandbook,
      ...renders
    })
  } catch (error: any) {
    console.error('[POST /preview] Error:', error)
    console.error('[POST /preview] Error stack:', error instanceof Error ? error.stack : 'No stack')
    return internalError(c, 'Failed to preview handbook')
  }
})

handbookRoutes.post('/', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const body = await c.req.json()

    if (!body.title || !body.content) {
      return badRequest(c, 'Title and content are required')
    }

    const sourceLang = body.source_lang || ''
    const fullText = `${body.title}\n${body.description || ''}\n${body.content}`
    const expressions: Array<{ text: string, language_code: string }> = []
    const regex = /\{\{(?:text:)?([^\}|}]+)(?:\|lang:([^\}|]+))?\}\}/g
    let match
    while ((match = regex.exec(fullText)) !== null) {
      const text = match[1]
      const lang = match[2] || sourceLang
      if (text && lang && !expressions.some(e => e.text === text && e.language_code === lang)) {
        expressions.push({ text, language_code: lang })
      }
    }

    if (expressions.length > 0) {
      await db.ensureExpressionsExist(expressions, user.username)
    }

    const handbook = await db.createHandbook({
      ...body,
      user_id: user.id
    })

    return created(c, handbook)
  } catch (error: any) {
    console.error('Error in POST /handbooks:', error)
    return internalError(c, 'Failed to create handbook')
  }
})

handbookRoutes.put('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const existing = await db.getHandbookById(id)
    if (!existing) return notFound(c, 'Handbook')

    if (existing.user_id !== user.id) {
      return forbidden(c, 'Access denied')
    }

    const sourceLang = body.source_lang || ''
    const fullText = `${body.title || ''}\n${body.description || ''}\n${body.content || ''}`
    const expressions: Array<{ text: string, language_code: string }> = []
    const regex = /\{\{(?:text:)?([^\}|}]+)(?:\|lang:([^\}|]+))?\}\}/g
    let match
    while ((match = regex.exec(fullText)) !== null) {
      const text = match[1]
      const lang = match[2] || sourceLang
      if (text && lang && !expressions.some(e => e.text === text && e.language_code === lang)) {
        expressions.push({ text, language_code: lang })
      }
    }

    if (expressions.length > 0) {
      await db.ensureExpressionsExist(expressions, user.username)
    }

    await db.invalidateHandbookRenders(id)

    const updated = await db.updateHandbook(id, body)
    return success(c, updated)
  } catch (error: any) {
    console.error('Error in PUT /handbooks/:id:', error)
    return internalError(c, 'Failed to update handbook')
  }
})

handbookRoutes.post('/:id/rerender', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const handbook = await db.getHandbookById(id)
    if (!handbook) return notFound(c, 'Handbook')

    if (handbook.user_id !== user.id && user.role !== 'admin') {
      return forbidden(c, 'Access denied')
    }

    await db.invalidateHandbookRenders(id)

    return success(c, null, 'Handbook render cache cleared successfully')
  } catch (error: any) {
    console.error('Error in POST /handbooks/:id/rerender:', error)
    return internalError(c, 'Failed to rerender handbook')
  }
})

handbookRoutes.delete('/:id', requireAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const id = parseInt(c.req.param('id'))

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    const existing = await db.getHandbookById(id)
    if (!existing) return notFound(c, 'Handbook')

    if (existing.user_id !== user.id && user.role !== 'admin') {
      return forbidden(c, 'Access denied')
    }

    const success = await db.deleteHandbook(id)
    return success(c, { success }, 'Handbook deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /handbooks/:id:', error)
    return internalError(c, 'Failed to delete handbook')
  }
})

export default handbookRoutes
