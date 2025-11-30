# Frontend Dockerfile
FROM node:18-alpine AS build

# 添加构建参数支持国内镜像源
ARG NODE_REGISTRY=https://registry.npmjs.org/
RUN npm config set registry $NODE_REGISTRY

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the app with environment variables
ARG VITE_API_PROXY=http://127.0.0.1:8000
ENV VITE_API_PROXY=$VITE_API_PROXY
RUN npm run build

# Production stage - using a simple HTTP server
FROM node:18-alpine

# Install a simple web server to serve the built files
RUN npm install -g serve

WORKDIR /app

# Copy built files from the build stage
COPY --from=build /app/dist .

# Expose port
EXPOSE 80

# Serve the built app
CMD ["serve", "-s", ".", "-l", "80"]