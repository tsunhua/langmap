# Langmap

Langmap is an open-source, community-driven online language map that collects phrases and expressions from languages around the world, showcases differences between languages, and provides a valuable resource for language enthusiasts.

## Project Architecture

### Frontend

The frontend is built with Vue.js and uses Vite as the build tool. It communicates with the backend through RESTful APIs.

Key technologies:
- Vue.js 3 with Composition API
- Vue Router for navigation
- Vue I18n for internationalization
- Tailwind CSS for styling
- Vite for fast development and building

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

Deploy frontend using Cloudflare Assets + backend using Cloudflare Workers

This is the recommended approach because:

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

### Building

To build the application, run:

```bash
./build.sh
```

This script will:
1. Install frontend dependencies if needed
2. Build the frontend Vue.js application
3. Copy the built files to the backend's public directory

### Deployment

To deploy to Cloudflare Workers:

```bash
npm run deploy
```

This will build the application and deploy it to Cloudflare Workers using Wrangler.

To perform a dry-run of the deployment:

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

### Frontend Development

Navigate to the `web` directory and run:

```bash
cd web
npm install
npm run dev
```

This starts the Vite development server with hot reloading for the frontend.

### Backend Development

In the `backend` directory, run:

```bash
cd backend
npm install
npm run dev
```

This starts the backend development server with remote D1 database connection.