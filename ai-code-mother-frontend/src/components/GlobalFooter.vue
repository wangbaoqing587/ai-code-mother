<script setup lang="ts"></script>

<template>
  <a-layout-footer class="global-footer">
    <div class="footer-content">
      <span>AI 零代码应用生成平台</span>
      <a href="https://github.com" target="_blank" rel="noopener noreferrer">GitHub</a>
      <span>Copyright © 2026 AI Code Mother</span>
    </div>
  </a-layout-footer>
</template>

<style scoped>
.global-footer {
  text-align: center;
  background: #f5f5f5;
  color: rgba(0, 0, 0, 0.45);
  padding: 16px 24px;
}

.footer-content {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: center;
  gap: 12px 24px;
  font-size: 14px;
}

.footer-content a {
  color: rgba(0, 0, 0, 0.65);
}

.footer-content a:hover {
  color: #1677ff;
}
</style>
