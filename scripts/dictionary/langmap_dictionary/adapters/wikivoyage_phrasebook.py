"""Normalization rules for English Wikivoyage phrasebook exports."""

from __future__ import annotations

import re
import unicodedata
from typing import Any

from ..models import (
    NormalizedAnnotation,
    NormalizedEntry,
    NormalizedOccurrence,
    NormalizedReading,
    NormalizedSense,
    StagedEntry,
)
from ..expression_surface import prepare_expression_value, surface_errors
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


def _surface_reading_scheme(value: str) -> str:
    if "-" not in value and re.search(r"[ːˈˌɐ-ʯɶ-ʸəɪɔʊɑɛɜɞɡɣɲŋʃʒʔʦʧʤ]", value):
        return "ipa"
    return "wikivoyage-respelling"


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
        head_errors: tuple[str, ...] = surface_errors(entry.canonical_headword)
        if not target_lang:
            head_errors = ("missing_target_language",)
        if not target_locale:
            head_errors = (*head_errors, "missing_target_locale")
        head_surfaces, head_surface_readings, head_annotation = prepare_expression_value(entry.canonical_headword)
        target_annotation = _text(raw_meta.get("target_annotation") or "") or None
        if not head_surfaces:
            head_surfaces = (entry.canonical_headword,)
        head_text = head_surfaces[0]
        head_cluster = _claim("headword", target_lang or "unknown", _expression_text(head_text).casefold())
        head = NormalizedOccurrence(
            _claim("entry", entry.entry_key, "headword"),
            "headword",
            entry.raw_headword,
            _expression_text(head_text),
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
        annotations: list[NormalizedAnnotation] = []
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
        for reading_ordinal, reading_value in enumerate(head_surface_readings, 1):
            scheme = _surface_reading_scheme(reading_value)
            reading_errors = ()
            readings.append(NormalizedReading(
                _claim("entry", entry.entry_key, "reading", "surface", str(reading_ordinal)),
                entry.entry_key,
                reading_value,
                _text(reading_value),
                scheme,
                target_locale,
                reading_errors,
                head.claim_key,
            ))
        annotation_text = head_annotation or target_annotation
        if annotation_text:
            annotations.append(NormalizedAnnotation(
                f"{head.claim_key}:annotation", entry.entry_key, None, entry.raw_headword,
                annotation_text, head.claim_key, "headword", {},
            ))
        headword_alternatives: list[NormalizedOccurrence] = []
        for alternative_index, alternative in enumerate(head_surfaces[1:], 2):
            cleaned = _expression_text(alternative)
            headword_alternatives.append(NormalizedOccurrence(
                _claim("entry", entry.entry_key, "headword", str(alternative_index)),
                "headword",
                entry.raw_headword,
                cleaned,
                target_lang,
                target_locale,
                _claim("headword", target_lang or "unknown", cleaned.casefold()),
                entry.entry_key,
                None,
                {"source_marker": source_marker, "surface_alternative_ordinal": alternative_index},
                head_errors,
            ))

        senses: list[NormalizedSense] = []
        for sense in entry.senses:
            occurrences: list[NormalizedOccurrence] = []
            for ordinal, raw_item in enumerate(sense.equivalents, 1):
                item: dict[str, Any] = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
                value = item.get("value") or item.get("text")
                alternatives, surface_readings, annotation = prepare_expression_value(value) if isinstance(value, str) else ((), (), None)
                language = str(item.get("language") or "").strip() or None
                locale = str(item.get("locale") or "").strip() or ("eng-Latn-US" if language == "eng" else None)
                for alternative_index, alternative in enumerate(alternatives, 1):
                    english = _expression_text(alternative)
                    errors: tuple[str, ...] = ()
                    if not english:
                        errors = ("empty_english_equivalent",)
                    elif language != "eng":
                        errors = ("non_english_equivalent",)
                    errors = tuple(dict.fromkeys((
                        *surface_errors(value if isinstance(value, str) else ""),
                        *surface_errors(english),
                        *errors,
                    )))
                    claim_ordinal = str(ordinal) if len(alternatives) == 1 else f"{ordinal}.{alternative_index}"
                    occurrence_claim = _claim("entry", entry.entry_key, "sense", sense.sense_key, "equivalent", claim_ordinal)
                    occurrence = NormalizedOccurrence(
                        occurrence_claim,
                        "equivalent",
                        value if isinstance(value, str) else "",
                        english,
                        "eng" if language == "eng" else language,
                        locale,
                        _claim("mapping", "eng", english.casefold()),
                        entry.entry_key,
                        sense.sense_key,
                        {"source_marker": source_marker, "target_lang_code": target_lang, "target_locale_code": target_locale, "surface_alternative_ordinal": alternative_index},
                        errors,
                    )
                    occurrences.append(occurrence)
                    for reading_index, reading_value in enumerate(surface_readings, 1):
                        scheme = _surface_reading_scheme(reading_value)
                        readings.append(NormalizedReading(
                            _claim(occurrence_claim, "reading", "surface", str(reading_index)),
                            entry.entry_key,
                            reading_value,
                            _text(reading_value),
                            scheme,
                            locale,
                            (),
                            occurrence_claim,
                        ))
                    if annotation:
                        annotations.append(NormalizedAnnotation(
                            f"{occurrence_claim}:annotation", entry.entry_key, sense.sense_key,
                            value if isinstance(value, str) else "", annotation, occurrence_claim,
                            "equivalent", {"surface_alternative_ordinal": alternative_index},
                        ))
            senses.append(NormalizedSense(sense.sense_key, tuple(occurrences), (), ()))
        return NormalizedEntry(
            entry.dictionary_key,
            entry.entry_key,
            head,
            tuple(senses),
            tuple(readings),
            entry.raw,
            (),
            tuple(annotations),
            tuple(headword_alternatives),
        )


__all__ = ["WikivoyagePhrasebookAdapter"]
