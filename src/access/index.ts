import type { Router } from 'vue-router'
import { ACCESS_ENUM } from '@/access/accessEnum'
import { checkAccess } from '@/access/checkAccess'
import { useLoginUserStore } from '@/stores/loginUser'

function needLoginAccess(access: string) {
  return access === ACCESS_ENUM.USER || access === ACCESS_ENUM.ADMIN
}

export function setupAccessGuard(router: Router) {
  router.beforeEach(async (to, _from, next) => {
    const loginUserStore = useLoginUserStore()
    const needAccess = (to.meta.access as string) ?? ACCESS_ENUM.NOT_LOGIN

    if (needLoginAccess(needAccess) || !loginUserStore.loginUser.id) {
      await loginUserStore.fetchLoginUser()
    }

    const loginUser = loginUserStore.loginUser

    if (checkAccess(loginUser, needAccess)) {
      next()
      return
    }

    if (!loginUser.id) {
      next({
        path: '/user/login',
        query: {
          redirect: to.fullPath,
        },
      })
      return
    }

    next('/401')
  })
}
