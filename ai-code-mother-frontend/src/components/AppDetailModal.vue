<script setup lang="ts">
import { computed } from 'vue'
import CodeGenTypeTag from '@/components/CodeGenTypeTag.vue'
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
const creatorGender = computed(() => props.app.user?.gender ?? 1)
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
    :width="440"
    wrap-class-name="mint-modal-wrap app-detail-modal-wrap"
    @update:open="handleOpenChange"
  >
    <div class="detail-card">
      <div class="detail-section">
        <div class="detail-label">创建者</div>
        <div class="detail-creator">
          <UserAvatar :size="40" :src="creatorAvatar" :gender="creatorGender" />
          <span class="detail-creator-name">{{ creatorName }}</span>
        </div>
      </div>
      <div class="detail-section">
        <div class="detail-label">生成类型</div>
        <div class="detail-value">
          <CodeGenTypeTag v-if="app.codeGenType" :code-gen-type="app.codeGenType" />
          <span v-else>-</span>
        </div>
      </div>
      <div class="detail-section detail-section-last">
        <div class="detail-label">创建时间</div>
        <div class="detail-value">{{ createTimeText }}</div>
      </div>
    </div>
    <div v-if="canManage" class="detail-actions">
      <button type="button" class="detail-action-btn detail-action-btn-edit" @click="emit('edit')">
        修改
      </button>
      <button type="button" class="detail-action-btn detail-action-btn-delete" @click="emit('delete')">
        删除
      </button>
    </div>
  </a-modal>
</template>

<style scoped>
.detail-card {
  padding: 4px 0 0;
}

.detail-section {
  margin-bottom: 18px;
}

.detail-section-last {
  margin-bottom: 0;
}

.detail-label {
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 500;
  letter-spacing: 0.04em;
  color: #94a3b8;
}

.detail-creator {
  display: flex;
  align-items: center;
  gap: 12px;
}

.detail-creator-name {
  font-size: 15px;
  font-weight: 600;
  color: #1a2e35;
}

.detail-value {
  font-size: 15px;
  color: #334155;
}

.detail-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid rgba(136, 216, 176, 0.22);
}

.detail-action-btn {
  height: 34px;
  padding: 0 18px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition:
    background 0.2s ease,
    border-color 0.2s ease,
    color 0.2s ease;
}

.detail-action-btn-edit {
  border: 1.5px solid rgba(136, 216, 176, 0.55);
  background: #fff;
  color: #334155;
}

.detail-action-btn-edit:hover {
  border-color: rgba(91, 196, 160, 0.75);
  color: #2d9a78;
  background: #f0fdf7;
}

.detail-action-btn-delete {
  border: 1.5px solid rgba(248, 113, 113, 0.45);
  background: #fff;
  color: #dc6b6b;
}

.detail-action-btn-delete:hover {
  border-color: rgba(239, 68, 68, 0.55);
  color: #ef4444;
  background: #fef2f2;
}
</style>
