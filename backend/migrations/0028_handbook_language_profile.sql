ALTER TABLE handbooks ADD COLUMN language_profile_code TEXT REFERENCES language_locales(code);

UPDATE handbooks
SET language_profile_code = CASE id
  WHEN 'v1-handbook:1539253276' THEN 'nan-Hant-CN_LufengJiazi'
  WHEN 'v1-handbook:1847796151' THEN 'nan-Hant-CN_LufengJiazi'
  WHEN 'v1-handbook:1871662428' THEN 'cmn-Hant-TW'
  WHEN 'v1-handbook:2093097998' THEN 'nan-Hant-CN_LufengJiazi'
END
WHERE id IN (
  'v1-handbook:1539253276',
  'v1-handbook:1847796151',
  'v1-handbook:1871662428',
  'v1-handbook:2093097998'
);
