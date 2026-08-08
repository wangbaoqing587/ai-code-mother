<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import { checkAccess } from '@/access/checkAccess'
import { menus } from '@/config/menus'
import { userLogout } from '@/api/userController'
import { iconLogo } from '@/assets'
import UserAvatar from '@/components/UserAvatar.vue'
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
  <a-layout-header class="global-header">
    <div class="header-left">
      <img class="logo" :src="iconLogo" alt="logo" />
      <h1 class="title">AI 零代码应用生成平台</h1>
    </div>
    <a-menu
      class="header-menu"
      mode="horizontal"
      :selected-keys="selectedKeys"
      :items="menuItems"
      @click="onMenuClick"
    />
    <div class="header-right">
      <a-dropdown v-if="isLogin" :trigger="['hover']" placement="bottomRight">
        <div class="user-info">
          <UserAvatar :src="loginUserStore.loginUser.userAvatar" />
          <span>{{ loginUserStore.loginUser.userName }}</span>
        </div>
        <template #overlay>
          <a-menu @click="onUserMenuClick">
            <a-menu-item key="userInfo">个人信息</a-menu-item>
            <a-menu-item key="logout">退出登录</a-menu-item>
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

.header-right {
  flex-shrink: 0;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

@media (max-width: 768px) {
  .global-header {
    padding: 0 12px;
    gap: 8px;
  }

  .title {
    display: none;
  }
}
</style>
