import { ref } from 'vue'

export const contentRevision = ref(0)

export function markContentChanged() {
  contentRevision.value += 1
}
