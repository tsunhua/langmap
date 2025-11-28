import { createRouter, createWebHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import Search from '../pages/Search.vue'
import Detail from '../pages/Detail.vue'

const routes = [
  { path: '/', name: 'home', component: Home },
  { path: '/search', name: 'search', component: Search },
  { path: '/expressions/:id', name: 'detail', component: Detail, props: true }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router