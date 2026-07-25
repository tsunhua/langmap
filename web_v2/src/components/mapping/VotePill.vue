<script setup lang="ts">
import { ref } from 'vue'
import { ThumbsUp, ThumbsDown } from 'lucide-vue-next'
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
const error = ref('')

async function vote(direction: 'up' | 'down') {
  if (busy.value) return
  busy.value = true
  error.value = ''
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
    error.value = '投票失敗，已還原'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="vote">
    <button
      :class="['up', { on: currentVote === 1 }]"
      :aria-pressed="currentVote === 1"
      :disabled="busy"
      aria-label="讚"
      @click="vote('up')"
    ><ThumbsUp :size="14" aria-hidden="true" /></button>
    <span class="score">{{ localScore }}</span>
    <button
      :class="['down', { on: currentVote === -1 }]"
      :aria-pressed="currentVote === -1"
      :disabled="busy"
      aria-label="踩"
      @click="vote('down')"
    ><ThumbsDown :size="14" aria-hidden="true" /></button>
    <span v-if="error" class="vote-error" role="alert">{{ error }}</span>
  </div>
</template>

<style scoped>
.vote-error {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--down);
  margin-left: 4px;
}
</style>
