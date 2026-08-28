<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import type { UploadProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import { changePassword, updateUser } from '@/api/userController'
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
const isPasswordModalOpen = ref(false)
const isPasswordSubmitting = ref(false)

const formState = reactive({
  userName: '',
  userAvatar: '',
  userProfile: '',
})

const passwordFormState = reactive({
  userPassword: '',
  newPassword: '',
  checkPassword: '',
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

function resetPasswordForm() {
  passwordFormState.userPassword = ''
  passwordFormState.newPassword = ''
  passwordFormState.checkPassword = ''
}

function openPasswordModal() {
  resetPasswordForm()
  isPasswordModalOpen.value = true
}

function closePasswordModal() {
  isPasswordModalOpen.value = false
  resetPasswordForm()
}

async function handleChangePassword() {
  if (!passwordFormState.userPassword || !passwordFormState.newPassword || !passwordFormState.checkPassword) {
    message.error('请填写完整密码信息')
    return Promise.reject()
  }
  if (passwordFormState.newPassword.length < 8 || passwordFormState.checkPassword.length < 8) {
    message.error('密码长度不能小于 8 位')
    return Promise.reject()
  }
  if (passwordFormState.newPassword !== passwordFormState.checkPassword) {
    message.error('两次输入的密码不一致')
    return Promise.reject()
  }
  isPasswordSubmitting.value = true
  try {
    const res = await changePassword({
      userPassword: passwordFormState.userPassword,
      newPassword: passwordFormState.newPassword,
      checkPassword: passwordFormState.checkPassword,
    })
    if (res.data.code === 0) {
      message.success('密码修改成功')
      closePasswordModal()
      return
    }
    message.error('密码修改失败：' + (res.data.message ?? '未知错误'))
    return Promise.reject()
  } finally {
    isPasswordSubmitting.value = false
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
      <a-space>
        <a-button @click="openPasswordModal">修改密码</a-button>
        <a-button @click="startEdit">编辑</a-button>
      </a-space>
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
      <a-form-item
        label="昵称"
        name="userName"
        :rules="[{ max: 12, message: '昵称不能超过 12 个字符' }]"
      >
        <a-input v-model:value="formState.userName" placeholder="请输入昵称" :maxlength="12" />
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
      <a-descriptions-item label="昵称">
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

    <a-modal
      v-model:open="isPasswordModalOpen"
      title="修改密码"
      ok-text="保存"
      cancel-text="取消"
      :width="440"
      centered
      wrap-class-name="mint-modal-wrap password-modal-wrap"
      :confirm-loading="isPasswordSubmitting"
      @ok="handleChangePassword"
      @cancel="closePasswordModal"
    >
      <a-form layout="vertical" :model="passwordFormState">
        <a-form-item label="原密码">
          <a-input-password
            v-model:value="passwordFormState.userPassword"
            placeholder="请输入原密码"
            autocomplete="current-password"
          />
        </a-form-item>
        <a-form-item label="新密码">
          <a-input-password
            v-model:value="passwordFormState.newPassword"
            placeholder="请输入新密码"
            autocomplete="new-password"
          />
        </a-form-item>
        <a-form-item label="确认新密码">
          <a-input-password
            v-model:value="passwordFormState.checkPassword"
            placeholder="请再次输入新密码"
            autocomplete="new-password"
          />
        </a-form-item>
      </a-form>
    </a-modal>
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
