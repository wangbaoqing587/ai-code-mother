import axios from 'axios'
import { message } from 'ant-design-vue'

const myAxios = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8123/api',
  timeout: 60000,
  withCredentials: true,
})

myAxios.interceptors.request.use(
  (config) => {
    return config
  },
  (error) => {
    return Promise.reject(error)
  },
)

myAxios.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    message.error(`请求错误：${error.message}`)
    return Promise.reject(error)
  },
)

export default myAxios
