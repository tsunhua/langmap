<template>
  <div class="min-h-screen flex items-center justify-center bg-slate-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-slate-900">
          {{ $t('emailVerification.title') }}
        </h2>
      </div>
      
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10 text-center">
        <div v-if="verificationStatus === 'success'" class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
          <svg class="h-6 w-6 text-green-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
        <div v-else-if="verificationStatus === 'error'" class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100">
          <svg class="h-6 w-6 text-red-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        
        <div v-else class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-blue-100">
          <svg class="animate-spin h-6 w-6 text-blue-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>
        
        <h3 v-if="verificationStatus === 'success'" class="mt-4 text-lg font-medium text-slate-900">
          {{ $t('emailVerification.successTitle') }}
        </h3>
        
        <h3 v-else-if="verificationStatus === 'error'" class="mt-4 text-lg font-medium text-slate-900">
          {{ $t('emailVerification.errorTitle') }}
        </h3>
        
        <h3 v-else class="mt-4 text-lg font-medium text-slate-900">
          {{ $t('emailVerification.verifyingTitle') }}
        </h3>
        
        <div class="mt-2 text-sm text-slate-500">
          <p v-if="verificationStatus === 'success'">
            {{ $t('emailVerification.successMessage') }}
          </p>
          
          <p v-else-if="verificationStatus === 'error'">
            {{ $t('emailVerification.errorMessage') }}
          </p>
          
          <p v-else>
            {{ $t('emailVerification.verifyingMessage') }}
          </p>
        </div>
        
        <div v-if="verificationStatus !== 'verifying'" class="mt-6">
          <router-link 
            to="/login" 
            class="w-full flex justify-center py-2 px-4 border border-slate-300 rounded-md shadow-sm text-sm font-medium text-slate-700 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {{ $t('emailVerification.goToLogin') }}
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'EmailVerification',
  setup() {
    const { t } = useI18n()
    const route = useRoute()
    const router = useRouter()
    
    const verificationStatus = ref('verifying') // 'verifying', 'success', 'error'
    
    onMounted(async () => {
      try {
        // Get token from URL query params
        const token = route.query.token
        
        if (!token) {
          verificationStatus.value = 'error'
          return
        }
        
        // Make API call to verify email
        const response = await fetch(`/api/v1/auth/verify-email?token=${encodeURIComponent(token)}`)
        const data = await response.json()
        
        if (response.ok) {
          verificationStatus.value = 'success'
          // Redirect to login page after 3 seconds
          setTimeout(() => {
            router.push('/login')
          }, 3000)
        } else {
          verificationStatus.value = 'error'
        }
      } catch (err) {
        console.error('Email verification error:', err)
        verificationStatus.value = 'error'
      }
    })
    
    return {
      verificationStatus
    }
  }
}
</script>