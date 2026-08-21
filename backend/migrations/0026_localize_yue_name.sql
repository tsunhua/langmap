-- Use the Traditional Chinese language name for the canonical Yue locale.
UPDATE language_locales
SET name = '粵語'
WHERE code = 'yue-Hant-HK';
