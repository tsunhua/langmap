from __future__ import annotations

import sqlite3
from pathlib import Path

from scripts.wikivoyage.catalog import (
    load_page_catalog,
    load_section_catalog,
    profile_for,
    resolve_section,
    validate_registry,
)


ROOT = Path(__file__).parents[1]


def test_catalog_resolves_only_explicit_section_aliases() -> None:
    catalog = load_section_catalog(ROOT / "section-catalog.json")

    assert resolve_section("Basic phrases", catalog) == "basics"
    assert resolve_section("Basics for travelers", catalog) is None


def test_missing_page_profile_is_blocked_instead_of_guessed() -> None:
    catalog = load_page_catalog(ROOT / "page-catalog.json")

    profile = profile_for(999999, "Some language phrasebook", catalog)

    assert profile.status == "blocked"
    assert profile.reason == "missing_reviewed_page_profile"
    assert profile.lang_code is None


def test_registry_report_accounts_for_every_discovered_page() -> None:
    connection = sqlite3.connect(":memory:")
    connection.executescript("CREATE TABLE languages(code TEXT); CREATE TABLE language_locales(code TEXT);")
    connection.executemany("INSERT INTO languages(code) VALUES (?)", [("jpn",), ("eng",)])
    connection.executemany("INSERT INTO language_locales(code) VALUES (?)", [("jpn-Jpan-JP",)])
    catalog = load_page_catalog(ROOT / "page-catalog.json")

    report = validate_registry(connection, [(16153, "Japanese phrasebook"), (999999, "Unknown phrasebook")], catalog)

    assert [row.state for row in report.pages] == ["included", "blocked"]
    assert report.pages[1].reason == "missing_reviewed_page_profile"
    assert report.counts["included"] == 1
    assert report.counts["blocked"] == 1

