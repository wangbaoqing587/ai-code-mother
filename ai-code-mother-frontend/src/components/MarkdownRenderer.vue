<script setup lang="ts">
import { computed } from 'vue'
import { renderMarkdown } from '@/utils/markdown'
import 'highlight.js/styles/github.css'

interface Props {
  content: string
}

const props = defineProps<Props>()

const htmlContent = computed(() => renderMarkdown(props.content))
</script>

<template>
  <div class="markdown-body" v-html="htmlContent" />
</template>

<style scoped>
.markdown-body {
  font-size: 14px;
  line-height: 1.7;
  color: rgba(0, 0, 0, 0.88);
  word-break: break-word;
  overflow-wrap: anywhere;
}

.markdown-body :deep(:first-child) {
  margin-top: 0;
}

.markdown-body :deep(:last-child) {
  margin-bottom: 0;
}

.markdown-body :deep(p),
.markdown-body :deep(ul),
.markdown-body :deep(ol),
.markdown-body :deep(blockquote),
.markdown-body :deep(pre),
.markdown-body :deep(table) {
  margin: 0 0 12px;
}

.markdown-body :deep(h1),
.markdown-body :deep(h2),
.markdown-body :deep(h3),
.markdown-body :deep(h4),
.markdown-body :deep(h5),
.markdown-body :deep(h6) {
  margin: 16px 0 8px;
  font-weight: 600;
  line-height: 1.35;
}

.markdown-body :deep(h1) {
  font-size: 1.4em;
}

.markdown-body :deep(h2) {
  font-size: 1.25em;
}

.markdown-body :deep(h3) {
  font-size: 1.1em;
}

.markdown-body :deep(ul),
.markdown-body :deep(ol) {
  padding-left: 1.4em;
}

.markdown-body :deep(li + li) {
  margin-top: 4px;
}

.markdown-body :deep(blockquote) {
  padding: 0 12px;
  color: rgba(0, 0, 0, 0.55);
  border-left: 3px solid #d9d9d9;
}

.markdown-body :deep(a) {
  color: #1677ff;
  text-decoration: none;
}

.markdown-body :deep(a:hover) {
  text-decoration: underline;
}

.markdown-body :deep(code) {
  padding: 0.15em 0.4em;
  border-radius: 4px;
  background: #f5f5f5;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 0.9em;
}

.markdown-body :deep(pre) {
  overflow-x: auto;
  padding: 12px 14px;
  border-radius: 8px;
  background: #f6f8fa;
  border: 1px solid #eaeef2;
}

.markdown-body :deep(pre code) {
  padding: 0;
  background: transparent;
  border-radius: 0;
  font-size: 13px;
  line-height: 1.55;
}

.markdown-body :deep(table) {
  width: 100%;
  border-collapse: collapse;
  display: block;
  overflow-x: auto;
}

.markdown-body :deep(th),
.markdown-body :deep(td) {
  padding: 6px 10px;
  border: 1px solid #e8e8e8;
}

.markdown-body :deep(th) {
  background: #fafafa;
  font-weight: 600;
}

.markdown-body :deep(hr) {
  margin: 16px 0;
  border: none;
  border-top: 1px solid #f0f0f0;
}

.markdown-body :deep(img) {
  max-width: 100%;
}
</style>
