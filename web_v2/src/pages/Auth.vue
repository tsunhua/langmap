<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

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
    errorMsg.value = e.response?.data?.message || '操作失敗'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <h1>{{ mode === 'login' ? '登入' : '註冊' }}</h1>

    <form class="auth-form" @submit.prevent="submit">
      <div v-if="mode === 'register'" class="field">
        <label for="auth-username">用戶名</label>
        <input id="auth-username" v-model="username" type="text" placeholder="用戶名" required autocomplete="username" />
      </div>
      <div class="field">
        <label for="auth-email">電郵</label>
        <input id="auth-email" v-model="email" type="email" placeholder="電郵" required autocomplete="email" />
      </div>
      <div class="field">
        <label for="auth-password">密碼</label>
        <input id="auth-password" v-model="password" type="password" placeholder="密碼" required autocomplete="current-password" />
      </div>

      <p v-if="errorMsg" class="error" role="alert">{{ errorMsg }}</p>

      <button type="submit" class="btn btn-primary" :disabled="submitting">
        {{ submitting ? '處理中…' : (mode === 'login' ? '登入' : '註冊') }}
      </button>
    </form>

    <p class="toggle">
      {{ mode === 'login' ? '沒有帳號？' : '已有帳號？' }}
      <a href="#" @click.prevent="mode = mode === 'login' ? 'register' : 'login'">
        {{ mode === 'login' ? '註冊' : '登入' }}
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
