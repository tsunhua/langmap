from pathlib import Path

import pytest

from scripts.postgres.build_wikivoyage_handbook import (
    SectionCatalog,
    SectionProfile,
    _case_style_rank,
    _can_merge_case_variants,
    _ordered_sections,
    load_section_catalog,
)


def test_section_catalog_orders_only_discovered_included_sections(tmp_path: Path) -> None:
    path = tmp_path / "sections.json"
    path.write_text(
        '{"sections": [{"key": "later", "title": "Later", "position": 2}, '
        '{"key": "first", "title": "First", "position": 1}, '
        '{"key": "skip", "title": "Skip", "position": 3, "include": false}]}',
        encoding="utf-8",
    )

    catalog = load_section_catalog(path)

    assert _ordered_sections(catalog, {"later", "first"}) == [
        ("first", "First", 1),
        ("later", "Later", 2),
    ]


def test_unknown_section_fails_closed() -> None:
    catalog = SectionCatalog((SectionProfile("known", "Known", 1),))

    with pytest.raises(ValueError, match="outside the section catalog"):
        _ordered_sections(catalog, {"unknown"})


def test_sentence_case_is_required_before_casefold_deduplication() -> None:
    assert _case_style_rank("Closed") == 0
    assert _can_merge_case_variants([(1, 1, "CLOSED"), (2, 2, "Closed")])
    assert not _can_merge_case_variants([(1, 1, "US"), (2, 2, "us")])
