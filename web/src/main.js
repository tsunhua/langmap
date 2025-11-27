import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './index.css'
import i18n from './i18n'

// Handle unhandled rejections
window.addEventListener('unhandledrejection', event => {
  console.error('Unhandled promise rejection:', event.reason)
})

createApp(App).use(router).use(i18n).mount('#app')