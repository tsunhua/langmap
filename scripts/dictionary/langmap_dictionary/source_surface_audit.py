"""Streaming audit for lexical surfaces in Structured JSONL v2 sources.

The audit is intentionally read-only.  It ranks source-local candidates for a
source-side exporter repair without exporting a production baseline or
rewriting JSONL in place.  Counts are deterministic; samples are bounded so
the report remains useful for large dictionaries.
"""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable, Iterator

from .expression_surface import (
    extract_mapping_annotation,
    extract_reading_parentheses,
    normalize_expression_surface,
    prepare_expression_value,
    split_expression_alternatives,
    surface_errors,
)

try:  # ujson keeps the audit practical for multi-gigabyte corpora.
    import ujson as _json
except ImportError:  # pragma: no cover - stdlib fallback for minimal tooling.
    _json = json


_SURFACE_FIELDS = {
    "canonical_headword",
    "forms",
    "mappings",
    "senses",
    "equivalents",
    "examples",
    "relations",
}
_PUNCTUATION = re.compile(r"\s+[,，.;:!?！？。．、；：]")
_TERMINAL_PUNCTUATION = re.compile(r"[,，.;:。．、；：]\s*$")


def _surface_values(value: Any, path: str = "") -> Iterator[tuple[str, str]]:
    """Yield only lexical text fields, excluding definitions and metadata."""

    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            if key in _SURFACE_FIELDS:
                yield from _surface_values(child, child_path)
            elif path and path.split(".")[-1] in _SURFACE_FIELDS:
                if key in {"value", "text", "translation", "raw_related_text"}:
                    yield from _surface_values(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from _surface_values(child, f"{path}[{index}]")
    elif isinstance(value, str) and value.strip():
        yield path, value


def _sample(samples: dict[str, list[dict[str, str]]], issue: str, path: str, value: str, entry_key: str, limit: int) -> None:
    bucket = samples.setdefault(issue, [])
    if len(bucket) < limit:
        bucket.append({"field": path, "value": value, "entry_key": entry_key})


def _sample_entry_lines(path: Path, sample_entries: int) -> tuple[dict[str, Any], ...]:
    """Read a bounded head/middle/tail sample without scanning the corpus.

    JSONL files are immutable export artifacts, so byte offsets are stable for
    the duration of this read.  Seeking to deterministic offsets keeps a large
    source audit proportional to the requested sample size rather than to the
    number of entries in the file.  A small tail window is enough for ordinary
    entries; it grows only when a source has unusually large final records.
    """

    if sample_entries < 1:
        return ()
    with Path(path).open("rb") as handle:
        header_line = handle.readline()
        if not header_line:
            return ()
        header_end = handle.tell()
        handle.seek(0, 2)
        file_size = handle.tell()
        if file_size <= header_end:
            return ()
        offsets: set[int] = set()
        if sample_entries == 1:
            head_count, middle_count, tail_count = 1, 0, 0
        elif sample_entries == 2:
            head_count, middle_count, tail_count = 1, 0, 1
        else:
            head_count = max(1, sample_entries // 3)
            tail_count = max(1, sample_entries // 3)
            middle_count = sample_entries - head_count - tail_count
        handle.seek(header_end)
        for _ in range(head_count):
            offset = handle.tell()
            line = handle.readline()
            if not line:
                break
            offsets.add(offset)

        span = file_size - header_end
        for index in range(1, middle_count + 1):
            target = header_end + (span * index) // (middle_count + 1)
            handle.seek(target)
            handle.readline()  # discard the partial line at the seek point
            offset = handle.tell()
            if handle.readline():
                offsets.add(offset)

        window = 64 * 1024
        tail_lines: list[tuple[int, bytes]] = []
        while len(tail_lines) < tail_count and window <= 16 * 1024 * 1024:
            start = max(header_end, file_size - window)
            handle.seek(start)
            if start > header_end:
                handle.readline()  # discard the partial line
            tail_lines = []
            while True:
                offset = handle.tell()
                line = handle.readline()
                if not line:
                    break
                if line.strip():
                    tail_lines.append((offset, line))
            if len(tail_lines) < tail_count:
                window *= 4
        if tail_count:
            offsets.update(offset for offset, _ in tail_lines[-tail_count:])

        entries: list[dict[str, Any]] = []
        for offset in sorted(offsets):
            handle.seek(offset)
            line = handle.readline()
            if not line.strip():
                continue
            try:
                value = _json.loads(line.decode("utf-8"))
            except (UnicodeDecodeError, ValueError):
                continue
            if isinstance(value, dict) and value.get("record_type") == "entry":
                entries.append(value)
        return tuple(entries)


def audit_file(
    path: Path,
    *,
    sample_limit: int = 5,
    sample_entries: int | None = None,
) -> dict[str, Any]:
    """Audit one Structured JSONL v2 file without retaining the corpus.

    ``sample_entries`` uses deterministic head/middle/tail seeks.  When it is
    omitted, the function retains the original full streaming audit behavior.
    """

    stats: Counter[str] = Counter()
    samples: dict[str, list[dict[str, str]]] = {}
    entries = 0
    sampled = sample_entries is not None and sample_entries > 0
    values = 0
    dictionary_key = ""
    source_entry_count: int | None = None
    with Path(path).open("r", encoding="utf-8-sig") as handle:
        header = _json.loads(handle.readline())
        dictionary_key = str(header.get("dictionary_key", ""))
        if isinstance(header.get("entry_count"), int):
            source_entry_count = int(header["entry_count"])
        source_entries: Iterable[dict[str, Any]]
        if sampled:
            source_entries = _sample_entry_lines(Path(path), int(sample_entries))
        else:
            source_entries = (
                _json.loads(line)
                for line in handle
                if line.strip()
            )
        for entry in source_entries:
            if not isinstance(entry, dict) or entry.get("record_type") != "entry":
                continue
            entries += 1
            entry_key = str(entry.get("entry_key", ""))
            for field, value in _surface_values(entry):
                values += 1
                errors = surface_errors(value)
                for error in errors:
                    stats[error] += 1
                    _sample(samples, error, field, value, entry_key, sample_limit)
                normalized = normalize_expression_surface(value)
                if normalized != value and _PUNCTUATION.search(value):
                    stats["space_before_punctuation"] += 1
                    _sample(samples, "space_before_punctuation", field, value, entry_key, sample_limit)
                if normalized != value and _TERMINAL_PUNCTUATION.search(value):
                    stats["terminal_punctuation"] += 1
                    _sample(samples, "terminal_punctuation", field, value, entry_key, sample_limit)
                _, readings = extract_reading_parentheses(value)
                if readings:
                    stats["embedded_reading"] += len(readings)
                    _sample(samples, "embedded_reading", field, value, entry_key, sample_limit)
                _, annotation = extract_mapping_annotation(value)
                if annotation:
                    stats["terminal_annotation"] += 1
                    _sample(samples, "terminal_annotation", field, value, entry_key, sample_limit)
                alternatives = split_expression_alternatives(value)
                if len(alternatives) > 1:
                    stats["surface_alternative"] += len(alternatives) - 1
                    _sample(samples, "surface_alternative", field, value, entry_key, sample_limit)
    return {
        "file": Path(path).name,
        "dictionary_key": dictionary_key,
        "source_entry_count": source_entry_count,
        "entries": entries,
        "sampled": sampled,
        "values": values,
        "stats": dict(sorted(stats.items())),
        "samples": samples,
    }


def audit_directory(
    directory: Path,
    *,
    sample_limit: int = 5,
    sample_entries: int | None = None,
    only: Iterable[str] = (),
) -> dict[str, Any]:
    """Audit all JSONL files in a directory, optionally filtered by name."""

    wanted = tuple(str(item) for item in only)
    reports = []
    for path in sorted(Path(directory).glob("*.jsonl")):
        if wanted and not any(fragment in path.name for fragment in wanted):
            continue
        if ".pre-" in path.stem:
            continue
        reports.append(
            audit_file(path, sample_limit=sample_limit, sample_entries=sample_entries)
        )
    if not reports:
        raise ValueError(f"no Structured JSONL files found in {directory}")
    ranked = sorted(
        reports,
        key=lambda report: (
            -sum(report["stats"].get(issue, 0) for issue in ("malformed_surface", "placeholder_surface", "reading_in_expression")),
            -sum(report["stats"].values()),
            report["dictionary_key"],
        ),
    )
    return {
        "directory": str(Path(directory)),
        "sample_entries": sample_entries if sample_entries and sample_entries > 0 else None,
        "files": ranked,
    }


def compiled_audit_file(
    path: Path,
    *,
    sample_limit: int = 5,
    sample_entries: int = 100,
) -> dict[str, Any]:
    """Audit the surfaces that the adapter would actually publish.

    The raw surface audit is useful for finding source markup, but it can
    overstate a problem when the normalizer removes a reading shell,
    presentation wrapper, or empty placeholder.  This companion audit runs
    the same ``prepare_expression_value`` and ``surface_errors`` boundary as
    the dictionary adapter and ranks only the resulting alternatives.
    """

    path = Path(path)
    with path.open("r", encoding="utf-8-sig") as handle:
        header = _json.loads(handle.readline())
    sampled_entries = _sample_entry_lines(path, sample_entries)
    values = 0
    compiled_alternatives = 0
    failed_alternatives = 0
    filtered_values = 0
    failures: list[dict[str, Any]] = []
    dictionary_key = str(header.get("dictionary_key", ""))
    for entry in sampled_entries:
        if not isinstance(entry, dict) or entry.get("record_type") != "entry":
            continue
        entry_key = str(entry.get("entry_key", ""))
        documented_symbol_headword = (
            "documented_symbol_headword" in entry.get("diagnostics", [])
        )
        for field, value in _surface_values(entry):
            values += 1
            alternatives, _readings, _annotation = prepare_expression_value(value)
            raw_errors = surface_errors(value)
            if documented_symbol_headword and field == "canonical_headword":
                raw_errors = tuple(error for error in raw_errors if error != "punctuation_only")
            alternatives = tuple(alternative for alternative in alternatives if alternative.strip())
            if not alternatives:
                filtered_values += 1
                if len(failures) < sample_limit:
                    failures.append({
                        "entry_key": entry_key,
                        "field": field,
                        "value": value,
                        "alternative": None,
                        "errors": ["no_publishable_alternative", *raw_errors],
                    })
                continue
            value_failed = False
            for alternative in alternatives:
                compiled_alternatives += 1
                errors = tuple(dict.fromkeys((*raw_errors, *surface_errors(alternative))))
                if documented_symbol_headword and field == "canonical_headword":
                    errors = tuple(error for error in errors if error != "punctuation_only")
                if errors:
                    failed_alternatives += 1
                    value_failed = True
                    if len(failures) < sample_limit:
                        failures.append({
                            "entry_key": entry_key,
                            "field": field,
                            "value": value,
                            "alternative": alternative,
                            "errors": list(errors),
                        })
            if value_failed:
                filtered_values += 1
    source_entry_count = header.get("entry_count")
    return {
        "file": path.name,
        "dictionary_key": dictionary_key,
        "source_entry_count": source_entry_count if isinstance(source_entry_count, int) else None,
        "entries": len(sampled_entries),
        "sampled": True,
        "values": values,
        "compiled_alternatives": compiled_alternatives,
        "failed_alternatives": failed_alternatives,
        "filtered_values": filtered_values,
        "correct_rate": (
            (compiled_alternatives - failed_alternatives) / compiled_alternatives
            if compiled_alternatives
            else 1.0
        ),
        "failures": failures,
    }


def compiled_audit_directory(
    directory: Path,
    *,
    sample_limit: int = 5,
    sample_entries: int = 100,
    only: Iterable[str] = (),
) -> dict[str, Any]:
    """Rank bounded source samples by compiled surface correctness."""

    wanted = tuple(str(item) for item in only)
    reports = []
    for path in sorted(Path(directory).glob("*.jsonl")):
        if ".pre-" in path.stem:
            continue
        if wanted and not any(fragment in path.name for fragment in wanted):
            continue
        reports.append(
            compiled_audit_file(
                path,
                sample_limit=sample_limit,
                sample_entries=sample_entries,
            )
        )
    if not reports:
        raise ValueError(f"no Structured JSONL files found in {directory}")
    reports.sort(key=lambda report: (-1 if report["correct_rate"] < 1 else 0, report["correct_rate"], report["dictionary_key"]))
    return {
        "directory": str(Path(directory)),
        "sample_entries": sample_entries,
        "files": reports,
    }


__all__ = [
    "audit_directory",
    "audit_file",
    "compiled_audit_directory",
    "compiled_audit_file",
]
