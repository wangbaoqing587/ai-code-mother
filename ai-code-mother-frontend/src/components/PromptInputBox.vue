<script setup lang="ts">
import { iconAigenerate } from '@/assets'

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
      <div class="prompt-actions-extra">
        <slot name="actions" />
      </div>
      <a-button
        class="send-btn send-btn-hero"
        type="primary"
        shape="circle"
        :loading="loading"
        :disabled="disableSubmit || disabled"
        @click="handleSubmit"
      >
        <template #icon>
          <img :src="iconAigenerate" alt="" class="send-icon-img" />
        </template>
      </a-button>
    </div>
  </div>
</template>

<style scoped>
.prompt-input-box.is-hero {
  padding: 16px 18px 14px;
  text-align: left;
  background: #fff;
  border: 2px solid rgba(136, 216, 176, 0.5);
  border-radius: 20px;
  box-shadow:
    0 10px 32px rgba(136, 216, 176, 0.14),
    0 2px 8px rgba(26, 46, 53, 0.05);
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.prompt-input-box.is-hero:focus-within {
  border-color: rgba(91, 196, 160, 0.75);
  box-shadow:
    0 12px 36px rgba(136, 216, 176, 0.2),
    0 2px 8px rgba(26, 46, 53, 0.05);
}

.prompt-input-box.is-chat {
  margin: 0 16px 12px;
  padding: 12px 14px;
  background: #fff;
  border: 2px solid rgba(136, 216, 176, 0.45);
  border-radius: 18px;
  box-shadow: 0 4px 16px rgba(136, 216, 176, 0.1);
  transition:
    border-color 0.2s ease,
    box-shadow 0.2s ease;
}

.prompt-input-box.is-chat:focus-within {
  border-color: rgba(91, 196, 160, 0.7);
  box-shadow: 0 6px 20px rgba(136, 216, 176, 0.16);
}

.prompt-input-box.is-chat .prompt-input :deep(.ant-input::placeholder) {
  color: #94a3b8;
}

.prompt-input-box.is-hero .prompt-input {
  font-size: 16px;
  line-height: 1.6;
}

.prompt-input-box.is-hero .prompt-input :deep(.ant-input) {
  padding: 0;
  min-height: 52px !important;
}

.prompt-input-box.is-hero .prompt-input :deep(.ant-input::placeholder) {
  color: #94a3b8;
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
  gap: 8px;
  margin-top: 4px;
}

.prompt-actions-extra {
  display: flex;
  align-items: center;
  gap: 8px;
}

.send-btn {
  width: 40px;
  height: 40px;
}

.prompt-input-box.is-hero .send-btn-hero,
.prompt-input-box.is-chat .send-btn-hero {
  width: 44px;
  height: 44px;
  border: 1.5px solid rgba(255, 255, 255, 0.7) !important;
  background: linear-gradient(
    145deg,
    rgba(136, 216, 176, 0.92) 0%,
    rgba(77, 184, 146, 0.86) 100%
  ) !important;
  box-shadow:
    0 4px 14px rgba(91, 196, 160, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.55),
    inset 0 -1px 0 rgba(91, 196, 160, 0.12);
  backdrop-filter: blur(6px);
}

.prompt-input-box.is-hero .send-btn-hero:hover:not(:disabled),
.prompt-input-box.is-chat .send-btn-hero:hover:not(:disabled) {
  border-color: rgba(255, 255, 255, 0.85) !important;
  background: linear-gradient(
    145deg,
    rgba(120, 210, 175, 0.96) 0%,
    rgba(68, 175, 138, 0.92) 100%
  ) !important;
  box-shadow:
    0 6px 18px rgba(91, 196, 160, 0.28),
    inset 0 1px 0 rgba(255, 255, 255, 0.65),
    inset 0 -1px 0 rgba(91, 196, 160, 0.15);
}

.prompt-input-box.is-hero .send-btn-hero:disabled,
.prompt-input-box.is-chat .send-btn-hero:disabled {
  border-color: rgba(255, 255, 255, 0.45) !important;
  background: rgba(136, 216, 176, 0.42) !important;
  box-shadow: none;
  backdrop-filter: none;
}

.send-icon-img {
  width: 26px;
  height: 26px;
  object-fit: contain;
}
</style>
