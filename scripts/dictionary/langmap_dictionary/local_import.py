"""Write normalized dictionary data directly into canonical D1 tables."""

from __future__ import annotations

import json
import sqlite3
import time
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Mapping

RELATION_MAPPING = 1
RELATION_SYNONYM = 2
RELATION_EXAMPLE = 4
ProgressCallback = Callable[[dict[str, Any]], None]


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
    phase_seconds: Mapping[str, float] = field(default_factory=dict)

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


@dataclass(frozen=True)
class StagingSnapshot:
    occurrences: dict[str, sqlite3.Row]
    clusters: dict[str, sqlite3.Row]
    members: dict[str, list[str]]
    entry_sources: dict[str, str]


def canonical_text(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip())


# ISO 639-3 macrolanguage codes used by Apple dictionary bundles that the
# LangMap registry does not pin (it keeps individual-language codes only).
# Dictionary imports must resolve these to the pinned individual code instead
# of silently expanding the registry.
_LANGUAGE_CODE_ALIASES: dict[str, str] = {
    "msa": "zsm",  # Malay → Standard Malay
    "ara": "arb",  # Arabic → Standard Arabic
    "nor": "nob",  # Norwegian → Norwegian Bokmål
}


def _locale_parts(code: str, language_code: str, language_id: int) -> dict[str, Any]:
    parts = code.split("-")
    script = next((part for part in parts[1:] if len(part) == 4), None)
    region = next((part for part in parts[1:] if len(part) in (2, 3) and part != script), None)
    return {
        "code": code, "language_id": language_id, "lang_code": language_code,
        "script_code": script or "Zyyy", "orthography": None,
        "region_code": region, "place_path": "", "name": code, "name_en": code,
    }


def _source_rank(dictionary_key: str, source_catalog: Mapping[str, Mapping[str, Any]] | None) -> int:
    return int((source_catalog or {}).get(dictionary_key, {}).get("source_rank", 0))


@dataclass
class _CanonicalImportContext:
    connection: sqlite3.Connection
    source_catalog: Mapping[str, Mapping[str, Any]] | None
    column_cache: dict[str, set[str]] = field(default_factory=dict)
    resolved_language_cache: dict[str, str | None] = field(default_factory=dict)
    language_id_cache: dict[str, int | None] = field(default_factory=dict)
    locale_id_cache: dict[str, int] = field(default_factory=dict)
    source_id_cache: dict[tuple[str, str], int | None] = field(default_factory=dict)
    pos_bit_cache: dict[str, int | None] = field(default_factory=dict)
    pos_mask_cache: dict[tuple[str, ...], int] = field(default_factory=dict)

    def columns(self, table: str) -> set[str]:
        if table not in self.column_cache:
            self.column_cache[table] = {
                str(row[1]) for row in self.connection.execute(f"PRAGMA table_info({table})")
            }
        return self.column_cache[table]

    def insert_ignore(self, table: str, values: Mapping[str, Any]) -> None:
        supported = {key: value for key, value in values.items() if key in self.columns(table)}
        if not supported:
            raise ValueError(f"canonical table has no supported columns: {table}")
        keys = sorted(supported)
        self.connection.execute(
            f"INSERT OR IGNORE INTO {table} ({','.join(keys)}) VALUES ({','.join('?' for _ in keys)})",
            tuple(supported[key] for key in keys),
        )

    def resolve_language_code(self, code: str) -> str | None:
        if code not in self.resolved_language_cache:
            resolved = code if self.connection.execute(
                "SELECT 1 FROM languages WHERE code=?", (code,)
            ).fetchone() is not None else None
            if resolved is None and code in _LANGUAGE_CODE_ALIASES:
                alias = _LANGUAGE_CODE_ALIASES[code]
                if self.connection.execute(
                    "SELECT 1 FROM languages WHERE code=?", (alias,)
                ).fetchone() is not None:
                    resolved = alias
            self.resolved_language_cache[code] = resolved
            if resolved is not None:
                self.resolved_language_cache[resolved] = resolved
        return self.resolved_language_cache[code]

    def language_id(self, code: str) -> int | None:
        if code not in self.language_id_cache:
            resolved = self.resolve_language_code(code)
            row = None if resolved is None else self.connection.execute(
                "SELECT id FROM languages WHERE code=?", (resolved,)
            ).fetchone()
            self.language_id_cache[code] = int(row[0]) if row is not None else None
            if resolved is not None:
                self.language_id_cache[resolved] = self.language_id_cache[code]
        return self.language_id_cache[code]

    def locale_id(self, code: str, language_code: str) -> int:
        if code not in self.locale_id_cache:
            resolved = self.resolve_language_code(language_code)
            if resolved is None:
                raise ValueError(f"unable to register locale with unknown language: {code} ({language_code})")
            language_id = self.language_id(resolved)
            if language_id is None:
                raise ValueError(f"unable to register locale language: {language_code}")
            self.insert_ignore("language_locales", _locale_parts(code, resolved, language_id))
            row = self.connection.execute(
                "SELECT id FROM language_locales WHERE code=?", (code,)
            ).fetchone()
            if row is None:
                raise ValueError(f"unable to register locale: {code}")
            self.locale_id_cache[code] = int(row[0])
        return self.locale_id_cache[code]

    def source_id(self, dictionary_key: str) -> int | None:
        configured = dict((self.source_catalog or {}).get(dictionary_key, {}))
        source_type = str(configured.get("type", "publication"))
        if source_type not in {"publication", "url", "system"}:
            source_type = "publication"
        source_name = str(configured.get("name", dictionary_key))
        cache_key = (source_type, source_name)
        if cache_key not in self.source_id_cache:
            self.insert_ignore("sources", {"type": source_type, "name": source_name})
            row = self.connection.execute(
                "SELECT id FROM sources WHERE type=? AND name=?", cache_key
            ).fetchone()
            self.source_id_cache[cache_key] = int(row[0]) if row is not None else None
        return self.source_id_cache[cache_key]

    def pos_mask(self, codes: set[str]) -> int:
        cache_key = tuple(sorted(codes))
        if cache_key in self.pos_mask_cache:
            return self.pos_mask_cache[cache_key]
        columns = self.columns("parts_of_speech")
        mask = 0
        for code in cache_key:
            if code not in self.pos_bit_cache:
                row = self.connection.execute(
                    "SELECT * FROM parts_of_speech WHERE code=?", (code,)
                ).fetchone()
                bit = None
                if row is not None:
                    bit = int(row["bit_index"]) if "bit_index" in columns else int(row["sort_order"]) - 1
                self.pos_bit_cache[code] = bit if bit is not None and 0 <= bit <= 62 else None
            bit = self.pos_bit_cache[code]
            if bit is not None:
                mask |= 1 << bit
        self.pos_mask_cache[cache_key] = mask
        return mask


def _report_progress(
    progress: ProgressCallback | None,
    started: float,
    phase: str,
    step: str,
    processed: int,
    total: int | None = None,
) -> None:
    if progress is None:
        return
    event: dict[str, Any] = {
        "phase": phase,
        "step": step,
        "processed": processed,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
    }
    if total is not None:
        event["total"] = total
    progress(event)


def load_staging_snapshot(
    connection: sqlite3.Connection,
    run_id: str,
    *,
    progress: ProgressCallback | None = None,
    progress_every: int = 5_000,
) -> StagingSnapshot:
    """Load one staged release through sequential table scans."""

    if progress_every < 1:
        raise ValueError("progress_every must be positive")
    started = time.perf_counter()
    _report_progress(progress, started, "staging_load", "start", 0)
    entry_sources: dict[str, str] = {}
    for index, row in enumerate(connection.execute(
        "SELECT entry_key,dictionary_key FROM input_entries NOT INDEXED WHERE release_id=?",
        (run_id,),
    ), 1):
        entry_sources[str(row["entry_key"])] = str(row["dictionary_key"])
        if index % progress_every == 0:
            _report_progress(progress, started, "staging_load", "entry_sources", index)
    _report_progress(progress, started, "staging_load", "entry_sources", len(entry_sources), len(entry_sources))

    occurrences: dict[str, sqlite3.Row] = {}
    for index, row in enumerate(connection.execute(
        "SELECT * FROM lexical_occurrences NOT INDEXED "
        "WHERE release_id=? AND lang_code IS NOT NULL AND errors_json='[]'",
        (run_id,),
    ), 1):
        occurrences[str(row["claim_key"])] = row
        if index % progress_every == 0:
            _report_progress(progress, started, "staging_load", "occurrences", index)
    _report_progress(progress, started, "staging_load", "occurrences", len(occurrences), len(occurrences))
    for row in occurrences.values():
        entry_key = str(row["entry_key"])
        if entry_key not in entry_sources:
            raise ValueError(f"staging release {run_id} occurrence references missing entry source: {entry_key}")
    clusters: dict[str, sqlite3.Row] = {}
    for index, row in enumerate(connection.execute(
        "SELECT * FROM lexical_clusters NOT INDEXED WHERE release_id=?",
        (run_id,),
    ), 1):
        clusters[str(row["cluster_key"])] = row
        if index % progress_every == 0:
            _report_progress(progress, started, "staging_load", "clusters", index)
    _report_progress(progress, started, "staging_load", "clusters", len(clusters), len(clusters))
    members: dict[str, list[str]] = {}
    member_count = 0
    for member_count, row in enumerate(connection.execute(
        "SELECT cluster_key,claim_key FROM cluster_members NOT INDEXED WHERE release_id=?",
        (run_id,),
    ), 1):
        members.setdefault(str(row["cluster_key"]), []).append(str(row["claim_key"]))
        if member_count % progress_every == 0:
            _report_progress(progress, started, "staging_load", "members", member_count)
    _report_progress(progress, started, "staging_load", "members", member_count, member_count)
    return StagingSnapshot(occurrences, clusters, members, entry_sources)


def _expression_for_cluster(context: _CanonicalImportContext, cluster: sqlite3.Row, cluster_members: list[str], claim_rows: Mapping[str, sqlite3.Row], entry_sources: Mapping[str, str], sense_pos: Mapping[str, set[str]], marker_by_entry: Mapping[str, str] | None = None) -> int:
    connection = context.connection
    language_code = str(cluster["lang_code"])
    text = canonical_text(str(cluster["canonical_text"]))
    language_id = context.language_id(language_code)
    if language_id is None:
        raise ValueError(f"dictionary language not in registry: {language_code}")
    members = [key for key in cluster_members if key in claim_rows]
    source_key = max(sorted({entry_sources[str(claim_rows[key]["entry_key"])] for key in members}) or ["dictionary"], key=lambda key: (_source_rank(key, context.source_catalog), key))
    existing = connection.execute(
        "SELECT id FROM expressions WHERE language_id=? AND text=? ORDER BY homograph_index LIMIT 1",
        (language_id, text),
    ).fetchone()
    if existing is not None:
        expression_id = int(existing[0])
    else:
        pos_codes = set().union(*(sense_pos.get(str(claim_rows[key]["sense_key"]), set()) for key in members))
        connection.execute(
            "INSERT INTO expressions(language_id,text,homograph_index,pos_mask,source_id) VALUES (?,?,?,?,?) "
            "ON CONFLICT(language_id,text,homograph_index) DO UPDATE SET pos_mask=expressions.pos_mask | excluded.pos_mask",
            (language_id, text, 1, context.pos_mask(pos_codes), context.source_id(source_key)),
        )
        row = connection.execute("SELECT id FROM expressions WHERE language_id=? AND text=? AND homograph_index=?", (language_id, text, 1)).fetchone()
        if row is None:
            raise ValueError(f"unable to create canonical expression: {language_code}:{text}")
        expression_id = int(row[0])
    marker = ""
    is_headword = str(cluster["cluster_key"]).startswith("headword:")
    if is_headword:
        entry_keys = sorted({str(claim_rows[key]["entry_key"]) for key in members})
        if entry_keys and marker_by_entry is not None:
            marker = marker_by_entry.get(entry_keys[0], "")
    context.insert_ignore("expression_sources", {"expression_id": expression_id, "source_id": context.source_id(source_key), "source_marker": marker})
    return expression_id


def _upsert_reading(context: _CanonicalImportContext, expression_id: int, locale_id: int, scheme: str, value: str, source_id: int | None, source_rank: int = 0) -> bool:
    connection = context.connection
    existing = connection.execute(
        "SELECT source_id FROM expression_readings WHERE expression_id=? AND locale_id=? AND scheme=? AND value=?",
        (expression_id, locale_id, scheme, canonical_text(value)),
    ).fetchone()
    if existing is not None:
        return False
    context.insert_ignore("expression_readings", {"expression_id": expression_id, "locale_id": locale_id, "scheme": scheme, "value": canonical_text(value), "source_id": source_id})
    return True


def _upsert_edge(context: _CanonicalImportContext, left: int, right: int, relation_mask: int, created_by: int | None) -> int | None:
    if left == right:
        return None
    left, right = sorted((int(left), int(right)))
    connection = context.connection
    if "relation_mask" not in context.columns("expression_edges"):
        raise ValueError("canonical expression_edges.relation_mask is required")
    connection.execute(
        "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask,score,created_by) VALUES (?,?,?,?,?) "
        "ON CONFLICT(expression_a_id,expression_b_id) DO UPDATE SET relation_mask=expression_edges.relation_mask | excluded.relation_mask",
        (left, right, relation_mask, 0, created_by),
    )
    row = connection.execute(
        "SELECT id FROM expression_edges WHERE expression_a_id=? AND expression_b_id=?",
        (left, right),
    ).fetchone()
    return int(row[0]) if row is not None else None


def _refresh_language_statistics(connection: sqlite3.Connection, language_ids: set[int]) -> None:
    """Refresh only languages touched by this release, when the new table exists."""
    table = connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='language_statistics'"
    ).fetchone()
    if table is None:
        return
    for language_id in sorted(language_ids):
        connection.execute(
            "INSERT INTO language_statistics(language_id,expression_count,locale_count,active_ui_locale_count,updated_at) "
            "VALUES (?,(SELECT COUNT(*) FROM expressions WHERE language_id=?),"
            "(SELECT COUNT(*) FROM language_locales WHERE language_id=?),"
            "(SELECT COUNT(*) FROM ui_locales u JOIN language_locales ll ON ll.id=u.locale_id "
            " WHERE ll.language_id=? AND u.status='active'),CURRENT_TIMESTAMP) "
            "ON CONFLICT(language_id) DO UPDATE SET expression_count=excluded.expression_count,"
            "locale_count=excluded.locale_count,active_ui_locale_count=excluded.active_ui_locale_count,"
            "updated_at=excluded.updated_at",
            (language_id, language_id, language_id, language_id),
        )


def import_release_to_local_d1(
    staging_database: Path, d1_database: Path, release_id: str, *, activate: bool = True,
    packed: bool = False, append: bool = False, chunk_size: int = 5_000,
    source_catalog: Mapping[str, Mapping[str, Any]] | None = None, system_user_id: int | None = None,
    progress: ProgressCallback | None = None,
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
    context = _CanonicalImportContext(connection, source_catalog)
    staging = sqlite3.connect(Path(staging_database))
    staging.row_factory = sqlite3.Row
    try:
        run = staging.execute("SELECT * FROM staging_releases WHERE id=? AND status='staged'", (release_id,)).fetchone()
        if run is None:
            raise ValueError(f"run is not staged: {release_id}")
        load_started = time.perf_counter()
        snapshot = load_staging_snapshot(staging, release_id, progress=progress, progress_every=chunk_size)
        staging_load_seconds = time.perf_counter() - load_started
        occurrences = snapshot.occurrences
        clusters = snapshot.clusters
        members = snapshot.members
        entry_sources = snapshot.entry_sources
        sense_pos: dict[str, set[str]] = {}
        for row in staging.execute("SELECT sense_key,code FROM normalized_pos WHERE release_id=? AND code IS NOT NULL AND errors_json='[]'", (release_id,)):
            sense_pos.setdefault(str(row["sense_key"]), set()).add(str(row["code"]))
        marker_by_entry: dict[str, str] = {}
        for claim_key, row in sorted(occurrences.items()):
            if str(row["occurrence_kind"]) != "headword" or str(row["entry_key"]) in marker_by_entry:
                continue
            try:
                metadata = json.loads(str(row["metadata_json"])) if row["metadata_json"] else {}
            except ValueError:
                metadata = {}
            marker = metadata.get("homograph_marker")
            marker_by_entry[str(row["entry_key"])] = str(marker) if marker else ""
        write_started = time.perf_counter()
        _report_progress(progress, write_started, "d1_write", "start", 0)
        connection.execute("BEGIN IMMEDIATE")
        affected_language_ids: set[int] = set()
        for key in sorted({entry_sources[str(row["entry_key"])] for row in occurrences.values()}):
            context.source_id(key)
        ordered_clusters = sorted(clusters.items(), key=lambda item: (str(item[1]["lang_code"]), str(item[1]["canonical_text"]), not str(item[1]["cluster_key"]).startswith("headword:"), item[0]))
        cluster_ids: dict[str, int] = {}
        for offset in range(0, len(ordered_clusters), chunk_size):
            for cluster_key, cluster in ordered_clusters[offset:offset + chunk_size]:
                cluster_ids[cluster_key] = _expression_for_cluster(context, cluster, members.get(cluster_key, []), occurrences, entry_sources, sense_pos, marker_by_entry)
                affected_language_ids.add(context.language_id(str(cluster["lang_code"])))
            _report_progress(progress, write_started, "d1_write", "expressions", min(offset + chunk_size, len(ordered_clusters)), len(ordered_clusters))
        links = readings = edges = 0
        ordered_occurrences = sorted(occurrences)
        for index, claim_key in enumerate(ordered_occurrences, 1):
            row = occurrences[claim_key]
            expression_id = cluster_ids.get(str(row["cluster_key"]))
            if expression_id is None or not row["locale_code"]:
                continue
            locale_id = context.locale_id(str(row["locale_code"]), str(row["lang_code"]))
            before = connection.total_changes
            context.insert_ignore("expression_locale_links", {"expression_id": expression_id, "locale_id": locale_id})
            links += int(connection.total_changes > before)
            if index % chunk_size == 0:
                _report_progress(progress, write_started, "d1_write", "locale_links", index, len(ordered_occurrences))
        _report_progress(progress, write_started, "d1_write", "locale_links", len(ordered_occurrences), len(ordered_occurrences))
        head_by_entry: dict[str, int] = {}
        source_by_entry: dict[str, str] = {}
        for claim_key in sorted(occurrences):
            row = occurrences[claim_key]
            if str(row["occurrence_kind"]) == "headword" and str(row["entry_key"]) not in head_by_entry:
                head_by_entry[str(row["entry_key"])] = cluster_ids.get(str(row["cluster_key"]))
                source_by_entry[str(row["entry_key"])] = entry_sources[str(row["entry_key"])]
        reading_rows = list(staging.execute(
            "SELECT * FROM lexical_readings NOT INDEXED WHERE release_id=? AND errors_json='[]'",
            (release_id,),
        ))
        ordered_readings = sorted(reading_rows, key=lambda item: str(item["claim_key"]))
        for index, row in enumerate(ordered_readings, 1):
            expression_id = head_by_entry.get(str(row["entry_key"]))
            if expression_id is None or not row["locale_code"]:
                continue
            code = str(row["locale_code"])
            source_key = source_by_entry.get(str(row["entry_key"]), "dictionary")
            readings += int(_upsert_reading(context, expression_id, context.locale_id(code, code.split("-", 1)[0]), str(row["scheme"]), str(row["value"]), context.source_id(source_key), _source_rank(source_key, source_catalog)))
            if index % chunk_size == 0:
                _report_progress(progress, write_started, "d1_write", "readings", index, len(ordered_readings))
        _report_progress(progress, write_started, "d1_write", "readings", len(ordered_readings), len(ordered_readings))
        for claim_key in sorted(occurrences):
            row = occurrences[claim_key]
            kind = str(row["occurrence_kind"])
            if kind not in {"equivalent", "synonym"}:
                continue
            head = head_by_entry.get(str(row["entry_key"]))
            target = cluster_ids.get(str(row["cluster_key"]))
            if head is None or target is None:
                continue
            relation = RELATION_SYNONYM if kind == "synonym" else RELATION_MAPPING
            edge_id = _upsert_edge(context, head, target, relation, system_user_id)
            if edge_id is not None:
                source_key = source_by_entry.get(str(row["entry_key"]), "dictionary")
                context.insert_ignore("expression_edge_sources", {"edge_id": edge_id, "source_id": context.source_id(source_key), "source_marker": marker_by_entry.get(str(row["entry_key"]), "")})
                edges += 1
        example_rows = {str(row["claim_key"]): row for row in occurrences.values() if str(row["occurrence_kind"]) == "example"}
        for claim_key in sorted(example_rows):
            row = example_rows[claim_key]
            if not claim_key.endswith(":translation"):
                continue
            text_row = example_rows.get(claim_key[: -len(":translation")] + ":text")
            if text_row is None:
                continue
            left = cluster_ids.get(str(text_row["cluster_key"]))
            right = cluster_ids.get(str(row["cluster_key"]))
            if left is not None and right is not None:
                edge_id = _upsert_edge(context, left, right, RELATION_EXAMPLE, system_user_id)
                if edge_id is not None:
                    entry_key = str(text_row["entry_key"])
                    source_key = entry_sources.get(entry_key, "dictionary")
                    context.insert_ignore("expression_edge_sources", {"edge_id": edge_id, "source_id": context.source_id(source_key), "source_marker": marker_by_entry.get(entry_key, "")})
                    edges += 1
        _report_progress(progress, write_started, "d1_write", "edges", edges, edges)
        pos_updates = int(connection.execute("SELECT COUNT(*) FROM expressions WHERE pos_mask<>0").fetchone()[0]) if "pos_mask" in context.columns("expressions") else 0
        _refresh_language_statistics(connection, affected_language_ids)
        connection.commit()
        d1_write_seconds = time.perf_counter() - write_started
        _report_progress(progress, write_started, "d1_write", "commit", len(cluster_ids), len(cluster_ids))
        return LocalImportSummary(
            release_id,
            len(set(cluster_ids.values())),
            links,
            readings,
            edges,
            pos_updates,
            max(1, (len(ordered_clusters) + chunk_size - 1) // chunk_size),
            phase_seconds={
                "staging_load": round(staging_load_seconds, 3),
                "d1_write": round(d1_write_seconds, 3),
            },
        )
    except Exception:
        connection.rollback()
        raise
    finally:
        staging.close()
        connection.close()
