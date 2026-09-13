"""Conservative parser for phrase rows in pinned Wikivoyage wikitext."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from typing import Any, Iterable

from .catalog import PageProfile, SectionCatalog, resolve_section


_HEADING = re.compile(r"^\s*(={2,6})\s*(.*?)\s*\1\s*$")
_ITALIC = re.compile(r"(?<!')''(?!')(.+?)(?<!')''")
_TEMPLATE = re.compile(r"\{\{([^{}]*)\}\}")
_LINK = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")
_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)
_BRACKET_READING = re.compile(r"\[\s*['’]([^'’]+)['’]\s*\]")
_TARGET_CORE_RANGES = r"\u2e80-\u9fff\uf900-\ufaff\u3000-\u303f\uff00-\uffef"
_TARGET_SCRIPT_RANGES = _TARGET_CORE_RANGES + r".,!?;:"
_READING_CHARS = r"A-Za-z\u00c0-\u00ff\u0100-\u024f\u0300-\u036f"
# Wikivoyage uses underscore slots in both the target phrase and its inline
# respelling (for example ``过咗_____ Gwojó _____``).  Keep those slots in the
# reading value; they are positional placeholders, not expression text.
_READING_SLOT_CHARS = r" _\[\]{}…"
_INLINE_READING = re.compile(
    rf"^(?P<target>.*?[{_TARGET_SCRIPT_RANGES}][{_READING_SLOT_CHARS}-]*)"
    rf"(?:\s+|(?<=[.!?！？。])(?=[{_READING_CHARS}]))"
    rf"(?P<reading>[{_READING_CHARS}][{_READING_CHARS}0-9'’{_READING_SLOT_CHARS}.,/!?-]*)\s*$"
)
_INLINE_TOKEN = re.compile(
    rf"(?<=[{_TARGET_SCRIPT_RANGES}])\s+(?P<reading>[{_READING_CHARS}][{_READING_CHARS}0-9'’ .!?-]*?)"
    rf"(?=\s*(?:[,;/]|\(|$|[{_TARGET_CORE_RANGES}]))"
)
_CJK = re.compile(r"[\u2e80-\u9fff\uf900-\ufaff]")
_THAI = re.compile(r"[\u0e00-\u0e7f]")
_JAPANESE = re.compile(r"[\u3040-\u30ff\u31f0-\u31ff\u2e80-\u9fff\uf900-\ufaff]")
_KOREAN = re.compile(r"[\u1100-\u11ff\u3130-\u318f\uac00-\ud7af]")
_PLACEHOLDERS = frozenset({"", "-", "—", "…", "...", "n/a", "none", "tbd"})
_READING_NOTE_WORDS = frozenset({
    "formal", "informal", "polite", "colloquial", "literally", "lit", "example",
    "examples", "optional", "preferred", "common", "more", "often", "usually", "or",
})
_READING_PROSE_WORDS = frozenset({
    "a", "an", "and", "are", "but", "call", "common", "for", "in", "is", "it",
    "of", "on", "some", "term", "the", "to", "using", "waitress", "waiter", "would",
})
_TARGET_ANNOTATION_PREFIXES = (
    "example:", "e.g.", "in ", "when ", "from ", "means ", "used ",
    "usually ", "often ", "only ", "more commonly ",
)
_PLAIN_RESPelling_EXCLUSIONS = frozenset({
    "formal", "informal", "polite", "colloquial", "literally", "optional",
    "preferred", "common", "only", "telephone", "coming", "through",
})
_THAI_PRONOUNS = ("ผม", "ดิฉัน")
_THAI_POLITE_ENDINGS = ("ครับ", "ค่ะ", "คะ")
_GENDER_NOTE = re.compile(r"\s*\((?:masc(?:uline)?|fem(?:inine)?)\.?\)", re.IGNORECASE)


def _normalize_phrase_text(value: str) -> str:
    """Normalize phrase punctuation and discard layout-only prefixes."""

    text = canonicalize_text(value)
    # Wikivoyage uses a leading ellipsis to indicate an omitted context (for
    # example ``...a bathroom``). It is a layout cue, not part of the phrase
    # identity; keeping it creates a second, punctuation-prefixed expression.
    text = re.sub(r"^(?:\.{3}|…)+\s*", "", text)
    text = re.sub(r"^[—–‐‑‒―-]+\s+", "", text)
    # A full stop immediately before a parenthetical is sentence punctuation,
    # not part of the phrase. Keep the parenthetical itself for the English
    # side, where it often disambiguates register or place.
    text = re.sub(r"[.。](?=\s*[\(\[])", "", text)
    # Wikivoyage uses both ASCII and full-width sentence stops. Ellipses are
    # continuation layout markers, not part of a publishable expression.
    text = re.sub(r"\.+$", "", text)
    text = re.sub(r"。+$", "", text)
    text = re.sub(r"\s+([,;!?])", r"\1", text)
    return canonicalize_text(text)


def _looks_like_ipa_span(value: str, slash_position: int) -> bool:
    """Return whether a slash pair is phonetic notation, not a lexical slot."""

    # Lexical alternatives are written with spaces around the slash (``a / b``);
    # an IPA span always starts immediately after its opening delimiter.
    if slash_position + 1 >= len(value) or value[slash_position + 1].isspace():
        return False
    if slash_position > 0 and not value[slash_position - 1].isspace() and value[slash_position - 1] not in "([{<":
        return False
    closing = value.find("/", slash_position + 1)
    if closing < 0 or closing - slash_position > 48:
        return False
    body = value[slash_position + 1 : closing]
    # IPA spans contain at least one non-ASCII-letter phonetic symbol or a
    # length/stress marker. Plain `word/word` alternatives do not satisfy this.
    return bool(re.search(r"[ːˈˌɐ-ʯɶ-ʸəɪɔʊɑɛɜɞɡɣɲŋʃʒʔʦʧʤ.\[\]]", body))


def _ipa_reading_spans(value: str) -> tuple[str, ...]:
    """Extract every IPA slash pair without pairing neighbouring slashes."""

    readings: list[str] = []
    index = 0
    while index < len(value):
        if value[index] != "/" or not _looks_like_ipa_span(value, index):
            index += 1
            continue
        closing = value.find("/", index + 1)
        if closing < 0:
            break
        body = value[index + 1 : closing].strip(" .。;；/")
        if body:
            readings.append(body)
        index = closing + 1
    if not readings:
        # A few snapshot rows omit the closing slash but retain the terminal
        # parenthesis: ``phrase (..., /ˈipa/)`` becomes ``phrase (..., /ˈipa)``.
        # Only accept a final slash tail with unmistakable IPA symbols.
        match = re.search(r"/([^/]+)\s*\)?\s*$", value)
        if (
            match
            and (body := match.group(1).strip(" .。;；/()"))
            and not re.search(r"[\[\]{}'\"]", body)
            and _looks_like_ipa_span(f"/{body}/", 0)
        ):
            readings.append(body.strip(" .。;；/"))
    return tuple(dict.fromkeys(readings))


def _malformed_ipa_tail(value: str) -> str | None:
    """Recognize a final IPA token missing its opening slash."""

    match = re.search(r"(?:^|[,;]\s*|\s)(?P<body>[A-Za-zÀ-ÿːˈˌɐ-ʯɶ-ʸəɪɔʊɑɛɜɞɡɣɲŋʃʒʔʦʧʤ.]+)\s*/\s*$", value)
    if match is None:
        return None
    body = match.group("body").strip(" .。;；/")
    if not body or re.search(r"[\[\]{}'\"]", body):
        return None
    return body if _looks_like_ipa_span(f"/{body}/", 0) else None


def _slash_positions(value: str) -> tuple[int, ...]:
    """Find lexical slashes while ignoring notes, brackets and IPA spans."""

    positions: list[int] = []
    paren_depth = 0
    bracket_depth = 0
    ipa_closing: int | None = None
    for index, char in enumerate(value):
        if ipa_closing is not None:
            if index == ipa_closing:
                ipa_closing = None
            continue
        if char in "(（":
            paren_depth += 1
            continue
        if char in ")）" and paren_depth:
            paren_depth -= 1
            continue
        if char == "[":
            bracket_depth += 1
            continue
        if char == "]" and bracket_depth:
            bracket_depth -= 1
            continue
        if char != "/" or paren_depth or bracket_depth:
            continue
        if _looks_like_ipa_span(value, index):
            closing = value.find("/", index + 1)
            if closing >= 0:
                ipa_closing = closing
            continue
        positions.append(index)
    return tuple(positions)


def _dedupe_phrases(values: Iterable[str]) -> tuple[str, ...]:
    result: list[str] = []
    seen: set[str] = set()
    for value in values:
        normalized = _normalize_phrase_text(value)
        if not _valid_phrase(normalized):
            continue
        key = normalized.casefold()
        if key in seen:
            continue
        seen.add(key)
        result.append(normalized)
    return tuple(result)


def _last_word(value: str) -> str:
    words = re.findall(r"[^\s]+", value.rstrip())
    return words[-1] if words else ""


def _expand_embedded_slash(value: str, positions: tuple[int, ...]) -> tuple[str, ...] | None:
    """Expand one contiguous `word/word` group and preserve its context."""

    if not positions:
        return None
    first = positions[0]
    # Embedded groups are token alternatives with no whitespace next to the
    # slash. A whitespace gap starts another independent group (for example
    # `ผม/ดิฉัน ... ครับ/ค่ะ`).
    last_index = 0
    for index, position in enumerate(positions):
        if index and (
            any(char.isspace() for char in value[positions[index - 1] + 1 : position])
            or value[position - 1].isspace()
            or value[position + 1 : position + 2].isspace()
            or position - positions[index - 1] > 20
        ):
            break
        last_index = index
    group_positions = positions[: last_index + 1]
    last = group_positions[-1]
    if first == 0 or value[first - 1].isspace():
        start = first
    else:
        start = first
        while start > 0 and not value[start - 1].isspace() and value[start - 1] not in ",;!?。！？:：()[]":
            start -= 1
    end = last + 1
    while end < len(value) and value[end] != "/" and not value[end].isspace() and value[end] not in ",;!?。！？:：()[]":
        end += 1
    # Without an explicit word separator (for example in Thai), a slash group
    # is only safe when both sides have a visible phrase boundary. Otherwise we
    # leave the source row intact instead of manufacturing truncated phrases.
    if (start > 0 and not value[start - 1].isspace() and value[start - 1] not in ",;!?。！？:：()[]") or (
        end < len(value) and not value[end].isspace() and value[end] not in ",;!?。！？:：()[]"
    ):
        return None
    group = value[start:end]
    relative = [position - start for position in group_positions]
    pieces: list[str] = []
    piece_start = 0
    for position in relative:
        pieces.append(group[piece_start:position].strip())
        piece_start = position + 1
    pieces.append(group[piece_start:].strip())
    if any(not piece for piece in pieces):
        return None
    prefix = value[:start]
    suffix = value[end:]

    # French and similar phrasebooks abbreviate a shared connector as
    # `de chèvre/de brebis`. The connector appears before the first variant and
    # again at the start of the second piece; restore it once in each output.
    connector = pieces[-1]
    if len(pieces) == 2 and _last_word(prefix).casefold() == connector.casefold() and suffix.strip():
        base_prefix = prefix.rstrip()
        base_prefix = base_prefix[: -len(connector)].rstrip()
        separator = " " if prefix.endswith(" ") or base_prefix else ""
        return _dedupe_phrases(
            (
                f"{base_prefix}{separator}{connector} {pieces[0]}",
                f"{base_prefix}{separator}{connector} {suffix.strip()}",
            )
        )
    return _dedupe_phrases(tuple(f"{prefix}{piece}{suffix}" for piece in pieces))


def _spaced_group_parts(value: str, positions: tuple[int, ...]) -> tuple[str, str, tuple[str, ...]] | None:
    """Return context and pieces for a slash group separated by whitespace."""

    if not positions:
        return None
    first = positions[0]
    # Stop at sentence punctuation so a row containing two independent groups
    # is not collapsed into one enormous alternative chain.
    start = first
    while start > 0 and value[start - 1] not in ".!?。！？;；":
        start -= 1
    # A sentence stop immediately before the slash belongs to the first
    # alternative (`question? / yes / no`), so continue through it
    if start > 0 and value[start - 1] in ".!?。！？":
        start -= 1
        while start > 0 and value[start - 1] not in ".!?。！？;；":
            start -= 1
    last = positions[-1]
    end = last + 1
    while end < len(value) and value[end] not in ".!?。！？;；":
        end += 1
    if end < len(value) and value[end] in ".!?。！？":
        end += 1
    group = value[start:end]
    relative = [position - start for position in positions]
    pieces: list[str] = []
    piece_start = 0
    for position in relative:
        pieces.append(group[piece_start:position].strip())
        piece_start = position + 1
    pieces.append(group[piece_start:].strip())
    if any(not piece for piece in pieces):
        return None
    return value[:start], value[end:], tuple(pieces)


def _expand_spaced_group(value: str, positions: tuple[int, ...]) -> tuple[str, ...] | None:
    grouped = _spaced_group_parts(value, positions)
    if grouped is None:
        return None
    prefix, suffix, pieces = grouped
    if len(pieces) < 2:
        return None

    # If every alternative is a complete sentence (or carries an explicit
    # note), keep the pieces intact. Otherwise a short final piece commonly
    # supplies a shared suffix: `red / white wine` -> `red wine`, `white wine`.
    has_sentence_punctuation = any(re.search(r"[?！!。.]$", piece) for piece in pieces)
    has_note = any("(" in piece or ")" in piece for piece in pieces)
    token_counts = [len(piece.split()) for piece in pieces]
    if not has_sentence_punctuation and not has_note and token_counts[-1] > 1 and all(count == 1 for count in token_counts[:-1]):
        first_token = pieces[-1].split()[0]
        same_case_style = all(
            bool(piece[:1]) and piece[0].isupper() == first_token[0].isupper()
            for piece in pieces[:-1]
        )
        if not same_case_style:
            return _dedupe_phrases(tuple(f"{prefix}{piece}{suffix}" for piece in pieces))
        suffix_words = pieces[-1].split()[1:]
        shared_suffix = " " + " ".join(suffix_words) if suffix_words else ""
        pieces = (*pieces[:-1], pieces[-1].split()[0])
        return _dedupe_phrases(tuple(f"{prefix}{piece}{shared_suffix}{suffix}" for piece in pieces))

    # The same connector shorthand can occur with spaces around the slash.
    connector = pieces[-1].split()[0] if pieces[-1].split() else ""
    first_words = pieces[0].split()
    repeated_connector = (
        connector
        and (
            _last_word(pieces[0]).casefold() == connector.casefold()
            or (len(first_words) >= 2 and first_words[-2].casefold() == connector.casefold())
        )
    )
    if len(pieces) == 2 and repeated_connector:
        if first_words[-1].casefold() == connector.casefold():
            base = " ".join(first_words[:-1])
            first_variant = ""
        else:
            base = " ".join(first_words[:-2])
            first_variant = first_words[-1]
        return _dedupe_phrases(
            tuple(
                f"{prefix}{base} {connector} {variant}{suffix}"
                for variant in (first_variant, " ".join(pieces[1].split()[1:]))
                if variant
            )
        )
    return _dedupe_phrases(tuple(f"{prefix}{piece}{suffix}" for piece in pieces))


def _expand_thai_known_variants(value: str) -> tuple[str, ...]:
    """Resolve common Thai gender slots whose words are not space-delimited."""

    pronoun = "|".join(re.escape(item) for item in _THAI_PRONOUNS)
    ending = "|".join(re.escape(item) for item in _THAI_POLITE_ENDINGS)
    aligned = re.compile(
        rf"^(?P<prefix>.*?)(?P<p1>{pronoun})/(?P<p2>{pronoun})"
        rf"(?P<middle>.*?)(?P<e1>{ending})/(?P<e2>{ending})(?P<suffix>.*)$"
    )
    match = aligned.match(value)
    if match:
        groups = match.groupdict()
        return _dedupe_phrases(
            (
                f"{groups['prefix']}{groups['p1']}{groups['middle']}{groups['e1']}{groups['suffix']}",
                f"{groups['prefix']}{groups['p2']}{groups['middle']}{groups['e2']}{groups['suffix']}",
            )
        )

    # A slash immediately following a Thai pronoun or polite ending marks a
    # slot even when the following shared words have no whitespace
    slot = re.compile(rf"(?P<prefix>.*?)(?P<left>{pronoun}|{ending})/(?P<right>{pronoun}|{ending})(?P<suffix>.*)$")
    match = slot.match(value)
    if match:
        groups = match.groupdict()
        return _dedupe_phrases(
            (
                f"{groups['prefix']}{groups['left']}{groups['suffix']}",
                f"{groups['prefix']}{groups['right']}{groups['suffix']}",
            )
        )
    return (value,)


def _clean_portuguese_variant(value: str) -> str:
    """Remove Portuguese gender labels from the lexical surface."""

    # The page writes ``obrigado. (masc.)``. The full stop belongs to the
    # phrase boundary, while ``(masc.)`` is a grammatical label rather than
    # phrase text. Remove both before alternatives are aligned.
    cleaned = _GENDER_NOTE.sub("", value)
    return _normalize_phrase_text(cleaned)


def _split_portuguese_sentences(value: str) -> tuple[str, ...]:
    """Split adjacent Portuguese sentence phrases at top-level punctuation."""

    parts = re.split(r"(?<=[.!?])\s+(?=[A-ZÀ-ÖØ-Þ])", value)
    return tuple(_normalize_phrase_text(part) for part in parts if _valid_phrase(_normalize_phrase_text(part)))


def _expand_portuguese_variants(value: str) -> tuple[str, ...]:
    """Expand the reviewed Portuguese phrasebook's lexical alternatives.

    Portuguese rows combine two different notations: spaced slashes for full
    alternatives (``obrigado / obrigada``) and compact slashes for a shared
    context (``comboio/autocarro``). Treat the former as independent rows and
    delegate the latter to the existing context-preserving expander.
    """

    normalized = _clean_portuguese_variant(value)
    optional = re.match(r"^\((?P<option>[^()]*)\)\s+(?P<rest>.+)$", normalized)
    if optional is not None and optional.group("option").strip().casefold() not in {
        "masc.", "fem.", "formal", "informal"
    }:
        option = _normalize_phrase_text(optional.group("option"))
        rest = _normalize_phrase_text(optional.group("rest"))
        if option and rest:
            return _dedupe_phrases((rest, f"{option} {rest}"))
    positions = _slash_positions(normalized)
    if not positions:
        return _dedupe_phrases(_split_portuguese_sentences(normalized))
    spaced = tuple(
        position
        for position in positions
        if (position > 0 and normalized[position - 1].isspace())
        or (position + 1 < len(normalized) and normalized[position + 1].isspace())
        or (position > 0 and normalized[position - 1] in ".!?。！？")
    )
    if spaced:
        parts = _split_top_level_slashes(normalized)
        return _dedupe_phrases(
            sentence
            for part in parts
            for sentence in _split_portuguese_sentences(_clean_portuguese_variant(part))
        )
    embedded = _expand_embedded_slash(normalized, positions)
    if embedded is not None:
        return _dedupe_phrases(
            sentence
            for part in embedded
            for sentence in _split_portuguese_sentences(_clean_portuguese_variant(part))
        )
    return (normalized,)


def _split_top_level_commas(value: str) -> tuple[str, ...]:
    """Split a target-side alternatives list without breaking parenthetical notes."""

    parts: list[str] = []
    start = 0
    depth = 0
    for index, char in enumerate(value):
        if char in "(（":
            depth += 1
        elif char in ")）" and depth:
            depth -= 1
        elif char == "," and depth == 0:
            parts.append(value[start:index].strip())
            start = index + 1
    parts.append(value[start:].strip())
    return tuple(part for part in parts if part)


def _split_top_level_slashes(value: str) -> tuple[str, ...]:
    """Split a value at slashes outside notes and bracketed markup."""

    positions = _slash_positions(value)
    if not positions:
        return (value.strip(),)
    parts: list[str] = []
    start = 0
    for position in positions:
        parts.append(value[start:position].strip())
        start = position + 1
    parts.append(value[start:].strip())
    return tuple(part for part in parts if part)


def _chinese_locale_target_alternatives(
    value: str,
    readings: tuple[tuple[str, str], ...],
    locale_codes: tuple[str, ...],
) -> tuple[tuple[str, str, tuple[tuple[str, str], ...]], ...] | None:
    """Parse slash-separated Chinese target pairs without crossing row notes.

    A slash in a Chinese phrasebook row can separate complete lexical entries,
    but it can also occur inside a word, a reading, or explanatory prose. Only
    accept the former when every segment contains exactly one clean
    simplified/traditional pair and the readings have matching cardinality.
    """

    if len(locale_codes) < 2:
        return None
    parts = _split_top_level_slashes(value)
    if len(parts) < 2:
        return None
    parsed: list[tuple[str, str]] = []
    for part in parts:
        lexical = _ITALIC.sub("", part)
        lexical = _BRACKET_READING.sub("", lexical)
        pair = re.match(
            r"^\s*(?P<first>[^()（）]+?)\s*[\(（]\s*(?P<second>[^()（）]+?)\s*[\)）]",
            lexical,
        )
        if pair is None:
            return None
        first = _target_text(pair.group("first"), language_code="cmn")
        second = _target_text(pair.group("second"), language_code="cmn")
        if not first or not second or not _CJK.search(first) or not _CJK.search(second):
            return None
        remainder = f"{lexical[:pair.start()]} {lexical[pair.end():]}"
        # A Latin register/place note is safe; another target-script span
        # means the slash segment swallowed a second lexical phrase or prose.
        if _CJK.search(remainder):
            return None
        parsed.append((first, second))

    if readings and len(readings) not in {1, len(parsed)}:
        return None
    result: list[tuple[str, str, tuple[tuple[str, str], ...]]] = []
    for index, (first, second) in enumerate(parsed):
        segment_readings = readings
        if len(readings) == len(parsed) and len(readings) > 1:
            segment_readings = (readings[index],)
        result.extend(
            (
                (first, locale_codes[0], segment_readings),
                (second, locale_codes[1], segment_readings),
            )
        )
    return tuple(result)


def _spanish_target_variants(value: str) -> tuple[str, ...] | None:
    """Parse regional/gender alternatives used by the Spanish phrasebook.

    The page writes entries such as ``camarero/a (Spain), mesero/a ...``.
    Generic slash expansion treats the ``a`` suffix as a standalone phrase
    and also sees slash forms in the explanatory prose. Split the regional
    clauses first, remove their parenthetical labels, and expand the gender
    suffix as a lexical alternative.
    """

    clauses = _split_top_level_commas(value)
    if len(clauses) < 2 or not any(re.search(r"[A-Za-zÀ-ÿ]+/a(?=\W|$)", clause) for clause in clauses):
        return None
    variants: list[str] = []
    for clause in clauses:
        clause = re.sub(r"\s*\([^()]*\)\s*$", "", clause).strip(" .;；")
        if not clause:
            continue
        gender = re.match(r"^(?P<prefix>.*?)(?P<stem>[A-Za-zÀ-ÿ]+)/(?:a)(?P<suffix>[^A-Za-zÀ-ÿ]*)$", clause)
        if gender:
            prefix = gender.group("prefix")
            stem = gender.group("stem")
            suffix = gender.group("suffix")
            feminine = f"{stem[:-1]}a" if stem.casefold().endswith("o") else f"{stem}a"
            variants.extend((f"{prefix}{stem}{suffix}", f"{prefix}{feminine}{suffix}"))
        else:
            variants.append(clause)
    return _dedupe_phrases(variants) or None


def _trim_target_prose(value: str, language_code: str | None) -> str:
    """Remove narrowly recognized explanatory tails from reviewed rows."""

    if language_code == "cmn":
        # A second Chinese phrasebook alternative may be followed by an
        # Indonesia-specific parenthetical containing another target phrase.
        # It is prose, not a third lexical alternative.
        value = re.split(r"\s+\(In Indonesia\b", value, maxsplit=1, flags=re.IGNORECASE)[0]
    if language_code != "spa":
        return value
    # Keep the lexical sentence before a new English sentence such as
    # ``In some places ...``. The cue is deliberately narrow: a generic
    # period split would damage legitimate target phrases.
    return re.split(r"\.\s+(?=(?:In some places|You may simply)\b)", value, maxsplit=1, flags=re.IGNORECASE)[0]


def _chinese_example_parts(value: str, language_code: str | None) -> tuple[str, str] | None:
    """Extract the target example and English gloss from a grammar infobox row."""

    if language_code != "cmn":
        return None
    prefix = re.match(r"^\s*(?:Example|Exception)\s*[-:]\s*", value, flags=re.IGNORECASE)
    if prefix is None:
        return None
    body = value[prefix.end():]
    separator = re.search(r"\s+-\s+(?=[A-Za-zÀ-ÖØ-öø-ÿ])", body)
    if separator is None:
        return None
    target = body[:separator.start()].strip()
    english = clean_markup(body[separator.end():]).strip()
    if not _CJK.search(target) or not english:
        return None
    english = re.sub(r"\s*\((?:literally|lit\.)\b.*\)\s*$", "", english, flags=re.IGNORECASE).strip()
    return (target, english) if english else None


def _chinese_binary_question_target(value: str, language_code: str | None) -> str | None:
    """Combine a positive/negative Chinese pair into a yes-no phrase.

    Reviewed phrasebook rows such as ``是 ..., 不是 ...`` describe the
    repeated-verb question pattern. Keeping only the first comma clause turns
    the source into a misleading one-character expression, so combine the
    positive form with the negative form while preserving locale variants and
    their readings.
    """

    if language_code != "cmn":
        return None
    clauses = _split_top_level_commas(value)
    if len(clauses) != 2:
        return None

    locale_forms: list[tuple[str, ...]] = []
    readings: list[str] = []
    for clause in clauses:
        lexical = _ITALIC.sub("", clause)
        lexical = _BRACKET_READING.sub("", lexical)
        pair = re.match(
            r"^\s*(?P<first>[^()（）]+?)\s*[\(（]\s*(?P<second>[^()（）]+?)\s*[\)）]",
            lexical,
        )
        if pair and _CJK.search(pair.group("first")) and _CJK.search(pair.group("second")):
            forms = (
                _target_text(pair.group("first"), language_code=language_code),
                _target_text(pair.group("second"), language_code=language_code),
            )
        else:
            forms = (_target_text(clause, language_code=language_code),)
        if not forms or not all(_valid_phrase(form) for form in forms):
            return None
        locale_forms.append(forms)
        clause_readings = _reading_candidates(clause, language_code=language_code)
        if clause_readings:
            readings.append(clause_readings[0][0])

    if len(locale_forms[0]) != len(locale_forms[1]):
        return None
    if not all(
        any(second.startswith(marker) and second[len(marker):] == first for marker in ("不", "没", "沒"))
        for first, second in zip(locale_forms[0], locale_forms[1])
    ):
        return None

    combined = tuple(
        first + second
        for first, second in zip(locale_forms[0], locale_forms[1])
    )
    target_source = combined[0]
    if len(combined) > 1:
        target_source += f" ({combined[1]})"
    if readings:
        target_source += f" ''{' '.join(readings)}''"
    return target_source


def _expand_slash_variants(
    value: str,
    *,
    source_kind: str | None = None,
    language_code: str | None = None,
) -> tuple[str, ...]:
    """Expand lexical slash alternatives while retaining all non-slash text."""

    normalized = canonicalize_text(value)
    if source_kind == "ipa":
        return (_normalize_phrase_text(normalized),)
    if language_code == "por":
        return _expand_portuguese_variants(normalized)
    if language_code == "spa":
        spanish_variants = _spanish_target_variants(normalized)
        if spanish_variants is not None:
            return spanish_variants
    results = _expand_thai_known_variants(normalized) if language_code == "tha" else (normalized,)
    # Each pass expands the leftmost group. The small cap prevents malformed
    # wikitext from causing an unbounded Cartesian product.
    for _ in range(8):
        expanded: list[str] = []
        changed = False
        for item in results:
            positions = _slash_positions(item)
            if not positions:
                expanded.append(item)
                continue
            spaced_list = [
                position
                for position in positions
                if (position > 0 and item[position - 1].isspace())
                or (position + 1 < len(item) and item[position + 1].isspace())
                or (position > 0 and item[position - 1] in ".!?。！？")
            ]
            # Once a sentence-level slash starts a chain, subsequent compact
            # alternatives belong to that same chain (`question?/yes/no`).
            for previous, position in zip(positions, positions[1:]):
                if position in spaced_list:
                    continue
                if previous in spaced_list and not any(char in ".!?。！？;；" for char in item[previous + 1 : position]):
                    spaced_list.append(position)
            spaced = tuple(position for position in positions if position in spaced_list)
            variants = _expand_embedded_slash(item, tuple(position for position in positions if position not in spaced))
            if variants is None:
                variants = _expand_spaced_group(item, spaced)
            if variants is None:
                expanded.append(item)
            else:
                expanded.extend(variants)
                changed = True
        results = tuple(expanded)
        if not changed:
            break
    return _dedupe_phrases(results)


def _phrase_variant_pairs(
    english: tuple[str, ...],
    targets: tuple[str, ...],
) -> tuple[tuple[str, str, int], ...]:
    """Align equal-length alternatives and retain a target variant index."""

    if not english or not targets:
        return ()
    if len(english) == len(targets) and len(targets) > 1:
        return tuple((left, right, index) for index, (left, right) in enumerate(zip(english, targets)))
    if len(english) == 1:
        return tuple((english[0], target, index) for index, target in enumerate(targets))
    if len(targets) == 1:
        return tuple((left, targets[0], 0) for left in english)
    # Unequal alternative lists are ambiguous. Preserve all source material,
    # but cap the fallback to keep malformed rows from producing an explosion.
    return tuple(
        (left, right, target_index)
        for left in english
        for target_index, right in enumerate(targets)
    )[:64]


@dataclass(frozen=True)
class PageSnapshot:
    pageid: int
    title: str
    canonical_url: str
    revision: int
    revision_timestamp: str
    content: str
    content_sha256: str

    @classmethod
    def from_content(
        cls,
        *,
        pageid: int,
        title: str,
        canonical_url: str,
        revision: int,
        revision_timestamp: str,
        content: str,
    ) -> "PageSnapshot":
        return cls(pageid, title, canonical_url, revision, revision_timestamp, content, hashlib.sha256(content.encode("utf-8")).hexdigest())


@dataclass(frozen=True)
class PageParseResult:
    pageid: int
    title: str
    entries: tuple[dict[str, Any], ...]
    state: str
    diagnostics: tuple[dict[str, Any], ...] = ()


def canonicalize_text(value: str) -> str:
    return " ".join(str(value).replace("\u00a0", " ").split()).strip()


def _template_replace(match: re.Match[str]) -> str:
    body = match.group(1).strip(" .。;；/()")
    parts = [part.strip() for part in body.split("|")]
    if not parts:
        return ""
    name = parts[0].casefold()
    if name in {"lang", "rtl-lang", "small", "nowrap", "nobr", "g2", "transl"}:
        return parts[-1] if len(parts) > 1 else ""
    if name in {"ipa", "ipa-all", "pron", "pronunciation"}:
        return parts[-1] if len(parts) > 1 else ""
    if name in {"br", "break"}:
        return " / "
    # A template name is not a phrase. Keep a named positional value only when
    # it is clearly content, otherwise remove the display-only wrapper.
    return parts[1] if len(parts) > 1 and "=" not in parts[1] else ""


def clean_markup(value: str) -> str:
    """Remove display markup while leaving lexical punctuation and placeholders."""

    text = _COMMENT.sub("", str(value))
    for _ in range(6):
        updated = _TEMPLATE.sub(_template_replace, text)
        updated = _LINK.sub(lambda match: match.group(2) or match.group(1), updated)
        if updated == text:
            break
        text = updated
    text = re.sub(r"<br\s*/?>", " / ", text, flags=re.IGNORECASE)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.replace("&nbsp;", " ").replace("&ndash;", "–").replace("&mdash;", "—")
    text = text.replace("'''", "").replace("''", "")
    # Bracketed readings and infobox terminators can become visible after
    # their italic/template wrappers are removed. They are source markup, not
    # part of a phrase.
    text = re.sub(r"\[\s*\]", "", text)
    text = re.sub(r"\s*\}\}\s*$", "", text)
    return canonicalize_text(text)


def _terminal_parenthetical(value: str) -> tuple[str, str] | None:
    cleaned = clean_markup(value)
    stripped = cleaned.rstrip()
    if not stripped or stripped[-1] != ")":
        return None
    depth = 0
    for index in range(len(stripped) - 1, -1, -1):
        character = stripped[index]
        if character == ")":
            depth += 1
        elif character == "(":
            depth -= 1
            if depth == 0:
                return stripped[:index].strip(), stripped[index + 1 : -1].strip()
    return None


def _plain_respelling(body: str, language_code: str | None) -> bool:
    normalized = canonicalize_text(body).strip()
    if not normalized or normalized.casefold() in _PLAIN_RESPelling_EXCLUSIONS:
        return False
    if any(character.isspace() or not (character.isalnum() or character in "'’·.-") for character in normalized):
        return False
    if language_code in {None, "eng"}:
        return False
    # A target-script parenthetical is a lexical alternate (for example the
    # traditional form in ``厕所 (廁所)``), not a respelling.  Without this
    # guard it is promoted to a CJK "reading" and then quarantined as a
    # script mismatch, hiding the actual readings on the definition side.
    if _looks_like_target_script(normalized, language_code):
        return False
    return any(ord(character) > 127 for character in normalized) or "-" in normalized or "'" in normalized or "’" in normalized


def _looks_like_target_annotation(body: str, language_code: str | None) -> bool:
    """Recognize a prose note after a target phrase without stealing readings."""

    normalized = canonicalize_text(body)
    folded = normalized.casefold()
    if not normalized or _plain_respelling(normalized, language_code):
        return False
    if folded.startswith(_TARGET_ANNOTATION_PREFIXES):
        return True
    # Reviewed Wikivoyage rows sometimes explain a CJK word in a terminal note,
    # e.g. ``差佬 chāai lóu is in colloquial speech``.  A CJK span plus an
    # English prose cue is a note, not a lexical parenthetical or reading.
    if _looks_like_target_script(normalized, language_code) and re.search(
        r"\b(?:is|are|used|before|after|in|from|means|common|colloquial|vulgar)\b",
        folded,
    ):
        return True
    return False


def _split_target_annotation(value: str, language_code: str | None) -> tuple[str, str | None]:
    """Remove one terminal explanatory note and return its text separately."""

    terminal = _terminal_parenthetical(value)
    if terminal is None:
        return value, None
    prefix, body = terminal
    if not _looks_like_target_annotation(body, language_code):
        return value, None
    return prefix, canonicalize_text(body)


def _remove_inline_reading_parentheticals(
    value: str,
    language_code: str | None,
) -> tuple[str, tuple[str, ...]]:
    """Remove plain respelling shells embedded between a target and its reading."""

    readings: list[str] = []
    pieces: list[str] = []
    cursor = 0
    for match in re.finditer(r"\(([^()]*)\)", value):
        body = canonicalize_text(match.group(1))
        if not _plain_respelling(body, language_code):
            continue
        pieces.append(value[cursor:match.start()])
        pieces.append(" ")
        cursor = match.end()
        readings.append(body)
    if not readings:
        return value, ()
    pieces.append(value[cursor:])
    return canonicalize_text("".join(pieces)), tuple(dict.fromkeys(readings))


def _split_inline_reading_surface(
    value: str,
    language_code: str | None,
) -> tuple[str, tuple[tuple[str, str], ...]]:
    """Detach a complete target-plus-inline-reading tail before surface cleanup."""

    if language_code is None or not _looks_like_target_script(value, language_code):
        return value, ()
    inline = _INLINE_READING.match(canonicalize_text(value))
    if inline is None:
        return value, ()
    text = clean_markup(inline.group("reading")).strip(" .。;；/")
    if not _looks_like_reading(text, allow_long=True):
        return value, ()
    spaced_parts = _split_top_level_slashes(text) if " / " in text else (text,)
    if len(spaced_parts) > 1 and all(_looks_like_reading(part, allow_long=True) for part in spaced_parts):
        variants = _dedupe_phrases(spaced_parts)
    else:
        variants = _expand_slash_variants(text, source_kind="romanization")
    readings = tuple((variant, "inline") for variant in variants if variant and _looks_like_reading(variant, allow_long=True))
    return inline.group("target"), readings


def _strip_target_surface_shell(value: str, language_code: str | None) -> str:
    terminal = _terminal_parenthetical(value)
    if terminal is None:
        return value
    prefix, body = terminal
    if not body.strip(" /,;；、"):
        return prefix
    if _ipa_reading_spans(body) or _malformed_ipa_tail(body):
        return prefix
    spans = re.findall(r"/([^/]+)/", body)
    if spans and all(span.strip() for span in spans):
        return prefix
    if _plain_respelling(body, language_code):
        return prefix
    return value


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


def _strip_unbalanced_ipa_tail(value: str) -> str:
    """Drop a trailing IPA fragment when its surrounding shell is malformed."""

    if _balanced(value):
        terminal = _terminal_parenthetical(value)
        if terminal is None or re.search(r"/[^/]+/", terminal[1]):
            return value
        if "/" in terminal[1] and _ipa_reading_spans(terminal[1]):
            return terminal[0]
    matches = list(re.finditer(r"(?:,\s*)?/([^/]+)/\s*\)?\s*$", value))
    if not matches:
        matches = list(re.finditer(r"(?:,\s*)?/([^/]+)\s*\)?\s*$", value))
    if not matches:
        return value
    match = matches[-1]
    body = match.group(1)
    if re.search(r"[\[\]{}'\"]", body) or not _looks_like_ipa_span(f"/{body}/", 0):
        return value
    return value[: match.start()].rstrip(" ,(")


def _looks_like_reading(value: str, *, allow_long: bool = False) -> bool:
    """Reject prose annotations that happen to use italic markup."""

    text = canonicalize_text(value).strip(" .。;；/,")
    if not text or text.casefold() in _READING_NOTE_WORDS:
        return False
    if (not allow_long and len(text.split()) > 5) or any(char in text for char in '"“”():'):
        return False
    # Inline-reading detection runs across target-script boundaries. Without
    # this guard, an explanatory English tail such as ``it is common to call
    # a waitress ...`` can be mistaken for a long romanization.
    words = re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ]+", text.casefold())
    if len(words) >= 2 and sum(word in _READING_PROSE_WORDS for word in words) >= 2:
        return False
    return True


def _strip_outer_note(value: str) -> str:
    value = value.strip()
    while value.startswith("(") and value.endswith(")"):
        inner = value[1:-1].strip()
        if inner.count("(") != inner.count(")"):
            break
        value = inner
    return value


def _split_definition(line: str) -> tuple[str, str] | None:
    value = line.lstrip()
    if not value.startswith(";"):
        return None
    value = value[1:].strip()
    if not value:
        return None
    # Wikivoyage phrase rows use a spaced colon. Fall back to the first colon
    # for compact rows, but never treat a colon-less definition as bilingual.
    marker = value.find(" : ")
    width = 3
    if marker < 0:
        marker = value.find(":")
        width = 1
    if marker <= 0:
        return None
    left, right = value[:marker], value[marker + width:]
    if not left.strip() or not right.strip():
        return None
    return left.strip(), right.strip()


def _reading_candidates(value: str, *, language_code: str | None = None) -> tuple[tuple[str, str], ...]:
    candidates: list[tuple[int, str, str]] = []
    terminal = _terminal_parenthetical(value)
    if terminal is not None:
        target, body = terminal
        for reading in _ipa_reading_spans(body):
            candidates.append((value.rfind(reading), reading, "ipa"))
        malformed = _malformed_ipa_tail(body)
        if malformed:
            candidates.append((value.rfind(malformed), malformed, "ipa"))
        target_has_non_ascii = any(ord(character) > 127 for character in target)
        if _plain_respelling(body, language_code) and (_looks_like_target_script(target, language_code) or target_has_non_ascii):
            candidates.append((value.rfind(body), body, "romanization"))
    elif not _balanced(value):
        # A small number of rows have a missing opening parenthesis around the
        # final IPA (``phrase? ''respelling'', /.../)``). Keep the IPA as a
        # reading and let target cleanup remove the malformed shell.
        for reading in _ipa_reading_spans(value):
            candidates.append((value.rfind(reading), reading, "ipa"))
    for match in _ITALIC.finditer(value):
        text = clean_markup(match.group(1)).strip(" .。;；")
        for variant_index, variant in enumerate(_expand_slash_variants(text, source_kind="romanization")):
            if variant and variant.casefold() not in _PLACEHOLDERS and _looks_like_reading(variant):
                candidates.append((match.start(1) + variant_index, variant, "italic"))
    for match in _TEMPLATE.finditer(value):
        body = match.group(1)
        if body.split("|", 1)[0].strip().casefold() in {"ipa", "ipa-all"}:
            text = clean_markup(body.split("|", 1)[-1]).strip(" .。;；/")
            if text:
                for variant_index, variant in enumerate(_expand_slash_variants(text, source_kind="ipa")):
                    candidates.append((match.start(1) + variant_index, variant, "ipa"))
    for match in _BRACKET_READING.finditer(value):
        text = clean_markup(match.group(1)).strip(" .。;；/")
        for variant_index, variant in enumerate(_expand_slash_variants(text, source_kind="romanization")):
            if variant and variant.casefold() not in _PLACEHOLDERS and _looks_like_reading(variant):
                candidates.append((match.start(1) + variant_index, variant, "bracket"))
    target_script_value = language_code is not None and _looks_like_target_script(value, language_code)
    if target_script_value:
        inline = _INLINE_READING.match(canonicalize_text(value))
        if inline:
            text = clean_markup(inline.group("reading")).strip(" .。;；/")
            for variant_index, variant in enumerate(_expand_slash_variants(text, source_kind="romanization")):
                if variant and variant.casefold() not in _PLACEHOLDERS and _looks_like_reading(variant, allow_long=True):
                    candidates.append((inline.start("reading") + variant_index, variant, "inline"))
        for match in _INLINE_TOKEN.finditer(value):
            text = clean_markup(match.group("reading")).strip(" .。;；/,")
            for variant_index, variant in enumerate(_expand_slash_variants(text, source_kind="romanization")):
                if variant and variant.casefold() not in _PLACEHOLDERS and _looks_like_reading(variant, allow_long=True):
                    candidates.append((match.start("reading") + variant_index, variant, "inline"))
    candidates.sort(key=lambda item: (item[0], item[2], item[1]))
    seen: set[tuple[str, str]] = set()
    result: list[tuple[str, str]] = []
    for _position, text, scheme in candidates:
        item = (text, scheme)
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return tuple(result)


def _target_text(value: str, *, language_code: str | None = None) -> str:
    value = _trim_target_prose(value, language_code)
    value = _strip_unbalanced_ipa_tail(value)
    without_italics = _ITALIC.sub("", value)
    without_italics = _BRACKET_READING.sub("", without_italics)
    without_italics = _strip_target_surface_shell(without_italics, language_code)
    if language_code is not None and _looks_like_target_script(value, language_code):
        without_italics = _INLINE_TOKEN.sub(" ", without_italics)
        inline = _INLINE_READING.match(canonicalize_text(without_italics))
        if inline:
            without_italics = inline.group("target")
    # Parenthesized pronunciation notes can be left behind after removing
    # italics. Remove only empty shells (including ``(/)`` after a slash-
    # separated reading) and preserve real lexical parentheses.
    without_italics = re.sub(r"\(\s*\)", "", without_italics)
    without_italics = re.sub(r"\(\s*(?:[/|,;；、]\s*)+\)", "", without_italics)
    cleaned = clean_markup(without_italics).strip(" /,;；")
    # Some pages append an audio-player timestamp to the target cell rather
    # than keeping it in markup. It is metadata, not part of the expression.
    cleaned = re.sub(r"\s+\d{1,2}:\d{2}$", "", cleaned)
    # Parenthesized Latin notes describe usage rather than the target phrase.
    # Keep parentheticals that contain target-script characters (for example a
    # simplified/traditional pair), and remove only Latin-only notes.
    if language_code is not None and _looks_like_target_script(cleaned, language_code):
        cleaned = re.sub(
            r"\((?P<note>[^()]*?)\)",
            lambda match: ""
            if not _looks_like_target_script(match.group("note"), language_code)
            else match.group(0),
            cleaned,
        )
    cleaned = re.sub(r"\s+([,;!?])", r"\1", cleaned)
    return canonicalize_text(cleaned).strip(" /,;；")


def _looks_like_target_script(value: str, language_code: str | None) -> bool:
    """Return whether a value contains the reviewed page's target script."""

    if language_code in {"cmn", "yue"}:
        return bool(_CJK.search(value))
    if language_code == "jpn":
        return bool(_JAPANESE.search(value))
    if language_code == "kor":
        return bool(_KOREAN.search(value))
    if language_code == "tha":
        return bool(_THAI.search(value))
    # Preserve the original conservative behavior for an unlisted script.
    return bool(_CJK.search(value))


def _english_gloss(
    value: str,
    *,
    language_code: str | None,
    reading_values: Iterable[str] = (),
) -> str:
    """Extract a Latin parenthetical gloss from a reading-first row."""

    reading_keys = {canonicalize_text(item).casefold() for item in reading_values}
    candidates: list[str] = []
    for match in re.finditer(r"\(([^()]*)\)", clean_markup(value)):
        note = canonicalize_text(match.group(1)).strip(" .。;；/")
        if not note or _looks_like_target_script(note, language_code):
            continue
        if note.casefold() in reading_keys or note.casefold() in _READING_NOTE_WORDS:
            continue
        candidates.append(note)
    return candidates[-1] if candidates else ""


def _valid_phrase(value: str) -> bool:
    normalized = canonicalize_text(value).casefold()
    return bool(normalized) and normalized not in _PLACEHOLDERS


def _normalize_english_case(value: str) -> str:
    """Use sentence case for all-caps English phrases, preserving acronyms."""

    normalized = canonicalize_text(value)
    tokens = re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ]+", normalized)
    if not tokens or not all(token.isupper() for token in tokens):
        return normalized
    # Keep compact, punctuation-bound abbreviations such as ``ATM`` and
    # ``O.K``. A multi-word phrase is lexical even when every word is short
    # (for example ``ONE WAY``) and should still become sentence case.
    if (
        not any(character.isspace() for character in normalized)
        and all(len(token) <= 3 for token in tokens)
    ):
        return normalized
    lowered = normalized.lower()
    first = next((index for index, character in enumerate(lowered) if character.isalpha()), None)
    if first is None:
        return normalized
    return lowered[:first] + lowered[first].upper() + lowered[first + 1:]


def _scheme_for(profile: PageProfile, ordinal: int, source_kind: str) -> str:
    if source_kind == "ipa":
        return "ipa"
    if ordinal < len(profile.reading_schemes):
        return profile.reading_schemes[ordinal]
    if profile.reading_schemes:
        return profile.reading_schemes[-1]
    return "wikivoyage-romanization"


def _entry_fingerprint(record: dict[str, Any]) -> str:
    payload = dict(record)
    payload.pop("record_fingerprint", None)
    return hashlib.sha256(json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()


def _record(
    *,
    snapshot: PageSnapshot,
    profile: PageProfile,
    section_key: str,
    section_title: str,
    row_number: int,
    english: str,
    target: str,
    occurrence: int,
    target_locale: str | None,
    readings: Iterable[tuple[str, str]],
    target_annotation: str | None = None,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    english = _normalize_phrase_text(english)
    target = _normalize_phrase_text(target)
    entry_key = f"{snapshot.pageid}:{section_key}:{hashlib.sha256(english.encode('utf-8')).hexdigest()}:{occurrence}"
    pronunciation_rows: list[dict[str, Any]] = []
    diagnostics: list[dict[str, Any]] = []
    locale = target_locale if target_locale else (profile.locale_codes[0] if len(profile.locale_codes) == 1 else None)
    for ordinal, (reading, source_kind) in enumerate(readings, 1):
        scheme = _scheme_for(profile, ordinal - 1, source_kind)
        reading_locale = locale
        if source_kind == "ipa":
            scheme = "ipa"
        if _CJK.search(reading) and scheme in {
            "ipa",
            "hepburn",
            "pinyin",
            "jyutping",
            "tailo",
            "wikivoyage-romanization",
            "wikivoyage-respelling",
        }:
            diagnostics.append({"error_code": "reading_script_mismatch", "reading": reading, "scheme": scheme, "row": row_number})
            continue
        if reading.casefold() == target.casefold() or not _valid_phrase(reading):
            diagnostics.append({"error_code": "invalid_reading", "reading": reading, "row": row_number})
            continue
        pronunciation_rows.append({"value": reading, "scheme": scheme, "locale": reading_locale})
    raw_metadata: dict[str, Any] = {
        "pageid": snapshot.pageid,
        "title": snapshot.title,
        "revision": snapshot.revision,
        "revision_timestamp": snapshot.revision_timestamp,
        "canonical_url": snapshot.canonical_url,
        "section_key": section_key,
        "section_title": section_title,
        "row": row_number,
        "target_lang_code": profile.lang_code,
        "target_locale_code": locale,
        "source_marker": f"oldid:{snapshot.revision}#{section_key}/{row_number}",
    }
    if target_annotation:
        raw_metadata["target_annotation"] = target_annotation
    record: dict[str, Any] = {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": f"enwikivoyage:{snapshot.pageid}",
        "entry_key": entry_key,
        "record_fingerprint": "",
        "csv_row_number": row_number,
        "raw_headword": target,
        "canonical_headword": target,
        "homograph_marker": None,
        "direction_hint": f"{profile.lang_code or 'unknown'}-to-eng",
        "forms": [],
        "mappings": [],
        "pronunciations": pronunciation_rows,
        "senses": [{
            "sense_key": f"{entry_key}:sense:1",
            "ordinal": 1,
            "definitions": [],
            "pos": [],
            "equivalents": [{"value": english, "language": "eng", "locale": "eng-Latn-US"}],
            "relations": [],
            "examples": [],
            "labels": [],
        }],
        "diagnostics": diagnostics,
        "raw": raw_metadata,
    }
    record["record_fingerprint"] = _entry_fingerprint(record)
    return record, diagnostics


def parse_phrase_rows(wikitext: str, page: PageProfile, sections: SectionCatalog) -> PageParseResult:
    """Parse only explicit phrasebook rows for a reviewed page profile."""

    if page.status != "included":
        return PageParseResult(page.pageid, page.title, (), page.status, ({"reason": page.reason or page.status},))
    entries: list[dict[str, Any]] = []
    diagnostics: list[dict[str, Any]] = []
    current_key: str | None = None
    current_title = ""
    section_context: list[tuple[int, str, str | None]] = []
    in_infobox = False
    target_first_infobox = False
    target_first_infobox_titles = {
        canonicalize_text(title).casefold() for title in page.target_first_infoboxes
    }
    occurrence_by_english: dict[tuple[str, str], int] = {}
    pending_term: tuple[str, int, str] | None = None
    row_number = 0
    # A synthetic snapshot is replaced by export_page, which injects source
    # metadata after parsing. Keeping this function pure makes fixture tests
    # independent from the download filesystem.
    for line_number, raw_line in enumerate(str(wikitext).splitlines(), 1):
        line = raw_line.rstrip()
        heading = _HEADING.match(line)
        if heading:
            level = len(heading.group(1))
            heading_title = clean_markup(heading.group(2))
            section_context = [item for item in section_context if item[0] < level]
            resolved_key = resolve_section(heading_title, sections)
            section_context.append((level, heading_title, resolved_key))
            active = next(
                ((title, key) for _level, title, key in reversed(section_context) if key is not None),
                None,
            )
            if active is None:
                current_title = ""
                current_key = None
            else:
                current_title, current_key = active
            in_infobox = False
            target_first_infobox = False
            pending_term = None
            continue
        if line.lstrip().startswith("{{infobox"):
            in_infobox = True
            infobox_parts = line.lstrip().split("|", 1)
            infobox_title = infobox_parts[1].split("|", 1)[0] if len(infobox_parts) > 1 else ""
            target_first_infobox = canonicalize_text(clean_markup(infobox_title)).casefold() in target_first_infobox_titles
            continue
        if in_infobox:
            if "}}" in line:
                in_infobox = False
                target_first_infobox = False
            # Infobox prose is not a phrase row, but a few reviewed pages put
            # compact definition-list vocabulary inside the box. Let those
            # rows through while still ignoring all other explanatory text.
            if not line.lstrip().startswith(";") and not (
                pending_term is not None and line.lstrip().startswith(":")
            ):
                pending_term = None
                continue
        if current_key is None:
            continue
        source_line_number = line_number
        source_line = raw_line
        split = _split_definition(line)
        if split is None and pending_term is not None and line.lstrip().startswith(":"):
            definition = line.lstrip()[1:].strip()
            if definition:
                split = (pending_term[0], definition)
                source_line_number = pending_term[1]
                source_line = f"{pending_term[2]}\n{raw_line}"
            pending_term = None
        elif split is None and line.lstrip().startswith(";"):
            term = line.lstrip()[1:].strip()
            # Some reviewed pages use a two-line definition-list row:
            # ``;English phrase`` followed immediately by ``:target``.
            # Hold only this colon-less term; any other next line cancels it.
            pending_term = (term, line_number, raw_line) if term and ":" not in term else None
        else:
            pending_term = None
        if split is None:
            continue
        raw_left, raw_right = split
        # A small number of Wikivoyage sections use the target language as the
        # definition-list term and English as the definition. Detect this only
        # when the scripts make the direction unambiguous; do not infer from
        # title text or fuzzy language heuristics.
        left_markup = clean_markup(raw_left)
        right_markup = clean_markup(raw_right)
        left_readings = _reading_candidates(raw_left, language_code=page.lang_code)
        left_reading_text = canonicalize_text(left_markup).strip(" /,;；").casefold()
        explicit_reading_texts = {
            canonicalize_text(reading).strip(" /,;；").casefold()
            for reading, _scheme in left_readings
        }
        explicit_reading_texts.add(
            canonicalize_text(" / ".join(reading for reading, _scheme in left_readings)).casefold()
        )
        reading_first = bool(
            left_readings
            and any(scheme in {"italic", "bracket", "ipa"} for _reading, scheme in left_readings)
            and left_reading_text in explicit_reading_texts
            and not _looks_like_target_script(left_markup, page.lang_code)
            and _looks_like_target_script(right_markup, page.lang_code)
        )
        reversed_row = bool(
            not reading_first
            and (
                target_first_infobox
                or (
                    _looks_like_target_script(left_markup, page.lang_code)
                    and not _looks_like_target_script(right_markup, page.lang_code)
                )
            )
        )
        chinese_example = _chinese_example_parts(raw_right, page.lang_code)
        target_annotation: str | None = None
        if chinese_example:
            # Grammar infobox rows put the real target example and its English
            # gloss on the definition side; the left side is only a formula.
            target_source, english = chinese_example
            target = _target_text(target_source, language_code=page.lang_code)
            readings = _reading_candidates(target_source, language_code=page.lang_code)
            reading_first = False
            reversed_row = False
        elif reading_first:
            raw_english, raw_target = raw_right, raw_right
            target_source = _trim_target_prose(raw_target, page.lang_code)
            english = _english_gloss(
                raw_right,
                language_code=page.lang_code,
                reading_values=(reading for reading, _scheme in left_readings),
            )
            target = _target_text(target_source, language_code=page.lang_code)
            readings = left_readings
        elif reversed_row:
            raw_english, raw_target = raw_right, raw_left
            target_source = _trim_target_prose(raw_target, page.lang_code)
            english = _target_text(raw_english)
            target = _target_text(target_source, language_code=page.lang_code)
            readings = _reading_candidates(target_source, language_code=page.lang_code) or _reading_candidates(raw_right)
        else:
            raw_english, raw_target = raw_left, raw_right
            target_source = _chinese_binary_question_target(raw_target, page.lang_code) or _trim_target_prose(
                raw_target,
                page.lang_code,
            )
            english = clean_markup(raw_english)
            target = _target_text(target_source, language_code=page.lang_code)
            readings = _reading_candidates(target_source, language_code=page.lang_code)
        if page.lang_code == "yue":
            target_source, target_annotation = _split_target_annotation(target_source, page.lang_code)
            target_source, embedded_readings = _remove_inline_reading_parentheticals(target_source, page.lang_code)
            inline_match = _INLINE_READING.match(canonicalize_text(target_source))
            split_spaced_readings = bool(
                inline_match and " / " in inline_match.group("reading")
            )
            if target_annotation or embedded_readings or split_spaced_readings:
                target_source, inline_readings = _split_inline_reading_surface(target_source, page.lang_code)
            else:
                inline_readings = ()
        else:
            embedded_readings = ()
            inline_readings = ()
        target = _target_text(target_source, language_code=page.lang_code)
        embedded_reading_rows = tuple((value, "inline") for value in embedded_readings)
        readings = tuple(dict.fromkeys((*embedded_reading_rows, *inline_readings, *readings, *_reading_candidates(target_source, language_code=page.lang_code))))
        if reading_first and not _valid_phrase(english):
            diagnostics.append({"error_code": "missing_english_gloss", "line": source_line_number, "source_wikitext": source_line})
            continue
        if not _valid_phrase(english) or not _valid_phrase(target):
            diagnostics.append({"error_code": "empty_phrase_side", "line": source_line_number, "source_wikitext": source_line})
            continue

        # A reviewed split-by-locale profile (currently the Mandarin page)
        # may carry a simplified form followed by its traditional form. If a
        # row has no explicit pair, the same lexical form is linked to both
        # reviewed locales; this is safer than silently choosing one region.
        locale_targets: list[tuple[str, str | None, tuple[tuple[str, str], ...]]] = []
        if page.split_by_locale and len(page.locale_codes) >= 2:
            structured_targets = _chinese_locale_target_alternatives(
                target_source,
                readings,
                page.locale_codes,
            ) if page.lang_code == "cmn" else None
            if structured_targets is not None:
                locale_targets.extend(structured_targets)
            else:
                lexical = _ITALIC.sub("", target_source)
                lexical = _BRACKET_READING.sub("", lexical)
                pair = re.match(
                    r"^\s*(?P<first>[^()（）]+?)\s*[\(（]\s*(?P<second>[^()（）]+?)\s*[\)）]",
                    lexical,
                )
                if pair and _CJK.search(pair.group("first")) and _CJK.search(pair.group("second")):
                    locale_targets = [
                        (_target_text(pair.group("first"), language_code=page.lang_code), page.locale_codes[0], readings),
                        (_target_text(pair.group("second"), language_code=page.lang_code), page.locale_codes[1], readings),
                    ]
                else:
                    locale_targets = [
                        (target, page.locale_codes[0], readings),
                        (target, page.locale_codes[1], readings),
                    ]
        else:
            locale_targets = [(target, page.locale_codes[0] if len(page.locale_codes) == 1 else None, readings)]

        english_variants = tuple(
            _normalize_english_case(item) for item in _expand_slash_variants(english)
        )
        for target_base, target_locale, target_readings in locale_targets:
            target_variants = _expand_slash_variants(target_base, language_code=page.lang_code)
            if not target_variants or not all(_valid_phrase(item) for item in target_variants):
                diagnostics.append({"error_code": "empty_phrase_side", "line": source_line_number, "source_wikitext": source_line})
                continue
            for english_variant, target_variant, target_index in _phrase_variant_pairs(english_variants, target_variants):
                row_number += 1
                key = (current_key, english_variant.casefold())
                occurrence_by_english[key] = occurrence_by_english.get(key, 0) + 1
                # When the phrase and reading alternatives have matching
                # cardinality, preserve their one-to-one order. Otherwise all
                # readings remain attached to the expression.
                record_readings = target_readings
                if len(target_variants) > 1 and len(target_readings) == len(target_variants):
                    record_readings = (target_readings[target_index],)
                # The parser emits a provisional record; export_page supplies
                # the immutable page metadata and recalculates the fingerprint.
                provisional_snapshot = PageSnapshot.from_content(
                    pageid=page.pageid,
                    title=page.title,
                    canonical_url="",
                    revision=0,
                    revision_timestamp="",
                    content="",
                )
                record, row_diagnostics = _record(
                    snapshot=provisional_snapshot,
                    profile=page,
                    section_key=current_key,
                    section_title=current_title,
                    row_number=row_number,
                    english=english_variant,
                    target=target_variant,
                    occurrence=occurrence_by_english[key],
                    target_locale=target_locale,
                    readings=record_readings,
                    target_annotation=target_annotation,
                )
                record["raw"]["wikitext_line"] = source_line_number
                record["raw"]["source_wikitext"] = source_line
                record["raw"]["row_orientation"] = (
                    "reading-to-target-gloss"
                    if reading_first
                    else "target-to-english"
                    if reversed_row
                    else "english-to-target"
                )
                record["raw"]["source_marker"] = f"oldid:0#{current_key}/{row_number}"
                diagnostics.extend({**item, "line": line_number} for item in row_diagnostics)
                entries.append(record)
    state = "included" if entries else "empty"
    return PageParseResult(page.pageid, page.title, tuple(entries), state, tuple(diagnostics))


def export_page(snapshot: PageSnapshot, profile: PageProfile, sections: SectionCatalog) -> PageParseResult:
    parsed = parse_phrase_rows(snapshot.content, profile, sections)
    records: list[dict[str, Any]] = []
    for record in parsed.entries:
        record = json.loads(json.dumps(record, ensure_ascii=False))
        record["raw"].update({
            "canonical_url": snapshot.canonical_url,
            "revision": snapshot.revision,
            "revision_timestamp": snapshot.revision_timestamp,
        })
        # Rebuild the marker after injecting the actual revision and preserve
        # the source line/section metadata produced by the parser.
        record["raw"]["source_marker"] = f"oldid:{snapshot.revision}#{record['raw']['section_key']}/{record['raw']['row']}"
        record["record_fingerprint"] = _entry_fingerprint(record)
        records.append(record)
    return PageParseResult(parsed.pageid, parsed.title, tuple(records), parsed.state, parsed.diagnostics)
