# User Profile Page Design

## Goal

Add a user profile page (`/profile`) that displays basic account info, a logout button, and a recent activity feed. Move logout from the top navigation bar into this page; the username in the nav becomes a link to the profile.

## Scope

### In scope

- New backend endpoint `GET /api/v2/users/me` returning user info + recent activity
- New frontend page `Profile.vue` at route `/profile`
- TopNav username becomes `<router-link to="/profile">`
- Logout button removed from TopNav (desktop + mobile drawer)
- i18n keys for the profile page

### Out of scope

- Profile editing (username, email, password change)
- Avatar / profile picture
- Public user profiles (`/user/:id`)
- Activity pagination (limit to 20 items)

## Backend

### Endpoint: `GET /api/v2/users/me`

- Auth: `requireAuth`
- Response shape:

```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "alice",
      "email": "alice@example.com",
      "role": "user",
      "created_at": "2026-08-17T10:00:00Z"
    },
    "activity": [
      {
        "type": "expression",
        "description": "Added expression \"hello\" (eng)",
        "ref_id": "01ABC...",
        "created_at": "2026-08-17T12:00:00Z"
      },
      {
        "type": "vote",
        "description": "Upvoted a mapping",
        "ref_id": "01XYZ...",
        "created_at": "2026-08-17T11:30:00Z"
      }
    ]
  }
}
```

### Activity query

Single SQL using `UNION ALL` across activity tables, ordered by `created_at DESC`, limited to 20 rows:

```sql
-- Expressions created by user
SELECT 'expression' AS type,
       'Added expression "' || e.text || '" (' || e.lang_code || ')' AS description,
       e.id AS ref_id,
       e.created_at
FROM expressions e
WHERE e.created_by = :userId

UNION ALL

-- Mappings (expression_edges) created by user
SELECT 'mapping' AS type,
       'Mapped "' || ea.text || '" → "' || eb.text || '"' AS description,
       ee.id AS ref_id,
       ee.created_at
FROM expression_edges ee
JOIN expressions ea ON ee.expression_a_id = ea.id
JOIN expressions eb ON ee.expression_b_id = eb.id
WHERE ee.created_by = :userId

UNION ALL

-- Handbooks created by user
SELECT 'handbook' AS type,
       'Created handbook "' || h.title || '"' AS description,
       h.id AS ref_id,
       h.created_at
FROM handbooks h
WHERE h.user_id = :userId

UNION ALL

-- Votes cast by user
SELECT 'vote' AS type,
       CASE WHEN v.vote = 1 THEN 'Upvoted' ELSE 'Downvoted' END || ' a mapping' AS description,
       v.target_id AS ref_id,
       v.created_at
FROM votes v
WHERE v.user_id = :userId

ORDER BY created_at DESC
LIMIT 20
```

### Route registration

Add to `backend/src/routes/index.ts`:

```typescript
import users from './users';
api.route('/users', users);
```

New file `backend/src/routes/users.ts` with a single `GET /me` handler using `requireAuth`.

## Frontend

### Route

Add to `router.ts`:

```typescript
{ path: '/profile', component: () => import('./pages/Profile.vue') },
```

Place before the catch-all `/:pathMatch(.*)*`.

### Page: `Profile.vue`

Layout:

```
┌─────────────────────────────────┐
│ ← Back                          │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Username                    │ │
│ │ email@example.com           │ │
│ │ Role: user                  │ │
│ │ Member since: Aug 2026      │ │
│ │                             │ │
│ │ [Sign out]                  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Recent activity                 │
│ ┌─────────────────────────────┐ │
│ │ 📝 Added expression...      │ │
│ │ 🗺️ Mapped...               │ │
│ │ 📖 Created handbook...      │ │
│ │ ⬆️ Upvoted a mapping        │ │
│ └─────────────────────────────┘ │
│                                 │
│ (empty state if no activity)    │
└─────────────────────────────────┘
```

- Unauthenticated users: redirect to `/auth`
- Loading state while fetching
- Error state if fetch fails
- Logout calls `auth.logout()` then redirects to `/`
- Activity items: icon (lucide) + description + relative time
- Activity icons: `FileText` for expression, `GitBranch` for mapping, `BookOpen` for handbook, `ThumbsUp`/`ThumbsDown` for vote

### TopNav changes

**Desktop (`.right-group`):**

```diff
- <span class="user-badge auth-inline">{{ auth.user.username }}</span>
- <button class="btn btn-ghost btn-sm auth-inline" @click="auth.logout()">{{ t('nav.signOut') }}</button>
+ <router-link v-if="auth.user" to="/profile" class="user-badge auth-inline">{{ auth.user.username }}</router-link>
```

**Mobile drawer (`.drawer-foot`):**

```diff
- <span class="user-badge">{{ auth.user.username }}</span>
- <button class="btn btn-ghost" @click="auth.logout()">{{ t('nav.signOut') }}</button>
+ <router-link v-if="auth.user" to="/profile" class="user-badge">{{ auth.user.username }}</router-link>
```

The `.user-badge` class gets `text-decoration: none` and a hover style to indicate it's clickable.

### API method

Add to `web/src/api/` (or inline in Profile.vue):

```typescript
api.get('/users/me')
```

### i18n keys

Add to `en.ts` under a new `profile` namespace:

```typescript
profile: {
  title: 'Profile',
  back: 'Back',
  email: 'Email',
  role: 'Role',
  memberSince: 'Member since',
  signOut: 'Sign out',
  recentActivity: 'Recent activity',
  noActivity: 'No activity yet',
  loadFailed: 'Unable to load profile',
}
```

Activity type labels:

```typescript
activity: {
  expression: 'Added expression "{text}" ({lang})',
  mapping: 'Mapped "{a}" → "{b}"',
  handbook: 'Created handbook "{title}"',
  voteUp: 'Upvoted a mapping',
  voteDown: 'Downvoted a mapping',
}
```

## Styling

Follow existing `atlas.css` token system and scoped CSS pattern:

- Profile card: `.card` style with `var(--surface)` background
- User info: mono font for username (`.user-badge` style), muted text for metadata
- Logout button: `.btn` with red/warning color (using `var(--down)`)
- Activity list: similar to feed items, with icon + text + relative time
- Activity icons: 16px lucide icons, muted color
- Responsive: single column, max-width ~480px centered (like Auth page)

## Files to create/modify

| File | Action |
|------|--------|
| `backend/src/routes/users.ts` | Create — new route module |
| `backend/src/routes/index.ts` | Modify — register `/users` route |
| `web/src/pages/Profile.vue` | Create — profile page component |
| `web/src/router.ts` | Modify — add `/profile` route |
| `web/src/components/nav/TopNav.vue` | Modify — username → link, remove logout |
| `web/src/locales/en.ts` | Modify — add `profile` + `activity` keys |
