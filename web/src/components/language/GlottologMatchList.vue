<script setup lang="ts">
import { ref, watch, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { Search } from 'lucide-vue-next'
import type { LanguoidCandidate } from '@/api/languages'

const { t } = useI18n()

const props = defineProps<{
  candidates: LanguoidCandidate[]
  selectedGlottocode: string | null
  hasSelection: boolean
  loading: boolean
  initialQuery?: string
}>()

const emit = defineEmits<{
  select: [glottocode: string | null]
  search: [query: string]
}>()

const query = ref(props.initialQuery || '')
let debounceTimer: ReturnType<typeof setTimeout> | null = null

watch(
  () => props.initialQuery,
  (val) => {
    if (val) {
      query.value = val
      emit('search', val)
    }
  },
  { immediate: true },
)

function onInput() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    if (query.value.trim()) emit('search', query.value.trim())
  }, 300)
}

onUnmounted(() => {
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div class="glottolog-match">
    <p id="glottolog-choice-label" class="match-hint">
      {{ t('languageCreate.glottologChoose') }} *
    </p>

    <div class="match-search">
      <Search :size="14" aria-hidden="true" />
      <input
        v-model="query"
        type="search"
        :placeholder="t('languageCreate.glottologSearchPlaceholder')"
        :aria-label="t('languageCreate.glottologSearchPlaceholder')"
        class="match-search-input"
        @input="onInput"
      />
    </div>

    <div
      class="match-options"
      role="radiogroup"
      aria-labelledby="glottolog-choice-label"
      aria-required="true"
    >
      <div v-if="loading" class="match-loading">
        {{ t('common.loading') }}
      </div>

      <div v-else-if="candidates.length" class="match-list">
        <p class="match-count">{{ t('languageCreate.glottologCandidates', { count: candidates.length }) }}</p>
        <label
          v-for="c in candidates"
          :key="c.id"
          class="match-item"
          :class="{ selected: selectedGlottocode === c.glottocode }"
        >
          <input
            type="radio"
            name="glottolog-match"
            :value="c.glottocode"
            :checked="selectedGlottocode === c.glottocode"
            class="match-radio"
            required
            @change="emit('select', c.glottocode)"
          />
          <div class="match-info">
            <span class="match-name">{{ c.preferred_name }}</span>
            <span class="match-meta">
              <span class="match-level">{{ t(`languageCreate.glottologLevel${c.level === 'language' ? 'Language' : 'Dialect'}`) }}</span>
              <span class="match-code">{{ c.glottocode }}</span>
              <span v-if="c.iso639_3" class="match-iso">ISO 639-3: {{ c.iso639_3 }}</span>
            </span>
            <span v-if="c.parent_name" class="match-parent">{{ c.parent_name }}</span>
          </div>
        </label>
      </div>

      <label
        class="match-item no-match"
        :class="{ selected: hasSelection && selectedGlottocode === null }"
      >
        <input
          type="radio"
          name="glottolog-match"
          value="no-match"
          :checked="hasSelection && selectedGlottocode === null"
          class="match-radio"
          data-choice="no-match"
          required
          @change="emit('select', null)"
        />
        <span class="match-info">
          <span class="match-name">{{ t('languageCreate.glottologNoMatch') }}</span>
        </span>
      </label>
    </div>
  </div>
</template>

<style scoped>
.glottolog-match {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.match-hint {
  font-size: 13px;
  color: var(--muted);
}
.match-search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  min-height: 44px;
  color: var(--muted);
}
.match-search-input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: var(--fg);
  min-height: 44px;
}
.match-search:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.match-loading {
  font-size: 13px;
  color: var(--muted);
  padding: 12px 0;
}
.match-options {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.match-count {
  font-size: 12px;
  color: var(--muted);
}
.match-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.match-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  cursor: pointer;
  min-height: 44px;
  transition: border-color 0.15s;
}
.match-item:hover {
  border-color: var(--accent);
}
.match-item.selected {
  border-color: var(--accent);
  background: var(--accent-soft);
}
.match-radio {
  margin-top: 2px;
  accent-color: var(--accent);
}
.match-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.match-name {
  font-weight: 500;
  font-size: 14px;
}
.match-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  font-size: 11px;
  color: var(--muted);
}
.match-level {
  text-transform: capitalize;
}
.match-code {
  font-family: var(--mono);
}
.match-iso {
  font-family: var(--mono);
}
.match-parent {
  font-size: 11px;
  color: var(--faint);
}
.no-match .match-name {
  color: var(--muted);
  font-style: italic;
}
</style>
