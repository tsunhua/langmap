"""Adapter protocol for dictionary-specific offline normalization."""

from __future__ import annotations

from typing import Protocol

from ..models import NormalizedEntry, StagedEntry


class DictionaryAdapter(Protocol):
    id: str

    def normalize_entry(self, entry: StagedEntry) -> NormalizedEntry:
        """Normalize one staged entry without assigning online expression IDs."""
