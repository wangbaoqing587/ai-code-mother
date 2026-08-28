<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import type { UploadProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import { updateUser } from '@/api/userController'
import UserAvatar from '@/components/UserAvatar.vue'
import UserPageLayout from '@/components/UserPageLayout.vue'
import { useLoginUserStore } from '@/stores/loginUser'
import { compressImage } from '@/utils/image'

const MAX_AVATAR_SIZE = 2 * 1024 * 1024
const AVATAR_MAX_EDGE = 256

const ROLE_TEXT_MAP: Record<string, string> = {
  admin: '管理员',
  user: '用户',
}

const EMPTY_PROFILE_TEXT = '还没有填写简介'

const router = useRouter()
const loginUserStore = useLoginUserStore()
const isEditing = ref(false)
const isSubmitting = ref(false)

const formState = reactive({
  userName: '',
  userAvatar: '',
  userProfile: '',
})

const userRoleText = computed(() => {
  const role = loginUserStore.loginUser.userRole
  if (!role) {
    return '-'
  }
  return ROLE_TEXT_MAP[role] ?? role
})

const registerTimeText = computed(() => {
  const createTime = loginUserStore.loginUser.createTime
  if (!createTime) {
    return '-'
  }
  const date = new Date(createTime)
  if (Number.isNaN(date.getTime())) {
    return '-'
  }
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}年${month}月${day}日`
})

const profileText = computed(() => loginUserStore.loginUser.userProfile?.trim() || EMPTY_PROFILE_TEXT)

function syncFormFromLoginUser() {
  formState.userName = loginUserStore.loginUser.userName ?? ''
  formState.userAvatar = loginUserStore.loginUser.userAvatar ?? ''
  formState.userProfile = loginUserStore.loginUser.userProfile ?? ''
}

const beforeAvatarUpload: UploadProps['beforeUpload'] = async (file) => {
  if (!file.type.startsWith('image/')) {
    message.error('只能上传图片文件')
    return false
  }
  if (file.size > MAX_AVATAR_SIZE) {
    message.error('图片大小不能超过 2MB')
    return false
  }
  try {
    formState.userAvatar = await compressImage(file as File, AVATAR_MAX_EDGE)
    message.success('头像已选择')
  } catch {
    message.error('头像读取失败')
  }
  return false
}

function startEdit() {
  syncFormFromLoginUser()
  isEditing.value = true
}

function cancelEdit() {
  syncFormFromLoginUser()
  isEditing.value = false
}

async function handleSave() {
  if (!loginUserStore.loginUser.id) {
    return
  }
  isSubmitting.value = true
  try {
    const res = await updateUser({
      id: loginUserStore.loginUser.id,
      userName: formState.userName,
      userAvatar: formState.userAvatar,
      userProfile: formState.userProfile,
    })
    if (res.data.code === 0) {
      message.success('保存成功')
      await loginUserStore.fetchLoginUser()
      isEditing.value = false
      return
    }
    message.error('保存失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isSubmitting.value = false
  }
}

watch(
  () => loginUserStore.loginUser.id,
  () => {
    if (!isEditing.value) {
      syncFormFromLoginUser()
    }
  },
)

onMounted(async () => {
  await loginUserStore.fetchLoginUser()
  if (!loginUserStore.loginUser.id) {
    await router.replace('/user/login')
    return
  }
  syncFormFromLoginUser()
})
</script>

<template>
  <UserPageLayout v-if="loginUserStore.loginUser.id" title="个人信息">
    <div v-if="!isEditing" class="panel-toolbar">
      <a-button @click="startEdit">编辑</a-button>
    </div>

    <a-form v-if="isEditing" layout="vertical" :model="formState" class="edit-form">
      <a-form-item label="头像">
        <div class="avatar-edit">
          <UserAvatar :size="64" :src="formState.userAvatar" />
          <a-upload accept="image/*" :show-upload-list="false" :before-upload="beforeAvatarUpload">
            <a-button>本地上传</a-button>
          </a-upload>
        </div>
      </a-form-item>
      <a-form-item label="用户名">
        <a-input v-model:value="formState.userName" placeholder="请输入用户名" />
      </a-form-item>
      <a-form-item label="账号">
        <a-input :value="loginUserStore.loginUser.userAccount" disabled />
      </a-form-item>
      <a-form-item label="角色">
        <a-input :value="userRoleText" disabled />
      </a-form-item>
      <a-form-item label="简介">
        <a-textarea v-model:value="formState.userProfile" placeholder="请输入简介" :rows="4" />
      </a-form-item>
      <a-form-item label="注册时间">
        <a-input :value="registerTimeText" disabled />
      </a-form-item>
      <div class="form-actions">
        <a-space>
          <a-button @click="cancelEdit">取消</a-button>
          <a-button type="primary" :loading="isSubmitting" @click="handleSave">保存</a-button>
        </a-space>
      </div>
    </a-form>

    <a-descriptions v-else bordered :column="1">
      <a-descriptions-item label="头像">
        <UserAvatar :size="64" :src="loginUserStore.loginUser.userAvatar" />
      </a-descriptions-item>
      <a-descriptions-item label="用户名">
        {{ loginUserStore.loginUser.userName || '-' }}
      </a-descriptions-item>
      <a-descriptions-item label="账号">
        {{ loginUserStore.loginUser.userAccount || '-' }}
      </a-descriptions-item>
      <a-descriptions-item label="角色">
        {{ userRoleText }}
      </a-descriptions-item>
      <a-descriptions-item label="简介">
        <span :class="{ 'empty-profile-text': !loginUserStore.loginUser.userProfile?.trim() }">
          {{ profileText }}
        </span>
      </a-descriptions-item>
      <a-descriptions-item label="注册时间">
        {{ registerTimeText }}
      </a-descriptions-item>
    </a-descriptions>
  </UserPageLayout>
</template>

<style scoped>
.panel-toolbar {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 16px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.avatar-edit {
  display: flex;
  align-items: center;
  gap: 16px;
}

.edit-form {
  max-width: 100%;
}

.empty-profile-text {
  color: #94a3b8;
}
</style>
