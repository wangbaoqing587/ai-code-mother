<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

function goHome() {
  router.push('/')
}
</script>

<template>
  <div class="no-auth-page">
    <a-result status="403" title="401" sub-title="抱歉，您没有权限访问该页面">
      <template #extra>
        <a-button type="primary" @click="goHome">返回首页</a-button>
      </template>
    </a-result>
  </div>
</template>

<style scoped>
.no-auth-page {
  display: flex;
  justify-content: center;
  padding-top: 80px;
}
</style>
