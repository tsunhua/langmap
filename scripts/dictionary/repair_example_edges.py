#!/usr/bin/env python3
"""Repair dictionary edges whose old import classified examples as mappings.

The current Structured JSONL is the source of truth.  For one dictionary, the
script compares its explicit equivalents and example pairs with the canonical
mirror and emits a deterministic, idempotent SQL repair:

* equivalent pairs keep the mapping bit;
* example-only pairs keep the edge but become relation ``4``;
* the known old headword-to-example-translation pair loses that dictionary's
  provenance and is deleted only when no other source still claims the edge;
* unmatched legacy claims are reported but preserved for manual review.

Usage:
    python3 scripts/dictionary/repair_example_edges.py \
      --jsonl <structured.jsonl> \
      --mirror <canonical.sqlite> \
      --output <repair.split.sql> \
      --report <repair.report.json>
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
import unicodedata
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


RELATION_MAPPING = 1
RELATION_SYNONYM = 2
RELATION_EXAMPLE = 4
SEMANTIC_RELATIONS = RELATION_MAPPING | RELATION_SYNONYM
DEFAULT_SAMPLE_LIMIT = 12
EDGE_ID_CHUNK = 500

Pair = tuple[tuple[str, str], tuple[str, str]]


@dataclass(frozen=True)
class EdgeClaim:
    edge_id: int
    source_marker: str
    relation_mask: int
    pair: Pair
    source_claim_count: int
    source_count: int


def canonicalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFC", value.strip())
    without_period = normalized.rstrip(".．。 ").rstrip()
    return without_period or normalized


def _language_code(profile: str) -> str:
    token = profile.strip()
    if not token:
        raise ValueError("direction_hint contains an empty language profile")
    return token.split("-", 1)[0].lower()


def _direction(entry: dict[str, Any]) -> tuple[str, str]:
    value = entry.get("direction_hint")
    if not isinstance(value, str) or "-to-" not in value:
        raise ValueError(f"entry has no usable direction_hint: {entry.get('entry_key', '<unknown>')}")
    left, right = value.split("-to-", 1)
    return _language_code(left), _language_code(right)


def _pair(left: tuple[str, str], right: tuple[str, str]) -> Pair:
    return tuple(sorted((left, right)))  # type: ignore[return-value]


def _value(item: Any) -> str | None:
    if isinstance(item, str):
        value = item
    elif isinstance(item, dict) and isinstance(item.get("value"), str):
        value = item["value"]
    else:
        return None
    value = canonicalize_text(value)
    return value or None


def load_source_pairs(path: Path, dictionary_key: str | None = None) -> tuple[set[Pair], set[Pair], set[Pair], dict[str, Any]]:
    equivalents: set[Pair] = set()
    examples: set[Pair] = set()
    # Before relation masks were honoured, the importer connected each
    # headword directly to the example translation.  Keep this separate from
    # the proper example pair so the repair can remove that polluted edge.
    polluted_examples: set[Pair] = set()
    header: dict[str, Any] | None = None
    with path.open("r", encoding="utf-8-sig") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"invalid JSONL at line {line_number}: {path}") from exc
            if not isinstance(entry, dict):
                raise ValueError(f"JSONL record is not an object at line {line_number}: {path}")
            if line_number == 1 and entry.get("record_type") == "dictionary":
                header = entry
                actual_key = str(entry.get("dictionary_key", ""))
                if dictionary_key is not None and actual_key != dictionary_key:
                    raise ValueError(f"dictionary_key mismatch: header={actual_key!r}, requested={dictionary_key!r}")
                continue
            if entry.get("record_type") != "entry":
                continue
            source_key = str(entry.get("dictionary_key", ""))
            if header is not None and source_key != str(header.get("dictionary_key", "")):
                raise ValueError(f"entry dictionary_key differs from header at line {line_number}")
            left_code, right_code = _direction(entry)
            headword = _value(entry.get("canonical_headword"))
            if not headword:
                continue
            left = (left_code, headword)
            for sense in entry.get("senses", []):
                if not isinstance(sense, dict):
                    continue
                for equivalent in sense.get("equivalents", []):
                    target = _value(equivalent)
                    if target:
                        equivalents.add(_pair(left, (right_code, target)))
                for example in sense.get("examples", []):
                    if not isinstance(example, dict):
                        continue
                    text = example.get("text")
                    translation = example.get("translation")
                    if not isinstance(text, str) or not isinstance(translation, str):
                        continue
                    text = canonicalize_text(text)
                    translation = canonicalize_text(translation)
                    if text and translation:
                        examples.add(_pair((left_code, text), (right_code, translation)))
                        polluted_examples.add(_pair(left, (right_code, translation)))
    if header is None:
        raise ValueError(f"missing Structured JSONL v2 dictionary header: {path}")
    if int(header.get("entry_count", 0)) < 0:
        raise ValueError(f"invalid entry_count in header: {path}")
    return equivalents, examples, polluted_examples, header


def _connect(path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(path, timeout=300)
    connection.row_factory = sqlite3.Row
    return connection


def _source_id(connection: sqlite3.Connection, dictionary_key: str) -> int:
    row = connection.execute("SELECT id FROM sources WHERE name=?", (dictionary_key,)).fetchone()
    if row is None:
        raise ValueError(f"source is not present in mirror: {dictionary_key}")
    return int(row[0])


def _iter_claims(connection: sqlite3.Connection, source_id: int) -> Iterable[EdgeClaim]:
    query = """
        SELECT
          es.edge_id,
          es.source_marker,
          e.relation_mask,
          la.code AS left_code,
          ea.text AS left_text,
          lb.code AS right_code,
          eb.text AS right_text,
          all_sources.source_claim_count,
          all_sources.source_count
        FROM expression_edge_sources es
        JOIN expression_edges e ON e.id = es.edge_id
        JOIN expressions ea ON ea.id = e.expression_a_id
        JOIN languages la ON la.id = ea.language_id
        JOIN expressions eb ON eb.id = e.expression_b_id
        JOIN languages lb ON lb.id = eb.language_id
        JOIN (
          SELECT edge_id, COUNT(*) AS source_claim_count,
                 COUNT(DISTINCT source_id) AS source_count
          FROM expression_edge_sources
          GROUP BY edge_id
        ) all_sources ON all_sources.edge_id = es.edge_id
        WHERE es.source_id=?
        ORDER BY es.edge_id, es.source_marker
    """
    for row in connection.execute(query, (source_id,)):
        left = (str(row["left_code"]).lower(), canonicalize_text(str(row["left_text"])))
        right = (str(row["right_code"]).lower(), canonicalize_text(str(row["right_text"])))
        yield EdgeClaim(
            edge_id=int(row["edge_id"]),
            source_marker=str(row["source_marker"] or ""),
            relation_mask=int(row["relation_mask"]),
            pair=_pair(left, right),
            source_claim_count=int(row["source_claim_count"]),
            source_count=int(row["source_count"]),
        )


def _chunks(values: list[int], size: int = EDGE_ID_CHUNK) -> Iterable[list[int]]:
    for offset in range(0, len(values), size):
        yield values[offset:offset + size]


def _in_clause(values: list[int]) -> str:
    return ", ".join(str(value) for value in values)


def _write_sql(
    output: Path,
    *,
    source_id: int,
    source_only_example_edges: list[int],
    shared_example_edges: list[int],
    valid_equivalent_edges: list[int],
    stale_edges: list[int],
    stale_claim_edges: list[int],
    jsonl_sha256: str,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "-- Generated by scripts/dictionary/repair_example_edges.py.",
        f"-- source_id={source_id}; jsonl_sha256={jsonl_sha256}",
        "-- Relation bits: mapping=1, synonym=2, example=4.",
        "-- Unmatched legacy claims are intentionally preserved for review.",
    ]
    for chunk in _chunks(sorted(set(valid_equivalent_edges))):
        lines.append(
            "UPDATE expression_edges SET relation_mask = relation_mask | 1 "
            f"WHERE id IN ({_in_clause(chunk)}) AND (relation_mask & 1) = 0;"
        )
    for chunk in _chunks(sorted(set(source_only_example_edges))):
        lines.append(
            "UPDATE expression_edges SET relation_mask = 4 "
            f"WHERE id IN ({_in_clause(chunk)});"
        )
    for chunk in _chunks(sorted(set(shared_example_edges))):
        lines.append(
            "UPDATE expression_edges SET relation_mask = relation_mask | 4 "
            f"WHERE id IN ({_in_clause(chunk)});"
        )
    for chunk in _chunks(sorted(set(stale_claim_edges))):
        lines.append(
            "DELETE FROM expression_edge_sources "
            f"WHERE source_id={source_id} AND edge_id IN ({_in_clause(chunk)});"
        )
    for chunk in _chunks(sorted(set(stale_edges))):
        lines.append(
            "DELETE FROM expression_edges "
            f"WHERE id IN ({_in_clause(chunk)}) "
            "AND NOT EXISTS (SELECT 1 FROM expression_edge_sources s WHERE s.edge_id=expression_edges.id);"
        )
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _sample(claims: list[EdgeClaim], limit: int = DEFAULT_SAMPLE_LIMIT) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for claim in sorted(claims, key=lambda item: (item.edge_id, item.source_marker))[:limit]:
        rows.append({
            "edge_id": claim.edge_id,
            "source_marker": claim.source_marker,
            "relation_mask_before": claim.relation_mask,
            "source_claim_count": claim.source_claim_count,
            "source_count": claim.source_count,
            "left": {"lang": claim.pair[0][0], "text": claim.pair[0][1]},
            "right": {"lang": claim.pair[1][0], "text": claim.pair[1][1]},
        })
    return rows


def repair(
    jsonl: Path,
    mirror: Path,
    output: Path,
    report: Path,
    *,
    dictionary_key: str | None = None,
) -> dict[str, Any]:
    equivalents, examples, polluted_examples, header = load_source_pairs(jsonl, dictionary_key)
    connection = _connect(mirror)
    try:
        source_key = str(header["dictionary_key"])
        source_id = _source_id(connection, source_key)
        claims = list(_iter_claims(connection, source_id))
    finally:
        connection.close()

    by_edge: dict[int, list[EdgeClaim]] = defaultdict(list)
    for claim in claims:
        by_edge[claim.edge_id].append(claim)

    equivalent_claims: list[EdgeClaim] = []
    source_only_example_claims: list[EdgeClaim] = []
    shared_example_claims: list[EdgeClaim] = []
    equivalent_example_claims: list[EdgeClaim] = []
    polluted_claims: list[EdgeClaim] = []
    unmatched_claims: list[EdgeClaim] = []
    for claim in claims:
        if claim.pair in equivalents:
            equivalent_claims.append(claim)
            if claim.pair in examples:
                equivalent_example_claims.append(claim)
        elif claim.pair in examples:
            (source_only_example_claims if claim.source_count == 1 else shared_example_claims).append(claim)
        elif claim.pair in polluted_examples:
            polluted_claims.append(claim)
        else:
            unmatched_claims.append(claim)

    jsonl_sha256 = hashlib.sha256(jsonl.read_bytes()).hexdigest()
    polluted_edge_ids = sorted({claim.edge_id for claim in polluted_claims})
    # Deleting the source claim is sufficient for shared edges; the SQL then
    # removes only edges left without any provenance.
    _write_sql(
        output,
        source_id=source_id,
        source_only_example_edges=[claim.edge_id for claim in source_only_example_claims],
        shared_example_edges=[claim.edge_id for claim in shared_example_claims],
        valid_equivalent_edges=[claim.edge_id for claim in equivalent_claims],
        stale_edges=polluted_edge_ids,
        stale_claim_edges=polluted_edge_ids,
        jsonl_sha256=jsonl_sha256,
    )
    payload: dict[str, Any] = {
        "schema_version": 1,
        "jsonl": str(jsonl),
        "jsonl_sha256": jsonl_sha256,
        "dictionary_key": source_key,
        "source_id": source_id,
        "source_entry_count": int(header["entry_count"]),
        "source_equivalent_pair_count": len(equivalents),
        "source_example_pair_count": len(examples),
        "source_polluted_example_pair_count": len(polluted_examples),
        "mirror_source_claim_count": len(claims),
        "mirror_source_edge_count": len(by_edge),
        "valid_equivalent_claim_count": len(equivalent_claims),
        "equivalent_example_claim_count": len(equivalent_example_claims),
        "example_edge_claim_count": len(source_only_example_claims) + len(shared_example_claims) + len(equivalent_example_claims),
        "example_source_only_edge_count": len({claim.edge_id for claim in source_only_example_claims}),
        "example_shared_edge_count": len({claim.edge_id for claim in shared_example_claims}),
        "polluted_source_claim_count": len(polluted_claims),
        "polluted_edge_count": len({claim.edge_id for claim in polluted_claims}),
        "unmatched_source_claim_count": len(unmatched_claims),
        "unmatched_edge_count": len({claim.edge_id for claim in unmatched_claims}),
        "samples": {
            "valid_equivalent": _sample(equivalent_claims),
            "equivalent_example": _sample(equivalent_example_claims),
            "source_only_example": _sample(source_only_example_claims),
            "shared_example": _sample(shared_example_claims),
            "polluted_example": _sample(polluted_claims),
            "unmatched": _sample(unmatched_claims),
        },
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return payload


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jsonl", type=Path, required=True)
    parser.add_argument("--mirror", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--dictionary-key")
    args = parser.parse_args()
    payload = repair(args.jsonl, args.mirror, args.output, args.report, dictionary_key=args.dictionary_key)
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
