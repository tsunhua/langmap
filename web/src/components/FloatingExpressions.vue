<template>
  <div class="absolute inset-0 overflow-hidden pointer-events-none">
    <div
      v-for="(expr, index) in floatingExpressions"
      :key="expr.id"
      class="floating-expression"
      :class="['color-' + (index % 6), { 'paused': isHovered[index] }]"
      :style="getExpressionStyle(index)"
      @mouseenter="isHovered[index] = true"
      @mouseleave="isHovered[index] = false"
      @click="goToExpression(expr.id)"
    >
      {{ expr.text }}
    </div>
  </div>
</template>

<script>
import { ref, onMounted, watch, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'FloatingExpressions',
  setup() {
    const router = useRouter()
    const { locale } = useI18n()
    const expressions = ref([])
    const loading = ref(true)
    const positions = ref([])
    const velocities = ref([])
    const isHovered = ref({})

    const floatingExpressions = computed(() => {
      return expressions.value.slice(0, 10)
    })

    const goToExpression = (id) => {
      router.push({ name: 'Detail', params: { id } })
    }

    const loadExpressions = async () => {
      loading.value = true
      try {
        let currentLang = locale.value

        if (!currentLang || currentLang === 'en-US') {
          const savedLang = localStorage.getItem('langmap-lang')
          if (savedLang) {
            currentLang = savedLang
          }
        }

        console.log('Loading expressions for language:', currentLang)
        const res = await fetch(`/api/v1/expressions?language=${currentLang}&limit=10&exclude_tag=langmap`)
        if (!res.ok) throw new Error('Failed to fetch expressions')
        const data = await res.json()

        console.log('Loaded expressions:', data)
        expressions.value = data || []

        const count = Math.min(data.length, 10)
        const minY = 10
        const maxY = 70
        const spacing = (maxY - minY) / Math.max(count - 1, 1)
        positions.value = Array.from({ length: count }, (_, index) => ({
          x: -10 - (index * 4),
          y: minY + (index * spacing)
        }))

        velocities.value = Array.from({ length: count }, () => ({
          speed: 0.015 + Math.random() * 0.025
        }))

        isHovered.value = {}
      } catch (e) {
        console.error('Failed to load expressions:', e)
      } finally {
        loading.value = false
      }
    }

    const getExpressionStyle = (index) => {
      const pos = positions.value[index] || { x: 0, y: 0 }
      return {
        left: `${pos.x}%`,
        top: `${pos.y}%`
      }
    }

    const animate = () => {
      if (loading.value || positions.value.length === 0) {
        requestAnimationFrame(animate)
        return
      }

      const newPositions = positions.value.map((pos, index) => {
        if (isHovered.value[index]) return pos

        const vel = velocities.value[index] || { speed: 0.015 }
        let newX = pos.x + vel.speed
        let newY = pos.y

        if (newX > 105) {
          newX = -20
        }

        return { x: newX, y: newY }
      })

      positions.value = newPositions
      requestAnimationFrame(animate)
    }

    onMounted(() => {
      loadExpressions()
      animate()
    })

    watch(locale, () => {
      console.log('Language changed to:', locale.value)
      loadExpressions()
    })

    return {
      floatingExpressions,
      loading,
      positions,
      isHovered,
      goToExpression,
      getExpressionStyle
    }
  }
}
</script>

<style scoped>
.floating-expression {
  position: absolute;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
  background: rgba(255, 255, 255, 0.95);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  pointer-events: auto;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;
  white-space: nowrap;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  z-index: 1;
}

.floating-expression.color-0 {
  color: #64748b;
}

.floating-expression.color-1 {
  color: #8b5cf6;
}

.floating-expression.color-2 {
  color: #3b82f6;
}

.floating-expression.color-3 {
  color: #14b8a6;
}

.floating-expression.color-4 {
  color: #f59e0b;
}

.floating-expression.color-5 {
  color: #ec4899;
}

.floating-expression:hover {
  background: rgba(255, 255, 255, 1);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: scale(1.05);
  z-index: 2;
}
</style>
