<script setup lang="ts">
import { computed } from 'vue'

type SemanticLevel = 'compact' | 'medium' | 'full'

const props = defineProps<{
  nodeId: number
  text: string
  languageCode: string
  languageName: string | null
  depth: number
  x: number
  y: number
  displayParentId: number | null
  childCount: number
  score: number | null
  isRoot: boolean
  isSelected: boolean
  semanticLevel: SemanticLevel
}>()

const emit = defineEmits<{ select: [id: number]; navigate: [id: number] }>()

const accessibleName = computed(() => {
  const parts = [props.text, props.languageCode]
  if (props.languageName) parts.push(props.languageName)
  parts.push(`深度 ${props.depth}`)
  if (props.score !== null) parts.push(`評分 ${props.score}`)
  return parts.join(' · ')
})

const displayText = computed(() => {
  if (props.semanticLevel === 'compact') {
    return props.languageCode
  }
  if (props.semanticLevel === 'medium') {
    const max = 18
    return props.text.length > max ? props.text.slice(0, max) + '…' : props.text
  }
  return props.text
})

function onClick() {
  emit('select', props.nodeId)
}
function onDblclick() {
  emit('navigate', props.nodeId)
}
function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault()
    emit('select', props.nodeId)
  }
}
</script>

<template>
  <div
    class="graph-node"
    :class="{
      anchor: isRoot,
      selected: isSelected,
      [`depth-${depth}`]: true,
      [`level-${semanticLevel}`]: true,
    }"
    :data-node-id="nodeId"
    :data-depth="depth"
    tabindex="0"
    role="button"
    :aria-label="accessibleName"
    :style="{ transform: `translate3d(${x}px, ${y}px, 0)` }"
    @click.stop="onClick"
    @dblclick.stop="onDblclick"
    @keydown="onKeydown"
  >
    <span class="gn-text">{{ displayText }}</span>
    <span v-if="semanticLevel !== 'compact'" class="gn-meta">
      <span class="gn-lang">{{ languageCode }}</span>
      <span v-if="semanticLevel === 'full' && childCount > 0" class="gn-children">+{{ childCount }}</span>
    </span>
  </div>
</template>

<style scoped>
.graph-node {
  position: absolute;
  top: 0;
  left: 0;
  transform-origin: 0 0;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 6px 10px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  text-align: center;
  min-width: 80px;
  max-width: 200px;
  box-shadow: 0 1px 2px oklch(0 0 0 / 0.04);
  transition: border-color 0.12s, box-shadow 0.12s;
  will-change: transform;
  user-select: none;
}
.graph-node:hover {
  border-color: var(--accent);
  box-shadow: 0 3px 8px oklch(0 0 0 / 0.08);
  z-index: 4;
}
.graph-node:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.gn-text {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.gn-meta {
  display: flex;
  gap: 6px;
  justify-content: center;
  margin-top: 2px;
}
.gn-lang {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  font-weight: 400;
}
.gn-children {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--accent);
}

.graph-node.anchor {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
  font-size: 15px;
  font-weight: 600;
  min-width: 100px;
  padding: 8px 14px;
  box-shadow: 0 0 0 5px color-mix(in oklch, var(--accent) 15%, transparent);
  cursor: default;
  z-index: 3;
}
.graph-node.anchor .gn-lang {
  color: oklch(0.92 0.04 35);
}

.graph-node.selected {
  border-color: var(--accent);
  border-width: 2px;
  box-shadow: 0 0 0 4px color-mix(in oklch, var(--accent) 18%, transparent);
  z-index: 5;
}

.graph-node.level-compact {
  padding: 3px 6px;
  min-width: 40px;
}
.graph-node.level-compact .gn-text {
  font-size: 10px;
  font-family: var(--mono);
}
.graph-node.level-medium {
  padding: 4px 8px;
  min-width: 60px;
}

@media (prefers-reduced-motion: reduce) {
  .graph-node {
    transition: none;
  }
}
</style>
