<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    texts: string[]
    typingSpeed?: number
    deletingSpeed?: number
    pauseDuration?: number
  }>(),
  {
    typingSpeed: 80,
    deletingSpeed: 45,
    pauseDuration: 2200,
  },
)

const displayText = ref('')
const containerWidth = computed(() => {
  const maxLen = Math.max(...props.texts.map((text) => text.length), 0)
  return `${(maxLen * 1.12 + 1).toFixed(1)}em`
})
let textIndex = 0
let charIndex = 0
let isDeleting = false
let timer: ReturnType<typeof setTimeout> | null = null
let reducedMotion = false

function clearTimer() {
  if (timer) {
    clearTimeout(timer)
    timer = null
  }
}

function schedule(next: () => void, delay: number) {
  clearTimer()
  timer = setTimeout(next, delay)
}

function tick() {
  const current = props.texts[textIndex] ?? ''
  if (!isDeleting) {
    charIndex += 1
    displayText.value = current.slice(0, charIndex)
    if (charIndex >= current.length) {
      isDeleting = true
      schedule(tick, props.pauseDuration)
      return
    }
    schedule(tick, props.typingSpeed)
    return
  }
  charIndex -= 1
  displayText.value = current.slice(0, charIndex)
  if (charIndex <= 0) {
    isDeleting = false
    textIndex = (textIndex + 1) % props.texts.length
    schedule(tick, props.typingSpeed)
    return
  }
  schedule(tick, props.deletingSpeed)
}

onMounted(() => {
  reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (reducedMotion || props.texts.length === 0) {
    displayText.value = props.texts[0] ?? ''
    return
  }
  tick()
})

onBeforeUnmount(() => {
  clearTimer()
})
</script>

<template>
  <span class="typewriter" :style="{ minWidth: containerWidth }">
    {{ displayText }}<span class="typewriter-cursor" aria-hidden="true">|</span>
  </span>
</template>

<style scoped>
.typewriter {
  display: inline-block;
  text-align: left;
  white-space: nowrap;
  font-family: 'Noto Serif SC', 'Songti SC', 'STSong', serif;
  font-size: 26px;
  font-weight: 500;
  letter-spacing: 0.08em;
  background: linear-gradient(120deg, #1a4d3e 0%, #2d6a5a 45%, #5bc4a0 100%);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

.typewriter-cursor {
  display: inline-block;
  margin-left: 3px;
  font-family: inherit;
  font-size: 26px;
  font-weight: 400;
  color: #5bc4a0;
  -webkit-text-fill-color: #5bc4a0;
  animation: typewriter-blink 1s step-end infinite;
}

@keyframes typewriter-blink {
  50% {
    opacity: 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .typewriter-cursor {
    animation: none;
  }
}

@media (max-width: 640px) {
  .typewriter,
  .typewriter-cursor {
    font-size: 20px;
  }
}
</style>
