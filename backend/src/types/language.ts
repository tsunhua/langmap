export type SourceType = 'publication' | 'url' | 'system';

export interface SourceInput {
  type: SourceType;
  name: string;
  ref?: string;
}

export interface LanguageLocaleParts {
  lang_code: string;
  script_code: string;
  region_code: string;
  place_segments: string[];
}

export interface LanguageLocaleRow {
  code: string;
  lang_code: string;
  script_code: string;
  region_code: string;
  place_path: string;
  name: string;
  name_en: string;
  latitude: number | null;
  longitude: number | null;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
}
