import { createRouter, createWebHistory } from 'vue-router'
import { accessConfig } from '@/access/accessConfig'
import { setupAccessGuard } from '@/access'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/pages/HomePage.vue'),
      meta: {
        access: accessConfig.home,
      },
    },
    {
      path: '/my/works',
      name: 'myWorks',
      component: () => import('@/pages/MyWorksPage.vue'),
      meta: {
        access: accessConfig.myWorks,
      },
    },
    {
      path: '/user/login',
      name: 'userLogin',
      component: () => import('@/pages/user/UserLoginPage.vue'),
      meta: {
        access: accessConfig.userLogin,
      },
    },
    {
      path: '/user/register',
      name: 'userRegister',
      component: () => import('@/pages/user/UserRegisterPage.vue'),
      meta: {
        access: accessConfig.userRegister,
      },
    },
    {
      path: '/user/info',
      name: 'userInfo',
      component: () => import('@/pages/user/UserInfoPage.vue'),
      meta: {
        access: accessConfig.userInfo,
      },
    },
    {
      path: '/user/profile/:userId',
      name: 'userProfile',
      component: () => import('@/pages/user/UserInfoPage.vue'),
      meta: {
        access: accessConfig.userProfile,
      },
    },
    {
      path: '/app/chat/:id',
      name: 'appChat',
      component: () => import('@/pages/app/AppChatPage.vue'),
      meta: {
        access: accessConfig.appChat,
        hideFooter: true,
      },
    },
    {
      path: '/app/edit/:id',
      name: 'appEdit',
      component: () => import('@/pages/app/AppEditPage.vue'),
      meta: {
        access: accessConfig.appEdit,
      },
    },
    {
      path: '/admin/userManage',
      name: 'userManage',
      component: () => import('@/pages/admin/UserManagePage.vue'),
      meta: {
        access: accessConfig.userManage,
      },
    },
    {
      path: '/admin/appManage',
      name: 'appManage',
      component: () => import('@/pages/admin/AppManagePage.vue'),
      meta: {
        access: accessConfig.appManage,
      },
    },
    {
      path: '/admin/chatManage',
      name: 'chatManage',
      component: () => import('@/pages/admin/ChatManagePage.vue'),
      meta: {
        access: accessConfig.chatManage,
      },
    },
    {
      path: '/401',
      name: 'noAuth',
      component: () => import('@/pages/NoAuthPage.vue'),
      meta: {
        access: accessConfig.noAuth,
      },
    },
  ],
})

setupAccessGuard(router)

export default router
