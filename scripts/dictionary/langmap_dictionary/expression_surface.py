"""Conservative parsing helpers for publishable expression surfaces.

The structured dictionary exporters deliberately keep source values close to
the input.  This module is the small, source-agnostic boundary between those
values and the expression identity layer.  It does not infer a language or
rewrite case; callers still apply the existing identity canonicalizer.
"""

from __future__ import annotations

import re
import unicodedata


_CJK = re.compile(r"[\u2e80-\u9fff\uf900-\ufaff]")
_IPA_MARKERS = re.compile(
    r"[ːˈˌɐ-ʯɶ-ʸəɪɔʊɑɛɜɞɡɣɲŋʃʒʔʦʧʤ]"
)
_TERMINAL_ORPHAN_PUNCTUATION = ".．。,，"
_SENTENCE_END = ".．?!！？。"
_OPENING = "([{（［｛"
_QUOTE_OPENING = "“‘「『《〈"
_QUOTE_CLOSING = "”’」』》〉"
_QUOTE_PAIRS = {
    opening: closing for opening, closing in zip(_QUOTE_OPENING, _QUOTE_CLOSING)
}
# Some dictionaries use straight quotes and some Arabic/European sources use
# the typographic single quote in the reverse direction (``’text‘``).  Keep
# these as explicit pairs so punctuation inside a quoted turn is not treated
# as an expression boundary.
_QUOTE_PAIRS.update({
    '"': '"',
    "'": "'",
    "’": "‘",
    "«": "»",
    "»": "«",
})
_DIALOGUE_DASHES = "-‒–—―"
_LIST_MARKERS = "•‣▪"
_EMPTY_PLACEHOLDER = re.compile(r"(?<!\w)\[\s*\](?!\w)")
_BRACKET_NOTATION_WORDS = re.compile(
    r"(?:bracket|parenthes|ngoặc|kurung|括弧|括號|方括号|方括號|大括号|大括號)",
    re.IGNORECASE,
)
_NON_READING_PARENTHESES = frozenset({
    "formal", "informal", "polite", "colloquial", "literally", "lit",
    "optional", "preferred", "common", "only", "telephone", "coming",
    "through", "masc", "masc.", "fem", "fem.", "fresh",
})
_ANNOTATION_PREFIXES = (
    "only ", "coming through", "by telephone", "on the telephone",
    "at the telephone", "in writing", "spoken ", "used ", "usually ",
    "often ", "typically ", "for example", "e.g.", "figuratively",
    "regionally", "dialectally", "in this glossary", "in this dictionary",
    "getting ",
)
_LEXICAL_PARENTHESES_PREFIXES = frozenset({
    "by", "on", "at", "to", "for", "from", "in", "out", "off", "up",
    "away", "through", "over", "with", "without", "of",
})
_CLOSING = ")]}）］｝"
_TRANSFORMATION_ARROWS = ("⇒", "→")
_LEADING_ANNOTATION_PAIRS = {
    "《": "》",
    "〈": "〉",
    "〔": "〕",
    "［": "］",
    "『": "』",
}


def _quote_opening(value: str, index: int, quote_stack: list[tuple[str, int, bool]]) -> bool:
    """Return whether a quote-like character starts a quoted span."""

    character = value[index]
    previous = value[index - 1] if index else ""
    following = value[index + 1] if index + 1 < len(value) else ""
    if character == "'":
        # Apostrophes inside a word (``don't``) are not quote delimiters.
        if previous.isalnum() and following.isalnum():
            return False
        # A stray closing apostrophe after sentence punctuation is a layout
        # marker, not the beginning of a new quoted span.
        if previous in _SENTENCE_END and (not following or following.isspace()):
            return False
        # A bare contraction such as ``'ll``/``'d`` is a lexical surface, not
        # an unterminated quote.  There is no matching closing quote anyway;
        # treating it as ordinary punctuation lets the surface validator keep
        # the established form.
        if not quote_stack and index == 0 and value.strip() in {"'ll", "'d"}:
            return False
    return True


def _internal_apostrophe(value: str, index: int) -> bool:
    return (
        value[index] == "'"
        and index > 0
        and index + 1 < len(value)
        and value[index - 1].isalnum()
        and value[index + 1].isalnum()
    )


def _mismatched_ascii_quote_close(value: str, index: int, quote_stack: list[tuple[str, int, bool]]) -> bool:
    if not quote_stack or value[index] not in {"'", '"'} or _internal_apostrophe(value, index):
        return False
    following = value[index + 1] if index + 1 < len(value) else ""
    return not following or following.isspace() or following in _SENTENCE_END


def _strip_outer_wrappers(value: str) -> str:
    """Remove a balanced presentation wrapper around one expression.

    Source examples commonly arrive as ``[sentence]`` or ``‘sentence’``.
    A wrapper is removed only when its matching closer is the final
    non-whitespace character; this deliberately leaves a dialogue such as
    ``‘one?’ — ‘two!’`` intact for turn splitting.
    """

    candidate = value.strip()
    changed = True
    while changed and len(candidate) >= 2:
        changed = False
        opening = candidate[0]
        closing = {
            "(": ")", "[": "]", "{": "}", "（": "）", "［": "］", "｛": "｝",
            "“": "”", "‘": "’", "「": "」", "『": "』", "《": "》", "〈": "〉",
            "«": "»", "»": "«",
            '"': '"', "'": "'", "”": "“", "’": "‘",
        }.get(opening)
        if closing is None:
            break
        matched_edge = candidate[-1] == closing
        if not matched_edge:
            expected_closing = {
                "“": "”", "‘": "’", "”": "“", "’": "‘",
                "«": "»", "»": "«",
            }.get(opening)
            if expected_closing and expected_closing in candidate[1:-1]:
                break
            # Exported examples occasionally mix a typographic opening quote
            # with a straight closing apostrophe. Treat that pair as a
            # presentation shell when it is clearly at both edges.
            quote_chars = set(_QUOTE_PAIRS) | set(_QUOTE_PAIRS.values()) | {'"', "'"}
            if opening not in quote_chars or candidate[-1] not in quote_chars:
                break
            closing = candidate[-1]
        inner = candidate[1:-1].strip()
        if not inner or _is_literal_bracket_notation(candidate):
            break
        # If the same wrapper closes before the final character, the outer
        # pair is part of a multi-turn dialogue rather than a single shell.
        if opening in _QUOTE_PAIRS and matched_edge:
            if opening in {"“", "‘", "”", "’", "«", "»"} and any(
                character in {"'", '"'}
                and index > 0
                and index + 1 < len(inner)
                and inner[index - 1] in _SENTENCE_END
                and inner[index + 1].isspace()
                for index, character in enumerate(inner)
            ):
                break
            first_close = next(
                (
                    index
                    for index, character in enumerate(inner)
                    if character == closing
                    and not (closing == "'" and _internal_apostrophe(inner, index))
                ),
                -1,
            )
            if first_close >= 0:
                break
        elif not _balanced(inner):
            break
        candidate = inner
        changed = True
    return candidate


def _strip_leading_quoted_span(value: str) -> str:
    """Remove a quoted phrase followed by ordinary explanatory prose."""

    candidate = value.strip()
    if not candidate or candidate[0] not in _QUOTE_PAIRS:
        return candidate
    opening = candidate[0]
    closing = _QUOTE_PAIRS[opening]
    for index in range(1, len(candidate)):
        character = candidate[index]
        # A straight apostrophe inside a word is not a closing delimiter.
        if opening == "'" and character == "'":
            previous = candidate[index - 1] if index else ""
            following = candidate[index + 1] if index + 1 < len(candidate) else ""
            if previous.isalnum() and following.isalnum():
                continue
        if character == closing:
            remainder = candidate[index + 1 :].strip()
            if remainder:
                return f"{candidate[1:index].strip()} {remainder}".strip()
    return candidate


def _balanced(value: str) -> bool:
    pairs = {"(": ")", "[": "]", "{": "}", "（": "）", "［": "］", "｛": "｝"}
    stack: list[str] = []
    for character in value:
        if character in pairs:
            stack.append(pairs[character])
        elif character in pairs.values():
            if not stack or stack.pop() != character:
                return False
    return not stack


def _reading_body(body: str) -> bool:
    body = body.strip()
    if not body:
        return False
    if _IPA_MARKERS.search(body):
        return True
    # A slash-delimited single token at a phrase boundary is the common plain
    # romanization form (``word /pinyin/``).  Requiring a single token avoids
    # mistaking spaced alternatives for a reading block.
    return bool(re.fullmatch(r"[A-Za-zÀ-ÖØ-öø-ÿĀ-ſ0-9'’·.-]+", body))


def _surface_reading_body(body: str) -> bool:
    """Recognize a plain parenthetical respelling without stealing prose notes."""

    normalized = body.strip()
    if not _reading_body(normalized) or normalized.casefold() in _NON_READING_PARENTHESES:
        return False
    # Plain prose notes are normally space-delimited. A non-ASCII letter or a
    # respelling hyphen is enough evidence for compact forms such as
    # ``dauung-kưə`` while keeping ``Hello (formal)`` as an annotation.
    return any(ord(character) > 127 for character in normalized) or "-" in normalized


def _looks_like_mapping_annotation(body: str) -> bool:
    """Recognize explicit usage notes without stealing lexical complements.

    Dictionary sources use terminal parentheses for both kinds of content:
    ``Hello (only on the telephone)`` is a usage note, while ``intimidated
    (by)`` and ``new kid (on the block)`` are lexical phrases. The generic
    surface layer only moves a deliberately small set of note-shaped values;
    source adapters remain responsible for richer, source-specific markup.
    """

    normalized = re.sub(r"\s+", " ", body.strip()).casefold()
    if not normalized:
        return False
    if normalized in _NON_READING_PARENTHESES:
        return True
    if any(normalized.startswith(prefix) for prefix in _ANNOTATION_PREFIXES):
        return True
    if normalized.startswith(tuple(f"{prefix} " for prefix in _NON_READING_PARENTHESES)):
        return True
    first_word = normalized.split(" ", 1)[0]
    # A bare preposition or phrasal-verb particle is part of the expression;
    # do not turn it into a mapping note merely because it is parenthesized.
    return first_word not in _LEXICAL_PARENTHESES_PREFIXES and first_word in _NON_READING_PARENTHESES


def _is_literal_bracket_notation(value: str) -> bool:
    """Keep explanatory examples that literally name empty bracket forms."""

    if not _EMPTY_PLACEHOLDER.search(value):
        return False
    if _BRACKET_NOTATION_WORDS.search(value):
        return True
    compact = re.sub(r"\s+", "", value)
    return "()" in compact and "{}" in compact


def _reading_span(value: str, opening: int) -> int | None:
    if opening > 0 and value[opening - 1] not in " \t([{（［｛":
        return None
    closing = value.find("/", opening + 1)
    if closing < 0:
        return None
    body = value[opening + 1 : closing]
    if not _reading_body(body):
        return None
    after = value[closing + 1 :]
    if after and after[0] not in " \t,，.;:!?！？)]}）］｝":
        return None
    return closing


def _top_level_slashes(value: str) -> tuple[int, ...]:
    positions: list[int] = []
    depth = 0
    index = 0
    while index < len(value):
        character = value[index]
        if character in _OPENING:
            depth += 1
            index += 1
            continue
        if character in _CLOSING and depth:
            depth -= 1
            index += 1
            continue
        if character == "/" and depth == 0:
            closing = _reading_span(value, index)
            if closing is not None:
                index = closing + 1
                continue
            positions.append(index)
        index += 1
    return tuple(positions)


def _split_sentence_boundaries(value: str) -> tuple[str, ...]:
    """Split complete sentences while leaving notes and reading shells intact."""

    boundaries: list[int] = []
    depth = 0
    quote_stack: list[tuple[str, int, bool]] = []
    index = 0
    while index < len(value):
        character = value[index]
        if quote_stack and quote_stack[-1][0] == character and not _internal_apostrophe(value, index):
            _, opening_index, boundary_quote = quote_stack.pop()
            # A complete quoted turn at the beginning of a value is itself an
            # expression. Split after its closing quote when another token
            # follows, but do not split embedded quotations such as
            # ``狗“汪汪！”地叫了起来``.
            if (
                boundary_quote
            ):
                next_index = index + 1
                while next_index < len(value) and value[next_index].isspace():
                    next_index += 1
                previous_is_sentence_end = index > 0 and value[index - 1] in _SENTENCE_END + "…"
                next_is_quoted_segment = next_index < len(value) and value[next_index] in _QUOTE_PAIRS
                if (
                    next_index < len(value)
                    and value[next_index] not in _DIALOGUE_DASHES + ",;:；：、"
                    and (previous_is_sentence_end or next_is_quoted_segment)
                ):
                    boundaries.append(index + 1)
            index += 1
            continue
        if _mismatched_ascii_quote_close(value, index, quote_stack):
            quote_stack.pop()
            index += 1
            continue
        if character in _QUOTE_PAIRS and _quote_opening(value, index, quote_stack):
            boundary_quote = index == 0 or value[index - 1].isspace() or value[index - 1] in _DIALOGUE_DASHES + _OPENING
            quote_stack.append((_QUOTE_PAIRS[character], index, boundary_quote))
            index += 1
            continue
        if character in _OPENING:
            depth += 1
            index += 1
            continue
        if character in _CLOSING and depth:
            depth -= 1
            index += 1
            continue
        if character == "/" and depth == 0:
            closing = _reading_span(value, index)
            if closing is not None:
                index = closing + 1
                continue
        if character not in _SENTENCE_END or depth or quote_stack:
            index += 1
            continue
        # Keep ellipses and decimal numbers intact.  A slash immediately after
        # sentence punctuation is handled by the alternative splitter below.
        if character in ".．" and (
            (index > 0 and value[index - 1] in ".．")
            or (index + 1 < len(value) and value[index + 1] in ".．")
            or (index > 0 and index + 1 < len(value) and value[index - 1].isdigit() and value[index + 1].isdigit())
            # Periods between adjacent ASCII letters are abbreviations or
            # domain-like tokens (``A.A.``, ``U.S.``), not sentence ends.
            or (
                index > 0
                and index + 1 < len(value)
                and value[index - 1].isascii()
                and value[index + 1].isascii()
                and value[index - 1].isalnum()
                and value[index + 1].isalnum()
            )
        ):
            index += 1
            continue
        if character == "." and re.search(
            r"\b(?:vs|e\.g|i\.e|lit|dr|mr|mrs|ms|st)\.$",
            value[: index + 1],
            re.IGNORECASE,
        ):
            index += 1
            continue
        if character in ".．" and index + 1 < len(value) and value[index + 1] in _SENTENCE_END + ",，;；:：":
            # Dotted abbreviations (``a.m.?``/``p.m.,``) keep their internal
            # periods; the following question mark or comma is the boundary.
            index += 1
            continue
        next_index = index + 1
        while next_index < len(value) and value[next_index].isspace():
            next_index += 1
        if next_index < len(value) and value[next_index] not in _CLOSING + _OPENING + "'\"/":
            boundaries.append(index + 1)
        index += 1
    if not boundaries:
        return (value,)
    parts: list[str] = []
    start = 0
    for boundary in boundaries:
        part = value[start:boundary].strip()
        if part:
            parts.append(part)
        start = boundary
    final = value[start:].strip()
    if final:
        parts.append(final)
    return tuple(parts)


def _split_dialogue_segments(value: str) -> tuple[str, ...]:
    """Split a top-level dialogue at spaced em dashes.

    Bilingual sources often put two turns on one example row. The dash is a
    stronger alignment boundary than sentence punctuation because one side may
    contain an extra interjection that the other side translates inside the
    same turn.
    """

    parts: list[str] = []
    depth = 0
    quote_stack: list[tuple[str, int, bool]] = []
    start = 0
    index = 0
    while index < len(value):
        character = value[index]
        if quote_stack and quote_stack[-1][0] == character and not _internal_apostrophe(value, index):
            quote_stack.pop()
            index += 1
            continue
        if _mismatched_ascii_quote_close(value, index, quote_stack):
            quote_stack.pop()
            index += 1
            continue
        if character in _QUOTE_PAIRS and _quote_opening(value, index, quote_stack):
            quote_stack.append((_QUOTE_PAIRS[character], index, True))
            index += 1
            continue
        if character in _OPENING:
            depth += 1
            index += 1
            continue
        if character in _CLOSING and depth:
            depth -= 1
            index += 1
            continue
        if (
            character in _DIALOGUE_DASHES
            and depth == 0
            and index > 0
            and index + 1 < len(value)
            and (
                (
                    not quote_stack
                    and value[index - 1].isspace()
                    and value[index + 1].isspace()
                )
                or (
                    (
                        value[index - 1] in _QUOTE_CLOSING + "‘«»'\""
                        and (value[index + 1].isspace() or value[index + 1] in _QUOTE_PAIRS)
                    )
                    or (
                        value[index - 1].isspace()
                        and value[index + 1] in _QUOTE_PAIRS
                    )
                )
            )
        ):
            part = value[start:index].strip()
            if part:
                parts.append(part)
            start = index + 1
        index += 1
    tail = value[start:].strip()
    if tail:
        parts.append(tail)
    return tuple(parts) if len(parts) > 1 else (value,)


def _terminal_parenthetical(value: str) -> tuple[str, str] | None:
    if not _balanced(value):
        return None
    stripped = value.rstrip()
    if not stripped or stripped[-1] not in ")）":
        return None
    closing = len(stripped) - 1
    opening = "(" if stripped[closing] == ")" else "（"
    matching = ")" if opening == "(" else "）"
    depth = 0
    for index in range(closing, -1, -1):
        character = stripped[index]
        if character == matching:
            depth += 1
        elif character == opening:
            depth -= 1
            if depth == 0:
                return stripped[:index].rstrip(), stripped[index + 1 : closing].strip()
    return None


def normalize_expression_surface(value: str) -> str:
    """Trim source residue while retaining semantic ``?``/``!`` punctuation."""

    normalized = unicodedata.normalize("NFC", str(value)).strip()
    # Wikivoyage uses a leading ellipsis as a continuation marker (``...a
    # bathroom``), not as part of the expression identity.
    normalized = re.sub(r"^(?:\.{3}|…)+\s*", "", normalized)
    # Dialogue dashes are layout markers, not part of the lexical surface.
    # Keep this narrow: a dash without following whitespace/CJK remains
    # available for legitimate hyphenated or symbolic expressions.
    normalized = re.sub(
        r"^[\u2012\u2013\u2014\u2015\u2212\u2500\u2501―-]+(?:[ \t]+|(?=[\u2e80-\u9fff]))",
        "",
        normalized,
    )
    if not _is_literal_bracket_notation(normalized):
        normalized = _EMPTY_PLACEHOLDER.sub("", normalized)
    # Apple examples occasionally encode a quoted possessive as ``'H''s``;
    # collapse the doubled delimiter before sentence/turn splitting.
    normalized = re.sub(r"(?<=\w)''(?=\w)", "'", normalized)
    normalized = _strip_outer_wrappers(normalized)
    normalized = _strip_leading_quoted_span(normalized)
    # A few source rows use a typographic quote as a one-sided layout marker
    # around an example. Remove only those orphan edge markers; ordinary
    # straight apostrophes remain available for contractions such as ``'ll``.
    normalized = re.sub(r"^[‘’«]+(?=\w)", "", normalized)
    if normalized not in {"'ll", "'d"}:
        normalized = re.sub(r'''^[\'"](?=\w)''', "", normalized)
    normalized = re.sub(r"(?<=[\w!?！？。])['‘’»]+$", "", normalized)
    normalized = re.sub(r"\s{2,}", " ", normalized)
    normalized = re.sub(r"\s+([,，.;:])$", r"\1", normalized)
    normalized = normalized.rstrip(_TERMINAL_ORPHAN_PUNCTUATION).rstrip()
    return normalized


def _expand_cjk_parenthetical(value: str) -> tuple[str, ...] | None:
    """Expand compact CJK optional forms such as ``你（們）好``."""

    if not _balanced(value):
        return None
    for opening, closing in (("(", ")"), ("（", "）")):
        start = value.find(opening)
        if start < 0:
            continue
        end = value.find(closing, start + 1)
        if end < 0:
            return None
        content = value[start + 1 : end].strip()
        if not content or re.search(r"\s", content) or not _CJK.search(content):
            continue
        before, after = value[:start], value[end + 1 :]
        if not (_CJK.search(before) or _CJK.search(after)):
            continue
        # A CJK gloss inside an otherwise Latin sentence is explanatory
        # material (``wood （木）``), not an optional spelling.  Only expand
        # parentheticals whose surrounding lexical material is CJK-like; this
        # keeps compact forms such as ``你（們）好`` while leaving bilingual
        # prose intact.
        surrounding = before + after
        if any(
            unicodedata.category(character)[0] in {"L", "N"}
            and not _CJK.search(character)
            for character in surrounding
        ):
            continue
        return (
            normalize_expression_surface(before + after),
            normalize_expression_surface(before + content + after),
        )
    return None


def _expand_cjk_parentheticals(value: str) -> tuple[str, ...] | None:
    """Expand all compact CJK optional forms with a bounded breadth-first walk."""

    pending = [value]
    results: list[str] = []
    seen: set[str] = set()
    changed = False
    # A source value with more than five independent optional forms is almost
    # certainly explanatory prose.  Keep the expansion bounded so malformed
    # dictionary rows cannot create an exponential number of expressions.
    while pending and len(seen) < 64:
        candidate = pending.pop(0)
        if candidate in seen:
            continue
        seen.add(candidate)
        expanded = _expand_cjk_parenthetical(candidate)
        if expanded is None:
            results.append(candidate)
            continue
        changed = True
        pending.extend(expanded)
    if pending:
        # Preserve the original value if the safety bound was reached; callers
        # should not publish a partial optional-form expansion.
        return None
    if not changed:
        return None
    return tuple(dict.fromkeys(normalize_expression_surface(item) for item in results if item))


def split_expression_alternatives(value: str, *, _split_dialogue: bool = True) -> tuple[str, ...]:
    """Split only reliable top-level expression alternatives.

    Reading slash pairs, parenthetical notes, bracketed markup, URLs and other
    non-boundary slash uses remain in the original candidate.  A compact CJK
    optional form is expanded only when its content is itself CJK text.
    """

    original = unicodedata.normalize("NFC", str(value)).strip()
    original = re.sub(r"(?<=\w)''(?=\w)", "'", original)
    if not original or not _balanced(original):
        return (original,)
    if _split_dialogue:
        dialogue = _split_dialogue_segments(original)
        if len(dialogue) > 1:
            parts: list[str] = []
            for segment in dialogue:
                parts.extend(split_expression_alternatives(segment, _split_dialogue=False))
            return tuple(dict.fromkeys(part for part in parts if part)) or (original,)
    compact = _expand_cjk_parentheticals(original)
    if compact is not None:
        parts: list[str] = []
        for candidate in compact:
            parts.extend(
                normalize_expression_surface(part)
                for part in _split_sentence_boundaries(candidate)
                if normalize_expression_surface(part)
            )
        return tuple(dict.fromkeys(parts)) or (original,)
    positions = _top_level_slashes(original)
    if not positions:
        return tuple(
            normalize_expression_surface(part)
            for part in _split_sentence_boundaries(original)
            if normalize_expression_surface(part)
        ) or (original,)
    slash_parts: list[str] = []
    start = 0
    for position in positions:
        part = normalize_expression_surface(original[start:position])
        if part:
            slash_parts.append(part)
        start = position + 1
    final = normalize_expression_surface(original[start:])
    if final:
        slash_parts.append(final)
    parts: list[str] = []
    for slash_part in slash_parts:
        parts.extend(
            normalize_expression_surface(part)
            for part in _split_sentence_boundaries(slash_part)
            if normalize_expression_surface(part)
        )
    return tuple(dict.fromkeys(parts)) or (original,)


def extract_reading_parentheses(value: str) -> tuple[str, tuple[str, ...]]:
    """Remove terminal slash-delimited readings and return their values."""

    original = unicodedata.normalize("NFC", str(value)).strip()
    if not _balanced(original):
        return original, ()
    candidate = original
    readings: list[str] = []
    terminal = _terminal_parenthetical(candidate)
    if terminal is not None:
        prefix, body = terminal
        reading_shell = re.fullmatch(
            r"\s*(?:[,;:，；：、]\s*)?(?:/([^/]+)/\s*)+",
            body,
        )
        spans = re.findall(r"/([^/]+)/", body) if reading_shell else []
        if spans and all(_reading_body(span) for span in spans):
            readings.extend(span.strip() for span in spans)
            candidate = prefix
        elif _surface_reading_body(body):
            readings.append(body.strip())
            candidate = prefix
    # Also accept a reading shell directly after the expression.  This keeps
    # the helper useful for exporters that put ``word /reading/`` outside
    # parentheses while still rejecting ordinary ``word/foo`` alternatives.
    if not readings:
        match = re.search(r"(?:^|\s)/([^/]+)/\s*$", candidate)
        if match and _reading_body(match.group(1)):
            readings.append(match.group(1).strip())
            candidate = candidate[: match.start()].rstrip()
    return normalize_expression_surface(candidate), tuple(dict.fromkeys(readings))


def _extract_leading_annotation_groups(value: str) -> tuple[str, tuple[str, ...]]:
    """Move source-layout groups before a lexical surface into annotations.

    Apple bundles use corner and square brackets for usage frames, for example
    ``《속담》 Birds ...`` or ``［keep＋〈목〉］ 〈남을 위해〉 보존하다``.
    These groups describe the following expression; they are not part of the
    expression identity.  Only the explicit full-width/corner pairs are
    handled here so ordinary optional forms such as ``你（們）好`` remain
    alternatives.
    """

    candidate = str(value).strip()
    annotations: list[str] = []
    pairs = _LEADING_ANNOTATION_PAIRS
    while candidate:
        if candidate[0] == "[":
            # ASCII square labels in Apple equivalents are short usage or
            # register markers (``[U]``, ``[정치]``).  Do not consume prose
            # wrappers such as ``[A sample sentence]`` as annotations.
            match = re.match(r"^\[(?P<label>[^\[\]]{1,40})\](?P<gap>\s*)(?P<surface>.+)$", candidate)
            if match is None:
                break
            label = normalize_expression_surface(match.group("label"))
            if not label or (
                re.search(r"\s", label)
                and not any(
                    "\u3400" <= character <= "\u9fff"
                    or "\uac00" <= character <= "\ud7af"
                    for character in label
                )
            ):
                break
            annotations.append(label)
            candidate = match.group("surface").strip()
            continue
        if candidate[0] not in pairs:
            break
        stack: list[str] = []
        closing_index: int | None = None
        for index, character in enumerate(candidate):
            if character in pairs:
                stack.append(pairs[character])
            elif stack and character == stack[-1]:
                stack.pop()
                if not stack:
                    closing_index = index
                    break
            elif character in _CLOSING:
                break
        if closing_index is None:
            break
        content = candidate[1:closing_index].strip()
        remainder = candidate[closing_index + 1 :].strip()
        if content:
            annotations.append(re.sub(r"\s+", " ", content))
        if not remainder:
            return "", tuple(annotations)
        candidate = remainder
    return candidate, tuple(annotations)


def extract_mapping_annotation(value: str) -> tuple[str, str | None]:
    """Extract a bounded explanatory note from an expression value.

    Some bilingual dictionaries put a grammatical rewrite after an example,
    for example "She said ... then she said ...". The rewrite is explanatory
    metadata for the example mapping, not part of either expression surface.
    Keep the source side as the expression and attach the rewrite as an edge
    annotation. Only a single arrow with lexical text on both sides is treated
    this way so symbols in ordinary source text remain untouched.
    """

    original = unicodedata.normalize("NFC", str(value)).strip()
    surface, leading_annotations = _extract_leading_annotation_groups(original)
    if leading_annotations:
        if not surface:
            return "", "；".join(leading_annotations)
        cleaned, nested_annotation = extract_mapping_annotation(surface)
        annotations = [*leading_annotations]
        if nested_annotation:
            annotations.append(nested_annotation)
        return cleaned, "；".join(annotations)
    surface, _ = extract_reading_parentheses(original)
    if not surface:
        return "", None
    leading = re.match(
        r"^(?P<opener>[\(（])(?P<note>[^()（）]*)(?P<closer>[\)）])(?P<gap>\s*)(?P<expression>.+)$",
        surface,
    )
    if (
        leading is not None
        and not (leading.group("opener") == "（" and not leading.group("gap"))
        and _expand_cjk_parenthetical(surface) is None
    ):
        note = normalize_expression_surface(leading.group("note"))
        expression = normalize_expression_surface(leading.group("expression"))
        # Leading parentheticals in dictionary forms are labels or optional
        # grammatical material (``(public) health``, ``(the) least``), not
        # part of the expression surface. CJK optional forms are expanded
        # separately and must remain alternatives instead of annotations.
        if expression and note and _expand_cjk_parenthetical(surface) is None:
            return expression, note
    arrow_positions = [
        (surface.find(arrow), arrow)
        for arrow in _TRANSFORMATION_ARROWS
        if surface.find(arrow) >= 0
    ]
    arrow_count = sum(surface.count(arrow) for arrow in _TRANSFORMATION_ARROWS)
    if arrow_count == 1 and len(arrow_positions) == 1:
        position, arrow = arrow_positions[0]
        expression = normalize_expression_surface(surface[:position])
        annotation = normalize_expression_surface(surface[position + len(arrow):])
        if expression and annotation and any(
            unicodedata.category(character)[0] in {"L", "N"}
            for character in expression
        ) and any(
            unicodedata.category(character)[0] in {"L", "N"}
            for character in annotation
        ):
            return expression, f"rewrite: {annotation}"
    terminal = _terminal_parenthetical(surface)
    if terminal is None:
        return normalize_expression_surface(surface), None
    prefix, body = terminal
    if not body.strip(" /,;；、"):
        return normalize_expression_surface(prefix), None
    # A one-word note such as ``(polite)`` is lexically shaped like a plain
    # respelling, but it is still explanatory prose.  Use the stricter
    # respelling predicate here so known notes are moved to the mapping edge
    # instead of becoming part of the expression identity.
    if not body or _CJK.fullmatch(body) or _surface_reading_body(body):
        return normalize_expression_surface(surface), None
    # A compact CJK parenthetical is an alternative, not a prose annotation.
    if _expand_cjk_parenthetical(surface) is not None:
        return normalize_expression_surface(surface), None
    annotation = normalize_expression_surface(body).strip("()（）")
    expression = normalize_expression_surface(prefix)
    if not expression or not annotation:
        return normalize_expression_surface(surface), None
    if not _looks_like_mapping_annotation(annotation):
        return normalize_expression_surface(surface), None
    return expression, annotation


def prepare_expression_value(value: str) -> tuple[tuple[str, ...], tuple[str, ...], str | None]:
    """Return expression alternatives, extracted readings and one annotation."""

    surface, annotation = extract_mapping_annotation(value)
    _, readings = extract_reading_parentheses(value)
    alternatives = split_expression_alternatives(surface) if surface or annotation is None else ()
    return alternatives, readings, annotation


def prepare_paired_expression_values(
    left: str,
    right: str,
) -> tuple[
    tuple[str, ...],
    tuple[str, ...],
    str | None,
    tuple[str, ...],
    tuple[str, ...],
    str | None,
]:
    """Prepare translated examples without cross-pairing unequal splits.

    Dialogue turns separated by a top-level spaced dash are aligned first. If
    sentence or slash splitting still produces different counts on a turn, keep
    that turn as one expression on each side. Pairing by ordinal in that case
    can silently connect unrelated sentences from a dialogue.
    """

    left_surface, left_annotation = extract_mapping_annotation(left)
    _, left_readings = extract_reading_parentheses(left)
    right_surface, right_annotation = extract_mapping_annotation(right)
    _, right_readings = extract_reading_parentheses(right)
    left_dialogue = _split_dialogue_segments(left_surface)
    right_dialogue = _split_dialogue_segments(right_surface)
    if len(left_dialogue) == len(right_dialogue) and len(left_dialogue) > 1:
        paired_left: list[str] = []
        paired_right: list[str] = []
        for left_segment, right_segment in zip(left_dialogue, right_dialogue):
            left_segment_alternatives = split_expression_alternatives(left_segment)
            right_segment_alternatives = split_expression_alternatives(right_segment)
            if len(left_segment_alternatives) != len(right_segment_alternatives):
                left_segment_alternatives = (normalize_expression_surface(left_segment),)
                right_segment_alternatives = (normalize_expression_surface(right_segment),)
            paired_left.extend(left_segment_alternatives)
            paired_right.extend(right_segment_alternatives)
        if len(paired_left) == len(paired_right):
            return (
                tuple(paired_left),
                left_readings,
                left_annotation,
                tuple(paired_right),
                right_readings,
                right_annotation,
            )
    left_alternatives = split_expression_alternatives(left_surface)
    right_alternatives = split_expression_alternatives(right_surface)
    if len(left_alternatives) != len(right_alternatives):
        left_alternatives = (normalize_expression_surface(left_surface),) if left_surface else ()
        right_alternatives = (normalize_expression_surface(right_surface),) if right_surface else ()
    return (
        left_alternatives,
        left_readings,
        left_annotation,
        right_alternatives,
        right_readings,
        right_annotation,
    )


def surface_errors(value: str) -> tuple[str, ...]:
    """Return conservative quality errors without rejecting the raw value."""

    original = unicodedata.normalize("NFC", str(value)).strip()
    errors: list[str] = []
    if not _balanced(original):
        errors.append("malformed_surface")
    if _EMPTY_PLACEHOLDER.search(original) and not _is_literal_bracket_notation(original):
        errors.append("placeholder_surface")
    if re.fullmatch(r"/[^/]+/", original) and _reading_body(original[1:-1]):
        errors.append("reading_in_expression")
    reading_only = bool(re.fullmatch(r"/[^/]+/", original) and _reading_body(original[1:-1]))
    # Equivalence lists in Apple bundles use a leading bullet as a layout
    # marker.  The adapter removes it from the published surface, so validate
    # the payload after removing only that marker instead of quarantining an
    # otherwise valid expression as ``leading_punctuation``.
    quality_value = original
    cleaned_quality, leading_annotations = _extract_leading_annotation_groups(quality_value)
    if leading_annotations:
        quality_value = cleaned_quality
        if not quality_value:
            return ()
    if quality_value.startswith(tuple(_LIST_MARKERS)):
        quality_value = quality_value[1:].lstrip()
    normalized = normalize_expression_surface(quality_value)
    leading = re.match(
        r"^(?P<opener>[\(（])(?P<note>[^()（）]*)(?P<closer>[\)）])(?P<gap>\s*)(?P<expression>.+)$",
        normalized,
    )
    if (
        leading is not None
        and leading.group("note").strip()
        and not (leading.group("opener") == "（" and not leading.group("gap"))
        and _expand_cjk_parenthetical(original) is None
    ):
        normalized = normalize_expression_surface(leading.group("expression"))
    # Validate the cleaned alternatives as well as the raw shell. This catches
    # genuine punctuation-only rows while allowing quoted/bracketed examples
    # once their presentation wrappers have been removed.
    candidates = split_expression_alternatives(quality_value)
    if not candidates:
        candidates = (normalized,)
    candidate_values_list: list[str] = []
    for candidate in candidates:
        candidate_value = normalize_expression_surface(candidate)
        candidate_leading = re.match(
            r"^(?P<opener>[\(（])(?P<note>[^()（）]*)(?P<closer>[\)）])(?P<gap>\s*)(?P<expression>.+)$",
            candidate_value,
        )
        if (
            candidate_leading is not None
            and candidate_leading.group("note").strip()
            and not (candidate_leading.group("opener") == "（" and not candidate_leading.group("gap"))
            and _expand_cjk_parenthetical(candidate_value) is None
        ):
            candidate_value = normalize_expression_surface(candidate_leading.group("expression"))
        candidate_values_list.append(candidate_value)
    candidate_values = tuple(candidate_values_list)
    has_lexical_character = any(
        any(unicodedata.category(character)[0] in {"L", "N"} for character in candidate)
        for candidate in candidate_values
    )
    # A compact CJK optional form such as ``(心胸)寬廣`` is an input notation
    # for the alternatives ``寬廣`` and ``心胸寬廣``.  The adapter keeps those
    # alternatives and should not quarantine the original notation merely
    # because its opening parenthesis is punctuation.
    cjk_optional = _expand_cjk_parentheticals(original) is not None
    if not has_lexical_character and not _is_literal_bracket_notation(original):
        errors.append("punctuation_only")
    elif (
        not reading_only
        and not cjk_optional
        and any(
            candidate
            and not candidate.startswith("_")
            and candidate[0] not in "¡¿"
            and not (
                candidate[0] in "-‐‑‒–—―"
                and len(candidate) > 1
                and candidate[1].isalnum()
            )
            and not (
                candidate[0] == "#"
                and len(candidate) > 1
                and any(character.isalnum() for character in candidate[1:])
            )
            and candidate not in {"'ll", "'d"}
            and unicodedata.category(candidate[0]).startswith("P")
            for candidate in candidate_values
        )
    ):
        errors.append("leading_punctuation")
    return tuple(errors)


__all__ = [
    "extract_mapping_annotation",
    "extract_reading_parentheses",
    "normalize_expression_surface",
    "prepare_paired_expression_values",
    "prepare_expression_value",
    "surface_errors",
    "split_expression_alternatives",
]
