"""Explicit Traditional Chinese--English normalization rules."""

from __future__ import annotations

import json
import re
import unicodedata
from typing import Any

from ..loader import iter_staged_entries
from ..models import (
    NormalizedEntry,
    NormalizedOccurrence,
    NormalizedPos,
    NormalizedReading,
    NormalizedSense,
    StagedEntry,
)

_HAN = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")
_POS = {
    "n": "noun", "noun": "noun", "名詞": "noun",
    "v": "verb", "verb": "verb", "動詞": "verb",
    "adj": "adjective", "adjective": "adjective", "形容詞": "adjective",
    "adv": "adverb", "adverb": "adverb", "副詞": "adverb",
    "prep": "preposition", "preposition": "preposition", "介詞": "preposition",
    "pron": "pronoun", "pronoun": "pronoun", "代詞": "pronoun",
    "idiom": "idiom", "片語": "idiom", "成語": "idiom",
}


def canonicalize_text(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip())


def clean_equivalent(value: str) -> tuple[str, bool]:
    text = canonicalize_text(value)
    bullet = text.startswith("•")
    return (text[1:].lstrip() if bullet else text), bullet


def _is_han(value: str) -> bool:
    return bool(_HAN.search(value))


def _language(value: str, hint: str | None = None) -> tuple[str | None, str | None, str | None]:
    token = (hint or "").lower()
    if "eng" in token or token in {"en", "en-us", "en-gb"}:
        return "eng", "eng-Latn-US", None
    if "cmn" in token or "hant" in token or token in {"zh", "zh-tw", "zh-hant"}:
        return "cmn", "cmn-Hant-TW", None
    if _is_han(value):
        return "cmn", "cmn-Hant-TW", None
    if value and all(ord(char) < 0x2E80 or char.isspace() or char.isascii() for char in value):
        return "eng", "eng-Latn-US", None
    return None, None, "unknown_locale"


def _side_hint(direction: str | None, headword: bool) -> str | None:
    token = (direction or "").lower().replace("→", "-").replace(">", "-")
    if not token:
        return None
    if headword and token.startswith("eng-"):
        return "eng"
    if headword and (token.startswith("cmn-") or token.startswith("zh-")):
        return "cmn"
    if not headword and token.startswith("eng-"):
        return "cmn"
    if not headword and (token.startswith("cmn-") or token.startswith("zh-")):
        return "eng"
    return None


def _claim(*parts: str) -> str:
    return ":".join(parts)


class TraditionalChineseEnglishAdapter:
    id = "traditional-chinese-english"

    def normalize_entry(self, entry: StagedEntry) -> NormalizedEntry:
        head_hint = _side_hint(entry.direction_hint, True)
        head_lang, head_locale, head_error = _language(entry.canonical_headword, head_hint)
        head_errors = (head_error,) if head_error else ()
        marker = entry.homograph_marker or "none"
        head_cluster = _claim("headword", entry.dictionary_key, entry.entry_key, marker)
        head = NormalizedOccurrence(
            _claim("entry", entry.entry_key, "headword"), "headword", entry.raw_headword,
            canonicalize_text(entry.canonical_headword), head_lang, head_locale, head_cluster,
            entry.entry_key, None, {"homograph_marker": entry.homograph_marker}, head_errors,
        )
        readings = tuple(self._reading(entry, index, item) for index, item in enumerate(entry.pronunciations, 1))
        senses: list[NormalizedSense] = []
        for sense in entry.senses:
            occurrences: list[NormalizedOccurrence] = []
            for ordinal, raw_item in enumerate(sense.equivalents, 1):
                item = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
                raw_value = item.get("value") or item.get("text")
                if not isinstance(raw_value, str) or not raw_value.strip():
                    continue
                cleaned, had_bullet = clean_equivalent(raw_value)
                hint = item.get("language") or item.get("language_hint") or _side_hint(entry.direction_hint, False)
                lang, locale, error = _language(cleaned, hint)
                occurrences.append(NormalizedOccurrence(
                    _claim("entry", entry.entry_key, "sense", sense.sense_key, "equivalent", str(ordinal)),
                    "equivalent", raw_value, cleaned, lang, locale,
                    _claim("claim", entry.entry_key, sense.sense_key, "equivalent", str(ordinal)),
                    entry.entry_key, sense.sense_key, {"bullet_removed": had_bullet}, (error,) if error else (),
                ))
            for ordinal, raw_item in enumerate(sense.relations, 1):
                item = raw_item if isinstance(raw_item, dict) else {}
                if item.get("kind") != "synonym":
                    # Antonyms remain fully available in input_relations.raw_json,
                    # but the first online model has no opposition edge kind.
                    continue
                raw_value = item.get("related_text") or item.get("text")
                if not isinstance(raw_value, str) or not raw_value.strip():
                    continue
                cleaned = canonicalize_text(raw_value)
                hint = item.get("language") or item.get("language_hint") or _side_hint(entry.direction_hint, False)
                lang, locale, error = _language(cleaned, hint)
                occurrences.append(NormalizedOccurrence(
                    _claim("entry", entry.entry_key, "sense", sense.sense_key, "synonym", str(ordinal)),
                    "synonym", raw_value, cleaned, lang, locale,
                    _claim("claim", entry.entry_key, sense.sense_key, "synonym", str(ordinal)),
                    entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                ))
            for ordinal, raw_item in enumerate(sense.examples, 1):
                item = raw_item if isinstance(raw_item, dict) else {"text": raw_item}
                text = item.get("text")
                if isinstance(text, str) and text.strip():
                    lang, locale, error = _language(text, item.get("language"))
                    occurrences.append(NormalizedOccurrence(
                        _claim("entry", entry.entry_key, "sense", sense.sense_key, "example", str(ordinal), "text"),
                        "example", text, canonicalize_text(text), lang, locale,
                        _claim("claim", entry.entry_key, sense.sense_key, "example", str(ordinal), "text"),
                        entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                    ))
                translation = item.get("translation")
                if isinstance(translation, str) and translation.strip():
                    lang, locale, error = _language(translation, item.get("translation_language"))
                    occurrences.append(NormalizedOccurrence(
                        _claim("entry", entry.entry_key, "sense", sense.sense_key, "example", str(ordinal), "translation"),
                        "example", translation, canonicalize_text(translation), lang, locale,
                        _claim("claim", entry.entry_key, sense.sense_key, "example", str(ordinal), "translation"),
                        entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                    ))
            pos = tuple(self._pos(sense.sense_key, entry.entry_key, index, value) for index, value in enumerate(sense.pos, 1))
            senses.append(NormalizedSense(sense.sense_key, tuple(occurrences), readings, pos))
        return NormalizedEntry(entry.dictionary_key, entry.entry_key, head, tuple(senses), readings, entry.raw)

    def _reading(self, entry: StagedEntry, index: int, item: Any) -> NormalizedReading:
        scheme = item.scheme
        upper = scheme.upper()
        if "IPA" in upper:
            normalized_scheme = "ipa"
            locale = "eng-Latn-GB" if upper.startswith("UK") else "eng-Latn-US" if upper.startswith("US") else None
            errors = () if locale else ("unknown_locale",)
        elif "PINYIN" in upper or "BOPOMOFO" in upper:
            normalized_scheme = "pinyin" if "PINYIN" in upper else "bopomofo"
            locale = "cmn-Hant-TW"
            errors = ()
        else:
            normalized_scheme, locale, errors = scheme, None, ("unknown_reading_scheme",)
        return NormalizedReading(_claim("entry", entry.entry_key, "reading", str(index)), entry.entry_key, item.value, canonicalize_text(item.value), normalized_scheme, locale, errors)

    def _pos(self, sense_key: str, entry_key: str, index: int, value: Any) -> NormalizedPos:
        raw = value if isinstance(value, str) else value.get("value") if isinstance(value, dict) else str(value)
        code = _POS.get(raw.strip().lower()) if isinstance(raw, str) else None
        errors = () if code else ("unknown_pos",)
        return NormalizedPos(_claim("sense", sense_key, "pos", str(index)), sense_key, raw, code, errors)


def normalize_release(connection, release_id: str, adapter: TraditionalChineseEnglishAdapter | None = None) -> int:
    adapter = adapter or TraditionalChineseEnglishAdapter()
    connection.execute("DELETE FROM normalized_pos WHERE release_id=?", (release_id,))
    connection.execute("DELETE FROM lexical_readings WHERE release_id=?", (release_id,))
    connection.execute("DELETE FROM lexical_occurrences WHERE release_id=?", (release_id,))
    count = 0
    for entry in iter_staged_entries(connection, release_id):
        normalized = adapter.normalize_entry(entry)
        values = (normalized.headword, *(occurrence for sense in normalized.senses for occurrence in sense.occurrences))
        for occurrence in values:
            connection.execute("INSERT INTO lexical_occurrences VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", (release_id, occurrence.claim_key, occurrence.occurrence_kind, occurrence.entry_key, occurrence.sense_key, occurrence.raw_value, occurrence.canonical_text, occurrence.lang_code, occurrence.locale_code, occurrence.cluster_key, json.dumps(occurrence.metadata, ensure_ascii=False, sort_keys=True), json.dumps(occurrence.errors)))
            if occurrence.errors:
                connection.execute("INSERT OR IGNORE INTO quarantine_items (release_id,dictionary_key,entry_key,sense_key,claim_key,error_code,detail,raw_json) VALUES (?,?,?,?,?,?,?,?)", (release_id, entry.dictionary_key, entry.entry_key, occurrence.sense_key, occurrence.claim_key, occurrence.errors[0], "normalization failed", json.dumps(entry.raw, ensure_ascii=False, sort_keys=True)))
        for reading in normalized.readings:
            connection.execute("INSERT INTO lexical_readings VALUES (?,?,?,?,?,?,?,?)", (release_id, reading.claim_key, reading.entry_key, reading.raw_value, reading.value, reading.scheme, reading.locale_code, json.dumps(reading.errors)))
        for sense in normalized.senses:
            for pos in sense.pos:
                connection.execute("INSERT INTO normalized_pos VALUES (?,?,?,?,?,?)", (release_id, pos.claim_key, pos.sense_key, pos.raw_value, pos.code, json.dumps(pos.errors)))
        count += 1
    connection.commit()
    return count
