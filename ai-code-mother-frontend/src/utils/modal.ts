import { Modal } from 'ant-design-vue'
import type { ModalFuncProps } from 'ant-design-vue'

export type ConfirmModalVariant = 'mint' | 'admin'

export interface ConfirmModalOptions extends ModalFuncProps {
  variant?: ConfirmModalVariant
}

export function showConfirmModal(options: ConfirmModalOptions) {
  const { variant = 'mint', wrapClassName, centered = true, ...rest } = options
  const variantClass = variant === 'admin' ? 'admin-confirm-wrap' : 'mint-confirm-wrap'
  const mergedWrapClassName = wrapClassName ? `${variantClass} ${wrapClassName}` : variantClass

  return Modal.confirm({
    centered,
    wrapClassName: mergedWrapClassName,
    ...rest,
  })
}
