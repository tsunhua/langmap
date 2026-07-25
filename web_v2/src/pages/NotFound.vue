<template>
  <div class="nf-page">
    <h1>404</h1>
    <p>頁面不存在</p>
    <router-link to="/" class="btn btn-ghost">回首頁</router-link>
  </div>
</template>

<style scoped>
.nf-page {
  text-align: center;
  padding: var(--page-pad-top) 20px var(--page-pad-bottom);
}
.nf-page h1 { font-size: 48px; margin-bottom: var(--space-sm); }
.nf-page p { color: oklch(0.52 0.010 200); margin-bottom: var(--space-md); }
</style>
