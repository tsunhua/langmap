import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    proxy: {
      '/api/v2': 'http://localhost:8789',
      '/api/v1': 'http://localhost:8787',
    },
  },
})
