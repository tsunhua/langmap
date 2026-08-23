"""Release-level conservation and profile gates for a staged corpus."""

from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from typing import Any, Mapping


@dataclass(frozen=True)
class QualityGate:
    input_records: int
    staged_entries: int
    staged_claims: int
    quarantined: int
    unknown_profiles: int
    unknown_directions: int
    passed: bool
    errors: tuple[str, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "input_records": self.input_records,
            "staged_entries": self.staged_entries,
            "staged_claims": self.staged_claims,
            "quarantined": self.quarantined,
            "unknown_profiles": self.unknown_profiles,
            "unknown_directions": self.unknown_directions,
            "passed": self.passed,
            "errors": list(self.errors),
        }


def evaluate_quality(connection: sqlite3.Connection, release_id: str, profiles: Mapping[str, Any]) -> QualityGate:
    release = connection.execute("SELECT * FROM staging_releases WHERE id=?", (release_id,)).fetchone()
    if release is None:
        raise ValueError(f"unknown release: {release_id}")
    input_records = int(release["input_records"])
    staged_entries = int(release["staged_entries"])
    staged_claims = int(connection.execute("SELECT COUNT(*) FROM input_senses WHERE release_id=?", (release_id,)).fetchone()[0])
    quarantined = int(connection.execute("SELECT COUNT(*) FROM quarantine_items WHERE release_id=?", (release_id,)).fetchone()[0])
    dictionaries = {str(row[0]) for row in connection.execute("SELECT DISTINCT dictionary_key FROM input_entries WHERE release_id=?", (release_id,))}
    unknown_profiles = len(dictionaries - set(profiles))
    unknown_directions = int(connection.execute("SELECT COUNT(*) FROM input_entries WHERE release_id=? AND (direction_hint IS NULL OR direction_hint='')", (release_id,)).fetchone()[0])
    errors: list[str] = []
    if input_records != staged_entries + int(release["quarantined"]):
        errors.append("entry_conservation")
    if unknown_profiles:
        errors.append("unknown_dictionary_profile")
    if unknown_directions:
        errors.append("unknown_direction")
    if release["status"] != "staged":
        errors.append("release_not_staged")
    return QualityGate(input_records, staged_entries, staged_claims, quarantined, unknown_profiles, unknown_directions, not errors, tuple(errors))
