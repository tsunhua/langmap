<template>
  <header class="appbar">
    <router-link to="/" class="brand">lang<span class="em">map</span></router-link>
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
</style>
