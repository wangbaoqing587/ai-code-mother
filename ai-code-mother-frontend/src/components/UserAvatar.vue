<script setup lang="ts">
import { computed } from 'vue'
import { avatarDefaultMale, avatarDefaultFemale } from '@/assets'

interface Props {
  src?: string
  size?: number
  gender?: number
}

const props = withDefaults(defineProps<Props>(), {
  src: '',
  size: 32,
  gender: 1,
})

const avatarSrc = computed(() => {
  if (props.src) {
    return props.src
  }
  return props.gender === 0 ? avatarDefaultFemale : avatarDefaultMale
})
</script>

<template>
  <a-avatar :size="size" :src="avatarSrc" />
</template>
