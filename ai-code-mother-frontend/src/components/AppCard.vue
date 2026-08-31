<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { icProductCoverDefault } from '@/assets'
import UserAvatar from '@/components/UserAvatar.vue'
import CodeGenTypeTag from '@/components/CodeGenTypeTag.vue'
import AppCommentModal from '@/components/AppCommentModal.vue'
import { toggleAppLike } from '@/api/appController'
import { getDeployUrl } from '@/config/env'
import { useLoginUserStore } from '@/stores/loginUser'

interface Props {
  app: API.AppVO
  restrictChatToOwner?: boolean
  variant?: 'default' | 'compact'
}

const props = withDefaults(defineProps<Props>(), {
  restrictChatToOwner: false,
  variant: 'default',
})
const router = useRouter()
const loginUserStore = useLoginUserStore()
const commentModalOpen = ref(false)
const likeCount = ref(Number(props.app.likeCount) || 0)
const commentCount = ref(Number(props.app.commentCount) || 0)
const hasLiked = ref(props.app.hasLiked ?? false)
const liking = ref(false)

watch(
  () => props.app,
  (app) => {
    likeCount.value = Number(app.likeCount) || 0
    commentCount.value = Number(app.commentCount) || 0
    hasLiked.value = app.hasLiked ?? false
  },
  { deep: true },
)

const coverUrl = computed(() => props.app.cover || icProductCoverDefault)
const authorName = computed(() => props.app.user?.userName || '未知用户')
const authorAvatar = computed(() => props.app.user?.userAvatar || '')
const hasDeployKey = computed(() => !!props.app.deployKey)
const deployUrl = computed(() =>
  props.app.deployKey ? getDeployUrl(props.app.deployKey, props.app.codeGenType) : '',
)
const showViewChat = computed(() => {
  if (!props.restrictChatToOwner) {
    return true
  }
  const loginUserId = loginUserStore.loginUser.id
  if (!loginUserId || !props.app.userId) {
    return false
  }
  return String(loginUserId) === String(props.app.userId)
})

const avatarSize = computed(() => (props.variant === 'compact' ? 28 : 36))

function handleViewChat() {
  if (!props.app.id) {
    return
  }
  router.push(`/app/chat/${props.app.id}`)
}

function handleViewWork() {
  if (!deployUrl.value) {
    return
  }
  window.open(deployUrl.value, '_blank')
}

function handleViewAuthor(event: Event) {
  event.stopPropagation()
  if (!props.app.userId) {
    return
  }
  router.push(`/user/profile/${props.app.userId}`)
}

async function handleToggleLike(event: Event) {
  event.stopPropagation()
  if (!props.app.id) {
    return
  }
  if (!loginUserStore.loginUser.id) {
    message.warning('请先登录')
    return
  }
  if (liking.value) {
    return
  }
  liking.value = true
  try {
    const res = await toggleAppLike({ appId: props.app.id })
    if (res.data.code === 0 && res.data.data) {
      hasLiked.value = !!res.data.data.liked
      likeCount.value = Number(res.data.data.likeCount) || 0
    } else {
      message.error(res.data.message || '操作失败')
    }
  } catch {
    message.error('点赞失败，请稍后重试')
  } finally {
    liking.value = false
  }
}

function handleOpenComment(event: Event) {
  event.stopPropagation()
  commentModalOpen.value = true
}

function handleCommentAdded() {
  commentCount.value = (Number(commentCount.value) || 0) + 1
}
</script>

<template>
  <div class="app-card" :class="{ 'app-card--compact': variant === 'compact' }">
    <div class="app-card-cover">
      <img :src="coverUrl" :alt="app.appName || '应用封面'" />
      <div class="app-card-actions">
        <button
          v-if="showViewChat"
          class="action-btn primary"
          type="button"
          @click="handleViewChat"
        >
          查看对话
        </button>
        <button
          v-if="hasDeployKey"
          class="action-btn"
          type="button"
          @click="handleViewWork"
        >
          查看作品
        </button>
      </div>
    </div>
    <div class="app-card-meta">
      <button
        v-if="app.userId"
        type="button"
        class="author-avatar-btn"
        @click="handleViewAuthor"
      >
        <UserAvatar :size="avatarSize" :src="authorAvatar" />
      </button>
      <UserAvatar v-else :size="avatarSize" :src="authorAvatar" />
      <div class="app-card-text">
        <div class="app-card-top">
          <div class="app-card-title">{{ app.appName || '未命名应用' }}</div>
          <CodeGenTypeTag :code-gen-type="app.codeGenType" />
        </div>
        <div class="app-card-sub">
          <span class="app-card-author">{{ authorName }}</span>
          <div class="app-card-stats">
            <button
              type="button"
              class="stat-btn"
              :class="{ active: hasLiked }"
              :disabled="liking"
              @click="handleToggleLike"
            >
              <span class="stat-icon">♥</span>
              <span>{{ likeCount }}</span>
            </button>
            <button type="button" class="stat-btn" @click="handleOpenComment">
              <span class="stat-icon">💬</span>
              <span>{{ commentCount }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
    <AppCommentModal
      v-model:open="commentModalOpen"
      :app="app"
      @comment-added="handleCommentAdded"
    />
  </div>
</template>

<style scoped>
.app-card {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #fff;
  border: 2px solid rgba(136, 216, 176, 0.2);
  border-radius: 20px;
  box-shadow:
    0 8px 28px rgba(136, 216, 176, 0.12),
    0 2px 8px rgba(26, 46, 53, 0.04);
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease,
    border-color 0.2s ease;
}

.app-card:hover {
  transform: translateY(-2px);
  border-color: rgba(136, 216, 176, 0.45);
  box-shadow:
    0 14px 36px rgba(136, 216, 176, 0.2),
    0 4px 12px rgba(26, 46, 53, 0.06);
}

.app-card-cover {
  position: relative;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  background: linear-gradient(135deg, #c8f0dc 0%, #b8e4f5 50%, #fff0c2 100%);
}

.app-card-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.app-card-actions {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  pointer-events: none;
}

.action-btn {
  height: 36px;
  padding: 0 16px;
  border: 1px solid rgba(45, 154, 120, 0.65);
  border-radius: 999px;
  background: #fff;
  color: rgba(0, 0, 0, 0.88);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  pointer-events: auto;
  box-shadow: 0 4px 12px rgba(26, 46, 53, 0.1);
}

.action-btn.primary {
  background: #5bc4a0;
  border-color: #8ed9bf;
  color: #fff;
  box-shadow: 0 4px 12px rgba(91, 196, 160, 0.35);
}

.app-card-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px 16px;
}

.author-avatar-btn {
  display: inline-flex;
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 50%;
  transition: transform 0.2s ease;
}

.author-avatar-btn:hover {
  transform: scale(1.05);
}

.app-card-text {
  flex: 1;
  min-width: 0;
}

.app-card-top {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.app-card-title {
  flex: 1;
  min-width: 0;
  font-size: 16px;
  font-weight: 600;
  color: rgba(0, 0, 0, 0.88);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-card-sub {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: 4px;
  min-width: 0;
}

.app-card-author {
  flex: 1;
  min-width: 0;
  font-size: 13px;
  color: rgba(0, 0, 0, 0.45);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-card-stats {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
  margin-right: 6px;
}

.stat-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  border: none;
  background: transparent;
  font-size: 12px;
  color: rgba(0, 0, 0, 0.45);
  cursor: pointer;
}

.stat-btn.active {
  color: #ef4444;
}

.stat-btn:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.stat-icon {
  font-size: 12px;
  line-height: 1;
}

.app-card--compact {
  border-radius: 14px;
  border-width: 1.5px;
  box-shadow:
    0 6px 20px rgba(136, 216, 176, 0.1),
    0 1px 6px rgba(26, 46, 53, 0.04);
}

.app-card--compact:hover {
  box-shadow:
    0 10px 28px rgba(136, 216, 176, 0.16),
    0 2px 8px rgba(26, 46, 53, 0.06);
}

.app-card--compact .app-card-actions {
  gap: 8px;
}

.app-card--compact .action-btn {
  height: 30px;
  padding: 0 12px;
  font-size: 12px;
}

.app-card--compact .app-card-meta {
  gap: 8px;
  padding: 10px 12px 12px;
}

.app-card--compact .app-card-top {
  gap: 6px;
}

.app-card--compact .app-card-title {
  font-size: 14px;
}

.app-card--compact .app-card-sub {
  gap: 6px;
  margin-top: 2px;
}

.app-card--compact .app-card-author {
  font-size: 12px;
}

.app-card--compact .app-card-stats {
  gap: 6px;
  margin-right: 2px;
}

.app-card--compact .stat-btn {
  font-size: 11px;
}

.app-card--compact .stat-icon {
  font-size: 11px;
}

.app-card--compact :deep(.code-gen-type-tag) {
  padding: 1px 8px;
  font-size: 11px;
  line-height: 18px;
}
</style>
