# User Profile Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a user profile page at `/profile` showing basic account info, logout button, and recent activity feed; move logout from TopNav into this page.

**Architecture:** Backend adds `GET /api/v2/users/me` endpoint (UNION query across activity tables). Frontend adds `Profile.vue` page, updates router, and modifies TopNav to link username to profile instead of showing logout.

**Tech Stack:** Vue 3 + TypeScript + Pinia + Vue Router + vue-i18n, Hono + Cloudflare Workers + D1, scoped CSS with atlas.css tokens, lucide-vue-next icons.

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `backend/src/routes/users.ts` | Create | New route module with `GET /me` |
| `backend/src/routes/index.ts` | Modify | Register `/users` route |
| `backend/tests/users.test.ts` | Create | Integration tests for `/users/me` |
| `web/src/pages/Profile.vue` | Create | Profile page component |
| `web/src/router.ts` | Modify | Add `/profile` route |
| `web/src/components/nav/TopNav.vue` | Modify | Username → link, remove logout |
| `web/src/locales/en.ts` | Modify | Add `profile` + `activity` i18n keys |

---

### Task 1: Backend — Create users route module

**Files:**
- Create: `backend/src/routes/users.ts`

- [ ] **Step 1: Create the users route file**

```typescript
import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { success, internalError } from '../utils/response';
import type { Bindings, Variables } from '../types';

interface UserProfileRow {
  id: number;
  username: string;
  email: string;
  role: string;
  created_at: string;
}

interface ActivityRow {
  type: string;
  description: string;
  ref_id: string;
  created_at: string;
}

const users = new Hono<{ Bindings: Bindings; Variables: Variables }>();

const ACTIVITY_QUERY = `
SELECT 'expression' AS type,
       'Added expression "' || e.text || '" (' || e.lang_code || ')' AS description,
       e.id AS ref_id,
       e.created_at
FROM expressions e
WHERE e.created_by = ?
UNION ALL
SELECT 'mapping' AS type,
       'Mapped "' || ea.text || '" → "' || eb.text || '"' AS description,
       ee.id AS ref_id,
       ee.created_at
FROM expression_edges ee
JOIN expressions ea ON ee.expression_a_id = ea.id
JOIN expressions eb ON ee.expression_b_id = eb.id
WHERE ee.created_by = ?
UNION ALL
SELECT 'handbook' AS type,
       'Created handbook "' || h.title || '"' AS description,
       h.id AS ref_id,
       h.created_at
FROM handbooks h
WHERE h.user_id = ?
UNION ALL
SELECT 'vote' AS type,
       CASE WHEN v.vote = 1 THEN 'Upvoted' ELSE 'Downvoted' END || ' a mapping' AS description,
       v.target_id AS ref_id,
       v.created_at
FROM votes v
WHERE v.user_id = ?
ORDER BY created_at DESC
LIMIT 20
`;

users.get('/me', requireAuth, async (c) => {
  try {
    const currentUser = c.get('user');
    const userId = currentUser!.id;

    const user = await c.env.DB.prepare(
      'SELECT id, username, email, role, created_at FROM users WHERE id = ?'
    ).bind(userId).first<UserProfileRow>();

    if (!user) {
      return internalError(c);
    }

    const { results: activity } = await c.env.DB.prepare(ACTIVITY_QUERY)
      .bind(userId, userId, userId, userId)
      .all<ActivityRow>();

    return success(c, { user, activity });
  } catch (error: any) {
    console.error('Users/me error:', error);
    return internalError(c);
  }
});

export default users;
```

- [ ] **Step 2: Register the route in index.ts**

Modify `backend/src/routes/index.ts` — add import and route:

```typescript
import users from './users';
// ... existing imports
api.route('/users', users);
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/routes/users.ts backend/src/routes/index.ts
git commit -m "feat: add GET /api/v2/users/me endpoint"
```

---

### Task 2: Backend — Integration tests

**Files:**
- Create: `backend/tests/users.test.ts`

- [ ] **Step 1: Write integration tests**

```typescript
import { describe, expect, it } from 'vitest';

const BASE_URL = 'http://127.0.0.1:8788';

describe('v2 users', () => {
  it('returns 401 without auth token', async () => {
    const response = await fetch(`${BASE_URL}/api/v2/users/me`);
    expect(response.status).toBe(401);
  });

  it('returns user profile and activity for authenticated user', async () => {
    const unique = Math.random().toString(36).slice(2, 10);

    const registerResponse = await fetch(`${BASE_URL}/api/v2/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        username: `tester-${unique}`,
        email: `${unique}@example.com`,
        password: 'pass1234',
      }),
    });
    expect(registerResponse.status).toBe(201);
    const { data: { token } } = await registerResponse.json();

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(profileResponse.status).toBe(200);
    const body = await profileResponse.json();
    expect(body.success).toBe(true);
    expect(body.data.user.username).toBe(`tester-${unique}`);
    expect(body.data.user.email).toBe(`${unique}@example.com`);
    expect(body.data.user.role).toBe('user');
    expect(body.data.user.created_at).toBeDefined();
    expect(Array.isArray(body.data.activity)).toBe(true);
  });

  it('returns activity after creating contributions', async () => {
    const unique = Math.random().toString(36).slice(2, 10);

    const registerResponse = await fetch(`${BASE_URL}/api/v2/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        username: `tester-${unique}`,
        email: `${unique}@example.com`,
        password: 'pass1234',
      }),
    });
    const { data: { token } } = await registerResponse.json();

    await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        expressions: [
          { lang_code: 'cmn', text: `測試-${unique}` },
          { lang_code: 'eng', text: `test-${unique}` },
        ],
      }),
    });

    const profileResponse = await fetch(`${BASE_URL}/api/v2/users/me`, {
      headers: { authorization: `Bearer ${token}` },
    });
    const body = await profileResponse.json();
    expect(body.success).toBe(true);
    expect(body.data.activity.length).toBeGreaterThanOrEqual(1);
    expect(body.data.activity[0].type).toBeDefined();
    expect(body.data.activity[0].description).toBeDefined();
    expect(body.data.activity[0].created_at).toBeDefined();
  });
});
```

- [ ] **Step 2: Run tests**

```bash
cd backend && npx vitest run tests/users.test.ts
```

- [ ] **Step 3: Commit**

```bash
git add backend/tests/users.test.ts
git commit -m "test: add integration tests for GET /users/me"
```

---

### Task 3: Frontend — i18n keys

**Files:**
- Modify: `web/src/locales/en.ts`

- [ ] **Step 1: Add profile and activity i18n keys**

Add after the `translate` block (before the closing `} as const`):

```typescript
profile: {
  title: 'Profile',
  email: 'Email',
  role: 'Role',
  memberSince: 'Member since',
  signOut: 'Sign out',
  recentActivity: 'Recent activity',
  noActivity: 'No activity yet',
  loadFailed: 'Unable to load profile',
  mustLogin: 'Please sign in to view your profile',
},
activity: {
  expression: 'Added expression',
  mapping: 'Mapped',
  handbook: 'Created handbook',
  voteUp: 'Upvoted a mapping',
  voteDown: 'Downvoted a mapping',
},
```

- [ ] **Step 2: Commit**

```bash
git add web/src/locales/en.ts
git commit -m "feat: add profile and activity i18n keys"
```

---

### Task 4: Frontend — Profile page

**Files:**
- Create: `web/src/pages/Profile.vue`

- [ ] **Step 1: Create the Profile.vue page**

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'
import api from '@/api/client'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { LogOut, FileText, GitBranch, BookOpen, ThumbsUp, ThumbsDown } from 'lucide-vue-next'

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
```

- [ ] **Step 2: Commit**

```bash
git add web/src/pages/Profile.vue
git commit -m "feat: add Profile page component"
```

---

### Task 5: Frontend — Router and TopNav

**Files:**
- Modify: `web/src/router.ts`
- Modify: `web/src/components/nav/TopNav.vue`

- [ ] **Step 1: Add /profile route to router.ts**

Add before the catch-all route:

```typescript
{ path: '/profile', component: () => import('./pages/Profile.vue') },
```

- [ ] **Step 2: Modify TopNav desktop — replace username + logout with link**

In `TopNav.vue`, replace the desktop auth block (lines 107-111):

```diff
-       <template v-if="auth.user">
-         <span class="user-badge auth-inline">{{ auth.user.username }}</span>
-         <button class="btn btn-ghost btn-sm auth-inline" @click="auth.logout()">{{ t('nav.signOut') }}</button>
-       </template>
-       <router-link v-else to="/auth" class="btn btn-ghost btn-sm auth-inline">{{ t('nav.signIn') }}</router-link>
+       <router-link v-if="auth.user" to="/profile" class="user-badge auth-inline">{{ auth.user.username }}</router-link>
+       <router-link v-else to="/auth" class="btn btn-ghost btn-sm auth-inline">{{ t('nav.signIn') }}</router-link>
```

- [ ] **Step 3: Modify TopNav mobile drawer — replace username + logout with link**

In `TopNav.vue`, replace the drawer auth block (lines 147-151):

```diff
-           <template v-if="auth.user">
-             <span class="user-badge">{{ auth.user.username }}</span>
-             <button class="btn btn-ghost" @click="auth.logout()">{{ t('nav.signOut') }}</button>
-           </template>
-           <router-link v-else to="/auth" class="btn btn-ghost">{{ t('nav.signIn') }}</router-link>
+           <router-link v-if="auth.user" to="/profile" class="user-badge">{{ auth.user.username }}</router-link>
+           <router-link v-else to="/auth" class="btn btn-ghost">{{ t('nav.signIn') }}</router-link>
```

- [ ] **Step 4: Add hover style for .user-badge as link**

In TopNav.vue `<style scoped>`, update `.user-badge`:

```diff
  .user-badge {
    font-family: var(--mono); font-size: 13px;
    color: var(--muted);
+   text-decoration: none;
+   cursor: pointer;
+   transition: color 0.12s;
+ }
+ a.user-badge:hover {
+   color: var(--fg);
  }
```

- [ ] **Step 5: Commit**

```bash
git add web/src/router.ts web/src/components/nav/TopNav.vue
git commit -m "feat: link username to profile page, remove logout from nav"
```

---

### Task 6: Build verification

**Files:** None (verification only)

- [ ] **Step 1: Build frontend**

```bash
cd /home/ubuntu/floating-cloud/code/langmap/web && npm run build
```

Expected: Build succeeds with no errors.

- [ ] **Step 2: Run backend tests**

```bash
cd /home/ubuntu/floating-cloud/code/langmap/backend && npx vitest run tests/users.test.ts
```

Expected: All 3 tests pass.

- [ ] **Step 3: Final commit if any fixes needed**
