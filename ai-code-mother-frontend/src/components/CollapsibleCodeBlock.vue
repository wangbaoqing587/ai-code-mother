<script setup lang="ts">
import { computed, ref } from 'vue'
import { highlightCode } from '@/utils/markdown'
import 'highlight.js/styles/github.css'

interface Props {
  lang: string
  content: string
  defaultCollapsed?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  defaultCollapsed: true,
})

const collapsed = ref(props.defaultCollapsed)

const highlightedHtml = computed(() => highlightCode(props.content, props.lang))

const lineCount = computed(() => {
  if (!props.content) {
    return 0
  }
  return props.content.split('\n').length
})

const langLabel = computed(() => props.lang || 'code')

function toggleCollapsed() {
  collapsed.value = !collapsed.value
}
</script>

<template>
  <div class="collapsible-code-block">
    <button type="button" class="code-block-header" @click="toggleCollapsed">
      <span class="code-block-toggle" :class="{ 'is-expanded': !collapsed }">▶</span>
      <span class="code-block-lang">{{ langLabel }}</span>
      <span class="code-block-meta">{{ lineCount }} 行</span>
    </button>
    <div v-show="!collapsed" class="code-block-body" v-html="highlightedHtml" />
  </div>
</template>

<style scoped>
.collapsible-code-block {
  margin: 0 0 12px;
  border: 1px solid #eaeef2;
  border-radius: 8px;
  overflow: hidden;
  background: #f6f8fa;
}

.code-block-header {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 8px 12px;
  border: none;
  background: #eef2f6;
  cursor: pointer;
  text-align: left;
  font-size: 13px;
  color: #475569;
}

.code-block-header:hover {
  background: #e8edf2;
}

.code-block-toggle {
  display: inline-block;
  font-size: 10px;
  transition: transform 0.2s ease;
  color: #64748b;
}

.code-block-toggle.is-expanded {
  transform: rotate(90deg);
}

.code-block-lang {
  font-weight: 600;
  color: #334155;
}

.code-block-meta {
  margin-left: auto;
  font-size: 12px;
  color: #94a3b8;
}

.code-block-body :deep(pre) {
  margin: 0;
  padding: 12px 14px;
  overflow-x: auto;
  background: #f6f8fa;
  border: none;
  border-radius: 0;
}

.code-block-body :deep(code) {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 13px;
  line-height: 1.55;
}
</style>
