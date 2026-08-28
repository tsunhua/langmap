CREATE TABLE language_statistics (
  language_id INTEGER PRIMARY KEY,
  expression_count INTEGER NOT NULL DEFAULT 0,
  locale_count INTEGER NOT NULL DEFAULT 0,
  active_ui_locale_count INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
);

INSERT INTO language_statistics (language_id, expression_count, locale_count, active_ui_locale_count)
SELECT l.id,
       (SELECT COUNT(*) FROM expressions e WHERE e.language_id = l.id),
       (SELECT COUNT(*) FROM language_locales ll WHERE ll.language_id = l.id),
       (SELECT COUNT(*) FROM ui_locales u JOIN language_locales ll ON ll.id = u.locale_id
        WHERE ll.language_id = l.id AND u.status = 'active')
FROM languages l;
