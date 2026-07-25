import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/',                  component: () => import('./pages/HomeFeed.vue') },
    { path: '/mapping/:id',       component: () => import('./pages/MappingDetail.vue') },
    { path: '/contribute',        component: () => import('./pages/Contribute.vue') },
    { path: '/handbooks',         component: () => import('./pages/HandbookList.vue') },
    { path: '/handbook/:id',      component: () => import('./pages/HandbookView.vue') },
    { path: '/handbook/:id/edit', component: () => import('./pages/HandbookEdit.vue') },
    { path: '/map',              redirect: '/' },
    { path: '/map/:id',          component: () => import('./pages/MapLens.vue') },
    { path: '/languages',         component: () => import('./pages/LanguageList.vue') },
    { path: '/language/:code',    component: () => import('./pages/LanguageDetail.vue') },
    { path: '/search',            component: () => import('./pages/Search.vue') },
    { path: '/auth',              component: () => import('./pages/Auth.vue') },
    { path: '/:pathMatch(.*)*',  component: () => import('./pages/NotFound.vue') },
  ],
})

export default router
