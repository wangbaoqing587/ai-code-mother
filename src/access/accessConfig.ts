import { ACCESS_ENUM, type AccessEnum } from '@/access/accessEnum'

export const accessConfig: Record<string, AccessEnum> = {
  home: ACCESS_ENUM.NOT_LOGIN,
  userLogin: ACCESS_ENUM.NOT_LOGIN,
  userRegister: ACCESS_ENUM.NOT_LOGIN,
  userInfo: ACCESS_ENUM.USER,
  userManage: ACCESS_ENUM.ADMIN,
  appManage: ACCESS_ENUM.ADMIN,
  chatManage: ACCESS_ENUM.ADMIN,
  appChat: ACCESS_ENUM.USER,
  appEdit: ACCESS_ENUM.USER,
  noAuth: ACCESS_ENUM.NOT_LOGIN,
}
