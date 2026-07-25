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
      await auth.login(username.value, password.value)
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
      <input v-model="username" type="text" placeholder="用戶名" required />
      <input v-if="mode === 'register'" v-model="email" type="email" placeholder="電郵" required />
      <input v-model="password" type="password" placeholder="密碼" required />

      <p v-if="errorMsg" class="error">{{ errorMsg }}</p>

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
.auth-page { max-width: 360px; margin: 60px auto; }
.auth-form { display: flex; flex-direction: column; gap: 12px; margin-top: 20px; }
.auth-form input { width: 100%; }
.error { color: #A03030; font-size: 13px; }
.toggle { text-align: center; margin-top: 16px; font-size: 14px; color: #4A6FA5; }
</style>
