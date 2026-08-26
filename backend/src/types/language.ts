export type SourceType = 'publication' | 'url' | 'system';

export interface LanguageLocaleParts {
  lang_code: string;
  script_code: string;
  orthography?: string;
  region_code: string;
  place_segments: string[];
}
