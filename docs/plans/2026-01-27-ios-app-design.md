# iOS App Design - LangMap

**Date:** 2026-01-27

## Overview

Native SwiftUI iOS app for the LangMap language map project, connecting to the existing Cloudflare Workers backend with D1 database.

## Architecture

The app follows Model-View-ViewModel architecture:

- **Model Layer**: Data models matching backend API structure (User, Language, Expression, Collection)
- **ViewModel Layer**: State management using ObservableObject and @StateObject
- **View Layer**: SwiftUI views following Apple's HIG (Human Interface Guidelines)
- **Service Layer**: API client using URLSession for RESTful endpoints

**Requirements:**
- iOS 15.0+ deployment target
- Dark mode support
- Localized strings (matching web app's i18n structure)
- Offline-first capabilities using Core Data for caching

## Core Screens

1. **Splash/Login Screen**: App startup with authentication (email/password or social login)
2. **Home Screen**: Featured expressions and collections with language picker
3. **Search Screen**: Search bar with filters by language, collection, and keyword
4. **Detail Screen**: Full expression details with translations, origins, and usage notes
5. **Collections Screen**: Browse user's collections and create new ones
6. **Profile Screen**: User settings, language preferences, saved content
7. **Tab Bar Navigation**: Bottom tab bar for Home, Search, Collections, Profile

## Data Flow and API Integration

Communication with backend using URLSession:

**API Endpoints:**
- `/api/v1/auth/login`, `/logout`, `/me` - Authentication
- `/api/v1/languages` - Language data
- `/api/v1/expressions` - Expressions with filtering/searching
- `/api/v1/collections` - Collection management

**NetworkService Class:**
- Handles all API communication
- Manages authentication tokens (stored in Keychain)
- Implements request/response interceptors for automatic token refresh and error handling
- Caches API responses using Core Data for offline access

**Data Flow:** SwiftUI View → ViewModel → NetworkService → API → Backend

Each ViewModel exposes observable state (`@Published` properties) for reactive updates.

## Internationalization and Localization

Mirrors web app's i18n structure:

- JSON files for each language (en-US, zh-CN, zh-TW, es, fr, ja, etc.)
- `Localization.localizedString` for all UI text
- Dynamic language loading from backend
- Language preference saved in UserDefaults

Each screen has localized strings in separate JSON files, loaded at app launch and updated on language switch.

## Error Handling and Offline Support

- Network errors displayed through unified `AlertManager` with user-friendly messages
- 401 errors trigger automatic token refresh and retry
- Core Data cache allows reading saved expressions/collections without internet
- Queue-based offline write operations that sync when network returns
- Retry mechanism for failed API calls with exponential backoff

## Technical Stack and Dependencies

**Frameworks:**
- SwiftUI (iOS 15+)
- Core Data (local caching)
- URLSession (API networking)
- Keychain Services (secure token storage)
- User Defaults (app settings)
- CryptoKit (password hashing if needed)

**Project Structure:**
```
apple/langmap/
├── Models/           # Data models (User, Language, Expression, Collection)
├── Views/            # SwiftUI views for each screen
├── ViewModels/       # State management and business logic
├── Services/         # NetworkService, AuthService, CacheService
├── Resources/        # Localization files, Assets.xcassets
├── Utils/            # Helpers, extensions
└── Core Data/        # Data model, persistence controller
```

## Testing Strategy

- Unit tests for ViewModels using XCTest
- Integration tests for API Service with mock responses
- Snapshot tests for critical UI screens
- Test coverage target: 70%+ for ViewModels and Services

## Deployment Requirements

- iOS 15.0+ deployment target
- App Store Connect configuration for TestFlight and App Store
- Code signing and provisioning profiles
- Privacy manifest and App Privacy Details for data collection
- Store localization for all supported languages
