<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { addApp, listAppVoByPageByAdmin, listGoodAppVoByPage, listMyAppVoByPage } from '@/api/appController'
import { iconCoverLogo } from '@/assets'
import AppListSection from '@/components/AppListSection.vue'
import PromptInputBox from '@/components/PromptInputBox.vue'
import TypewriterText from '@/components/TypewriterText.vue'
import { GOOD_APP_PAGE_SIZE, MY_APP_PAGE_SIZE, QUICK_PROMPTS } from '@/constants/app'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { useLoginUserStore } from '@/stores/loginUser'

const router = useRouter()
const loginUserStore = useLoginUserStore()

const HERO_SLOGANS = [
  '以灵感为星，衍万千应用',
  '一句话描述，快速生成网站',
]

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
    <div class="home-bg" aria-hidden="true">
      <div class="home-bg-blob home-bg-blob-yellow" />
    </div>
    <section class="hero-section">
      <img class="hero-logo" :src="iconCoverLogo" alt="logo" />
      <h1 class="hero-title">星衍-AI 零代码应用生成平台</h1>
      <p class="hero-subtitle">
        <TypewriterText :texts="HERO_SLOGANS" />
      </p>

      <PromptInputBox
        v-model="prompt"
        class="hero-prompt"
        variant="hero"
        placeholder="帮我创建个人博客网站"
        :loading="isCreating"
        :min-rows="2"
        :max-rows="6"
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
      restrict-chat-to-owner
      @page-change="handleGoodPageChange"
    />
  </div>
</template>

<style scoped>
.home-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 32px 24px 72px;
  box-sizing: border-box;
  overflow: hidden;
}

.home-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #f5fbf8 0%, #f0f9ff 45%, #fffef5 100%);
}

.home-bg::before {
  content: '';
  position: absolute;
  width: 520px;
  height: 520px;
  top: -120px;
  left: -80px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(136, 216, 176, 0.45) 0%, transparent 70%);
  filter: blur(2px);
}

.home-bg::after {
  content: '';
  position: absolute;
  width: 480px;
  height: 480px;
  top: 40px;
  right: -100px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(129, 212, 250, 0.35) 0%, transparent 70%);
}

.home-bg-blob {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}

.home-bg-blob-yellow {
  width: 360px;
  height: 360px;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(255, 224, 130, 0.28) 0%, transparent 70%);
}

.hero-section {
  position: relative;
  z-index: 1;
  max-width: 820px;
  margin: 0 auto 56px;
  text-align: center;
}

.hero-logo {
  width: 160px;
  height: 160px;
  object-fit: contain;
  filter: drop-shadow(0 12px 32px rgba(136, 216, 176, 0.35));
}

.hero-title {
  margin: 8px 0 0;
  font-size: 44px;
  font-weight: 700;
  line-height: 1.25;
  letter-spacing: -0.01em;
  color: #1a2e35;
}

.hero-subtitle {
  display: flex;
  justify-content: center;
  margin: 16px 0 0;
  min-height: 40px;
}

.hero-prompt {
  margin-top: 32px;
}

.quick-prompts {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px;
  margin-top: 20px;
}

.quick-prompt {
  height: 38px;
  padding: 0 18px;
  border: 2px solid rgba(136, 216, 176, 0.45);
  border-radius: 999px;
  background: #fff;
  color: #334155;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  box-shadow:
    0 4px 12px rgba(136, 216, 176, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transition:
    background 0.2s ease,
    border-color 0.2s ease,
    box-shadow 0.2s ease,
    transform 0.2s ease;
}

.quick-prompt:nth-child(2n) {
  border-color: rgba(129, 212, 250, 0.5);
  box-shadow:
    0 4px 12px rgba(129, 212, 250, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.9);
}

.quick-prompt:nth-child(3n) {
  border-color: rgba(255, 224, 130, 0.65);
  box-shadow:
    0 4px 12px rgba(255, 224, 130, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.9);
}

.quick-prompt:hover {
  background: #f0fdf7;
  border-color: rgba(91, 196, 160, 0.65);
  box-shadow:
    0 6px 16px rgba(136, 216, 176, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.9);
  transform: translateY(-1px);
}

@media (max-width: 960px) {
  .hero-title {
    font-size: 34px;
  }
}

@media (max-width: 640px) {
  .home-page {
    padding: 20px 16px 56px;
  }

  .hero-title {
    font-size: 26px;
  }

  .hero-logo {
    width: 128px;
    height: 128px;
  }

  .hero-subtitle {
    min-height: 34px;
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
