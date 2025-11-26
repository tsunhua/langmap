import { createRouter, createWebHistory } from 'vue-router'
import Search from '../pages/Search.vue'
import Detail from '../pages/Detail.vue'
import CreateExpression from '../pages/CreateExpression.vue'

const routes = [
  { path: '/', name: 'home', component: Search },
  { path: '/expressions/new', name: 'create', component: CreateExpression },
  { path: '/expressions/:id', name: 'detail', component: Detail, props: true }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
