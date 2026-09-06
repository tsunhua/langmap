#!/usr/bin/env python3
"""Recover the approved subset of the old v1 user/handbook snapshot.

The old dump has no direct equivalent for the canonical ``meanings`` table.
This recovery therefore treats a v1 meaning as a one-hop relation: seed
expressions are the three approved users' content plus the expressions
rendered by the Jiazi handbook; every other content expression in one of
those meanings is included once.  The generated delta uses language codes,
locale codes, expression text, and source markers instead of staging IDs.

Typical workflow::

    python3 scripts/db/migrate_v1/recover_selected.py \
      --staging /tmp/langmap-jiazi-recovery.sqlite \
      --output scripts/db/state/backup/delta/034-v1-jiazi-recovery.split.sql

The staging database must be a disposable copy of a canonical SQLite mirror.
The command mutates only that copy and writes a report beside the delta; it
does not contact production.  Production publication is intentionally left
to ``scripts/db/manage.sh production plan/apply``.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from itertools import combinations
from pathlib import Path
from typing import Iterable, Sequence

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from scripts.db.migrate_v1.handbooks import clean_section_title, parse_sections
from scripts.db.migrate_v1.identity import canonicalize_text
from scripts.db.migrate_v1.parse_sql import load_table_file


SOURCE_TYPE = "system"
SOURCE_NAME = "LangMap V1 selected user/handbook recovery: Jiazi"
HANDBOOK_TITLE = "甲子話表達分類手冊（更新中）"
HANDBOOK_ID = 1539253276
HANDBOOK_SOURCE_LOCALE = "nan-Hant-CN_LufengJiazi"
APPROVED_USERNAMES = frozenset({"monhiko", "benojan", "ladybug"})
# ``system`` rows can be genuine content counterparts of a selected meaning
# and are therefore in scope for this one-hop recovery.  These three owners
# are generated/runtime or auxiliary data and remain excluded.
AUXILIARY_RUNTIME_OWNERS = frozenset({"langmap", "ai", "opus"})

# These are either explicitly excluded exact profiles or legacy Taiwanese
# profile/reading rows already covered by the ChhoeTaigi publication.
SKIPPED_CODES = frozenset(
    {
        "fr-FR",
        "de-DE",
        "ko-KR",
        "nan-x-hai",
        "nan-TW",
        "nan-TW-POJ",
        "nan-TW-TL",
    }
)

LANGUAGE_LOCALE_MAP: dict[str, tuple[str, str]] = {
    "zh-TW": ("cmn", "cmn-Hant-TW"),
    "zh-CN": ("cmn", "cmn-Hans-CN"),
    "zh-HK": ("yue", "yue-Hant-HK"),
    "yue-HK": ("yue", "yue-Hant-HK"),
    "en-US": ("eng", "eng-Latn-US"),
    "en-GB": ("eng", "eng-Latn-GB"),
    "ja-JP": ("jpn", "jpn-Jpan-JP"),
    "es-ES": ("spa", "spa-Latn-ES"),
    "cieh-tc": ("wuu", "wuu-Hant-CN_Taizhou"),
    # The old v1 label was a Shanghai profile.  Do not inherit the stale
    # migration helper's Wenzhou/Hans mapping.
    "wuu-sh": ("wuu", "wuu-Hant-CN_Shanghai"),
    "zyg-jx": ("zyg", "zyg-Latn-CN_Jingxi"),
    "ral": ("ral", "ral-Latn-IN"),
    "swh": ("swh", "swh-Latn-TZ"),
    "image": ("x-image", "x-image-Latn-US"),
    "emoji": ("x-emoji", "x-emoji-Latn-US"),
}
NAN_JIAZI_CODES = frozenset({"nan-x-cha", "nan-x-cha-Latn-puj", "nan-x-cha-jiazi"})

EXPRESSION_ID_RE = re.compile(r"data-expression-id[^0-9]*(\d+)")


@dataclass(frozen=True)
class SelectedRow:
    old_id: str
    old_code: str
    language_code: str
    locale_code: str
    text: str
    created_by: int | None
    owner_name: str
    created_at: str

    @property
    def key(self) -> tuple[str, str]:
        return (self.language_code, self.text)


@dataclass(frozen=True)
class CanonicalExpression:
    language_code: str
    text: str
    homograph_index: int
    pos_mask: int
    created_by: int | None
    created_at: str
    locale_codes: tuple[str, ...]
    old_ids: tuple[str, ...]

    @property
    def key(self) -> tuple[str, str]:
        return (self.language_code, self.text)


@dataclass(frozen=True)
class EdgeRow:
    a: tuple[str, str]
    b: tuple[str, str]
    relation_mask: int
    score: int
    source_markers: tuple[str, ...]


@dataclass
class RecoveryData:
    old_users: list[dict[str, object]]
    handbook: dict[str, object]
    selected_rows: dict[str, SelectedRow]
    canonical: dict[tuple[str, str], CanonicalExpression]
    edges: list[EdgeRow]
    handbook_sections: list[dict[str, object]]
    seed_ids: set[str]
    seed_user_ids: set[str]
    seed_handbook_ids: set[str]
    seed_meanings: set[str]
    report: dict[str, object]


def _literal(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value)
    if "\x00" in text:
        raise ValueError("NUL byte cannot be represented in generated SQL")
    return "'" + text.replace("'", "''") + "'"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _as_id(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, int):
        return str(value)
    text = str(value).strip()
    if text.isdigit():
        return str(int(text))
    return text


def _owner_name(value: object, users_by_id: dict[str, dict[str, object]]) -> str:
    owner_id = _as_id(value)
    if owner_id in users_by_id:
        return str(users_by_id[owner_id].get("username") or "")
    return str(value).strip() if value is not None else ""


def _owner_id(
    value: object,
    users_by_id: dict[str, dict[str, object]],
    users_by_name: dict[str, int],
) -> int | None:
    owner_id = _as_id(value)
    if owner_id in users_by_id:
        return int(owner_id)
    return users_by_name.get(str(value).strip()) if value is not None else None


def _is_cjk_text(text: str) -> bool:
    """Return whether text contains a Han/CJK code point.

    Old Chaozhou romanization contains combining marks and superscript nasal
    signs, so an ASCII-letter regex misclassifies it.  Any Han character is a
    reliable Hant-vs-Latn discriminator for the two Jiazi profiles.
    """

    for character in text:
        codepoint = ord(character)
        if (
            codepoint == 0x3007
            or 0x3400 <= codepoint <= 0x4DBF
            or 0x4E00 <= codepoint <= 0x9FFF
            or 0xF900 <= codepoint <= 0xFAFF
            or 0x20000 <= codepoint <= 0x323AF
        ):
            return True
    return False


def map_old_expression(code: str, text: str) -> tuple[str, str] | None:
    if code in NAN_JIAZI_CODES:
        locale = (
            "nan-Hant-CN_LufengJiazi"
            if _is_cjk_text(text)
            else "nan-Latn-CN_LufengJiazi"
        )
        return ("nan", locale)
    return LANGUAGE_LOCALE_MAP.get(code)


def _has_ui_tag(row: dict[str, object]) -> bool:
    tags = row.get("tags")
    return isinstance(tags, str) and "langmap." in tags


def _created_at(row: dict[str, object]) -> str:
    value = row.get("created_at")
    return str(value) if value not in (None, "") else "1970-01-01 00:00:00"


def _drop_reason(
    row: dict[str, object],
    *,
    users_by_id: dict[str, dict[str, object]],
    handbook_ids: set[str],
) -> str | None:
    if _has_ui_tag(row):
        return "langmap-ui-translation"
    code = str(row.get("language_code") or "")
    if code in SKIPPED_CODES:
        return "excluded-locale-or-chhoetaigi-duplicate"
    text = canonicalize_text(str(row.get("text") or ""))
    if not text:
        return "empty-text"
    if map_old_expression(code, text) is None:
        return "unmapped-locale"
    owner = _owner_name(row.get("created_by"), users_by_id)
    if owner in AUXILIARY_RUNTIME_OWNERS:
        return "runtime-owner"
    return None


def _creator_sort(row: SelectedRow) -> tuple[int, str, int, str]:
    # A real user is a more useful canonical creator than a system row when
    # NFC/text identity merges duplicate old rows.
    user_priority = 0 if row.created_by is not None else 1
    return (user_priority, row.created_at, row.created_by or 0, row.old_id)


def _load_inputs(source_dir: Path) -> dict[str, list[dict[str, object]]]:
    return {
        "users": load_table_file(str(source_dir / "remote-users.sql"), "users"),
        "expressions": load_table_file(
            str(source_dir / "remote-expressions.sql"), "expressions"
        ),
        "expression_meaning": load_table_file(
            str(source_dir / "remote-expression_meaning.sql"), "expression_meaning"
        ),
        "handbooks": load_table_file(
            str(source_dir / "remote-handbooks.sql"), "handbooks"
        ),
        "handbook_pages": load_table_file(
            str(source_dir / "remote-handbook_pages.sql"), "handbook_pages"
        ),
    }


def _select_data(inputs: dict[str, list[dict[str, object]]]) -> RecoveryData:
    users = inputs["users"]
    expressions = inputs["expressions"]
    expression_meaning = inputs["expression_meaning"]
    handbooks = inputs["handbooks"]
    pages = inputs["handbook_pages"]

    users_by_id: dict[str, dict[str, object]] = {}
    users_by_name: dict[str, int] = {}
    duplicate_user_ids = 0
    for row in users:
        key = _as_id(row.get("id"))
        if key in users_by_id:
            duplicate_user_ids += 1
        users_by_id[key] = row
        users_by_name[str(row.get("username") or "")] = int(row.get("id") or 0)

    handbook_matches = [row for row in handbooks if row.get("title") == HANDBOOK_TITLE]
    if len(handbook_matches) != 1:
        raise ValueError(
            f"expected exactly one handbook titled {HANDBOOK_TITLE!r}, "
            f"found {len(handbook_matches)}"
        )
    handbook = handbook_matches[0]
    handbook_id = _as_id(handbook.get("id"))
    if handbook_id != str(HANDBOOK_ID):
        raise ValueError(f"unexpected Jiazi handbook id: {handbook_id}")

    rendered_ids = {
        match
        for match in EXPRESSION_ID_RE.findall(str(handbook.get("renders") or ""))
    }
    expression_by_id: dict[str, dict[str, object]] = {}
    duplicate_expression_ids = 0
    for row in expressions:
        key = _as_id(row.get("id"))
        if key in expression_by_id:
            duplicate_expression_ids += 1
        expression_by_id[key] = row

    meaning_to_ids: dict[str, set[str]] = defaultdict(set)
    meanings_by_expression: dict[str, set[str]] = defaultdict(set)
    for row in expression_meaning:
        meaning_id = _as_id(row.get("meaning_id"))
        expression_id = _as_id(row.get("expression_id"))
        if meaning_id and expression_id:
            meaning_to_ids[meaning_id].add(expression_id)
            meanings_by_expression[expression_id].add(meaning_id)

    exclusion_counts: Counter[str] = Counter()
    seed_handbook_ids: set[str] = set()
    missing_render_ids = sorted(rendered_ids - set(expression_by_id))
    for expression_id in sorted(rendered_ids & set(expression_by_id)):
        row = expression_by_id[expression_id]
        reason = _drop_reason(
            row, users_by_id=users_by_id, handbook_ids=rendered_ids
        )
        if reason is None:
            seed_handbook_ids.add(expression_id)
        else:
            exclusion_counts[reason] += 1

    seed_user_ids: set[str] = set()
    for row in expressions:
        owner = _owner_name(row.get("created_by"), users_by_id)
        if owner not in APPROVED_USERNAMES:
            continue
        reason = _drop_reason(
            row, users_by_id=users_by_id, handbook_ids=rendered_ids
        )
        if reason is None:
            seed_user_ids.add(_as_id(row.get("id")))
        else:
            exclusion_counts[f"seed-user:{reason}"] += 1

    seed_ids = seed_user_ids | seed_handbook_ids
    seed_meanings = {
        meaning_id
        for expression_id in seed_ids
        for meaning_id in meanings_by_expression.get(expression_id, set())
    }
    related_ids = {
        expression_id
        for meaning_id in seed_meanings
        for expression_id in meaning_to_ids[meaning_id]
    }
    closure_ids = seed_ids | related_ids

    selected_rows: dict[str, SelectedRow] = {}
    for expression_id in sorted(closure_ids):
        row = expression_by_id.get(expression_id)
        if row is None:
            exclusion_counts["missing-expression-row"] += 1
            continue
        reason = _drop_reason(
            row, users_by_id=users_by_id, handbook_ids=rendered_ids
        )
        if reason is not None:
            exclusion_counts[reason] += 1
            continue
        old_code = str(row.get("language_code") or "")
        text = canonicalize_text(str(row.get("text") or ""))
        mapped = map_old_expression(old_code, text)
        if mapped is None:
            # _drop_reason already checks this; keep the guard local so a
            # future mapping change cannot create an invalid SelectedRow.
            exclusion_counts["unmapped-locale"] += 1
            continue
        selected_rows[expression_id] = SelectedRow(
            old_id=expression_id,
            old_code=old_code,
            language_code=mapped[0],
            locale_code=mapped[1],
            text=text,
            created_by=_owner_id(row.get("created_by"), users_by_id, users_by_name),
            owner_name=_owner_name(row.get("created_by"), users_by_id),
            created_at=_created_at(row),
        )

    grouped: dict[tuple[str, str], list[SelectedRow]] = defaultdict(list)
    for row in selected_rows.values():
        grouped[row.key].append(row)
    canonical: dict[tuple[str, str], CanonicalExpression] = {}
    for key, group in sorted(grouped.items()):
        ordered = sorted(group, key=_creator_sort)
        canonical[key] = CanonicalExpression(
            language_code=key[0],
            text=key[1],
            homograph_index=1,
            pos_mask=0,
            created_by=ordered[0].created_by,
            created_at=min(row.created_at for row in group),
            locale_codes=tuple(sorted({row.locale_code for row in group})),
            old_ids=tuple(sorted(row.old_id for row in group)),
        )

    old_to_key = {old_id: row.key for old_id, row in selected_rows.items()}
    edge_markers: dict[tuple[tuple[str, str], tuple[str, str]], set[str]] = defaultdict(set)
    old_meaning_pair_count = 0
    meaning_endpoint_count = 0
    meanings_with_multiple_kept_endpoints = 0
    for meaning_id in sorted(seed_meanings):
        kept_old_ids = sorted(
            {
                expression_id
                for expression_id in meaning_to_ids[meaning_id]
                if expression_id in old_to_key
            }
        )
        meaning_endpoint_count += len(kept_old_ids)
        if len(kept_old_ids) >= 2:
            meanings_with_multiple_kept_endpoints += 1
            old_meaning_pair_count += len(kept_old_ids) * (len(kept_old_ids) - 1) // 2
        for old_a, old_b in combinations(kept_old_ids, 2):
            key_a = old_to_key[old_a]
            key_b = old_to_key[old_b]
            if key_a == key_b:
                continue
            edge_key = tuple(sorted((key_a, key_b)))
            edge_markers[edge_key].add(f"v1-meaning:{meaning_id}")
    edges = [
        EdgeRow(
            a=edge_key[0],
            b=edge_key[1],
            relation_mask=1,
            score=0,
            source_markers=tuple(sorted(markers)),
        )
        for edge_key, markers in sorted(edge_markers.items())
    ]

    pages_by_handbook: dict[str, list[dict[str, object]]] = defaultdict(list)
    for page in pages:
        pages_by_handbook[_as_id(page.get("handbook_id"))].append(page)
    handbook_contents = [
        str(page.get("content") or "")
        for page in sorted(
            pages_by_handbook.get(handbook_id, []),
            key=lambda row: int(row.get("sort_order") or 0),
        )
    ] or [str(handbook.get("content") or "")]

    text_index: dict[str, list[SelectedRow]] = defaultdict(list)
    for row in selected_rows.values():
        text_index[row.text].append(row)
    handbook_sections: list[dict[str, object]] = []
    unresolved_handbook_refs: Counter[str] = Counter()
    section_position = 0
    for content in handbook_contents:
        stack: list[tuple[int, int]] = []
        for title, refs, level in parse_sections(content):
            while stack and stack[-1][0] >= level:
                stack.pop()
            parent_position = stack[-1][1] if stack else None
            section: dict[str, object] = {
                "position": section_position,
                "title": title,
                "parent_position": parent_position,
                "items": [],
            }
            item_rows: list[dict[str, object]] = []
            for item_position, ref in enumerate(refs):
                candidates: list[SelectedRow]
                if ref.isdigit():
                    candidate = selected_rows.get(_as_id(ref))
                    candidates = [candidate] if candidate is not None else []
                elif ref.startswith("text:"):
                    candidates = text_index.get(canonicalize_text(ref[5:]), [])
                else:
                    candidates = []
                if not candidates:
                    unresolved_handbook_refs[ref] += 1
                    continue
                direct_candidates = [
                    candidate for candidate in candidates if candidate.old_id in rendered_ids
                ]
                ordered = sorted(
                    direct_candidates or candidates,
                    key=_creator_sort,
                )
                item_rows.append(
                    {
                        "position": item_position,
                        "key": ordered[0].key,
                        "ref": ref,
                    }
                )
            section["items"] = item_rows
            handbook_sections.append(section)
            stack.append((level, section_position))
            section_position += 1

    owner_counts = Counter(row.owner_name or "<unknown>" for row in selected_rows.values())
    old_code_counts = Counter(row.old_code for row in selected_rows.values())
    locale_counts = Counter(row.locale_code for row in selected_rows.values())
    report: dict[str, object] = {
        "schema_version": 1,
        "kind": "selected-v1-user-handbook-recovery",
        "source": {"type": SOURCE_TYPE, "name": SOURCE_NAME},
        "scope": {
            "approved_users": sorted(APPROVED_USERNAMES),
            "handbook_id": HANDBOOK_ID,
            "handbook_title": HANDBOOK_TITLE,
            "included_handbooks": [HANDBOOK_TITLE],
            "excluded_handbooks": [
                "各地中文常用語對照",
                "Test_multi",
                "測試",
            ],
            "meaning_hops": 1,
            "collections_imported": False,
            "old_auxiliary_data_imported": False,
        },
        "source_counts": {
            "users": len(users),
            "expressions": len(expressions),
            "expression_meaning": len(expression_meaning),
            "handbooks": len(handbooks),
            "handbook_pages": len(pages),
            "duplicate_user_ids": duplicate_user_ids,
            "duplicate_expression_ids": duplicate_expression_ids,
        },
        "selection": {
            "handbook_render_ids": len(rendered_ids),
            "missing_handbook_render_rows": len(missing_render_ids),
            "seed_user_expressions": len(seed_user_ids),
            "seed_handbook_expressions": len(seed_handbook_ids),
            "seed_expressions": len(seed_ids),
            "seed_meanings": len(seed_meanings),
            "meaning_endpoints_kept": meaning_endpoint_count,
            "meanings_with_multiple_kept_endpoints": meanings_with_multiple_kept_endpoints,
            "raw_old_meaning_pairs_before_canonical_dedupe": old_meaning_pair_count,
            "raw_closure_expression_ids": len(closure_ids),
            "selected_old_expression_rows": len(selected_rows),
            "canonical_expression_identities": len(canonical),
            "merged_old_rows": len(selected_rows) - len(canonical),
            "canonical_edges": len(edges),
            "edge_source_markers": sum(len(edge.source_markers) for edge in edges),
            "handbook_sections": len(handbook_sections),
            "handbook_item_refs": sum(
                len(section["items"]) for section in handbook_sections
            ),
            "unresolved_handbook_item_refs": sum(unresolved_handbook_refs.values()),
        },
        "selected_owner_counts": dict(sorted(owner_counts.items())),
        "selected_old_code_counts": dict(sorted(old_code_counts.items())),
        "selected_locale_counts": dict(sorted(locale_counts.items())),
        "exclusions": dict(sorted(exclusion_counts.items())),
        "unresolved_handbook_refs": dict(sorted(unresolved_handbook_refs.items())),
        "missing_handbook_render_ids": missing_render_ids,
    }
    return RecoveryData(
        old_users=users,
        handbook=handbook,
        selected_rows=selected_rows,
        canonical=canonical,
        edges=edges,
        handbook_sections=handbook_sections,
        seed_ids=seed_ids,
        seed_user_ids=seed_user_ids,
        seed_handbook_ids=seed_handbook_ids,
        seed_meanings=seed_meanings,
        report=report,
    )


def _ensure_staging_schema(connection: sqlite3.Connection) -> None:
    required = {
        "users",
        "languages",
        "language_locales",
        "sources",
        "expressions",
        "expression_locale_links",
        "expression_edges",
        "expression_sources",
        "expression_edge_sources",
        "handbooks",
        "handbook_sections",
        "handbook_section_items",
    }
    actual = {
        str(row[0])
        for row in connection.execute(
            "SELECT name FROM sqlite_master WHERE type='table'"
        )
    }
    missing = sorted(required - actual)
    if missing:
        raise ValueError("staging is not canonical or is missing tables: " + ", ".join(missing))


def _lookup_languages_and_locales(
    connection: sqlite3.Connection,
    canonical: dict[tuple[str, str], CanonicalExpression],
) -> tuple[dict[str, int], dict[str, int]]:
    language_codes = sorted({expression.language_code for expression in canonical.values()})
    locale_codes = sorted(
        {locale for expression in canonical.values() for locale in expression.locale_codes}
        | {HANDBOOK_SOURCE_LOCALE}
    )
    languages = {
        str(row[0]): int(row[1])
        for row in connection.execute(
            "SELECT code,id FROM languages WHERE code IN ({})".format(
                ",".join("?" for _ in language_codes)
            ),
            language_codes,
        )
    }
    locales = {
        str(row[0]): int(row[1])
        for row in connection.execute(
            "SELECT code,id FROM language_locales WHERE code IN ({})".format(
                ",".join("?" for _ in locale_codes)
            ),
            locale_codes,
        )
    }
    missing_languages = sorted(set(language_codes) - set(languages))
    missing_locales = sorted(set(locale_codes) - set(locales))
    if missing_languages:
        raise ValueError("staging is missing languages: " + ", ".join(missing_languages))
    if missing_locales:
        raise ValueError("staging is missing locales: " + ", ".join(missing_locales))
    return languages, locales


def _upsert_users(
    connection: sqlite3.Connection,
    users: Sequence[dict[str, object]],
) -> None:
    for row in users:
        user_id = int(row.get("id") or 0)
        username = str(row.get("username") or "")
        existing_by_id = connection.execute(
            "SELECT username,email FROM users WHERE id=?", (user_id,)
        ).fetchone()
        existing_by_name = connection.execute(
            "SELECT id,email FROM users WHERE username=?", (username,)
        ).fetchone()
        if existing_by_id and str(existing_by_id[0]) != username:
            raise ValueError(f"staging user id conflict: {user_id}")
        if existing_by_name and int(existing_by_name[0]) != user_id:
            raise ValueError(f"staging username conflict: {username}")
        created_at = str(row.get("created_at") or "1970-01-01 00:00:00")
        updated_at = str(row.get("updated_at") or created_at)
        role = str(row.get("role") or "user")
        if role not in {"admin", "user"}:
            role = "user"
        connection.execute(
            """
            INSERT OR IGNORE INTO users
              (id,username,email,password_hash,role,email_verified,created_at,updated_at)
            VALUES (?,?,?,?,?,?,?,?)
            """,
            (
                user_id,
                username,
                str(row.get("email") or ""),
                str(row.get("password_hash") or ""),
                role,
                int(row.get("email_verified") or 0),
                created_at,
                updated_at,
            ),
        )


def _stage_data(staging: Path, data: RecoveryData) -> dict[str, object]:
    connection = sqlite3.connect(staging, timeout=120)
    connection.execute("PRAGMA foreign_keys=ON")
    try:
        _ensure_staging_schema(connection)
        languages, locales = _lookup_languages_and_locales(connection, data.canonical)
        users_by_id = {
            int(row.get("id") or 0): row for row in data.old_users
        }
        with connection:
            _upsert_users(connection, data.old_users)
            connection.execute(
                "INSERT OR IGNORE INTO sources(type,name) VALUES (?,?)",
                (SOURCE_TYPE, SOURCE_NAME),
            )
            source_id = int(
                connection.execute(
                    "SELECT id FROM sources WHERE type=? AND name=?",
                    (SOURCE_TYPE, SOURCE_NAME),
                ).fetchone()[0]
            )

            expression_ids: dict[tuple[str, str], int] = {}
            for key, expression in sorted(data.canonical.items()):
                connection.execute(
                    """
                    INSERT OR IGNORE INTO expressions
                      (language_id,text,homograph_index,pos_mask,source_id,created_by,created_at)
                    VALUES (?,?,?,?,?,?,?)
                    """,
                    (
                        languages[expression.language_code],
                        expression.text,
                        expression.homograph_index,
                        expression.pos_mask,
                        source_id,
                        expression.created_by,
                        expression.created_at,
                    ),
                )
                row = connection.execute(
                    """
                    SELECT id FROM expressions
                    WHERE language_id=? AND text=? AND homograph_index=?
                    """,
                    (
                        languages[expression.language_code],
                        expression.text,
                        expression.homograph_index,
                    ),
                ).fetchone()
                if row is None:
                    raise ValueError(f"failed to stage expression: {key!r}")
                expression_ids[key] = int(row[0])
                for old_id in expression.old_ids:
                    connection.execute(
                        """
                        INSERT OR IGNORE INTO expression_sources
                          (expression_id,source_id,source_marker)
                        VALUES (?,?,?)
                        """,
                        (expression_ids[key], source_id, f"v1-expression:{old_id}"),
                    )
                for locale_code in expression.locale_codes:
                    connection.execute(
                        """
                        INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id)
                        VALUES (?,?)
                        """,
                        (expression_ids[key], locales[locale_code]),
                    )

            staged_edge_ids: dict[tuple[tuple[str, str], tuple[str, str]], int] = {}
            for edge in data.edges:
                a_id = expression_ids[edge.a]
                b_id = expression_ids[edge.b]
                low_id, high_id = sorted((a_id, b_id))
                connection.execute(
                    """
                    INSERT OR IGNORE INTO expression_edges
                      (expression_a_id,expression_b_id,relation_mask,score,created_by)
                    VALUES (?,?,?,?,NULL)
                    """,
                    (low_id, high_id, edge.relation_mask, edge.score),
                )
                row = connection.execute(
                    """
                    SELECT id FROM expression_edges
                    WHERE expression_a_id=? AND expression_b_id=?
                    """,
                    (low_id, high_id),
                ).fetchone()
                if row is None:
                    raise ValueError(f"failed to stage edge: {edge.a!r} {edge.b!r}")
                edge_id = int(row[0])
                staged_edge_ids[(edge.a, edge.b)] = edge_id
                for marker in edge.source_markers:
                    connection.execute(
                        """
                        INSERT OR IGNORE INTO expression_edge_sources
                          (edge_id,source_id,source_marker)
                        VALUES (?,?,?)
                        """,
                        (edge_id, source_id, marker),
                    )

            handbook_user_id = int(data.handbook.get("user_id") or 0)
            if handbook_user_id not in users_by_id:
                raise ValueError(f"handbook owner is not in old users: {handbook_user_id}")
            handbook_locale_id = locales[HANDBOOK_SOURCE_LOCALE]
            handbook_created_at = str(
                data.handbook.get("created_at") or "1970-01-01 00:00:00"
            )
            handbook_updated_at = str(
                data.handbook.get("updated_at") or handbook_created_at
            )
            visibility = (
                "public"
                if data.handbook.get("is_public") in (1, "1", True)
                else "private"
            )
            status = str(data.handbook.get("status") or "published")
            if status not in {"draft", "published", "archived"}:
                status = "published"
            connection.execute(
                """
                INSERT OR IGNORE INTO handbooks
                  (id,user_id,title,visibility,status,language_locale_id,score,created_at,updated_at)
                VALUES (?,?,?,?,?,?,?,?,?)
                """,
                (
                    HANDBOOK_ID,
                    handbook_user_id,
                    HANDBOOK_TITLE,
                    visibility,
                    status,
                    handbook_locale_id,
                    int(data.handbook.get("score") or 0),
                    handbook_created_at,
                    handbook_updated_at,
                ),
            )
            handbook_check = connection.execute(
                "SELECT user_id,title FROM handbooks WHERE id=?", (HANDBOOK_ID,)
            ).fetchone()
            if handbook_check is None or int(handbook_check[0]) != handbook_user_id or handbook_check[1] != HANDBOOK_TITLE:
                raise ValueError("staging handbook identity conflict")

            section_ids: dict[int, int] = {}
            for section in data.handbook_sections:
                position = int(section["position"])
                title = section["title"]
                existing = connection.execute(
                    "SELECT id,title FROM handbook_sections WHERE handbook_id=? AND position=?",
                    (HANDBOOK_ID, position),
                ).fetchone()
                if existing is not None and existing[1] != title:
                    raise ValueError(f"staging handbook section conflict at {position}")
                connection.execute(
                    """
                    INSERT OR IGNORE INTO handbook_sections
                      (handbook_id,title,position,parent_section_id)
                    VALUES (?,?,?,NULL)
                    """,
                    (HANDBOOK_ID, title, position),
                )
                section_id = connection.execute(
                    "SELECT id FROM handbook_sections WHERE handbook_id=? AND position=?",
                    (HANDBOOK_ID, position),
                ).fetchone()
                if section_id is None:
                    raise ValueError(f"failed to stage handbook section {position}")
                section_ids[position] = int(section_id[0])
            for section in data.handbook_sections:
                position = int(section["position"])
                parent_position = section["parent_position"]
                parent_id = (
                    section_ids[int(parent_position)]
                    if parent_position is not None
                    else None
                )
                connection.execute(
                    """
                    UPDATE handbook_sections SET parent_section_id=?
                    WHERE handbook_id=? AND position=?
                    """,
                    (parent_id, HANDBOOK_ID, position),
                )
                for item in section["items"]:
                    expression_id = expression_ids[item["key"]]
                    item_position = int(item["position"])
                    existing_item = connection.execute(
                        """
                        SELECT expression_id FROM handbook_section_items
                        WHERE section_id=? AND position=?
                        """,
                        (section_ids[position], item_position),
                    ).fetchone()
                    if existing_item is not None and int(existing_item[0]) != expression_id:
                        raise ValueError(
                            f"staging handbook item conflict at section {position}, "
                            f"position {item_position}"
                        )
                    connection.execute(
                        """
                        INSERT OR IGNORE INTO handbook_section_items
                          (section_id,position,expression_id)
                        VALUES (?,?,?)
                        """,
                        (section_ids[position], item_position, expression_id),
                    )

        foreign_key_errors = [tuple(row) for row in connection.execute("PRAGMA foreign_key_check")]
        if foreign_key_errors:
            raise ValueError(f"staging foreign-key errors: {foreign_key_errors[:3]}")
        return _staging_counts(connection, source_id)
    finally:
        connection.close()


def _staging_counts(connection: sqlite3.Connection, source_id: int) -> dict[str, object]:
    def one(sql: str, parameters: Sequence[object] = ()) -> int:
        return int(connection.execute(sql, tuple(parameters)).fetchone()[0])

    counts: dict[str, object] = {
        "source_id": source_id,
        "source_rows": one(
            "SELECT COUNT(*) FROM sources WHERE id=?", (source_id,)
        ),
        "source_expression_identities": one(
            "SELECT COUNT(DISTINCT expression_id) FROM expression_sources WHERE source_id=?",
            (source_id,),
        ),
        "source_expression_claims": one(
            "SELECT COUNT(*) FROM expression_sources WHERE source_id=?", (source_id,)
        ),
        "source_locale_links": one(
            """
            SELECT COUNT(*) FROM expression_locale_links x
            JOIN expression_sources s ON s.expression_id=x.expression_id
            WHERE s.source_id=?
            """,
            (source_id,),
        ),
        "source_edges": one(
            "SELECT COUNT(DISTINCT edge_id) FROM expression_edge_sources WHERE source_id=?",
            (source_id,),
        ),
        "source_edge_claims": one(
            "SELECT COUNT(*) FROM expression_edge_sources WHERE source_id=?", (source_id,)
        ),
        "users": one("SELECT COUNT(*) FROM users"),
        "handbook_rows": one("SELECT COUNT(*) FROM handbooks WHERE id=?", (HANDBOOK_ID,)),
        "handbook_sections": one(
            "SELECT COUNT(*) FROM handbook_sections WHERE handbook_id=?", (HANDBOOK_ID,)
        ),
        "handbook_items": one(
            """
            SELECT COUNT(*) FROM handbook_section_items i
            JOIN handbook_sections s ON s.id=i.section_id
            WHERE s.handbook_id=?
            """,
            (HANDBOOK_ID,),
        ),
        "orphan_expression_sources": one(
            """
            SELECT COUNT(*) FROM expression_sources s
            LEFT JOIN expressions e ON e.id=s.expression_id
            WHERE e.id IS NULL
            """
        ),
        "orphan_expression_locale_links": one(
            """
            SELECT COUNT(*) FROM expression_locale_links x
            LEFT JOIN expressions e ON e.id=x.expression_id
            LEFT JOIN language_locales l ON l.id=x.locale_id
            WHERE e.id IS NULL OR l.id IS NULL
            """
        ),
        "orphan_expression_edges": one(
            """
            SELECT COUNT(*) FROM expression_edges e
            LEFT JOIN expressions a ON a.id=e.expression_a_id
            LEFT JOIN expressions b ON b.id=e.expression_b_id
            WHERE a.id IS NULL OR b.id IS NULL
            """
        ),
        "orphan_handbook_items": one(
            """
            SELECT COUNT(*) FROM handbook_section_items i
            LEFT JOIN handbook_sections s ON s.id=i.section_id
            LEFT JOIN expressions e ON e.id=i.expression_id
            WHERE s.id IS NULL OR e.id IS NULL
            """
        ),
    }
    return counts


def _write_cte_batches(
    handle,
    columns: Sequence[str],
    rows: Sequence[Sequence[object]],
    statement: str,
    *,
    batch_size: int,
) -> None:
    if not rows:
        return
    names = ", ".join(f'"{column}"' for column in columns)
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row) + ")"
            for row in batch
        )
        handle.write(f"WITH rows({names}) AS (VALUES\n  {values}\n)\n{statement}\n")


def _export_delta(
    staging: Path,
    output: Path,
    data: RecoveryData,
    *,
    rows_per_insert: int = 100,
) -> dict[str, object]:
    connection = sqlite3.connect(staging, timeout=120)
    connection.row_factory = sqlite3.Row
    try:
        source_row = connection.execute(
            "SELECT id FROM sources WHERE type=? AND name=?",
            (SOURCE_TYPE, SOURCE_NAME),
        ).fetchone()
        if source_row is None:
            raise ValueError("recovery source is absent from staging")
        source_id = int(source_row[0])

        nodes = connection.execute(
            """
            WITH claimed AS (
              SELECT expression_id FROM expression_sources WHERE source_id=?
              UNION
              SELECT e.expression_a_id FROM expression_edges e
              JOIN expression_edge_sources s ON s.edge_id=e.id
              WHERE s.source_id=?
              UNION
              SELECT e.expression_b_id FROM expression_edges e
              JOIN expression_edge_sources s ON s.edge_id=e.id
              WHERE s.source_id=?
              UNION
              SELECT id FROM expressions WHERE source_id=?
            )
            SELECT e.id,l.code,e.text,e.homograph_index,e.pos_mask,e.created_by,e.created_at
            FROM claimed c
            JOIN expressions e ON e.id=c.expression_id
            JOIN languages l ON l.id=e.language_id
            ORDER BY l.code,e.text,e.homograph_index,e.id
            """,
            (source_id, source_id, source_id, source_id),
        ).fetchall()
        node_by_id = {int(row["id"]): row for row in nodes}
        claims = connection.execute(
            """
            SELECT e.id,l.code,e.text,e.homograph_index,s.source_marker
            FROM expression_sources s
            JOIN expressions e ON e.id=s.expression_id
            JOIN languages l ON l.id=e.language_id
            WHERE s.source_id=?
            ORDER BY l.code,e.text,e.homograph_index,s.source_marker
            """,
            (source_id,),
        ).fetchall()
        locale_links = connection.execute(
            """
            SELECT DISTINCT e.id,l.code,e.text,e.homograph_index,ll.code AS locale_code
            FROM expression_sources s
            JOIN expressions e ON e.id=s.expression_id
            JOIN languages l ON l.id=e.language_id
            JOIN expression_locale_links x ON x.expression_id=e.id
            JOIN language_locales ll ON ll.id=x.locale_id
            WHERE s.source_id=?
            ORDER BY l.code,e.text,e.homograph_index,ll.code
            """,
            (source_id,),
        ).fetchall()
        readings = connection.execute(
            """
            SELECT DISTINCT e.id,l.code,e.text,e.homograph_index,
                            ll.code AS locale_code,r.scheme,r.value
            FROM expression_readings r
            JOIN expressions e ON e.id=r.expression_id
            JOIN languages l ON l.id=e.language_id
            JOIN language_locales ll ON ll.id=r.locale_id
            WHERE r.source_id=?
            ORDER BY l.code,e.text,e.homograph_index,ll.code,r.scheme,r.value
            """,
            (source_id,),
        ).fetchall()
        edges = connection.execute(
            """
            SELECT DISTINCT e.id,e.expression_a_id,e.expression_b_id,
                            e.relation_mask,e.score
            FROM expression_edges e
            JOIN expression_edge_sources s ON s.edge_id=e.id
            WHERE s.source_id=?
            ORDER BY e.id
            """,
            (source_id,),
        ).fetchall()
        edge_markers = connection.execute(
            """
            SELECT s.edge_id,s.source_marker
            FROM expression_edge_sources s
            WHERE s.source_id=?
            ORDER BY s.edge_id,s.source_marker
            """,
            (source_id,),
        ).fetchall()
        markers_by_edge: dict[int, list[str]] = defaultdict(list)
        for row in edge_markers:
            markers_by_edge[int(row["edge_id"])].append(str(row["source_marker"]))

        handbook_sections = connection.execute(
            """
            SELECT id,position,title,parent_section_id
            FROM handbook_sections
            WHERE handbook_id=?
            ORDER BY position,id
            """,
            (HANDBOOK_ID,),
        ).fetchall()
        section_position_by_id = {
            int(row["id"]): int(row["position"]) for row in handbook_sections
        }
        handbook_items = connection.execute(
            """
            SELECT s.position AS section_position,i.position AS item_position,
                   l.code,e.text,e.homograph_index
            FROM handbook_section_items i
            JOIN handbook_sections s ON s.id=i.section_id
            JOIN expressions e ON e.id=i.expression_id
            JOIN languages l ON l.id=e.language_id
            WHERE s.handbook_id=?
            ORDER BY s.position,i.position
            """,
            (HANDBOOK_ID,),
        ).fetchall()
        users = connection.execute(
            """
            SELECT id,username,email,password_hash,role,email_verified,created_at,updated_at
            FROM users WHERE id IN ({}) ORDER BY id
            """.format(",".join("?" for _ in data.old_users)),
            [int(row.get("id") or 0) for row in data.old_users],
        ).fetchall()
        if len(users) != len(data.old_users):
            raise ValueError("staging user rows are incomplete")
        handbook = connection.execute(
            """
            SELECT h.id,h.user_id,h.title,h.visibility,h.status,ll.code,
                   h.score,h.created_at,h.updated_at
            FROM handbooks h
            LEFT JOIN language_locales ll ON ll.id=h.language_locale_id
            WHERE h.id=?
            """,
            (HANDBOOK_ID,),
        ).fetchone()
        if handbook is None or handbook[5] is None:
            raise ValueError("staging Jiazi handbook row is absent")

        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("w", encoding="utf-8") as handle:
            handle.write("PRAGMA foreign_keys=ON;\n")
            for row in users:
                handle.write(
                    "INSERT OR IGNORE INTO users "
                    "(id,username,email,password_hash,role,email_verified,created_at,updated_at) VALUES ("
                    + ",".join(_literal(row[index]) for index in range(8))
                    + ");\n"
                )
            handle.write(
                "INSERT OR IGNORE INTO sources(type,name) VALUES "
                f"({_literal(SOURCE_TYPE)},{_literal(SOURCE_NAME)});\n"
            )

            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "pos_mask", "created_by", "created_at"),
                [
                    (
                        row["code"],
                        row["text"],
                        row["homograph_index"],
                        row["pos_mask"],
                        row["created_by"],
                        row["created_at"],
                    )
                    for row in nodes
                ],
                """
                INSERT OR IGNORE INTO expressions
                  (language_id,text,homograph_index,pos_mask,source_id,created_by,created_at)
                SELECT l.id,r.text,r.homograph_index,r.pos_mask,s.id,r.created_by,r.created_at
                FROM rows r
                JOIN languages l ON l.code=r.language_code
                JOIN sources s ON s.type=%s AND s.name=%s;
                """ % (_literal(SOURCE_TYPE), _literal(SOURCE_NAME)),
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "source_marker"),
                [
                    (row["code"], row["text"], row["homograph_index"], row["source_marker"])
                    for row in claims
                ],
                """
                INSERT OR IGNORE INTO expression_sources
                  (expression_id,source_id,source_marker)
                SELECT e.id,s.id,r.source_marker
                FROM rows r
                JOIN languages l ON l.code=r.language_code
                JOIN expressions e ON e.language_id=l.id
                  AND e.text=r.text AND e.homograph_index=r.homograph_index
                JOIN sources s ON s.type=%s AND s.name=%s;
                """ % (_literal(SOURCE_TYPE), _literal(SOURCE_NAME)),
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code"),
                [
                    (row["code"], row["text"], row["homograph_index"], row["locale_code"])
                    for row in locale_links
                ],
                """
                INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id)
                SELECT e.id,ll.id
                FROM rows r
                JOIN languages l ON l.code=r.language_code
                JOIN expressions e ON e.language_id=l.id
                  AND e.text=r.text AND e.homograph_index=r.homograph_index
                JOIN language_locales ll ON ll.code=r.locale_code;
                """,
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code", "scheme", "value"),
                [
                    (
                        row["code"],
                        row["text"],
                        row["homograph_index"],
                        row["locale_code"],
                        row["scheme"],
                        row["value"],
                    )
                    for row in readings
                ],
                """
                INSERT OR IGNORE INTO expression_readings
                  (expression_id,locale_id,scheme,value,source_id)
                SELECT e.id,ll.id,r.scheme,r.value,s.id
                FROM rows r
                JOIN languages l ON l.code=r.language_code
                JOIN expressions e ON e.language_id=l.id
                  AND e.text=r.text AND e.homograph_index=r.homograph_index
                JOIN language_locales ll ON ll.code=r.locale_code
                JOIN sources s ON s.type=%s AND s.name=%s;
                """ % (_literal(SOURCE_TYPE), _literal(SOURCE_NAME)),
                batch_size=rows_per_insert,
            )

            edge_rows = []
            for row in edges:
                a = node_by_id[int(row["expression_a_id"])]
                b = node_by_id[int(row["expression_b_id"])]
                edge_rows.append(
                    (
                        a["code"],
                        a["text"],
                        a["homograph_index"],
                        b["code"],
                        b["text"],
                        b["homograph_index"],
                        row["relation_mask"],
                        row["score"],
                    )
                )
            edge_insert = """
                INSERT OR IGNORE INTO expression_edges
                  (expression_a_id,expression_b_id,relation_mask,score)
                SELECT DISTINCT
                  CASE WHEN a.id<b.id THEN a.id ELSE b.id END,
                  CASE WHEN a.id<b.id THEN b.id ELSE a.id END,
                  r.relation_mask,r.score
                FROM rows r
                JOIN languages al ON al.code=r.a_language_code
                JOIN expressions a ON a.language_id=al.id
                  AND a.text=r.a_text AND a.homograph_index=r.a_homograph_index
                JOIN languages bl ON bl.code=r.b_language_code
                JOIN expressions b ON b.language_id=bl.id
                  AND b.text=r.b_text AND b.homograph_index=r.b_homograph_index;
                """
            _write_cte_batches(
                handle,
                (
                    "a_language_code",
                    "a_text",
                    "a_homograph_index",
                    "b_language_code",
                    "b_text",
                    "b_homograph_index",
                    "relation_mask",
                    "score",
                ),
                edge_rows,
                edge_insert,
                batch_size=rows_per_insert,
            )
            edge_source_rows = []
            for row in edges:
                a = node_by_id[int(row["expression_a_id"])]
                b = node_by_id[int(row["expression_b_id"])]
                for marker in markers_by_edge[int(row["id"])]:
                    edge_source_rows.append(
                        (
                            a["code"],
                            a["text"],
                            a["homograph_index"],
                            b["code"],
                            b["text"],
                            b["homograph_index"],
                            marker,
                        )
                    )
            edge_source_insert = """
                INSERT OR IGNORE INTO expression_edge_sources
                  (edge_id,source_id,source_marker)
                SELECT e.id,s.id,r.source_marker
                FROM rows r
                JOIN languages al ON al.code=r.a_language_code
                JOIN expressions a ON a.language_id=al.id
                  AND a.text=r.a_text AND a.homograph_index=r.a_homograph_index
                JOIN languages bl ON bl.code=r.b_language_code
                JOIN expressions b ON b.language_id=bl.id
                  AND b.text=r.b_text AND b.homograph_index=r.b_homograph_index
                JOIN expression_edges e ON e.expression_a_id=CASE WHEN a.id<b.id THEN a.id ELSE b.id END
                  AND e.expression_b_id=CASE WHEN a.id<b.id THEN b.id ELSE a.id END
                JOIN sources s ON s.type=%s AND s.name=%s;
                """ % (_literal(SOURCE_TYPE), _literal(SOURCE_NAME))
            _write_cte_batches(
                handle,
                (
                    "a_language_code",
                    "a_text",
                    "a_homograph_index",
                    "b_language_code",
                    "b_text",
                    "b_homograph_index",
                    "source_marker",
                ),
                edge_source_rows,
                edge_source_insert,
                batch_size=rows_per_insert,
            )

            handle.write(
                "WITH handbook_row(id,user_id,title,visibility,status,language_locale_code,score,created_at,updated_at) AS (VALUES ("
                + ",".join(_literal(handbook[index]) for index in range(9))
                + "))\n"
                "INSERT OR IGNORE INTO handbooks "
                "(id,user_id,title,visibility,status,language_locale_id,score,created_at,updated_at) "
                "SELECT h.id,h.user_id,h.title,h.visibility,h.status,ll.id,h.score,h.created_at,h.updated_at "
                "FROM handbook_row h JOIN language_locales ll ON ll.code=h.language_locale_code;\n"
            )
            section_rows = [
                (int(row["position"]), row["title"]) for row in handbook_sections
            ]
            _write_cte_batches(
                handle,
                ("position", "title"),
                section_rows,
                f"""
                INSERT OR IGNORE INTO handbook_sections
                  (handbook_id,title,position,parent_section_id)
                SELECT {HANDBOOK_ID},r.title,r.position,NULL FROM rows r;
                """,
                batch_size=rows_per_insert,
            )
            for row in handbook_sections:
                if row["parent_section_id"] is None:
                    continue
                parent_position = section_position_by_id[int(row["parent_section_id"])]
                handle.write(
                    "UPDATE handbook_sections SET parent_section_id=("
                    "SELECT id FROM handbook_sections WHERE handbook_id=%d AND position=%d) "
                    "WHERE handbook_id=%d AND position=%d;\n"
                    % (HANDBOOK_ID, parent_position, HANDBOOK_ID, int(row["position"]))
                )
            item_rows = [
                (
                    int(row["section_position"]),
                    int(row["item_position"]),
                    row["code"],
                    row["text"],
                    row["homograph_index"],
                )
                for row in handbook_items
            ]
            _write_cte_batches(
                handle,
                (
                    "section_position",
                    "item_position",
                    "language_code",
                    "text",
                    "homograph_index",
                ),
                item_rows,
                f"""
                INSERT OR IGNORE INTO handbook_section_items
                  (section_id,position,expression_id)
                SELECT s.id,r.item_position,e.id
                FROM rows r
                JOIN handbook_sections s ON s.handbook_id={HANDBOOK_ID}
                  AND s.position=r.section_position
                JOIN languages l ON l.code=r.language_code
                JOIN expressions e ON e.language_id=l.id
                  AND e.text=r.text AND e.homograph_index=r.homograph_index;
                """,
                batch_size=rows_per_insert,
            )

        counts = {
            "users": len(users),
            "nodes": len(nodes),
            "expression_claims": len(claims),
            "locale_links": len(locale_links),
            "readings": len(readings),
            "edges": len(edges),
            "edge_source_claims": len(edge_markers),
            "handbook_sections": len(handbook_sections),
            "handbook_items": len(handbook_items),
            "source_type": SOURCE_TYPE,
            "source_name": SOURCE_NAME,
        }
        return counts
    finally:
        connection.close()


def _write_report(path: Path, report: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path(__file__).resolve().parents[3] / "scripts" / "v2",
    )
    parser.add_argument("--staging", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--rows-per-insert", type=int, default=100)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.rows_per_insert < 1:
        raise SystemExit("--rows-per-insert must be positive")
    source_dir = args.source_dir.resolve()
    staging = args.staging.resolve()
    output = args.output.resolve()
    report_path = (args.report or output.with_suffix(".report.json")).resolve()
    if not staging.is_file():
        raise SystemExit(f"staging SQLite not found: {staging}")
    required = [
        "remote-users.sql",
        "remote-expressions.sql",
        "remote-expression_meaning.sql",
        "remote-handbooks.sql",
        "remote-handbook_pages.sql",
    ]
    missing = [str(source_dir / name) for name in required if not (source_dir / name).is_file()]
    if missing:
        raise SystemExit("missing v1 source files: " + ", ".join(missing))
    try:
        inputs = _load_inputs(source_dir)
        data = _select_data(inputs)
        staging_counts = _stage_data(staging, data)
        delta_counts = _export_delta(
            staging,
            output,
            data,
            rows_per_insert=args.rows_per_insert,
        )
        report = {
            **data.report,
            "staging": staging_counts,
            "delta": {
                **delta_counts,
                "path": str(output),
                "sha256": _sha256(output),
                "bytes": output.stat().st_size,
                "mode": "split" if output.name.endswith(".split.sql") else "file",
            },
            "inputs": {
                name: {"path": str(source_dir / name), "sha256": _sha256(source_dir / name)}
                for name in required
            },
        }
        _write_report(report_path, report)
        print(json.dumps(report, ensure_ascii=False, sort_keys=True))
        return 0
    except (OSError, sqlite3.Error, ValueError, KeyError) as exc:
        print(f"selected recovery failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
