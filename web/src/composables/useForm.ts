import { ref, computed } from 'vue'

export interface UseFormOptions<T> {
  initialValues: T
  validation?: (values: T) => Record<string, string> | null
  onSubmit: (values: T) => Promise<void>
}

export function useForm<T extends Record<string, any>>(options: UseFormOptions<T>) {
  const { initialValues, validation, onSubmit } = options

  const values = ref<T>({ ...initialValues })
  const errors = ref<Record<string, string>>({})
  const touched = ref<Record<string, boolean>>({})
  const submitting = ref(false)

  const isValid = computed(() => {
    return Object.keys(errors.value).length === 0
  })

  function setValue<K extends keyof T>(key: K, value: T[K]) {
    values.value[key] = value
    touched.value[key as string] = true
    if (validation) {
      const validationErrors = validation(values.value)
      errors.value = validationErrors || {}
    }
  }

  function setError<K extends keyof T>(key: K, message: string) {
    errors.value[key as string] = message
  }

  function clearError<K extends keyof T>(key?: K) {
    if (key) {
      delete errors.value[key as string]
    } else {
      errors.value = {}
    }
  }

  function reset() {
    values.value = { ...initialValues }
    errors.value = {}
    touched.value = {}
  }

  async function handleSubmit() {
    if (validation) {
      const validationErrors = validation(values.value)
      if (validationErrors) {
        errors.value = validationErrors
        return false
      }
    }

    submitting.value = true
    try {
      await onSubmit(values.value)
      return true
    } catch (error) {
      console.error('Form submission error:', error)
      return false
    } finally {
      submitting.value = false
    }
  }

  return {
    values,
    errors,
    touched,
    submitting,
    isValid,
    setValue,
    setError,
    clearError,
    reset,
    handleSubmit
  }
}
