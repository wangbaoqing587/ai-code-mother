<script setup lang="ts">
import { computed } from 'vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { formatDateTime } from '@/utils/time'

interface Props {
  open: boolean
  app: API.AppVO
  canManage?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  canManage: false,
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  edit: []
  delete: []
}>()

const creatorName = computed(() => props.app.user?.userName || '未知用户')
const creatorAvatar = computed(() => props.app.user?.userAvatar || '')
const createTimeText = computed(() => formatDateTime(props.app.createTime))

function handleOpenChange(value: boolean) {
  emit('update:open', value)
}
</script>

<template>
  <a-modal
    :open="open"
    title="应用详情"
    :footer="null"
    :width="420"
    @update:open="handleOpenChange"
  >
    <div class="detail-section">
      <div class="detail-label">创建者</div>
      <div class="detail-creator">
        <UserAvatar :size="40" :src="creatorAvatar" />
        <span>{{ creatorName }}</span>
      </div>
    </div>
    <div class="detail-section">
      <div class="detail-label">创建时间</div>
      <div class="detail-value">{{ createTimeText }}</div>
    </div>
    <div v-if="canManage" class="detail-actions">
      <a-button @click="emit('edit')">修改</a-button>
      <a-button danger @click="emit('delete')">删除</a-button>
    </div>
  </a-modal>
</template>

<style scoped>
.detail-section {
  margin-bottom: 20px;
}

.detail-label {
  margin-bottom: 8px;
  font-size: 13px;
  color: rgba(0, 0, 0, 0.45);
}

.detail-creator {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  font-weight: 500;
}

.detail-value {
  font-size: 15px;
  color: rgba(0, 0, 0, 0.88);
}

.detail-actions {
  display: flex;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px solid #f0f0f0;
}
</style>
