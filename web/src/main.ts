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
  const localization = useLocalizationStore(pinia)

  await router.isReady()
  app.mount('#app')

  // The English catalog is bundled, so the shell can render while the saved
  // locale and server-backed messages load in the background.
  void localization.loadLocales().catch((error: unknown) => {
    console.error('Localization bootstrap failed:', error)
  })
}

void bootstrap()
