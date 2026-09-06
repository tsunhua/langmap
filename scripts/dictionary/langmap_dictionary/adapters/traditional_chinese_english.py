"""Explicit Traditional Chinese--English normalization rules."""

from __future__ import annotations

import json
import re
import sqlite3
import time
import unicodedata
from typing import Any, Callable

from ..loader import iter_staged_entry_rows
from ..models import (
    NormalizedEntry,
    NormalizedOccurrence,
    NormalizedPos,
    NormalizedReading,
    NormalizedSense,
    StagedEntry,
)

try:
    import ujson as _fast_json
except ImportError:  # pragma: no cover - the standard library remains supported
    _fast_json = json

_HAN = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")

# Unicode block ranges that uniquely identify a dictionary target language script.
# Used to split ``definitions`` entries that bundle an English definition with its
# foreign-language equivalent (common in Kannada/Telugu/Malayalam OUP bundles).
_SCRIPT_RANGES: dict[str, tuple[tuple[int, int], ...]] = {
    "arab": ((0x0600, 0x06FF), (0x0750, 0x077F), (0x08A0, 0x08FF)),
    "beng": ((0x0980, 0x09FF),),
    "cyrl": ((0x0400, 0x052F),),
    "deva": ((0x0900, 0x097F),),
    "geor": ((0x10A0, 0x10FF),),
    "grek": ((0x0370, 0x03FF),),
    "gujr": ((0x0A80, 0x0AFF),),
    "guru": ((0x0A00, 0x0A7F),),
    "hang": ((0xAC00, 0xD7AF), (0x1100, 0x11FF)),
    "hebr": ((0x0590, 0x05FF),),
    "jpan": ((0x3040, 0x30FF),),
    "knda": ((0x0C80, 0x0CFF),),
    "mlym": ((0x0D00, 0x0D7F),),
    "taml": ((0x0B80, 0x0BFF),),
    "telu": ((0x0C00, 0x0C7F),),
    "thai": ((0x0E00, 0x0E7F),),
}

_SCRIPT_LANGUAGE = {
    "arab": "arb", "beng": "ben", "cyrl": "rus", "deva": "hin",
    "geor": "kat", "grek": "ell", "gujr": "guj", "guru": "pan",
    "hang": "kor", "hebr": "heb", "jpan": "jpn", "knda": "kan",
    "mlym": "mal", "taml": "tam", "telu": "tel", "thai": "tha",
}

_IPA_INCOMPATIBLE_SCRIPTS = tuple(
    ranges for script, ranges in _SCRIPT_RANGES.items() if script != "grek"
)
_IPA_COMPATIBLE_NAME_MARKERS = (
    "LATIN", "GREEK", "MODIFIER LETTER", "COMBINING", "SUPERSCRIPT", "SUBSCRIPT",
)

_POS = {
    "n": "noun", "noun": "noun", "名詞": "noun",
    "v": "verb", "verb": "verb", "動詞": "verb",
    "adj": "adjective", "adjective": "adjective", "形容詞": "adjective",
    "adv": "adverb", "adverb": "adverb", "副詞": "adverb",
    "prep": "preposition", "preposition": "preposition", "介詞": "preposition",
    "pron": "pronoun", "pronoun": "pronoun", "代詞": "pronoun",
    "idiom": "idiom", "phrase": "phrase", "片語": "idiom", "成語": "idiom",
}
_PROFILE_LOCALES = {
    "eng": ("eng", "eng-Latn-US"), "cmn": ("cmn", "cmn-Hant-TW"),
    "cmn-Hant": ("cmn", "cmn-Hant-TW"), "cmn-Hans": ("cmn", "cmn-Hans-CN"),
    "cmn-Hant-TW": ("cmn", "cmn-Hant-TW"), "cmn-Hans-CN": ("cmn", "cmn-Hans-CN"),
    "hak": ("hak", "hak-Hant-TW"), "hak-Hant-TW": ("hak", "hak-Hant-TW"),
    "hak-Hant-TW_Sixian": ("hak", "hak-Hant-TW_Sixian"),
    "hak-Hant-TW_Hailu": ("hak", "hak-Hant-TW_Hailu"),
    "hak-Hant-TW_Dapu": ("hak", "hak-Hant-TW_Dapu"),
    "hak-Hant-TW_Jaoping": ("hak", "hak-Hant-TW_Jaoping"),
    "hak-Hant-TW_Zhaoan": ("hak", "hak-Hant-TW_Zhaoan"),
    "hak-Hant-TW_SouthernSixian": ("hak", "hak-Hant-TW_SouthernSixian"),
    "yue": ("yue", "yue-Hant-HK"),
    "yue-Hant-HK": ("yue", "yue-Hant-HK"),
    "yue-Hans-HK": ("yue", "yue-Hans-HK"),
    "yue-Hans-CN_Guangzhou": ("yue", "yue-Hans-CN_Guangzhou"),
    "yue-Hans-CN_Kaiping": ("yue", "yue-Hans-CN_Kaiping"),
    "yue-Hans-CN_Qinzhou": ("yue", "yue-Hans-CN_Qinzhou"),
    "yue-Hans-CN_Taishan": ("yue", "yue-Hans-CN_Taishan"),
    "jpn": ("jpn", "jpn-Jpan-JP"),
    "nan": ("nan", "nan-Hant-TW"), "nan-Hant-TW": ("nan", "nan-Hant-TW"),
    "nan-Hant-CN": ("nan", "nan-Hant-CN"),
    "nan-Hant-CN_Chaozhou": ("nan", "nan-Hant-CN_Chaozhou"),
    "nan-Hant-CN_Swatow": ("nan", "nan-Hant-CN_Swatow"),
    "nan-Latn-CN_Swatow": ("nan", "nan-Latn-CN_Swatow"),
    "nan-Latn-CN_Swatow_DP": ("nan", "nan-Latn-CN_Swatow_DP"),
    "nan-Latn-CN_Chaozhou": ("nan", "nan-Latn-CN_Chaozhou"),
    "nan-Latn-CN_Chaozhou_DP": ("nan", "nan-Latn-CN_Chaozhou_DP"),
    "wuu": ("wuu", "wuu-Hant-CN_Shanghai"),
    "wuu-Hant-CN_Shanghai": ("wuu", "wuu-Hant-CN_Shanghai"),
    "arb": ("arb", "arb-Arab"), "ben": ("ben", "ben-Beng"),
    "ces": ("ces", "ces-Latn"), "dan": ("dan", "dan-Latn"),
    "deu": ("deu", "deu-Latn"), "ell": ("ell", "ell-Grek"),
    "fin": ("fin", "fin-Latn"), "fra": ("fra", "fra-Latn"),
    "guj": ("guj", "guj-Gujr"), "hin": ("hin", "hin-Deva"),
    "hrv": ("hrv", "hrv-Latn"), "hun": ("hun", "hun-Latn"),
    "ind": ("ind", "ind-Latn"), "ita": ("ita", "ita-Latn"),
    "kan": ("kan", "kan-Knda"), "kaz": ("kaz", "kaz-Cyrl"),
    "kor": ("kor", "kor-Hang"), "mal": ("mal", "mal-Mlym"),
    "zsm": ("zsm", "zsm-Latn"), "nld": ("nld", "nld-Latn"),
    "nob": ("nob", "nob-Latn"), "pan": ("pan", "pan-Guru"),
    "pol": ("pol", "pol-Latn"), "por": ("por", "por-Latn"),
    "rus": ("rus", "rus-Cyrl"), "slk": ("slk", "slk-Latn"),
    "spa": ("spa", "spa-Latn-ES"), "swe": ("swe", "swe-Latn"),
    "tam": ("tam", "tam-Taml"), "tel": ("tel", "tel-Telu"),
    "tha": ("tha", "tha-Thai"), "tur": ("tur", "tur-Latn"),
    "ukr": ("ukr", "ukr-Cyrl"), "urd": ("urd", "urd-Arab"),
    "vie": ("vie", "vie-Latn"),
}


def canonicalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFC", value.strip())
    without_period = normalized.rstrip(".．。").rstrip()
    return without_period or normalized


def clean_equivalent(value: str) -> tuple[str, bool]:
    text = canonicalize_text(value)
    bullet = text.startswith("•")
    return (text[1:].lstrip() if bullet else text), bullet


def _is_han(value: str) -> bool:
    return bool(_HAN.search(value))


def _script_language(value: str) -> str | None:
    """Return the language identified by a distinctive Unicode script, if any."""
    for char in value:
        codepoint = ord(char)
        for script, ranges in _SCRIPT_RANGES.items():
            if any(start <= codepoint <= end for start, end in ranges):
                return _SCRIPT_LANGUAGE[script]
    if _is_han(value):
        return "cmn"
    return None


def _has_ipa_incompatible_script(value: str) -> bool:
    for character in value:
        if any(
            start <= ord(character) <= end
            for ranges in _IPA_INCOMPATIBLE_SCRIPTS
            for start, end in ranges
        ) or _is_han(character):
            return True
        name = unicodedata.name(character, "")
        if unicodedata.category(character).startswith("L") and not any(
            marker in name for marker in _IPA_COMPATIBLE_NAME_MARKERS
        ):
            # Keep the gate fail-closed for a future dictionary that introduces
            # a script not yet listed in _SCRIPT_RANGES.
            return True
    return False


def _relation_reading_values(entry: StagedEntry) -> set[str]:
    if entry.dictionary_key != "com.apple.dictionary.zh_CN.thes":
        return set()
    pronunciations = tuple(
        canonicalize_text(pronunciation.value) for pronunciation in entry.pronunciations
    )
    relation_values = {
        canonicalize_text(str(item["reading"]))
        for sense in entry.senses
        for item in sense.relations
        if isinstance(item, dict)
        and isinstance(item.get("reading"), str)
        and str(item["reading"]).strip()
    }
    # A single legitimate homophone can coincide with a synonym's reading.
    # The legacy exporter bug is the larger pattern where a valid headword
    # reading is accompanied by one or more relation readings.
    if len(pronunciations) < 2 or not any(value not in relation_values for value in pronunciations):
        return set()
    return relation_values


def _language(value: str, hint: str | None = None) -> tuple[str | None, str | None, str | None]:
    token = (hint or "").lower()
    profile = token.split("-to-", 1)[0] if "-to-" in token else token
    profile = next((key for key in _PROFILE_LOCALES if key.lower() == profile), profile)
    if profile in _PROFILE_LOCALES:
        language, locale = _PROFILE_LOCALES[profile]
        return language, locale, None
    if "eng" in token or token in {"en", "en-us", "en-gb"}:
        return "eng", "eng-Latn-US", None
    if "cmn" in token or "hant" in token or token in {"zh", "zh-tw", "zh-hant"}:
        return "cmn", "cmn-Hant-TW", None
    detected = _script_language(value)
    if detected is not None:
        language, locale = _PROFILE_LOCALES.get(detected, (detected, None))
        return language, locale or (_known_locale(detected)), None
    if value and all(ord(char) < 0x2E80 or char.isspace() or char.isascii() for char in value):
        return "eng", "eng-Latn-US", None
    return None, None, "unknown_locale"


def _known_locale(language: str) -> str | None:
    seen: dict[str, str] = {
        "heb": "heb-Hebr", "kat": "kat-Geor", "rus": "rus-Cyrl", "pan": "pan-Guru",
    }
    return seen.get(language)


def _side_hint(direction: str | None, headword: bool) -> str | None:
    token = (direction or "").strip().replace("→", "-to-").replace(">", "-to-")
    if "-to-" not in token:
        return None
    source, target = token.split("-to-", 1)
    return source if headword else target


def _claim(*parts: str) -> str:
    return ":".join(parts)


_PINYIN_TONE_MARKS = frozenset("āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ")


def _has_pinyin_tone_marks(value: str) -> bool:
    """True when ``value`` carries pinyin tone diacritics (ḿ kamu, ē, ǎ…).

    Apple's Chinese bundles label the headword pinyin as ``UK_IPA``/``solitary``;
    the tone-marked Latin spelling is the reliable signal to reclassify it as
    pinyin instead of attaching it to an English IPA reading and locale."""
    return any(character in _PINYIN_TONE_MARKS for character in value)


_LATIN_PINYIN_ALLOWED = frozenset(
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    " \t'’·，。？！、；：・…—（）()·,?!."
) | _PINYIN_TONE_MARKS


def _is_pinyin_spelling(value: str) -> bool:
    """``Crown`` bundles mix romanized pinyin into ``equivalents`` (e.g.
    ``kuàiyào lái le``).  Pinyin is a reading, not a word, so an equivalent
    that carries pinyin tone marks and otherwise stays within the pinyin/Latin
    character set is folded into a reading instead of being allocated an
    expression node."""
    if not _has_pinyin_tone_marks(value):
        return False
    return all(character in _LATIN_PINYIN_ALLOWED for character in value)


def _is_latin_expression(value: str) -> bool:
    """Identify Crown's unlabelled English glosses after pinyin is removed."""
    letters = [character for character in value if character.isalpha()]
    return bool(letters) and all(
        "LATIN" in unicodedata.name(character, "") for character in letters
    )


_JYUTPING_SUPERSCRIPT = str.maketrans("0123456789", "⁰¹²³⁴⁵⁶⁷⁸⁹")


def _canonical_jyutping(value: str) -> str:
    """Collapse the OUP/CP spaced-tone spelling (``daat 3``, ``taat 3/1``)
    into the canonical Jyutping tone superscripts (``daat³``, ``taat³/¹``)."""
    value = re.sub(r"[ \t]+([0-9])", lambda match: match.group(1).translate(_JYUTPING_SUPERSCRIPT), value)
    value = re.sub(r"(?<=/)([0-9])", lambda match: match.group(1).translate(_JYUTPING_SUPERSCRIPT), value)
    return value.strip()


def _entry_jyutping_values(entry: StagedEntry) -> set[str]:
    return {
        _canonical_jyutping(pronunciation.value)
        for pronunciation in entry.pronunciations
        if pronunciation.scheme.strip().lower() == "jyutping"
    }


class TraditionalChineseEnglishAdapter:
    id = "traditional-chinese-english"

    def normalize_entry(self, entry: StagedEntry) -> NormalizedEntry:
        crown = str(entry.dictionary_key or "").endswith("zhs-ja.Crown")
        direction_hint = entry.direction_hint
        # A small set of Crown Chinese names/events is tagged jpn-to-cmn even
        # though its structured headword pronunciation is pinyin and its first
        # equivalent is Japanese. Require both independent source signals so
        # Japanese entries that merely contain example pinyin stay unchanged.
        if crown and str(direction_hint or "").startswith("jpn") and any(
            _is_pinyin_spelling(str(item.value)) for item in entry.pronunciations
        ):
            first_equivalent = ""
            for sense in entry.senses:
                for raw in sense.equivalents:
                    value = (
                        str(raw.get("value") or raw.get("text") or "")
                        if isinstance(raw, dict)
                        else str(raw)
                    )
                    if value.strip():
                        first_equivalent = value
                        break
                if first_equivalent:
                    break
            if _script_language(first_equivalent) == "jpn":
                direction_hint = "cmn-Hans-to-jpn"

        head_hint = _side_hint(direction_hint, True)
        head_lang, head_locale, head_error = _language(entry.canonical_headword, head_hint)
        head_errors = (head_error,) if head_error else ()
        marker = entry.homograph_marker or "none"
        head_cluster = _claim("headword", entry.dictionary_key, entry.entry_key, marker)
        head = NormalizedOccurrence(
            _claim("entry", entry.entry_key, "headword"), "headword", entry.raw_headword,
            canonicalize_text(entry.canonical_headword), head_lang, head_locale, head_cluster,
            entry.entry_key, None, {"homograph_marker": entry.homograph_marker}, head_errors,
        )
        # Chinese bundles may mix romanized pinyin into equivalents and use bare
        # tone numbers as pronunciation schemes. Pinyin is a reading, never a
        # separate expression node.
        extended_readings = list(
            self._reading(
                entry,
                index,
                item,
                _entry_jyutping_values(entry),
                head_lang,
                fold_pinyin=crown or head_lang == "cmn",
                relation_readings=_relation_reading_values(entry),
            )
            for index, item in enumerate(entry.pronunciations, 1)
        )
        form_occurrences: list[NormalizedOccurrence] = []
        for ordinal, raw_item in enumerate(entry.forms, 1):
            item = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
            raw_value = item.get("value") or item.get("text")
            if not isinstance(raw_value, str) or not raw_value.strip():
                continue
            cleaned = canonicalize_text(raw_value)
            hint = item.get("language") or item.get("language_hint")
            lang, locale, error = _language(cleaned, hint)
            form_claim = _claim("entry", entry.entry_key, "form", str(ordinal))
            form_occurrences.append(NormalizedOccurrence(
                form_claim,
                "form",
                raw_value,
                cleaned,
                lang,
                locale,
                form_claim,
                entry.entry_key,
                None,
                {"labels": item.get("labels", []), "form_ordinal": ordinal},
                (error,) if error else (),
            ))
            for reading_ordinal, raw_reading in enumerate(item.get("readings") or (), 1):
                if not isinstance(raw_reading, dict):
                    continue
                raw_reading_value = raw_reading.get("value")
                raw_scheme = raw_reading.get("scheme")
                if not isinstance(raw_reading_value, str) or not raw_reading_value.strip() or not isinstance(raw_scheme, str):
                    continue
                if raw_scheme.strip().lower() == "hakka-pinyin":
                    reading_scheme = "hakka-pinyin"
                    reading_locale = str(raw_reading.get("locale") or locale or "hak-Hant-TW")
                    reading_value = canonicalize_text(raw_reading_value)
                    reading_errors: tuple[str, ...] = ()
                else:
                    reading_scheme = raw_scheme
                    reading_locale = str(raw_reading.get("locale") or locale) if (raw_reading.get("locale") or locale) else None
                    reading_value = canonicalize_text(raw_reading_value)
                    reading_errors = ("unknown_reading_scheme",)
                extended_readings.append(NormalizedReading(
                    _claim(form_claim, "reading", str(reading_ordinal)),
                    entry.entry_key,
                    raw_reading_value,
                    reading_value,
                    reading_scheme,
                    reading_locale,
                    reading_errors,
                    form_claim,
                ))
        mapping_occurrences: list[NormalizedOccurrence] = []
        for ordinal, raw_item in enumerate(entry.mappings, 1):
            item = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
            raw_value = item.get("value") or item.get("text")
            if not isinstance(raw_value, str) or not raw_value.strip():
                continue
            cleaned = canonicalize_text(raw_value)
            hint = item.get("language") or item.get("language_hint")
            lang, locale, error = _language(cleaned, hint)
            mapping_claim = _claim("entry", entry.entry_key, "mapping", str(ordinal))
            cluster = head_cluster if lang == head_lang and cleaned == head.canonical_text else _claim(
                "mapping", lang or "unknown", cleaned,
            )
            mapping_occurrences.append(NormalizedOccurrence(
                mapping_claim,
                "equivalent",
                raw_value,
                cleaned,
                lang,
                locale,
                cluster,
                entry.entry_key,
                None,
                {"labels": item.get("labels", []), "mapping_ordinal": ordinal, "entry_level": True},
                (error,) if error else (),
            ))
            for reading_ordinal, raw_reading in enumerate(item.get("readings") or (), 1):
                if not isinstance(raw_reading, dict):
                    continue
                raw_reading_value = raw_reading.get("value")
                raw_scheme = raw_reading.get("scheme")
                if not isinstance(raw_reading_value, str) or not raw_reading_value.strip() or not isinstance(raw_scheme, str):
                    continue
                if raw_scheme.strip().lower() == "hakka-pinyin":
                    reading_scheme = "hakka-pinyin"
                    reading_locale = str(raw_reading.get("locale") or locale or "hak-Hant-TW")
                    reading_value = canonicalize_text(raw_reading_value)
                    reading_errors: tuple[str, ...] = ()
                else:
                    reading_scheme = raw_scheme
                    reading_locale = str(raw_reading.get("locale") or locale) if (raw_reading.get("locale") or locale) else None
                    reading_value = canonicalize_text(raw_reading_value)
                    reading_errors = ("unknown_reading_scheme",)
                extended_readings.append(NormalizedReading(
                    _claim(mapping_claim, "reading", str(reading_ordinal)),
                    entry.entry_key,
                    raw_reading_value,
                    reading_value,
                    reading_scheme,
                    reading_locale,
                    reading_errors,
                    mapping_claim,
                ))
        senses: list[NormalizedSense] = []
        for sense in entry.senses:
            occurrences: list[NormalizedOccurrence] = []
            equivalent_texts: set[str] = set()

            def add_occurrence(raw_value: str, hint: str | None, kind: str, ordinal: str, extra: dict[str, Any]) -> None:
                cleaned = canonicalize_text(raw_value)
                bullet = cleaned.startswith("•")
                if bullet:
                    cleaned = cleaned[1:].lstrip()
                # ``Crown`` mixes romanized pinyin into equivalents.  Pinyin is
                # a reading, not a word: fold it into the headword reading when
                # the headword is Chinese, otherwise drop it instead of creating
                # a bogus expression node.
                if (crown or head_lang == "cmn") and kind == "equivalent" and _is_pinyin_spelling(cleaned):
                    if head_lang == "cmn":
                        extended_readings.append(NormalizedReading(
                            _claim("entry", entry.entry_key, "sense", sense.sense_key, "reading", f"eq{ordinal}"),
                            entry.entry_key, raw_value, cleaned, "pinyin", "cmn-Hant-TW", (),
                        ))
                    return
                # Crown supplies Chinese/Japanese direction only, while its
                # equivalent list also contains unlabelled English glosses.
                # Pinyin was handled above; a remaining Latin expression is an
                # English gloss and must not inherit the direction target.
                if crown and kind == "equivalent" and _is_latin_expression(cleaned):
                    lang, locale, error = "eng", "eng-Latn-US", None
                else:
                    lang, locale, error = _language(cleaned, hint)
                occurrences.append(NormalizedOccurrence(
                    _claim("entry", entry.entry_key, "sense", sense.sense_key, kind, ordinal),
                    kind, raw_value, cleaned, lang, locale,
                    _claim("claim", entry.entry_key, sense.sense_key, kind, ordinal),
                    entry.entry_key, sense.sense_key, {**(extra or {}), "bullet_removed": extra.get("bullet_removed", bullet)},
                    (error,) if error else (),
                ))
                equivalent_texts.add(cleaned.lower())

            for ordinal, raw_item in enumerate(sense.equivalents, 1):
                item = raw_item if isinstance(raw_item, dict) else {"value": raw_item}
                raw_value = item.get("value") or item.get("text")
                if not isinstance(raw_value, str) or not raw_value.strip():
                    continue
                hint = item.get("language") or item.get("language_hint") or _side_hint(direction_hint, False)
                add_occurrence(raw_value, hint, "equivalent", str(ordinal), {"bullet_removed": False})

            # Some OUP bundles (Kannada, Telugu, Malayalam, ...) store the
            # foreign equivalence inside the definition list rather than as a
            # separate equivalents entry. A definition carrying a distinctive
            # non-Latin script that differs from the headword language (e.g.
            # Kannada/Telugu inside an English-headword bundle) is the
            # target-language equivalent, whereas a Latin-script or same-language
            # definition is a plain meaning and stays untouched.
            for ordinal, definition in enumerate(sense.definitions, 1):
                if not isinstance(definition, str) or not definition.strip():
                    continue
                cleaned = canonicalize_text(definition)
                # Kannada/Telugu/Malayalam OUP definitions are a semicolon-joined
                # list inside one sense; the trailing ``;`` is a list separator,
                # not part of the word.
                cleaned = cleaned.rstrip(";").rstrip()
                # A stray leading sentence punctuation (e.g. ``.腦力。``) is a
                # source-data blemish, not part of the meaning.
                cleaned = cleaned.lstrip(".,，。、·").strip()
                if not cleaned or cleaned.lower() in equivalent_texts:
                    continue
                if head_lang in {"cmn", "yue", "hak"} and _is_han(cleaned):
                    continue
                # A Chinese/Spanish/English definition may contain a single
                # Greek or Cyrillic symbol as notation; it is not a language
                # switch. Require two distinctive-script characters here.
                distinctive = [char for char in cleaned if _script_language(char)]
                if len(distinctive) < 2:
                    continue
                inferred = _script_language(cleaned)
                if inferred is None or inferred == head_lang:
                    continue
                lang, _, _ = _language(cleaned, inferred)
                if lang is None:
                    continue
                add_occurrence(cleaned, inferred, "equivalent", f"def{ordinal}", {"definition_sourced": True})
            for ordinal, raw_item in enumerate(sense.relations, 1):
                item = raw_item if isinstance(raw_item, dict) else {}
                if item.get("kind") != "synonym":
                    # Antonyms remain fully available in input_relations.raw_json,
                    # but the first online model has no opposition edge kind.
                    continue
                raw_value = item.get("raw_related_text") or item.get("related_text") or item.get("text")
                if not isinstance(raw_value, str) or not raw_value.strip():
                    continue
                cleaned = canonicalize_text(raw_value)
                hint = item.get("language_hint") or item.get("language") or _side_hint(direction_hint, False)
                lang, locale, error = _language(cleaned, hint)
                occurrences.append(NormalizedOccurrence(
                    _claim("entry", entry.entry_key, "sense", sense.sense_key, "synonym", str(ordinal)),
                    "synonym", raw_value, cleaned, lang, locale,
                    _claim("claim", entry.entry_key, sense.sense_key, "synonym", str(ordinal)),
                    entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                ))
            for ordinal, raw_item in enumerate(sense.examples, 1):
                item = raw_item if isinstance(raw_item, dict) else {"text": raw_item}
                example_claim_prefix = _claim(
                    "entry", entry.entry_key, "sense", sense.sense_key,
                    "example", str(ordinal),
                )
                locale: str | None = None
                text = item.get("text")
                if isinstance(text, str) and text.strip():
                    lang, locale, error = _language(
                        text,
                        item.get("language") or item.get("language_hint") or _side_hint(direction_hint, True),
                    )
                    occurrences.append(NormalizedOccurrence(
                        example_claim_prefix + ":text",
                        "example", text, canonicalize_text(text), lang, locale,
                        _claim("claim", entry.entry_key, sense.sense_key, "example", str(ordinal), "text"),
                        entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                    ))
                translation = item.get("translation")
                if isinstance(translation, str) and translation.strip():
                    lang, locale, error = _language(translation, item.get("translation_language") or _side_hint(direction_hint, False))
                    occurrences.append(NormalizedOccurrence(
                        example_claim_prefix + ":translation",
                        "example", translation, canonicalize_text(translation), lang, locale,
                        _claim("claim", entry.entry_key, sense.sense_key, "example", str(ordinal), "translation"),
                        entry.entry_key, sense.sense_key, {}, (error,) if error else (),
                    ))
                for reading_ordinal, raw_reading in enumerate(item.get("readings") or (), 1):
                    if not isinstance(raw_reading, dict):
                        continue
                    raw_value = raw_reading.get("value")
                    scheme = raw_reading.get("scheme")
                    if not isinstance(raw_value, str) or not raw_value.strip() or not isinstance(scheme, str):
                        continue
                    upper_scheme = scheme.strip().upper()
                    if "JYUTPING" in upper_scheme:
                        normalized_scheme = "jyutping"
                        value = _canonical_jyutping(raw_value)
                        reading_locale = str(raw_reading.get("locale") or locale or "yue-Hant-HK")
                        reading_errors: tuple[str, ...] = ()
                    else:
                        normalized_scheme = scheme
                        value = canonicalize_text(raw_value)
                        reading_locale = str(raw_reading.get("locale") or locale) if (raw_reading.get("locale") or locale) else None
                        reading_errors = ("unknown_reading_scheme",)
                    extended_readings.append(NormalizedReading(
                        example_claim_prefix + ":reading:" + str(reading_ordinal),
                        entry.entry_key,
                        raw_value,
                        value,
                        normalized_scheme,
                        reading_locale,
                        reading_errors,
                        example_claim_prefix + ":text",
                    ))
            pos = tuple(self._pos(sense.sense_key, entry.entry_key, index, value) for index, value in enumerate(sense.pos, 1))
            senses.append(NormalizedSense(sense.sense_key, tuple(occurrences), tuple(extended_readings), pos))
        if form_occurrences and senses:
            first = senses[0]
            senses[0] = NormalizedSense(first.sense_key, first.occurrences + tuple(form_occurrences), first.readings, first.pos)
        return NormalizedEntry(
            entry.dictionary_key,
            entry.entry_key,
            head,
            tuple(senses),
            tuple(extended_readings),
            entry.raw,
            tuple(mapping_occurrences),
        )

    def _reading(
        self,
        entry: StagedEntry,
        index: int,
        item: Any,
        yue_readings: set[str],
        head_lang: str | None,
        fold_pinyin: bool = False,
        relation_readings: set[str] | None = None,
    ) -> NormalizedReading:
        scheme = item.scheme
        upper = scheme.upper()
        if scheme.strip().lower() == "hakka-pinyin":
            normalized_scheme = "hakka-pinyin"
            locale = str(item.raw.get("locale") or "hak-Hant-TW")
            errors = ()
            value = canonicalize_text(item.value)
        elif "IPA" in upper:
            # Apple's Chinese->English bundles store the headword pinyin under a
            # ``UK_IPA``-style scheme. Tone-marked Latin is pinyin, not an
            # English IPA reading, so reclassify it to the Chinese locale.
            if head_lang in {"cmn", "yue"} and _has_pinyin_tone_marks(item.value):
                normalized_scheme, locale, errors = "pinyin", "cmn-Hant-TW", ()
                value = canonicalize_text(item.value)
            else:
                normalized_scheme = "ipa"
                locale = "eng-Latn-GB" if upper.startswith("UK") else "eng-Latn-US" if upper.startswith("US") else None
                errors = () if locale else ("unknown_locale",)
                value = canonicalize_text(item.value)
        elif "PINYIN" in upper or "BOPOMOFO" in upper:
            normalized_scheme = "pinyin" if "PINYIN" in upper else "bopomofo"
            locale = "cmn-Hant-TW"
            errors = ()
            value = canonicalize_text(item.value)
        elif "JYUTPING" in upper:
            normalized_scheme, locale, errors = "jyutping", str(item.raw.get("locale") or "yue-Hant-HK"), ()
            value = _canonical_jyutping(item.value)
        elif upper in {"TL", "TAILO", "TAI-LO"}:
            normalized_scheme, locale, errors = "tailo", str(item.raw.get("locale") or "nan-Hant-TW"), ()
            value = canonicalize_text(item.value)
        elif scheme.strip().lower() == "shanghai-church-romanization":
            normalized_scheme = "shanghai-church-romanization"
            locale = str(item.raw.get("locale") or "wuu-Hant-CN_Shanghai")
            errors = ()
            value = canonicalize_text(item.value)
        elif scheme.strip().isdigit() and fold_pinyin and _is_pinyin_spelling(str(item.value)):
            # ``Crown`` pronunciations carry only the tone number as their
            # scheme (``1``) alongside the pinyin value; classify as pinyin.
            normalized_scheme, locale, errors = "pinyin", "cmn-Hant-TW", ()
            value = canonicalize_text(item.value)
        else:
            normalized_scheme, locale, errors = scheme, None, ("unknown_reading_scheme",)
            value = canonicalize_text(item.value)
            # Apple's Cantonese bundles also spell the headword Jyutping in a
            # spaced-tone form under the legacy ``unknown`` scheme. Publish only
            # the value that collapses onto the entry's own canonical reading;
            # example-sentence transcriptions stay quarantined.
            candidate = _canonical_jyutping(item.value)
            if candidate in yue_readings:
                normalized_scheme, locale, value, errors = "jyutping", str(item.raw.get("locale") or "yue-Hant-HK"), candidate, ()
        if normalized_scheme == "ipa" and _has_ipa_incompatible_script(value):
            locale, errors = None, ("reading_script_mismatch",)
        elif value in (relation_readings or set()):
            locale, errors = None, ("relation_reading_as_headword",)
        return NormalizedReading(_claim("entry", entry.entry_key, "reading", str(index)), entry.entry_key, item.value, value, normalized_scheme, locale, errors)

    def _pos(self, sense_key: str, entry_key: str, index: int, value: Any) -> NormalizedPos:
        raw = value if isinstance(value, str) else value.get("value") if isinstance(value, dict) else str(value)
        code = _POS.get(raw.strip().lower()) if isinstance(raw, str) else None
        errors = () if code else ("unknown_pos",)
        return NormalizedPos(_claim("sense", sense_key, "pos", str(index)), sense_key, raw, code, errors)


def normalize_release(
    connection,
    release_id: str,
    adapter: TraditionalChineseEnglishAdapter | None = None,
    *,
    resume: bool = False,
    resume_after: tuple[str, str] | None = None,
    batch_size: int = 500,
    commit_every: int = 10_000,
    progress: Callable[[dict[str, Any]], None] | None = None,
    defer_foreign_keys: bool = False,
    timings: dict[str, float] | None = None,
) -> int:
    if batch_size <= 0:
        raise ValueError("batch_size must be greater than zero")
    if commit_every <= 0:
        raise ValueError("commit_every must be greater than zero")
    component_timings = timings if timings is not None else {}
    timing_keys = (
        "normalize_staging_read",
        "normalize_compute",
        "normalize_sqlite_flush",
        "normalize_checkpoint_commit",
        "normalize_foreign_key_check",
    )
    component_timings.update({key: 0.0 for key in timing_keys})
    foreign_keys_enabled = bool(connection.execute("PRAGMA foreign_keys").fetchone()[0])
    restore_foreign_keys = defer_foreign_keys and foreign_keys_enabled
    if restore_foreign_keys:
        # SQLite only changes this PRAGMA outside an active transaction.
        connection.commit()
        connection.execute("PRAGMA foreign_keys = OFF")
    try:
        count = _normalize_release_rows(
            connection,
            release_id,
            adapter=adapter,
            resume=resume,
            resume_after=resume_after,
            batch_size=batch_size,
            commit_every=commit_every,
            progress=progress,
            timings=component_timings,
        )
        check_started = time.perf_counter()
        try:
            if defer_foreign_keys:
                violation = connection.execute("PRAGMA foreign_key_check").fetchone()
                if violation is not None:
                    raise sqlite3.IntegrityError(f"staging foreign key violation: {tuple(violation)!r}")
        finally:
            component_timings["normalize_foreign_key_check"] += time.perf_counter() - check_started
        for key in timing_keys:
            component_timings[key] = round(component_timings[key], 6)
        if progress is not None:
            processed = connection.execute(
                "SELECT processed_entries FROM normalization_progress WHERE release_id=?",
                (release_id,),
            ).fetchone()
            progress({
                "phase": "normalize",
                "step": "completed",
                "processed_entries": int(processed[0]) if processed is not None else count,
                "status": "completed",
                "timings": _timing_snapshot(component_timings),
            })
        return count
    finally:
        if restore_foreign_keys:
            if connection.in_transaction:
                connection.rollback()
            connection.execute("PRAGMA foreign_keys = ON")


def _normalize_release_rows(
    connection,
    release_id: str,
    adapter: TraditionalChineseEnglishAdapter | None = None,
    *,
    resume: bool = False,
    resume_after: tuple[str, str] | None = None,
    batch_size: int = 500,
    commit_every: int = 10_000,
    progress: Callable[[dict[str, Any]], None] | None = None,
    timings: dict[str, float] | None = None,
) -> int:
    timings = timings if timings is not None else {}
    adapter = adapter or TraditionalChineseEnglishAdapter()
    checkpoint = connection.execute(
        "SELECT last_entry_rowid,processed_entries FROM normalization_progress WHERE release_id=?",
        (release_id,),
    ).fetchone()
    start_rowid = int(checkpoint["last_entry_rowid"]) if resume and checkpoint else 0
    processed_entries = int(checkpoint["processed_entries"]) if resume and checkpoint else 0
    existing_entries: set[str] = set()
    if resume and checkpoint is None and resume_after is not None:
        cursor = connection.execute(
            "SELECT rowid FROM input_entries WHERE release_id=? AND dictionary_key=? AND entry_key=?",
            (release_id, resume_after[0], resume_after[1]),
        ).fetchone()
        if cursor is None:
            raise ValueError(f"unknown staged entry cursor: {resume_after!r}")
        start_rowid = int(cursor[0])
    elif resume and checkpoint is None:
        existing_entries = {
            str(row[0])
            for row in connection.execute(
                "SELECT entry_key FROM lexical_occurrences NOT INDEXED "
                "WHERE release_id=? AND occurrence_kind='headword'",
                (release_id,),
            )
        }
        processed_entries = len(existing_entries)
    if not resume:
        # Normalized rows invalidate any clusters built by an earlier run. This
        # must be explicit when bulk mode temporarily disables FK cascades.
        connection.execute("DELETE FROM cluster_members WHERE release_id=?", (release_id,))
        connection.execute("DELETE FROM lexical_clusters WHERE release_id=?", (release_id,))
        connection.execute("DELETE FROM normalized_pos WHERE release_id=?", (release_id,))
        connection.execute("DELETE FROM lexical_readings WHERE release_id=?", (release_id,))
        connection.execute("DELETE FROM lexical_occurrences WHERE release_id=?", (release_id,))
        connection.execute(
            "DELETE FROM quarantine_items WHERE release_id=? AND claim_key IS NOT NULL",
            (release_id,),
        )
        connection.execute("DELETE FROM normalization_progress WHERE release_id=?", (release_id,))
    count = 0
    occurrence_rows: list[tuple[Any, ...]] = []
    reading_rows: list[tuple[Any, ...]] = []
    pos_rows: list[tuple[Any, ...]] = []
    quarantine_rows: list[tuple[Any, ...]] = []

    def flush() -> None:
        started = time.perf_counter()
        try:
            if occurrence_rows:
                occurrence_rows.sort(key=lambda row: row[1])
                connection.executemany("INSERT INTO lexical_occurrences VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", occurrence_rows)
                occurrence_rows.clear()
            if reading_rows:
                reading_rows.sort(key=lambda row: row[1])
                connection.executemany("INSERT INTO lexical_readings VALUES (?,?,?,?,?,?,?,?,?)", reading_rows)
                reading_rows.clear()
            if pos_rows:
                pos_rows.sort(key=lambda row: row[1])
                connection.executemany("INSERT INTO normalized_pos VALUES (?,?,?,?,?,?)", pos_rows)
                pos_rows.clear()
            if quarantine_rows:
                quarantine_rows.sort(key=lambda row: str(row[4]))
                connection.executemany(
                    "INSERT OR IGNORE INTO quarantine_items(release_id,dictionary_key,entry_key,sense_key,claim_key,error_code,detail,raw_json) VALUES (?,?,?,?,?,?,?,?)",
                    quarantine_rows,
                )
                quarantine_rows.clear()
        finally:
            timings["normalize_sqlite_flush"] += time.perf_counter() - started

    def checkpoint(status: str) -> None:
        started = time.perf_counter()
        try:
            connection.execute(
                "INSERT INTO normalization_progress(release_id,last_entry_rowid,processed_entries,status) VALUES (?,?,?,?) "
                "ON CONFLICT(release_id) DO UPDATE SET last_entry_rowid=excluded.last_entry_rowid,processed_entries=excluded.processed_entries,status=excluded.status",
                (release_id, last_rowid, processed_entries + count, status),
            )
            connection.commit()
        finally:
            timings["normalize_checkpoint_commit"] += time.perf_counter() - started

    def timed_entries():
        iterator = iter(iter_staged_entry_rows(
            connection, release_id, start_rowid=start_rowid, batch_size=batch_size
        ))
        while True:
            started = time.perf_counter()
            try:
                item = next(iterator)
            except StopIteration:
                timings["normalize_staging_read"] += time.perf_counter() - started
                return
            timings["normalize_staging_read"] += time.perf_counter() - started
            yield item

    last_rowid = start_rowid
    for rowid, entry in timed_entries():
        last_rowid = rowid
        if entry.entry_key in existing_entries:
            continue
        compute_started = time.perf_counter()
        try:
            normalized = adapter.normalize_entry(entry)
            values = (
                normalized.headword,
                *(occurrence for sense in normalized.senses for occurrence in sense.occurrences),
                *normalized.mappings,
            )
            for occurrence in values:
                occurrence_rows.append((release_id, occurrence.claim_key, occurrence.occurrence_kind, occurrence.entry_key, occurrence.sense_key, occurrence.raw_value, occurrence.canonical_text, occurrence.lang_code, occurrence.locale_code, occurrence.cluster_key, _fast_json.dumps(occurrence.metadata, ensure_ascii=False, sort_keys=True), _fast_json.dumps(occurrence.errors, ensure_ascii=False)))
                if occurrence.errors:
                    quarantine_rows.append((release_id, entry.dictionary_key, entry.entry_key, occurrence.sense_key, occurrence.claim_key, occurrence.errors[0], "normalization failed", _fast_json.dumps(entry.raw, ensure_ascii=False, sort_keys=True)))
            for reading in normalized.readings:
                reading_rows.append((release_id, reading.claim_key, reading.entry_key, reading.raw_value, reading.value, reading.scheme, reading.locale_code, _fast_json.dumps(reading.errors, ensure_ascii=False), reading.target_claim_key))
                if reading.errors:
                    quarantine_rows.append((release_id, entry.dictionary_key, entry.entry_key, None, reading.claim_key, reading.errors[0], "normalization failed", _fast_json.dumps(entry.raw, ensure_ascii=False, sort_keys=True)))
            for sense in normalized.senses:
                for pos in sense.pos:
                    pos_rows.append((release_id, pos.claim_key, pos.sense_key, pos.raw_value, pos.code, _fast_json.dumps(pos.errors, ensure_ascii=False)))
        finally:
            timings["normalize_compute"] += time.perf_counter() - compute_started
        count += 1
        flush_due = count % batch_size == 0
        commit_due = count % commit_every == 0
        if flush_due or commit_due:
            flush()
        if commit_due:
            checkpoint("running")
        if (flush_due or commit_due) and progress is not None:
            progress({
                "phase": "normalize",
                "step": "checkpoint" if commit_due else "flush",
                "processed_entries": processed_entries + count,
                "status": "running",
                "timings": _timing_snapshot(timings),
            })
    flush()
    checkpoint("completed")
    processed_entries += count
    return count


def _timing_snapshot(timings: dict[str, float]) -> dict[str, float]:
    return {key: round(value, 3) for key, value in timings.items()}
