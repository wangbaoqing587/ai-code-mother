<script setup lang="ts">
import GlobalHeader from '@/components/GlobalHeader.vue'
import GlobalFooter from '@/components/GlobalFooter.vue'
</script>

<template>
  <a-layout class="basic-layout">
    <GlobalHeader />
    <a-layout-content class="basic-layout-content">
      <router-view />
    </a-layout-content>
    <GlobalFooter />
  </a-layout>
</template>

<style scoped>
.basic-layout {
  min-height: 100vh;
}

.basic-layout-content {
  flex: 1;
  padding: 24px;
  background: #fff;
}

@media (max-width: 768px) {
  .basic-layout-content {
    padding: 16px;
  }
}
</style>
