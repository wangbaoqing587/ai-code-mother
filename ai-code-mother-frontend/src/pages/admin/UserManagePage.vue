<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { message } from 'ant-design-vue'
import type { TableColumnsType } from 'ant-design-vue'
import UserAvatar from '@/components/UserAvatar.vue'
import AdminPageLayout from '@/components/AdminPageLayout.vue'
import { deleteUser, listUserVoByPage, updateUser } from '@/api/userController'
import { showConfirmModal } from '@/utils/modal'
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
  { title: 'id', dataIndex: 'id', width: '6%', align: 'center' },
  { title: '账号', dataIndex: 'userAccount', width: '12%', ellipsis: true },
  { title: '昵称', dataIndex: 'userName', width: '10%', ellipsis: true },
  { title: '头像', dataIndex: 'userAvatar', key: 'userAvatar', width: '6%', align: 'center' },
  { title: '简介', dataIndex: 'userProfile', key: 'userProfile', width: '18%', ellipsis: true },
  { title: '角色', dataIndex: 'userRole', width: '8%', align: 'center' },
  { title: '创建时间', dataIndex: 'createTime', key: 'createTime', width: '18%' },
  { title: '操作', key: 'action', width: '22%', align: 'left' },
]

const EMPTY_USER_PROFILE_TEXT = '该用户还没有填写简介'

function formatUserProfile(profile?: string) {
  return profile?.trim() || EMPTY_USER_PROFILE_TEXT
}

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
  showConfirmModal({
    variant: 'admin',
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
  <AdminPageLayout title="用户管理">
    <div class="admin-panel">
      <a-form layout="inline" class="search-form" :model="searchParams" @finish="handleSearch">
      <a-form-item label="账号">
        <a-input v-model:value="searchParams.userAccount" placeholder="请输入账号" allow-clear />
      </a-form-item>
      <a-form-item label="昵称">
        <a-input v-model:value="searchParams.userName" placeholder="请输入昵称" allow-clear />
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
        <template v-if="column.key === 'userAvatar'">
          <UserAvatar :src="(record as API.UserVO).userAvatar" />
        </template>
        <template v-else-if="column.key === 'userProfile'">
          <span
            :class="{ 'empty-profile-text': !((record as API.UserVO).userProfile?.trim()) }"
          >
            {{ formatUserProfile((record as API.UserVO).userProfile) }}
          </span>
        </template>
        <template v-else-if="column.key === 'createTime'">
          {{ formatDateTime((record as API.UserVO).createTime) }}
        </template>
        <template v-else-if="column.key === 'action'">
          <div v-if="!isAdminUser(record as API.UserVO)" class="table-action-cell">
            <a-space :size="8">
              <a-button
                size="small"
                class="table-action-btn table-action-btn--edit"
                @click="openEditModal(record as API.UserVO)"
              >
                编辑
              </a-button>
              <a-button
                size="small"
                class="table-action-btn table-action-btn--delete"
                @click="handleDelete(record as API.UserVO)"
              >
                删除
              </a-button>
            </a-space>
          </div>
          <span v-else>-</span>
        </template>
      </template>
    </a-table>
    </div>

    <a-modal
      v-model:open="isModalOpen"
      title="编辑用户"
      wrap-class-name="admin-modal-wrap"
      ok-text="保存"
      cancel-text="取消"
      :confirm-loading="isSubmitting"
      @ok="handleSubmit"
    >
      <a-form layout="vertical" :model="formState">
        <a-form-item
          label="昵称"
          name="userName"
          :rules="[{ max: 12, message: '昵称不能超过 12 个字符' }]"
        >
          <a-input v-model:value="formState.userName" placeholder="请输入昵称" :maxlength="12" />
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
  </AdminPageLayout>
</template>
