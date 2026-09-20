"""Shared expression-text identity normalization for LangMap writers."""

from __future__ import annotations

from dataclasses import dataclass
import unicodedata


class ExpressionTextIdentityError(ValueError):
    """Raised when non-lexical quotes or brackets remain unbalanced."""

    code = "UNBALANCED_DELIMITER"


@dataclass(frozen=True)
class _DelimiterFamily:
    name: str
    opening: str
    closing: str
    symmetric: bool = False


_DELIMITERS = (
    _DelimiterFamily("double_quote", '"', '"', True),
    _DelimiterFamily("ascii_apostrophe_quote", "'", "'", True),
    _DelimiterFamily("curly_double_quote", "“", "”"),
    _DelimiterFamily("curly_single_quote", "‘", "’"),
    _DelimiterFamily("cjk_corner_quote", "「", "」"),
    _DelimiterFamily("cjk_double_corner_quote", "『", "』"),
    _DelimiterFamily("parenthesis", "(", ")"),
    _DelimiterFamily("fullwidth_parenthesis", "（", "）"),
    _DelimiterFamily("square_bracket", "[", "]"),
    _DelimiterFamily("fullwidth_square_bracket", "【", "】"),
    _DelimiterFamily("brace", "{", "}"),
    _DelimiterFamily("angle_bracket", "〈", "〉"),
    _DelimiterFamily("double_angle_bracket", "《", "》"),
    _DelimiterFamily("tortoise_bracket", "〔", "〕"),
)
_BY_OPENING = {item.opening: item for item in _DELIMITERS if not item.symmetric}
_BY_CLOSING = {item.closing: item for item in _DELIMITERS if not item.symmetric}
_BY_SYMMETRIC = {item.opening: item for item in _DELIMITERS if item.symmetric}

_PERIODS = frozenset({".", "．", "。", "｡"})
_BOUNDARY_MARKS = frozenset(
    {
        *_PERIODS,
        ",",
        "，",
        "､",
        "!",
        "！",
        "?",
        "？",
        "、",
    }
)


@dataclass
class _DelimiterScan:
    matched: list[tuple[int, int, str]]
    unmatched: list[tuple[int, str]]


def _is_alphanumeric(character: str) -> bool:
    return character.isalnum()


def _is_lexical_apostrophe(characters: list[str], index: int) -> bool:
    if characters[index] not in {"'", "’"}:
        return False
    if index == 0 or index + 1 == len(characters):
        return False
    return (
        _is_alphanumeric(characters[index - 1])
        or _is_alphanumeric(characters[index + 1])
    )


def _scan_delimiters(characters: list[str]) -> _DelimiterScan:
    stack: list[tuple[str, int]] = []
    matched: list[tuple[int, int, str]] = []
    unmatched: list[tuple[int, str]] = []
    for index, character in enumerate(characters):
        if _is_lexical_apostrophe(characters, index):
            continue
        symmetric = _BY_SYMMETRIC.get(character)
        if symmetric is not None:
            if stack and stack[-1][0] == symmetric.name:
                _, opening_index = stack.pop()
                matched.append((opening_index, index, symmetric.name))
            else:
                stack.append((symmetric.name, index))
            continue
        opening = _BY_OPENING.get(character)
        if opening is not None:
            stack.append((opening.name, index))
            continue
        closing = _BY_CLOSING.get(character)
        if closing is not None:
            if stack and stack[-1][0] == closing.name:
                _, opening_index = stack.pop()
                matched.append((opening_index, index, closing.name))
            else:
                unmatched.append((index, closing.name))
    unmatched.extend((index, name) for name, index in stack)
    unmatched.sort()
    matched.sort()
    return _DelimiterScan(matched=matched, unmatched=unmatched)


def _all_cased_upper(characters: list[str]) -> bool:
    cased = [character for character in characters if character.lower() != character.upper()]
    return bool(cased) and all(character == character.upper() for character in cased)


def _ascii_period_run_length(characters: list[str], index: int) -> int:
    if characters[index] != ".":
        return 0
    start = index
    while start > 0 and characters[start - 1] == ".":
        start -= 1
    end = index + 1
    while end < len(characters) and characters[end] == ".":
        end += 1
    return end - start


def _strip_boundary_marks(characters: list[str]) -> tuple[list[str], bool]:
    changed = False
    preserve_periods = _all_cased_upper(characters)
    while characters:
        character = characters[0]
        if character not in _BOUNDARY_MARKS:
            break
        if character in _PERIODS and (
            preserve_periods
            or (character == "." and _ascii_period_run_length(characters, 0) >= 3)
        ):
            break
        characters.pop(0)
        changed = True
    while characters:
        index = len(characters) - 1
        character = characters[index]
        if character not in _BOUNDARY_MARKS:
            break
        if character in _PERIODS and (
            preserve_periods
            or (character == "." and _ascii_period_run_length(characters, index) >= 3)
        ):
            break
        characters.pop()
        changed = True
    return characters, changed


def _remove_outer_pair(characters: list[str], scan: _DelimiterScan) -> bool:
    if not characters:
        return False
    for opening_index, closing_index, _name in scan.matched:
        if opening_index == 0 and closing_index == len(characters) - 1:
            del characters[-1]
            del characters[0]
            return True
    return False


def _remove_boundary_orphan(characters: list[str], scan: _DelimiterScan) -> bool:
    for index, _name in scan.unmatched:
        if index == 0 or index == len(characters) - 1:
            del characters[index]
            return True
    return False


def _sentence_case(normalized: str) -> str:
    if not normalized:
        return normalized
    cased = [character for character in normalized if character.lower() != character.upper()]
    if cased and all(character == character.upper() for character in cased):
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
    return "".join(characters)


def canonicalize_expression_text(value: str) -> str:
    """Trim, NFC-normalize, remove safe boundary marks, and sentence-case text."""

    normalized = unicodedata.normalize("NFC", value.strip())
    if not normalized:
        return normalized
    characters = list(normalized)
    while characters:
        changed = False
        characters, marks_changed = _strip_boundary_marks(characters)
        changed = changed or marks_changed
        if not characters:
            return ""
        scan = _scan_delimiters(characters)
        if _remove_outer_pair(characters, scan):
            changed = True
        elif _remove_boundary_orphan(characters, scan):
            changed = True
        if not changed:
            break
        while characters and characters[0].isspace():
            characters.pop(0)
        while characters and characters[-1].isspace():
            characters.pop()
    if not characters:
        return ""
    if _scan_delimiters(characters).unmatched:
        raise ExpressionTextIdentityError("UNBALANCED_DELIMITER")
    normalized = "".join(characters).strip()
    if not normalized:
        return ""
    return unicodedata.normalize("NFC", _sentence_case(normalized))
