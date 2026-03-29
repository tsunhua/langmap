import { D1Database } from '@cloudflare/workers-types'
import { Statistics, HeatmapData, UILocale } from '../protocol.js'

export class MetaQueries {
  constructor(private db: D1Database) {}

  async getStatistics(): Promise<Statistics> {
    const totalExpressions = await this.db.prepare('SELECT COUNT(*) as count FROM expressions').first<number>('count') || 0
    const totalLanguages = await this.db.prepare('SELECT COUNT(*) as count FROM languages').first<number>('count') || 0
    const totalRegions = await this.db.prepare('SELECT COUNT(DISTINCT region_name) as count FROM languages WHERE region_name IS NOT NULL').first<number>('count') || 0

    return {
      total_expressions: totalExpressions,
      total_languages: totalLanguages,
      total_regions: totalRegions
    }
  }

  async getHeatmapData(): Promise<HeatmapData[]> {
    const query = `
      SELECT 
        ls.language_code,
        l.name as language_name,
        l.region_code,
        l.region_name,
        ls.expression_count as count,
        l.region_latitude as latitude,
        l.region_longitude as longitude
      FROM language_stats ls
      JOIN languages l ON ls.language_code = l.code
      WHERE l.region_latitude IS NOT NULL AND l.region_longitude IS NOT NULL
    `
    const { results } = await this.db.prepare(query).all<HeatmapData>()
    return results || []
  }

  async getUILocale(languageCode: string): Promise<UILocale | null> {
    return await this.db.prepare(
      'SELECT * FROM ui_locales WHERE language_code = ?'
    ).bind(languageCode).first<UILocale>() || null
  }

  async saveUILocale(languageCode: string, localeJson: string, username: string): Promise<UILocale> {
    const now = new Date().toISOString()
    const id = Math.abs(this.hashCode(`${languageCode}|${Date.now()}`))
    
    const result = await this.db.prepare(
      `INSERT INTO ui_locales (id, language_code, locale_json, created_by, updated_by)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(language_code) DO UPDATE SET
         locale_json = excluded.locale_json,
         updated_by = excluded.updated_by,
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`
    ).bind(id, languageCode, localeJson, username, username).first<UILocale>()

    if (!result) {
      throw new Error('Failed to save UI locale')
    }

    return result
  }

  async deleteUILocale(languageCode: string): Promise<boolean> {
    const result = await this.db.prepare(
      'DELETE FROM ui_locales WHERE language_code = ?'
    ).bind(languageCode).run()
    return (result.meta?.changes ?? 0) > 0
  }

  private hashCode(s: string): number {
    let hash = 0
    for (let i = 0; i < s.length; i++) {
      const char = s.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32bit integer
    }
    return hash
  }
}
