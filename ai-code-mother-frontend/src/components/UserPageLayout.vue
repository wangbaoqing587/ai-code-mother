<script setup lang="ts">
interface Props {
  title: string
  fillViewport?: boolean
}

withDefaults(defineProps<Props>(), {
  fillViewport: true,
})
</script>

<template>
  <div class="user-page" :class="{ 'user-page--compact': !fillViewport }">
    <div class="user-bg" aria-hidden="true">
      <div class="user-bg-blob user-bg-blob-soft" />
    </div>
    <div class="user-content">
      <div class="user-page-header">
        <h1 class="user-title">{{ title }}</h1>
      </div>
      <div class="user-panel">
        <slot />
      </div>
    </div>
    <div v-if="$slots.extra" class="user-extra">
      <slot name="extra" />
    </div>
  </div>
</template>

<style scoped>
.user-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 28px 24px 56px;
  box-sizing: border-box;
  overflow: hidden;
}

.user-page--compact {
  min-height: auto;
  padding-bottom: 24px;
}

.user-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #faf9f7 0%, #f7f6f4 50%, #fafaf8 100%);
}

.user-bg::before {
  content: '';
  position: absolute;
  width: 520px;
  height: 520px;
  top: -140px;
  right: -100px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(136, 216, 176, 0.22) 0%, transparent 70%);
}

.user-bg::after {
  content: '';
  position: absolute;
  width: 440px;
  height: 440px;
  bottom: -80px;
  left: -60px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(180, 210, 195, 0.18) 0%, transparent 70%);
}

.user-bg-blob {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}

.user-bg-blob-soft {
  width: 380px;
  height: 380px;
  top: 120px;
  left: 45%;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(136, 216, 176, 0.16) 0%, transparent 70%);
}

.user-content {
  position: relative;
  z-index: 1;
  max-width: 760px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.user-extra {
  position: relative;
  z-index: 1;
}

.user-page-header {
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-title {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  line-height: 1.3;
  color: #1a2e35;
  text-align: center;
}

.user-panel {
  padding: 24px 28px;
  background: #fff;
  border: 2px solid rgba(136, 216, 176, 0.28);
  border-radius: 20px;
  box-shadow:
    0 8px 28px rgba(136, 216, 176, 0.08),
    0 2px 8px rgba(26, 46, 53, 0.04);
}

.user-panel :deep(.ant-form-item-label > label) {
  color: #475569;
}

.user-panel :deep(.ant-input),
.user-panel :deep(.ant-input-affix-wrapper),
.user-panel :deep(.ant-input-textarea textarea) {
  border-radius: 10px !important;
  border-color: rgba(136, 216, 176, 0.4) !important;
}

.user-panel :deep(.ant-input-affix-wrapper .ant-input),
.user-panel :deep(.ant-input-textarea textarea) {
  border: none !important;
  box-shadow: none !important;
}

.user-panel :deep(.ant-input:hover),
.user-panel :deep(.ant-input-affix-wrapper:hover),
.user-panel :deep(.ant-input-textarea textarea:hover) {
  border-color: rgba(91, 196, 160, 0.55) !important;
}

.user-panel :deep(.ant-input),
.user-panel :deep(.ant-input-textarea textarea) {
  caret-color: #5bc4a0;
}

.user-panel :deep(.ant-btn-primary) {
  background: #5bc4a0;
  border-color: #5bc4a0;
  border-radius: 999px;
  box-shadow: 0 4px 12px rgba(91, 196, 160, 0.28);
}

.user-panel :deep(.ant-btn-primary:hover) {
  background: #4db892 !important;
  border-color: #4db892 !important;
}

.user-panel :deep(.ant-btn-default) {
  border-radius: 999px;
  border-color: rgba(136, 216, 176, 0.45);
  color: #475569;
}

.user-panel :deep(.ant-btn-default:hover) {
  color: #2d9a78 !important;
  border-color: rgba(91, 196, 160, 0.55) !important;
}

.user-panel :deep(.ant-descriptions-bordered .ant-descriptions-item-label) {
  width: 120px;
  background: #f7faf8;
  color: #475569;
  font-weight: 500;
  border-color: rgba(136, 216, 176, 0.2) !important;
}

.user-panel :deep(.ant-descriptions-bordered .ant-descriptions-item-content) {
  color: #334155;
  border-color: rgba(136, 216, 176, 0.2) !important;
}

.user-panel :deep(.ant-descriptions-bordered .ant-descriptions-view) {
  border-color: rgba(136, 216, 176, 0.2) !important;
  border-radius: 12px;
  overflow: hidden;
}

@media (max-width: 640px) {
  .user-page {
    padding: 20px 16px 48px;
  }

  .user-title {
    font-size: 22px;
  }

  .user-panel {
    padding: 16px;
  }
}
</style>
