<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { register } from '@/api/userController'
import AuthPageLayout from '@/components/AuthPageLayout.vue'

const router = useRouter()
const isSubmitting = ref(false)

const formState = reactive<API.UserRegisterRequest>({
  userName: '',
  userAccount: '',
  userPassword: '',
  checkPassword: '',
  gender: 1,
})

async function handleSubmit() {
  if (formState.userPassword !== formState.checkPassword) {
    message.error('两次输入的密码不一致')
    return
  }
  isSubmitting.value = true
  try {
    const res = await register(formState)
    if (res.data.code === 0) {
      message.success('注册成功')
      await router.push('/user/login')
      return
    }
    message.error('注册失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <AuthPageLayout title="用户注册">
    <a-form :model="formState" layout="vertical" @finish="handleSubmit">
      <a-form-item
        name="userName"
        label="昵称"
        :rules="[
          { required: true, message: '请输入昵称' },
          { max: 12, message: '昵称不能超过 12 个字符' },
        ]"
      >
        <a-input
          v-model:value="formState.userName"
          placeholder="请输入昵称"
          :maxlength="12"
          autocomplete="nickname"
        />
      </a-form-item>
      <a-form-item
        name="userAccount"
        label="账号"
        :rules="[{ required: true, message: '请输入账号' }]"
      >
        <a-input
          v-model:value="formState.userAccount"
          placeholder="请输入账号"
          autocomplete="username"
        />
      </a-form-item>
      <a-form-item
        name="gender"
        label="性别"
        :rules="[{ required: true, message: '请选择性别' }]"
      >
        <a-radio-group v-model:value="formState.gender">
          <a-radio :value="1">男</a-radio>
          <a-radio :value="0">女</a-radio>
        </a-radio-group>
      </a-form-item>
      <a-form-item
        name="userPassword"
        label="密码"
        :rules="[
          { required: true, message: '请输入密码' },
          { min: 8, message: '密码长度不能小于 8 位' },
        ]"
      >
        <a-input-password
          v-model:value="formState.userPassword"
          placeholder="请输入密码"
          autocomplete="new-password"
        />
      </a-form-item>
      <a-form-item
        name="checkPassword"
        label="确认密码"
        :rules="[
          { required: true, message: '请再次输入密码' },
          { min: 8, message: '密码长度不能小于 8 位' },
        ]"
      >
        <a-input-password
          v-model:value="formState.checkPassword"
          placeholder="请再次输入密码"
          autocomplete="new-password"
        />
      </a-form-item>
      <a-form-item>
        <a-button type="primary" html-type="submit" block :loading="isSubmitting">注册</a-button>
      </a-form-item>
    </a-form>
    <template #footer>
      已有账号？
      <RouterLink to="/user/login">去登录</RouterLink>
    </template>
  </AuthPageLayout>
</template>
