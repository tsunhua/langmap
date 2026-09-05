"""Small immutable DTOs shared by the staging pipeline."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class StagedPronunciation:
    ordinal: int
    value: str
    scheme: str
    raw: dict[str, Any]


@dataclass(frozen=True)
class StagedSense:
    sense_key: str
    ordinal: int
    definitions: tuple[Any, ...] = ()
    pos: tuple[Any, ...] = ()
    equivalents: tuple[Any, ...] = ()
    relations: tuple[Any, ...] = ()
    examples: tuple[Any, ...] = ()
    labels: tuple[Any, ...] = ()
    raw: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class StagedEntry:
    release_id: str
    dictionary_key: str
    entry_key: str
    canonical_headword: str
    raw_headword: str
    homograph_marker: str | None
    direction_hint: str | None
    record_fingerprint: str
    pronunciations: tuple[StagedPronunciation, ...] = ()
    senses: tuple[StagedSense, ...] = ()
    forms: tuple[Any, ...] = ()
    raw: dict[str, Any] = field(default_factory=dict)
    mappings: tuple[Any, ...] = ()


@dataclass(frozen=True)
class NormalizedOccurrence:
    claim_key: str
    occurrence_kind: str
    raw_value: str
    canonical_text: str
    lang_code: str | None
    locale_code: str | None
    cluster_key: str
    entry_key: str
    sense_key: str | None
    metadata: dict[str, Any] = field(default_factory=dict)
    errors: tuple[str, ...] = ()


@dataclass(frozen=True)
class NormalizedReading:
    claim_key: str
    entry_key: str
    raw_value: str
    value: str
    scheme: str
    locale_code: str | None
    errors: tuple[str, ...] = ()
    target_claim_key: str | None = None


@dataclass(frozen=True)
class NormalizedPos:
    claim_key: str
    sense_key: str
    raw_value: str
    code: str | None
    errors: tuple[str, ...] = ()


@dataclass(frozen=True)
class NormalizedSense:
    sense_key: str
    occurrences: tuple[NormalizedOccurrence, ...]
    readings: tuple[NormalizedReading, ...] = ()
    pos: tuple[NormalizedPos, ...] = ()


@dataclass(frozen=True)
class NormalizedEntry:
    dictionary_key: str
    entry_key: str
    headword: NormalizedOccurrence
    senses: tuple[NormalizedSense, ...]
    readings: tuple[NormalizedReading, ...] = ()
    raw: dict[str, Any] = field(default_factory=dict)
    mappings: tuple[NormalizedOccurrence, ...] = ()


@dataclass(frozen=True)
class ClusterSummary:
    release_id: str
    clusters: int
    occurrences: int
    quarantined: int


@dataclass(frozen=True)
class PreviewManifest:
    release_id: str
    manifest_hash: str
    files: tuple[dict[str, Any], ...]
