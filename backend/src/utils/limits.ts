export const MAX_CONTRIBUTION_EXPRESSIONS = 50;
export const MAX_LOCALIZATION_MAPPINGS = 100;
export const MAX_HANDBOOK_SECTIONS = 50;
export const MAX_HANDBOOK_ITEMS = 500;
export const MAX_SPLIT_EDGE_IDS = 100;
export const D1_WRITE_CHUNK_SIZE = 50;

export function exceedsLimit(value: number, maximum: number): boolean {
  return !Number.isInteger(value) || value > maximum;
}
