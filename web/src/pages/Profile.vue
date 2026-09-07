<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'
import api from '@/api/client'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { LogOut } from 'lucide-vue-next'

const router = useRouter()
const auth = useAuthStore()
const { t } = useI18n()

interface UserProfile {
  id: number
  username: string
  email: string
  role: string
  created_at: string
}

const profile = ref<UserProfile | null>(null)
const loading = ref(true)
const loadError = ref('')

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

function doLogout() {
  auth.logout()
  router.push('/')
}

onMounted(async () => {
  if (!auth.user) {
    loading.value = false
    return
  }
  try {
    const { data } = await api.get('/users/me')
    profile.value = data.data.user
  } catch (e: any) {
    loadError.value = e.response?.data?.message || t('profile.loadFailed')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="profile-page">
    <LoadingSpinner v-if="loading" />

    <div v-else-if="!auth.user" class="profile-auth-hint">
      <p>{{ t('profile.mustLogin') }}</p>
      <router-link to="/auth" class="btn btn-primary">{{ t('nav.signIn') }}</router-link>
    </div>

    <div v-else-if="loadError" role="alert">
      <EmptyState :message="loadError" />
    </div>

    <template v-else-if="profile">
      <div class="profile-card">
        <h1 class="profile-name">{{ profile.username }}</h1>
        <dl class="profile-fields">
          <div class="profile-field">
            <dt>{{ t('profile.email') }}</dt>
            <dd>{{ profile.email }}</dd>
          </div>
          <div class="profile-field">
            <dt>{{ t('profile.role') }}</dt>
            <dd>{{ profile.role }}</dd>
          </div>
          <div class="profile-field">
            <dt>{{ t('profile.memberSince') }}</dt>
            <dd>{{ formatDate(profile.created_at) }}</dd>
          </div>
        </dl>
        <button class="btn btn-danger" @click="doLogout">
          <LogOut :size="14" aria-hidden="true" /> {{ t('profile.signOut') }}
        </button>
      </div>

    </template>
  </div>
</template>

<style scoped>
.profile-page {
  max-width: 480px;
  margin: 0 auto;
  padding: var(--page-pad-top) 28px var(--page-pad-bottom);
}

.profile-auth-hint {
  text-align: center;
  padding: var(--space-xxl) var(--space-md);
  color: var(--muted);
}
.profile-auth-hint .btn { margin-top: var(--space-md); }

.profile-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: var(--space-lg);
  margin-bottom: var(--space-lg);
}

.profile-name {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.02em;
  margin-bottom: var(--space-md);
}

.profile-fields {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  margin-bottom: var(--space-lg);
}

.profile-field {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  font-size: 14px;
  padding-bottom: var(--space-xs);
  border-bottom: 1px solid var(--border);
}
.profile-field:last-child { border-bottom: none; }
.profile-field dt { color: var(--muted); }
.profile-field dd { font-weight: 500; }

.btn-danger {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: var(--mono);
  font-size: 13px;
  color: var(--down);
  background: transparent;
  border: 1px solid color-mix(in oklch, var(--down) 30%, var(--border));
  border-radius: var(--r);
  padding: 6px 14px;
  cursor: pointer;
  min-height: 44px;
}
.btn-danger:hover {
  background: color-mix(in oklch, var(--down) 8%, var(--surface));
}
.btn-danger:focus-visible {
  outline: 2px solid var(--down);
  outline-offset: 2px;
}

@media (max-width: 768px) {
  .profile-page { padding-left: 20px; padding-right: 20px; }
}
@media (max-width: 640px) {
  .profile-page { margin-top: var(--space-md); padding-left: 16px; padding-right: 16px; }
}
</style>
