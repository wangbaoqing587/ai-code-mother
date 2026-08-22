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
import AdminPageLayout from '@/components/AdminPageLayout.vue'
import CodeGenTypeTag from '@/components/CodeGenTypeTag.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import UserPageLayout from '@/components/UserPageLayout.vue'
import { getDeployUrl, getStaticPreviewUrl } from '@/config/env'
import { useLoginUserStore } from '@/stores/loginUser'
import { compressImage } from '@/utils/image'
import { parseRouteParamId } from '@/utils/route'
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

const appId = computed(() => parseRouteParamId(route.params.id))
const isAdmin = computed(() => loginUserStore.loginUser.userRole === ACCESS_ENUM.ADMIN)
const isOwner = computed(() => appInfo.value.userId === loginUserStore.loginUser.id)
const canEdit = computed(() => isAdmin.value || isOwner.value)
const creatorName = computed(() => appInfo.value.user?.userName || '未知用户')
const creatorAvatar = computed(() => appInfo.value.user?.userAvatar || '')
const accessUrl = computed(() => {
  const { deployKey, codeGenType } = appInfo.value
  if (deployKey) {
    return getDeployUrl(deployKey, codeGenType)
  }
  if (codeGenType && appId.value) {
    return getStaticPreviewUrl(codeGenType, appId.value)
  }
  return ''
})

const infoLabelStyle = {
  width: '90px',
  maxWidth: '90px',
  whiteSpace: 'nowrap',
}

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

function openAccessUrl() {
  if (accessUrl.value) {
    window.open(accessUrl.value, '_blank', 'noopener,noreferrer')
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
  <div class="app-edit-root">
    <AdminPageLayout v-if="isAdmin" title="应用信息编辑">
    <div class="admin-panel app-edit-panel">
      <a-spin :spinning="isLoading">
        <div class="panel-toolbar">
          <a-space>
            <a-button @click="router.back()">返回</a-button>
            <a-button type="primary" :loading="isSubmitting" @click="handleSubmit">保存</a-button>
          </a-space>
        </div>

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
                style="width: 200px"
                placeholder="请输入优先级"
              />
              <span class="field-tip">99 表示精选应用</span>
            </div>
          </a-form-item>

          <a-form-item label="初始提示词">
            <a-textarea :value="appInfo.initPrompt || '-'" :rows="4" disabled class="readonly-field" />
          </a-form-item>

          <a-form-item label="生成类型">
            <div class="readonly-value">
              <CodeGenTypeTag v-if="appInfo.codeGenType" :code-gen-type="appInfo.codeGenType" />
              <span v-else>-</span>
            </div>
          </a-form-item>

          <a-form-item label="部署密钥">
            <a-input :value="appInfo.deployKey || '-'" disabled class="readonly-field" />
          </a-form-item>
        </a-form>

        <div class="info-section">
          <h3 class="info-title">应用信息</h3>
          <a-descriptions
            class="app-info-descriptions app-info-descriptions-two-col"
            bordered
            :column="2"
            size="middle"
            :label-style="infoLabelStyle"
          >
            <a-descriptions-item label="应用 ID">
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
              <div v-if="accessUrl" class="access-link-row">
                <span class="access-link-url">{{ accessUrl }}</span>
                <a-button size="small" class="access-link-btn" @click="openAccessUrl">浏览</a-button>
              </div>
              <span v-else>-</span>
            </a-descriptions-item>
          </a-descriptions>
        </div>
      </a-spin>
    </div>
  </AdminPageLayout>

  <UserPageLayout v-else title="应用信息编辑">
    <a-spin :spinning="isLoading">
      <div class="panel-toolbar">
        <a-space>
          <a-button @click="router.back()">返回</a-button>
          <a-button type="primary" :loading="isSubmitting" @click="handleSubmit">保存</a-button>
        </a-space>
      </div>

      <a-form layout="vertical" :model="formState" class="edit-form">
        <a-form-item label="应用名称" required>
          <a-input v-model:value="formState.appName" placeholder="请输入应用名称" />
        </a-form-item>

        <a-form-item label="应用封面">
          <div class="cover-edit">
            <div class="cover-preview cover-preview-mint">
              <img v-if="formState.cover" :src="formState.cover" alt="封面预览" />
              <span v-else>暂无封面</span>
            </div>
            <div class="cover-inputs">
              <a-input v-model:value="formState.cover" placeholder="请输入封面 URL" allow-clear />
              <a-upload accept="image/*" :show-upload-list="false" :before-upload="beforeCoverUpload">
                <a-button>本地上传</a-button>
              </a-upload>
            </div>
          </div>
        </a-form-item>

        <a-form-item label="初始提示词">
          <a-textarea :value="appInfo.initPrompt || '-'" :rows="4" disabled class="readonly-field" />
        </a-form-item>

        <a-form-item label="生成类型">
          <div class="readonly-value">
            <CodeGenTypeTag v-if="appInfo.codeGenType" :code-gen-type="appInfo.codeGenType" />
            <span v-else>-</span>
          </div>
        </a-form-item>
      </a-form>

      <div class="info-section">
        <h3 class="info-title">应用信息</h3>
        <a-descriptions
          class="app-info-descriptions"
          bordered
          :column="1"
          size="middle"
          :label-style="infoLabelStyle"
        >
          <a-descriptions-item label="应用 ID">
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
            <div v-if="accessUrl" class="access-link-row">
              <span class="access-link-url">{{ accessUrl }}</span>
              <a-button size="small" class="access-link-btn" @click="openAccessUrl">浏览</a-button>
            </div>
            <span v-else>-</span>
          </a-descriptions-item>
        </a-descriptions>
      </div>
    </a-spin>
  </UserPageLayout>
  </div>
</template>

<style scoped>
.app-edit-root :deep(.admin-content),
.app-edit-root :deep(.user-content) {
  max-width: 760px;
}

.app-edit-root :deep(.admin-title) {
  text-align: center;
}

.app-edit-panel {
  width: 100%;
  max-width: 760px;
  margin: 0 auto;
}

.panel-toolbar {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 20px;
}

.edit-form {
  max-width: 100%;
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
  border-radius: 14px;
  border: 1.5px solid rgba(129, 212, 250, 0.4);
  background: #f5faff;
  color: #94a3b8;
}

.cover-preview-mint {
  border-color: rgba(136, 216, 176, 0.4);
  background: #f7faf8;
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
  flex-wrap: wrap;
}

.cover-inputs :deep(.ant-input-affix-wrapper) {
  flex: 1;
  min-width: 200px;
}

.priority-row {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.field-tip {
  font-size: 13px;
  color: #94a3b8;
  white-space: nowrap;
}

.readonly-value {
  min-height: 32px;
  display: flex;
  align-items: center;
}

.readonly-field {
  background: #f8fafc !important;
  color: #64748b !important;
  cursor: not-allowed;
}

.info-section {
  margin-top: 28px;
  padding-top: 24px;
  border-top: 1px solid rgba(148, 163, 184, 0.2);
}

.info-title {
  margin: 0 0 16px;
  font-size: 16px;
  font-weight: 600;
  color: #1a2e35;
}

.creator-cell {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.access-link-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.access-link-url {
  flex: 1;
  min-width: 0;
  font-size: 13px;
  line-height: 1.5;
  word-break: break-all;
  color: #334155;
}

.access-link-btn {
  flex-shrink: 0;
  border-radius: 999px;
}

.app-info-descriptions :deep(.ant-descriptions-view table) {
  table-layout: fixed;
  width: 100%;
}

.app-info-descriptions :deep(.ant-descriptions-item-label) {
  width: 90px !important;
  max-width: 90px !important;
  padding: 12px 8px !important;
  box-sizing: border-box;
}

.app-info-descriptions :deep(.ant-descriptions-row > th) {
  width: 90px !important;
  max-width: 90px !important;
}

.app-info-descriptions-two-col :deep(.ant-descriptions-row > .ant-descriptions-item-content:nth-child(2)) {
  width: 220px !important;
  max-width: 220px !important;
  word-break: break-all;
}

.app-edit-panel :deep(.ant-descriptions-bordered .ant-descriptions-item-label) {
  background: #eef6fc;
  color: #475569;
  font-weight: 500;
  border-color: rgba(129, 212, 250, 0.22) !important;
}

.app-edit-panel :deep(.ant-descriptions-bordered .ant-descriptions-item-content) {
  color: #334155;
  border-color: rgba(129, 212, 250, 0.22) !important;
}

.app-edit-panel :deep(.ant-descriptions-bordered .ant-descriptions-view) {
  border-color: rgba(129, 212, 250, 0.22) !important;
  border-radius: 12px;
  overflow: hidden;
}

.app-edit-panel :deep(.ant-input-number) {
  border-radius: 10px !important;
  border-color: rgba(129, 212, 250, 0.45) !important;
}

.app-edit-panel :deep(.ant-input-number-input) {
  caret-color: #6bb5f0;
}
</style>
