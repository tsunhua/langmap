<template>
  <div class="min-h-screen bg-slate-50 py-4 sm:py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-3xl mx-auto">
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-slate-900">
            {{ $t('user_profile') }}
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-slate-500">
            {{ $t('description') }}
          </p>
        </div>
        <div class="border-t border-slate-200">
          <dl>
            <div class="bg-slate-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-slate-500">
                {{ $t('username') }}
              </dt>
              <dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
                {{ user.username }}
              </dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-slate-500">
                {{ $t('email_address') }}
              </dt>
              <dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
                {{ user.email }}
              </dd>
            </div>
            <div class="bg-slate-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-slate-500">
                {{ $t('role') }}
              </dt>
              <dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
                <span
                  class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                  {{ user.role }}
                </span>
              </dd>
            </div>
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-slate-500">
                {{ $t('member_since') }}
              </dt>
              <dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
                {{ formatDate(user.created_at) }}
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <div class="mt-6 bg-white shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-slate-900">
            {{ $t('actions') }}
          </h3>
        </div>
        <div class="border-t border-slate-200 px-4 py-5 sm:p-6">
          <div class="flex flex-col sm:flex-row gap-3">
            <button @click="handleLogout"
              class="inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
              {{ $t('logout') }}
            </button>

            <button @click="changePassword"
              class="inline-flex items-center justify-center px-4 py-2 border border-slate-300 text-sm font-medium rounded-md shadow-sm text-slate-700 bg-white hover:bg-slate-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
              {{ $t('change_password') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="error" class="mt-6 rounded-md bg-red-50 p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"
              fill="currentColor">
              <path fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">
              {{ error }}
            </h3>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'UserProfile',
  setup() {
    const { t } = useI18n()
    const router = useRouter()

    const user = ref({
      username: '',
      email: '',
      role: '',
      created_at: ''
    })

    const loading = ref(true)
    const error = ref('')

    // Format date
    const formatDate = (dateString) => {
      if (!dateString) return ''
      const date = new Date(dateString)
      return date.toLocaleDateString(undefined, {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })
    }

    // Fetch user profile
    const fetchUserProfile = async () => {
      try {
        loading.value = true
        error.value = ''

        const token = localStorage.getItem('authToken')
        if (!token) {
          router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
          return
        }

        const response = await fetch('/api/v1/users/me', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        const data = await response.json()

        if (response.ok) {
          user.value = data.data
        } else {
          error.value = data.error || t('userProfile.fetchFailed')
          // If unauthorized, redirect to login
          if (response.status === 401) {
            localStorage.removeItem('authToken')
            router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
          }
        }
      } catch (err) {
        error.value = t('userProfile.fetchFailed')
        console.error('Fetch user profile error:', err)
      } finally {
        loading.value = false
      }
    }

    // Handle logout
    const handleLogout = async () => {
      try {
        const token = localStorage.getItem('authToken')
        if (!token) {
          router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
          return
        }

        // Call logout API
        const response = await fetch('/api/v1/auth/logout', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        // Remove token and redirect to login
        localStorage.removeItem('authToken')
        router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
      } catch (err) {
        // Even if API fails, still do local logout
        localStorage.removeItem('authToken')
        router.push({ path: '/login', query: { redirect: router.currentRoute.value.fullPath } })
        error.value = t('userProfile.logoutFailed')
        console.error('Logout error:', err)
      }
    }

    // Change password
    const changePassword = () => {
      // In a real implementation, you would show a modal or navigate to a change password page
      alert(t('userProfile.changePasswordNotImplemented'))
    }

    // Fetch user profile on mount
    onMounted(() => {
      fetchUserProfile()
    })

    return {
      user,
      loading,
      error,
      formatDate,
      handleLogout,
      changePassword
    }
  }
}
</script>