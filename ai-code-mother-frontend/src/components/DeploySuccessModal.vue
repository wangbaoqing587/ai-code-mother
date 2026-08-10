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
    @update:open="handleOpenChange"
  >
    <div class="deploy-success-content">
      <span class="deploy-url">{{ url }}</span>
      <button class="copy-btn" type="button" title="复制" @click="copyDeployUrl(url)">
        <img :src="iconCopy" alt="复制" />
      </button>
    </div>
    <div class="deploy-success-actions">
      <a-button type="primary" @click="openDeployedSite(url)">打开网站</a-button>
      <a-button @click="close">关闭</a-button>
    </div>
  </a-modal>
</template>

<style scoped>
.deploy-success-content {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 8px 0 24px;
  color: rgba(0, 0, 0, 0.88);
}

.deploy-url {
  flex: 1;
  min-width: 0;
  word-break: break-all;
}

.copy-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 28px;
  height: 28px;
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
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
}
</style>
