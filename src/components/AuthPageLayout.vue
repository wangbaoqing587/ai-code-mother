<script setup lang="ts">
interface Props {
  title: string
}

defineProps<Props>()
</script>

<template>
  <div class="auth-page">
    <h2 class="auth-title">{{ title }}</h2>
    <slot />
    <div v-if="$slots.footer" class="auth-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  max-width: 400px;
  margin: 48px auto 0;
}

.auth-title {
  margin: 0 0 24px;
  text-align: center;
  font-size: 24px;
  font-weight: 600;
}

.auth-footer {
  text-align: center;
}
</style>
