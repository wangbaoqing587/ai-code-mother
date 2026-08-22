<script setup lang="ts">
interface Props {
  title: string
}

defineProps<Props>()
</script>

<template>
  <div class="auth-page">
    <div class="auth-bg" aria-hidden="true">
      <div class="auth-bg-blob auth-bg-blob-soft" />
    </div>
    <div class="auth-content">
      <div class="auth-panel">
        <h2 class="auth-title">{{ title }}</h2>
        <slot />
        <div v-if="$slots.footer" class="auth-footer">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  position: relative;
  width: 100%;
  min-height: calc(100vh - 64px);
  padding: 32px 24px 56px;
  box-sizing: border-box;
  overflow: hidden;
}

.auth-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #faf9f7 0%, #f7f6f4 50%, #fafaf8 100%);
}

.auth-bg::before {
  content: '';
  position: absolute;
  width: 520px;
  height: 520px;
  top: -140px;
  right: -100px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(136, 216, 176, 0.22) 0%, transparent 70%);
}

.auth-bg::after {
  content: '';
  position: absolute;
  width: 440px;
  height: 440px;
  bottom: -80px;
  left: -60px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(180, 210, 195, 0.18) 0%, transparent 70%);
}

.auth-bg-blob {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}

.auth-bg-blob-soft {
  width: 380px;
  height: 380px;
  top: 120px;
  left: 50%;
  transform: translateX(-50%);
  background: radial-gradient(circle, rgba(136, 216, 176, 0.16) 0%, transparent 70%);
}

.auth-content {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 64px - 88px);
  max-width: 420px;
  margin: 0 auto;
}

.auth-panel {
  width: 100%;
  padding: 28px 28px 24px;
  background: #fff;
  border: 2px solid rgba(136, 216, 176, 0.28);
  border-radius: 20px;
  box-shadow:
    0 8px 28px rgba(136, 216, 176, 0.08),
    0 2px 8px rgba(26, 46, 53, 0.04);
}

.auth-title {
  margin: 0 0 24px;
  text-align: center;
  font-size: 26px;
  font-weight: 700;
  line-height: 1.3;
  color: #1a2e35;
}

.auth-footer {
  margin-top: 16px;
  text-align: center;
  font-size: 14px;
  color: #64748b;
}

.auth-footer :deep(a) {
  color: #2d9a78;
  font-weight: 500;
}

.auth-footer :deep(a:hover) {
  color: #5bc4a0;
}

.auth-panel :deep(.ant-form-item-label > label) {
  color: #475569;
}

.auth-panel :deep(.ant-input),
.auth-panel :deep(.ant-input-affix-wrapper),
.auth-panel :deep(.ant-input-password) {
  border-radius: 10px !important;
  border-color: rgba(136, 216, 176, 0.4) !important;
}

.auth-panel :deep(.ant-input-affix-wrapper .ant-input) {
  border: none !important;
  box-shadow: none !important;
  border-radius: 0 !important;
}

.auth-panel :deep(.ant-input:hover),
.auth-panel :deep(.ant-input-affix-wrapper:hover) {
  border-color: rgba(91, 196, 160, 0.55) !important;
}

.auth-panel :deep(.ant-input),
.auth-panel :deep(.ant-input-affix-wrapper .ant-input) {
  caret-color: #5bc4a0;
}

.auth-panel :deep(.ant-input:not(.ant-input-borderless)),
.auth-panel :deep(.ant-input-affix-wrapper),
.auth-panel :deep(.ant-input-affix-wrapper .ant-input) {
  background-color: #fff !important;
}

.auth-panel :deep(.ant-input:not(.ant-input-borderless):-webkit-autofill),
.auth-panel :deep(.ant-input:not(.ant-input-borderless):-webkit-autofill:hover),
.auth-panel :deep(.ant-input:not(.ant-input-borderless):-webkit-autofill:focus),
.auth-panel :deep(.ant-input-affix-wrapper .ant-input:-webkit-autofill),
.auth-panel :deep(.ant-input-affix-wrapper .ant-input:-webkit-autofill:hover),
.auth-panel :deep(.ant-input-affix-wrapper .ant-input:-webkit-autofill:focus) {
  -webkit-box-shadow: 0 0 0 1000px #fff inset !important;
  box-shadow: 0 0 0 1000px #fff inset !important;
  -webkit-text-fill-color: #1a2e35 !important;
  transition: background-color 99999s ease-out 0s;
}

.auth-panel :deep(.ant-btn-primary) {
  height: 40px;
  background: #5bc4a0;
  border-color: #5bc4a0;
  border-radius: 999px;
  box-shadow: 0 4px 12px rgba(91, 196, 160, 0.28);
}

.auth-panel :deep(.ant-btn-primary:hover) {
  background: #4db892 !important;
  border-color: #4db892 !important;
}

@media (max-width: 640px) {
  .auth-page {
    padding: 24px 16px 48px;
  }

  .auth-content {
    min-height: calc(100vh - 64px - 72px);
  }

  .auth-panel {
    padding: 24px 20px 20px;
  }

  .auth-title {
    font-size: 22px;
  }
}
</style>
