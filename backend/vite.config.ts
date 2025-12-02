import { defineConfig } from 'vite'
import ssrPlugin from 'vite-ssr-components/plugin'
import { resolve } from 'path'

export default defineConfig({
  plugins: [ssrPlugin()],
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: './src/index.tsx',
      output: {
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash].[ext]'
      }
    }
  },
  publicDir: 'public',
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  }
})