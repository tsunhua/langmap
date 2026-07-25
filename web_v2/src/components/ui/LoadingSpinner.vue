<template>
  <div class="spinner-wrap">
    <div class="spinner"></div>
  </div>
</template>

<style scoped>
.spinner-wrap { display: flex; justify-content: center; padding: 40px; }
.spinner {
  width: 24px; height: 24px;
  border: 2px solid #EDE5D8;
  border-top-color: #8B4513;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
