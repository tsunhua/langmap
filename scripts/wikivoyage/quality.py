#!/usr/bin/env python3
"""Fail-closed integrity checks for a Wikivoyage export artifact."""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping


VALID_STATES = frozenset({"included", "empty", "excluded", "blocked", "quarantined"})
_REQUIRED_SAMPLE_FIELDS = ("record_type", "schema_version", "dictionary_key", "entry_key", "canonical_headword", "senses", "raw")


class QualityGateError(ValueError):
    """Raised when the export cannot be safely handed to staging."""


@dataclass(frozen=True)
class ExportQualityReport:
    passed: bool
    errors: tuple[str, ...]
    manifest_pages: int
    report_pages: int
    included_pages: int
    jsonl_files: int
    input_entries: int
    quarantine_rows: int
    removal_rows: int
    state_counts: Mapping[str, int]
    samples: tuple[Mapping[str, Any], ...]
    manifest_sha256: str
    export_report_sha256: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "passed": self.passed,
            "errors": list(self.errors),
            "manifest_pages": self.manifest_pages,
            "report_pages": self.report_pages,
            "included_pages": self.included_pages,
            "jsonl_files": self.jsonl_files,
            "input_entries": self.input_entries,
            "quarantine_rows": self.quarantine_rows,
            "removal_rows": self.removal_rows,
            "state_counts": dict(self.state_counts),
            "samples": list(self.samples),
            "manifest_sha256": self.manifest_sha256,
            "export_report_sha256": self.export_report_sha256,
        }


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _read_json(path: Path) -> Mapping[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, Mapping):
        raise QualityGateError(f"JSON artifact must be an object: {path}")
    return value


def _jsonl_rows(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with Path(path).open(encoding="utf-8-sig") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            value = json.loads(line)
            if not isinstance(value, dict):
                raise QualityGateError(f"JSONL row is not an object: {path}:{line_number}")
            rows.append(value)
    return rows


def _iter_review_rows(path: Path) -> Iterable[dict[str, Any]]:
    if not path.is_file():
        return ()
    rows = _jsonl_rows(path)
    return tuple(rows)


def _sample_entry(entry: Mapping[str, Any], pageid: int) -> tuple[dict[str, Any] | None, str | None]:
    missing = [key for key in _REQUIRED_SAMPLE_FIELDS if key not in entry]
    if missing:
        return None, f"sample_missing_fields:{pageid}:{','.join(missing)}"
    if entry.get("record_type") != "entry" or entry.get("schema_version") != 2:
        return None, f"sample_schema:{pageid}"
    if not str(entry.get("canonical_headword") or "").strip():
        return None, f"sample_empty_headword:{pageid}"
    senses = entry.get("senses")
    if not isinstance(senses, list) or not senses:
        return None, f"sample_missing_sense:{pageid}"
    equivalents = [
        item for sense in senses if isinstance(sense, Mapping)
        for item in (sense.get("equivalents") or [])
        if isinstance(item, Mapping)
    ]
    if not any(str(item.get("language") or "") == "eng" and str(item.get("value") or "").strip() for item in equivalents):
        return None, f"sample_missing_english_equivalent:{pageid}"
    raw = entry.get("raw")
    if not isinstance(raw, Mapping):
        return None, f"sample_raw_metadata:{pageid}"
    if not str(raw.get("target_lang_code") or "").strip() or not str(raw.get("target_locale_code") or "").strip():
        return None, f"sample_missing_target_identity:{pageid}"
    marker = str(raw.get("source_marker") or "")
    if not marker.startswith("oldid:") or "#" not in marker or "/" not in marker:
        return None, f"sample_missing_source_marker:{pageid}"
    return {
        "pageid": pageid,
        "entry_key": str(entry.get("entry_key")),
        "canonical_headword": str(entry.get("canonical_headword")),
        "english": next(str(item.get("value")) for item in equivalents if str(item.get("language") or "") == "eng" and str(item.get("value") or "").strip()),
        "target_locale_code": str(raw.get("target_locale_code")),
        "readings": len(entry.get("pronunciations") or []) if isinstance(entry.get("pronunciations"), list) else 0,
    }, None


def evaluate_export_quality(
    snapshot_dir: Path,
    export_dir: Path,
    export_report_path: Path | None = None,
) -> ExportQualityReport:
    """Validate one snapshot/export pair without touching D1 or production."""

    snapshot_dir = Path(snapshot_dir)
    export_dir = Path(export_dir)
    manifest_path = snapshot_dir / "manifest.json"
    report_path = Path(export_report_path or export_dir / "export-report.json")
    errors: list[str] = []
    manifest: Mapping[str, Any] = {}
    export_report: Mapping[str, Any] = {}
    if not manifest_path.is_file():
        errors.append("missing_manifest")
    else:
        try:
            manifest = _read_json(manifest_path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"invalid_manifest:{type(error).__name__}")
    if not report_path.is_file():
        errors.append("missing_export_report")
    else:
        try:
            export_report = _read_json(report_path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"invalid_export_report:{type(error).__name__}")

    raw_manifest_pages = manifest.get("pages", []) if manifest else []
    raw_report_pages = export_report.get("pages", []) if export_report else []
    manifest_pages = [item for item in raw_manifest_pages if isinstance(item, Mapping)] if isinstance(raw_manifest_pages, list) else []
    report_pages = [item for item in raw_report_pages if isinstance(item, Mapping)] if isinstance(raw_report_pages, list) else []
    if not isinstance(raw_manifest_pages, list):
        errors.append("manifest_pages_not_array")
    if not isinstance(raw_report_pages, list):
        errors.append("report_pages_not_array")

    manifest_ids: list[int] = []
    for page in manifest_pages:
        try:
            pageid = int(page["pageid"])
        except (KeyError, TypeError, ValueError):
            errors.append("manifest_page_missing_id")
            continue
        manifest_ids.append(pageid)
        snapshot_file = snapshot_dir / str(page.get("snapshot_file") or "")
        if not snapshot_file.is_file():
            errors.append(f"missing_snapshot:{pageid}")
        elif str(page.get("snapshot_sha256") or "") != _sha256(snapshot_file):
            errors.append(f"snapshot_checksum:{pageid}")
    if len(set(manifest_ids)) != len(manifest_ids):
        errors.append("duplicate_manifest_page")

    report_ids: list[int] = []
    report_entry_counts: dict[int, int] = {}
    state_counts = {state: 0 for state in sorted(VALID_STATES)}
    included_ids: list[int] = []
    for page in report_pages:
        try:
            pageid = int(page["pageid"])
        except (KeyError, TypeError, ValueError):
            errors.append("report_page_missing_id")
            continue
        report_ids.append(pageid)
        try:
            report_entry_counts[pageid] = int(page.get("entry_count") or 0)
        except (TypeError, ValueError):
            errors.append(f"invalid_entry_count:{pageid}")
            report_entry_counts[pageid] = -1
        state = str(page.get("state") or "")
        if state not in VALID_STATES:
            errors.append(f"invalid_page_state:{pageid}:{state or '<empty>'}")
            continue
        state_counts[state] += 1
        if state == "included":
            included_ids.append(pageid)
        if report_entry_counts[pageid] < 0:
            errors.append(f"negative_entry_count:{pageid}")
    if len(set(report_ids)) != len(report_ids):
        errors.append("duplicate_report_page")
    if sorted(manifest_ids) != sorted(report_ids):
        errors.append("page_accounting_mismatch")
    reported_counts = export_report.get("counts") if export_report else None
    if isinstance(reported_counts, Mapping):
        for state, count in state_counts.items():
            try:
                if int(reported_counts.get(state, 0)) != count:
                    errors.append(f"state_count_mismatch:{state}")
            except (TypeError, ValueError):
                errors.append(f"state_count_invalid:{state}")

    source_catalog_path = export_dir / "source-catalog.json"
    if not source_catalog_path.is_file():
        errors.append("missing_source_catalog")
    else:
        try:
            source_catalog = _read_json(source_catalog_path)
            sources = source_catalog.get("sources")
            if not isinstance(sources, Mapping):
                errors.append("source_catalog_sources_not_object")
            else:
                for pageid in included_ids:
                    if f"enwikivoyage:{pageid}" not in sources:
                        errors.append(f"source_catalog_missing:{pageid}")
        except (OSError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"invalid_source_catalog:{type(error).__name__}")

    numeric_files = {path.stem: path for path in export_dir.glob("*.jsonl") if path.stem.isdigit()}
    expected_files = {str(pageid) for pageid in included_ids}
    if set(numeric_files) != expected_files:
        errors.append("jsonl_page_count_mismatch")
    input_entries = 0
    all_entries: list[tuple[int, Mapping[str, Any]]] = []
    for pageid in sorted(included_ids):
        path = numeric_files.get(str(pageid))
        if path is None:
            continue
        try:
            rows = _jsonl_rows(path)
        except (OSError, ValueError, json.JSONDecodeError) as error:
            errors.append(f"invalid_jsonl:{pageid}:{type(error).__name__}")
            continue
        if not rows or rows[0].get("record_type") != "dictionary":
            errors.append(f"missing_header:{pageid}")
            continue
        header = rows[0]
        entries = rows[1:]
        entry_count = int(header.get("entry_count") or 0)
        if entry_count != len(entries):
            errors.append(f"entry_count_mismatch:{pageid}")
        if entry_count <= 0:
            errors.append(f"included_page_empty:{pageid}")
        if str(header.get("dictionary_key") or "") != f"enwikivoyage:{pageid}":
            errors.append(f"dictionary_key_mismatch:{pageid}")
        if pageid in report_entry_counts and report_entry_counts[pageid] != entry_count:
            errors.append(f"report_entry_count_mismatch:{pageid}")
        input_entries += len(entries)
        all_entries.extend((pageid, entry) for entry in entries)

    all_entries.sort(key=lambda item: (item[0], str(item[1].get("entry_key") or "")))
    samples: list[Mapping[str, Any]] = []
    if all_entries:
        for index in (0, len(all_entries) // 2, len(all_entries) - 1):
            pageid, entry = all_entries[index]
            sample, error = _sample_entry(entry, pageid)
            if error:
                errors.append(error)
            elif sample is not None:
                samples.append(sample)
    else:
        errors.append("no_valid_entries")

    review_dir = export_dir / "review"
    quarantine_rows = len(tuple(_iter_review_rows(review_dir / "quarantine.jsonl")))
    removal_rows = len(tuple(_iter_review_rows(review_dir / "removals.jsonl")))
    manifest_sha256 = _sha256(manifest_path) if manifest_path.is_file() else ""
    report_sha256 = _sha256(report_path) if report_path.is_file() else ""
    return ExportQualityReport(
        passed=not errors,
        errors=tuple(dict.fromkeys(errors)),
        manifest_pages=len(manifest_pages),
        report_pages=len(report_pages),
        included_pages=len(included_ids),
        jsonl_files=len(numeric_files),
        input_entries=input_entries,
        quarantine_rows=quarantine_rows,
        removal_rows=removal_rows,
        state_counts=state_counts,
        samples=tuple(samples),
        manifest_sha256=manifest_sha256,
        export_report_sha256=report_sha256,
    )


def quality_gate(snapshot_dir: Path, export_dir: Path, export_report_path: Path | None = None) -> ExportQualityReport:
    report = evaluate_export_quality(snapshot_dir, export_dir, export_report_path)
    if not report.passed:
        raise QualityGateError("Wikivoyage export quality gate failed: " + ", ".join(report.errors))
    return report


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot-dir", type=Path, required=True)
    parser.add_argument("--export-dir", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--output", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    report = evaluate_export_quality(args.snapshot_dir, args.export_dir, args.report)
    payload = report.to_dict()
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        temporary = args.output.with_name(f".{args.output.name}.tmp")
        temporary.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        temporary.replace(args.output)
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True))
    return 0 if report.passed else 1


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
