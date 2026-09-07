"""Explicit dictionary adapter dispatch."""

from __future__ import annotations

from typing import Any

from .base import DictionaryAdapter
from .traditional_chinese_english import TraditionalChineseEnglishAdapter
from .wikivoyage_phrasebook import WikivoyagePhrasebookAdapter


def adapter_for_dictionary_key(dictionary_key: str) -> DictionaryAdapter:
    if str(dictionary_key).startswith("enwikivoyage:"):
        return WikivoyagePhrasebookAdapter()
    return TraditionalChineseEnglishAdapter()


def adapter_for_release(connection: Any, release_id: str) -> DictionaryAdapter:
    keys = [
        str(row[0])
        for row in connection.execute(
            "SELECT DISTINCT dictionary_key FROM input_entries WHERE release_id=? ORDER BY dictionary_key",
            (release_id,),
        )
    ]
    if not keys:
        raise ValueError(f"release has no staged dictionary entries: {release_id}")
    adapters = {adapter_for_dictionary_key(key).id for key in keys}
    if len(adapters) != 1:
        raise ValueError(f"release mixes dictionary adapters: {keys}")
    return adapter_for_dictionary_key(keys[0])


__all__ = ["adapter_for_dictionary_key", "adapter_for_release"]

