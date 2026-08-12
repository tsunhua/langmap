<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'

type SemanticLevel = 'compact' | 'medium' | 'full'

const props = defineProps<{
  nodeId: string
  text: string
  languageCode: string
  languageName: string | null
  depth: number
  x: number
  y: number
  displayParentId: string | null
  childCount: number
  score: number | null
  isRoot: boolean
  isSelected: boolean
  semanticLevel: SemanticLevel
  worldScale: number
}>()
const { t } = useI18n()

const emit = defineEmits<{
  select: [id: string]
  navigate: [id: string]
  dragMove: [nodeId: string, worldX: number, worldY: number]
  dragEnd: [nodeId: string, worldX: number, worldY: number]
  toggleCollapse: [id: string]
}>()

const DRAG_THRESHOLD = 4
const dragging = ref(false)

let nodeEl: HTMLElement | null = null
let dragStartScreenX = 0
let dragStartScreenY = 0
let dragStartWorldX = 0
let dragStartWorldY = 0
let dragDidMove = false
let pointerId = -1

const accessibleName = computed(() => {
  const parts = [props.text, props.languageCode]
  if (props.languageName) parts.push(props.languageName)
  parts.push(t('components.depth', { depth: props.depth }))
  if (props.score !== null) parts.push(`${t('components.mappingScore')}: ${props.score}`)
  return parts.join(' · ')
})

const displayText = computed(() => {
  if (props.semanticLevel === 'full') return props.text
  const max = props.semanticLevel === 'compact' ? 6 : 18
  return props.text.length > max ? props.text.slice(0, max) + '…' : props.text
})

function onPointerDown(e: PointerEvent) {
  if (e.button !== 0 || props.isRoot) return
  nodeEl = e.currentTarget as HTMLElement
  nodeEl.setPointerCapture(e.pointerId)
  pointerId = e.pointerId
  nodeEl.addEventListener('pointermove', onPointerMove)
  nodeEl.addEventListener('pointerup', onPointerUp)
  nodeEl.addEventListener('pointercancel', onPointerCancel)
  dragStartScreenX = e.clientX
  dragStartScreenY = e.clientY
  dragStartWorldX = props.x
  dragStartWorldY = props.y
  dragDidMove = false
  dragging.value = true
}

function onPointerMove(e: PointerEvent) {
  if (e.pointerId !== pointerId) return
  const k = props.worldScale
  const dx = (e.clientX - dragStartScreenX) / k
  const dy = (e.clientY - dragStartScreenY) / k
  if (Math.abs(e.clientX - dragStartScreenX) > DRAG_THRESHOLD || Math.abs(e.clientY - dragStartScreenY) > DRAG_THRESHOLD) {
    dragDidMove = true
  }
  const worldX = dragStartWorldX + dx
  const worldY = dragStartWorldY + dy
  const el = e.currentTarget as HTMLElement
  el.style.transform = `translate3d(${worldX}px, ${worldY}px, 0) translate(-50%, -50%)`
  emit('dragMove', props.nodeId, worldX, worldY)
}

function onPointerUp(e: PointerEvent) {
  if (e.pointerId !== pointerId) return
  cleanup()
  if (dragDidMove) {
    const k = props.worldScale
    const dx = (e.clientX - dragStartScreenX) / k
    const dy = (e.clientY - dragStartScreenY) / k
    const worldX = dragStartWorldX + dx
    const worldY = dragStartWorldY + dy
    emit('dragEnd', props.nodeId, worldX, worldY)
  }
  dragging.value = false
}

function onPointerCancel() {
  cleanup()
  dragging.value = false
}

function cleanup() {
  if (nodeEl) {
    nodeEl.removeEventListener('pointermove', onPointerMove)
    nodeEl.removeEventListener('pointerup', onPointerUp)
    nodeEl.removeEventListener('pointercancel', onPointerCancel)
    nodeEl = null
  }
}

function onClick() {
  if (dragDidMove) return
  emit('select', props.nodeId)
}
function onToggleCollapse(e: MouseEvent) {
  e.stopPropagation()
  emit('toggleCollapse', props.nodeId)
}
function onToggleCollapseKey(e: KeyboardEvent) {
  e.stopPropagation()
  emit('toggleCollapse', props.nodeId)
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
      dragging,
      [`depth-${depth}`]: true,
      [`level-${semanticLevel}`]: true,
    }"
    :data-node-id="nodeId"
    :data-depth="depth"
    tabindex="0"
    role="button"
    :aria-label="accessibleName"
    :style="{ transform: `translate3d(${x}px, ${y}px, 0) translate(-50%, -50%)` }"
    @pointerdown="onPointerDown"
    @click.stop="onClick"
    @dblclick.stop="onDblclick"
    @keydown="onKeydown"
  >
    <span class="gn-text">{{ displayText }}</span>
    <span v-if="semanticLevel !== 'compact'" class="gn-meta">
      <span class="gn-lang">{{ languageCode }}</span>
      <span
        v-if="semanticLevel === 'full' && childCount > 0"
        class="gn-children"
        role="button"
        tabindex="0"
        :aria-label="t('components.childNodes', { count: childCount })"
        @click.stop="onToggleCollapse"
        @keydown.enter.stop="onToggleCollapseKey"
        @keydown.space.prevent.stop="onToggleCollapseKey"
      >+{{ childCount }}</span>
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
  touch-action: none;
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
.graph-node.dragging {
  transition: none;
  z-index: 20;
  box-shadow: 0 6px 20px oklch(0 0 0 / 0.12);
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
  min-width: 56px;
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
