import { accessConfig } from '@/access/accessConfig'
import type { AccessEnum } from '@/access/accessEnum'

export interface MenuConfig {
  key: string
  label: string
  path: string
  access?: AccessEnum
}

export const menus: MenuConfig[] = [
  { key: 'home', label: '首页', path: '/', access: accessConfig.home },
  {
    key: 'userManage',
    label: '用户管理',
    path: '/admin/userManage',
    access: accessConfig.userManage,
  },
  {
    key: 'appManage',
    label: '应用管理',
    path: '/admin/appManage',
    access: accessConfig.appManage,
  },
  {
    key: 'chatManage',
    label: '对话管理',
    path: '/admin/chatManage',
    access: accessConfig.chatManage,
  },
]
