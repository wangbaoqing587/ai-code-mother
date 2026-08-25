<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { deleteApp, deleteAppByAdmin, deployApp, downloadAppCode, getAppVoById } from '@/api/appController'
import { listAppChatHistory } from '@/api/chatHistoryController'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { avatarChatbot, iconPageEdit, iconPageOpen, iconWeb } from '@/assets'
import AppDetailModal from '@/components/AppDetailModal.vue'
import CodeGenTypeTag from '@/components/CodeGenTypeTag.vue'
import DeploySuccessModal from '@/components/DeploySuccessModal.vue'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import StreamingMessageRenderer from '@/components/StreamingMessageRenderer.vue'
import PromptInputBox from '@/components/PromptInputBox.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { getDeployUrl, getStaticPreviewUrl } from '@/config/env'
import { useLoginUserStore } from '@/stores/loginUser'
import { getFilenameFromContentDisposition, triggerBlobDownload } from '@/utils/download'
import { generateCode } from '@/utils/sse'
import { throttle } from '@/utils/throttle'
import { showConfirmModal } from '@/utils/modal'
import { parseRouteParamId } from '@/utils/route'
import {
  buildPromptWithElement,
  createVisualEditor,
  type ElementInfo,
} from '@/utils/visualEditor'

interface ChatMessage {
  id: string
  role: 'user' | 'ai'
  content: string
  createTime?: string
  isStreaming?: boolean
}

const HISTORY_PAGE_SIZE = 10
const APP_GEN_STATUS_GENERATING = 'generating'
const APP_GEN_STATUS_FAILED = 'failed'
const GENERATION_POLL_INTERVAL_MS = 2000
const GENERATION_POLL_TIMEOUT_MS = 5 * 60 * 1000

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()

const appInfo = ref<API.AppVO>({})
const messages = ref<ChatMessage[]>([])
const inputMessage = ref('')
const isLoadingApp = ref(false)
const isLoadingHistory = ref(false)
const isLoadingMoreHistory = ref(false)
const isGenerating = ref(false)
const isDeploying = ref(false)
const isDownloading = ref(false)
const isDetailOpen = ref(false)
const isDeploySuccessOpen = ref(false)
const deployUrl = ref('')
const showPreview = ref(false)
const previewKey = ref(0)
const hasMoreHistory = ref(false)
const historyTotal = ref(0)
const historyCursor = ref<string>()
const messagesRef = ref<HTMLElement | null>(null)
const previewFrameRef = ref<HTMLIFrameElement | null>(null)
const isEditMode = ref(false)
const selectedElementInfo = ref<ElementInfo | null>(null)

let closeStream: (() => void) | null = null
let activeFlushContent: ReturnType<typeof throttle> | null = null
let activeScheduleScroll: ReturnType<typeof throttle> | null = null
let generationPollTimer: ReturnType<typeof setInterval> | null = null
let generationPollStartedAt = 0

function cancelStreamThrottles() {
  activeFlushContent?.cancel()
  activeScheduleScroll?.cancel()
  activeFlushContent = null
  activeScheduleScroll = null
}

const visualEditor = createVisualEditor({
  onElementSelected(info) {
    selectedElementInfo.value = info
  },
})

const selectedElementAlertText = computed(() => {
  const info = selectedElementInfo.value
  if (!info) {
    return ''
  }
  const tag = info.tagName.toLowerCase()
  const content = info.textContent || '无'
  return `已选中 ${tag}（${info.selector}），当前内容：${content}`
})

const appId = computed(() => parseRouteParamId(route.params.id))
const previewUrl = computed(() => {
  const { codeGenType } = appInfo.value
  return codeGenType && appId.value ? getStaticPreviewUrl(codeGenType, appId.value) : ''
})
const canPreview = computed(() => showPreview.value && !!previewUrl.value)
const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)
const isOwner = computed(() => appInfo.value.userId === loginUserStore.loginUser.id)
const canManage = computed(() => isAdmin.value || isOwner.value)
const userAvatar = computed(() => loginUserStore.loginUser.userAvatar || '')

function createMessageId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function isUserMessageType(messageType?: string) {
  return messageType === 'user' || messageType === 'USER'
}

function mapHistoryToMessages(records: API.ChatHistory[]) {
  return [...records]
    .sort((a, b) => {
      const timeA = a.createTime ? new Date(a.createTime).getTime() : 0
      const timeB = b.createTime ? new Date(b.createTime).getTime() : 0
      return timeA - timeB
    })
    .map((item) => {
      return {
        id: String(item.id ?? createMessageId()),
        role: isUserMessageType(item.messageType) ? 'user' : 'ai',
        content: item.message ?? '',
        createTime: item.createTime,
      } satisfies ChatMessage
    })
}

function updateHistoryCursor() {
  const historyMessages = messages.value.filter((item) => !!item.createTime)
  historyCursor.value = historyMessages[0]?.createTime
}

function updatePreviewByHistory() {
  if (historyTotal.value >= 2 && appInfo.value.codeGenType) {
    showPreview.value = true
  }
}

async function scrollToBottom() {
  await nextTick()
  if (messagesRef.value) {
    messagesRef.value.scrollTop = messagesRef.value.scrollHeight
  }
}

async function fetchAppInfo(silent = false) {
  if (!appId.value) {
    return
  }
  if (!silent) {
    isLoadingApp.value = true
  }
  try {
    const res = await getAppVoById({ id: appId.value })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data
      return
    }
    if (!silent) {
      message.error('获取应用信息失败：' + (res.data.message ?? '未知错误'))
    }
  } finally {
    if (!silent) {
      isLoadingApp.value = false
    }
  }
}

async function fetchChatHistory(isLoadMore = false, silent = false) {
  if (!appId.value) {
    return
  }
  if (isLoadMore) {
    if (!hasMoreHistory.value || isLoadingMoreHistory.value || !historyCursor.value) {
      return
    }
    isLoadingMoreHistory.value = true
  } else if (!silent) {
    isLoadingHistory.value = true
  }

  try {
    const res = await listAppChatHistory({
      appId: appId.value,
      pageSize: HISTORY_PAGE_SIZE,
      lastCreateTime: isLoadMore ? historyCursor.value : undefined,
    })
    if (res.data.code === 0 && res.data.data) {
      const records = res.data.data.records ?? []
      historyTotal.value = res.data.data.totalRow ?? records.length
      hasMoreHistory.value = records.length >= HISTORY_PAGE_SIZE
      const mapped = mapHistoryToMessages(records)

      if (isLoadMore) {
        const container = messagesRef.value
        const prevHeight = container?.scrollHeight ?? 0
        const existingIds = new Set(messages.value.map((item) => item.id))
        const olderMessages = mapped.filter((item) => !existingIds.has(item.id))
        messages.value = [...olderMessages, ...messages.value]
        updateHistoryCursor()
        await nextTick()
        if (container) {
          container.scrollTop = container.scrollHeight - prevHeight
        }
        return
      }

      messages.value = mapped
      updateHistoryCursor()
      await scrollToBottom()
      return
    }
    message.error('获取对话历史失败：' + (res.data.message ?? '未知错误'))
  } finally {
    if (isLoadMore) {
      isLoadingMoreHistory.value = false
    } else if (!silent) {
      isLoadingHistory.value = false
    }
  }
}

async function handleLoadMoreHistory() {
  await fetchChatHistory(true)
}

function stopGenerationPolling() {
  if (generationPollTimer) {
    clearInterval(generationPollTimer)
    generationPollTimer = null
  }
  generationPollStartedAt = 0
}

function ensureGeneratingAiPlaceholder() {
  const lastMessage = messages.value[messages.value.length - 1]
  if (lastMessage?.role === 'user') {
    messages.value.push({
      id: createMessageId(),
      role: 'ai',
      content: '',
      isStreaming: true,
    })
    return
  }
  if (lastMessage?.role === 'ai' && !lastMessage.content) {
    lastMessage.isStreaming = true
  }
}

async function finishGeneration(aiMessageIndex?: number) {
  if (aiMessageIndex !== undefined) {
    const aiMessage = messages.value[aiMessageIndex]
    if (aiMessage) {
      aiMessage.isStreaming = false
    }
  } else {
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage?.role === 'ai') {
      lastMessage.isStreaming = false
    }
  }
  isGenerating.value = false
  setTimeout(async () => {
    await fetchAppInfo(true)
    if (appInfo.value.codeGenType) {
      showPreview.value = true
      previewKey.value += 1
    }
    await scrollToBottom()
  }, 1000)
}

async function pollGenerationStatus() {
  if (generationPollStartedAt && Date.now() - generationPollStartedAt > GENERATION_POLL_TIMEOUT_MS) {
    stopGenerationPolling()
    isGenerating.value = false
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage?.role === 'ai') {
      lastMessage.isStreaming = false
    }
    await fetchAppInfo(true)
    message.error('生成超时，请重试')
    return
  }

  await fetchAppInfo(true)
  if (appInfo.value.genStatus === APP_GEN_STATUS_GENERATING) {
    return
  }

  stopGenerationPolling()
  await fetchChatHistory(false, true)

  if (appInfo.value.genStatus === APP_GEN_STATUS_FAILED) {
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage?.role === 'user') {
      messages.value.push({
        id: createMessageId(),
        role: 'ai',
        content: '❌ 生成失败，请重试',
      })
    } else if (lastMessage?.role === 'ai') {
      lastMessage.isStreaming = false
      lastMessage.content = lastMessage.content || '❌ 生成失败，请重试'
    }
    isGenerating.value = false
    message.error('生成失败，请重试')
    return
  }

  await finishGeneration()
}

function startGenerationPolling() {
  stopGenerationPolling()
  generationPollStartedAt = Date.now()
  generationPollTimer = setInterval(() => {
    void pollGenerationStatus()
  }, GENERATION_POLL_INTERVAL_MS)
}

async function restoreGeneratingState() {
  ensureGeneratingAiPlaceholder()
  isGenerating.value = true
  showPreview.value = false
  await scrollToBottom()
  startGenerationPolling()
}

function stopStream() {
  cancelStreamThrottles()
  if (closeStream) {
    closeStream()
    closeStream = null
  }
}

function resetVisualEditState() {
  selectedElementInfo.value = null
  if (isEditMode.value) {
    visualEditor.disableEditMode()
    isEditMode.value = false
  }
}

function handleToggleEditMode() {
  if (!canPreview.value || isGenerating.value) {
    message.warning('请先生成网站后再进行编辑')
    return
  }
  if (previewFrameRef.value) {
    visualEditor.init(previewFrameRef.value)
  }
  const enabled = visualEditor.toggleEditMode()
  isEditMode.value = enabled
  if (enabled) {
    message.info('已进入编辑模式，点击预览中的元素进行选中', 3)
    return
  }
  selectedElementInfo.value = null
}

function clearSelectedElement() {
  selectedElementInfo.value = null
  visualEditor.clearSelection()
}

function handleIframeLoad() {
  if (previewFrameRef.value) {
    visualEditor.init(previewFrameRef.value)
  }
  visualEditor.onIframeLoad()
}

function handleWindowMessage(event: MessageEvent) {
  visualEditor.handleIframeMessage(event)
}

async function sendMessage(rawMessage: string) {
  const text = rawMessage.trim()
  if (!text || !appId.value || isGenerating.value) {
    return
  }

  const prompt = buildPromptWithElement(text, selectedElementInfo.value)
  resetVisualEditState()

  messages.value.push({
    id: createMessageId(),
    role: 'user',
    content: prompt,
  })
  const aiMessageIndex = messages.value.length
  messages.value.push({
    id: createMessageId(),
    role: 'ai',
    content: '',
    isStreaming: true,
  })
  inputMessage.value = ''
  isGenerating.value = true
  showPreview.value = false
  await scrollToBottom()
  await generateCodeStream(prompt, aiMessageIndex)
}

async function generateCodeStream(userMessage: string, aiMessageIndex: number) {
  if (!appId.value) {
    return
  }
  stopStream()
  let pendingContent = ''

  const scheduleScrollToBottom = throttle(async () => {
    await nextTick()
    if (messagesRef.value) {
      messagesRef.value.scrollTop = messagesRef.value.scrollHeight
    }
  }, 200)

  const flushContentUpdate = throttle(() => {
    const aiMessage = messages.value[aiMessageIndex]
    if (aiMessage) {
      aiMessage.content = pendingContent
    }
    scheduleScrollToBottom()
  }, 200)

  activeFlushContent = flushContentUpdate
  activeScheduleScroll = scheduleScrollToBottom

  closeStream = generateCode(
    { appId: appId.value, message: userMessage },
    {
      onMessage: (chunk) => {
        pendingContent += chunk
        flushContentUpdate()
      },
      onDone: async () => {
        flushContentUpdate.flush()
        closeStream = null
        scheduleScrollToBottom.flush()
        cancelStreamThrottles()
        await finishGeneration(aiMessageIndex)
      },
      onBusinessError: (errorMessage) => {
        flushContentUpdate.flush()
        const aiMessage = messages.value[aiMessageIndex]
        if (aiMessage) {
          aiMessage.content = `❌ ${errorMessage}`
          aiMessage.isStreaming = false
        }
        isGenerating.value = false
        closeStream = null
        cancelStreamThrottles()
        message.error(errorMessage)
      },
      onError: (error) => {
        flushContentUpdate.flush()
        const aiMessage = messages.value[aiMessageIndex]
        if (aiMessage) {
          aiMessage.isStreaming = false
          aiMessage.content = aiMessage.content || `❌ ${error.message || '生成失败'}`
        }
        isGenerating.value = false
        closeStream = null
        cancelStreamThrottles()
        message.error(error.message || '生成失败')
      },
    },
  )
}

async function handleSend() {
  await sendMessage(inputMessage.value)
}

function handleOpenPreview(event: Event) {
  if (!canPreview.value || !previewUrl.value) {
    event.preventDefault()
  }
}

async function handleDeploy() {
  if (!appId.value || isDeploying.value) {
    return
  }
  isDeploying.value = true
  try {
    const res = await deployApp({ appId: appId.value })
    if (res.data.code === 0 && res.data.data) {
      await fetchAppInfo()
      const { deployKey, codeGenType } = appInfo.value
      deployUrl.value = deployKey
        ? getDeployUrl(deployKey, codeGenType)
        : res.data.data
      isDeploySuccessOpen.value = true
      return
    }
    message.error('部署失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isDeploying.value = false
  }
}

async function handleDownload() {
  if (!appId.value || isDownloading.value) {
    return
  }
  isDownloading.value = true
  try {
    const res = await downloadAppCode(
      { appId: appId.value },
      { responseType: 'blob' },
    )
    const blob = res.data as Blob
    const contentType = String(res.headers['content-type'] || '')
    if (contentType.includes('application/json')) {
      const text = await blob.text()
      const json = JSON.parse(text) as { message?: string }
      message.error('下载失败：' + (json.message ?? '未知错误'))
      return
    }
    const filename = getFilenameFromContentDisposition(
      res.headers['content-disposition'],
      `${appInfo.value.appName || appId.value}.zip`,
    )
    triggerBlobDownload(blob, filename)
    message.success('下载成功')
  } catch {
    message.error('下载失败')
  } finally {
    isDownloading.value = false
  }
}

function handleEditApp() {
  isDetailOpen.value = false
  router.push(`/app/edit/${appId.value}`)
}

function handleDeleteApp() {
  if (!appId.value) {
    return
  }
  showConfirmModal({
    variant: 'mint',
    title: '确认删除该应用？',
    content: `应用：${appInfo.value.appName || appId.value}`,
    okText: '确定',
    cancelText: '取消',
    okType: 'danger',
    async onOk() {
      const res = isAdmin.value
        ? await deleteAppByAdmin({ id: appId.value })
        : await deleteApp({ id: appId.value })
      if (res.data.code === 0) {
        message.success('删除成功')
        isDetailOpen.value = false
        await router.replace('/')
        return
      }
      message.error('删除失败：' + (res.data.message ?? '未知错误'))
    },
  })
}

async function initPage() {
  stopGenerationPolling()
  stopStream()
  resetVisualEditState()
  messages.value = []
  showPreview.value = false
  hasMoreHistory.value = false
  historyTotal.value = 0
  historyCursor.value = undefined
  isGenerating.value = false
  await fetchAppInfo()
  await fetchChatHistory(false)

  if (appInfo.value.genStatus === APP_GEN_STATUS_GENERATING) {
    await restoreGeneratingState()
    return
  }

  updatePreviewByHistory()

  if (isOwner.value && !messages.value.length && appInfo.value.initPrompt) {
    await sendMessage(appInfo.value.initPrompt)
  }
}

watch(
  () => route.params.id,
  () => {
    initPage()
  },
)

watch(canPreview, (value) => {
  if (!value) {
    resetVisualEditState()
  }
})

onMounted(() => {
  window.addEventListener('message', handleWindowMessage)
  initPage()
})

onBeforeUnmount(() => {
  window.removeEventListener('message', handleWindowMessage)
  resetVisualEditState()
  stopGenerationPolling()
  stopStream()
})
</script>

<template>
  <div class="app-chat-page">
    <div class="chat-header">
      <div class="app-name">
        <img class="app-logo" :src="iconWeb" alt="web" />
        <a-spin v-if="isLoadingApp" size="small" />
        <template v-else>
          <span class="app-name-text">{{ appInfo.appName || '未命名应用' }}</span>
          <CodeGenTypeTag v-if="appInfo.codeGenType" :code-gen-type="appInfo.codeGenType" />
        </template>
      </div>
      <a-space>
        <a-button class="header-btn header-btn-outline" @click="isDetailOpen = true">应用详情</a-button>
        <a-button class="header-btn header-btn-outline" :loading="isDownloading" @click="handleDownload">
          下载代码
        </a-button>
        <a-button class="header-btn header-btn-primary" type="primary" :loading="isDeploying" @click="handleDeploy">
          部署
        </a-button>
      </a-space>
    </div>

    <DeploySuccessModal v-model:open="isDeploySuccessOpen" :url="deployUrl" />
    <AppDetailModal
      v-model:open="isDetailOpen"
      :app="appInfo"
      :can-manage="canManage"
      @edit="handleEditApp"
      @delete="handleDeleteApp"
    />

    <div class="chat-body">
      <div class="chat-panel">
        <div ref="messagesRef" class="messages-area">
          <a-spin :spinning="isLoadingHistory">
            <div v-if="hasMoreHistory" class="load-more-wrap">
              <a-button
                class="load-more-btn"
                type="link"
                :loading="isLoadingMoreHistory"
                @click="handleLoadMoreHistory"
              >
                加载更多
              </a-button>
            </div>
            <div v-if="!messages.length" class="messages-empty">开始对话，生成你的网站应用</div>
            <div
              v-for="item in messages"
              :key="item.id"
              class="message-row"
              :class="item.role === 'user' ? 'is-user' : 'is-ai'"
            >
              <UserAvatar
                v-if="item.role === 'ai'"
                class="message-avatar"
                :size="36"
                :src="avatarChatbot"
              />
              <div v-else class="message-avatar-placeholder" aria-hidden="true" />
              <div class="message-bubble" :class="item.role">
                <StreamingMessageRenderer
                  v-if="item.role === 'ai' && item.isStreaming"
                  :content="item.content"
                  :is-streaming="true"
                />
                <MarkdownRenderer
                  v-else-if="item.role === 'ai' && item.content"
                  :content="item.content"
                />
                <pre v-else class="message-content">{{
                  item.content || (item.isStreaming ? '生成中...' : '')
                }}</pre>
              </div>
              <UserAvatar
                v-if="item.role === 'user'"
                class="message-avatar"
                :size="36"
                :src="userAvatar"
              />
              <div v-else class="message-avatar-placeholder" aria-hidden="true" />
            </div>
          </a-spin>
        </div>

        <div class="chat-input-area">
          <a-alert
            v-if="selectedElementInfo"
            class="selected-element-alert"
            type="info"
            show-icon
            closable
            :message="selectedElementAlertText"
            @close="clearSelectedElement"
          />
          <PromptInputBox
            v-model="inputMessage"
            variant="chat"
            placeholder="请描述你想生成的网站，越详细效果越好哦"
            :loading="isGenerating"
            :disabled="isGenerating"
            :disable-submit="!inputMessage.trim()"
            :min-rows="3"
            :max-rows="6"
            @submit="handleSend"
          />
        </div>
      </div>

      <div class="preview-panel">
        <div class="preview-toolbar">
          <span class="preview-title">网页预览</span>
          <div class="preview-toolbar-actions">
            <button
              type="button"
              class="preview-action-btn"
              :class="{ 'is-active': isEditMode }"
              :disabled="!canPreview || isGenerating"
              @click="handleToggleEditMode"
            >
              <img :src="iconPageEdit" alt="" class="preview-action-icon" />
              {{ isEditMode ? '退出编辑' : '编辑' }}
            </button>
            <a
              class="preview-action-btn"
              :class="{ 'is-disabled': !canPreview }"
              :href="canPreview ? previewUrl : undefined"
              :tabindex="canPreview ? 0 : -1"
              target="_blank"
              rel="noopener noreferrer"
              @click="handleOpenPreview"
            >
              <img :src="iconPageOpen" alt="" class="preview-action-icon" />
              新窗口打开
            </a>
          </div>
        </div>
        <div v-if="canPreview" class="preview-frame-wrap">
          <iframe
            ref="previewFrameRef"
            :key="previewKey"
            class="preview-frame"
            :src="previewUrl"
            title="应用预览"
            @load="handleIframeLoad"
          />
        </div>
        <div v-else class="preview-empty">
          <a-spin v-if="isGenerating" tip="正在生成网站..." />
          <span v-else>生成完成后将在此展示网站效果</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.app-chat-page {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 64px);
  box-sizing: border-box;
  background: transparent;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  height: 56px;
  padding: 0 20px;
  background: rgba(255, 255, 255, 0.82);
  border-bottom: 1px solid rgba(136, 216, 176, 0.28);
  backdrop-filter: blur(10px);
}

.app-name {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  font-size: 16px;
  font-weight: 600;
  color: #1a2e35;
}

.app-name-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-logo {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.header-btn {
  height: 34px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 500;
}

.header-btn-outline {
  border: 1.5px solid rgba(136, 216, 176, 0.55) !important;
  background: #fff !important;
  color: #334155 !important;
  box-shadow: 0 2px 8px rgba(136, 216, 176, 0.1);
}

.header-btn-outline:hover {
  border-color: rgba(91, 196, 160, 0.75) !important;
  color: #2d9a78 !important;
  background: #f0fdf7 !important;
}

.header-btn-primary {
  background: #5bc4a0 !important;
  border-color: #5bc4a0 !important;
  box-shadow: 0 4px 12px rgba(91, 196, 160, 0.32);
}

.header-btn-primary:hover {
  background: #4db892 !important;
  border-color: #4db892 !important;
}

.chat-body {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 3fr);
  flex: 1;
  min-height: 0;
  overflow: hidden;
  gap: 0;
}

.chat-panel {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  background: rgba(255, 255, 255, 0.55);
  border-right: 1px solid rgba(136, 216, 176, 0.22);
}

.messages-area {
  flex: 1;
  overflow-y: auto;
  padding: 16px 18px;
}

.load-more-wrap {
  display: flex;
  justify-content: center;
  margin-bottom: 8px;
}

.load-more-btn {
  color: #2d9a78 !important;
}

.load-more-btn:hover {
  color: #5bc4a0 !important;
}

.messages-empty {
  padding: 48px 0;
  text-align: center;
  color: #94a3b8;
}

.message-row {
  display: grid;
  grid-template-columns: 36px minmax(0, 1fr) 36px;
  column-gap: 10px;
  align-items: flex-start;
  margin-bottom: 16px;
}

.message-avatar {
  flex-shrink: 0;
}

.message-avatar-placeholder {
  width: 36px;
  height: 36px;
  flex-shrink: 0;
}

.message-bubble {
  min-width: 0;
  padding: 12px 14px;
  border-radius: 16px;
  overflow-x: auto;
}

.message-bubble.user {
  background: rgba(136, 216, 176, 0.22);
  border: 1px solid rgba(136, 216, 176, 0.35);
}

.message-bubble.ai {
  background: #fff;
  border: 1px solid rgba(136, 216, 176, 0.28);
  box-shadow: 0 4px 14px rgba(136, 216, 176, 0.1);
}

.message-content {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: inherit;
  font-size: 14px;
  line-height: 1.6;
  color: #334155;
}

.chat-input-area {
  display: flex;
  flex-direction: column;
  padding-top: 4px;
}

.selected-element-alert {
  margin: 0 16px 8px;
  border-radius: 12px;
  border: 1px solid rgba(136, 216, 176, 0.35);
  background: rgba(240, 253, 247, 0.9);
}

.preview-title {
  font-size: 15px;
  font-weight: 600;
  letter-spacing: 0.02em;
  color: #1a2e35;
}

.chat-input-area :deep(.prompt-input-box.is-chat) {
  margin-top: 0;
}

.preview-panel {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  background: rgba(240, 247, 244, 0.85);
}

.preview-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  height: 48px;
  padding: 0 18px;
  background: rgba(255, 255, 255, 0.88);
  border-bottom: 1px solid rgba(136, 216, 176, 0.22);
}

.preview-toolbar-actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

.preview-action-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 10px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: #64748b;
  font-size: 13px;
  font-weight: 500;
  line-height: 1;
  text-decoration: none;
  cursor: pointer;
  transition:
    background 0.2s ease,
    color 0.2s ease;
}

.preview-action-btn:hover:not(:disabled):not(.is-disabled) {
  background: rgba(136, 216, 176, 0.14);
  color: #2d9a78;
}

.preview-action-btn.is-active {
  background: rgba(91, 196, 160, 0.16);
  color: #2d9a78;
}

.preview-action-btn:disabled,
.preview-action-btn.is-disabled {
  color: #cbd5e1;
  cursor: not-allowed;
  pointer-events: none;
}

.preview-action-icon {
  width: 14px;
  height: 14px;
  flex-shrink: 0;
  object-fit: contain;
}

.preview-action-btn:disabled .preview-action-icon,
.preview-action-btn.is-disabled .preview-action-icon {
  opacity: 0.45;
}

.preview-frame-wrap,
.preview-empty {
  flex: 1;
  min-height: 0;
  width: 100%;
  padding: 12px;
  box-sizing: border-box;
}

.preview-frame {
  width: 100%;
  height: 100%;
  border: 0;
  border-radius: 14px;
  background: #fff;
  box-shadow:
    0 8px 24px rgba(136, 216, 176, 0.14),
    0 2px 8px rgba(26, 46, 53, 0.06);
}

.preview-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
}

@media (max-width: 960px) {
  .chat-body {
    grid-template-columns: 1fr;
    grid-template-rows: 1fr 1fr;
  }

  .chat-panel {
    border-right: none;
    border-bottom: 1px solid rgba(136, 216, 176, 0.22);
  }
}
</style>
