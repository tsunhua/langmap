<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'
import api from '@/api/client'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { LogOut, FileText, GitBranch, BookOpen, ThumbsUp } from 'lucide-vue-next'

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

interface ActivityItem {
  type: string
  description: string
  ref_id: string
  created_at: string
}

const profile = ref<UserProfile | null>(null)
const activity = ref<ActivityItem[]>([])
const loading = ref(true)
const loadError = ref('')

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime()
  const min = Math.floor(diff / 60000)
  if (min < 1) return t('components.justNow')
  if (min < 60) return t('components.minutesAgo', { count: min })
  const hr = Math.floor(min / 60)
  if (hr < 24) return t('components.hoursAgo', { count: hr })
  return t('components.daysAgo', { count: Math.floor(hr / 24) })
}

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

function activityIcon(type: string) {
  switch (type) {
    case 'expression': return FileText
    case 'mapping': return GitBranch
    case 'handbook': return BookOpen
    case 'vote': return ThumbsUp
    default: return FileText
  }
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
    activity.value = data.data.activity
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

      <section class="profile-activity">
        <h2>{{ t('profile.recentActivity') }}</h2>
        <EmptyState v-if="activity.length === 0" :message="t('profile.noActivity')" />
        <ul v-else class="activity-list">
          <li v-for="(item, i) in activity" :key="i" class="activity-item">
            <component :is="activityIcon(item.type)" :size="14" class="activity-icon" aria-hidden="true" />
            <span class="activity-desc">{{ item.description }}</span>
            <span class="activity-time">{{ timeAgo(item.created_at) }}</span>
          </li>
        </ul>
      </section>
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

.profile-activity h2 {
  font-size: 18px;
  font-weight: 600;
  letter-spacing: -0.01em;
  margin-bottom: 14px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--border);
}

.activity-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--border);
  font-size: 14px;
}
.activity-item:last-child { border-bottom: none; }

.activity-icon {
  flex-shrink: 0;
  color: var(--muted);
}

.activity-desc {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.activity-time {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--muted);
  white-space: nowrap;
}

@media (max-width: 640px) {
  .profile-page { margin-top: var(--space-md); }
  .activity-desc { white-space: normal; }
}
</style>
