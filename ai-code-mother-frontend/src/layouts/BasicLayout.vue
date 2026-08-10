<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import GlobalHeader from '@/components/GlobalHeader.vue'
import GlobalFooter from '@/components/GlobalFooter.vue'

const route = useRoute()

const isHomePage = computed(() => route.name === 'home')
const isChatPage = computed(() => route.name === 'appChat')
const hideFooter = computed(() => Boolean(route.meta.hideFooter) || isChatPage.value)
const contentClass = computed(() => ({
  'basic-layout-content': true,
  'is-home': isHomePage.value,
  'is-chat': isChatPage.value,
}))
</script>

<template>
  <a-layout class="basic-layout">
    <GlobalHeader />
    <a-layout-content :class="contentClass">
      <router-view />
    </a-layout-content>
    <GlobalFooter v-if="!hideFooter" />
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

.basic-layout-content.is-home {
  padding: 0;
  background: transparent;
}

.basic-layout-content.is-chat {
  padding: 0;
  background: #f7f8fa;
}

@media (max-width: 768px) {
  .basic-layout-content {
    padding: 16px;
  }

  .basic-layout-content.is-chat {
    padding: 0;
  }
}
</style>
