<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { UploadProps } from 'ant-design-vue'
import { message } from 'ant-design-vue'
import {
  getAppByIdByAdmin,
  getAppVoById,
  updateApp,
  updateAppByAdmin,
} from '@/api/appController'
import { ACCESS_ENUM } from '@/access/accessEnum'
import PageHeader from '@/components/PageHeader.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import { getDeployUrl, getStaticPreviewUrl } from '@/config/env'
import { formatCodeGenType } from '@/constants/codeGenType'
import { useLoginUserStore } from '@/stores/loginUser'
import { compressImage } from '@/utils/image'
import { formatDateTime } from '@/utils/time'

const MAX_COVER_SIZE = 2 * 1024 * 1024
const COVER_MAX_EDGE = 800

const route = useRoute()
const router = useRouter()
const loginUserStore = useLoginUserStore()

const isLoading = ref(false)
const isSubmitting = ref(false)
const appInfo = ref<API.AppVO>({})

const formState = reactive({
  appName: '',
  cover: '',
  priority: undefined as number | undefined,
})

const appId = computed(() => {
  const id = route.params.id
  return Array.isArray(id) ? id[0] ?? '' : (id ?? '')
})
const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)
const isOwner = computed(() => appInfo.value.userId === loginUserStore.loginUser.id)
const canEdit = computed(() => isAdmin.value || isOwner.value)
const creatorName = computed(() => appInfo.value.user?.userName || '未知用户')
const creatorAvatar = computed(() => appInfo.value.user?.userAvatar || '')
const accessUrl = computed(() => {
  const { deployKey, codeGenType, id } = appInfo.value
  if (deployKey) {
    return getDeployUrl(deployKey, codeGenType)
  }
  if (codeGenType && id) {
    return getStaticPreviewUrl(codeGenType, id)
  }
  return ''
})

function syncFormFromApp() {
  formState.appName = appInfo.value.appName ?? ''
  formState.cover = appInfo.value.cover ?? ''
  formState.priority = appInfo.value.priority
}

async function fetchAppInfo() {
  if (!appId.value) {
    return
  }
  isLoading.value = true
  try {
    const res = isAdmin.value
      ? await getAppByIdByAdmin({ id: appId.value })
      : await getAppVoById({ id: appId.value })
    if (res.data.code === 0 && res.data.data) {
      appInfo.value = res.data.data
      syncFormFromApp()
      if (!canEdit.value) {
        message.error('无权编辑该应用')
        await router.replace('/')
      }
      return
    }
    message.error('获取应用信息失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isLoading.value = false
  }
}

const beforeCoverUpload: UploadProps['beforeUpload'] = async (file) => {
  if (!file.type.startsWith('image/')) {
    message.error('只能上传图片文件')
    return false
  }
  if (file.size > MAX_COVER_SIZE) {
    message.error('图片大小不能超过 2MB')
    return false
  }
  try {
    formState.cover = await compressImage(file as File, COVER_MAX_EDGE)
    message.success('封面已选择')
  } catch {
    message.error('封面读取失败')
  }
  return false
}

async function handleSubmit() {
  if (!appId.value) {
    return
  }
  if (!formState.appName.trim()) {
    message.warning('请输入应用名称')
    return
  }
  isSubmitting.value = true
  try {
    const res = isAdmin.value
      ? await updateAppByAdmin({
          id: appId.value,
          appName: formState.appName.trim(),
          cover: formState.cover || undefined,
          priority: formState.priority,
        })
      : await updateApp({
          id: appId.value,
          appName: formState.appName.trim(),
        })
    if (res.data.code === 0) {
      message.success('保存成功')
      await fetchAppInfo()
      return
    }
    message.error('保存失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isSubmitting.value = false
  }
}

onMounted(async () => {
  await loginUserStore.fetchLoginUser()
  if (!loginUserStore.loginUser.id) {
    await router.replace(`/user/login?redirect=${encodeURIComponent(route.fullPath)}`)
    return
  }
  await fetchAppInfo()
})
</script>

<template>
  <div class="app-edit-page">
    <PageHeader title="应用信息编辑">
      <template #actions>
        <a-space>
          <a-button @click="router.back()">返回</a-button>
          <a-button type="primary" :loading="isSubmitting" @click="handleSubmit">保存</a-button>
        </a-space>
      </template>
    </PageHeader>

    <a-spin :spinning="isLoading">
      <a-form layout="vertical" :model="formState" class="edit-form">
        <a-form-item label="应用名称" required>
          <a-input v-model:value="formState.appName" placeholder="请输入应用名称" />
        </a-form-item>

        <a-form-item label="应用封面">
          <div class="cover-edit">
            <div class="cover-preview">
              <img v-if="formState.cover" :src="formState.cover" alt="封面预览" />
              <span v-else>暂无封面</span>
            </div>
            <div class="cover-inputs">
              <a-input v-model:value="formState.cover" placeholder="请输入封面 URL" allow-clear />
              <a-upload
                accept="image/*"
                :show-upload-list="false"
                :before-upload="beforeCoverUpload"
              >
                <a-button>本地上传</a-button>
              </a-upload>
            </div>
          </div>
        </a-form-item>

        <a-form-item label="优先级">
          <div class="priority-row">
            <a-input-number
              v-model:value="formState.priority"
              :min="0"
              :disabled="!isAdmin"
              style="width: 200px"
              placeholder="请输入优先级"
            />
            <span class="field-tip">99表示精选应用</span>
          </div>
        </a-form-item>

        <a-form-item label="初始提示词">
          <a-textarea :value="appInfo.initPrompt || '-'" :rows="4" disabled />
        </a-form-item>

        <a-form-item label="生成类型">
          <a-input :value="formatCodeGenType(appInfo.codeGenType)" disabled />
        </a-form-item>

        <a-form-item label="部署密钥">
          <a-input :value="appInfo.deployKey || '-'" disabled />
        </a-form-item>
      </a-form>

      <div class="info-section">
        <h3 class="info-title">应用信息</h3>
        <a-descriptions bordered :column="2" size="middle">
          <a-descriptions-item label="应用ID">
            {{ appInfo.id || '-' }}
          </a-descriptions-item>
          <a-descriptions-item label="创建者">
            <div class="creator-cell">
              <UserAvatar :size="24" :src="creatorAvatar" />
              <span>{{ creatorName }}</span>
            </div>
          </a-descriptions-item>
          <a-descriptions-item label="创建时间">
            {{ formatDateTime(appInfo.createTime) }}
          </a-descriptions-item>
          <a-descriptions-item label="更新时间">
            {{ formatDateTime(appInfo.updateTime) }}
          </a-descriptions-item>
          <a-descriptions-item label="部署时间">
            {{ formatDateTime(appInfo.deployedTime) }}
          </a-descriptions-item>
          <a-descriptions-item label="访问链接">
            <a v-if="accessUrl" :href="accessUrl" target="_blank" rel="noopener noreferrer">
              查看预览
            </a>
            <span v-else>-</span>
          </a-descriptions-item>
        </a-descriptions>
      </div>
    </a-spin>
  </div>
</template>

<style scoped>
.app-edit-page {
  max-width: 720px;
  margin: 0 auto;
}

.edit-form {
  max-width: 560px;
}

.cover-edit {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.cover-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  max-width: 320px;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  border-radius: 12px;
  background: #f5f5f5;
  color: rgba(0, 0, 0, 0.35);
}

.cover-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.cover-inputs {
  display: flex;
  align-items: center;
  gap: 12px;
}

.priority-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.field-tip {
  font-size: 13px;
  color: rgba(0, 0, 0, 0.45);
  white-space: nowrap;
}

.info-section {
  margin-top: 32px;
}

.info-title {
  margin: 0 0 16px;
  font-size: 18px;
  font-weight: 600;
}

.creator-cell {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
</style>
