-- 0019: Rename Traditional script profile label from 繁體 to 傳承體.
-- The Hant profile name is shown on the language detail page next to 简体
-- (Simplified), so 傳承體 reads as its counterpart instead of 繁體/简体.
-- Rerunnable.
UPDATE language_profiles SET name = '傳承體' WHERE script_code = 'Hant' AND name = '繁體';
