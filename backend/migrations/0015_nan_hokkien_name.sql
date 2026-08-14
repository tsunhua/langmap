-- nan: unify the English display name as Hokkien. The (Simplified)/(China)
-- qualifiers mislabeled the variety; Hokkien is the common English name for
-- the Min Nan spoken in Fujian (both script variants).

UPDATE language_locales SET name_en = 'Min Nan Chinese (Hokkien)' WHERE code IN ('nan-Hans-CN', 'nan-Hant-CN');
