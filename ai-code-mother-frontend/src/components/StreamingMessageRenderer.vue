<script setup lang="ts">
import { computed } from 'vue'
import CollapsibleCodeBlock from '@/components/CollapsibleCodeBlock.vue'
import {
  parseStreamingMarkdown,
  type MessageSegment,
} from '@/utils/streamingMarkdown'

interface Props {
  content: string
  isStreaming?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  isStreaming: false,
})

const segments = computed(() => parseStreamingMarkdown(props.content, props.isStreaming))

function segmentKey(segment: MessageSegment, index: number) {
  if (segment.type === 'text') {
    return `text-${index}-${segment.content.length}`
  }
  return segment.blockId
}
</script>

<template>
  <div class="streaming-message">
    <template v-if="segments.length">
      <template v-for="(segment, index) in segments" :key="segmentKey(segment, index)">
        <pre v-if="segment.type === 'text'" class="message-text">{{ segment.content }}</pre>
        <CollapsibleCodeBlock
          v-else-if="segment.complete"
          :lang="segment.lang"
          :content="segment.content"
          :default-collapsed="true"
        />
        <div v-else class="code-pending">
          <a-spin size="small" />
          <span>代码生成中...</span>
          <span v-if="segment.lang" class="code-pending-lang">{{ segment.lang }}</span>
        </div>
      </template>
    </template>
    <pre v-else-if="isStreaming" class="message-text">生成中...</pre>
  </div>
</template>

<style scoped>
.streaming-message {
  font-size: 14px;
  line-height: 1.6;
  color: #334155;
}

.message-text {
  margin: 0 0 12px;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
}

.message-text:last-child {
  margin-bottom: 0;
}

.code-pending {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px dashed rgba(136, 216, 176, 0.55);
  background: rgba(240, 253, 247, 0.6);
  color: #64748b;
  font-size: 13px;
}

.code-pending-lang {
  margin-left: auto;
  padding: 2px 8px;
  border-radius: 999px;
  background: rgba(91, 196, 160, 0.16);
  color: #2d9a78;
  font-size: 12px;
  font-weight: 500;
}
</style>
