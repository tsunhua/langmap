import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    // useful default proxy for local backend during development
    proxy: {
      '/api': process.env.VITE_API_PROXY || 'http://127.0.0.1:8000'
    }
  },
  // Support for defining the base path for deployment to subdirectories
  base: process.env.VITE_BASE_PATH || '/',
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vue-vendor': ['vue', 'vue-router', 'pinia', 'vue-i18n'],
          'md-editor': ['md-editor-v3', 'markdown-it'],
          'axios': ['axios']
        }
      }
    },
    chunkSizeWarningLimit: 800
  }
})