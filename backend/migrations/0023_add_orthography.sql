-- Add orthography field to language_locales.
--
-- The original table recreation was not safe on databases that already have
-- foreign-key dependants (notably ui_locales). The application does not rely
-- on the expanded UNIQUE constraint, so keep this migration additive.
ALTER TABLE language_locales ADD COLUMN orthography TEXT;
