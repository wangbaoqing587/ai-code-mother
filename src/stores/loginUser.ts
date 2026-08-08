import { ref } from 'vue'
import { defineStore } from 'pinia'
import { getLoginUser } from '@/api/userController'

const NOT_LOGIN_USER: API.LoginUserVO = {
  userName: '未登录',
}

export const useLoginUserStore = defineStore('loginUser', () => {
  const loginUser = ref<API.LoginUserVO>({ ...NOT_LOGIN_USER })

  async function fetchLoginUser() {
    try {
      const res = await getLoginUser()
      if (res.data.code === 0 && res.data.data?.id) {
        loginUser.value = res.data.data
        return
      }
    } catch {
      // ignore
    }
    loginUser.value = { ...NOT_LOGIN_USER }
  }

  function setLoginUser(user: API.LoginUserVO) {
    loginUser.value = user
  }

  function logoutLoginUser() {
    loginUser.value = { ...NOT_LOGIN_USER }
  }

  return { loginUser, fetchLoginUser, setLoginUser, logoutLoginUser }
})
