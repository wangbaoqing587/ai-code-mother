<script setup lang="ts">
interface Props {
  title: string
}

defineProps<Props>()
</script>

<template>
  <div class="admin-page">
    <div class="admin-bg" aria-hidden="true">
      <div class="admin-bg-blob admin-bg-blob-soft" />
    </div>
    <div class="admin-content">
      <h1 class="admin-title">{{ title }}</h1>
      <slot />
    </div>
  </div>
</template>

<style scoped>
.admin-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 28px 24px 56px;
  box-sizing: border-box;
  overflow: hidden;
}

.admin-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #f3f8fd 0%, #ebf4fc 50%, #f5f9ff 100%);
}

.admin-bg::before {
  content: '';
  position: absolute;
  width: 520px;
  height: 520px;
  top: -140px;
  right: -100px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(129, 212, 250, 0.42) 0%, transparent 70%);
}

.admin-bg::after {
  content: '';
  position: absolute;
  width: 440px;
  height: 440px;
  bottom: -80px;
  left: -60px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(147, 197, 253, 0.32) 0%, transparent 70%);
}

.admin-bg-blob {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}

.admin-bg-blob-soft {
  width: 380px;
  height: 380px;
  top: 120px;
  left: 45%;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(186, 230, 253, 0.35) 0%, transparent 70%);
}

.admin-content {
  position: relative;
  z-index: 1;
  max-width: 1280px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.admin-title {
  margin: 0 0 8px;
  font-size: 28px;
  font-weight: 700;
  line-height: 1.3;
  color: #1a2e35;
}

.admin-content :deep(.admin-panel) {
  padding: 20px 24px;
  background: #fff;
  border: 2px solid rgba(129, 212, 250, 0.35);
  border-radius: 20px;
  box-shadow:
    0 8px 28px rgba(129, 212, 250, 0.12),
    0 2px 8px rgba(26, 46, 53, 0.04);
}

.admin-content :deep(.search-form) {
  row-gap: 12px;
}

.admin-content :deep(.ant-form-item-label > label) {
  color: #475569;
}

.admin-content :deep(.ant-input-affix-wrapper),
.admin-content :deep(.ant-input:not(.ant-input-borderless)),
.admin-content :deep(.ant-input-number),
.admin-content :deep(.ant-select-selector) {
  border-radius: 10px !important;
  border-color: rgba(129, 212, 250, 0.45) !important;
}

.admin-content :deep(.ant-input-affix-wrapper .ant-input),
.admin-content :deep(.ant-input-number .ant-input-number-input) {
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
  background: transparent;
}

.admin-content :deep(.ant-input),
.admin-content :deep(.ant-input-number-input) {
  caret-color: #6bb5f0;
}

.admin-content :deep(.ant-input-affix-wrapper:hover),
.admin-content :deep(.ant-input:not(.ant-input-borderless):hover),
.admin-content :deep(.ant-input-number:hover),
.admin-content :deep(.ant-select-selector:hover) {
  border-color: rgba(91, 168, 232, 0.65) !important;
}

.admin-content :deep(.ant-input-affix-wrapper-focused),
.admin-content :deep(.ant-input:focus),
.admin-content :deep(.ant-input-number-focused),
.admin-content :deep(.ant-select-focused .ant-select-selector) {
  border-color: rgba(129, 212, 250, 0.45) !important;
  box-shadow: none !important;
}

.admin-content :deep(.ant-btn-primary) {
  background: #6bb5f0;
  border-color: #6bb5f0;
  border-radius: 999px;
  box-shadow: 0 4px 12px rgba(107, 181, 240, 0.3);
}

.admin-content :deep(.ant-btn-primary:hover) {
  background: #5ba8e8 !important;
  border-color: #5ba8e8 !important;
}

.admin-content :deep(.ant-btn-default) {
  border-radius: 999px;
  border-color: rgba(129, 212, 250, 0.55);
  color: #475569;
}

.admin-content :deep(.ant-btn-default:hover) {
  color: #3b82c4 !important;
  border-color: rgba(91, 168, 232, 0.65) !important;
}

.admin-content :deep(.ant-table) {
  background: transparent;
}

.admin-content :deep(.ant-table-content > table) {
  width: 100% !important;
}

.admin-content :deep(.ant-table-thead > tr > th) {
  background: #eef6fc !important;
  color: #334155;
  font-weight: 600;
  border-bottom: 1px solid rgba(129, 212, 250, 0.25) !important;
}

.admin-content :deep(.ant-table-thead > tr > th::before) {
  display: none;
}

.admin-content :deep(.ant-table-tbody > tr > td) {
  border-bottom: 1px solid rgba(129, 212, 250, 0.12);
}

.admin-content :deep(.ant-table-tbody > tr:hover > td) {
  background: #f5faff !important;
}

.admin-content :deep(.table-action-cell) {
  display: flex;
  justify-content: flex-start;
}

.admin-content :deep(.table-action-cell .ant-space) {
  justify-content: flex-start;
}

.admin-content :deep(.table-action-btn.ant-btn) {
  border-radius: 999px;
  height: 28px;
  padding: 0 12px;
  font-size: 13px;
  background: #fff;
  box-shadow: none;
}

.admin-content :deep(.table-action-btn--edit.ant-btn) {
  color: #3a7fc8;
  border-color: #4a8fd8;
}

.admin-content :deep(.table-action-btn--edit.ant-btn:hover) {
  color: #2f6fad !important;
  border-color: #3b82c4 !important;
  background: #f5faff !important;
}

.admin-content :deep(.table-action-btn--featured.ant-btn) {
  color: #3a9dad;
  border-color: #4aadbd;
}

.admin-content :deep(.table-action-btn--featured.ant-btn:hover) {
  color: #2f8a98 !important;
  border-color: #3ba0b0 !important;
  background: #f0fafc !important;
}

.admin-content :deep(.table-action-btn--delete.ant-btn) {
  color: #6a84b4;
  border-color: #7a94c4;
}

.admin-content :deep(.table-action-btn--delete.ant-btn:hover) {
  color: #5a74a4 !important;
  border-color: #6a84b4 !important;
  background: #f4f7fc !important;
}

.admin-content :deep(.empty-profile-text) {
  color: #94a3b8;
}

.admin-content :deep(.table-id-cell) {
  display: inline-block;
  max-width: 80px;
  word-break: break-all;
  line-height: 1.45;
}

.admin-content :deep(.table-message-cell) {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  word-break: break-word;
  line-height: 1.45;
  white-space: normal;
}

.admin-content :deep(.table-message-cell--clickable) {
  cursor: pointer;
  transition: color 0.2s ease;
}

.admin-content :deep(.table-message-cell--clickable:hover) {
  color: #3b82c4;
}

.admin-content :deep(.ant-table-wrapper .ant-table-pagination) {
  margin-bottom: 0;
}

.admin-content :deep(.ant-pagination-item-active) {
  border-color: #6bb5f0;
}

.admin-content :deep(.ant-pagination-item-active a) {
  color: #3b82c4;
}

.admin-content :deep(.ant-pagination-item:hover),
.admin-content :deep(.ant-pagination-prev:hover .ant-pagination-item-link),
.admin-content :deep(.ant-pagination-next:hover .ant-pagination-item-link) {
  border-color: #6bb5f0;
  color: #3b82c4;
}

.admin-content :deep(.ant-btn-link) {
  color: #3b82c4;
}

.admin-content :deep(.ant-btn-link:hover) {
  color: #2563a8 !important;
}

@media (max-width: 640px) {
  .admin-page {
    padding: 20px 16px 48px;
  }

  .admin-title {
    font-size: 22px;
  }

  .admin-content :deep(.admin-panel) {
    padding: 16px;
  }
}
</style>
