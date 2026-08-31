<script setup lang="ts">
import { ref, watch } from 'vue'
import { message } from 'ant-design-vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { addAppComment, listAppComment } from '@/api/appController'
import { formatDateTime } from '@/utils/time'
import { useLoginUserStore } from '@/stores/loginUser'

interface Props {
  open: boolean
  app: API.AppVO
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  commentAdded: []
}>()

const loginUserStore = useLoginUserStore()
const comments = ref<API.AppCommentVO[]>([])
const loading = ref(false)
const submitting = ref(false)
const content = ref('')

async function loadComments() {
  if (!props.app.id) {
    return
  }
  loading.value = true
  try {
    const res = await listAppComment({ appId: props.app.id, pageSize: 50 })
    if (res.data.code === 0) {
      comments.value = res.data.data?.records || []
    }
  } finally {
    loading.value = false
  }
}

watch(
  () => props.open,
  (open) => {
    if (open) {
      content.value = ''
      loadComments()
    }
  },
)

function handleOpenChange(value: boolean) {
  emit('update:open', value)
}

async function handleSubmit() {
  if (!props.app.id) {
    return
  }
  if (!loginUserStore.loginUser.id) {
    message.warning('请先登录')
    return
  }
  const text = content.value.trim()
  if (!text) {
    message.warning('请输入评论内容')
    return
  }
  submitting.value = true
  try {
    const res = await addAppComment({ appId: props.app.id, content: text })
    if (res.data.code === 0) {
      content.value = ''
      await loadComments()
      emit('commentAdded')
      message.success('评论成功')
    } else {
      message.error(res.data.message || '评论失败')
    }
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <a-modal
    :open="open"
    :title="`${app.appName || '应用'} 的评论`"
    :footer="null"
    :width="480"
    wrap-class-name="mint-modal-wrap app-comment-modal-wrap"
    @update:open="handleOpenChange"
  >
    <div class="comment-input">
      <a-textarea
        v-model:value="content"
        :rows="3"
        :maxlength="1024"
        placeholder="写下你的评论..."
      />
      <button
        type="button"
        class="submit-btn"
        :disabled="submitting"
        @click="handleSubmit"
      >
        发表评论
      </button>
    </div>
    <a-spin :spinning="loading">
      <div v-if="comments.length" class="comment-list">
        <div v-for="item in comments" :key="item.id" class="comment-item">
          <UserAvatar :size="32" :src="item.user?.userAvatar || ''" />
          <div class="comment-body">
            <div class="comment-meta">
              <span class="comment-user">{{ item.user?.userName || '未知用户' }}</span>
              <span class="comment-time">{{ formatDateTime(item.createTime) }}</span>
            </div>
            <div class="comment-content">{{ item.content }}</div>
          </div>
        </div>
      </div>
      <div v-else class="comment-empty">暂无评论，快来抢沙发吧</div>
    </a-spin>
  </a-modal>
</template>

<style scoped>
.comment-input {
  margin-bottom: 16px;
}

.submit-btn {
  margin-top: 10px;
  height: 34px;
  padding: 0 18px;
  border: none;
  border-radius: 999px;
  background: #5bc4a0;
  color: #fff;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.comment-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  max-height: 360px;
  overflow-y: auto;
}

.comment-item {
  display: flex;
  gap: 10px;
}

.comment-body {
  flex: 1;
  min-width: 0;
}

.comment-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.comment-user {
  font-size: 14px;
  font-weight: 600;
  color: #1a2e35;
}

.comment-time {
  font-size: 12px;
  color: #94a3b8;
}

.comment-content {
  font-size: 14px;
  color: #334155;
  line-height: 1.5;
  word-break: break-word;
}

.comment-empty {
  padding: 24px 0;
  text-align: center;
  font-size: 14px;
  color: #94a3b8;
}
</style>
