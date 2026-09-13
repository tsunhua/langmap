from __future__ import annotations

import io
import sqlite3
import unittest

from scripts.db.export_dictionary_source_diff import _write_delete_edge_batches


SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE languages (id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE);
CREATE TABLE sources (id INTEGER PRIMARY KEY, type TEXT NOT NULL, name TEXT NOT NULL, UNIQUE(type,name));
CREATE TABLE expressions (
    id INTEGER PRIMARY KEY,
    language_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    homograph_index INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE expression_edges (
    id INTEGER PRIMARY KEY,
    expression_a_id INTEGER NOT NULL,
    expression_b_id INTEGER NOT NULL,
    relation_mask INTEGER NOT NULL DEFAULT 1,
    score INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE expression_edge_sources (
    edge_id INTEGER NOT NULL REFERENCES expression_edges(id) ON DELETE CASCADE,
    source_id INTEGER NOT NULL REFERENCES sources(id),
    source_marker TEXT NOT NULL DEFAULT '',
    PRIMARY KEY(edge_id, source_id, source_marker)
) WITHOUT ROWID;
CREATE TABLE edge_votes (
    user_id INTEGER NOT NULL,
    edge_id INTEGER NOT NULL,
    vote INTEGER NOT NULL,
    PRIMARY KEY(user_id, edge_id)
) WITHOUT ROWID;
"""


class ExportDictionarySourceDiffTests(unittest.TestCase):
    def test_removing_one_marker_preserves_same_source_edge(self) -> None:
        connection = sqlite3.connect(":memory:")
        connection.executescript(SCHEMA)
        connection.executemany(
            "INSERT INTO languages(id,code) VALUES (?,?)",
            ((1, "cmn"), (2, "eng")),
        )
        connection.execute(
            "INSERT INTO sources(id,type,name) VALUES (9,'publication','org.example.source')"
        )
        connection.executemany(
            "INSERT INTO expressions(id,language_id,text) VALUES (?,?,?)",
            ((10, 1, "她"), (20, 2, "Her")),
        )
        connection.execute(
            "INSERT INTO expression_edges(id,expression_a_id,expression_b_id) VALUES (70,10,20)"
        )
        connection.executemany(
            "INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES (70,9,?)",
            (("",), ("2",)),
        )

        output = io.StringIO()
        _write_delete_edge_batches(
            output,
            [
                (
                    "cmn", "她", 1,
                    "eng", "Her", 1,
                    1, 0, "2", "她", "Her",
                )
            ],
            source_type="publication",
            source_name="org.example.source",
            batch_size=1,
            mark_batches=True,
        )
        connection.executescript(output.getvalue())

        self.assertEqual(
            connection.execute(
                "SELECT source_marker FROM expression_edge_sources ORDER BY source_marker"
            ).fetchall(),
            [("",)],
        )
        self.assertIsNotNone(
            connection.execute("SELECT id FROM expression_edges WHERE id=70").fetchone()
        )
        connection.close()

    def test_skip_edge_source_cleanup_deletes_owned_parent_edge(self) -> None:
        connection = sqlite3.connect(":memory:")
        connection.executescript(SCHEMA)
        connection.execute("INSERT INTO languages(id,code) VALUES (1,'spa')")
        connection.execute(
            "INSERT INTO sources(id,type,name) VALUES (9,'publication','org.example.source')"
        )
        connection.executemany(
            "INSERT INTO expressions(id,language_id,text) VALUES (?,?,?)",
            ((10, 1, "Hola"), (20, 1, "Adiós")),
        )
        connection.execute(
            "INSERT INTO expression_edges(id,expression_a_id,expression_b_id) VALUES (70,10,20)"
        )
        connection.execute(
            "INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES (70,9,'')"
        )

        output = io.StringIO()
        _write_delete_edge_batches(
            output,
            [("spa", "Hola", 1, "spa", "Adiós", 1, 2, 0, "", "Hola", "Adiós")],
            source_type="publication",
            source_name="org.example.source",
            batch_size=1,
            mark_batches=False,
            delete_edge_sources=False,
        )
        connection.executescript(output.getvalue())

        self.assertIsNone(connection.execute("SELECT id FROM expression_edges WHERE id=70").fetchone())
        self.assertEqual(connection.execute("SELECT COUNT(*) FROM expression_edge_sources").fetchone()[0], 0)
        connection.close()


if __name__ == "__main__":
    unittest.main()
