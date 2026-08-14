-- languages: use the common English name Hokkien for Min Nan at the language
-- level, matching the locale-level names (spec: 2026-08-14 language detail).

UPDATE languages SET name_en = 'Hokkien' WHERE code = 'nan';
