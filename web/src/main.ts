import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/atlas.css'
import { i18n } from './locales'
import { useLocalizationStore } from './stores/localization'

async function bootstrap() {
  const pinia = createPinia()
  const app = createApp(App)
  app.use(pinia)
  app.use(router)
  app.use(i18n)

  try {
    // Resolve the saved locale before page components mount so they do not
    // first fetch data for the default English locale and then refetch it.
    await useLocalizationStore(pinia).loadLocales()
  } catch (error) {
    console.error('Localization bootstrap failed:', error)
  }

  await router.isReady()
  app.mount('#app')
}

void bootstrap()
