<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'

const router = useRouter()
const auth = useAuthStore()
const { t } = useI18n()

const mode = ref<'login' | 'register'>('login')
const username = ref('')
const email = ref('')
const password = ref('')
const errorMsg = ref('')
const submitting = ref(false)

async function submit() {
  errorMsg.value = ''
  submitting.value = true
  try {
    if (mode.value === 'login') {
      await auth.login(email.value, password.value)
    } else {
      await auth.register(username.value, email.value, password.value)
    }
    router.push('/')
  } catch (e: any) {
    errorMsg.value = e.response?.data?.message || t('auth.operationFailed')
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <h1>{{ mode === 'login' ? t('auth.login') : t('auth.register') }}</h1>

    <form class="auth-form" @submit.prevent="submit">
      <div v-if="mode === 'register'" class="field">
        <label for="auth-username">{{ t('auth.username') }}</label>
        <input id="auth-username" v-model="username" type="text" :placeholder="t('auth.username')" required autocomplete="username" />
      </div>
      <div class="field">
        <label for="auth-email">{{ t('auth.email') }}</label>
        <input id="auth-email" v-model="email" type="email" :placeholder="t('auth.email')" required autocomplete="email" />
      </div>
      <div class="field">
        <label for="auth-password">{{ t('auth.password') }}</label>
        <input id="auth-password" v-model="password" type="password" :placeholder="t('auth.password')" required autocomplete="current-password" />
      </div>

      <p v-if="errorMsg" class="error" role="alert">{{ errorMsg }}</p>

      <button type="submit" class="btn btn-primary" :disabled="submitting">
        {{ submitting ? t('auth.processing') : (mode === 'login' ? t('auth.login') : t('auth.register')) }}
      </button>
    </form>

    <p class="toggle">
      {{ mode === 'login' ? t('auth.noAccount') : t('auth.haveAccount') }}
      <a href="#" @click.prevent="mode = mode === 'login' ? 'register' : 'login'">
        {{ mode === 'login' ? t('auth.register') : t('auth.login') }}
      </a>
    </p>
  </div>
</template>

<style scoped>
.auth-page { max-width: 360px; margin: var(--page-pad-top) auto 0; }
.auth-form { display: flex; flex-direction: column; gap: 12px; margin-top: var(--space-md); }
.auth-form .field { display: flex; flex-direction: column; gap: var(--space-xs); }
.auth-form label { font-size: 13px; color: var(--muted); }
.auth-form input { width: 100%; }
.error { color: var(--down); font-size: 13px; }
.toggle { text-align: center; margin-top: var(--space-sm); font-size: 14px; color: var(--muted); }
@media (max-width: 640px) {
  .auth-page { margin: var(--space-md) auto 0; }
}
</style>
