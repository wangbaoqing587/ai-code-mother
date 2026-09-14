declare namespace API {
  type AppAddRequest = {
    initPrompt?: string
    appName?: string
  }

  type AppCommentAddRequest = {
    appId?: number | string
    content?: string
  }

  type AppCommentVO = {
    id?: number
    appId?: number
    userId?: number
    content?: string
    createTime?: string
    user?: UserVO
  }

  type AppLikeToggleRequest = {
    appId?: number | string
  }

  type AppLikeToggleVO = {
    liked?: boolean
    likeCount?: number
  }

  type AppAdminUpdateRequest = {
    id?: number | string
    appName?: string
    cover?: string
    priority?: number
    visibility?: string
  }

  type AppDeployRequest = {
    appId?: number | string
  }

  type AppQueryRequest = {
    pageNum?: number
    pageSize?: number
    sortField?: string
    sortOrder?: string
    id?: number
    appName?: string
    cover?: string
    initPrompt?: string
    codeGenType?: string
    deployKey?: string
    priority?: number
    visibility?: string
    userId?: number
  }

  type AppUpdateRequest = {
    id?: number | string
    appName?: string
    visibility?: string
  }

  type AppVO = {
    id?: number
    appName?: string
    cover?: string
    initPrompt?: string
    codeGenType?: string
    genStatus?: string
    deployKey?: string
    deployedTime?: string
    priority?: number
    visibility?: string
    userId?: number
    createTime?: string
    updateTime?: string
    user?: UserVO
    likeCount?: number
    commentCount?: number
    hasLiked?: boolean
  }

  type BaseResponseAppVO = {
    code?: number
    data?: AppVO
    message?: string
  }

  type BaseResponseBoolean = {
    code?: number
    data?: boolean
    message?: string
  }

  type BaseResponseLoginUserVO = {
    code?: number
    data?: LoginUserVO
    message?: string
  }

  type BaseResponseAppLikeToggleVO = {
    code?: number
    data?: AppLikeToggleVO
    message?: string
  }

  type BaseResponseLong = {
    code?: number
    data?: number
    message?: string
  }

  type BaseResponsePageAppCommentVO = {
    code?: number
    data?: PageAppCommentVO
    message?: string
  }

  type BaseResponsePageAppVO = {
    code?: number
    data?: PageAppVO
    message?: string
  }

  type BaseResponsePageChatHistory = {
    code?: number
    data?: PageChatHistory
    message?: string
  }

  type BaseResponsePageUserVO = {
    code?: number
    data?: PageUserVO
    message?: string
  }

  type BaseResponseString = {
    code?: number
    data?: string
    message?: string
  }

  type BaseResponseUser = {
    code?: number
    data?: User
    message?: string
  }

  type BaseResponseUserVO = {
    code?: number
    data?: UserVO
    message?: string
  }

  type ChatHistory = {
    id?: number
    message?: string
    messageType?: string
    appId?: number
    userId?: number
    createTime?: string
    updateTime?: string
    isDelete?: number
  }

  type ChatHistoryQueryRequest = {
    pageNum?: number
    pageSize?: number
    sortField?: string
    sortOrder?: string
    id?: number
    message?: string
    messageType?: string
    appId?: number
    userId?: number
    lastCreateTime?: string
  }

  type chatToGenCodeParams = {
    appId: number
    message: string
  }

  type DeleteRequest = {
    id?: number | string
  }

  type downloadAppCodeParams = {
    appId: number | string
  }

  type getAppByIdByAdminParams = {
    id: number | string
  }

  type getAppVOByIdParams = {
    id: number | string
  }

  type getInfoParams = {
    id: number
  }

  type getUserByIdParams = {
    id: number
  }

  type getUserVOByIdParams = {
    id: number
  }

  type listAppCommentParams = {
    appId: number | string
    pageSize?: number
    lastCreateTime?: string
  }

  type listAppChatHistoryParams = {
    appId: number | string
    pageSize?: number
    lastCreateTime?: string
  }

  type LoginUserVO = {
    id?: number
    userAccount?: string
    userName?: string
    userAvatar?: string
    userProfile?: string
    gender?: number
    userRole?: string
    createTime?: string
    updateTime?: string
  }

  type PageAppCommentVO = {
    records?: AppCommentVO[]
    pageNumber?: number
    pageSize?: number
    totalPage?: number
    totalRow?: number
    optimizeCountQuery?: boolean
  }

  type PageAppVO = {
    records?: AppVO[]
    pageNumber?: number
    pageSize?: number
    totalPage?: number
    totalRow?: number
    optimizeCountQuery?: boolean
  }

  type PageChatHistory = {
    records?: ChatHistory[]
    pageNumber?: number
    pageSize?: number
    totalPage?: number
    totalRow?: number
    optimizeCountQuery?: boolean
  }

  type pageParams = {
    page: PageUser
  }

  type PageUser = {
    records?: User[]
    pageNumber?: number
    pageSize?: number
    totalPage?: number
    totalRow?: number
    optimizeCountQuery?: boolean
  }

  type PageUserVO = {
    records?: UserVO[]
    pageNumber?: number
    pageSize?: number
    totalPage?: number
    totalRow?: number
    optimizeCountQuery?: boolean
  }

  type removeParams = {
    id: number
  }

  type ServerSentEventString = true

  type serveStaticResourceParams = {
    deployKey: string
  }

  type User = {
    id?: number
    userAccount?: string
    userPassword?: string
    userName?: string
    userAvatar?: string
    userProfile?: string
    gender?: number
    userRole?: string
    editTime?: string
    createTime?: string
    updateTime?: string
    isDelete?: number
  }

  type UserAddRequest = {
    userName?: string
    userAccount?: string
    userAvatar?: string
    userProfile?: string
    gender?: number
    userRole?: string
  }

  type UserLoginRequest = {
    userAccount?: string
    userPassword?: string
  }

  type UserQueryRequest = {
    pageNum?: number
    pageSize?: number
    sortField?: string
    sortOrder?: string
    id?: number
    userName?: string
    userAccount?: string
    userProfile?: string
    userRole?: string
  }

  type UserChangePasswordRequest = {
    userPassword?: string
    newPassword?: string
    checkPassword?: string
  }

  type UserRegisterRequest = {
    userAccount?: string
    userName?: string
    userPassword?: string
    checkPassword?: string
    gender?: number
  }

  type UserUpdateRequest = {
    id?: number
    userName?: string
    userAvatar?: string
    userProfile?: string
    gender?: number
    userRole?: string
  }

  type UserVO = {
    id?: number
    userAccount?: string
    userName?: string
    userAvatar?: string
    userProfile?: string
    gender?: number
    userRole?: string
    createTime?: string
  }
}
