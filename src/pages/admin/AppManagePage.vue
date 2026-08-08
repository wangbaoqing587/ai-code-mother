<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { message, Modal } from 'ant-design-vue'
import type { TableColumnsType } from 'ant-design-vue'
import {
  deleteAppByAdmin,
  listAppVoByPageByAdmin,
  updateAppByAdmin,
} from '@/api/appController'
import { GOOD_APP_PRIORITY } from '@/constants/app'
import { CODE_GEN_TYPE_OPTIONS, formatCodeGenType } from '@/constants/codeGenType'
import { formatDateTime } from '@/utils/time'

const isLoading = ref(false)
const dataList = ref<API.AppVO[]>([])
const total = ref(0)

const searchParams = reactive<API.AppQueryRequest>({
  pageNum: 1,
  pageSize: 10,
  id: undefined,
  appName: undefined,
  cover: undefined,
  initPrompt: undefined,
  codeGenType: undefined,
  deployKey: undefined,
  priority: undefined,
  userId: undefined,
})

const columns: TableColumnsType = [
  { title: 'id', dataIndex: 'id', width: 80 },
  { title: '应用名称', dataIndex: 'appName', ellipsis: true },
  { title: '封面', dataIndex: 'cover', key: 'cover', width: 80 },
  { title: '初始化提示词', dataIndex: 'initPrompt', ellipsis: true },
  { title: '生成类型', dataIndex: 'codeGenType', key: 'codeGenType', width: 160 },
  { title: '优先级', dataIndex: 'priority', width: 90 },
  { title: '创建者', dataIndex: 'user', key: 'user', width: 120 },
  { title: '创建时间', dataIndex: 'createTime', key: 'createTime', width: 180 },
  { title: '部署时间', dataIndex: 'deployedTime', key: 'deployedTime', width: 180 },
  { title: '操作', key: 'action', width: 260 },
]

async function fetchData() {
  isLoading.value = true
  try {
    const res = await listAppVoByPageByAdmin({ ...searchParams })
    if (res.data.code === 0 && res.data.data) {
      dataList.value = res.data.data.records ?? []
      total.value = res.data.data.totalRow ?? 0
      return
    }
    message.error('获取应用列表失败：' + (res.data.message ?? '未知错误'))
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
  searchParams.appName = undefined
  searchParams.cover = undefined
  searchParams.initPrompt = undefined
  searchParams.codeGenType = undefined
  searchParams.deployKey = undefined
  searchParams.priority = undefined
  searchParams.userId = undefined
  searchParams.pageNum = 1
  fetchData()
}

function handlePageChange(page: number, pageSize: number) {
  searchParams.pageNum = page
  searchParams.pageSize = pageSize
  fetchData()
}

function handleEdit(record: API.AppVO) {
  if (!record.id) {
    return
  }
  window.open(`/app/edit/${record.id}`, '_blank')
}

function isFeaturedApp(record: API.AppVO) {
  return record.priority === GOOD_APP_PRIORITY
}

function handleFeatured(record: API.AppVO) {
  if (!record.id) {
    return
  }
  Modal.confirm({
    title: '确认设为精选？',
    content: `应用：${record.appName || record.id}，优先级将设为 ${GOOD_APP_PRIORITY}`,
    okText: '确定',
    cancelText: '取消',
    async onOk() {
      const res = await updateAppByAdmin({
        id: record.id,
        priority: GOOD_APP_PRIORITY,
      })
      if (res.data.code === 0) {
        message.success('已设为精选')
        await fetchData()
        return
      }
      message.error('操作失败：' + (res.data.message ?? '未知错误'))
    },
  })
}

function handleCancelFeatured(record: API.AppVO) {
  if (!record.id) {
    return
  }
  Modal.confirm({
    title: '确认取消精选？',
    content: `应用：${record.appName || record.id}，优先级将设为 0`,
    okText: '确定',
    cancelText: '取消',
    async onOk() {
      const res = await updateAppByAdmin({
        id: record.id,
        priority: 0,
      })
      if (res.data.code === 0) {
        message.success('已取消精选')
        await fetchData()
        return
      }
      message.error('操作失败：' + (res.data.message ?? '未知错误'))
    },
  })
}

function handleDelete(record: API.AppVO) {
  if (!record.id) {
    return
  }
  Modal.confirm({
    title: '确认删除该应用？',
    content: `应用：${record.appName || record.id}`,
    okText: '确定',
    cancelText: '取消',
    okType: 'danger',
    async onOk() {
      const res = await deleteAppByAdmin({ id: record.id })
      if (res.data.code === 0) {
        message.success('删除成功')
        await fetchData()
        return
      }
      message.error('删除失败：' + (res.data.message ?? '未知错误'))
    },
  })
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="app-manage-page">
    <a-form layout="inline" class="search-form" :model="searchParams" @finish="handleSearch">
      <a-form-item label="id">
        <a-input v-model:value="searchParams.id" placeholder="应用 id" allow-clear style="width: 180px" />
      </a-form-item>
      <a-form-item label="应用名称">
        <a-input v-model:value="searchParams.appName" placeholder="请输入应用名称" allow-clear />
      </a-form-item>
      <a-form-item label="生成类型">
        <a-select
          v-model:value="searchParams.codeGenType"
          placeholder="请选择生成类型"
          allow-clear
          style="width: 180px"
          :options="CODE_GEN_TYPE_OPTIONS"
        />
      </a-form-item>
      <a-form-item label="用户 id">
        <a-input-number
          v-model:value="searchParams.userId"
          placeholder="用户 id"
          style="width: 140px"
        />
      </a-form-item>
      <a-form-item label="优先级">
        <a-input-number
          v-model:value="searchParams.priority"
          placeholder="优先级"
          style="width: 120px"
        />
      </a-form-item>
      <a-form-item>
        <a-space>
          <a-button type="primary" html-type="submit">搜索</a-button>
          <a-button @click="handleReset">重置</a-button>
        </a-space>
      </a-form-item>
    </a-form>

    <a-table
      :columns="columns"
      :data-source="dataList"
      :loading="isLoading"
      row-key="id"
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
        <template v-if="column.key === 'cover'">
          <a-avatar
            shape="square"
            :src="(record as API.AppVO).cover || undefined"
            :size="40"
          >
            {{ (record as API.AppVO).appName?.slice(0, 1) || 'A' }}
          </a-avatar>
        </template>
        <template v-else-if="column.key === 'codeGenType'">
          {{ formatCodeGenType((record as API.AppVO).codeGenType) }}
        </template>
        <template v-else-if="column.key === 'user'">
          {{ (record as API.AppVO).user?.userName || '-' }}
        </template>
        <template v-else-if="column.key === 'createTime'">
          {{ formatDateTime((record as API.AppVO).createTime) }}
        </template>
        <template v-else-if="column.key === 'deployedTime'">
          {{ formatDateTime((record as API.AppVO).deployedTime) }}
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space>
            <a-button type="link" @click="handleEdit(record as API.AppVO)">编辑</a-button>
            <a-button
              v-if="isFeaturedApp(record as API.AppVO)"
              type="link"
              @click="handleCancelFeatured(record as API.AppVO)"
            >
              取消精选
            </a-button>
            <a-button v-else type="link" @click="handleFeatured(record as API.AppVO)">精选</a-button>
            <a-button type="link" danger @click="handleDelete(record as API.AppVO)">删除</a-button>
          </a-space>
        </template>
      </template>
    </a-table>
  </div>
</template>

<style scoped>
.app-manage-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.search-form {
  row-gap: 12px;
}
</style>
