export interface MorphologicalFeatureDto {
  code: string;
  name: string;
  name_en: string;
  sort_order: number;
}

export interface MorphologicalDimensionDto {
  code: string;
  name: string;
  name_en: string;
  sort_order: number;
  features: MorphologicalFeatureDto[];
}

export interface MorphologicalFeaturesResponse {
  dimensions: MorphologicalDimensionDto[];
}

export interface FormEdgeExpressionSummary {
  id: string;
  text: string;
  lang_code: string;
  language_name: string;
}

export interface FormEdgeFeatureDto {
  code: string;
  name: string;
  dimension_code: string;
}

export interface FormEdgeAsFormDto {
  edge_id: string;
  lemma: FormEdgeExpressionSummary;
  features: FormEdgeFeatureDto[];
}

export interface FormEdgeAsLemmaDto {
  edge_id: string;
  form: FormEdgeExpressionSummary;
  features: FormEdgeFeatureDto[];
}

export interface CreateFormEdgeResult extends FormEdgeAsFormDto {
  created: boolean;
}

export interface ExpressionFormEdgesDto {
  as_form: FormEdgeAsFormDto[];
  as_lemma: FormEdgeAsLemmaDto[];
  as_form_truncated: boolean;
  as_form_omitted_count: number;
  as_lemma_truncated: boolean;
  as_lemma_omitted_count: number;
}

export interface SearchFormOfDto {
  lemma: { id: string; text: string; lang_code: string };
  features: Array<{ code: string; name: string }>;
}
