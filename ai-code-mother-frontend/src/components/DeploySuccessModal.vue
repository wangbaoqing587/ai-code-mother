<script setup lang="ts">
import { message } from 'ant-design-vue'
import { iconCopy } from '@/assets'

interface Props {
  open: boolean
  url: string
}

defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
}>()

function handleOpenChange(value: boolean) {
  emit('update:open', value)
}

function openDeployedSite(url: string) {
  if (url) {
    window.open(url, '_blank')
  }
}

async function copyDeployUrl(url: string) {
  if (!url) {
    return
  }
  try {
    await navigator.clipboard.writeText(url)
    message.success('链接已复制')
  } catch {
    message.error('复制失败')
  }
}

function close() {
  emit('update:open', false)
}
</script>

<template>
  <a-modal
    :open="open"
    title="部署成功"
    :footer="null"
    :width="480"
    centered
    wrap-class-name="mint-modal-wrap deploy-success-modal-wrap"
    @update:open="handleOpenChange"
  >
    <p class="deploy-success-tip">网站已成功部署，可通过以下链接访问</p>
    <div class="deploy-url-box">
      <span class="deploy-url">{{ url }}</span>
      <button class="copy-btn" type="button" title="复制" @click="copyDeployUrl(url)">
        <img :src="iconCopy" alt="复制" />
      </button>
    </div>
    <div class="deploy-success-actions">
      <button type="button" class="deploy-action-btn deploy-action-btn-primary" @click="openDeployedSite(url)">
        打开网站
      </button>
      <button type="button" class="deploy-action-btn deploy-action-btn-outline" @click="close">
        关闭
      </button>
    </div>
  </a-modal>
</template>

<style scoped>
.deploy-success-tip {
  margin: 0 0 14px;
  font-size: 14px;
  line-height: 1.6;
  color: #64748b;
}

.deploy-url-box {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border: 1.5px solid rgba(136, 216, 176, 0.45);
  border-radius: 14px;
  background: rgba(245, 251, 248, 0.65);
}

.deploy-url {
  flex: 1;
  min-width: 0;
  font-size: 14px;
  line-height: 1.5;
  word-break: break-all;
  color: #1a2e35;
}

.copy-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 32px;
  height: 32px;
  padding: 0;
  border: none;
  border-radius: 8px;
  background: transparent;
  cursor: pointer;
  transition: background 0.2s ease;
}

.copy-btn:hover {
  background: rgba(136, 216, 176, 0.18);
}

.copy-btn img {
  width: 18px;
  height: 18px;
  object-fit: contain;
  display: block;
}

.deploy-success-actions {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 24px;
}

.deploy-action-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 38px;
  padding: 0 20px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition:
    background 0.2s ease,
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.deploy-action-btn-primary {
  border: none;
  background: #5bc4a0;
  color: #fff;
  box-shadow: 0 4px 14px rgba(91, 196, 160, 0.32);
}

.deploy-action-btn-primary:hover {
  background: #4db892;
}

.deploy-action-btn-outline {
  border: 1.5px solid rgba(136, 216, 176, 0.55);
  background: #fff;
  color: #334155;
}

.deploy-action-btn-outline:hover {
  border-color: rgba(91, 196, 160, 0.75);
  color: #2d9a78;
  background: #f0fdf7;
}
</style>
