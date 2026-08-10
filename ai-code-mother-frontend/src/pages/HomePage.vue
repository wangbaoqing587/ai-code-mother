<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { addApp, listAppVoByPageByAdmin, listGoodAppVoByPage, listMyAppVoByPage } from '@/api/appController'
import { iconLogo } from '@/assets'
import AppListSection from '@/components/AppListSection.vue'
import PromptInputBox from '@/components/PromptInputBox.vue'
import { GOOD_APP_PAGE_SIZE, MY_APP_PAGE_SIZE, QUICK_PROMPTS } from '@/constants/app'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { useLoginUserStore } from '@/stores/loginUser'

const router = useRouter()
const loginUserStore = useLoginUserStore()

const prompt = ref('')
const isCreating = ref(false)

const isLogin = computed(() => !!loginUserStore.loginUser.id)
const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)

const myApps = ref<API.AppVO[]>([])
const myTotal = ref(0)
const isMyLoading = ref(false)
const myPage = reactive({
  pageNum: 1,
  pageSize: MY_APP_PAGE_SIZE,
})

const goodApps = ref<API.AppVO[]>([])
const goodTotal = ref(0)
const isGoodLoading = ref(false)
const goodPage = reactive({
  pageNum: 1,
  pageSize: GOOD_APP_PAGE_SIZE,
})

async function fetchMyApps() {
  if (!isLogin.value) {
    myApps.value = []
    myTotal.value = 0
    return
  }
  const currentUserId = loginUserStore.loginUser.id
  isMyLoading.value = true
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
      myApps.value = records
      myTotal.value = res.data.data.totalRow ?? records.length
      return
    }
    message.error('获取我的作品失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isMyLoading.value = false
  }
}

async function fetchGoodApps() {
  isGoodLoading.value = true
  try {
    const res = await listGoodAppVoByPage({
      pageNum: goodPage.pageNum,
      pageSize: goodPage.pageSize,
    })
    if (res.data.code === 0 && res.data.data) {
      goodApps.value = res.data.data.records ?? []
      goodTotal.value = res.data.data.totalRow ?? 0
      return
    }
    message.error('获取精选案例失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isGoodLoading.value = false
  }
}

function handleQuickPrompt(text: string) {
  prompt.value = text
}

async function handleCreate() {
  const initPrompt = prompt.value.trim()
  if (!initPrompt) {
    message.warning('请输入提示词')
    return
  }
  if (!isLogin.value) {
    message.warning('请先登录')
    await router.push({
      path: '/user/login',
      query: { redirect: '/' },
    })
    return
  }
  isCreating.value = true
  try {
    const res = await addApp({ initPrompt })
    if (res.data.code === 0 && res.data.data) {
      prompt.value = ''
      await router.push(`/app/chat/${res.data.data}`)
      return
    }
    message.error('创建应用失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isCreating.value = false
  }
}

function handleMyPageChange(page: number) {
  myPage.pageNum = page
  fetchMyApps()
}

function handleGoodPageChange(page: number) {
  goodPage.pageNum = page
  fetchGoodApps()
}

watch(isLogin, () => {
  myPage.pageNum = 1
  fetchMyApps()
})

onMounted(() => {
  fetchMyApps()
  fetchGoodApps()
})
</script>

<template>
  <div class="home-page">
    <div class="home-bg" aria-hidden="true" />
    <section class="hero-section">
      <img class="hero-logo" :src="iconLogo" alt="logo" />
      <h1 class="hero-title">AI 应用生成平台</h1>
      <p class="hero-subtitle">一句话轻松创建网站应用</p>

      <PromptInputBox
        v-model="prompt"
        class="hero-prompt"
        variant="hero"
        placeholder="帮我创建个人博客网站"
        :loading="isCreating"
        :min-rows="4"
        :max-rows="8"
        @submit="handleCreate"
      />

      <div class="quick-prompts">
        <button
          v-for="item in QUICK_PROMPTS"
          :key="item.label"
          class="quick-prompt"
          type="button"
          @click="handleQuickPrompt(item.prompt)"
        >
          {{ item.label }}
        </button>
      </div>
    </section>

    <AppListSection
      v-if="isLogin && myApps.length"
      title="我的作品"
      :apps="myApps"
      :total="myTotal"
      :loading="isMyLoading"
      :page-num="myPage.pageNum"
      :page-size="myPage.pageSize"
      @page-change="handleMyPageChange"
    />

    <AppListSection
      v-if="goodApps.length"
      title="精选案例"
      :apps="goodApps"
      :total="goodTotal"
      :loading="isGoodLoading"
      :page-num="goodPage.pageNum"
      :page-size="goodPage.pageSize"
      @page-change="handleGoodPageChange"
    />
  </div>
</template>

<style scoped>
.home-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 56px 24px 72px;
  box-sizing: border-box;
  overflow: hidden;
}

.home-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background:
    radial-gradient(ellipse 90% 60% at 10% 0%, rgba(14, 165, 233, 0.45), transparent 55%),
    radial-gradient(ellipse 70% 50% at 90% 10%, rgba(6, 182, 212, 0.35), transparent 50%),
    radial-gradient(ellipse 50% 40% at 50% 100%, rgba(56, 189, 248, 0.28), transparent 55%),
    linear-gradient(155deg, #071422 0%, #0b2a45 38%, #0a4d6e 72%, #0e7490 100%);
}

.home-bg::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.04) 1px, transparent 1px);
  background-size: 48px 48px;
  mask-image: linear-gradient(180deg, rgba(0, 0, 0, 0.55), transparent 85%);
}

.hero-section {
  position: relative;
  z-index: 1;
  max-width: 820px;
  margin: 0 auto 56px;
  text-align: center;
}

.hero-logo {
  width: 64px;
  height: 64px;
  margin-bottom: 16px;
  object-fit: contain;
  filter: drop-shadow(0 8px 24px rgba(56, 189, 248, 0.35));
}

.hero-title {
  margin: 0;
  font-size: 48px;
  font-weight: 700;
  line-height: 1.2;
  letter-spacing: 0.02em;
  color: #f8fafc;
  text-shadow: 0 2px 24px rgba(14, 165, 233, 0.35);
}

.hero-subtitle {
  margin: 14px 0 0;
  font-size: 18px;
  color: rgba(226, 242, 255, 0.78);
}

.hero-prompt {
  margin-top: 36px;
}

.quick-prompts {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
  margin-top: 20px;
}

.quick-prompt {
  height: 36px;
  padding: 0 16px;
  border: 1px solid rgba(255, 255, 255, 0.22);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  color: #e2f2ff;
  backdrop-filter: blur(8px);
  cursor: pointer;
  transition:
    background 0.2s ease,
    border-color 0.2s ease,
    transform 0.2s ease;
}

.quick-prompt:hover {
  background: rgba(255, 255, 255, 0.22);
  border-color: rgba(255, 255, 255, 0.4);
  transform: translateY(-1px);
}

@media (max-width: 960px) {
  .hero-title {
    font-size: 36px;
  }
}

@media (max-width: 640px) {
  .home-page {
    padding: 40px 16px 56px;
  }

  .hero-title {
    font-size: 28px;
  }

  .hero-logo {
    width: 48px;
    height: 48px;
  }

  .hero-subtitle {
    font-size: 15px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .quick-prompt {
    transition: none;
  }

  .quick-prompt:hover {
    transform: none;
  }
}
</style>
