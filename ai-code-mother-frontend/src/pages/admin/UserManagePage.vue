<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { message, Modal } from 'ant-design-vue'
import type { TableColumnsType } from 'ant-design-vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { deleteUser, listUserVoByPage, updateUser } from '@/api/userController'
import { formatDateTime } from '@/utils/time'

const isLoading = ref(false)
const isModalOpen = ref(false)
const isSubmitting = ref(false)
const dataList = ref<API.UserVO[]>([])
const total = ref(0)

const searchParams = reactive<API.UserQueryRequest>({
  pageNum: 1,
  pageSize: 10,
  userAccount: undefined,
  userName: undefined,
  userRole: undefined,
})

const formState = reactive<API.UserUpdateRequest>({
  id: undefined,
  userName: '',
  userAvatar: '',
  userProfile: '',
  userRole: 'user',
})

const columns: TableColumnsType = [
  { title: 'id', dataIndex: 'id', width: 80 },
  { title: '账号', dataIndex: 'userAccount' },
  { title: '用户名', dataIndex: 'userName' },
  { title: '头像', dataIndex: 'userAvatar', key: 'userAvatar' },
  { title: '简介', dataIndex: 'userProfile', ellipsis: true },
  { title: '角色', dataIndex: 'userRole', width: 100 },
  { title: '创建时间', dataIndex: 'createTime', key: 'createTime', width: 180 },
  { title: '操作', key: 'action', width: 160 },
]

function isAdminUser(record: API.UserVO) {
  return record.userRole === 'admin'
}

async function fetchData() {
  isLoading.value = true
  try {
    const res = await listUserVoByPage({ ...searchParams })
    if (res.data.code === 0 && res.data.data) {
      dataList.value = res.data.data.records ?? []
      total.value = res.data.data.totalRow ?? 0
      return
    }
    message.error('获取用户列表失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isLoading.value = false
  }
}

function handleSearch() {
  searchParams.pageNum = 1
  fetchData()
}

function handleReset() {
  searchParams.userAccount = undefined
  searchParams.userName = undefined
  searchParams.userRole = undefined
  searchParams.pageNum = 1
  fetchData()
}

function handlePageChange(page: number, pageSize: number) {
  searchParams.pageNum = page
  searchParams.pageSize = pageSize
  fetchData()
}

function openEditModal(record: API.UserVO) {
  if (isAdminUser(record)) {
    return
  }
  formState.id = record.id
  formState.userName = record.userName
  formState.userAvatar = record.userAvatar
  formState.userProfile = record.userProfile
  formState.userRole = record.userRole ?? 'user'
  isModalOpen.value = true
}

async function handleSubmit() {
  isSubmitting.value = true
  try {
    const res = await updateUser({
      id: formState.id,
      userName: formState.userName,
      userAvatar: formState.userAvatar,
      userProfile: formState.userProfile,
      userRole: formState.userRole,
    })
    if (res.data.code === 0) {
      message.success('更新成功')
      isModalOpen.value = false
      await fetchData()
      return
    }
    message.error('更新失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isSubmitting.value = false
  }
}

function handleDelete(record: API.UserVO) {
  if (isAdminUser(record)) {
    return
  }
  Modal.confirm({
    title: '确认删除该用户？',
    content: `账号：${record.userAccount}`,
    okText: '确定',
    cancelText: '取消',
    okType: 'danger',
    async onOk() {
      const res = await deleteUser({ id: record.id })
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
  <div class="user-manage-page">
    <a-form layout="inline" class="search-form" :model="searchParams" @finish="handleSearch">
      <a-form-item label="账号">
        <a-input v-model:value="searchParams.userAccount" placeholder="请输入账号" allow-clear />
      </a-form-item>
      <a-form-item label="用户名">
        <a-input v-model:value="searchParams.userName" placeholder="请输入用户名" allow-clear />
      </a-form-item>
      <a-form-item label="角色">
        <a-select
          v-model:value="searchParams.userRole"
          placeholder="请选择角色"
          allow-clear
          style="width: 140px"
          :options="[
            { label: '用户', value: 'user' },
            { label: '管理员', value: 'admin' },
          ]"
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
        <template v-if="column.key === 'userAvatar'">
          <UserAvatar :src="(record as API.UserVO).userAvatar" />
        </template>
        <template v-else-if="column.key === 'createTime'">
          {{ formatDateTime((record as API.UserVO).createTime) }}
        </template>
        <template v-else-if="column.key === 'action'">
          <a-space v-if="!isAdminUser(record as API.UserVO)">
            <a-button type="link" @click="openEditModal(record as API.UserVO)">编辑</a-button>
            <a-button type="link" danger @click="handleDelete(record as API.UserVO)">删除</a-button>
          </a-space>
          <span v-else>-</span>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="isModalOpen"
      title="编辑用户"
      :confirm-loading="isSubmitting"
      @ok="handleSubmit"
    >
      <a-form layout="vertical" :model="formState">
        <a-form-item label="用户名">
          <a-input v-model:value="formState.userName" placeholder="请输入用户名" />
        </a-form-item>
        <a-form-item label="头像">
          <a-input v-model:value="formState.userAvatar" placeholder="请输入头像 URL" />
        </a-form-item>
        <a-form-item label="简介">
          <a-textarea v-model:value="formState.userProfile" placeholder="请输入简介" :rows="3" />
        </a-form-item>
        <a-form-item label="角色">
          <a-select
            v-model:value="formState.userRole"
            :options="[
              { label: '用户', value: 'user' },
              { label: '管理员', value: 'admin' },
            ]"
          />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<style scoped>
.user-manage-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.search-form {
  row-gap: 12px;
}
</style>
