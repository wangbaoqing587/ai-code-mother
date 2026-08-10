import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '@/pages/HomePage.vue'
import UserLoginPage from '@/pages/user/UserLoginPage.vue'
import UserRegisterPage from '@/pages/user/UserRegisterPage.vue'
import UserInfoPage from '@/pages/user/UserInfoPage.vue'
import UserManagePage from '@/pages/admin/UserManagePage.vue'
import AppManagePage from '@/pages/admin/AppManagePage.vue'
import ChatManagePage from '@/pages/admin/ChatManagePage.vue'
import AppChatPage from '@/pages/app/AppChatPage.vue'
import AppEditPage from '@/pages/app/AppEditPage.vue'
import NoAuthPage from '@/pages/NoAuthPage.vue'
import { accessConfig } from '@/access/accessConfig'
import { setupAccessGuard } from '@/access'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePage,
      meta: {
        access: accessConfig.home,
      },
    },
    {
      path: '/user/login',
      name: 'userLogin',
      component: UserLoginPage,
      meta: {
        access: accessConfig.userLogin,
      },
    },
    {
      path: '/user/register',
      name: 'userRegister',
      component: UserRegisterPage,
      meta: {
        access: accessConfig.userRegister,
      },
    },
    {
      path: '/user/info',
      name: 'userInfo',
      component: UserInfoPage,
      meta: {
        access: accessConfig.userInfo,
      },
    },
    {
      path: '/app/chat/:id',
      name: 'appChat',
      component: AppChatPage,
      meta: {
        access: accessConfig.appChat,
        hideFooter: true,
      },
    },
    {
      path: '/app/edit/:id',
      name: 'appEdit',
      component: AppEditPage,
      meta: {
        access: accessConfig.appEdit,
      },
    },
    {
      path: '/admin/userManage',
      name: 'userManage',
      component: UserManagePage,
      meta: {
        access: accessConfig.userManage,
      },
    },
    {
      path: '/admin/appManage',
      name: 'appManage',
      component: AppManagePage,
      meta: {
        access: accessConfig.appManage,
      },
    },
    {
      path: '/admin/chatManage',
      name: 'chatManage',
      component: ChatManagePage,
      meta: {
        access: accessConfig.chatManage,
      },
    },
    {
      path: '/401',
      name: 'noAuth',
      component: NoAuthPage,
      meta: {
        access: accessConfig.noAuth,
      },
    },
  ],
})

setupAccessGuard(router)

export default router
