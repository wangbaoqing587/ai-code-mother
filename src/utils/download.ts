export function getFilenameFromContentDisposition(
  contentDisposition?: string,
  fallback = 'download.zip',
) {
  if (!contentDisposition) {
    return fallback
  }
  const utf8Match = contentDisposition.match(/filename\*=UTF-8''([^;]+)/i)
  if (utf8Match?.[1]) {
    return decodeURIComponent(utf8Match[1])
  }
  const asciiMatch = contentDisposition.match(/filename="?([^"]+)"?/i)
  if (asciiMatch?.[1]) {
    return asciiMatch[1]
  }
  return fallback
}

export function triggerBlobDownload(blob: Blob, filename: string) {
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  window.URL.revokeObjectURL(url)
}
