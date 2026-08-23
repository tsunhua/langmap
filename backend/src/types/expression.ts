export interface ExpressionRow {
  id: string;
  lang_code: string;
  text: string;
  text_hash: string;
  homograph_index: number;
  description: string;
  tags_json: string;
  source_id: string | null;
  source_ref: string | null;
  review_status: 'pending' | 'approved' | 'rejected';
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface LocaleAttestationRow {
  id: string;
  expression_id: string;
  language_locale_code: string;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
  created_by_username?: string | null;
}

export interface ReadingRow {
  id: string;
  expression_id: string;
  language_locale_code: string;
  scheme: string;
  value: string;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
}

export interface ExpressionPartOfSpeech {
  code: string;
  name_en: string;
}
