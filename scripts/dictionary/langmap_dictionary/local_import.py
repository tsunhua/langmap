"""Write normalized dictionary data directly into canonical D1 tables."""

from __future__ import annotations

import json
import sqlite3
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

RELATION_MAPPING = 1
RELATION_SYNONYM = 2
RELATION_EXAMPLE = 4


@dataclass(frozen=True)
class LocalImportSummary:
    run_id: str
    expressions: int
    locale_links: int
    readings: int
    edges: int
    pos_updates: int
    chunks: int
    rows_per_second: float = 0.0
    d1_bytes_delta: int = 0

    @property
    def release_id(self) -> str:
        return self.run_id

    @property
    def bindings(self) -> int:
        return self.locale_links

    @property
    def evidence(self) -> int:
        return self.edges

    @property
    def pos_attestations(self) -> int:
        return self.pos_updates


def canonical_text(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip())


def _columns(connection: sqlite3.Connection, table: str) -> set[str]:
    return {str(row[1]) for row in connection.execute(f"PRAGMA table_info({table})")}


def _insert_ignore(connection: sqlite3.Connection, table: str, values: Mapping[str, Any]) -> None:
    values = {key: value for key, value in values.items() if key in _columns(connection, table)}
    if not values:
        raise ValueError(f"canonical table has no supported columns: {table}")
    keys = sorted(values)
    connection.execute(
        f"INSERT OR IGNORE INTO {table} ({','.join(keys)}) VALUES ({','.join('?' for _ in keys)})",
        tuple(values[key] for key in keys),
    )


# ISO 639-3 macrolanguage codes used by Apple dictionary bundles that the
# LangMap registry does not pin (it keeps individual-language codes only).
# Dictionary imports must resolve these to the pinned individual code instead
# of silently expanding the registry.
_LANGUAGE_CODE_ALIASES: dict[str, str] = {
    "msa": "zsm",  # Malay → Standard Malay
    "ara": "arb",  # Arabic → Standard Arabic
    "nor": "nob",  # Norwegian → Norwegian Bokmål
}


def _resolve_language_code(connection: sqlite3.Connection, code: str) -> str | None:
    if connection.execute("SELECT 1 FROM languages WHERE code=?", (code,)).fetchone() is not None:
        return code
    if code in _LANGUAGE_CODE_ALIASES:
        alias = _LANGUAGE_CODE_ALIASES[code]
        if connection.execute("SELECT 1 FROM languages WHERE code=?", (alias,)).fetchone() is not None:
            return alias
    return None


def _language_id(connection: sqlite3.Connection, code: str) -> int | None:
    resolved = _resolve_language_code(connection, code)
    if resolved is None:
        return None
    row = connection.execute("SELECT id FROM languages WHERE code=?", (resolved,)).fetchone()
    return int(row[0]) if row is not None else None


def _locale_parts(code: str, language_code: str, language_id: int) -> dict[str, Any]:
    parts = code.split("-")
    script = next((part for part in parts[1:] if len(part) == 4), None)
    region = next((part for part in parts[1:] if len(part) in (2, 3) and part != script), None)
    return {
        "code": code, "language_id": language_id, "lang_code": language_code,
        "script_code": script or "Zyyy", "orthography": None,
        "region_code": region, "place_path": "", "name": code, "name_en": code,
    }


def _locale_id(connection: sqlite3.Connection, code: str, language_code: str) -> int:
    row = connection.execute("SELECT id FROM language_locales WHERE code=?", (code,)).fetchone()
    if row is None:
        resolved = _resolve_language_code(connection, language_code)
        if resolved is None:
            raise ValueError(f"unable to register locale with unknown language: {code} ({language_code})")
        language_id = _language_id(connection, resolved)
        if language_id is None:
            raise ValueError(f"unable to register locale language: {language_code}")
        _insert_ignore(connection, "language_locales", _locale_parts(code, resolved, language_id))
        row = connection.execute("SELECT id FROM language_locales WHERE code=?", (code,)).fetchone()
    if row is None:
        raise ValueError(f"unable to register locale: {code}")
    return int(row[0])


def _source_id(connection: sqlite3.Connection, dictionary_key: str, source_catalog: Mapping[str, Mapping[str, Any]] | None) -> int | None:
    configured = dict((source_catalog or {}).get(dictionary_key, {}))
    source_type = str(configured.get("type", "publication"))
    if source_type not in {"publication", "url", "system"}:
        source_type = "publication"
    source_name = str(configured.get("name", dictionary_key))
    row = connection.execute("SELECT id FROM sources WHERE type=? AND name=?", (source_type, source_name)).fetchone()
    if row is None:
        _insert_ignore(connection, "sources", {"type": source_type, "name": source_name})
        row = connection.execute("SELECT id FROM sources WHERE type=? AND name=?", (source_type, source_name)).fetchone()
    return int(row[0]) if row is not None else None


def _source_rank(dictionary_key: str, source_catalog: Mapping[str, Mapping[str, Any]] | None) -> int:
    return int((source_catalog or {}).get(dictionary_key, {}).get("source_rank", 0))


def _pos_mask(connection: sqlite3.Connection, codes: set[str]) -> int:
    mask = 0
    columns = _columns(connection, "parts_of_speech")
    for code in sorted(codes):
        row = connection.execute("SELECT * FROM parts_of_speech WHERE code=?", (code,)).fetchone()
        if row is None:
            continue
        names = set(row.keys()) if hasattr(row, "keys") else set()
        bit = int(row["bit_index"]) if "bit_index" in names else int(row["sort_order"]) - 1
        if 0 <= bit <= 62:
            mask |= 1 << bit
    return mask


def _load_rows(connection: sqlite3.Connection, run_id: str) -> tuple[dict[str, sqlite3.Row], dict[str, sqlite3.Row], dict[str, list[str]]]:
    occurrences = {
        str(row["claim_key"]): row
        for row in connection.execute(
            "SELECT o.*,e.dictionary_key FROM lexical_occurrences o JOIN input_entries e "
            "ON e.release_id=o.release_id AND e.entry_key=o.entry_key "
            "WHERE o.release_id=? AND o.lang_code IS NOT NULL AND o.errors_json='[]' ORDER BY o.claim_key", (run_id,)
        )
    }
    clusters = {str(row["cluster_key"]): row for row in connection.execute("SELECT * FROM lexical_clusters WHERE release_id=? ORDER BY lang_code,canonical_text,cluster_key", (run_id,))}
    members: dict[str, list[str]] = {}
    for row in connection.execute("SELECT cluster_key,claim_key FROM cluster_members WHERE release_id=? ORDER BY cluster_key,claim_key", (run_id,)):
        members.setdefault(str(row["cluster_key"]), []).append(str(row["claim_key"]))
    return occurrences, clusters, members


def _expression_for_cluster(connection: sqlite3.Connection, cluster: sqlite3.Row, cluster_members: list[str], claim_rows: Mapping[str, sqlite3.Row], sense_pos: Mapping[str, set[str]], source_catalog: Mapping[str, Mapping[str, Any]] | None) -> int:
    language_code = str(cluster["lang_code"])
    text = canonical_text(str(cluster["canonical_text"]))
    language_id = _language_id(connection, language_code)
    if language_id is None:
        raise ValueError(f"dictionary language not in registry: {language_code}")
    source_keys = sorted({str(claim_rows[key]["dictionary_key"]) for key in cluster_members if key in claim_rows})
    source_key = max(source_keys or ["dictionary"], key=lambda key: (_source_rank(key, source_catalog), key))
    source_id = _source_id(connection, source_key, source_catalog)
    existing = connection.execute("SELECT homograph_index FROM expressions WHERE language_id=? AND text=? ORDER BY homograph_index", (language_id, text)).fetchall()
    homograph = int(existing[-1][0]) + 1 if existing else 1
    pos_codes = set().union(*(sense_pos.get(str(claim_rows[key]["sense_key"]), set()) for key in cluster_members if key in claim_rows))
    connection.execute(
        "INSERT INTO expressions(language_id,text,homograph_index,pos_mask,source_id) VALUES (?,?,?,?,?) "
        "ON CONFLICT(language_id,text,homograph_index) DO UPDATE SET pos_mask=expressions.pos_mask | excluded.pos_mask",
        (language_id, text, homograph, _pos_mask(connection, pos_codes), source_id),
    )
    row = connection.execute("SELECT id FROM expressions WHERE language_id=? AND text=? AND homograph_index=?", (language_id, text, homograph)).fetchone()
    if row is None:
        raise ValueError(f"unable to create canonical expression: {language_code}:{text}:{homograph}")
    return int(row[0])


def _upsert_reading(connection: sqlite3.Connection, expression_id: int, locale_id: int, scheme: str, value: str, source_id: int | None, source_rank: int = 0) -> bool:
    existing = connection.execute(
        "SELECT source_id FROM expression_readings WHERE expression_id=? AND locale_id=? AND scheme=? AND value=?",
        (expression_id, locale_id, scheme, canonical_text(value)),
    ).fetchone()
    if existing is not None:
        return False
    _insert_ignore(connection, "expression_readings", {"expression_id": expression_id, "locale_id": locale_id, "scheme": scheme, "value": canonical_text(value), "source_id": source_id})
    return True


def _upsert_edge(connection: sqlite3.Connection, left: int, right: int, relation_mask: int, created_by: int | None) -> bool:
    if left == right:
        return False
    left, right = sorted((int(left), int(right)))
    if "relation_mask" not in _columns(connection, "expression_edges"):
        raise ValueError("canonical expression_edges.relation_mask is required")
    before = connection.total_changes
    connection.execute(
        "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask,score,created_by) VALUES (?,?,?,?,?) "
        "ON CONFLICT(expression_a_id,expression_b_id) DO UPDATE SET relation_mask=expression_edges.relation_mask | excluded.relation_mask",
        (left, right, relation_mask, 0, created_by),
    )
    return connection.total_changes > before


def import_release_to_local_d1(
    staging_database: Path, d1_database: Path, release_id: str, *, activate: bool = True,
    packed: bool = False, append: bool = False, chunk_size: int = 5_000,
    source_catalog: Mapping[str, Mapping[str, Any]] | None = None, system_user_id: int | None = None,
) -> LocalImportSummary:
    """Import one staged run into final canonical tables.

    The legacy keyword arguments are accepted so callers can migrate without
    changing their invocation; they do not create or update any runtime
    release, binding, claim, evidence, or packed rows.
    """
    del activate, packed, append
    if chunk_size < 1:
        raise ValueError("chunk_size must be positive")
    connection = sqlite3.connect(Path(d1_database), timeout=300)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys=ON")
    staging = sqlite3.connect(Path(staging_database))
    staging.row_factory = sqlite3.Row
    try:
        run = staging.execute("SELECT * FROM staging_releases WHERE id=? AND status='staged'", (release_id,)).fetchone()
        if run is None:
            raise ValueError(f"run is not staged: {release_id}")
        occurrences, clusters, members = _load_rows(staging, release_id)
        sense_pos: dict[str, set[str]] = {}
        for row in staging.execute("SELECT sense_key,code FROM normalized_pos WHERE release_id=? AND code IS NOT NULL AND errors_json='[]'", (release_id,)):
            sense_pos.setdefault(str(row["sense_key"]), set()).add(str(row["code"]))
        connection.execute("BEGIN IMMEDIATE")
        for key in sorted({str(row["dictionary_key"]) for row in occurrences.values()}):
            _source_id(connection, key, source_catalog)
        ordered_clusters = sorted(clusters.items(), key=lambda item: (str(item[1]["lang_code"]), str(item[1]["canonical_text"]), item[0]))
        cluster_ids: dict[str, int] = {}
        for offset in range(0, len(ordered_clusters), chunk_size):
            for cluster_key, cluster in ordered_clusters[offset:offset + chunk_size]:
                cluster_ids[cluster_key] = _expression_for_cluster(connection, cluster, members.get(cluster_key, []), occurrences, sense_pos, source_catalog)
        links = readings = edges = 0
        for row in occurrences.values():
            expression_id = cluster_ids.get(str(row["cluster_key"]))
            if expression_id is None or not row["locale_code"]:
                continue
            locale_id = _locale_id(connection, str(row["locale_code"]), str(row["lang_code"]))
            before = connection.total_changes
            _insert_ignore(connection, "expression_locale_links", {"expression_id": expression_id, "locale_id": locale_id})
            links += int(connection.total_changes > before)
        head_by_entry: dict[str, int] = {}
        source_by_entry: dict[str, str] = {}
        for row in occurrences.values():
            if str(row["occurrence_kind"]) == "headword" and str(row["entry_key"]) not in head_by_entry:
                head_by_entry[str(row["entry_key"])] = cluster_ids.get(str(row["cluster_key"]))
                source_by_entry[str(row["entry_key"])] = str(row["dictionary_key"])
        for row in staging.execute("SELECT * FROM lexical_readings WHERE release_id=? AND errors_json='[]' ORDER BY claim_key", (release_id,)):
            expression_id = head_by_entry.get(str(row["entry_key"]))
            if expression_id is None or not row["locale_code"]:
                continue
            code = str(row["locale_code"])
            source_key = source_by_entry.get(str(row["entry_key"]), "dictionary")
            readings += int(_upsert_reading(connection, expression_id, _locale_id(connection, code, code.split("-", 1)[0]), str(row["scheme"]), str(row["value"]), _source_id(connection, source_key, source_catalog), _source_rank(source_key, source_catalog)))
        for row in occurrences.values():
            kind = str(row["occurrence_kind"])
            if kind not in {"equivalent", "synonym"}:
                continue
            head = head_by_entry.get(str(row["entry_key"]))
            target = cluster_ids.get(str(row["cluster_key"]))
            if head is None or target is None:
                continue
            relation = RELATION_SYNONYM if kind == "synonym" else RELATION_MAPPING
            edges += int(_upsert_edge(connection, head, target, relation, system_user_id))
        example_rows = {str(row["claim_key"]): row for row in occurrences.values() if str(row["occurrence_kind"]) == "example"}
        for claim_key, row in example_rows.items():
            if not claim_key.endswith(":translation"):
                continue
            text_row = example_rows.get(claim_key[: -len(":translation")] + ":text")
            if text_row is None:
                continue
            left = cluster_ids.get(str(text_row["cluster_key"]))
            right = cluster_ids.get(str(row["cluster_key"]))
            if left is not None and right is not None:
                edges += int(_upsert_edge(connection, left, right, RELATION_EXAMPLE, system_user_id))
        pos_updates = int(connection.execute("SELECT COUNT(*) FROM expressions WHERE pos_mask<>0").fetchone()[0]) if "pos_mask" in _columns(connection, "expressions") else 0
        connection.commit()
        return LocalImportSummary(release_id, len(cluster_ids), links, readings, edges, pos_updates, max(1, (len(ordered_clusters) + chunk_size - 1) // chunk_size))
    except Exception:
        connection.rollback()
        raise
    finally:
        staging.close()
        connection.close()
