<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { UploadProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import { listUserAppVoByPage } from '@/api/appController'
import { changePassword, getUserVoById, updateUser } from '@/api/userController'
import AppLoadMoreListSection from '@/components/AppLoadMoreListSection.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import UserPageLayout from '@/components/UserPageLayout.vue'
import { MY_APP_PAGE_SIZE } from '@/constants/app'
import { useLoginUserStore } from '@/stores/loginUser'
import { compressImage } from '@/utils/image'

const MAX_AVATAR_SIZE = 2 * 1024 * 1024
const AVATAR_MAX_EDGE = 256

const ROLE_TEXT_MAP: Record<string, string> = {
  admin: '管理员',
  user: '用户',
}

const GENDER_TEXT_MAP: Record<number, string> = {
  1: '男',
  0: '女',
}

const EMPTY_PROFILE_TEXT = '还没有填写简介'

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()
const isEditing = ref(false)
const isSubmitting = ref(false)
const isPasswordModalOpen = ref(false)
const isPasswordSubmitting = ref(false)
const isGuestLoading = ref(false)
const guestUser = ref<API.UserVO | null>(null)

const guestApps = ref<API.AppVO[]>([])
const guestAppsTotal = ref(0)
const isGuestAppsLoading = ref(false)
const isGuestAppsLoadingMore = ref(false)
const guestAppsPage = reactive({
  pageNum: 1,
  pageSize: MY_APP_PAGE_SIZE,
})

const isGuestMode = computed(() => route.name === 'userProfile')
const profileUserId = computed(() => {
  if (isGuestMode.value) {
    return route.params.userId as string
  }
  return loginUserStore.loginUser.id ? String(loginUserStore.loginUser.id) : ''
})

const formState = reactive({
  userName: '',
  userAvatar: '',
  userProfile: '',
  gender: 1,
})

const passwordFormState = reactive({
  userPassword: '',
  newPassword: '',
  checkPassword: '',
})

const displayUser = computed(() => {
  if (isGuestMode.value) {
    return guestUser.value
  }
  return loginUserStore.loginUser
})

const pageTitle = computed(() => {
  if (isGuestMode.value) {
    const name = guestUser.value?.userName?.trim()
    return name ? `${name}的主页` : '用户主页'
  }
  return '个人信息'
})

const userRoleText = computed(() => {
  const role = loginUserStore.loginUser.userRole
  if (!role) {
    return '-'
  }
  return ROLE_TEXT_MAP[role] ?? role
})

const genderText = computed(() => {
  const gender = displayUser.value?.gender
  if (gender === undefined || gender === null) {
    return '-'
  }
  return GENDER_TEXT_MAP[gender] ?? '-'
})

function formatDateText(createTime?: string) {
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
}

const registerTimeText = computed(() => formatDateText(displayUser.value?.createTime))

const profileText = computed(
  () => displayUser.value?.userProfile?.trim() || EMPTY_PROFILE_TEXT,
)

function syncFormFromLoginUser() {
  formState.userName = loginUserStore.loginUser.userName ?? ''
  formState.userAvatar = loginUserStore.loginUser.userAvatar ?? ''
  formState.userProfile = loginUserStore.loginUser.userProfile ?? ''
  formState.gender = loginUserStore.loginUser.gender ?? 1
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
      gender: formState.gender,
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

async function fetchGuestUser() {
  const userId = profileUserId.value
  if (!userId) {
    return
  }
  isGuestLoading.value = true
  try {
    const res = await getUserVoById({ id: Number(userId) })
    if (res.data.code === 0 && res.data.data) {
      guestUser.value = res.data.data
      return
    }
    message.error('用户不存在')
    await router.replace('/')
  } finally {
    isGuestLoading.value = false
  }
}

async function fetchGuestApps(append = false) {
  const userId = profileUserId.value
  if (!userId) {
    return
  }
  if (append) {
    isGuestAppsLoadingMore.value = true
  } else {
    isGuestAppsLoading.value = true
  }
  try {
    const res = await listUserAppVoByPage({
      pageNum: guestAppsPage.pageNum,
      pageSize: guestAppsPage.pageSize,
      userId: Number(userId),
      sortField: 'createTime',
      sortOrder: 'descend',
    })
    if (res.data.code === 0 && res.data.data) {
      const records = res.data.data.records ?? []
      guestApps.value = append ? [...guestApps.value, ...records] : records
      guestAppsTotal.value = res.data.data.totalRow ?? records.length
      return
    }
    message.error('获取作品失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isGuestAppsLoading.value = false
    isGuestAppsLoadingMore.value = false
  }
}

function handleGuestAppsLoadMore() {
  guestAppsPage.pageNum += 1
  fetchGuestApps(true)
}

async function initGuestPage() {
  const userId = profileUserId.value
  if (!userId) {
    await router.replace('/')
    return
  }
  await loginUserStore.fetchLoginUser()
  if (loginUserStore.loginUser.id && String(loginUserStore.loginUser.id) === userId) {
    await router.replace('/user/info')
    return
  }
  guestAppsPage.pageNum = 1
  guestApps.value = []
  guestAppsTotal.value = 0
  await fetchGuestUser()
  await fetchGuestApps()
}

watch(
  () => loginUserStore.loginUser.id,
  () => {
    if (!isGuestMode.value && !isEditing.value) {
      syncFormFromLoginUser()
    }
  },
)

watch(
  () => route.params.userId,
  () => {
    if (isGuestMode.value) {
      initGuestPage()
    }
  },
)

onMounted(async () => {
  if (isGuestMode.value) {
    await initGuestPage()
    return
  }
  await loginUserStore.fetchLoginUser()
  if (!loginUserStore.loginUser.id) {
    await router.replace('/user/login')
    return
  }
  syncFormFromLoginUser()
})
</script>

<template>
  <div class="user-info-page">
    <a-spin :spinning="isGuestMode && isGuestLoading">
      <UserPageLayout v-if="displayUser?.id" :title="pageTitle" :fill-viewport="!isGuestMode">
        <div v-if="!isGuestMode && !isEditing" class="panel-toolbar">
          <a-space>
            <a-button @click="openPasswordModal">修改密码</a-button>
            <a-button @click="startEdit">编辑</a-button>
          </a-space>
        </div>

        <a-form v-if="!isGuestMode && isEditing" layout="vertical" :model="formState" class="edit-form">
          <a-form-item label="头像">
            <div class="avatar-edit">
              <UserAvatar :size="64" :src="formState.userAvatar" :gender="formState.gender" />
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
          <a-form-item label="性别">
            <a-radio-group v-model:value="formState.gender">
              <a-radio :value="1">男</a-radio>
              <a-radio :value="0">女</a-radio>
            </a-radio-group>
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
            <UserAvatar :size="64" :src="displayUser?.userAvatar" :gender="displayUser?.gender" />
          </a-descriptions-item>
          <a-descriptions-item label="昵称">
            {{ displayUser?.userName || '-' }}
          </a-descriptions-item>
          <a-descriptions-item v-if="!isGuestMode" label="账号">
            {{ loginUserStore.loginUser.userAccount || '-' }}
          </a-descriptions-item>
          <a-descriptions-item v-if="!isGuestMode" label="角色">
            {{ userRoleText }}
          </a-descriptions-item>
          <a-descriptions-item label="性别">
            {{ genderText }}
          </a-descriptions-item>
          <a-descriptions-item label="简介">
            <span :class="{ 'empty-profile-text': !displayUser?.userProfile?.trim() }">
              {{ profileText }}
            </span>
          </a-descriptions-item>
          <a-descriptions-item label="注册时间">
            {{ registerTimeText }}
          </a-descriptions-item>
        </a-descriptions>

        <a-modal
          v-if="!isGuestMode"
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

        <template v-if="isGuestMode && guestUser?.id" #extra>
          <AppLoadMoreListSection
            v-if="isGuestAppsLoading || guestApps.length"
            class="guest-works-section"
            title="TA 的作品"
            :apps="guestApps"
            :total="guestAppsTotal"
            :loading="isGuestAppsLoading"
            :loading-more="isGuestAppsLoadingMore"
            restrict-chat-to-owner
            @load-more="handleGuestAppsLoadMore"
          />
          <div v-else-if="!isGuestAppsLoading" class="guest-empty-wrap">
            <a-empty description="暂无作品" />
          </div>
        </template>
      </UserPageLayout>
    </a-spin>
  </div>
</template>

<style scoped>
.user-info-page {
  width: 100%;
}

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

.guest-empty-wrap {
  max-width: 1320px;
  margin: 0 auto;
  padding: 0 24px 48px;
}

.user-info-page :deep(.guest-works-section.list-section) {
  padding-top: 24px;
  margin-top: 0;
}
</style>
