-- 0018: Add language_profiles.endonym.
-- The language's own name written in the profile's script (e.g. cmn-Hans = "华语",
-- cmn-Hant = "華語"), used for the detail-page title when a script is selected.
-- Forward-only: applied once, tracked by the d1_migrations table.
ALTER TABLE language_profiles ADD COLUMN endonym TEXT NOT NULL DEFAULT '';
UPDATE language_profiles SET endonym = '华语' WHERE code = 'cmn-Hans' AND endonym = '';
UPDATE language_profiles SET endonym = '華語' WHERE code = 'cmn-Hant' AND endonym = '';
