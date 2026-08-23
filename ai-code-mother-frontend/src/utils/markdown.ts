import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js/lib/core'
import javascript from 'highlight.js/lib/languages/javascript'
import xml from 'highlight.js/lib/languages/xml'
import css from 'highlight.js/lib/languages/css'

hljs.registerLanguage('javascript', javascript)
hljs.registerLanguage('js', javascript)
hljs.registerLanguage('html', xml)
hljs.registerLanguage('xml', xml)
hljs.registerLanguage('css', css)

const md = new MarkdownIt({
  html: false,
  linkify: true,
  breaks: true,
})

export function highlightCode(code: string, lang: string): string {
  if (lang && hljs.getLanguage(lang)) {
    try {
      return (
        '<pre class="hljs"><code class="language-' +
        lang +
        '">' +
        hljs.highlight(code, { language: lang, ignoreIllegals: true }).value +
        '</code></pre>'
      )
    } catch {
      // ignore
    }
  }
  return '<pre class="hljs"><code>' + md.utils.escapeHtml(code) + '</code></pre>'
}

md.set({
  highlight(str: string, lang: string): string {
    return highlightCode(str, lang)
  },
})

export function renderMarkdown(content: string) {
  if (!content) {
    return ''
  }
  return md.render(content)
}
