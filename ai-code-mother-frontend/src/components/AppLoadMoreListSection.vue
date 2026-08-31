<script setup lang="ts">
import { computed } from 'vue'
import AppCard from '@/components/AppCard.vue'

interface Props {
  title: string
  apps: API.AppVO[]
  total: number
  loading?: boolean
  loadingMore?: boolean
  restrictChatToOwner?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  loadingMore: false,
  restrictChatToOwner: false,
})

const emit = defineEmits<{
  loadMore: []
}>()

const hasMore = computed(() => props.apps.length < props.total)
</script>

<template>
  <section class="list-section">
    <h2 class="section-title">{{ title }}</h2>
    <a-spin :spinning="loading">
      <div class="app-grid app-grid--compact">
        <AppCard
          v-for="app in apps"
          :key="app.id"
          :app="app"
          variant="compact"
          :restrict-chat-to-owner="restrictChatToOwner"
        />
      </div>
      <div v-if="hasMore" class="load-more-wrap">
        <a-button :loading="loadingMore" @click="emit('loadMore')">加载更多</a-button>
      </div>
    </a-spin>
  </section>
</template>

<style scoped>
.list-section {
  position: relative;
  z-index: 1;
  max-width: 1320px;
  margin: 0 auto 40px;
  padding: 28px 24px;
  background: transparent;
  box-sizing: border-box;
}

.section-title {
  margin: 0 0 20px;
  font-size: 24px;
  font-weight: 700;
  text-align: center;
  color: #1a2e35;
}

.app-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.app-grid--compact {
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 16px;
}

.load-more-wrap {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}

@media (max-width: 1200px) {
  .app-grid--compact {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

@media (max-width: 960px) {
  .app-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .app-grid--compact {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .list-section {
    padding: 20px 16px;
  }

  .app-grid {
    grid-template-columns: 1fr;
  }

  .app-grid--compact {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 12px;
  }
}

@media (max-width: 480px) {
  .app-grid--compact {
    grid-template-columns: 1fr;
  }
}
</style>
