-- 0017: Fix Hans script label from traditional "簡體" to simplified "简体".
-- The profile name for Simplified Chinese scripts should be written in simplified characters.
-- Rerunnable.
UPDATE language_profiles SET name = '简体' WHERE script_code = 'Hans' AND name = '簡體';
