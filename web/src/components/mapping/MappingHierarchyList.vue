<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronRight, ChevronDown } from 'lucide-vue-next'
import type { DisplayTree, MappingGraphResponse } from './mappingGraphTypes'

const props = defineProps<{
  tree: DisplayTree
  graph: MappingGraphResponse
  selectedNodeId: string | null
  collapsedIds: Set<string>
}>()
const { t } = useI18n()

const emit = defineEmits<{
  select: [id: string]
  toggleCollapse: [id: string]
}>()

const nodeChildren = computed(() => {
  const m = new Map<string | null, string[]>()
  for (const n of props.tree.nodes) {
    const parent = n.displayParentId
    if (!m.has(parent)) m.set(parent, [])
    m.get(parent)!.push(n.id)
  }
  return m
})

const childCountMap = computed(() => {
  const m = new Map<string, number>()
  for (const n of props.tree.nodes) {
    if (n.displayParentId !== null) {
      m.set(n.displayParentId, (m.get(n.displayParentId) ?? 0) + 1)
    }
  }
  return m
})

const hasChildren = (id: string) => (childCountMap.value.get(id) ?? 0) > 0

const nodeText = (id: string) => {
  if (id === props.graph.root_id) return ''
  return props.graph.nodes.find(n => n.expression_id === id)?.text ?? `#${id}`
}

const nodeLang = (id: string) => {
  if (id === props.graph.root_id) return ''
  const node = props.graph.nodes.find(n => n.expression_id === id)
  return node?.language_profile_code || node?.lang_code || ''
}

function flattenTree(): Array<{ id: string; depth: number; parent: string | null }> {
  const out: Array<{ id: string; depth: number; parent: string | null }> = []
  const queue: Array<{ id: string; depth: number; parent: string | null }> = [{ id: props.graph.root_id, depth: 0, parent: null }]
  while (queue.length > 0) {
    const item = queue.shift()!
    out.push(item)
    if (props.collapsedIds.has(item.id)) continue
    const children = nodeChildren.value.get(item.id)
    if (!children) continue
    for (const child of children) {
      const depth = (props.graph.nodes.find(n => n.expression_id === child)?.depth ?? 0)
      queue.push({ id: child, depth, parent: item.id })
    }
  }
  return out
}

const listRef = ref<HTMLElement>()

const flatList = computed(() => flattenTree())
</script>

<template>
  <div ref="listRef" class="hierarchy-list" role="tree" :aria-label="t('components.hierarchyList')">
    <div
      v-for="item in flatList"
      :key="item.id"
      class="hl-row"
      :class="{
        selected: item.id === selectedNodeId,
        root: item.id === graph.root_id,
      }"
      :style="{ paddingLeft: item.depth * 20 + 8 + 'px' }"
      :data-node-id="item.id"
      role="treeitem"
      :aria-selected="item.id === selectedNodeId"
      :aria-expanded="hasChildren(item.id) ? !collapsedIds.has(item.id) : undefined"
      tabindex="0"
      @click="emit('select', item.id)"
      @keydown.enter="emit('select', item.id)"
      @keydown.space.prevent="emit('select', item.id)"
    >
      <button
        v-if="hasChildren(item.id)"
        class="hl-toggle"
        :aria-label="collapsedIds.has(item.id) ? t('components.expand') : t('components.collapse')"
        @click.stop="emit('toggleCollapse', item.id)"
      >
        <ChevronRight
          v-if="collapsedIds.has(item.id)"
          :size="12"
          aria-hidden="true"
        />
        <ChevronDown
          v-else
          :size="12"
          aria-hidden="true"
        />
      </button>
      <span v-else class="hl-spacer" />

      <span v-if="item.id === graph.root_id" class="hl-text hl-root-text">
        {{ graph.nodes.find(n => n.expression_id === graph.root_id)?.text ?? t('components.rootNode') }}
      </span>
      <template v-else>
        <span class="hl-text">{{ nodeText(item.id) }}</span>
        <span class="hl-lang">{{ nodeLang(item.id) }}</span>
      </template>
    </div>
  </div>
</template>

<style scoped>
.hierarchy-list {
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  max-height: 480px;
  overflow-y: auto;
}
.hl-row {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  font-size: 13px;
  cursor: pointer;
  border-bottom: 1px solid var(--border);
  min-height: 32px;
  transition: background 0.1s;
}
.hl-row:last-child { border-bottom: none; }
.hl-row:hover { background: color-mix(in oklch, var(--accent) 6%, transparent); }
.hl-row:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.hl-row.selected {
  background: color-mix(in oklch, var(--accent) 12%, transparent);
  border-left: 3px solid var(--accent);
  padding-left: calc(var(--depth) * 20px + 5px);
}
.hl-row.root { cursor: default; font-weight: 600; }
.hl-toggle {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border: none;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  border-radius: 3px;
  padding: 0;
}
.hl-toggle:hover { color: var(--fg); }
.hl-toggle:focus-visible { outline: 2px solid var(--accent); }
.hl-spacer { flex-shrink: 0; width: 18px; }
.hl-text {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.hl-root-text { font-size: 14px; }
.hl-lang {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  flex-shrink: 0;
}
</style>
