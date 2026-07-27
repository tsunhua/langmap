<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { LanguoidCandidate } from '@/api/languages'

const { t } = useI18n()

defineProps<{
  candidates: LanguoidCandidate[]
  selectedGlottocode: string | null
  loading: boolean
}>()

const emit = defineEmits<{
  select: [glottocode: string | null]
}>()
</script>

<template>
  <div class="glottolog-match">
    <p class="match-hint">{{ t('languageCreate.glottologChoose') }}</p>

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
      :class="{ selected: selectedGlottocode === null }"
    >
      <input
        type="radio"
        name="glottolog-match"
        value="no-match"
        :checked="selectedGlottocode === null && selectedGlottocode !== undefined"
        class="match-radio"
        data-choice="no-match"
        @change="emit('select', null)"
      />
      <span class="match-info">
        <span class="match-name">{{ t('languageCreate.glottologNoMatch') }}</span>
      </span>
    </label>
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
.match-loading {
  font-size: 13px;
  color: var(--muted);
  padding: 12px 0;
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
