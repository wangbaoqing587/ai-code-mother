<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message, Modal } from 'ant-design-vue'
import { deleteApp, deleteAppByAdmin, deployApp, downloadAppCode, getAppVoById } from '@/api/appController'
import { listAppChatHistory } from '@/api/chatHistoryController'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { avatarChatbot, iconWeb } from '@/assets'
import AppDetailModal from '@/components/AppDetailModal.vue'
import DeploySuccessModal from '@/components/DeploySuccessModal.vue'
import MarkdownRenderer from '@/components/MarkdownRenderer.vue'
import PromptInputBox from '@/components/PromptInputBox.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { getDeployUrl, getStaticPreviewUrl } from '@/config/env'
import { formatCodeGenType, getCodeGenTypeOption } from '@/constants/codeGenType'
import { useLoginUserStore } from '@/stores/loginUser'
import { getFilenameFromContentDisposition, triggerBlobDownload } from '@/utils/download'
import { generateCode } from '@/utils/sse'
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

const appId = computed(() => {
  const id = route.params.id
  return Array.isArray(id) ? id[0] ?? '' : (id ?? '')
})
const previewUrl = computed(() => {
  const { codeGenType, id } = appInfo.value
  return codeGenType && id ? getStaticPreviewUrl(codeGenType, id) : ''
})
const canPreview = computed(() => showPreview.value && !!previewUrl.value)
const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)
const isOwner = computed(() => appInfo.value.userId === loginUserStore.loginUser.id)
const canManage = computed(() => isAdmin.value || isOwner.value)
const userAvatar = computed(() => loginUserStore.loginUser.userAvatar || '')
const codeGenTypeTag = computed(() => {
  const option = getCodeGenTypeOption(appInfo.value.codeGenType)
  return {
    label: option?.label || formatCodeGenType(appInfo.value.codeGenType),
    color: option?.color || '#8c8c8c',
  }
})

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

async function fetchAppInfo() {
  if (!appId.value) {
    return
  }
  isLoadingApp.value = true
  try {
    const res = await getAppVoById({ id: appId.value })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data
      return
    }
    message.error('获取应用信息失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isLoadingApp.value = false
  }
}

async function fetchChatHistory(isLoadMore = false) {
  if (!appId.value) {
    return
  }
  if (isLoadMore) {
    if (!hasMoreHistory.value || isLoadingMoreHistory.value || !historyCursor.value) {
      return
    }
    isLoadingMoreHistory.value = true
  } else {
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
    isLoadingHistory.value = false
    isLoadingMoreHistory.value = false
  }
}

async function handleLoadMoreHistory() {
  await fetchChatHistory(true)
}

function stopStream() {
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
  stopStream()
  let fullContent = ''

  closeStream = generateCode(
    { appId: appId.value, message: userMessage },
    {
      onMessage: (chunk) => {
        fullContent += chunk
        const aiMessage = messages.value[aiMessageIndex]
        if (!aiMessage) {
          return
        }
        aiMessage.content = fullContent
        aiMessage.isStreaming = false
        scrollToBottom()
      },
      onDone: async () => {
        const aiMessage = messages.value[aiMessageIndex]
        if (aiMessage) {
          aiMessage.isStreaming = false
        }
        isGenerating.value = false
        closeStream = null
        setTimeout(async () => {
          await fetchAppInfo()
          if (appInfo.value.codeGenType) {
            showPreview.value = true
            previewKey.value += 1
          }
          await scrollToBottom()
        }, 1000)
      },
      onError: (error) => {
        const aiMessage = messages.value[aiMessageIndex]
        if (aiMessage) {
          aiMessage.isStreaming = false
          aiMessage.content = aiMessage.content || `❌ ${error.message || '生成失败'}`
        }
        isGenerating.value = false
        closeStream = null
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
      { appId: appId.value as unknown as number },
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
  Modal.confirm({
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
  stopStream()
  resetVisualEditState()
  messages.value = []
  showPreview.value = false
  hasMoreHistory.value = false
  historyTotal.value = 0
  historyCursor.value = undefined
  await fetchAppInfo()
  await fetchChatHistory(false)
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
          <span
            v-if="appInfo.codeGenType"
            class="app-type-tag"
            :style="{ background: codeGenTypeTag.color + '22', color: codeGenTypeTag.color }"
          >
            {{ codeGenTypeTag.label }}
          </span>
        </template>
      </div>
      <a-space>
        <a-button @click="isDetailOpen = true">应用详情</a-button>
        <a-button :loading="isDownloading" @click="handleDownload">下载代码</a-button>
        <a-button type="primary" :loading="isDeploying" @click="handleDeploy">部署</a-button>
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
                class="message-avatar"
                :size="36"
                :src="item.role === 'ai' ? avatarChatbot : userAvatar"
              />
              <div class="message-bubble" :class="item.role">
                <MarkdownRenderer
                  v-if="item.role === 'ai' && item.content"
                  :content="item.content"
                />
                <pre v-else class="message-content">{{
                  item.content || (item.isStreaming ? '生成中...' : '')
                }}</pre>
              </div>
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
          >
            <template #actions>
              <a-button
                class="edit-mode-btn"
                :type="isEditMode ? 'primary' : 'default'"
                :disabled="!canPreview || isGenerating"
                @click="handleToggleEditMode"
              >
                {{ isEditMode ? '退出编辑' : '编辑' }}
              </a-button>
            </template>
          </PromptInputBox>
        </div>
      </div>

      <div class="preview-panel">
        <div class="preview-toolbar">
          <span class="preview-title">生成后的网页展示</span>
          <a
            class="preview-open-link"
            :href="canPreview ? previewUrl : undefined"
            :class="{ 'is-disabled': !canPreview }"
            target="_blank"
            rel="noopener noreferrer"
            @click="handleOpenPreview"
          >
            <svg
              class="preview-open-icon"
              viewBox="0 0 16 16"
              width="14"
              height="14"
              aria-hidden="true"
            >
              <path
                fill="currentColor"
                d="M6.5 2a.5.5 0 0 0 0 1H12.3L5.15 10.15a.5.5 0 1 0 .7.7L13 3.71V9.5a.5.5 0 0 0 1 0v-7A.5.5 0 0 0 13.5 2h-7z"
              />
              <path
                fill="currentColor"
                d="M3 4.5A1.5 1.5 0 0 1 4.5 3H8a.5.5 0 0 1 0 1H4.5a.5.5 0 0 0-.5.5v7a.5.5 0 0 0 .5.5h7a.5.5 0 0 0 .5-.5V8a.5.5 0 0 1 1 0v3.5A1.5 1.5 0 0 1 11.5 13h-7A1.5 1.5 0 0 1 3 11.5v-7z"
              />
            </svg>
            新窗口打开
          </a>
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
  background: #fff;
}

.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  height: 52px;
  padding: 0 16px;
  background: #fff;
  border-bottom: 1px solid #f0f0f0;
}

.app-name {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  font-size: 16px;
  font-weight: 600;
}

.app-name-text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-type-tag {
  flex-shrink: 0;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  line-height: 20px;
}

.app-logo {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.chat-body {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(0, 3fr);
  flex: 1;
  min-height: 0;
  overflow: hidden;
  background: #fff;
}

.chat-panel {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  background: #fff;
  border-right: 1px solid #f0f0f0;
}

.messages-area {
  flex: 1;
  overflow-y: auto;
  padding: 12px 16px;
}

.load-more-wrap {
  display: flex;
  justify-content: center;
  margin-bottom: 8px;
}

.messages-empty {
  padding: 48px 0;
  text-align: center;
  color: rgba(0, 0, 0, 0.45);
}

.message-row {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 16px;
}

.message-row.is-user {
  flex-direction: row-reverse;
}

.message-row.is-ai {
  flex-direction: row;
}

.message-avatar {
  flex-shrink: 0;
}

.message-bubble {
  max-width: calc(88% - 46px);
  min-width: 0;
  padding: 12px 14px;
  border-radius: 14px;
  overflow-x: auto;
}

.message-bubble.user {
  background: #f0f0f0;
}

.message-bubble.ai {
  background: #fff;
  border: 1px solid #f0f0f0;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.04);
}

.message-content {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: inherit;
  font-size: 14px;
  line-height: 1.6;
}

.chat-input-area {
  display: flex;
  flex-direction: column;
}

.selected-element-alert {
  margin: 0 16px 8px;
}

.edit-mode-btn {
  height: 40px;
  padding: 0 14px;
  border-radius: 20px;
}

.chat-input-area :deep(.prompt-input-box.is-chat) {
  margin-top: 0;
}

.preview-panel {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  background: #eef2f6;
}

.preview-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  height: 44px;
  padding: 0 16px;
  background: #fff;
  border-bottom: 1px solid #f0f0f0;
}

.preview-title {
  font-size: 14px;
  color: rgba(0, 0, 0, 0.88);
}

.preview-open-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #1677ff;
  font-size: 14px;
  text-decoration: none;
  cursor: pointer;
}

.preview-open-link:hover {
  color: #4096ff;
}

.preview-open-link.is-disabled {
  color: rgba(0, 0, 0, 0.25);
  cursor: not-allowed;
}

.preview-open-icon {
  display: block;
  flex-shrink: 0;
}

.preview-frame-wrap,
.preview-empty {
  flex: 1;
  min-height: 0;
  width: 100%;
}

.preview-frame {
  width: 100%;
  height: 100%;
  border: 0;
  background: #fff;
}

.preview-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(0, 0, 0, 0.45);
}

@media (max-width: 960px) {
  .chat-body {
    grid-template-columns: 1fr;
    grid-template-rows: 1fr 1fr;
  }

  .chat-panel {
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
  }
}
</style>
