from .base import DictionaryAdapter
from .registry import adapter_for_dictionary_key, adapter_for_release
from .traditional_chinese_english import TraditionalChineseEnglishAdapter, normalize_release
from .wikivoyage_phrasebook import WikivoyagePhrasebookAdapter

__all__ = [
    "DictionaryAdapter",
    "TraditionalChineseEnglishAdapter",
    "WikivoyagePhrasebookAdapter",
    "adapter_for_dictionary_key",
    "adapter_for_release",
    "normalize_release",
]
