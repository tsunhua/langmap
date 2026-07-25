<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const auth = useAuthStore()
const searchQuery = ref('')

function onSearch() {
  if (searchQuery.value.trim()) {
    window.location.href = `/search?q=${encodeURIComponent(searchQuery.value)}`
  }
}
</script>

<template>
  <header class="appbar">
    <router-link to="/" class="brand">
      lang<span class="em">map</span>
    </router-link>

    <nav class="appnav">
      <router-link to="/" :class="{ on: route.path === '/' }">首頁</router-link>
      <router-link to="/languages" :class="{ on: route.path.startsWith('/language') }">語言</router-link>
      <router-link to="/handbooks" :class="{ on: route.path.startsWith('/handbook') }">手冊</router-link>
      <router-link to="/search" :class="{ on: route.path === '/search' }">搜尋</router-link>
    </nav>

    <div class="top-search">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="搜尋詞句…"
        @keydown.enter="onSearch"
      />
    </div>

    <router-link to="/contribute" class="btn btn-primary btn-sm">+ 新增映射</router-link>

    <template v-if="auth.user">
      <span class="lang-switch">{{ auth.user.username }}</span>
      <button class="btn btn-ghost btn-sm" @click="auth.logout()">登出</button>
    </template>
    <router-link v-else to="/auth" class="btn btn-ghost btn-sm">登入</router-link>
  </header>
</template>

<style scoped>
.brand {
  font-family: "Noto Serif", serif;
  font-weight: 700;
  font-size: 18px;
  color: #1A1A1A;
  text-decoration: none;
}
.brand .em {
  font-family: "IBM Plex Mono", monospace;
  font-size: 11px;
  background: #8B4513;
  color: #fff;
  padding: 1px 4px;
  border-radius: 3px;
  margin-left: 2px;
  vertical-align: super;
}
.appnav { display: flex; gap: 12px; margin-left: 16px; }
.appnav a {
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #4A6FA5;
  text-decoration: none;
  padding: 4px 0;
}
.appnav a.on { color: #1A1A1A; font-weight: 600; }
.top-search {
  margin-left: auto;
  position: relative;
}
.top-search input {
  width: 180px;
  height: 30px;
  padding: 0 10px;
  font-size: 13px;
  border: 1px solid #EDE5D8;
  border-radius: 4px;
  background: #fff;
}
</style>
