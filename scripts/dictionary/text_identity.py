"""Shared expression-text identity normalization for legacy audit helpers."""

from __future__ import annotations

import unicodedata


def canonicalize_expression_text(value: str) -> str:
    """Trim, NFC-normalize, and sentence-case expression text."""

    normalized = unicodedata.normalize("NFC", value.strip())
    if not normalized:
        return normalized
    cased = [character for character in normalized if character.lower() != character.upper()]
    if cased and all(character == character.upper() for character in cased):
        return normalized
    lowered = normalized.lower()
    first = next(
        (index for index, character in enumerate(lowered) if character.lower() != character.upper()),
        None,
    )
    if first is None:
        return normalized
    return unicodedata.normalize("NFC", lowered[:first] + lowered[first].upper() + lowered[first + 1 :])
