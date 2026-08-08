import axios from 'axios'
import { message } from 'ant-design-vue'
import { redirectToLogin } from '@/access/redirectToLogin'
import { API_BASE_URL } from '@/config/env'

const myAxios = axios.create({
  baseURL: API_BASE_URL,
  timeout: 60000,
  withCredentials: true,
})

myAxios.interceptors.request.use(
  function (config) {
    return config
  },
  function (error) {
    return Promise.reject(error)
  },
)

myAxios.interceptors.response.use(
  function (response) {
    const { data } = response
    if (data.code === 40100) {
      const requestUrl = String(response.config.url || response.request?.responseURL || '')
      if (!requestUrl.includes('/user/get/login') && !requestUrl.includes('/user/login')) {
        message.warning('请先登录')
        redirectToLogin()
      }
    }
    return response
  },
  function (error) {
    return Promise.reject(error)
  },
)

export default myAxios
