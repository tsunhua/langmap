# Frontend Dynamic Language Loading Implementation

## Overview

This document describes the implementation of dynamic language loading for the Langmap frontend. This feature allows the application to load languages and translations dynamically from the backend, enabling support for user-contributed languages and translations.

## Implementation Details

### 1. Language Service

The language service (`src/services/languageService.js`) provides functions to communicate with the backend API for language and translation management:

- `fetchLanguages()` - Retrieves all available languages from the backend
- `fetchUITranslations(languageCode)` - Fetches UI translations for a specific language by meaning
- `createLanguage(languageData)` - Creates a new language in the system
- `transformTranslations(expressions)` - Transforms flat expressions list to nested i18n messages object

### 2. Dynamic i18n Loading

The i18n module (`src/i18n.js`) has been enhanced to support dynamic language loading:

1. Static languages (en, zh-CN, zh-TW, es, fr, ja) are loaded from the existing static configuration
2. Dynamic languages are fetched from the backend when needed
3. Translation caching prevents repeated backend requests for the same language
4. Fallback mechanism ensures the application continues to work even if dynamic translations fail to load

### 3. App Component Enhancements

The App component (`src/App.vue`) has been updated with:

1. Dynamic language list loading from the backend on application startup
2. Language switching that supports both static and dynamic languages
3. "Add New Language" functionality that allows users to contribute new languages
4. Modal interface for language creation with fields for:
   - Language code (can be custom/non-standard)
   - Language name
   - Native name
   - Text direction (LTR/RTL)

### 4. Integration with Vue Router

The implementation works seamlessly with Vue Router, ensuring that language preferences are preserved during navigation.

## Technical Architecture

### Data Flow

1. Application startup:
   - Load static languages from configuration
   - Fetch dynamic languages from backend
   - Merge into available languages list
   - Load user's preferred language (from localStorage or default)

2. Language switching:
   - Check if language is static or dynamic
   - For dynamic languages, fetch translations from backend
   - Transform translations to i18n format
   - Update i18n instance with new messages
   - Cache translations for future use
   - Save preference to localStorage

3. Adding new languages:
   - Show modal form for language details
   - Submit to backend API
   - Add to available languages list
   - Switch to the new language
   - Load (empty) translations for the new language

### Caching Strategy

Translations are cached in memory to prevent repeated backend requests:

1. When a dynamic language is loaded, its translations are stored in `dynamicMessagesCache`
2. Subsequent requests for the same language use cached data
3. Cache is maintained in-memory during the application session
4. Future enhancements could include localStorage-based caching with expiration

### Error Handling

1. Failed translation loading falls back to English translations
2. Network errors are logged to console for debugging
3. User-facing error messages are displayed for critical operations (like adding languages)
4. Application continues to function even if dynamic language loading fails

## API Integration

The frontend communicates with these backend endpoints:

### GET /api/v1/languages
Retrieves all available languages

Response:
```json
[
  {
    "code": "en",
    "name": "English",
    "native_name": "English",
    "direction": "ltr"
  },
  {
    "code": "custom-lang",
    "name": "Custom Language",
    "native_name": "Native Name",
    "direction": "ltr"
  }
]
```

### GET /api/v1/ui-translations/{language}
Retrieves UI translations for a specific language by meaning

Response:
```json
[
  {
    "id": 1,
    "text": "Home",
    "language": "custom-lang",
    "gloss": "langmap.nav.home"
  }
]
```

### POST /api/v1/languages
Creates a new language

Request:
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

Response:
```json
{
  "code": "custom-lang",
  "name": "Custom Language",
  "native_name": "Native Name",
  "direction": "ltr"
}
```

## Future Improvements

1. **Persistent Caching**: Store translations in localStorage with expiration timestamps
2. **Lazy Loading**: Load translations on-demand per component rather than all at once
3. **Offline Support**: Cache translations for offline usage
4. **Translation Management UI**: Interface for users to contribute translations for existing languages
5. **Language Packs**: Bundle common languages for offline-first scenarios
6. **Performance Monitoring**: Track translation loading times and optimize accordingly

## Testing

Unit tests have been added for key functions in the language service, particularly the translation transformation logic. Additional end-to-end tests should be added to verify the complete dynamic loading workflow.