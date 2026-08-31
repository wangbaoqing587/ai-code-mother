<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import { checkAccess } from '@/access/checkAccess'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { menus } from '@/config/menus'
import { userLogout } from '@/api/userController'
import { iconLogo } from '@/assets'
import UserAvatar from '@/components/UserAvatar.vue'
import { getGreetingByTime } from '@/utils/time'
import { useLoginUserStore } from '@/stores/loginUser'

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()

const menuItems = computed(() =>
  menus
    .filter((item) => checkAccess(loginUserStore.loginUser, item.access))
    .map((item) => ({
      key: item.path,
      label: item.label,
    })),
)

const selectedKeys = computed(() => [route.path])
const isLogin = computed(() => !!loginUserStore.loginUser.id)
const isHomePage = computed(() => route.name === 'home')
const isMyWorksPage = computed(() => route.name === 'myWorks')
const isChatPage = computed(() => route.name === 'appChat')
const isAdminPage = computed(() => String(route.path).startsWith('/admin/'))
const isUserInfoPage = computed(() => route.name === 'userInfo')
const isAuthPage = computed(() => route.name === 'userLogin' || route.name === 'userRegister')
const isAppEditPage = computed(() => route.name === 'appEdit')
const isAdminUser = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)
const isAdminHeader = computed(() => isAdminPage.value || (isAppEditPage.value && isAdminUser.value))
const isMintUserPage = computed(() => isUserInfoPage.value || isAuthPage.value)
const isMintHeader = computed(
  () =>
    isHomePage.value ||
    isMyWorksPage.value ||
    isChatPage.value ||
    isMintUserPage.value ||
    (isAppEditPage.value && !isAdminUser.value),
)
const greetingText = computed(() => getGreetingByTime())

const onMenuClick: MenuProps['onClick'] = ({ key }) => {
  router.push(String(key))
}

function goLogin() {
  router.push('/user/login')
}

const onUserMenuClick: MenuProps['onClick'] = async ({ key }) => {
  if (key === 'userInfo') {
    await router.push('/user/info')
    return
  }
  if (key !== 'logout') {
    return
  }
  const res = await userLogout()
  if (res.data.code === 0) {
    loginUserStore.logoutLoginUser()
    message.success('已退出登录')
    await router.push('/user/login')
    return
  }
  message.error('退出失败：' + (res.data.message ?? '未知错误'))
}
</script>

<template>
  <a-layout-header class="global-header" :class="{ 'is-mint': isMintHeader, 'is-admin': isAdminHeader }">
    <div class="header-left">
      <img class="logo" :src="iconLogo" alt="logo" />
      <h1 class="title">星衍</h1>
    </div>
    <a-menu
      class="header-menu"
      mode="horizontal"
      :selected-keys="selectedKeys"
      :items="menuItems"
      @click="onMenuClick"
    />
    <div class="header-right">
      <a-dropdown
        v-if="isLogin"
        overlay-class-name="user-dropdown-overlay"
        :trigger="['hover']"
        placement="bottomRight"
      >
        <div class="user-info">
          <UserAvatar :src="loginUserStore.loginUser.userAvatar" />
          <span class="user-name">{{ loginUserStore.loginUser.userName }}</span>
          <span class="greeting">{{ greetingText }}</span>
        </div>
        <template #overlay>
          <a-menu class="user-dropdown-menu" @click="onUserMenuClick">
            <a-menu-item key="userInfo">
              <span class="user-dropdown-label">个人信息</span>
            </a-menu-item>
            <a-menu-item key="logout">
              <span class="user-dropdown-label">退出登录</span>
            </a-menu-item>
          </a-menu>
        </template>
      </a-dropdown>
      <a-button v-else type="primary" @click="goLogin">登录</a-button>
    </div>
  </a-layout-header>
</template>

<style scoped>
.global-header {
  display: flex;
  align-items: center;
  gap: 16px;
  height: 64px;
  padding: 0 24px;
  background: #fff;
  border-bottom: 1px solid #f0f0f0;
  line-height: 64px;
}

.global-header.is-mint {
  background: rgba(245, 251, 248, 0.88);
  border-bottom: 1px solid rgba(136, 216, 176, 0.22);
  backdrop-filter: blur(12px);
}

.global-header.is-mint .header-menu {
  background: transparent;
  color: #334155;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item) {
  color: #64748b;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item-selected) {
  color: #2d9a78 !important;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item-selected::after) {
  border-bottom-color: #5bc4a0 !important;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)) {
  color: #64748b !important;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)::after) {
  border-bottom-color: transparent !important;
}

.global-header.is-mint .header-menu :deep(.ant-menu-item:hover) {
  color: #2d9a78 !important;
}

.global-header.is-mint :deep(.ant-btn-primary) {
  background: #5bc4a0;
  border-color: #5bc4a0;
  box-shadow: 0 2px 8px rgba(91, 196, 160, 0.3);
}

.global-header.is-mint :deep(.ant-btn-primary:hover) {
  background: #4db892 !important;
  border-color: #4db892 !important;
}

.global-header.is-admin {
  background: rgba(243, 248, 253, 0.9);
  border-bottom: 1px solid rgba(129, 212, 250, 0.28);
  backdrop-filter: blur(12px);
}

.global-header.is-admin .header-menu {
  background: transparent;
  color: #334155;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item) {
  color: #64748b;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item-selected) {
  color: #3b82c4 !important;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item-selected::after) {
  border-bottom-color: #6bb5f0 !important;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)) {
  color: #64748b !important;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)::after) {
  border-bottom-color: transparent !important;
}

.global-header.is-admin .header-menu :deep(.ant-menu-item:hover) {
  color: #3b82c4 !important;
}

.global-header.is-admin :deep(.ant-btn-primary) {
  background: #6bb5f0;
  border-color: #6bb5f0;
  box-shadow: 0 2px 8px rgba(107, 181, 240, 0.3);
}

.global-header.is-admin :deep(.ant-btn-primary:hover) {
  background: #5ba8e8 !important;
  border-color: #5ba8e8 !important;
}

.global-header.is-user-info {
  background: rgba(250, 249, 247, 0.92);
  border-bottom: 1px solid rgba(136, 216, 176, 0.22);
  backdrop-filter: blur(12px);
}

.global-header.is-user-info .header-menu {
  background: transparent;
  color: #334155;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item) {
  color: #64748b;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item-selected) {
  color: #2d9a78 !important;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item-selected::after) {
  border-bottom-color: #5bc4a0 !important;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)) {
  color: #64748b !important;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item-active:not(.ant-menu-item-selected)::after) {
  border-bottom-color: transparent !important;
}

.global-header.is-user-info .header-menu :deep(.ant-menu-item:hover) {
  color: #2d9a78 !important;
}

.global-header.is-user-info :deep(.ant-btn-primary) {
  background: #5bc4a0;
  border-color: #5bc4a0;
  box-shadow: 0 2px 8px rgba(91, 196, 160, 0.28);
}

.global-header.is-user-info :deep(.ant-btn-primary:hover) {
  background: #4db892 !important;
  border-color: #4db892 !important;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.logo {
  width: 36px;
  height: 36px;
  object-fit: contain;
}

.title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: rgba(0, 0, 0, 0.88);
  white-space: nowrap;
}

.header-menu {
  flex: 1;
  min-width: 0;
  border-bottom: none;
  line-height: 62px;
}

.header-menu :deep(.ant-menu-item::after),
.header-menu :deep(.ant-menu-submenu::after) {
  border-top: none !important;
  border-left: none !important;
  border-right: none !important;
  inset-block: auto !important;
  transform: none !important;
}

.header-menu :deep(.ant-menu-item:focus),
.header-menu :deep(.ant-menu-item:focus-visible),
.header-menu :deep(.ant-menu-submenu-title:focus),
.header-menu :deep(.ant-menu-submenu-title:focus-visible) {
  outline: none !important;
}

.header-right {
  flex-shrink: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.greeting {
  font-size: 14px;
  color: #64748b;
  white-space: nowrap;
}

.user-name {
  white-space: nowrap;
}

@media (max-width: 768px) {
  .global-header {
    padding: 0 12px;
    gap: 8px;
  }

  .title {
    display: none;
  }

  .greeting {
    display: none;
  }
}
</style>

<style>
.user-dropdown-menu.ant-menu {
  min-width: 128px;
  padding: 4px 0;
}

.user-dropdown-menu.ant-menu .ant-menu-item {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 40px;
  margin: 0;
  padding: 0 16px;
}

.user-dropdown-menu.ant-menu .ant-menu-title-content {
  flex: 1;
  margin: 0;
}

.user-dropdown-menu .user-dropdown-label {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  text-align: center;
}
</style>
