<template>
  <div class="min-h-screen flex items-top justify-center bg-slate-50 py-6 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-3 text-center text-3xl font-extrabold text-slate-900">
          {{ $t('new_account') }}
        </h2>
        <p class="mt-2 text-center text-sm text-slate-600">
          {{ $t('register_description') }}
        </p>
      </div>
      
      <div v-if="!registrationSuccess" class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <form class="space-y-6" @submit.prevent="handleRegister">
          <div>
            <label for="username" class="block text-sm font-medium text-slate-700">
              {{ $t('username') }}
            </label>
            <div class="mt-1">
              <input
                id="username"
                name="username"
                type="text"
                autocomplete="username"
                required
                v-model="form.username"
                class="appearance-none block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm placeholder-slate-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                :disabled="loading"
              />
            </div>
          </div>
          
          <div>
            <label for="email" class="block text-sm font-medium text-slate-700">
              {{ $t('email_address') }}
            </label>
            <div class="mt-1">
              <input
                id="email"
                name="email"
                type="email"
                autocomplete="email"
                required
                v-model="form.email"
                class="appearance-none block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm placeholder-slate-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                :disabled="loading"
              />
            </div>
          </div>

          <div>
            <label for="password" class="block text-sm font-medium text-slate-700">
              {{ $t('password') }}
            </label>
            <div class="mt-1">
              <input
                id="password"
                name="password"
                type="password"
                autocomplete="new-password"
                required
                v-model="form.password"
                class="appearance-none block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm placeholder-slate-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                :disabled="loading"
              />
            </div>
          </div>
          
          <div>
            <label for="confirmPassword" class="block text-sm font-medium text-slate-700">
              {{ $t('confirm_password') }}
            </label>
            <div class="mt-1">
              <input
                id="confirmPassword"
                name="confirmPassword"
                type="password"
                autocomplete="new-password"
                required
                v-model="form.confirmPassword"
                class="appearance-none block w-full px-3 py-2 border border-slate-300 rounded-md shadow-sm placeholder-slate-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                :disabled="loading"
              />
            </div>
          </div>

          <div class="flex items-start">
            <div class="flex items-center h-5">
              <input
                id="terms"
                name="terms"
                type="checkbox"
                required
                v-model="form.agreeToTerms"
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-slate-300 rounded"
                :disabled="loading"
              />
            </div>
            <div class="ml-3 text-sm">
              <label for="terms" class="text-slate-900">
                {{ $t('agree_to_terms') }}
                <router-link to="/policies" class="text-blue-600 hover:text-blue-500">{{ $t('terms_of_service') }}</router-link>
                {{ $t('and') }}
                <router-link to="/policies" class="text-blue-600 hover:text-blue-500">{{ $t('privacy_policy') }}</router-link>
              </label>
            </div>
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading || !form.agreeToTerms"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              <span v-if="loading" class="flex items-center">
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                {{ $t('signing_up') }}
              </span>
              <span v-else>
                {{ $t('sign_up') }}
              </span>
            </button>
          </div>
          
          <div v-if="error" class="rounded-md bg-red-50 p-4">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                </svg>
              </div>
              <div class="ml-3">
                <h3 class="text-sm font-medium text-red-800">
                  {{ error }}
                </h3>
              </div>
            </div>
          </div>
        </form>
        
        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-slate-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-slate-500">
                {{ $t('or') }}
              </span>
            </div>
          </div>

          <div class="mt-6">
            <router-link 
              to="/login" 
              class="w-full flex justify-center py-2 px-4 border border-slate-300 rounded-md shadow-sm text-sm font-medium text-slate-700 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              {{ $t('sign_in') }}
            </router-link>
          </div>
        </div>
      </div>
      
      <div v-else class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10 text-center">
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
          <svg class="h-6 w-6 text-green-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h3 class="mt-4 text-lg font-medium text-slate-900">{{ $t('registration_successful') }}</h3>
        <div class="mt-2 text-sm text-slate-500">
          <p>{{ $t('registration_successful_message') }}</p>
          <p class="mt-2 font-medium">{{ $t('registration_check_email') }}</p>
        </div>
        <div class="mt-6">
          <router-link 
            to="/login" 
            class="w-full flex justify-center py-2 px-4 border border-slate-300 rounded-md shadow-sm text-sm font-medium text-slate-700 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {{ $t('go_to_login') }}
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'Register',
  setup() {
    const { t } = useI18n()
    const router = useRouter()
    
    const form = ref({
      username: '',
      email: '',
      password: '',
      confirmPassword: '',
      agreeToTerms: false
    })
    
    const loading = ref(false)
    const error = ref('')
    const registrationSuccess = ref(false)
    
    // Watch for password mismatch
    watch([() => form.value.password, () => form.value.confirmPassword], ([password, confirmPassword]) => {
      if (password && confirmPassword && password !== confirmPassword) {
        error.value = t('register.passwordMismatch')
      } else {
        error.value = ''
      }
    })
    
    const handleRegister = async () => {
      try {
        // Check if terms are agreed
        if (!form.value.agreeToTerms) {
          error.value = t('register.agreeToTermsRequired')
          return
        }
        
        // Check passwords match
        if (form.value.password !== form.value.confirmPassword) {
          error.value = t('register.passwordMismatch')
          return
        }
        
        loading.value = true
        error.value = ''
        
        // Make API call to register user
        const response = await fetch('/api/v1/auth/register', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            username: form.value.username,
            email: form.value.email,
            password: form.value.password
          })
        })
        
        const data = await response.json()
        
        if (response.ok) {
          // Registration successful, show email verification message
          registrationSuccess.value = true
        } else {
          error.value = data.error || t('register.registrationFailed')
        }
      } catch (err) {
        error.value = t('register.registrationFailed')
        console.error('Registration error:', err)
      } finally {
        loading.value = false
      }
    }
    
    return {
      form,
      loading,
      error,
      registrationSuccess,
      handleRegister
    }
  }
}
</script>