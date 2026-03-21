import { Hono, Context } from 'hono'
import { createDatabaseService } from '../db/index.js'
import type { Bindings, JWTPayload } from '../types/bindings.js'
import { requireAuth, optionalAuth } from '../middleware/auth.js'
import { clearCache } from '../middleware/cache.js'
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

// Helper: Precompute language colors for efficiency
function precomputeLanguageColors(langs: string[], handbook: any): Record<string, string> {
  const colors: Record<string, string> = {}
  for (const lang of langs) {
    if (lang) {
      colors[lang] = getLanguageColor(lang, handbook)
    }
  }
  return colors
}

// Helper for handbook rendering
async function renderHandbookInternal(c: Context, handbook: any, targetLangs: string[]) {
  console.log('[renderHandbookInternal] START', {
    handbookId: handbook.id,
    handbookTitle: handbook.title,
    handbookSourceLang: handbook.source_lang,
    handbookTargetLang: handbook.target_lang,
    targetLangs: targetLangs,
    contentLength: handbook.content?.length
  })

  const langColors = precomputeLanguageColors(targetLangs, handbook)

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

  const TEXT_LANG_REGEX = /\{\{(?:text:)?([^\}|}]+)(?:\|([^}]+))?(?:\|([^}]+))?\}\}/g

  let titleToExtract = title
  TEXT_LANG_REGEX.lastIndex = 0
  const hasTags = TEXT_LANG_REGEX.test(title)
  if (!hasTags && handbook.source_lang) {
    titleToExtract = `{{text:${title.replace(/\{/g, '\\{').replace(/\}/g, '\\}')}|lang:${handbook.source_lang}}}`
  }

  const expressionsToFetch: { text: string, lang: string, id: number }[] = []
  const midTags: Map<string, {text: string, mid: number, lang: string, expressionId: number}> = new Map()
  const expressionIdCache: Map<string, number> = new Map()
  const fullText = `${titleToExtract}\n${description}\n${content}`

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

    try {
      const cacheKey = `${text}|${lang}`
      let id = expressionIdCache.get(cacheKey)
      if (id === undefined) {
        id = db.stableExpressionId(text, lang)
        expressionIdCache.set(cacheKey, id)
      }
      if (!expressionsToFetch.some(e => e.id === id)) {
        expressionsToFetch.push({ text, lang, id })
      }
      if (mid) {
        const key = `tag_${tagIndex++}`
        midTags.set(key, { text, mid, lang, expressionId: id })
      }
    } catch (err) {
      console.error('[renderHandbookInternal] Error getting stableExpressionId:', err)
    }
  }

  const expressionMap: Record<string, any> = {}

  const allExpressionIds = [...new Set([...expressionsToFetch.map(e => e.id)])]
  let expressionGroupsMap: Map<number, any[]>
  try {
    expressionGroupsMap = await db.getExpressionsGroups(allExpressionIds, targetLangs)
  } catch (err) {
    console.error('[renderHandbookInternal] Error fetching expression groups:', err)
    throw err
  }

  expressionGroupsMap.forEach((groups, exprId) => {
    expressionMap[exprId] = { id: exprId, groups }
    groups.forEach(group => {
      group.expressions.forEach(groupExpr => {
        if (groupExpr.id !== exprId && !expressionMap[groupExpr.id]) {
          expressionMap[groupExpr.id] = groupExpr
        }
      })
    })
  })

  expressionsToFetch.forEach(expr => {
    if (!expressionMap[expr.id]) {
      expressionMap[expr.id] = { id: expr.id, groups: [] }
    }
  })

  const audioUrlCache: Map<number, string> = new Map()
  Object.values(expressionMap).forEach(expr => {
    if (expr.audio_url) {
      try {
        const parsed = JSON.parse(expr.audio_url)
        const audioUrl = Array.isArray(parsed) ? (parsed[0]?.url || '') : ''
        audioUrlCache.set(expr.id, audioUrl)
      } catch { }
    }
  })

  const renderItem = (id: number, text: string, audioUrl: string, isTitle: boolean, meaningId?: number) => {
    const groupsToUse = meaningId
      ? expressionMap[id]?.groups?.filter((g: any) => g.id === meaningId) || []
      : expressionMap[id]?.groups || []

    const translationGroups: Array<{ groupId: number, translations: Record<string, string> }> = []

    groupsToUse.forEach((group: any) => {
      const translations: Record<string, string> = {}
      const groupExpressions = group.expressions || []

      targetLangs.forEach(targetLang => {
        if (!targetLang) return
        const targetLangExpr = groupExpressions.find((e: any) => e.language_code === targetLang)
        if (targetLangExpr && targetLangExpr.text) {
          translations[targetLang] = targetLangExpr.text
        }
      })

      if (Object.keys(translations).length > 0) {
        translationGroups.push({
          groupId: group.id,
          translations
        })
      }
    })

    let meaningsHtml = ''
    if (translationGroups.length > 0) {
      const showGroups = translationGroups.slice(0, 2)
      const hiddenGroups = translationGroups.slice(2)

      if (isTitle) {
        meaningsHtml = ` <span class="handbook-meaning-title">
          <span class="handbook-visible-groups">
            ${showGroups.map((tg, index) => {
              const groupPrefix = translationGroups.length > 1 ? `<span style="color: #666;">${index + 1}:</span> ` : ''
              const languageElements = targetLangs.map(targetLang => {
                const text = tg.translations[targetLang]
                if (text) {
                  const color = langColors[targetLang] || getLanguageColor(targetLang, handbook)
                  const langClass = targetLang.replace('.', '-')
                  return `<span class="lang-${langClass}" style="color: ${color}">${text}</span>`
                }
                return ''
              }).filter(Boolean).join(' ')
              return `${groupPrefix}${languageElements}`
            }).join(' ')}
          </span>
          ${hiddenGroups.length > 0 ? `
            <span class="handbook-hidden-groups" style="display: none;">
              ${hiddenGroups.map((tg, index) => {
                const groupPrefix = `<span style="color: #666;">${index + 3}:</span> `
                const languageElements = targetLangs.map(targetLang => {
                  const text = tg.translations[targetLang]
                  if (text) {
                    const color = langColors[targetLang] || getLanguageColor(targetLang, handbook)
                    const langClass = targetLang.replace('.', '-')
                    return `<span class="lang-${langClass}" style="color: ${color}">${text}</span>`
                  }
                  return ''
                }).filter(Boolean).join(' ')
                return `${groupPrefix}${languageElements}`
              }).join(' ')}
            </span>
            <span class="handbook-more-groups" style="cursor: pointer; color: #666; font-size: 0.9em; margin-left: 4px;" onclick="event.stopPropagation(); this.previousElementSibling.style.display = this.previousElementSibling.style.display === 'none' ? 'inline' : 'none'; this.textContent = this.textContent.includes('more') ? '+${hiddenGroups.length} less' : '+${hiddenGroups.length} more'">+${hiddenGroups.length} more</span>
          ` : ''}
        </span>`
      } else {
        meaningsHtml = ` <span class="handbook-meaning-content">
          <span class="handbook-visible-groups">
            ${showGroups.map((tg, index) => {
              const groupPrefix = translationGroups.length > 1 ? `<span style="color: #666;">${index + 1}:</span> ` : ''
              const languageElements = targetLangs.map(targetLang => {
                const text = tg.translations[targetLang]
                if (text) {
                  const color = langColors[targetLang] || getLanguageColor(targetLang, handbook)
                  const langClass = targetLang.replace('.', '-')
                  return `<span class="lang-${langClass}" style="color: ${color}">${text}</span>`
                }
                return ''
              }).filter(Boolean).join(' ')
              return `${groupPrefix}${languageElements}`
            }).join(' ')}
          </span>
          ${hiddenGroups.length > 0 ? `
            <span class="handbook-hidden-groups" style="display: none;">
              ${hiddenGroups.map((tg, index) => {
                const groupPrefix = `<span style="color: #666;">${index + 3}:</span> `
                const languageElements = targetLangs.map(targetLang => {
                  const text = tg.translations[targetLang]
                  if (text) {
                    const color = langColors[targetLang] || getLanguageColor(targetLang, handbook)
                    const langClass = targetLang.replace('.', '-')
                    return `<span class="lang-${langClass}" style="color: ${color}">${text}</span>`
                  }
                  return ''
                }).filter(Boolean).join(' ')
                return `${groupPrefix}${languageElements}`
              }).join(' ')}
            </span>
            <span class="handbook-more-groups" style="cursor: pointer; color: #666; font-size: 0.9em; margin-left: 4px;" onclick="event.stopPropagation(); this.previousElementSibling.style.display = this.previousElementSibling.style.display === 'none' ? 'inline' : 'none'; this.textContent = this.textContent.includes('more') ? '+${hiddenGroups.length} less' : '+${hiddenGroups.length} more'">+${hiddenGroups.length} more</span>
          ` : ''}
        </span>`
      }
    }

    const audioIcon = audioUrl ? ` <span class="handbook-audio-icon">🔊</span>` : ''
    const audioHandler = audioUrl ? `window.playHandbookAudio('${audioUrl}')` : ''

    const meaningIdValue = meaningId !== undefined ? meaningId : 'null'

    const result = isTitle
      ? `<span class="handbook-item" data-type="title" data-expression-id="${id}" data-meaning-id="${meaningId || ''}" onclick="event.stopPropagation(); window.dispatchEvent(new CustomEvent('handbook-expression-click', { detail: { id: ${id}, meaningId: ${meaningIdValue} } })); ${audioHandler}">${text}${meaningsHtml}${audioIcon}</span>`
      : `<span class="handbook-item" data-type="content" data-expression-id="${id}" data-meaning-id="${meaningId || ''}" onclick="event.stopPropagation(); window.dispatchEvent(new CustomEvent('handbook-expression-click', { detail: { id: ${id}, meaningId: ${meaningIdValue} } })); ${audioHandler}">${text}${meaningsHtml}${audioIcon}</span>`

    return result
  }

  const renderTextWithTags = (text: string, isTitle: boolean) => {
    if (!text) return ''
    const textToRender = text

    TEXT_LANG_REGEX.lastIndex = 0
    const result = textToRender.replace(TEXT_LANG_REGEX, (match, term, param1, param2) => {

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
          const tagInfo = Array.from(midTags.values()).find(t => t.mid === mid && t.lang === lang)
          const expressionId = tagInfo?.expressionId

          if (expressionId) {
            const expr = expressionMap[expressionId]
            if (expr) {
              const audioUrl = audioUrlCache.get(expr.id) || ''
              return renderItem(expr.id, term, audioUrl, isTitle, mid)
            }
            return `<span class="handbook-item-undefined">${term}</span>`
          }
          return `<span class="handbook-item-undefined">${term}</span>`
        }

      try {
        const cacheKey = `${term}|${lang}`
        const id = expressionIdCache.get(cacheKey) ?? db.stableExpressionId(term, lang)
        const expr = expressionMap[id]
        if (expr) {
          const audioUrl = audioUrlCache.get(expr.id) || ''
          return renderItem(id, term, audioUrl, isTitle)
        }
        return `<span class="handbook-item-undefined">${term}</span>`
      } catch (err) {
        console.error('[renderTextWithTags] Error in renderTextWithTags:', err)
        return `<span class="handbook-item-undefined">${term}</span>`
      }
    })
    return result
  }

  let rendered_title = renderTextWithTags(titleToExtract, true)
  if (!rendered_title.includes('handbook-meaning-title')) {
    rendered_title = ''
  }

  const rendered_description = renderTextWithTags(description, false)

  const htmlPlaceholders: Record<string, string> = {}

  TEXT_LANG_REGEX.lastIndex = 0
  const contentWithPlaceholders = content.replace(TEXT_LANG_REGEX, (match: string) => {
    const index = Object.keys(htmlPlaceholders).length
    const placeholder = `HANDBOOK_ITEM_${index}`
    htmlPlaceholders[placeholder] = match
    return placeholder
  })

  const renderedMarkdown = md.render(contentWithPlaceholders)

  const finalContent = renderedMarkdown.replace(/HANDBOOK_ITEM_\d+/g, (match) => {
    const originalTag = htmlPlaceholders[match]
    if (originalTag) {
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
          const tagInfo = Array.from(midTags.values()).find(t => t.mid === mid && t.lang === lang)
          const expressionId = tagInfo?.expressionId

          if (expressionId) {
            const expr = expressionMap[expressionId]
            if (expr) {
              const audioUrl = audioUrlCache.get(expr.id) || ''
              return renderItem(expr.id, term, audioUrl, false, mid)
            }
            return `<span class="handbook-item-undefined">${term}</span>`
          }
          return `<span class="handbook-item-undefined">${term}</span>`
        }

        try {
          const cacheKey = `${term}|${lang}`
          const id = expressionIdCache.get(cacheKey) ?? db.stableExpressionId(term, lang)
          const expr = expressionMap[id]
          if (expr) {
            const audioUrl = audioUrlCache.get(expr.id) || ''
            return renderItem(id, term, audioUrl, false)
          }
          return `<span class="handbook-item-undefined">${term}</span>`
        } catch (err) {
          console.error('[renderHandbookInternal] Error in placeholder substitution:', err)
          return `<span class="handbook-item-undefined">${term}</span>`
        }
      })
    }
    return match
  })

  return { rendered_title, rendered_description, rendered_content: finalContent }
}

handbookRoutes.get('/', optionalAuth, async (c) => {
  try {
    const db = createDatabaseService(c.env)
    const user = c.get('user')
    const isPublicParam = c.req.query('is_public')
    const skip = parseInt(c.req.query('skip') || '0')
    const limit = parseInt(c.req.query('limit') || '20')

    let userId: number | undefined
    let isPublic: boolean | undefined

    // Explicit is_public parameter
    if (isPublicParam !== undefined) {
      isPublic = isPublicParam === '1'
      userId = undefined  // Don't filter by user_id when is_public is explicitly set
    } else if (user) {
      // No is_public parameter, user is logged in -> get user's handbooks
      userId = user.id
      isPublic = undefined  // Get both public and private handbooks
    } else {
      // No is_public parameter, user is not logged in -> return empty (shouldn't happen normally)
      return success(c, [])
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

    console.log('[GET] Params:', {
      id,
      user: user?.id,
      queryTargetLang: c.req.query('target_lang'),
      queryTargetLangs: c.req.query('target_langs'),
      paramTargetLang: c.req.param('target_lang')
    })

    if (isNaN(id)) return badRequest(c, 'Invalid ID')

    console.log('[GET] Fetching handbook...')
    const handbook = await db.getHandbookById(id)
    if (!handbook) return notFound(c, 'Handbook')

    console.log('[GET] Handbook fetched:', {
      id: handbook.id,
      title: handbook.title ? handbook.title.substring(0, 50) : 'NO TITLE',
      target_lang: handbook.target_lang,
      source_lang: handbook.source_lang,
      contentLength: handbook.content?.length || 0
    })

    const targetLangsParam = c.req.query('target_langs') || c.req.query('target_lang') || c.req.param('target_lang')
    let targetLangs: string[] = []

    if (targetLangsParam) {
      targetLangs = targetLangsParam.split(',').map(l => l.trim()).filter(Boolean)
    }

    console.log('[GET] Parsed targetLangs:', targetLangs)
    console.log('[GET] Final targetLangs decision:', {
      inputParam: targetLangsParam,
      parsedTargetLangs: targetLangs,
      handbookTargetLang: handbook.target_lang,
      willUse: targetLangs.length > 0 ? 'PARSED' : 'HANDBOOK_DEFAULT',
      finalTargetLangs: targetLangs.length > 0 ? targetLangs : (handbook.target_lang ? [handbook.target_lang] : [])
    })

    // IMPORTANT: Use handbook.target_lang as default BEFORE checking cache
    if (targetLangs.length === 0) {
      if (handbook.target_lang) {
        // Split handbook.target_lang by comma to handle multiple languages
        targetLangs = handbook.target_lang.split(',').map(l => l.trim()).filter(Boolean)
        console.log('[GET] Using handbook target_lang:', handbook.target_lang)
        console.log('[GET] Parsed targetLangs from handbook.target_lang:', targetLangs)
      }
    }

    if (!handbook.is_public && (!user || user.id !== handbook.user_id)) {
      console.log('[GET] Access denied')
      return forbidden(c, 'Access denied')
    }

    if (targetLangs.length > 0) {
      const sortedTargetLangs = [...targetLangs].sort()
      const cacheKey = sortedTargetLangs.join('|')
      console.log('[GET] Checking cache for key:', cacheKey)
      console.log('[GET] targetLangs before sort:', targetLangs)
      console.log('[GET] targetLangs after sort:', sortedTargetLangs)

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

        console.log('[GET] Saving to cache with key:', cacheKey)
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
        console.error('[GET] Render error type:', renderError?.constructor?.name)
        console.error('[GET] Render error message:', renderError instanceof Error ? renderError.message : 'No message')
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
    await clearCache(c, '/api/v1/handbooks')

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
    await clearCache(c, `/api/v1/handbooks/${id}`)

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
    await clearCache(c, `/api/v1/handbooks/${id}`)

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
    await clearCache(c, '/api/v1/handbooks')
    return success(c, { success }, 'Handbook deleted successfully')
  } catch (error: any) {
    console.error('Error in DELETE /handbooks/:id:', error)
    return internalError(c, 'Failed to delete handbook')
  }
})

export default handbookRoutes
