import { createRouter, createWebHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import Search from '../pages/Search.vue'
import Detail from '../pages/Detail.vue'
import Login from '../pages/Login.vue'
import Register from '../pages/Register.vue'
import UserProfile from '../pages/UserProfile.vue'
import AboutUs from '../pages/AboutUs.vue'
import Policies from '../pages/Policies.vue'

const routes = [
  { path: '/', name: 'home', component: Home },
  { path: '/search', name: 'search', component: Search },
  { path: '/expressions/:id', name: 'detail', component: Detail, props: true },
  { path: '/login', name: 'login', component: Login },
  { path: '/register', name: 'register', component: Register },
  { path: '/profile', name: 'profile', component: UserProfile },
  { path: '/about', name: 'about', component: AboutUs },
  { path: '/policies', name: 'policies', component: Policies }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 添加导航守卫来检查用户是否已认证
router.beforeEach((to, from, next) => {
  // 检查目标路由是否需要认证
  const requiresAuth = ['profile'].includes(to.name);
  
  // 获取认证状态
  const isAuthenticated = !!localStorage.getItem('authToken');
  
  // 如果路由需要认证但用户未认证，则重定向到登录页
  if (requiresAuth && !isAuthenticated) {
    next('/login');
  } else {
    next();
  }
});

export default router