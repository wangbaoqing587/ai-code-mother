import { ACCESS_ENUM, type AccessEnum } from '@/access/accessEnum'

export function checkAccess(
  loginUser: API.LoginUserVO,
  needAccess: AccessEnum | string = ACCESS_ENUM.NOT_LOGIN,
) {
  const loginUserAccess = loginUser.userRole ?? ACCESS_ENUM.NOT_LOGIN

  if (needAccess === ACCESS_ENUM.NOT_LOGIN) {
    return true
  }

  if (needAccess === ACCESS_ENUM.USER) {
    return loginUserAccess !== ACCESS_ENUM.NOT_LOGIN && !!loginUser.id
  }

  if (needAccess === ACCESS_ENUM.ADMIN) {
    return loginUserAccess === ACCESS_ENUM.ADMIN
  }

  return true
}
