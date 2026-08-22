<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const isHomePage = computed(() => route.name === 'home')
const isAdminPage = computed(() => String(route.path).startsWith('/admin/'))
const isUserInfoPage = computed(() => route.name === 'userInfo')
const isAuthPage = computed(() => route.name === 'userLogin' || route.name === 'userRegister')
const isMintUserPage = computed(() => isUserInfoPage.value || isAuthPage.value)
</script>

<template>
  <a-layout-footer
    class="global-footer"
    :class="{ 'is-home': isHomePage, 'is-admin': isAdminPage, 'is-user-info': isMintUserPage }"
  >
    <div class="footer-content">
      <span>AI 零代码应用生成平台</span>
      <a href="https://github.com" target="_blank" rel="noopener noreferrer">GitHub</a>
      <span>Copyright © 2026 AI Code Mother</span>
    </div>
  </a-layout-footer>
</template>

<style scoped>
.global-footer {
  text-align: center;
  background: #f5f5f5;
  color: rgba(0, 0, 0, 0.45);
  padding: 16px 24px;
}

.global-footer.is-home {
  background: #f0faf5;
  border-top: 1px solid rgba(136, 216, 176, 0.18);
}

.global-footer.is-admin {
  background: #eef6fc;
  border-top: 1px solid rgba(129, 212, 250, 0.22);
}

.global-footer.is-user-info {
  background: #f7f6f4;
  border-top: 1px solid rgba(136, 216, 176, 0.18);
}

.global-footer.is-admin .footer-content a:hover {
  color: #6bb5f0;
}

.global-footer.is-user-info .footer-content a:hover {
  color: #5bc4a0;
}

.footer-content {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: 12px 24px;
  font-size: 14px;
}

.footer-content a {
  color: rgba(0, 0, 0, 0.65);
}

.footer-content a:hover {
  color: #5bc4a0;
}
</style>
