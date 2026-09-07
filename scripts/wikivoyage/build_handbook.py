#!/usr/bin/env python3
"""Build the single system-managed English Wikivoyage phrasebook handbook."""

from __future__ import annotations

import re
import sqlite3
import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from .catalog import SectionCatalog, load_section_catalog


MANAGED_KEY = "enwikivoyage-phrasebooks"
DEFAULT_TITLE = "English phrasebook"
_MARKER = re.compile(r"^oldid:(?P<revision>[^#]+)#(?P<section>[^/]+)/(?P<row>\d+)$")


@dataclass(frozen=True)
class BuildReport:
    handbook_id: int
    sections: int
    items: int
    reused: bool


def _source_rows(connection: sqlite3.Connection) -> Iterable[sqlite3.Row]:
    return connection.execute(
        "SELECT es.source_marker, s.name, e.id AS expression_id, e.text "
        "FROM expression_edge_sources es "
        "JOIN sources s ON s.id=es.source_id "
        "JOIN expression_edges ed ON ed.id=es.edge_id "
        "JOIN expressions a ON a.id=ed.expression_a_id "
        "JOIN expressions b ON b.id=ed.expression_b_id "
        "JOIN languages la ON la.id=a.language_id "
        "JOIN languages lb ON lb.id=b.language_id "
        "JOIN expressions e ON e.id=CASE WHEN la.code='eng' THEN a.id WHEN lb.code='eng' THEN b.id ELSE NULL END "
        "WHERE s.type='url' AND s.name LIKE 'https://en.wikivoyage.org/wiki/%' "
        "AND (ed.relation_mask & 1) <> 0 "
        "AND ((la.code='eng' AND lb.code<>'eng') OR (lb.code='eng' AND la.code<>'eng')) "
        "ORDER BY s.name, es.source_marker, e.text, e.id"
    )


def _section_rows(connection: sqlite3.Connection, section_catalog: SectionCatalog) -> dict[str, list[tuple[int, int, str]]]:
    sections: dict[str, list[tuple[int, int, str]]] = {profile.key: [] for profile in section_catalog.sections if profile.include}
    for row in _source_rows(connection):
        marker = str(row["source_marker"] or "")
        match = _MARKER.match(marker)
        if match is None:
            continue
        section = match.group("section").strip().casefold()
        if section not in sections:
            # Unknown sections are retained with a stable custom key. The
            # parser normally resolves catalog aliases before this stage.
            section = f"custom-{re.sub(r'[^a-z0-9]+', '-', section).strip('-') or 'section'}"
            sections.setdefault(section, [])
        row_number = int(match.group("row"))
        # URL and marker are already deterministic; expression id is only a
        # final tie breaker when two pages contain the same English text.
        sections[section].append((row_number, int(row["expression_id"]), str(row["text"])))
    return sections


def _ordered_sections(section_catalog: SectionCatalog, discovered: set[str]) -> list[tuple[str, str, int]]:
    known = {profile.key: profile for profile in section_catalog.sections if profile.include}
    rows = [(key, known[key].title, known[key].position) for key in known if key in discovered]
    extra = sorted(discovered - set(known), key=str)
    rows.extend((key, key.removeprefix("custom-").replace("-", " ").title(), 10000 + index) for index, key in enumerate(extra))
    return sorted(rows, key=lambda item: (item[2], item[0]))


def build_managed_handbook(
    connection: sqlite3.Connection,
    section_catalog: SectionCatalog,
    *,
    managed_key: str = MANAGED_KEY,
    title: str = DEFAULT_TITLE,
) -> BuildReport:
    """Rebuild managed sections/items in one transaction and validate counts."""

    connection.row_factory = sqlite3.Row
    system = connection.execute("SELECT id FROM users WHERE username='langmap' ORDER BY id LIMIT 1").fetchone()
    if system is None:
        raise ValueError("system user langmap is required")
    locale = connection.execute("SELECT id FROM language_locales WHERE code='eng-Latn-US' LIMIT 1").fetchone()
    if locale is None:
        raise ValueError("eng-Latn-US locale is required")
    section_items = _section_rows(connection, section_catalog)
    with connection:
        existing = connection.execute("SELECT id FROM handbooks WHERE managed_key=?", (managed_key,)).fetchone()
        reused = existing is not None
        if existing is None:
            cursor = connection.execute(
                "INSERT INTO handbooks(user_id,title,visibility,status,managed_key,language_locale_id) VALUES(?,?, 'public','published',?,?)",
                (int(system[0]), title, managed_key, int(locale[0])),
            )
            handbook_id = int(cursor.lastrowid)
        else:
            handbook_id = int(existing[0])
            connection.execute(
                "UPDATE handbooks SET title=?,visibility='public',status='published',language_locale_id=?,updated_at=CURRENT_TIMESTAMP WHERE id=?",
                (title, int(locale[0]), handbook_id),
            )
            connection.execute("DELETE FROM handbook_sections WHERE handbook_id=?", (handbook_id,))
        ordered = _ordered_sections(
            section_catalog,
            {key for key, rows in section_items.items() if rows},
        )
        total_items = 0
        for position, (section_key, section_title, _catalog_position) in enumerate(ordered, 1):
            section_cursor = connection.execute(
                "INSERT INTO handbook_sections(handbook_id,title,position,parent_section_id) VALUES(?,?,?,NULL)",
                (handbook_id, section_title, position),
            )
            section_id = int(section_cursor.lastrowid)
            candidates = section_items.get(section_key, [])
            by_expression: dict[int, tuple[int, int, str]] = {}
            for row_number, expression_id, text in candidates:
                current = by_expression.get(expression_id)
                candidate = (row_number, expression_id, text)
                if current is None or candidate < current:
                    by_expression[expression_id] = candidate
            ordered_items = sorted(by_expression.values(), key=lambda item: (item[0], item[2], item[1]))
            for item_position, (_row_number, expression_id, _text) in enumerate(ordered_items, 1):
                connection.execute(
                    "INSERT INTO handbook_section_items(section_id,position,expression_id) VALUES(?,?,?)",
                    (section_id, item_position, expression_id),
                )
                total_items += 1
        check_sections = int(connection.execute("SELECT COUNT(*) FROM handbook_sections WHERE handbook_id=?", (handbook_id,)).fetchone()[0])
        check_items = int(connection.execute("SELECT COUNT(*) FROM handbook_section_items i JOIN handbook_sections s ON s.id=i.section_id WHERE s.handbook_id=?", (handbook_id,)).fetchone()[0])
        if check_sections != len(ordered) or check_items != total_items:
            raise ValueError("managed handbook count validation failed")
    return BuildReport(handbook_id, len(ordered), total_items, reused)


def build_from_database(database: Path, section_catalog_path: Path) -> BuildReport:
    connection = sqlite3.connect(Path(database))
    try:
        return build_managed_handbook(connection, load_section_catalog(section_catalog_path))
    finally:
        connection.close()


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, required=True)
    parser.add_argument("--section-catalog", type=Path, required=True)
    parser.add_argument("--managed-key", default=MANAGED_KEY)
    parser.add_argument("--title", default=DEFAULT_TITLE)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    connection = sqlite3.connect(args.database)
    try:
        report = build_managed_handbook(
            connection,
            load_section_catalog(args.section_catalog),
            managed_key=args.managed_key,
            title=args.title,
        )
    finally:
        connection.close()
    print(json.dumps({
        "handbook_id": report.handbook_id,
        "sections": report.sections,
        "items": report.items,
        "reused": report.reused,
    }, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
