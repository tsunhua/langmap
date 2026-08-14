-- Locale display names become bare names (no script/region suffix). The
-- script/region structure is conveyed by the detail-page linked-select instead
-- of being baked into the name string (spec: language-detail-variety-selector §5.6).

UPDATE language_locales SET name = 'English' WHERE code = 'eng-Latn-US';
UPDATE language_locales SET name = '華語' WHERE code = 'cmn-Hant-TW';
UPDATE language_locales SET name = '普通话' WHERE code = 'cmn-Hans-CN';
UPDATE language_locales SET name = '閩南語' WHERE code = 'nan-Hant-CN';
UPDATE language_locales SET name = '閩南語' WHERE code = 'nan-Hant-TW';
UPDATE language_locales SET name = 'Español' WHERE code = 'spa-Latn-ES';
UPDATE language_locales SET name = '日本語' WHERE code = 'jpn-Jpan-JP';
