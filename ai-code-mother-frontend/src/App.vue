<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import zhCN from 'ant-design-vue/es/locale/zh_CN'
import BasicLayout from '@/layouts/BasicLayout.vue'
import { useLoginUserStore } from '@/stores/loginUser'

const route = useRoute()
const loginUserStore = useLoginUserStore()

const theme = computed(() => ({
  token: {
    colorPrimary: route.path.startsWith('/admin/') ? '#6bb5f0' : '#5bc4a0',
  },
}))

onMounted(() => {
  loginUserStore.fetchLoginUser()
})
</script>

<template>
  <a-config-provider :locale="zhCN" :theme="theme">
    <BasicLayout />
  </a-config-provider>
</template>
