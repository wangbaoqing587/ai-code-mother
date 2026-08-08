<script setup lang="ts">
import { computed } from 'vue'
import { avatarDefault } from '@/assets'

interface Props {
  src?: string
  size?: number
}

const props = withDefaults(defineProps<Props>(), {
  src: '',
  size: 32,
})

const avatarSrc = computed(() => props.src || avatarDefault)
</script>

<template>
  <a-avatar :size="size" :src="avatarSrc" />
</template>
