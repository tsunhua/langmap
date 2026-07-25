<script setup lang="ts">
import { ref } from 'vue'
import api from '@/api/client'

const props = defineProps<{
  targetId: string
  targetType: 'mapping' | 'handbook'
  score: number
  userVote?: 1 | -1 | null
}>()

const emit = defineEmits<{ 'update:score': [score: number] }>()

const currentVote = ref(props.userVote ?? null)
const localScore = ref(props.score)
const busy = ref(false)

async function vote(direction: 'up' | 'down') {
  if (busy.value) return
  busy.value = true
  const prevVote = currentVote.value
  const prevScore = localScore.value

  if (currentVote.value === (direction === 'up' ? 1 : -1)) {
    currentVote.value = null
    localScore.value -= direction === 'up' ? 1 : -1
  } else if (currentVote.value !== null) {
    currentVote.value = direction === 'up' ? 1 : -1
    localScore.value += direction === 'up' ? 2 : -2
  } else {
    currentVote.value = direction === 'up' ? 1 : -1
    localScore.value += direction === 'up' ? 1 : -1
  }

  try {
    const endpoint = props.targetType === 'mapping'
      ? `/mappings/${props.targetId}/vote`
      : `/handbooks/${props.targetId}/vote`
    const { data } = await api.post(endpoint, { direction })
    localScore.value = data.data.score
    emit('update:score', data.data.score)
  } catch {
    currentVote.value = prevVote
    localScore.value = prevScore
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="vote">
    <button
      :class="['up', { on: currentVote === 1 }]"
      @click="vote('up')"
    >▲</button>
    <span class="score">{{ localScore }}</span>
    <button
      :class="['down', { on: currentVote === -1 }]"
      @click="vote('down')"
    >▼</button>
  </div>
</template>
