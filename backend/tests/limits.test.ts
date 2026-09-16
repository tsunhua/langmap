import { describe, expect, it } from 'vitest';
import {
  APPROVED_PIVOT_LANGUAGES,
  D1_WRITE_CHUNK_SIZE,
  GENERATE_STAGE_DEADLINE_MS,
  GENERATION_TIMEOUT_MS,
  MAX_ALTERNATIVES,
  MAX_CONTRIBUTION_EXPRESSIONS,
  MAX_DIRECT_PATHS_PER_ROOT,
  MAX_EVIDENCE_SERIALIZED_BYTES,
  MAX_EVIDENCE_TOTAL,
  MAX_HANDBOOK_ITEMS,
  MAX_HANDBOOK_SECTIONS,
  MAX_LOCALIZATION_MAPPINGS,
  MAX_PLANNER_SPANS,
  MAX_PREFIX_CANDIDATES_PER_ROOT,
  MAX_SPLIT_EDGE_IDS,
  MAX_TRANSLATION_BODY_BYTES,
  MAX_TRANSLATION_GRAPHEMES,
  MAX_TRANSLATION_OUTPUT_TOKENS,
  MAX_TRANSLATION_TEXT_BYTES,
  PLANNER_MAX_COMPLETION_TOKENS,
  PLANNER_TIMEOUT_MS,
  RETRIEVAL_TIMEOUT_MS,
  exceedsLimit,
} from '../src/utils/limits';

describe('performance workload limits', () => {
  it('keeps mutation and write chunk limits explicit', () => {
    expect({
      contributions: MAX_CONTRIBUTION_EXPRESSIONS,
      localization: MAX_LOCALIZATION_MAPPINGS,
      sections: MAX_HANDBOOK_SECTIONS,
      items: MAX_HANDBOOK_ITEMS,
      edges: MAX_SPLIT_EDGE_IDS,
      chunk: D1_WRITE_CHUNK_SIZE,
    }).toEqual({ contributions: 50, localization: 100, sections: 50, items: 500, edges: 100, chunk: 50 });
  });

  it('only rejects integer values over the configured maximum', () => {
    expect(exceedsLimit(50, 50)).toBe(false);
    expect(exceedsLimit(51, 50)).toBe(true);
    expect(exceedsLimit(Number.NaN, 50)).toBe(true);
  });
});

describe('translation pipeline limits', () => {
  it('keeps translation workload thresholds explicit', () => {
    expect({
      graphemes: MAX_TRANSLATION_GRAPHEMES,
      textBytes: MAX_TRANSLATION_TEXT_BYTES,
      bodyBytes: MAX_TRANSLATION_BODY_BYTES,
      plannerSpans: MAX_PLANNER_SPANS,
      plannerCompletionTokens: PLANNER_MAX_COMPLETION_TOKENS,
      prefixCandidatesPerRoot: MAX_PREFIX_CANDIDATES_PER_ROOT,
      directPathsPerRoot: MAX_DIRECT_PATHS_PER_ROOT,
      evidenceTotal: MAX_EVIDENCE_TOTAL,
      alternatives: MAX_ALTERNATIVES,
      evidenceSerializedBytes: MAX_EVIDENCE_SERIALIZED_BYTES,
      outputTokens: MAX_TRANSLATION_OUTPUT_TOKENS,
    }).toEqual({
      graphemes: 500,
      textBytes: 8192,
      bodyBytes: 16384,
      plannerSpans: 8,
      plannerCompletionTokens: 2048,
      prefixCandidatesPerRoot: 3,
      directPathsPerRoot: 3,
      evidenceTotal: 24,
      alternatives: 2,
      evidenceSerializedBytes: 32768,
      outputTokens: 2048,
    });
  });

  it('keeps translation stage timeouts explicit', () => {
    expect({
      planner: PLANNER_TIMEOUT_MS,
      retrieval: RETRIEVAL_TIMEOUT_MS,
      generation: GENERATION_TIMEOUT_MS,
      generateStageDeadline: GENERATE_STAGE_DEADLINE_MS,
    }).toEqual({ planner: 20000, retrieval: 2000, generation: 30000, generateStageDeadline: 6000 });
  });

  it('keeps the approved pivot language allowlist explicit', () => {
    expect(APPROVED_PIVOT_LANGUAGES).toEqual(['eng', 'cmn', 'jpn', 'spa', 'fra', 'deu', 'por', 'kor', 'rus', 'arb']);
  });
});
