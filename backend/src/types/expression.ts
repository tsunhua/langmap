export interface ExpressionRow {
  id: number;
  language_id: number;
  lang_code: string;
  text: string;
  homograph_index: number;
  pos_mask: number;
  source_id: number | null;
  created_by: number | null;
  created_at: string;
}

export interface ExpressionLocaleRow {
  expression_id: number;
  locale_id: number;
  language_locale_code: string;
  locale_display_name?: string;
}

export interface ReadingRow {
  expression_id: number;
  locale_id: number;
  language_locale_code: string;
  scheme: string;
  value: string;
  source_id: number | null;
}

export interface ExpressionPartOfSpeech {
  code: string;
  name_en: string;
}
