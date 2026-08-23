"""Deterministic, offline-only features used for sense reconciliation.

This module deliberately returns plain structured values.  It never assigns an
online expression id and it never turns a definition, label, or example into a
database object.
"""

from __future__ import annotations

import hashlib
import json
import sqlite3
from dataclasses import asdict, dataclass, field
from typing import Any, Iterable


def _json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def _array(value: Any) -> tuple[str, ...]:
    value = _parse(value)
    if not isinstance(value, list):
        return ()
    values = [item if isinstance(item, str) else _json(item) for item in value]
    return tuple(sorted({item.strip() for item in values if item.strip()}))


def _raw_array(value: Any) -> tuple[str, ...]:
    value = _parse(value)
    if not isinstance(value, list):
        return ()
    return tuple(item if isinstance(item, str) else _json(item) for item in value)


def _parse(value: Any) -> Any:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value


def _row_value(row: sqlite3.Row | dict[str, Any], key: str, default: Any = None) -> Any:
    try:
        return row[key]
    except (IndexError, KeyError):
        return default


@dataclass(frozen=True, order=True)
class CandidateKey:
    """Canonical unordered pair key."""

    left_claim_key: str
    right_claim_key: str

    def __post_init__(self) -> None:
        if not self.left_claim_key or not self.right_claim_key:
            raise ValueError("candidate claim keys must be non-empty")
        if self.left_claim_key >= self.right_claim_key:
            raise ValueError("candidate keys must be lexically ordered")

    @property
    def value(self) -> str:
        return f"{self.left_claim_key}\0{self.right_claim_key}"

    def to_dict(self) -> dict[str, str]:
        return {"left_claim_key": self.left_claim_key, "right_claim_key": self.right_claim_key}

    @classmethod
    def from_dict(cls, value: Any) -> "CandidateKey":
        if not isinstance(value, dict) or set(value) != {"left_claim_key", "right_claim_key"}:
            raise ValueError("candidate_key must contain exactly left_claim_key and right_claim_key")
        return cls(value["left_claim_key"], value["right_claim_key"])


@dataclass(frozen=True)
class CandidateFeatures:
    language_code: str
    canonical_text: str
    left_claim_key: str
    right_claim_key: str
    left_pos: tuple[str, ...] = ()
    right_pos: tuple[str, ...] = ()
    left_definitions: tuple[str, ...] = ()
    right_definitions: tuple[str, ...] = ()
    left_labels: tuple[str, ...] = ()
    right_labels: tuple[str, ...] = ()
    left_examples: tuple[str, ...] = ()
    right_examples: tuple[str, ...] = ()
    left_equivalent_neighbors: tuple[tuple[str, str], ...] = ()
    right_equivalent_neighbors: tuple[tuple[str, str], ...] = ()
    left_raw_evidence_order: tuple[str, ...] = ()
    right_raw_evidence_order: tuple[str, ...] = ()
    left_homograph_marker: str | None = None
    right_homograph_marker: str | None = None
    left_dictionary_key: str = ""
    right_dictionary_key: str = ""
    left_adapter_id: str = ""
    right_adapter_id: str = ""
    left_published_expression_ids: tuple[str, ...] = ()
    right_published_expression_ids: tuple[str, ...] = ()
    left_binding_ambiguous: bool = False
    right_binding_ambiguous: bool = False
    completeness_codes: tuple[str, ...] = ()
    features_fingerprint: str = field(default="", compare=True)

    def __post_init__(self) -> None:
        expected = fingerprint_features(self)
        if self.features_fingerprint and self.features_fingerprint != expected:
            raise ValueError("features_fingerprint does not match canonical features")
        object.__setattr__(self, "features_fingerprint", expected)

    def to_dict(self, *, include_fingerprint: bool = True) -> dict[str, Any]:
        result = asdict(self)
        for key in (
            "left_pos", "right_pos", "left_definitions", "right_definitions",
            "left_labels", "right_labels", "left_examples", "right_examples",
            "left_raw_evidence_order", "right_raw_evidence_order", "left_published_expression_ids",
            "right_published_expression_ids", "completeness_codes",
        ):
            result[key] = list(result[key])
        result["left_equivalent_neighbors"] = [list(item) for item in self.left_equivalent_neighbors]
        result["right_equivalent_neighbors"] = [list(item) for item in self.right_equivalent_neighbors]
        if not include_fingerprint:
            result.pop("features_fingerprint", None)
        return result

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "CandidateFeatures":
        required = {"language_code", "canonical_text", "left_claim_key", "right_claim_key"}
        if not isinstance(value, dict) or not required <= set(value):
            raise ValueError("features missing required fields")
        allowed = set(cls.__dataclass_fields__)
        unknown = set(value) - allowed
        if unknown:
            raise ValueError(f"features has unknown fields: {', '.join(sorted(unknown))}")
        kwargs = dict(value)
        for key in (
            "left_pos", "right_pos", "left_definitions", "right_definitions", "left_labels",
            "right_labels", "left_examples", "right_examples", "left_raw_evidence_order",
            "right_raw_evidence_order", "left_published_expression_ids", "right_published_expression_ids",
            "completeness_codes",
        ):
            kwargs[key] = tuple(kwargs.get(key, ()))
        for key in ("left_equivalent_neighbors", "right_equivalent_neighbors"):
            kwargs[key] = tuple(tuple(item) for item in kwargs.get(key, ()))
        return cls(**kwargs)


def fingerprint_features(features: CandidateFeatures) -> str:
    payload = features.to_dict(include_fingerprint=False)
    return hashlib.sha256(_json(payload).encode("utf-8")).hexdigest()


def _sense_for_occurrence(connection: sqlite3.Connection, release_id: str, occurrence: sqlite3.Row) -> sqlite3.Row | None:
    sense_key = _row_value(occurrence, "sense_key")
    if not sense_key:
        return None
    return connection.execute(
        "SELECT * FROM input_senses WHERE release_id=? AND sense_key=?", (release_id, sense_key)
    ).fetchone()


def _published_bindings(connection: sqlite3.Connection, release_id: str, claim_key: str) -> tuple[str, ...]:
    """Read optional compiler bindings without requiring the online schema."""
    tables = {row[0] for row in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    if "dictionary_expression_bindings" not in tables:
        return ()
    columns = {row[1] for row in connection.execute("PRAGMA table_info(dictionary_expression_bindings)")}
    if not {"release_id", "claim_key", "expression_id"} <= columns:
        return ()
    rows = connection.execute(
        "SELECT DISTINCT expression_id FROM dictionary_expression_bindings WHERE release_id=? AND claim_key=? ORDER BY expression_id",
        (release_id, claim_key),
    )
    return tuple(str(row[0]) for row in rows)


def _one_features(connection: sqlite3.Connection, release_id: str, occurrence: sqlite3.Row) -> dict[str, Any]:
    sense = _sense_for_occurrence(connection, release_id, occurrence)
    definitions = _array(_row_value(sense, "definitions_json", [])) if sense else ()
    labels = _array(_row_value(sense, "labels_json", [])) if sense else ()
    examples = _array(_row_value(sense, "examples_json", [])) if sense else ()
    pos = _array(_row_value(sense, "pos_json", [])) if sense else ()
    raw_order = _raw_array(_row_value(sense, "equivalents_json", [])) if sense else ()
    neighbors: list[tuple[str, str]] = []
    if sense:
        equivalents = _parse(_row_value(sense, "equivalents_json", []))
        for item in equivalents if isinstance(equivalents, list) else []:
            if isinstance(item, str):
                text, language = item.strip(), ""
            elif isinstance(item, dict):
                text = str(item.get("value") or item.get("text") or "").strip()
                language = str(item.get("language") or item.get("language_hint") or "").strip()
            else:
                continue
            if text:
                neighbors.append((language, text))
    metadata = _parse(_row_value(occurrence, "metadata_json", {}))
    metadata = metadata if isinstance(metadata, dict) else {}
    errors = _parse(_row_value(occurrence, "errors_json", []))
    errors = errors if isinstance(errors, list) else []
    entry = connection.execute(
        "SELECT * FROM input_entries WHERE release_id=? AND entry_key=?",
        (release_id, _row_value(occurrence, "entry_key")),
    ).fetchone()
    dictionary_key = str(_row_value(entry, "dictionary_key", "")) if entry else ""
    adapter_id = str(metadata.get("adapter_id", dictionary_key))
    published = _published_bindings(connection, release_id, str(_row_value(occurrence, "claim_key")))
    return {
        "pos": pos, "definitions": definitions, "labels": labels, "examples": examples,
        "neighbors": tuple(sorted(set(neighbors))), "raw_order": raw_order,
        "homograph_marker": _row_value(entry, "homograph_marker") if entry else metadata.get("homograph_marker"),
        "dictionary_key": dictionary_key, "adapter_id": adapter_id,
        "published": published, "binding_ambiguous": len(published) > 1 or bool(metadata.get("fallback_identity_ambiguous") or metadata.get("identity_ambiguous")),
        "errors": tuple(str(item) for item in errors),
    }


def build_features(connection: sqlite3.Connection, release_id: str, left: str | CandidateKey, right: str | None = None) -> CandidateFeatures:
    """Build features for two claims in stable form."""
    if isinstance(left, CandidateKey):
        key = left
    else:
        if right is None:
            raise ValueError("right claim key is required")
        key = CandidateKey(left, right) if left < right else CandidateKey(right, left)
    rows = [connection.execute(
        "SELECT * FROM lexical_occurrences WHERE release_id=? AND claim_key=?", (release_id, claim)
    ).fetchone() for claim in (key.left_claim_key, key.right_claim_key)]
    if any(row is None for row in rows):
        missing = [claim for claim, row in zip((key.left_claim_key, key.right_claim_key), rows) if row is None]
        raise KeyError(f"unknown claim key(s): {', '.join(missing)}")
    left_row, right_row = rows  # type: ignore[misc]
    left_details, right_details = _one_features(connection, release_id, left_row), _one_features(connection, release_id, right_row)
    languages = {str(_row_value(left_row, "lang_code", "")), str(_row_value(right_row, "lang_code", ""))}
    text = str(_row_value(left_row, "canonical_text", ""))
    completeness: set[str] = set(left_details["errors"]) | set(right_details["errors"])
    if not left_details["definitions"] and not left_details["neighbors"] and not left_details["examples"]:
        completeness.add("left_semantic_evidence_missing")
    if not right_details["definitions"] and not right_details["neighbors"] and not right_details["examples"]:
        completeness.add("right_semantic_evidence_missing")
    if len(languages) > 1:
        completeness.add("different_language")
    if str(_row_value(right_row, "canonical_text", "")) != text:
        completeness.add("different_text")
    return CandidateFeatures(
        language_code=str(_row_value(left_row, "lang_code", "")), canonical_text=text,
        left_claim_key=key.left_claim_key, right_claim_key=key.right_claim_key,
        left_pos=left_details["pos"], right_pos=right_details["pos"],
        left_definitions=left_details["definitions"], right_definitions=right_details["definitions"],
        left_labels=left_details["labels"], right_labels=right_details["labels"],
        left_examples=left_details["examples"], right_examples=right_details["examples"],
        left_equivalent_neighbors=left_details["neighbors"], right_equivalent_neighbors=right_details["neighbors"],
        left_raw_evidence_order=left_details["raw_order"], right_raw_evidence_order=right_details["raw_order"],
        left_homograph_marker=left_details["homograph_marker"], right_homograph_marker=right_details["homograph_marker"],
        left_dictionary_key=left_details["dictionary_key"], right_dictionary_key=right_details["dictionary_key"],
        left_adapter_id=left_details["adapter_id"], right_adapter_id=right_details["adapter_id"],
        left_published_expression_ids=left_details["published"], right_published_expression_ids=right_details["published"],
        left_binding_ambiguous=left_details["binding_ambiguous"], right_binding_ambiguous=right_details["binding_ambiguous"],
        completeness_codes=tuple(sorted(completeness)),
    )
