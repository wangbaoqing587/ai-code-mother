<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { icProductCoverDefault } from '@/assets'
import UserAvatar from '@/components/UserAvatar.vue'
import CodeGenTypeTag from '@/components/CodeGenTypeTag.vue'
import { getDeployUrl } from '@/config/env'
import { useLoginUserStore } from '@/stores/loginUser'

interface Props {
  app: API.AppVO
  restrictChatToOwner?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  restrictChatToOwner: false,
})
const router = useRouter()
const loginUserStore = useLoginUserStore()

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
</script>

<template>
  <div class="app-card">
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
      <UserAvatar :size="36" :src="authorAvatar" />
      <div class="app-card-text">
        <div class="app-card-top">
          <div class="app-card-title">{{ app.appName || '未命名应用' }}</div>
          <CodeGenTypeTag :code-gen-type="app.codeGenType" />
        </div>
        <div class="app-card-sub">{{ authorName }}</div>
      </div>
    </div>
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
  margin-top: 4px;
  font-size: 13px;
  color: rgba(0, 0, 0, 0.45);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
