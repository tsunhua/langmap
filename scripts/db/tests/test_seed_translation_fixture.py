from __future__ import annotations

import sqlite3
import unittest

from scripts.db.seed_translation_fixture import (
    DEFAULT_EMAIL,
    DEFAULT_PASSWORD,
    FIXTURE_PAIRS,
    PASSWORD_SALT,
    SOURCE_NAME,
    TARGET_LOCALE,
    build_sql,
    password_hash,
)


def _fixture_database() -> sqlite3.Connection:
    db = sqlite3.connect(":memory:")
    db.executescript(
        """
        PRAGMA foreign_keys = ON;
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'user',
          email_verified INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE languages (id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE);
        CREATE TABLE language_locales (
          id INTEGER PRIMARY KEY,
          code TEXT NOT NULL UNIQUE,
          language_id INTEGER NOT NULL,
          name TEXT NOT NULL
        );
        CREATE TABLE sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          UNIQUE(type, name)
        );
        CREATE TABLE expressions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          language_id INTEGER NOT NULL,
          text TEXT NOT NULL,
          homograph_index INTEGER NOT NULL DEFAULT 1,
          pos_mask INTEGER NOT NULL DEFAULT 0,
          source_id INTEGER,
          created_by INTEGER,
          UNIQUE(language_id, text, homograph_index)
        );
        CREATE TABLE expression_locale_links (
          expression_id INTEGER NOT NULL,
          locale_id INTEGER NOT NULL,
          PRIMARY KEY(expression_id, locale_id)
        ) WITHOUT ROWID;
        CREATE TABLE expression_edges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expression_a_id INTEGER NOT NULL,
          expression_b_id INTEGER NOT NULL,
          relation_mask INTEGER NOT NULL DEFAULT 1,
          score INTEGER NOT NULL DEFAULT 0,
          annotations_json TEXT NOT NULL DEFAULT '[]',
          created_by INTEGER,
          CHECK(expression_a_id < expression_b_id),
          UNIQUE(expression_a_id, expression_b_id)
        );
        CREATE TABLE expression_sources (
          expression_id INTEGER NOT NULL,
          source_id INTEGER NOT NULL,
          source_marker TEXT NOT NULL DEFAULT '',
          PRIMARY KEY(expression_id, source_id, source_marker)
        ) WITHOUT ROWID;
        CREATE TABLE expression_edge_sources (
          edge_id INTEGER NOT NULL,
          source_id INTEGER NOT NULL,
          source_marker TEXT NOT NULL DEFAULT '',
          PRIMARY KEY(edge_id, source_id, source_marker)
        ) WITHOUT ROWID;
        CREATE TABLE language_statistics (
          language_id INTEGER PRIMARY KEY,
          expression_count INTEGER NOT NULL,
          locale_count INTEGER NOT NULL,
          active_ui_locale_count INTEGER NOT NULL,
          updated_at TEXT NOT NULL
        );
        CREATE TABLE ui_locales (
          project_id TEXT NOT NULL,
          locale_id INTEGER NOT NULL,
          status TEXT NOT NULL,
          PRIMARY KEY(project_id, locale_id)
        ) WITHOUT ROWID;
        INSERT INTO languages(id, code) VALUES (1, 'cmn'), (2, 'nan');
        INSERT INTO language_locales(id, code, language_id, name) VALUES
          (1, 'cmn-Hans-CN', 1, '普通话'),
          (2, 'nan-Hant-TW', 2, '台語');
        """
    )
    return db


class SeedTranslationFixtureTests(unittest.TestCase):
    def test_fixture_has_twenty_unique_pairs_and_expected_locale(self) -> None:
        self.assertEqual(len(FIXTURE_PAIRS), 20)
        self.assertEqual(len({pair.source_text for pair in FIXTURE_PAIRS}), 20)
        self.assertEqual(len({pair.target_text for pair in FIXTURE_PAIRS}), 20)
        self.assertIn(TARGET_LOCALE, build_sql())

    def test_password_hash_is_deterministic_and_matches_worker_format(self) -> None:
        first = password_hash(DEFAULT_PASSWORD)
        self.assertEqual(first, password_hash(DEFAULT_PASSWORD))
        salt, digest = first.split(":")
        self.assertEqual(salt, PASSWORD_SALT)
        self.assertEqual(len(digest), 64)

    def test_generated_sql_is_idempotent_and_populates_provenance(self) -> None:
        db = _fixture_database()
        sql = build_sql()
        db.executescript(sql)
        db.executescript(sql)

        self.assertEqual(db.execute("SELECT COUNT(*) FROM users WHERE email=?", (DEFAULT_EMAIL,)).fetchone()[0], 1)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM sources WHERE name=?", (SOURCE_NAME,)).fetchone()[0], 1)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM expression_sources").fetchone()[0], 40)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM expression_locale_links").fetchone()[0], 40)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM expression_edges").fetchone()[0], 20)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM expression_edge_sources").fetchone()[0], 20)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM language_statistics").fetchone()[0], 2)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM expressions").fetchone()[0], 40)
        translated = db.execute(
            """
            SELECT target.text
            FROM expressions source
            JOIN languages source_language ON source_language.id=source.language_id
            JOIN expression_edges edge
              ON edge.expression_a_id=source.id OR edge.expression_b_id=source.id
            JOIN expressions target
              ON target.id=CASE
                WHEN edge.expression_a_id=source.id THEN edge.expression_b_id
                ELSE edge.expression_a_id
              END
            JOIN languages target_language ON target_language.id=target.language_id
            JOIN expression_locale_links locale_link ON locale_link.expression_id=target.id
            JOIN language_locales locale ON locale.id=locale_link.locale_id
            WHERE source_language.code='cmn'
              AND source.text='谢谢你。'
              AND target_language.code='nan'
              AND locale.code='nan-Hant-TW'
            """
        ).fetchone()
        self.assertEqual(translated[0], "多謝你。")
        db.close()


if __name__ == "__main__":
    unittest.main()
