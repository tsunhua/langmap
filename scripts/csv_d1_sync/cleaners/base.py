from __future__ import annotations

import re
import unicodedata
from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path

VARIANT_SEPARATOR = " | "


@dataclass(frozen=True)
class CleanResult:
    headers: list[str]
    rows: list[dict[str, str]]
    source_rows: int


class CsvCleaner(ABC):
    name: str

    @abstractmethod
    def clean(self, source: Path) -> CleanResult:
        """把來源 CSV 轉成標準語言代碼表頭與內容。"""


def normalize_text(value: str | None) -> str:
    if not value:
        return ""
    text = unicodedata.normalize("NFC", value)
    text = text.replace("\ufeff", "").replace("\u200b", "")
    text = re.sub(r"\s+", " ", text).strip()
    return text.strip("€")


TRAILING_SUPPLEMENT = re.compile(
    r"\s*[(（]\s*(?:i\.?\s*e\.?|cf\.?)\s*[^()（）]*[)）]\s*$",
    re.IGNORECASE,
)


def remove_trailing_supplement(value: str) -> str:
    text = normalize_text(value)
    while TRAILING_SUPPLEMENT.search(text):
        text = TRAILING_SUPPLEMENT.sub("", text).rstrip()
    return text


def split_and_normalize(value: str | None, separator: str) -> list[str]:
    seen: set[str] = set()
    values: list[str] = []
    for piece in re.split(separator, value or ""):
        text = normalize_text(piece)
        if text and text not in seen:
            seen.add(text)
            values.append(text)
    return values


def join_variants(values: list[str]) -> str:
    return VARIANT_SEPARATOR.join(
        dict.fromkeys(value for value in values if value)
    )


def split_outside_parentheses(value: str | None, delimiters: str) -> list[str]:
    text = normalize_text(value)
    pieces: list[str] = []
    current: list[str] = []
    depth = 0
    for character in text:
        if character in "(（":
            depth += 1
        elif character in ")）" and depth:
            depth -= 1
        if depth == 0 and character in delimiters:
            piece = normalize_text("".join(current))
            if piece:
                pieces.append(piece)
            current = []
        else:
            current.append(character)
    piece = normalize_text("".join(current))
    if piece:
        pieces.append(piece)
    return list(dict.fromkeys(pieces))


PARENTHETICAL = re.compile(r"^(.*?)[(（]([^()（）]+)[)）](.*)$")


def expand_parenthetical_variants(value: str) -> list[str]:
    match = PARENTHETICAL.match(normalize_text(value))
    if not match:
        return [normalize_text(value)] if normalize_text(value) else []

    prefix, alternative, suffix = match.groups()
    outside = normalize_text(prefix + suffix)
    alternative = normalize_text(alternative)
    if not alternative:
        return [outside] if outside else []

    overlap = next(
        (
            size
            for size in range(min(len(prefix), len(alternative)), 0, -1)
            if prefix.endswith(alternative[:size])
        ),
        0,
    )
    if overlap:
        expanded = prefix[:-overlap] + alternative + suffix
    elif prefix:
        expanded = prefix[: -min(len(prefix), len(alternative))] + alternative + suffix
    else:
        expanded = alternative + suffix
    return list(
        dict.fromkeys(
            item
            for item in [outside, normalize_text(expanded)]
            if item
        )
    )
