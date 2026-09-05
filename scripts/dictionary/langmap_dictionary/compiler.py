"""Compile normalized staging rows into an idempotent managed D1 release."""

from __future__ import annotations

import base64
import hashlib
import json
import sqlite3
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Mapping

from .artifact import ReleaseArtifact, canonical_json, write_release_artifact
from .sql import insert_or_ignore, sql_literal, transaction, update_release_status

_BASE32 = "abcdefghijklmnopqrstuvwxyz234567"


def expression_text_hash(text: str) -> str:
    digest = hashlib.sha256(text.strip().encode("utf-8")).digest()[:16]
    bits = "".join(f"{byte:08b}" for byte in digest)
    return "".join(_BASE32[int(bits[index : index + 5].ljust(5, "0"), 2)] for index in range(0, 128, 5))


def build_expression_id(lang_code: str, text: str, homograph_index: int = 1) -> str:
    text_hash = expression_text_hash(text)
    return f"{lang_code}:{text_hash}" if homograph_index == 1 else f"{lang_code}:{text_hash}.{homograph_index}"


@dataclass(frozen=True)
class D1Inventory:
    expressions_by_identity: Mapping[Any, Any] = field(default_factory=dict)
    bindings_by_claim: Mapping[str, str] = field(default_factory=dict)
    edges_by_pair: Mapping[Any, str] = field(default_factory=dict)
    max_homograph_by_text: Mapping[Any, int] = field(default_factory=dict)
    fingerprint: str = ""


@dataclass(frozen=True)
class ReleaseArtifactResult:
    artifact: ReleaseArtifact
    expressions: int
    edges: int
    bindings: int
    chunks: int

    @property
    def root(self) -> Path:
        return self.artifact.root

    @property
    def manifest_hash(self) -> str:
        return self.artifact.manifest_hash


def _key(lang: str, text: str) -> tuple[str, str]:
    return lang, text


def _lookup(mapping: Mapping[Any, Any], lang: str, text: str) -> Any:
    return mapping.get((lang, text), mapping.get(f"{lang}:{text}"))


def _known_expression_ids(inventory: D1Inventory) -> set[str]:
    known: set[str] = set()
    for key, value in inventory.expressions_by_identity.items():
        if isinstance(value, str):
            known.add(value)
        if isinstance(key, str) and ":" in key:
            known.add(key)
    return known


def _entry_headwords(connection: sqlite3.Connection, release_id: str) -> dict[str, sqlite3.Row]:
    return {
        str(row["entry_key"]): row
        for row in connection.execute(
            "SELECT * FROM lexical_occurrences WHERE release_id=? AND occurrence_kind='headword' ORDER BY entry_key, claim_key",
            (release_id,),
        )
    }


def _allocate_clusters(connection: sqlite3.Connection, release_id: str, inventory: D1Inventory) -> tuple[dict[str, str], list[dict[str, Any]], set[str]]:
    known_ids = _known_expression_ids(inventory)
    cluster_to_expression: dict[str, str] = {}
    expression_rows: list[dict[str, Any]] = []
    allocated: set[str] = set()
    rows = connection.execute(
        "SELECT cluster_key, lang_code, canonical_text FROM lexical_clusters WHERE release_id=? AND lang_code IS NOT NULL ORDER BY lang_code, canonical_text, cluster_key",
        (release_id,),
    )
    claims_by_cluster: dict[str, list[str]] = defaultdict(list)
    for member in connection.execute(
        "SELECT cluster_key, claim_key FROM cluster_members WHERE release_id=? ORDER BY cluster_key, claim_key",
        (release_id,),
    ):
        claims_by_cluster[str(member["cluster_key"])].append(str(member["claim_key"]))
    used_indexes: dict[tuple[str, str], int] = {
        (str(key[0]), str(key[1])): int(value)
        for key, value in inventory.max_homograph_by_text.items()
        if isinstance(key, tuple) and len(key) == 2
    }
    for row in rows:
        cluster = str(row["cluster_key"])
        lang, text = str(row["lang_code"]), str(row["canonical_text"])
        claims = claims_by_cluster.get(cluster, [])
        parents = sorted({inventory.bindings_by_claim[claim] for claim in claims if claim in inventory.bindings_by_claim})
        if len(parents) > 1:
            raise ValueError(f"published_identity_conflict:{cluster}")
        if parents:
            expression_id = parents[0]
            action = "reused"
        else:
            identity = _key(lang, text)
            index = used_indexes.get(identity, 0) + 1
            used_indexes[identity] = index
            expression_id = build_expression_id(lang, text, index)
            action = "created"
            allocated.add(expression_id)
            expression_rows.append({"id": expression_id, "lang_code": lang, "text": text, "text_hash": expression_text_hash(text), "homograph_index": index, "object_action": action})
        cluster_to_expression[cluster] = expression_id
        if action == "reused":
            known_ids.add(expression_id)
    return cluster_to_expression, expression_rows, allocated


def _occurrence_bindings(connection: sqlite3.Connection, release_id: str, cluster_to_expression: Mapping[str, str]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    role_by_kind = {"headword": "headword", "equivalent": "equivalent", "synonym": "synonym", "example": "example_text"}
    ai_claims = {
        str(row[0])
        for row in connection.execute(
            "SELECT left_cluster_key FROM merge_decisions WHERE release_id=? AND decision='merge' "
            "UNION SELECT right_cluster_key FROM merge_decisions WHERE release_id=? AND decision='merge'",
            (release_id, release_id),
        )
    }
    explicit_group_sizes = {
        str(row[0]): int(row[1])
        for row in connection.execute(
            "SELECT cluster_key,COUNT(*) FROM cluster_members WHERE release_id=? GROUP BY cluster_key",
            (release_id,),
        )
    }
    for row in connection.execute("SELECT * FROM lexical_occurrences WHERE release_id=? AND lang_code IS NOT NULL AND errors_json='[]' ORDER BY claim_key", (release_id,)):
        expression_id = cluster_to_expression.get(str(row["cluster_key"]))
        if expression_id is None:
            continue
        kind = str(row["occurrence_kind"])
        role = "example_translation" if kind == "example" and str(row["claim_key"]).endswith(":translation") else role_by_kind.get(kind)
        if role is None:
            continue
        claim_key = str(row["claim_key"])
        cluster_key = str(row["cluster_key"])
        binding_kind = "ai_merged" if claim_key in ai_claims else (
            "explicit_group" if explicit_group_sizes.get(cluster_key, 0) > 1 else ""
        )
        rows.append({"claim_key": claim_key, "cluster_key": cluster_key, "role": role, "expression_id": expression_id, "entry_key": row["entry_key"], "sense_key": row["sense_key"], "binding_kind": binding_kind})
    return rows


def _reconciliation_config_hash(connection: sqlite3.Connection, release_id: str) -> str:
    hashes: set[str] = set()
    for row in connection.execute(
        "SELECT rationale_json FROM merge_decisions WHERE release_id=? ORDER BY decision_key",
        (release_id,),
    ):
        try:
            value = json.loads(str(row[0]))
        except (TypeError, ValueError) as error:
            raise ValueError("invalid reconciliation rationale JSON") from error
        if isinstance(value, dict) and value.get("config_hash"):
            hashes.add(str(value["config_hash"]))
    if len(hashes) > 1:
        raise ValueError("staging release contains multiple reconciliation config hashes")
    return next(iter(hashes), "")


def _edge_id(left: str, right: str) -> str:
    a, b = sorted((left, right))
    digest = hashlib.sha256(f"dictionary:{a}:{b}".encode("utf-8")).hexdigest()[:32]
    return f"dict-edge:{digest}"


def _pair_key(left: str, right: str) -> tuple[str, str]:
    return tuple(sorted((left, right)))


def _compile_statements(connection: sqlite3.Connection, release_id: str, inventory: D1Inventory, cluster_ids: Mapping[str, str], expression_rows: list[dict[str, Any]], binding_rows: list[dict[str, Any]], allocated: set[str], metadata: Mapping[str, Any]) -> tuple[list[str], dict[str, Any]]:
    statements: list[str] = []
    statements.append(insert_or_ignore("dictionary_dataset_releases", ["id", "dataset_key", "parent_release_id", "input_manifest_hash", "exporter_schema_version", "adapter_bundle_hash", "reconciliation_config_hash", "artifact_hash", "status"], [release_id, metadata.get("dataset_key", "managed-dictionaries"), metadata.get("parent_release_id"), metadata.get("input_manifest_hash", ""), metadata.get("exporter_schema_version", 2), metadata.get("adapter_bundle_hash", ""), metadata.get("reconciliation_config_hash", ""), metadata.get("artifact_hash", ""), "planned"]))
    for row in expression_rows:
        statements.append(insert_or_ignore("expressions", ["id", "lang_code", "text", "text_hash", "homograph_index", "description", "tags_json", "review_status"], [row["id"], row["lang_code"], row["text"], row["text_hash"], row["homograph_index"], "", "[]", "approved"]))
    for row in binding_rows:
        binding_kind = row.get("binding_kind") or ("allocated" if row["expression_id"] in allocated else "reused")
        statements.append(insert_or_ignore("dictionary_expression_bindings", ["release_id", "claim_key", "cluster_key", "role", "expression_id", "binding_kind"], [release_id, row["claim_key"], row["cluster_key"], row["role"], row["expression_id"], binding_kind]))
    # Headword/equivalent and explicit synonym pairs are online edges.
    # Example text/translation pairs are separate mappings; definitions and
    # labels remain in offline staging.
    by_claim = {str(row["claim_key"]): row for row in binding_rows}
    head_by_sense: dict[str, dict[str, Any]] = {}
    for row in binding_rows:
        if row["role"] == "headword":
            head_by_sense[str(row["entry_key"])] = row
    evidence_count = edge_count = 0
    for row in binding_rows:
        if row["role"] not in {"equivalent", "synonym"}:
            continue
        head = head_by_sense.get(str(row["entry_key"]))
        if head is None or head["expression_id"] == row["expression_id"]:
            continue
        left, right = sorted((head["expression_id"], row["expression_id"]))
        pair = _pair_key(left, right)
        edge_id = inventory.edges_by_pair.get(pair) or inventory.edges_by_pair.get("|".join(pair)) or _edge_id(left, right)
        statements.append(insert_or_ignore("expression_edges", ["id", "expression_a_id", "expression_b_id", "score", "source"], [edge_id, left, right, 0, "dictionary"]))
        evidence_kind = "synonym" if row["role"] == "synonym" else "equivalent"
        statements.append(insert_or_ignore("expression_edge_evidence", ["release_id", "edge_id", "claim_key", "evidence_kind"], [release_id, edge_id, row["claim_key"], evidence_kind]))
        edge_count += 1
        evidence_count += 1
    example_pairs: dict[tuple[str, str, str], dict[str, dict[str, Any]]] = {}
    for row in binding_rows:
        if row["role"] not in {"example_text", "example_translation"}:
            continue
        claim = str(row["claim_key"])
        try:
            prefix, suffix = claim.rsplit(":example:", 1)
            ordinal, side = suffix.split(":", 1)
        except ValueError:
            continue
        example_pairs.setdefault((str(row["entry_key"]), prefix, ordinal), {})[side] = row
    for pair_rows in example_pairs.values():
        text_row = pair_rows.get("text")
        translation_row = pair_rows.get("translation")
        if text_row is None or translation_row is None or text_row["expression_id"] == translation_row["expression_id"]:
            continue
        left, right = sorted((text_row["expression_id"], translation_row["expression_id"]))
        pair = _pair_key(left, right)
        edge_id = inventory.edges_by_pair.get(pair) or inventory.edges_by_pair.get("|".join(pair)) or _edge_id(left, right)
        statements.append(insert_or_ignore("expression_edges", ["id", "expression_a_id", "expression_b_id", "score", "source"], [edge_id, left, right, 0, "dictionary"]))
        statements.append(insert_or_ignore("expression_edge_evidence", ["release_id", "edge_id", "claim_key", "evidence_kind"], [release_id, edge_id, translation_row["claim_key"], "example"]))
        edge_count += 1
        evidence_count += 1
    for row in connection.execute("SELECT * FROM normalized_pos WHERE release_id=? AND code IS NOT NULL AND errors_json='[]' ORDER BY sense_key, claim_key", (release_id,)):
        head = head_by_sense.get(str(row["sense_key"]).split(":s", 1)[0])
        if head is None:
            continue
        statements.append(insert_or_ignore("expression_pos_attestations", ["release_id", "expression_id", "pos_code", "claim_key"], [release_id, head["expression_id"], row["code"], row["claim_key"]]))
    for row in connection.execute("SELECT * FROM lexical_readings WHERE release_id=? AND errors_json='[]' ORDER BY claim_key", (release_id,)):
        target_claim_key = row["target_claim_key"]
        target = by_claim.get(str(target_claim_key)) if target_claim_key else None
        head = head_by_sense.get(str(row["entry_key"])) if target is None else target
        if head is None or not row["locale_code"]:
            continue
        reading_id = f"dict-reading:{release_id}:{row['claim_key']}"
        statements.append(insert_or_ignore("expression_readings", ["id", "expression_id", "language_locale_code", "scheme", "value"], [reading_id, head["expression_id"], row["locale_code"], row["scheme"], row["value"]]))
    statements.append(update_release_status(release_id, "validated"))
    return statements, {"expressions": len(expression_rows), "bindings": len(binding_rows), "edges": edge_count, "evidence": evidence_count}


def compile_release(staging_db: sqlite3.Connection | Path, release_id: str, inventory: D1Inventory, output_dir: Path, *, chunk_statement_count: int = 500) -> ReleaseArtifactResult:
    connection = staging_db if isinstance(staging_db, sqlite3.Connection) else sqlite3.connect(str(staging_db))
    connection.row_factory = sqlite3.Row
    release = connection.execute("SELECT * FROM staging_releases WHERE id=?", (release_id,)).fetchone()
    if release is None or release["status"] != "staged":
        raise ValueError(f"release is not staged: {release_id}")
    cluster_ids, expression_rows, allocated = _allocate_clusters(connection, release_id, inventory)
    bindings = _occurrence_bindings(connection, release_id, cluster_ids)
    metadata = {"dataset_key": "managed-dictionaries", "input_manifest_hash": release["manifest_hash"], "exporter_schema_version": 2, "adapter_bundle_hash": "", "reconciliation_config_hash": _reconciliation_config_hash(connection, release_id), "input_fingerprint": inventory.fingerprint}
    statements, counts = _compile_statements(connection, release_id, inventory, cluster_ids, expression_rows, bindings, allocated, metadata)
    chunks: dict[str, bytes] = {}
    for offset in range(0, len(statements), max(1, chunk_statement_count)):
        number = offset // max(1, chunk_statement_count) + 1
        chunks[f"sql/{number:05d}.sql"] = transaction(statements[offset : offset + max(1, chunk_statement_count)]).encode("utf-8")
    quality = {"release_id": release_id, **counts, "staged_entries": release["staged_entries"], "staged_senses": release["staged_senses"]}
    artifact = write_release_artifact(output_dir, release_id=release_id, metadata={**metadata, "expected_counts": counts}, files=chunks, chunks=chunks.keys(), quality_report=quality)
    return ReleaseArtifactResult(artifact, counts["expressions"], counts["edges"], counts["bindings"], len(chunks))
