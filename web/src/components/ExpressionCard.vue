<template>
  <router-link :to="{ name: 'detail', params: { id: item.id } }" class="block no-underline text-inherit">
    <div class="border rounded-md p-3 hover:shadow-sm">
      <div class="flex justify-between items-center">
        <div>
          <strong class="block text-lg">{{ item.text }}</strong>
          <div class="text-sm text-gray-600">{{ item.language }} · {{ item.region || '—' }}</div>
        </div>
        <div class="text-right">
          <span class="bg-gray-100 px-3 py-1 rounded-full text-sm">{{ item.source_type }}</span>
        </div>
      </div>
      <div class="mt-3 flex items-center gap-3">
        <button v-if="item.audio_url" @click.stop.prevent="playAudio" class="px-3 py-1 bg-gray-50 rounded">Play</button>
        <div class="text-sm text-gray-500">Status: {{ item.review_status }} <span v-if="item.auto_approved">(auto)</span></div>
      </div>
    </div>
  </router-link>
</template>

<script>
export default {
  props: { item: { type: Object, required: true } },
  methods: {
    playAudio () {
      const audio = new Audio(this.item.audio_url)
      audio.play()
    }
  }
}
</script>
