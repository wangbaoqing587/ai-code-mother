<script setup lang="ts">
import { computed } from 'vue'
import { formatCodeGenType, getCodeGenTypeOption } from '@/constants/codeGenType'

interface Props {
  codeGenType?: string
}

const props = defineProps<Props>()

const typeTag = computed(() => {
  const option = getCodeGenTypeOption(props.codeGenType)
  return {
    label: option?.label || formatCodeGenType(props.codeGenType) || '应用',
    color: option?.color || '#8c8c8c',
  }
})
</script>

<template>
  <span
    class="code-gen-type-tag"
    :style="{ background: typeTag.color + '22', color: typeTag.color }"
  >
    {{ typeTag.label }}
  </span>
</template>

<style scoped>
.code-gen-type-tag {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 12px;
  line-height: 20px;
  white-space: nowrap;
}
</style>
