# Langmap

Langmap is an open-source, community-driven online language map that collects phrases and expressions from languages around world, showcases differences between languages, and provides a valuable resource for language enthusiasts.

## Project Architecture

### Web Frontend

The web frontend is built with Vue.js and uses Vite as build tool. It communicates with backend through RESTful APIs.

Key technologies:
- Vue.js 3 with Composition API
- Vue Router for navigation
- Vue I18n for internationalization
- Tailwind CSS for styling
- Vite for fast development and building

### iOS App

The iOS app is built with SwiftUI and follows iOS 26+ design guidelines with modern APIs.

Key technologies:
- SwiftUI for declarative UI
- LocalizationManager for multi-language support
- Combine for reactive programming
- async/await for modern concurrency
- NetworkService for API communication

### Backend

The backend is powered by Cloudflare Workers with Hono.js framework, providing a fast and scalable serverless API.

Key technologies:
- Hono.js - Lightweight Node.js framework for Cloudflare Workers
- Cloudflare D1 - SQLite-compatible database
- Cloudflare Assets - For serving static files
- TypeScript for type safety

### Database

We use Cloudflare D1, which is a SQLite-compatible database that runs on Cloudflare's edge network.

## Deployment Architecture

Deploy web frontend using Cloudflare Assets + backend using Cloudflare Workers

This is recommended approach because:

1. The frontend can fully leverage Cloudflare Assets' CDN capabilities.
2. The backend can utilize Cloudflare Workers' edge computing power.
```
┌─────────────────┐     ┌──────────────────────┐
│                 │     │                      │
│  Cloudflare     │     │  Cloudflare D1 or    │
│  Assets(Frontend)◄───►│  External Database   │
│                 │     │                      │
└─────────▲───────┘     └──────────────────────┘
          │
          │
┌─────────▼───────┐
│                 │
│  Cloudflare     │
│  Workers (API)  │
│                 │
└─────────────────┘
```

## Building and Deployment

### Web Building

To build the web application, run:

```bash
./build.sh
```

This script will:
1. Install frontend dependencies if needed
2. Build the frontend Vue.js application
3. Copy the built files to the backend's public directory

### iOS Building

To build the iOS application, run:

```bash
./build-ios.sh
```

This script will:
1. Clean DerivedData
2. Build the iOS app for iOS Simulator
3. Display build status and output location

You can customize the build with environment variables:
- `CONFIGURATION` - Debug (default) or Release
- `SDK` - iphonesimulator (default) or iphoneos
- `DESTINATION` - Target device (default: iPhone 17 Pro Max)

Example:
```bash
CONFIGURATION=Release ./build-ios.sh
SDK=iphoneos DESTINATION="platform=iOS,name=My iPhone" ./build-ios.sh
```

### Deployment

To deploy the web application to Cloudflare Workers:

```bash
npm run deploy
```

This will build application and deploy it to Cloudflare Workers using Wrangler.

To perform a dry-run of deployment:

```bash
npx wrangler deploy --dry-run
```

### Database Configuration

Using Cloudflare D1, configure the D1 binding in `wrangler.jsonc`:

```jsonc
{
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "your-database-name",
      "database_id": "your-database-id"
    }
  ]
}
```

## Development

### Web Frontend Development

Navigate to `web` directory and run:

```bash
cd web
npm install
npm run dev
```

This starts the Vite development server with hot reloading for frontend.

### iOS Development

Open `apple/langmap.xcodeproj` in Xcode to develop the iOS app.

For command-line builds, use the build-ios.sh script.

Key features:
- Multi-language support (English, Chinese)
- System language auto-detection
- Profile-based language selection
- Real-time language switching

### Backend Development

In the `backend` directory, run:

```bash
cd backend
npm install
npm run dev
```

This starts the backend development server with remote D1 database connection.