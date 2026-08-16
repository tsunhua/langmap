import { computed } from 'vue'
import { useLocalizationStore } from '@/stores/localization'

export function useLocaleParams() {
  const localization = useLocalizationStore()
  return computed(() => ({
    ui_locale: localization.locale,
    secondary_ui_locale: localization.secondary,
  }))
}
