import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import AboutUs from '../pages/AboutUs.vue'
import Login from '../pages/Login.vue'
import Register from '../pages/Register.vue'
import UserProfile from '../pages/UserProfile.vue'
import Search from '../pages/Search.vue'
import Detail from '../pages/Detail.vue'
import Policies from '../pages/Policies.vue'
import TranslateInterface from '../pages/TranslateInterface.vue'
import EmailVerification from '../pages/EmailVerification.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/about',
    name: 'AboutUs',
    component: AboutUs
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/register',
    name: 'Register',
    component: Register
  },
  {
    path: '/profile',
    name: 'UserProfile',
    component: UserProfile,
    meta: { requiresAuth: true }
  },
  {
    path: '/search',
    name: 'Search',
    component: Search
  },
  {
    path: '/detail/:id',
    name: 'Detail',
    component: Detail,
    props: true
  },
  {
    path: '/policies',
    name: 'Policies',
    component: Policies
  },
  {
    path: '/verify-email',
    name: 'EmailVerification',
    component: EmailVerification
  },
  {
    path: '/translate-interface',
    name: 'TranslateInterface',
    component: TranslateInterface
  },
  {
    path: '/collections',
    name: 'Collections',
    component: () => import('../pages/Collections.vue')
  },
  {
    path: '/collections/:id',
    name: 'CollectionDetail',
    component: () => import('../pages/CollectionDetail.vue')
  },
  {
    path: '/create-expression',
    name: 'CreateExpression',
    component: () => import('../pages/CreateExpression.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const isAuthenticated = !!localStorage.getItem('authToken')

  if (to.meta.requiresAuth && !isAuthenticated) {
    next('/login')
  } else {
    next()
  }
})

export default router