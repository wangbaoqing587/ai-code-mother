<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { message } from 'ant-design-vue'
import { listAppVoByPageByAdmin, listMyAppVoByPage } from '@/api/appController'
import AppLoadMoreListSection from '@/components/AppLoadMoreListSection.vue'
import { MY_APP_PAGE_SIZE } from '@/constants/app'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { useLoginUserStore } from '@/stores/loginUser'

const loginUserStore = useLoginUserStore()

const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)

const myApps = ref<API.AppVO[]>([])
const myTotal = ref(0)
const isLoading = ref(false)
const isLoadingMore = ref(false)
const myPage = reactive({
  pageNum: 1,
  pageSize: MY_APP_PAGE_SIZE,
})

async function fetchMyApps(append = false) {
  const currentUserId = loginUserStore.loginUser.id
  if (append) {
    isLoadingMore.value = true
  } else {
    isLoading.value = true
  }
  try {
    const query: API.AppQueryRequest = {
      pageNum: myPage.pageNum,
      pageSize: myPage.pageSize,
      userId: currentUserId,
    }
    const res = isAdmin.value
      ? await listAppVoByPageByAdmin(query)
      : await listMyAppVoByPage(query)
    if (res.data.code === 0 && res.data.data) {
      const records = (res.data.data.records ?? []).filter(
        (app) => String(app.userId) === String(currentUserId),
      )
      myApps.value = append ? [...myApps.value, ...records] : records
      myTotal.value = res.data.data.totalRow ?? records.length
      return
    }
    message.error('获取我的作品失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isLoading.value = false
    isLoadingMore.value = false
  }
}

function handleLoadMore() {
  myPage.pageNum += 1
  fetchMyApps(true)
}

onMounted(() => {
  fetchMyApps()
})
</script>

<template>
  <div class="my-works-page">
    <div class="page-bg" aria-hidden="true">
      <div class="page-bg-blob page-bg-blob-yellow" />
    </div>
    <div class="page-content">
      <AppLoadMoreListSection
        v-if="isLoading || myApps.length"
        title="我的作品"
        :apps="myApps"
        :total="myTotal"
        :loading="isLoading"
        :loading-more="isLoadingMore"
        @load-more="handleLoadMore"
      />
      <a-empty v-if="!isLoading && !myApps.length" description="暂无作品" />
    </div>
  </div>
</template>

<style scoped>
.my-works-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 32px 24px 72px;
  box-sizing: border-box;
  overflow: hidden;
}

.page-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #f5fbf8 0%, #f0f9ff 45%, #fffef5 100%);
}

.page-bg-blob {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}

.page-bg-blob-yellow {
  width: 360px;
  height: 360px;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(255, 224, 130, 0.28) 0%, transparent 70%);
}

.page-content {
  position: relative;
  z-index: 1;
  max-height: calc(100vh - 64px - 104px);
  overflow-y: auto;
}

@media (max-width: 640px) {
  .my-works-page {
    padding: 20px 16px 56px;
  }
}
</style>
