import { API_BASE_URL } from '@/config/env'

export interface StreamChatHandlers {
  onMessage: (chunk: string) => void
  onDone: () => void
  onError: (error: Error) => void
}

/**
 * 通过 SSE（EventSource）流式调用 /app/chat/gen/code
 */
export function generateCode(
  params: { appId: string; message: string },
  handlers: StreamChatHandlers,
) {
  const search = new URLSearchParams({
    appId: params.appId,
    message: params.message,
  })
  const url = `${API_BASE_URL}/app/chat/gen/code?${search.toString()}`
  const eventSource = new EventSource(url, { withCredentials: true })
  let isCompleted = false

  function finish() {
    if (isCompleted) {
      return
    }
    isCompleted = true
    eventSource.close()
  }

  eventSource.onmessage = (event) => {
    if (isCompleted) {
      return
    }
    try {
      const parsed = JSON.parse(event.data) as { d?: string }
      if (parsed.d !== undefined && parsed.d !== null) {
        handlers.onMessage(String(parsed.d))
      }
    } catch {
      if (event.data && event.data !== '[DONE]') {
        handlers.onMessage(event.data)
      }
    }
  }

  eventSource.addEventListener('done', () => {
    if (isCompleted) {
      return
    }
    finish()
    handlers.onDone()
  })

  eventSource.addEventListener('business-error', (event) => {
    if (isCompleted) {
      return
    }
    finish()
    try {
      const errorData = JSON.parse((event as MessageEvent).data) as { message?: string }
      handlers.onError(new Error(errorData.message || '生成过程中出现错误'))
    } catch {
      handlers.onError(new Error('服务器返回错误'))
    }
  })

  eventSource.onerror = () => {
    if (isCompleted) {
      return
    }
    // EventSource 在流正常结束后常进入 CONNECTING，按完成处理
    if (eventSource.readyState === EventSource.CONNECTING || eventSource.readyState === EventSource.CLOSED) {
      finish()
      handlers.onDone()
      return
    }
    finish()
    handlers.onError(new Error('SSE 连接错误'))
  }

  return () => {
    finish()
  }
}
