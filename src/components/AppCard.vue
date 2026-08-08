<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import UserAvatar from '@/components/UserAvatar.vue'
import { getDeployUrl } from '@/config/env'
import { formatCodeGenType, getCodeGenTypeOption } from '@/constants/codeGenType'

interface Props {
  app: API.AppVO
}

const props = defineProps<Props>()
const router = useRouter()

const coverUrl = computed(() => props.app.cover || '')
const typeTag = computed(() => {
  const option = getCodeGenTypeOption(props.app.codeGenType)
  return {
    label: option?.label || formatCodeGenType(props.app.codeGenType) || '应用',
    color: option?.color || '#8c8c8c',
  }
})
const authorName = computed(() => props.app.user?.userName || '未知用户')
const authorAvatar = computed(() => props.app.user?.userAvatar || '')
const hasDeployKey = computed(() => !!props.app.deployKey)
const deployUrl = computed(() =>
  props.app.deployKey ? getDeployUrl(props.app.deployKey, props.app.codeGenType) : '',
)

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
      <img v-if="coverUrl" :src="coverUrl" :alt="app.appName || '应用封面'" />
      <div v-else class="app-card-cover-placeholder">
        {{ app.appName?.slice(0, 1) || 'A' }}
      </div>
      <div class="app-card-actions">
        <button class="action-btn primary" type="button" @click="handleViewChat">查看对话</button>
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
          <span
            class="app-card-tag"
            :style="{ background: typeTag.color + '22', color: typeTag.color }"
          >
            {{ typeTag.label }}
          </span>
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
  border-radius: 16px;
  box-shadow: 0 8px 24px rgba(15, 35, 52, 0.06);
  transition:
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.app-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 12px 28px rgba(15, 35, 52, 0.1);
}

.app-card-cover {
  position: relative;
  aspect-ratio: 16 / 10;
  overflow: hidden;
  background: linear-gradient(135deg, #d9f3ef, #d7e9f8);
}

.app-card-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.app-card-cover-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  font-size: 40px;
  font-weight: 700;
  color: rgba(0, 0, 0, 0.25);
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
  border: none;
  border-radius: 8px;
  background: #fff;
  color: rgba(0, 0, 0, 0.88);
  font-size: 14px;
  cursor: pointer;
  pointer-events: auto;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.action-btn.primary {
  background: #1677ff;
  color: #fff;
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

.app-card-tag {
  flex-shrink: 0;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 12px;
  line-height: 20px;
}
</style>
