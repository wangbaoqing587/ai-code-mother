import { useLoginUserStore } from '@/stores/loginUser'

export function buildLoginPath(redirect?: string) {
  const target = redirect || `${window.location.pathname}${window.location.search}`
  return `/user/login?redirect=${encodeURIComponent(target)}`
}

export function redirectToLogin(redirect?: string) {
  if (window.location.pathname.startsWith('/user/login')) {
    return
  }
  const loginUserStore = useLoginUserStore()
  loginUserStore.logoutLoginUser()
  window.location.href = buildLoginPath(redirect)
}
