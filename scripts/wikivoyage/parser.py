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
_INLINE_READING = re.compile(
    rf"^(?P<target>.*?[{_TARGET_SCRIPT_RANGES}])\s+"
    rf"(?P<reading>[{_READING_CHARS}][{_READING_CHARS}0-9'’ .,/!?-]*)\s*$"
)
_INLINE_TOKEN = re.compile(
    rf"(?<=[{_TARGET_SCRIPT_RANGES}])\s+(?P<reading>[{_READING_CHARS}][{_READING_CHARS}0-9'’ .!?-]*?)"
    rf"(?=\s*(?:[,;/]|\(|$|[{_TARGET_CORE_RANGES}]))"
)
_CJK = re.compile(r"[\u2e80-\u9fff\uf900-\ufaff]")
_PLACEHOLDERS = frozenset({"", "-", "—", "…", "...", "n/a", "none", "tbd"})
_READING_NOTE_WORDS = frozenset({
    "formal", "informal", "polite", "colloquial", "literally", "lit", "example",
    "examples", "optional", "preferred", "common", "more", "often", "usually", "or",
})
_THAI_PRONOUNS = ("ผม", "ดิฉัน")
_THAI_POLITE_ENDINGS = ("ครับ", "ค่ะ", "คะ")


def _normalize_phrase_text(value: str) -> str:
    """Normalize phrase punctuation without changing meaningful ellipses."""

    text = canonicalize_text(value)
    # A full stop immediately before a parenthetical is sentence punctuation,
    # not part of the phrase. Keep the parenthetical itself for the English
    # side, where it often disambiguates register or place.
    text = re.sub(r"[.。](?=\s*[\(\[])", "", text)
    # Wikivoyage uses both ASCII and full-width sentence stops. Do not turn the
    # placeholder/ellipsis `...` into an empty phrase.
    if not re.search(r"\.{3,}$", text):
        text = re.sub(r"\.+$", "", text)
    text = re.sub(r"。+$", "", text)
    return canonicalize_text(text)


def _looks_like_ipa_span(value: str, slash_position: int) -> bool:
    """Return whether a slash pair is phonetic notation, not a lexical slot."""

    if slash_position > 0 and not value[slash_position - 1].isspace() and value[slash_position - 1] not in "([{<":
        return False
    closing = value.find("/", slash_position + 1)
    if closing < 0 or closing - slash_position > 48:
        return False
    body = value[slash_position + 1 : closing]
    # IPA spans contain at least one non-ASCII-letter phonetic symbol or a
    # length/stress marker. Plain `word/word` alternatives do not satisfy this.
    return bool(re.search(r"[ːˈˌɐ-ʯɶ-ʸəɪɔʊɑɛɜɞɡɣɲŋʃʒʔʦʧʤ.\[\]]", body))


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
        if char == "(":
            paren_depth += 1
            continue
        if char == ")" and paren_depth:
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
    body = match.group(1)
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
    return canonicalize_text(text)


def _looks_like_reading(value: str, *, allow_long: bool = False) -> bool:
    """Reject prose annotations that happen to use italic markup."""

    text = canonicalize_text(value).strip(" .。;；/,")
    if not text or text.casefold() in _READING_NOTE_WORDS:
        return False
    if (not allow_long and len(text.split()) > 5) or any(char in text for char in '"“”():'):
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


def _reading_candidates(value: str) -> tuple[tuple[str, str], ...]:
    candidates: list[tuple[int, str, str]] = []
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


def _target_text(value: str) -> str:
    without_italics = _ITALIC.sub("", value)
    without_italics = _BRACKET_READING.sub("", without_italics)
    without_italics = _INLINE_TOKEN.sub(" ", without_italics)
    inline = _INLINE_READING.match(canonicalize_text(without_italics))
    if inline:
        without_italics = inline.group("target")
    # Parenthesized pronunciation notes can be left behind after removing
    # italics. Remove only empty shells and preserve real lexical parentheses.
    without_italics = re.sub(r"\(\s*\)", "", without_italics)
    cleaned = clean_markup(without_italics).strip(" /,;；")
    # Parenthesized Latin notes describe usage rather than the target phrase.
    # Keep parentheticals that contain target-script characters (for example a
    # simplified/traditional pair), and remove only Latin-only notes.
    if _CJK.search(cleaned):
        cleaned = re.sub(
            r"\((?P<note>[^()]*?)\)",
            lambda match: "" if not _CJK.search(match.group("note")) else match.group(0),
            cleaned,
        )
    cleaned = re.sub(r"\s+([,;!?])", r"\1", cleaned)
    return canonicalize_text(cleaned).strip(" /,;；")


def _valid_phrase(value: str) -> bool:
    normalized = canonicalize_text(value).casefold()
    return bool(normalized) and normalized not in _PLACEHOLDERS


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
        "raw": {
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
        },
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
    in_infobox = False
    occurrence_by_english: dict[tuple[str, str], int] = {}
    row_number = 0
    # A synthetic snapshot is replaced by export_page, which injects source
    # metadata after parsing. Keeping this function pure makes fixture tests
    # independent from the download filesystem.
    for line_number, raw_line in enumerate(str(wikitext).splitlines(), 1):
        line = raw_line.rstrip()
        heading = _HEADING.match(line)
        if heading:
            current_title = clean_markup(heading.group(2))
            current_key = resolve_section(current_title, sections)
            in_infobox = False
            continue
        if line.lstrip().startswith("{{infobox"):
            in_infobox = True
            continue
        if in_infobox:
            if "}}" in line:
                in_infobox = False
            # Infobox prose is not a phrase row, but a few reviewed pages put
            # compact definition-list vocabulary inside the box. Let those
            # rows through while still ignoring all other explanatory text.
            if not line.lstrip().startswith(";"):
                continue
        if current_key is None:
            continue
        split = _split_definition(line)
        if split is None:
            continue
        raw_left, raw_right = split
        # A small number of Wikivoyage sections use the target language as the
        # definition-list term and English as the definition. Detect this only
        # when the scripts make the direction unambiguous; do not infer from
        # title text or fuzzy language heuristics.
        left_markup = clean_markup(raw_left)
        right_markup = clean_markup(raw_right)
        reversed_row = bool(_CJK.search(left_markup) and not _CJK.search(right_markup))
        if reversed_row:
            raw_english, raw_target = raw_right, raw_left
        else:
            raw_english, raw_target = raw_left, raw_right
        english = _target_text(raw_english) if reversed_row else clean_markup(raw_english)
        target = _target_text(raw_target)
        if not _valid_phrase(english) or not _valid_phrase(target):
            diagnostics.append({"error_code": "empty_phrase_side", "line": line_number, "source_wikitext": raw_line})
            continue
        readings = _reading_candidates(raw_target)
        if reversed_row:
            readings = _reading_candidates(raw_left) or _reading_candidates(raw_right)

        # A reviewed split-by-locale profile (currently the Mandarin page)
        # may carry a simplified form followed by its traditional form. If a
        # row has no explicit pair, the same lexical form is linked to both
        # reviewed locales; this is safer than silently choosing one region.
        locale_targets: list[tuple[str, str | None]] = []
        if page.split_by_locale and len(page.locale_codes) >= 2:
            lexical = _ITALIC.sub("", raw_target)
            lexical = _BRACKET_READING.sub("", lexical)
            pair = re.match(r"^\s*(?P<first>[^()]+?)\s*\(\s*(?P<second>[^()]+?)\s*\)", lexical)
            if pair and _CJK.search(pair.group("first")) and _CJK.search(pair.group("second")):
                locale_targets = [
                    (_target_text(pair.group("first")), page.locale_codes[0]),
                    (_target_text(pair.group("second")), page.locale_codes[1]),
                ]
            else:
                locale_targets = [(target, page.locale_codes[0]), (target, page.locale_codes[1])]
        else:
            locale_targets = [(target, page.locale_codes[0] if len(page.locale_codes) == 1 else None)]

        english_variants = _expand_slash_variants(english)
        for target_base, target_locale in locale_targets:
            target_variants = _expand_slash_variants(target_base, language_code=page.lang_code)
            if not target_variants or not all(_valid_phrase(item) for item in target_variants):
                diagnostics.append({"error_code": "empty_phrase_side", "line": line_number, "source_wikitext": raw_line})
                continue
            for english_variant, target_variant, target_index in _phrase_variant_pairs(english_variants, target_variants):
                row_number += 1
                key = (current_key, english_variant.casefold())
                occurrence_by_english[key] = occurrence_by_english.get(key, 0) + 1
                # When the phrase and reading alternatives have matching
                # cardinality, preserve their one-to-one order. Otherwise all
                # readings remain attached to the expression.
                record_readings = readings
                if len(target_variants) > 1 and len(readings) == len(target_variants):
                    record_readings = (readings[target_index],)
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
                )
                record["raw"]["wikitext_line"] = line_number
                record["raw"]["source_wikitext"] = raw_line
                record["raw"]["row_orientation"] = "target-to-english" if reversed_row else "english-to-target"
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
