import { createRouter, createWebHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import Search from '../pages/Search.vue'
import Detail from '../pages/Detail.vue'
import Login from '../pages/Login.vue'
import Register from '../pages/Register.vue'
import UserProfile from '../pages/UserProfile.vue'

const routes = [
  { path: '/', name: 'home', component: Home },
  { path: '/search', name: 'search', component: Search },
  { path: '/expressions/:id', name: 'detail', component: Detail, props: true },
  { path: '/login', name: 'login', component: Login },
  { path: '/register', name: 'register', component: Register },
  { path: '/profile', name: 'profile', component: UserProfile }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router