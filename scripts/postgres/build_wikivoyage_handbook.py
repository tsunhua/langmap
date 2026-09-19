#!/usr/bin/env python3
"""Rebuild the managed Wikivoyage handbook using PostgreSQL only."""

from __future__ import annotations

import argparse
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


MANAGED_KEY = "enwikivoyage-phrasebooks"
DEFAULT_TITLE = "English phrasebook"
_MARKER = re.compile(r"^oldid:(?P<revision>[^#]+)#(?P<section>[^/]+)/(?P<row>\d+)$")


@dataclass(frozen=True)
class SectionProfile:
    key: str
    title: str
    position: int
    include: bool = True


@dataclass(frozen=True)
class SectionCatalog:
    sections: tuple[SectionProfile, ...]


@dataclass(frozen=True)
class BuildReport:
    handbook_id: int
    sections: int
    items: int
    reused: bool


def load_section_catalog(path: Path) -> SectionCatalog:
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    raw_sections = payload.get("sections")
    if not isinstance(raw_sections, list):
        raise ValueError("section catalog sections must be an array")
    sections: list[SectionProfile] = []
    for raw in raw_sections:
        if not isinstance(raw, dict):
            raise ValueError("section profile must be an object")
        key = str(raw.get("key") or "").strip().lower()
        title = str(raw.get("title") or "").strip()
        if not key or not title:
            raise ValueError("section profile needs key/title")
        sections.append(SectionProfile(key, title, int(raw.get("position", len(sections) + 1)), bool(raw.get("include", True))))
    if len({section.key for section in sections}) != len(sections):
        raise ValueError("duplicate section key")
    return SectionCatalog(tuple(sections))


def _casefold_text(text: str) -> str:
    return text.strip().casefold()


def _case_style_rank(text: str) -> int:
    letters = [character for character in text if character.isalpha()]
    if not letters:
        return 4
    if all(character.isupper() for character in letters):
        return 3
    if letters[0].isupper() and all(character.islower() for character in letters[1:]):
        return 0
    if letters[0].isupper():
        return 1
    return 2


def _can_merge_case_variants(candidates: list[tuple[int, int, str]]) -> bool:
    return any(_case_style_rank(candidate[2]) == 0 for candidate in candidates)


def _source_rows(connection) -> list[tuple[str, str, int, str]]:
    with connection.cursor() as cursor:
        cursor.execute(
            """SELECT es.source_marker, s.name, e.id AS expression_id, e.text
                 FROM expression_edge_sources es
                 JOIN sources s ON s.id=es.source_id
                 JOIN expression_edges ed ON ed.id=es.edge_id
                 JOIN expressions a ON a.id=ed.expression_a_id
                 JOIN expressions b ON b.id=ed.expression_b_id
                 JOIN languages la ON la.id=a.language_id
                 JOIN languages lb ON lb.id=b.language_id
                 JOIN expressions e ON e.id=CASE
                   WHEN la.code='eng' THEN a.id
                   WHEN lb.code='eng' THEN b.id
                   ELSE NULL END
                WHERE s.type='url'
                  AND s.name LIKE 'https://en.wikivoyage.org/wiki/%'
                  AND (ed.relation_mask & 1) <> 0
                  AND ((la.code='eng' AND lb.code<>'eng') OR (lb.code='eng' AND la.code<>'eng'))
                ORDER BY s.name, es.source_marker, e.text, e.id"""
        )
        return [(str(marker or ""), str(name or ""), int(expression_id), str(text)) for marker, name, expression_id, text in cursor.fetchall()]


def _section_rows(connection, section_catalog: SectionCatalog) -> dict[str, list[tuple[int, int, str]]]:
    sections: dict[str, list[tuple[int, int, str]]] = {
        profile.key: [] for profile in section_catalog.sections if profile.include
    }
    for marker, _source_name, expression_id, text in _source_rows(connection):
        match = _MARKER.fullmatch(marker)
        if match is None:
            raise ValueError(f"invalid Wikivoyage source marker: {marker or '<empty>'}")
        section = match.group("section").strip().casefold()
        if section not in sections:
            raise ValueError(f"unknown Wikivoyage section in source marker: {section}")
        sections[section].append((int(match.group("row")), expression_id, text))
    return sections


def _ordered_sections(section_catalog: SectionCatalog, discovered: set[str]) -> list[tuple[str, str, int]]:
    known = {profile.key: profile for profile in section_catalog.sections if profile.include}
    if discovered - set(known):
        raise ValueError("handbook contains sections outside the section catalog")
    return sorted(
        [(key, known[key].title, known[key].position) for key in known if key in discovered],
        key=lambda item: (item[2], item[0]),
    )


def build_managed_handbook(
    connection,
    section_catalog: SectionCatalog,
    *,
    managed_key: str = MANAGED_KEY,
    title: str = DEFAULT_TITLE,
) -> BuildReport:
    """Rebuild managed sections/items in one PostgreSQL transaction."""

    system = connection.execute("SELECT id FROM users WHERE username='langmap' ORDER BY id LIMIT 1").fetchone()
    if system is None:
        raise ValueError("system user langmap is required")
    locale = connection.execute("SELECT id FROM language_locales WHERE code='eng-Latn-US' LIMIT 1").fetchone()
    if locale is None:
        raise ValueError("eng-Latn-US locale is required")
    section_items = _section_rows(connection, section_catalog)
    with connection.transaction():
        existing = connection.execute("SELECT id FROM handbooks WHERE managed_key=%s", (managed_key,)).fetchone()
        reused = existing is not None
        if existing is None:
            handbook_id = int(connection.execute(
                """INSERT INTO handbooks(user_id,title,visibility,status,managed_key,language_locale_id)
                   VALUES(%s,%s,'public','published',%s,%s) RETURNING id""",
                (int(system[0]), title, managed_key, int(locale[0])),
            ).fetchone()[0])
        else:
            handbook_id = int(existing[0])
            connection.execute(
                """UPDATE handbooks
                      SET title=%s, visibility='public', status='published', language_locale_id=%s,
                          updated_at=CURRENT_TIMESTAMP::text
                    WHERE id=%s""",
                (title, int(locale[0]), handbook_id),
            )
            connection.execute("DELETE FROM handbook_sections WHERE handbook_id=%s", (handbook_id,))
        ordered = _ordered_sections(section_catalog, {key for key, rows in section_items.items() if rows})
        total_items = 0
        for position, (section_key, section_title, _catalog_position) in enumerate(ordered, 1):
            section_id = int(connection.execute(
                """INSERT INTO handbook_sections(handbook_id,title,position,parent_section_id)
                   VALUES(%s,%s,%s,NULL) RETURNING id""",
                (handbook_id, section_title, position),
            ).fetchone()[0])
            candidates = section_items.get(section_key, [])
            by_expression: dict[int, tuple[int, int, str]] = {}
            for row_number, expression_id, text in candidates:
                candidate = (row_number, expression_id, text)
                current = by_expression.get(expression_id)
                if current is None or candidate < current:
                    by_expression[expression_id] = candidate
            by_casefold: dict[str, list[tuple[int, int, str]]] = {}
            for candidate in by_expression.values():
                by_casefold.setdefault(_casefold_text(candidate[2]), []).append(candidate)
            deduplicated: list[tuple[int, int, str]] = []
            for variants in by_casefold.values():
                if len(variants) == 1 or not _can_merge_case_variants(variants):
                    deduplicated.extend(variants)
                    continue
                earliest_row = min(candidate[0] for candidate in variants)
                canonical = min(variants, key=lambda candidate: (_case_style_rank(candidate[2]), candidate[2], candidate[1]))
                deduplicated.append((earliest_row, canonical[1], canonical[2]))
            for item_position, (_row_number, expression_id, _text) in enumerate(
                sorted(deduplicated, key=lambda item: (item[0], item[2], item[1])), 1
            ):
                connection.execute(
                    "INSERT INTO handbook_section_items(section_id,position,expression_id) VALUES(%s,%s,%s)",
                    (section_id, item_position, expression_id),
                )
                total_items += 1
        check_sections = int(connection.execute("SELECT COUNT(*) FROM handbook_sections WHERE handbook_id=%s", (handbook_id,)).fetchone()[0])
        check_items = int(connection.execute(
            """SELECT COUNT(*) FROM handbook_section_items i
                 JOIN handbook_sections s ON s.id=i.section_id WHERE s.handbook_id=%s""",
            (handbook_id,),
        ).fetchone()[0])
        if check_sections != len(ordered) or check_items != total_items:
            raise ValueError("managed handbook count validation failed")
    return BuildReport(handbook_id, len(ordered), total_items, reused)


def connect(database_url: str):
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - CLI environment
        raise RuntimeError("install psycopg[binary] to rebuild the handbook") from exc
    return psycopg.connect(database_url)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-url", default=os.environ.get("DATABASE_URL"))
    parser.add_argument("--section-catalog", type=Path, required=True)
    parser.add_argument("--managed-key", default=MANAGED_KEY)
    parser.add_argument("--title", default=DEFAULT_TITLE)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if not args.database_url:
        raise SystemExit("--database-url or DATABASE_URL is required")
    with connect(args.database_url) as connection:
        report = build_managed_handbook(
            connection,
            load_section_catalog(args.section_catalog),
            managed_key=args.managed_key,
            title=args.title,
        )
    print(json.dumps({
        "handbook_id": report.handbook_id,
        "sections": report.sections,
        "items": report.items,
        "reused": report.reused,
    }, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
