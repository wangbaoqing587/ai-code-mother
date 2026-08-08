<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { userLogin } from '@/api/userController'
import AuthPageLayout from '@/components/AuthPageLayout.vue'
import { useLoginUserStore } from '@/stores/loginUser'

const router = useRouter()
const route = useRoute()
const loginUserStore = useLoginUserStore()
const isSubmitting = ref(false)

const formState = reactive<API.UserLoginRequest>({
  userAccount: '',
  userPassword: '',
})

async function handleSubmit() {
  isSubmitting.value = true
  try {
    const res = await userLogin(formState)
    if (res.data.code === 0 && res.data.data) {
      loginUserStore.setLoginUser(res.data.data)
      message.success('登录成功')
      const redirect = (route.query.redirect as string) || '/'
      if (redirect.startsWith('http')) {
        window.location.href = redirect
        return
      }
      await router.push(redirect)
      return
    }
    message.error('登录失败：' + (res.data.message ?? '未知错误'))
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <AuthPageLayout title="用户登录">
    <a-form :model="formState" layout="vertical" @finish="handleSubmit">
      <a-form-item
        name="userAccount"
        label="账号"
        :rules="[{ required: true, message: '请输入账号' }]"
      >
        <a-input v-model:value="formState.userAccount" placeholder="请输入账号" />
      </a-form-item>
      <a-form-item
        name="userPassword"
        label="密码"
        :rules="[
          { required: true, message: '请输入密码' },
          { min: 8, message: '密码长度不能小于 8 位' },
        ]"
      >
        <a-input-password v-model:value="formState.userPassword" placeholder="请输入密码" />
      </a-form-item>
      <a-form-item>
        <a-button type="primary" html-type="submit" block :loading="isSubmitting">登录</a-button>
      </a-form-item>
    </a-form>
    <template #footer>
      还没有账号？
      <RouterLink to="/user/register">去注册</RouterLink>
    </template>
  </AuthPageLayout>
</template>
