import { transformTranslations } from '../languageService.js'

describe('languageService', () => {
  describe('transformTranslations', () => {
    it('should transform flat expressions to nested object', () => {
      const expressions = [
        {
          text: 'Home',
          tags: ['langmap.nav.home']
        },
        {
          text: 'Search',
          tags: ['langmap.nav.search']
        },
        {
          text: 'Explore the World of Languages',
          tags: ['langmap.home.title']
        }
      ]

      const result = transformTranslations(expressions)
      
      expect(result).toEqual({
        nav: {
          home: 'Home',
          search: 'Search'
        },
        home: {
          title: 'Explore the World of Languages'
        }
      })
    })

    it('should handle expressions without langmap tags', () => {
      const expressions = [
        {
          text: 'Home',
          tags: ['ui.nav.home']
        },
        {
          text: 'Search',
          tags: ['langmap.nav.search']
        }
      ]

      const result = transformTranslations(expressions)
      
      expect(result).toEqual({
        nav: {
          search: 'Search'
        }
      })
    })

    it('should handle empty expressions array', () => {
      const expressions = []
      const result = transformTranslations(expressions)
      expect(result).toEqual({})
    })
  })
})