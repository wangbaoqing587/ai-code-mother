<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuProps } from 'ant-design-vue'
import { menus } from '@/config/menus'

const route = useRoute()
const router = useRouter()

const menuItems = computed(() =>
  menus.map((item) => ({
    key: item.path,
    label: item.label,
  })),
)

const selectedKeys = computed(() => [route.path])

const onMenuClick: MenuProps['onClick'] = ({ key }) => {
  router.push(String(key))
}
</script>

<template>
  <a-layout-header class="global-header">
    <div class="header-left">
      <img class="logo" src="/logo.png" alt="logo" />
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
      <a-button type="primary">登录</a-button>
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
