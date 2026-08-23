export function throttle<T extends (...args: never[]) => void>(
  fn: T,
  wait: number,
): T & { flush: () => void; cancel: () => void } {
  let timer: ReturnType<typeof setTimeout> | null = null
  let hasPending = false

  function invoke() {
    hasPending = false
    fn()
  }

  const throttled = (() => {
    if (timer !== null) {
      hasPending = true
      return
    }
    timer = setTimeout(() => {
      timer = null
      if (hasPending) {
        invoke()
      }
    }, wait)
    invoke()
  }) as T & { flush: () => void; cancel: () => void }

  throttled.flush = () => {
    if (timer !== null) {
      clearTimeout(timer)
      timer = null
    }
    hasPending = false
    fn()
  }

  throttled.cancel = () => {
    if (timer !== null) {
      clearTimeout(timer)
      timer = null
    }
    hasPending = false
  }

  return throttled
}
