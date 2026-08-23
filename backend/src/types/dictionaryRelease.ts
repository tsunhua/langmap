export interface PartOfSpeechDto {
  code: string;
  name_en: string;
}

export interface DictionaryReleaseRow {
  id: string;
  dataset_key: string;
  parent_release_id: string | null;
  input_manifest_hash: string;
  exporter_schema_version: number;
  adapter_bundle_hash: string;
  reconciliation_config_hash: string;
  artifact_hash: string;
  status: 'planned' | 'applying' | 'validated' | 'failed';
  created_at: string;
  activated_at: string | null;
}
