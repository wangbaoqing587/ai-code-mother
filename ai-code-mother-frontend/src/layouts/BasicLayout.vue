<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import GlobalHeader from '@/components/GlobalHeader.vue'
import GlobalFooter from '@/components/GlobalFooter.vue'

const route = useRoute()

const isHomePage = computed(() => route.name === 'home')
const isMyWorksPage = computed(() => route.name === 'myWorks')
const isChatPage = computed(() => route.name === 'appChat')
const isAdminPage = computed(() => String(route.path).startsWith('/admin/'))
const isUserInfoPage = computed(() => route.name === 'userInfo' || route.name === 'userProfile')
const isAppEditPage = computed(() => route.name === 'appEdit')
const isAuthPage = computed(() => route.name === 'userLogin' || route.name === 'userRegister')
const hideFooter = computed(() => Boolean(route.meta.hideFooter) || isChatPage.value)
const contentClass = computed(() => ({
  'basic-layout-content': true,
  'is-home': isHomePage.value,
  'is-my-works': isMyWorksPage.value,
  'is-chat': isChatPage.value,
  'is-admin': isAdminPage.value,
  'is-user-info': isUserInfoPage.value || isAuthPage.value || isAppEditPage.value,
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

.basic-layout-content.is-home,
.basic-layout-content.is-my-works {
  padding: 0;
  background: transparent;
}

.basic-layout-content.is-admin {
  padding: 0;
  background: transparent;
}

.basic-layout-content.is-user-info {
  padding: 0;
  background: transparent;
}

.basic-layout-content.is-chat {
  padding: 0;
  background: linear-gradient(180deg, #f5fbf8 0%, #faf9f7 100%);
}

@media (max-width: 768px) {
  .basic-layout-content {
    padding: 16px;
  }

  .basic-layout-content.is-chat,
  .basic-layout-content.is-my-works {
    padding: 0;
  }
}
</style>
