"""Streaming loader from Structured JSONL v2 into the staging database."""

from __future__ import annotations

import hashlib
import json
import re
import sqlite3
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Iterator, Sequence

from .models import StagedEntry, StagedPronunciation, StagedSense

try:
    import ujson as _fast_json
except ImportError:  # pragma: no cover - the standard library remains supported
    _fast_json = json

_HEX64 = re.compile(r"^[0-9a-fA-F]{64}$")


@dataclass(frozen=True)
class StageSummary:
    input_records: int
    staged_entries: int
    staged_senses: int
    quarantined: int
    manifest_hash: str
    release_id: str = ""


class StageLoadError(ValueError):
    """A release-level error that must roll back all staged rows."""


def _json(value: Any) -> str:
    return _fast_json.dumps(value, ensure_ascii=False, sort_keys=True)


def _text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be a non-empty string")
    return value.strip()


def _array(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise ValueError(f"{label} must be an array")
    return value


ProgressCallback = Callable[[dict[str, Any]], None]


def _manifest(paths: Sequence[Path], progress: ProgressCallback | None = None) -> tuple[str, str]:
    digest = hashlib.sha256()
    for ordinal, path in enumerate(paths, 1):
        if not path.is_file():
            raise FileNotFoundError(path)
        file_digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                file_digest.update(chunk)
        digest.update(path.name.encode("utf-8"))
        digest.update(b"\0")
        digest.update(file_digest.hexdigest().encode("ascii"))
        digest.update(b"\0")
        if progress is not None:
            progress({"phase": "hash", "files": ordinal, "total_files": len(paths), "file": path.name})
    value = digest.hexdigest()
    return f"release-{value[:32]}", value


def _header(record: Any, path: Path) -> dict[str, Any]:
    if not isinstance(record, dict) or record.get("record_type") != "dictionary":
        raise StageLoadError(f"{path}: first record must be a dictionary header")
    if record.get("schema_version") != 2:
        raise StageLoadError(f"{path}: unsupported schema_version {record.get('schema_version')!r}")
    for key in ("dictionary_key", "input_file_name", "input_sha256", "entry_count", "exporter_version"):
        if key not in record:
            raise StageLoadError(f"{path}: header missing {key}")
    if not isinstance(record["dictionary_key"], str) or not record["dictionary_key"].strip():
        raise StageLoadError(f"{path}: dictionary_key must be non-empty")
    if not isinstance(record["input_sha256"], str) or not _HEX64.fullmatch(record["input_sha256"]):
        raise StageLoadError(f"{path}: input_sha256 must be a 64-character hex digest")
    if not isinstance(record["entry_count"], int) or record["entry_count"] < 0:
        raise StageLoadError(f"{path}: entry_count must be a non-negative integer")
    return record


def _entry(record: Any, path: Path, line: int, release_id: str) -> dict[str, Any]:
    if not isinstance(record, dict) or record.get("record_type") != "entry":
        raise ValueError("record is not an entry")
    if record.get("schema_version") != 2:
        raise StageLoadError(f"{path}:{line}: unsupported schema_version {record.get('schema_version')!r}")
    required = ("dictionary_key", "entry_key", "record_fingerprint", "csv_row_number", "raw_headword", "canonical_headword", "forms", "pronunciations", "senses", "diagnostics")
    for key in required:
        if key not in record:
            raise ValueError(f"missing {key}")
    for key in ("dictionary_key", "entry_key", "raw_headword", "canonical_headword"):
        _text(record[key], key)
    if not isinstance(record["record_fingerprint"], str) or not _HEX64.fullmatch(record["record_fingerprint"]):
        raise ValueError("record_fingerprint must be a 64-character hex digest")
    if not isinstance(record["csv_row_number"], int) or record["csv_row_number"] < 1:
        raise ValueError("csv_row_number must be positive")
    for key in ("forms", "pronunciations", "senses", "diagnostics"):
        _array(record[key], key)
    return record


def _child_text(item: Any, key: str, label: str) -> str:
    if isinstance(item, str):
        return _text(item, label)
    if not isinstance(item, dict):
        raise ValueError(f"{label} must be a string or object")
    return _text(item.get(key) or item.get("value") or item.get("text"), label)


def _insert_entry(
    connection: sqlite3.Connection,
    release_id: str,
    record: dict[str, Any],
    *,
    compact: bool = False,
) -> tuple[int, int]:
    rows, sense_count = _entry_rows(release_id, record, compact=compact)
    for table in ("input_entries", "input_forms", "input_pronunciations", "input_senses", "input_equivalents", "input_relations", "input_examples", "input_pos"):
        values = rows[table]
        if values:
            connection.executemany(_INSERT_SQL[table], values)
    return 1, sense_count


_INSERT_SQL = {
    "input_entries": "INSERT INTO input_entries VALUES (?,?,?,?,?,?,?,?,?)",
    "input_forms": "INSERT INTO input_forms VALUES (?,?,?,?,?)",
    "input_pronunciations": "INSERT INTO input_pronunciations VALUES (?,?,?,?,?,?)",
    "input_senses": "INSERT INTO input_senses VALUES (?,?,?,?,?,?,?,?,?,?,?)",
    "input_equivalents": "INSERT INTO input_equivalents VALUES (?,?,?,?,?,?)",
    "input_relations": "INSERT INTO input_relations VALUES (?,?,?,?,?,?,?,?)",
    "input_examples": "INSERT INTO input_examples VALUES (?,?,?,?,?,?)",
    "input_pos": "INSERT INTO input_pos VALUES (?,?,?,?,?)",
}

def _entry_rows(
    release_id: str,
    record: dict[str, Any],
    *,
    compact: bool = False,
) -> tuple[dict[str, list[tuple[Any, ...]]], int]:
    rows: dict[str, list[tuple[Any, ...]]] = defaultdict(list)
    entry_key = record["entry_key"]
    rows["input_entries"].append(
        (release_id, entry_key, record["dictionary_key"], record["raw_headword"], record["canonical_headword"], record.get("homograph_marker"), record.get("direction_hint"), record["record_fingerprint"], _json(record))
    )
    for ordinal, item in enumerate(record["forms"], 1):
        value = _child_text(item, "value", f"form {ordinal}")
        if not compact:
            rows["input_forms"].append((release_id, entry_key, ordinal, value, _json(item)))
    for ordinal, item in enumerate(record["pronunciations"], 1):
        if not isinstance(item, dict):
            raise ValueError(f"pronunciation {ordinal} must be an object")
        value = _text(item.get("value"), f"pronunciation {ordinal}.value")
        scheme = _text(item.get("scheme"), f"pronunciation {ordinal}.scheme")
        rows["input_pronunciations"].append((release_id, entry_key, ordinal, value, scheme, _json(item)))
    sense_count = 0
    for fallback_ordinal, sense in enumerate(record["senses"], 1):
        if not isinstance(sense, dict):
            raise ValueError(f"sense {fallback_ordinal} must be an object")
        sense_key = _text(sense.get("sense_key"), f"sense {fallback_ordinal}.sense_key")
        ordinal = sense.get("ordinal", fallback_ordinal)
        if not isinstance(ordinal, int) or ordinal < 1:
            raise ValueError(f"sense {sense_key}.ordinal must be positive")
        arrays = {key: _array(sense.get(key, []), f"sense {sense_key}.{key}") for key in ("definitions", "pos", "equivalents", "relations", "examples", "labels")}
        rows["input_senses"].append(
            (release_id, sense_key, entry_key, ordinal, *(_json(arrays[key]) for key in ("definitions", "pos", "equivalents", "relations", "examples", "labels")), _json(sense))
        )
        for child_ordinal, item in enumerate(arrays["equivalents"], 1):
            value = _child_text(item, "value", f"equivalent {sense_key}:{child_ordinal}")
            if not compact:
                language_hint = item.get("language") or item.get("language_hint") if isinstance(item, dict) else None
                rows["input_equivalents"].append((release_id, sense_key, child_ordinal, value, language_hint, _json(item)))
        for child_ordinal, item in enumerate(arrays["relations"], 1):
            if not isinstance(item, dict):
                raise ValueError(f"relation {sense_key}:{child_ordinal} must be an object")
            kind = _text(item.get("kind"), "relation.kind")
            related_text = _child_text(item, "related_text", "relation.related_text")
            if not compact:
                rows["input_relations"].append((release_id, sense_key, child_ordinal, kind, related_text, item.get("reading"), item.get("language"), _json(item)))
        for child_ordinal, item in enumerate(arrays["examples"], 1):
            text = _child_text(item, "text", f"example {sense_key}:{child_ordinal}")
            if not compact:
                translation = item.get("translation") if isinstance(item, dict) else None
                rows["input_examples"].append((release_id, sense_key, child_ordinal, text, translation, _json(item)))
        for child_ordinal, item in enumerate(arrays["pos"], 1):
            value = _child_text(item, "value", f"pos {sense_key}:{child_ordinal}")
            if not compact:
                rows["input_pos"].append((release_id, sense_key, child_ordinal, value, _json(item)))
        sense_count += 1
    return rows, sense_count


def _quarantine(connection: sqlite3.Connection, release_id: str, record: Any, error_code: str, detail: str) -> None:
    dictionary_key = record.get("dictionary_key") if isinstance(record, dict) else None
    entry_key = record.get("entry_key") if isinstance(record, dict) else None
    connection.execute("INSERT OR IGNORE INTO quarantine_items (release_id,dictionary_key,entry_key,error_code,detail,raw_json) VALUES (?,?,?,?,?,?)", (release_id, dictionary_key, entry_key, error_code, detail, _json(record)))


def load_jsonl_release(
    connection: sqlite3.Connection,
    paths: Sequence[Path],
    *,
    batch_size: int = 500,
    progress: ProgressCallback | None = None,
    compact: bool = False,
) -> StageSummary:
    """Load one or more v2 JSONL files atomically and idempotently."""

    if not paths:
        raise ValueError("at least one JSONL path is required")
    normalized_paths = tuple(Path(path) for path in paths)
    release_id, manifest_hash = _manifest(normalized_paths, progress)
    existing = connection.execute("SELECT * FROM staging_releases WHERE id = ?", (release_id,)).fetchone()
    if existing is not None:
        return StageSummary(existing["input_records"], existing["staged_entries"], existing["staged_senses"], existing["quarantined"], manifest_hash, release_id)

    if batch_size < 1:
        raise ValueError("batch_size must be positive")
    input_records = staged_entries = staged_senses = quarantined = 0
    pending_rows: dict[str, list[tuple[Any, ...]]] = defaultdict(list)
    pending_records: list[tuple[dict[str, Any], int]] = []
    next_progress = 100_000

    def flush_pending() -> tuple[int, int, int]:
        nonlocal pending_rows, pending_records
        if not pending_records:
            return 0, 0, 0
        inserted = senses = failed = 0
        connection.execute("SAVEPOINT entry_batch")
        try:
            for table in ("input_entries", "input_forms", "input_pronunciations", "input_senses", "input_equivalents", "input_relations", "input_examples", "input_pos"):
                values = pending_rows[table]
                if values:
                    connection.executemany(_INSERT_SQL[table], values)
            connection.execute("RELEASE SAVEPOINT entry_batch")
            inserted = len(pending_records)
            senses = sum(item[1] for item in pending_records)
        except Exception:
            connection.execute("ROLLBACK TO SAVEPOINT entry_batch")
            connection.execute("RELEASE SAVEPOINT entry_batch")
            for record, sense_count in pending_records:
                connection.execute("SAVEPOINT entry_row")
                try:
                    _insert_entry(connection, release_id, record, compact=compact)
                    connection.execute("RELEASE SAVEPOINT entry_row")
                    inserted += 1
                    senses += sense_count
                except Exception as error:
                    connection.execute("ROLLBACK TO SAVEPOINT entry_row")
                    connection.execute("RELEASE SAVEPOINT entry_row")
                    _quarantine(connection, release_id, record, "invalid_entry", str(error))
                    failed += 1
        pending_rows = defaultdict(list)
        pending_records = []
        return inserted, senses, failed

    connection.execute("BEGIN")
    try:
        connection.execute("INSERT INTO staging_releases (id,manifest_hash,schema_version,status) VALUES (?,?,1,'loading')", (release_id, manifest_hash))
        for path in normalized_paths:
            with path.open("r", encoding="utf-8-sig") as handle:
                first = handle.readline()
                if not first:
                    raise StageLoadError(f"{path}: empty JSONL")
                try:
                    header_record = _fast_json.loads(first)
                except json.JSONDecodeError as error:
                    raise StageLoadError(f"{path}: invalid header JSON: {error}") from error
                header = _header(header_record, path)
                expected_count = header["entry_count"]
                file_count = 0
                for line_number, raw_line in enumerate(handle, 2):
                    if not raw_line.strip():
                        continue
                    try:
                        record = _fast_json.loads(raw_line)
                        if isinstance(record, dict) and record.get("record_type") == "dictionary":
                            raise StageLoadError(f"{path}:{line_number}: duplicate dictionary header")
                        if not isinstance(record, dict) or record.get("record_type") != "entry":
                            continue
                        input_records += 1
                        file_count += 1
                        validated = _entry(record, path, line_number, release_id)
                        rows, senses = _entry_rows(release_id, validated, compact=compact)
                        for table, values in rows.items():
                            pending_rows[table].extend(values)
                        pending_records.append((validated, senses))
                        if len(pending_records) >= batch_size:
                            inserted, inserted_senses, failed = flush_pending()
                            staged_entries += inserted
                            staged_senses += inserted_senses
                            quarantined += failed
                            if progress is not None and input_records >= next_progress:
                                progress({"phase": "stage", "input_records": input_records, "file": path.name})
                                while next_progress <= input_records:
                                    next_progress += 100_000
                    except StageLoadError:
                        raise
                    except (ValueError, sqlite3.IntegrityError) as error:
                        quarantined += 1
                        _quarantine(connection, release_id, record if "record" in locals() else None, "invalid_entry", str(error))
                if file_count != expected_count:
                    raise StageLoadError(f"{path}: entry_count {expected_count} does not match {file_count}")
                inserted, inserted_senses, failed = flush_pending()
                staged_entries += inserted
                staged_senses += inserted_senses
                quarantined += failed
                if progress is not None:
                    progress({"phase": "stage-file", "input_records": input_records, "file": path.name})
        connection.execute("UPDATE staging_releases SET status='staged', input_records=?, staged_entries=?, staged_senses=?, quarantined=? WHERE id=?", (input_records, staged_entries, staged_senses, quarantined, release_id))
        connection.commit()
    except Exception as error:
        connection.rollback()
        connection.execute("INSERT OR IGNORE INTO staging_releases (id,manifest_hash,schema_version,status,failure_reason) VALUES (?,?,1,'failed',?)", (release_id, manifest_hash, str(error)))
        connection.commit()
        raise
    return StageSummary(input_records, staged_entries, staged_senses, quarantined, manifest_hash, release_id)


def iter_staged_entry_rows(
    connection: sqlite3.Connection,
    release_id: str,
    *,
    start_rowid: int = 0,
    batch_size: int = 500,
) -> Iterator[tuple[int, StagedEntry]]:
    """Yield staged entries with one sequential scan per staging table."""

    if batch_size < 1:
        raise ValueError("batch_size must be positive")
    entries = connection.execute(
        "SELECT rowid AS staging_rowid,* FROM input_entries NOT INDEXED "
        "WHERE release_id=? AND rowid>? ORDER BY rowid",
        (release_id, start_rowid),
    )

    def child_rows(table: str) -> Iterator[sqlite3.Row]:
        # Child rows are inserted in the same entry order as input_entries.
        # Fresh and legacy-resume runs avoid joins entirely.  Checkpoint resumes
        # add one parent lookup per child to filter the already committed prefix.
        if start_rowid == 0:
            return iter(connection.execute(
                f"SELECT * FROM {table} NOT INDEXED WHERE release_id=? ORDER BY rowid",
                (release_id,),
            ))
        return iter(connection.execute(
            f"SELECT child.* FROM {table} child NOT INDEXED "
            "JOIN input_entries parent ON parent.release_id=child.release_id AND parent.entry_key=child.entry_key "
            "WHERE child.release_id=? AND parent.rowid>? ORDER BY child.rowid",
            (release_id, start_rowid),
        ))

    pronunciation_rows = child_rows("input_pronunciations")
    sense_rows = child_rows("input_senses")
    form_rows = child_rows("input_forms")
    current_pronunciation = next(pronunciation_rows, None)
    current_sense = next(sense_rows, None)
    current_form = next(form_rows, None)

    for row in entries:
        entry_key = str(row["entry_key"])
        pronunciations: list[StagedPronunciation] = []
        while current_pronunciation is not None and current_pronunciation["entry_key"] == entry_key:
            pronunciations.append(StagedPronunciation(
                current_pronunciation["ordinal"],
                current_pronunciation["value"],
                current_pronunciation["scheme"],
                _fast_json.loads(current_pronunciation["raw_json"]),
            ))
            current_pronunciation = next(pronunciation_rows, None)
        senses: list[StagedSense] = []
        while current_sense is not None and current_sense["entry_key"] == entry_key:
            senses.append(StagedSense(
                current_sense["sense_key"],
                current_sense["ordinal"],
                tuple(_fast_json.loads(current_sense["definitions_json"])),
                tuple(_fast_json.loads(current_sense["pos_json"])),
                tuple(_fast_json.loads(current_sense["equivalents_json"])),
                tuple(_fast_json.loads(current_sense["relations_json"])),
                tuple(_fast_json.loads(current_sense["examples_json"])),
                tuple(_fast_json.loads(current_sense["labels_json"])),
                _fast_json.loads(current_sense["raw_json"]),
            ))
            current_sense = next(sense_rows, None)
        forms: list[object] = []
        while current_form is not None and current_form["entry_key"] == entry_key:
            forms.append(_fast_json.loads(current_form["raw_json"]))
            current_form = next(form_rows, None)
        yield int(row["staging_rowid"]), StagedEntry(
            row["release_id"],
            row["dictionary_key"],
            entry_key,
            row["canonical_headword"],
            row["raw_headword"],
            row["homograph_marker"],
            row["direction_hint"],
            row["record_fingerprint"],
            tuple(pronunciations),
            tuple(senses),
            tuple(forms),
            _fast_json.loads(row["raw_json"]),
        )
    if current_pronunciation is not None or current_sense is not None or current_form is not None:
        raise StageLoadError("child row order does not match staged entry order")


def iter_staged_entries(
    connection: sqlite3.Connection,
    release_id: str,
    *,
    start_after: tuple[str, str] | None = None,
    batch_size: int = 500,
) -> Iterator[StagedEntry]:
    start_rowid = 0
    if start_after is not None:
        row = connection.execute(
            "SELECT rowid FROM input_entries WHERE release_id=? AND dictionary_key=? AND entry_key=?",
            (release_id, start_after[0], start_after[1]),
        ).fetchone()
        if row is None:
            raise ValueError(f"unknown staged entry cursor: {start_after!r}")
        start_rowid = int(row[0])
    for _, entry in iter_staged_entry_rows(
        connection, release_id, start_rowid=start_rowid, batch_size=batch_size
    ):
        yield entry
