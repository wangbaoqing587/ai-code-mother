export interface TextSegment {
  type: 'text'
  content: string
}

export interface CodeSegment {
  type: 'code'
  lang: string
  content: string
  complete: boolean
  blockId: string
}

export type MessageSegment = TextSegment | CodeSegment

function parseFenceLang(fenceInfo: string) {
  const trimmed = fenceInfo.trim()
  if (!trimmed) {
    return ''
  }
  return trimmed.split(/\s+/)[0] ?? ''
}

function findClosingFence(raw: string, contentStart: number) {
  let searchFrom = contentStart
  while (searchFrom < raw.length) {
    const idx = raw.indexOf('```', searchFrom)
    if (idx === -1) {
      return -1
    }
    if (idx === contentStart || raw[idx - 1] === '\n') {
      return idx
    }
    searchFrom = idx + 3
  }
  return -1
}

export function parseStreamingMarkdown(raw: string, isStreaming = true): MessageSegment[] {
  if (!raw) {
    return []
  }

  const segments: MessageSegment[] = []
  let pos = 0
  let codeBlockIndex = 0

  while (pos < raw.length) {
    const fenceStart = raw.indexOf('```', pos)
    if (fenceStart === -1) {
      const text = raw.slice(pos)
      if (text) {
        segments.push({ type: 'text', content: text })
      }
      break
    }

    if (fenceStart > pos) {
      segments.push({ type: 'text', content: raw.slice(pos, fenceStart) })
    }

    const lineEnd = raw.indexOf('\n', fenceStart)
    if (lineEnd === -1) {
      if (isStreaming) {
        const lang = parseFenceLang(raw.slice(fenceStart + 3))
        segments.push({
          type: 'code',
          lang,
          content: '',
          complete: false,
          blockId: `pending-${codeBlockIndex}`,
        })
      } else {
        segments.push({ type: 'text', content: raw.slice(fenceStart) })
      }
      break
    }

    const lang = parseFenceLang(raw.slice(fenceStart + 3, lineEnd))
    const contentStart = lineEnd + 1
    const closeStart = findClosingFence(raw, contentStart)

    if (closeStart === -1) {
      if (isStreaming) {
        segments.push({
          type: 'code',
          lang,
          content: '',
          complete: false,
          blockId: `pending-${codeBlockIndex}`,
        })
      } else {
        const content = raw.slice(contentStart).replace(/\n$/, '')
        segments.push({
          type: 'code',
          lang,
          content,
          complete: true,
          blockId: `code-${codeBlockIndex}-${content.length}-${lang}`,
        })
      }
      break
    }

    let content = raw.slice(contentStart, closeStart)
    if (content.endsWith('\n')) {
      content = content.slice(0, -1)
    }

    segments.push({
      type: 'code',
      lang,
      content,
      complete: true,
      blockId: `code-${codeBlockIndex}-${content.length}-${lang}`,
    })
    codeBlockIndex += 1

    pos = closeStart + 3
    if (raw[pos] === '\n') {
      pos += 1
    }
  }

  return segments
}
