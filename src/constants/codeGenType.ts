export const CODE_GEN_TYPE_ENUM = {
  HTML: 'html',
  MULTI_FILE: 'multi_file',
  VUE_PROJECT: 'vue_project',
} as const

export type CodeGenType = (typeof CODE_GEN_TYPE_ENUM)[keyof typeof CODE_GEN_TYPE_ENUM]

export interface CodeGenTypeOption {
  value: CodeGenType
  label: string
  color: string
}

export const CODE_GEN_TYPE_OPTIONS: CodeGenTypeOption[] = [
  { value: CODE_GEN_TYPE_ENUM.HTML, label: '原生 HTML 模式', color: '#5b8ff9' },
  { value: CODE_GEN_TYPE_ENUM.MULTI_FILE, label: '原生多文件模式', color: '#5b8ff9' },
  { value: CODE_GEN_TYPE_ENUM.VUE_PROJECT, label: 'Vue 工程模式', color: '#9270ca' },
]

const CODE_GEN_TYPE_MAP: Record<string, CodeGenTypeOption> = Object.fromEntries(
  CODE_GEN_TYPE_OPTIONS.map((item) => [item.value, item]),
)

export function formatCodeGenType(codeGenType?: string) {
  if (!codeGenType) {
    return '-'
  }
  return CODE_GEN_TYPE_MAP[codeGenType]?.label ?? codeGenType
}

export function getCodeGenTypeOption(codeGenType?: string) {
  if (!codeGenType) {
    return undefined
  }
  return CODE_GEN_TYPE_MAP[codeGenType]
}
