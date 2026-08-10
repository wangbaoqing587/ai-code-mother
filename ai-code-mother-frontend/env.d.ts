/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  readonly VITE_DEPLOY_DOMAIN: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

import 'vue-router'

declare module 'vue-router' {
  interface RouteMeta {
    access?: string
  }
}
