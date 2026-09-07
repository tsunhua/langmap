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
_CJK = re.compile(r"[\u2e80-\u9fff\uf900-\ufaff]")
_PLACEHOLDERS = frozenset({"", "-", "—", "…", "...", "n/a", "none", "tbd"})


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
    candidates: list[tuple[str, str]] = []
    for match in _ITALIC.finditer(value):
        text = clean_markup(match.group(1)).strip(" .。;；")
        if text and text.casefold() not in _PLACEHOLDERS:
            candidates.append((text, "italic"))
    for match in _TEMPLATE.finditer(value):
        body = match.group(1)
        if body.split("|", 1)[0].strip().casefold() in {"ipa", "ipa-all"}:
            text = clean_markup(body.split("|", 1)[-1]).strip(" .。;；/")
            if text:
                candidates.append((text, "ipa"))
    seen: set[tuple[str, str]] = set()
    return tuple(item for item in candidates if not (item in seen or seen.add(item)))


def _target_text(value: str) -> str:
    without_italics = _ITALIC.sub("", value)
    # Parenthesized pronunciation notes can be left behind after removing
    # italics. Remove only empty shells and preserve real lexical parentheses.
    without_italics = re.sub(r"\(\s*\)", "", without_italics)
    return clean_markup(without_italics).strip(" /,;；")


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
    readings: Iterable[tuple[str, str]],
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    english = canonicalize_text(english)
    target = canonicalize_text(target)
    entry_key = f"{snapshot.pageid}:{section_key}:{hashlib.sha256(english.encode('utf-8')).hexdigest()}:{occurrence}"
    pronunciation_rows: list[dict[str, Any]] = []
    diagnostics: list[dict[str, Any]] = []
    locale = profile.locale_codes[0] if len(profile.locale_codes) == 1 else None
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
            continue
        if current_key is None:
            continue
        split = _split_definition(line)
        if split is None:
            continue
        raw_english, raw_target = split
        english = clean_markup(raw_english)
        target = _target_text(raw_target)
        if not _valid_phrase(english) or not _valid_phrase(target):
            diagnostics.append({"error_code": "empty_phrase_side", "line": line_number, "source_wikitext": raw_line})
            continue
        row_number += 1
        key = (current_key, english.casefold())
        occurrence_by_english[key] = occurrence_by_english.get(key, 0) + 1
        readings = _reading_candidates(raw_target)
        # The parser emits a provisional record; export_page supplies the
        # immutable page metadata and recalculates the fingerprint.
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
            english=english,
            target=target,
            occurrence=occurrence_by_english[key],
            readings=readings,
        )
        record["raw"]["wikitext_line"] = line_number
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
