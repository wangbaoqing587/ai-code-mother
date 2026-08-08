<script setup lang="ts">
interface Props {
  modelValue: string
  placeholder?: string
  loading?: boolean
  disabled?: boolean
  disableSubmit?: boolean
  minRows?: number
  maxRows?: number
  variant?: 'hero' | 'chat'
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: '',
  loading: false,
  disabled: false,
  disableSubmit: false,
  minRows: 3,
  maxRows: 6,
  variant: 'chat',
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  submit: []
}>()

function handleUpdate(value: string) {
  emit('update:modelValue', value)
}

function handleSubmit() {
  if (props.disabled || props.loading || props.disableSubmit) {
    return
  }
  emit('submit')
}
</script>

<template>
  <div class="prompt-input-box" :class="`is-${variant}`">
    <a-textarea
      :value="modelValue"
      class="prompt-input"
      :auto-size="{ minRows, maxRows }"
      :placeholder="placeholder"
      :bordered="false"
      :disabled="disabled"
      @update:value="handleUpdate"
      @pressEnter.exact.prevent="handleSubmit"
    />
    <div class="prompt-actions">
      <a-button
        class="send-btn"
        type="primary"
        shape="circle"
        :loading="loading"
        :disabled="disableSubmit || disabled"
        @click="handleSubmit"
      >
        <template #icon>
          <span class="send-icon">↑</span>
        </template>
      </a-button>
    </div>
  </div>
</template>

<style scoped>
.prompt-input-box.is-hero {
  padding: 18px 18px 14px;
  text-align: left;
  background: rgba(255, 255, 255, 0.92);
  border-radius: 20px;
  box-shadow: 0 16px 48px rgba(2, 20, 40, 0.28);
  backdrop-filter: blur(12px);
}

.prompt-input-box.is-chat {
  margin: 0 16px 12px;
  padding: 10px 14px 12px;
  background: #fff;
  border: 1px solid #f0f0f0;
  border-radius: 16px;
}

.prompt-input {
  font-size: 16px;
  resize: none;
}

.prompt-input-box.is-chat .prompt-input {
  font-size: 14px;
}

.prompt-input :deep(.ant-input) {
  background: transparent;
  box-shadow: none;
}

.prompt-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  margin-top: 8px;
}

.send-btn {
  width: 40px;
  height: 40px;
}

.prompt-input-box.is-hero .send-btn {
  background: #0ea5e9 !important;
  border-color: #0ea5e9 !important;
}

.send-icon {
  font-size: 18px;
  font-weight: 700;
}

.prompt-input-box.is-chat .send-icon {
  font-size: 16px;
}
</style>
