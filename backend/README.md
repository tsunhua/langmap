# LangMap Worker

This is a Hono-based application that serves both static assets and API endpoints.

## Development

To run the development server:

```txt
npm install
npm run dev
```

This will start the Vite development server with hot reloading.

## Building

To build the application for production:

```txt
npm run build
```

This will bundle the client-side assets into the `public/client` directory and prepare the server-side code.

## Deployment

To deploy to Cloudflare Workers:

```txt
npm run deploy
```

This will build the application and deploy it to Cloudflare Workers using Wrangler.

To perform a dry-run of the deployment:

```txt
npx wrangler deploy --dry-run
```

[For generating/synchronizing types based on your Worker configuration run](https://developers.cloudflare.com/workers/wrangler/commands/#types):

```txt
npm run cf-typegen
```

Pass the `CloudflareBindings` as generics when instantiation `Hono`:

```ts
// src/index.ts
const app = new Hono<{ Bindings: CloudflareBindings }>()
```
