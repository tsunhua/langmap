"""Shared expression-text identity normalization for Python importers."""

from __future__ import annotations

import unicodedata


def canonicalize_expression_text(value: str) -> str:
    """Trim, NFC-normalize, and sentence-case expression text.

    The first cased character is uppercased and the remainder is lowercased.
    Scripts without case (for example Chinese, Japanese, and Thai) are left
    unchanged apart from trimming and NFC normalization.
    """

    normalized = unicodedata.normalize("NFC", value.strip())
    if not normalized:
        return normalized
    lowered = normalized.lower()
    characters = list(lowered)
    first_cased = next(
        (
            index
            for index, character in enumerate(characters)
            if character.lower() != character.upper()
        ),
        None,
    )
    if first_cased is None:
        return normalized
    characters[first_cased] = characters[first_cased].upper()
    return unicodedata.normalize("NFC", "".join(characters))
