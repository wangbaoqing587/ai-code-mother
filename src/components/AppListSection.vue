<script setup lang="ts">
import AppCard from '@/components/AppCard.vue'

interface Props {
  title: string
  apps: API.AppVO[]
  total: number
  loading?: boolean
  pageNum: number
  pageSize: number
}

withDefaults(defineProps<Props>(), {
  loading: false,
})

const emit = defineEmits<{
  pageChange: [page: number]
}>()
</script>

<template>
  <section class="list-section">
    <h2 class="section-title">{{ title }}</h2>
    <a-spin :spinning="loading">
      <div class="app-grid">
        <AppCard v-for="app in apps" :key="app.id" :app="app" />
      </div>
      <div v-if="total > pageSize" class="pagination-wrap">
        <a-pagination
          :current="pageNum"
          :page-size="pageSize"
          :total="total"
          @change="emit('pageChange', $event)"
        />
      </div>
    </a-spin>
  </section>
</template>

<style scoped>
.list-section {
  position: relative;
  z-index: 1;
  max-width: 1120px;
  margin: 0 auto 40px;
  padding: 28px 0;
  background: transparent;
}

.section-title {
  margin: 0 0 20px;
  font-size: 24px;
  font-weight: 700;
  text-align: center;
  color: #f8fafc;
}

.app-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
}

.pagination-wrap {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}

@media (max-width: 960px) {
  .app-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 640px) {
  .list-section {
    padding: 20px 0;
  }

  .app-grid {
    grid-template-columns: 1fr;
  }
}
</style>
