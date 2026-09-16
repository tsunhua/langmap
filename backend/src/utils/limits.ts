export const MAX_CONTRIBUTION_EXPRESSIONS = 50;
export const MAX_LOCALIZATION_MAPPINGS = 100;
export const MAX_HANDBOOK_SECTIONS = 50;
export const MAX_HANDBOOK_ITEMS = 500;
export const MAX_SPLIT_EDGE_IDS = 100;
export const D1_WRITE_CHUNK_SIZE = 50;

export const MAX_TRANSLATION_GRAPHEMES = 500;
export const MAX_TRANSLATION_TEXT_BYTES = 8192;
export const MAX_TRANSLATION_BODY_BYTES = 16384;
export const MAX_PLANNER_SPANS = 8;
export const MAX_PREFIX_CANDIDATES_PER_ROOT = 3;
export const MAX_DIRECT_PATHS_PER_ROOT = 3;
export const MAX_EVIDENCE_TOTAL = 24;
export const MAX_ALTERNATIVES = 2;
export const MAX_EVIDENCE_SERIALIZED_BYTES = 32768;
export const MAX_TRANSLATION_OUTPUT_TOKENS = 2048;
export const PLANNER_TIMEOUT_MS = 20000;
export const RETRIEVAL_TIMEOUT_MS = 2000;
// Workers AI model latency can exceed the old 9s limit even when the request
// is healthy; keep the deadline bounded while leaving room for a normal remote
// inference response from the configured model.
export const GENERATION_TIMEOUT_MS = 30000;
export const GENERATE_STAGE_DEADLINE_MS = 6000;

export const APPROVED_PIVOT_LANGUAGES = [
  'eng',
  'cmn',
  'jpn',
  'spa',
  'fra',
  'deu',
  'por',
  'kor',
  'rus',
  'arb',
] as const;

export function exceedsLimit(value: number, maximum: number): boolean {
  return !Number.isInteger(value) || value > maximum;
}
