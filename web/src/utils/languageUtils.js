/**
 * Language utility functions for LangMap
 */

/**
 * Generate a stable color from language code
 * Uses HSL color space to ensure visually distinct colors
 * This matches the backend implementation
 * 
 * @param {string} langCode - Language code (e.g., 'zh-CN', 'ja', 'ko')
 * @returns {string} Hex color string (e.g., '#FF6B6B')
 */
export function generateLanguageColor(langCode) {
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
  const f = (n) => {
    const k = (n + hue / 30) % 12
    const color = l - a * Math.max(Math.min(k - 3, 9 - k, 1), -1)
    return Math.round(255 * color)
      .toString(16)
      .padStart(2, '0')
  }
  return `#${f(0)}${f(8)}${f(4)}`
}

/**
 * Get language color with fallback
 * If language has a custom color field, use it; otherwise generate one
 * 
 * @param {object} lang - Language object with code and optional color field
 * @param {array} languages - Array of available languages for lookup
 * @returns {string} Hex color string
 */
export function getLanguageColor(lang, languages = []) {
  if (lang.color) return lang.color
  
  const langData = languages.find(l => l.code === lang.code)
  if (langData?.color) return langData.color
  
  return generateLanguageColor(lang.code)
}
