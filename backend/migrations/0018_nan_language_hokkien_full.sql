-- languages: use the full display name at the language level, consistent with
-- the locale-level names (Min Nan Chinese (Hokkien)).

UPDATE languages SET name_en = 'Min Nan Chinese (Hokkien)' WHERE code = 'nan';
