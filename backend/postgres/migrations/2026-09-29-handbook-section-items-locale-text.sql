-- Handbook items reference a word by locale and text instead of expression_id.
--
-- Expression ids are reassigned on every dictionary release, so a handbook that
-- stored them would point at unrelated words after a rebuild.  (locale, text) is
-- the stable key: language_locale rows come from the deterministic registry seed
-- and the text is the authored content itself.  Reads resolve the pair back to
-- an expression, and an item whose word has since disappeared keeps rendering
-- its text with a null id.
--
-- The migration is re-runnable: when the table was already initialised from a
-- schema.sql that contains the new shape, it is a no-op.

DO $$
DECLARE
  has_legacy boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'handbook_section_items'
      AND column_name = 'expression_id'
  ) INTO has_legacy;

  IF NOT has_legacy THEN
    RAISE NOTICE 'handbook_section_items already uses (language_locale_id, text); skipping';
    RETURN;
  END IF;

  EXECUTE 'ALTER TABLE handbook_section_items ADD COLUMN language_locale_id BIGINT';
  EXECUTE 'ALTER TABLE handbook_section_items ADD COLUMN text TEXT';

  -- Prefer the expression's own locale link; fall back to the handbook's locale
  -- and finally to any locale of the expression's language, so items whose
  -- expression never carried a link still get a stable anchor.
  UPDATE handbook_section_items items
  SET language_locale_id = COALESCE(
        (
          SELECT link.locale_id
          FROM expression_locale_links link
          WHERE link.expression_id = items.expression_id
          ORDER BY link.locale_id
          LIMIT 1
        ),
        (
          SELECT handbook.language_locale_id
          FROM handbook_sections sections
          JOIN handbooks handbook ON handbook.id = sections.handbook_id
          WHERE sections.id = items.section_id
        ),
        (
          SELECT locale.id
          FROM expressions expression
          JOIN language_locales locale ON locale.language_id = expression.language_id
          WHERE expression.id = items.expression_id
          ORDER BY locale.id
          LIMIT 1
        )
      ),
      text = (
        SELECT expression.text FROM expressions expression WHERE expression.id = items.expression_id
      );

  -- Nothing may stay unanchored, otherwise the NOT NULL below would fail.
  DELETE FROM handbook_section_items WHERE language_locale_id IS NULL OR text IS NULL;

  -- Collapse duplicates the new UNIQUE key would otherwise reject, keeping the
  -- earliest position so handbook ordering is preserved.
  DELETE FROM handbook_section_items items
  USING handbook_section_items earlier
  WHERE items.section_id = earlier.section_id
    AND items.language_locale_id = earlier.language_locale_id
    AND items.text = earlier.text
    AND items.position > earlier.position;

  EXECUTE 'ALTER TABLE handbook_section_items ALTER COLUMN language_locale_id SET NOT NULL';
  EXECUTE 'ALTER TABLE handbook_section_items ALTER COLUMN text SET NOT NULL';
  EXECUTE 'ALTER TABLE handbook_section_items'
      || ' ADD CONSTRAINT handbook_section_items_language_locale_id_fkey'
      || ' FOREIGN KEY (language_locale_id) REFERENCES language_locales(id) ON DELETE RESTRICT';

  EXECUTE 'ALTER TABLE handbook_section_items'
      || ' DROP CONSTRAINT IF EXISTS handbook_section_items_section_id_expression_id_key';
  EXECUTE 'ALTER TABLE handbook_section_items'
      || ' DROP CONSTRAINT IF EXISTS handbook_section_items_expression_id_fkey';
  EXECUTE 'ALTER TABLE handbook_section_items DROP COLUMN IF EXISTS expression_id';

  EXECUTE 'ALTER TABLE handbook_section_items'
      || ' ADD CONSTRAINT handbook_section_items_section_id_language_locale_id_text_key'
      || ' UNIQUE (section_id, language_locale_id, text)';
  EXECUTE 'CREATE INDEX IF NOT EXISTS idx_handbook_section_items_locale_text'
      || ' ON handbook_section_items(language_locale_id, text)';
END $$;