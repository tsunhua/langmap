# Frontend Docker Deployment

This guide explains how to build and run the frontend service using Docker.

## Building the Frontend Docker Image

From the `web` directory, run:

```bash
docker build -t langmap-frontend .
```

## 如果遇到网络问题

如果在构建过程中遇到网络连接问题（特别是访问 NPM 源时），可以使用国内镜像源：

```bash
docker build \
  --build-arg NODE_REGISTRY=https://registry.npmmirror.com \
  -t langmap-frontend .
```

## Running the Container

To run the frontend container:

```bash
docker run -p 80:80 langmap-frontend
```

The frontend application will be available at http://localhost

## Connecting to a Different Backend

By default, the frontend is configured to connect to the backend at `http://127.0.0.1:8000`. 

To connect to a backend running on a different host or port, you can build the image with a different proxy target:

```bash
docker build --build-arg VITE_API_PROXY=http://your-backend-host:8000 -t langmap-frontend .
```

### Using Docker Network

1. Create a Docker network:
   ```bash
   docker network create langmap-network
   ```

2. Run the backend container on this network:
   ```bash
   docker run -d --name langmap-backend --network langmap-network langmap-backend
   ```

3. Run the frontend container on the same network:
   ```bash
   docker run -d --name langmap-frontend -p 80:80 --network langmap-network langmap-frontend
   ```

Note: With this setup, the frontend application will still try to connect to the backend at `http://127.0.0.1:8000` as configured in [vite.config.js](file:///Users/lim/Documents/Code/tsunhua/langmap/web/vite.config.js). To make it work with Docker networking, you would need to update the [vite.config.js](file:///Users/lim/Documents/Code/tsunhua/langmap/web/vite.config.js) to use the backend service name (`langmap-backend`) instead.

## Deploying to Subdirectories

If you need to deploy the application to a subdirectory (not the root of the domain), you can specify the base path during the build:

```bash
docker build --build-arg VITE_BASE_PATH=/my-app/ -t langmap-frontend .
```

## Cloudflare Pages Deployment

For deployment to Cloudflare Pages, you don't need this Dockerfile. Instead, you can directly deploy the built files in the `dist` directory after running:

```bash
npm run build
```

The `dist` folder will contain all the static files needed for deployment to Cloudflare Pages. You can configure Cloudflare Pages to automatically build and deploy your application by pointing it to your repository and specifying the build command (`npm run build`) and output directory (`dist`).

If you're deploying to a subdirectory on Cloudflare Pages, you can set the `VITE_BASE_PATH` environment variable in the Cloudflare Pages project settings.