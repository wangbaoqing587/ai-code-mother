<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { message } from 'ant-design-vue'
import type { TableColumnsType } from 'ant-design-vue'
import AdminPageLayout from '@/components/AdminPageLayout.vue'
import { listAllChatHistoryByPageForAdmin } from '@/api/chatHistoryController'
import { formatDateTime } from '@/utils/time'

const MESSAGE_TYPE_OPTIONS = [
  { label: '用户', value: 'user' },
  { label: 'AI', value: 'ai' },
]

const isLoading = ref(false)
const dataList = ref<API.ChatHistory[]>([])
const total = ref(0)

const searchParams = reactive<API.ChatHistoryQueryRequest>({
  pageNum: 1,
  pageSize: 10,
  id: undefined,
  message: undefined,
  messageType: undefined,
  appId: undefined,
  userId: undefined,
})

const columns: TableColumnsType = [
  { title: 'id', dataIndex: 'id', key: 'id', width: 112 },
  { title: '消息内容', dataIndex: 'message', key: 'message' },
  { title: '消息类型', dataIndex: 'messageType', key: 'messageType', width: 100 },
  { title: '应用 id', dataIndex: 'appId', width: 120 },
  { title: '用户 id', dataIndex: 'userId', width: 120 },
  { title: '创建时间', dataIndex: 'createTime', key: 'createTime', width: 180 },
  { title: '更新时间', dataIndex: 'updateTime', key: 'updateTime', width: 180 },
]

function formatMessageType(messageType?: string) {
  if (messageType === 'user' || messageType === 'USER') {
    return '用户'
  }
  if (messageType === 'ai' || messageType === 'AI') {
    return 'AI'
  }
  return messageType || '-'
}

async function fetchData() {
  isLoading.value = true
  try {
    const res = await listAllChatHistoryByPageForAdmin({ ...searchParams })
    if (res.data.code === 0 && res.data.data) {
      dataList.value = res.data.data.records ?? []
      total.value = res.data.data.totalRow ?? 0
      return
    }
    message.error('获取对话列表失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isLoading.value = false
  }
}

function handleSearch() {
  searchParams.pageNum = 1
  fetchData()
}

function handleReset() {
  searchParams.id = undefined
  searchParams.message = undefined
  searchParams.messageType = undefined
  searchParams.appId = undefined
  searchParams.userId = undefined
  searchParams.pageNum = 1
  fetchData()
}

function handlePageChange(page: number, pageSize: number) {
  searchParams.pageNum = page
  searchParams.pageSize = pageSize
  fetchData()
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <AdminPageLayout title="对话管理">
    <div class="admin-panel">
      <a-form layout="inline" class="search-form" :model="searchParams" @finish="handleSearch">
      <a-form-item label="id">
        <a-input-number
          v-model:value="searchParams.id"
          placeholder="消息 id"
          style="width: 160px"
        />
      </a-form-item>
      <a-form-item label="消息内容">
        <a-input
          v-model:value="searchParams.message"
          placeholder="请输入消息内容"
          allow-clear
          style="width: 200px"
        />
      </a-form-item>
      <a-form-item label="消息类型">
        <a-select
          v-model:value="searchParams.messageType"
          placeholder="请选择消息类型"
          allow-clear
          style="width: 140px"
          :options="MESSAGE_TYPE_OPTIONS"
        />
      </a-form-item>
      <a-form-item label="应用 id">
        <a-input
          v-model:value="searchParams.appId"
          placeholder="应用 id"
          allow-clear
          style="width: 160px"
        />
      </a-form-item>
      <a-form-item label="用户 id">
        <a-input-number
          v-model:value="searchParams.userId"
          placeholder="用户 id"
          style="width: 140px"
        />
      </a-form-item>
      <a-form-item>
        <a-space>
          <a-button type="primary" html-type="submit">搜索</a-button>
          <a-button @click="handleReset">重置</a-button>
        </a-space>
      </a-form-item>
    </a-form>
    </div>

    <div class="admin-panel">
    <a-table
      :columns="columns"
      :data-source="dataList"
      :loading="isLoading"
      row-key="id"
      table-layout="fixed"
      :pagination="{
        current: searchParams.pageNum,
        pageSize: searchParams.pageSize,
        total,
        showSizeChanger: true,
        showTotal: (t: number) => `共 ${t} 条`,
        onChange: handlePageChange,
      }"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'id'">
          <span class="table-id-cell">{{ (record as API.ChatHistory).id }}</span>
        </template>
        <template v-else-if="column.key === 'message'">
          <a-popover
            v-if="(record as API.ChatHistory).message"
            trigger="click"
            placement="topLeft"
            overlay-class-name="message-detail-popover"
          >
            <template #content>
              <div class="message-detail-content">{{ (record as API.ChatHistory).message }}</div>
            </template>
            <span class="table-message-cell table-message-cell--clickable">
              {{ (record as API.ChatHistory).message }}
            </span>
          </a-popover>
          <span v-else class="table-message-cell">-</span>
        </template>
        <template v-else-if="column.key === 'messageType'">
          {{ formatMessageType((record as API.ChatHistory).messageType) }}
        </template>
        <template v-else-if="column.key === 'createTime'">
          {{ formatDateTime((record as API.ChatHistory).createTime) }}
        </template>
        <template v-else-if="column.key === 'updateTime'">
          {{ formatDateTime((record as API.ChatHistory).updateTime) }}
        </template>
      </template>
    </a-table>
    </div>
  </AdminPageLayout>
</template>

<style>
.message-detail-popover .message-detail-content {
  max-width: 480px;
  max-height: 280px;
  overflow-y: auto;
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.6;
  color: #334155;
}
</style>
