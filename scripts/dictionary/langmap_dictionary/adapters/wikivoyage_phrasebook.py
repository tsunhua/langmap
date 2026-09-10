"""Normalization rules for English Wikivoyage phrasebook exports."""

from __future__ import annotations

import re
import unicodedata
from typing import Any

from ..models import (
    NormalizedEntry,
    NormalizedOccurrence,
    NormalizedReading,
    NormalizedSense,
    StagedEntry,
)
from ..text_identity import canonicalize_expression_text


_CJK = re.compile(r"[\u2e80-\u9fff\uf900-\ufaff]")
_READING_SCHEMES = frozenset({
    "ipa",
    "hepburn",
    "pinyin",
    "jyutping",
    "tailo",
    "wikivoyage-romanization",
    "wikivoyage-respelling",
})


def _text(value: str) -> str:
    return unicodedata.normalize("NFC", str(value).strip())


def _expression_text(value: str) -> str:
    return canonicalize_expression_text(str(value))


def _claim(*parts: str) -> str:
    return ":".join(parts)


class WikivoyagePhrasebookAdapter:
    """Project target-language heads and English equivalents only."""

    id = "wikivoyage-phrasebook"

    def normalize_entry(self, entry: StagedEntry) -> NormalizedEntry:
        if not entry.dictionary_key.startswith("enwikivoyage:"):
            raise ValueError(f"unsupported dictionary key: {entry.dictionary_key}")
        raw_meta = entry.raw.get("raw", {}) if isinstance(entry.raw, dict) else {}
        target_lang = str(raw_meta.get("target_lang_code") or "").strip() or None
        target_locale = str(raw_meta.get("target_locale_code") or "").strip() or None
        source_marker = str(raw_meta.get("source_marker") or "").strip()
        head_errors: tuple[str, ...] = ()
        if not target_lang:
            head_errors = ("missing_target_language",)
        if not target_locale:
            head_errors = (*head_errors, "missing_target_locale")
        head_cluster = _claim("headword", target_lang or "unknown", entry.canonical_headword.casefold())
        head = NormalizedOccurrence(
            _claim("entry", entry.entry_key, "headword"),
            "headword",
            entry.raw_headword,
            _expression_text(entry.canonical_headword),
            target_lang,
            target_locale,
            head_cluster,
            entry.entry_key,
            None,
            {
                "source_marker": source_marker,
                "homograph_marker": source_marker,
                "target_lang_code": target_lang,
                "target_locale_code": target_locale,
            },
            head_errors,
        )
        readings: list[NormalizedReading] = []
        for ordinal, pronunciation in enumerate(entry.pronunciations, 1):
            scheme = _text(pronunciation.scheme).casefold()
            value = _text(pronunciation.value)
            locale = str(pronunciation.raw.get("locale") or target_locale or "").strip() or None
            errors: list[str] = []
            if scheme not in _READING_SCHEMES:
                errors.append("unknown_reading_scheme")
            if locale is None:
                errors.append("missing_target_locale")
            if scheme in {"ipa", "hepburn", "pinyin", "jyutping", "tailo", "wikivoyage-romanization", "wikivoyage-respelling"} and _CJK.search(value):
                errors.append("reading_script_mismatch")
            if not value:
                errors.append("empty_reading")
            readings.append(NormalizedReading(
                _claim("entry", entry.entry_key, "reading", str(ordinal)),
                entry.entry_key,
                pronunciation.value,
                value,
                scheme,
                locale,
                tuple(dict.fromkeys(errors)),
            ))

        senses: list[NormalizedSense] = []
        for sense in entry.senses:
            occurrences: list[NormalizedOccurrence] = []
            for ordinal, raw_item in enumerate(sense.equivalents, 1):
                item: dict[str, Any] = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
                value = item.get("value") or item.get("text")
                english = _expression_text(value) if isinstance(value, str) else ""
                language = str(item.get("language") or "").strip() or None
                locale = str(item.get("locale") or "").strip() or ("eng-Latn-US" if language == "eng" else None)
                errors: tuple[str, ...] = ()
                if not english:
                    errors = ("empty_english_equivalent",)
                elif language != "eng":
                    errors = ("non_english_equivalent",)
                occurrence = NormalizedOccurrence(
                    _claim("entry", entry.entry_key, "sense", sense.sense_key, "equivalent", str(ordinal)),
                    "equivalent",
                    english,
                    english,
                    "eng" if language == "eng" else language,
                    locale,
                    _claim("mapping", "eng", english.casefold()),
                    entry.entry_key,
                    sense.sense_key,
                    {"source_marker": source_marker, "target_lang_code": target_lang, "target_locale_code": target_locale},
                    errors,
                )
                occurrences.append(occurrence)
            senses.append(NormalizedSense(sense.sense_key, tuple(occurrences), (), ()))
        return NormalizedEntry(
            entry.dictionary_key,
            entry.entry_key,
            head,
            tuple(senses),
            tuple(readings),
            entry.raw,
            (),
        )


__all__ = ["WikivoyagePhrasebookAdapter"]
