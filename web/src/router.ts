import { createRouter, createWebHistory, type RouteLocationNormalized } from 'vue-router'
import { getExpression } from './api/expressions'
import { expressionPath, mapLensPath } from './utils/expressionUrl'

const NUMERIC_ID = /^[1-9]\d*$/

// Legacy numeric urls (/mapping/123) predate the stable text keys; resolve the
// id once and canonicalize to the text-key path. When the id no longer exists
// (e.g. after an id renumbering migration) proceed to the page, which shows
// its link-expired state.
function legacyIdRedirect(base: 'mapping' | 'map') {
  return async (to: RouteLocationNormalized) => {
    const raw = to.params.id
    const id = Array.isArray(raw) ? raw[0] : raw
    if (!id || !NUMERIC_ID.test(id)) return true
    try {
      const detail = await getExpression(id)
      const expression = detail.expression
      const path = base === 'mapping'
        ? expressionPath(expression.lang_code, expression.text, expression.homograph_index)
        : mapLensPath(expression.lang_code, expression.text, expression.homograph_index)
      return { path, replace: true }
    } catch {
      return true
    }
  }
}

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash }
    if (to.path !== from.path) return { top: 0 }
    return false
  },
  routes: [
    { path: '/',                  component: () => import('./pages/HomeFeed.vue') },
    { path: '/mapping/:lang/:text(.+)', component: () => import('./pages/MappingDetail.vue') },
    { path: '/mapping/:id',       component: () => import('./pages/MappingDetail.vue'), beforeEnter: legacyIdRedirect('mapping') },
    { path: '/contribute',        component: () => import('./pages/Contribute.vue') },
    { path: '/translate',         component: () => import('./pages/ExpressionTranslation.vue') },
    { path: '/ui-translation',    component: () => import('./pages/UiTranslationWorkbench.vue') },
    { path: '/ui-translation/:code', component: () => import('./pages/UiTranslationWorkbench.vue') },
    { path: '/handbooks',         component: () => import('./pages/HandbookList.vue') },
    { path: '/handbooks/:id',      component: () => import('./pages/HandbookView.vue') },
    { path: '/handbooks/:id/edit', component: () => import('./pages/HandbookEdit.vue') },
    { path: '/handbook/:id', redirect: to => `/handbooks/${to.params.id}` },
    { path: '/handbook/:id/edit', redirect: to => `/handbooks/${to.params.id}/edit` },
    { path: '/map',              redirect: '/' },
    { path: '/map/:lang/:text(.+)', component: () => import('./pages/MapLens.vue') },
    { path: '/map/:id',          component: () => import('./pages/MapLens.vue'), beforeEnter: legacyIdRedirect('map') },
    { path: '/languages',         component: () => import('./pages/LanguageList.vue') },
    { path: '/languages/:code',   component: () => import('./pages/LanguageDetail.vue') },
    { path: '/language/:code',    redirect: to => `/languages/${to.params.code}` },
    { path: '/search',            component: () => import('./pages/Search.vue') },
    { path: '/auth',              component: () => import('./pages/Auth.vue') },
    { path: '/profile', component: () => import('./pages/Profile.vue') },
    { path: '/:pathMatch(.*)*',  component: () => import('./pages/NotFound.vue') },
  ],
})

export default router
