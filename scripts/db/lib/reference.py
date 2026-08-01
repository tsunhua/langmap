from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping


@dataclass(frozen=True)
class ReferenceDiff:
    inserts: tuple[str, ...]
    updates: tuple[str, ...]
    unchanged: tuple[str, ...]
    manual_review: tuple[str, ...]

    @property
    def counts(self) -> dict[str, int]:
        return {
            "insert": len(self.inserts),
            "update": len(self.updates),
            "unchanged": len(self.unchanged),
            "manual_review": len(self.manual_review),
            "delete": 0,
        }


def diff_owned_references(
    desired: Mapping[str, str],
    remote: Mapping[str, str],
    *,
    owned_keys: set[str],
) -> ReferenceDiff:
    inserts: list[str] = []
    updates: list[str] = []
    unchanged: list[str] = []
    manual_review: list[str] = []
    for key in sorted(desired):
        if key not in remote:
            inserts.append(key)
        elif key not in owned_keys:
            manual_review.append(key)
        elif remote[key] == desired[key]:
            unchanged.append(key)
        else:
            updates.append(key)
    for key in sorted(set(remote) - set(desired)):
        manual_review.append(key)
    return ReferenceDiff(
        inserts=tuple(inserts),
        updates=tuple(updates),
        unchanged=tuple(unchanged),
        manual_review=tuple(sorted(set(manual_review))),
    )
