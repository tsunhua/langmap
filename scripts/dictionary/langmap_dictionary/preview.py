"""Atomic, deterministic preview artifacts for staged dictionary data."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import sqlite3
import tempfile
from pathlib import Path
from typing import Any

from .models import PreviewManifest


def _encoded(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def _write(path: Path, payload: bytes) -> dict[str, Any]:
    path.write_bytes(payload)
    with path.open("rb") as handle:
        os.fsync(handle.fileno())
    return {"path": path.name, "bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest()}


def build_preview(connection: sqlite3.Connection, release_id: str, output_dir: Path) -> PreviewManifest:
    release = connection.execute("SELECT * FROM staging_releases WHERE id=?", (release_id,)).fetchone()
    if release is None:
        raise ValueError(f"unknown release: {release_id}")
    if release["status"] != "staged":
        raise ValueError(f"release is not staged: {release['status']}")
    bindings: list[dict[str, Any]] = []
    for row in connection.execute("SELECT * FROM lexical_occurrences WHERE release_id=? AND lang_code IS NOT NULL AND errors_json='[]' ORDER BY lang_code, canonical_text, cluster_key, claim_key", (release_id,)):
        bindings.append({
            "claim_key": row["claim_key"], "cluster_key": row["cluster_key"], "canonical_text": row["canonical_text"],
            "lang_code": row["lang_code"], "locale_code": row["locale_code"], "occurrence_kind": row["occurrence_kind"],
            "entry_key": row["entry_key"], "sense_key": row["sense_key"],
        })
    quarantine = [dict(row) for row in connection.execute("SELECT dictionary_key,entry_key,sense_key,claim_key,error_code,detail FROM quarantine_items WHERE release_id=? ORDER BY error_code,dictionary_key,claim_key", (release_id,))]
    quality = {
        "release_id": release_id,
        "input_records": release["input_records"],
        "staged_entries": release["staged_entries"],
        "staged_senses": release["staged_senses"],
        "bindings": len(bindings),
        "clusters": connection.execute("SELECT COUNT(*) FROM lexical_clusters WHERE release_id=?", (release_id,)).fetchone()[0],
        "quarantined": len(quarantine),
        "publishable_occurrences": len(bindings),
    }
    payloads = {
        "bindings.jsonl": b"".join(_encoded(item) for item in bindings),
        "quarantine.jsonl": b"".join(_encoded(item) for item in quarantine),
        "quality-report.json": _encoded(quality),
    }
    artifact_hash = hashlib.sha256(b"".join(payloads[name] for name in sorted(payloads))).hexdigest()
    files = tuple({"path": name, "bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest()} for name, payload in sorted(payloads.items()))
    manifest = {"release_id": release_id, "manifest_hash": artifact_hash, "files": list(files)}
    payloads["manifest.json"] = _encoded(manifest)
    final_manifest = PreviewManifest(release_id, artifact_hash, files + ({"path": "manifest.json", "bytes": len(payloads["manifest.json"]), "sha256": hashlib.sha256(payloads["manifest.json"]).hexdigest()},))

    output_dir = Path(output_dir)
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    if output_dir.exists():
        existing_path = output_dir / "manifest.json"
        if not existing_path.is_file():
            raise FileExistsError(f"refusing to overwrite incomplete artifact: {output_dir}")
        existing = json.loads(existing_path.read_text(encoding="utf-8"))
        if existing.get("manifest_hash") != artifact_hash:
            raise FileExistsError(f"refusing to overwrite a different artifact: {output_dir}")
        return final_manifest
    temporary = Path(tempfile.mkdtemp(prefix=f".{output_dir.name}.", dir=output_dir.parent))
    try:
        for name, payload in sorted(payloads.items()):
            _write(temporary / name, payload)
        os.replace(temporary, output_dir)
    except Exception:
        shutil.rmtree(temporary, ignore_errors=True)
        raise
    return final_manifest
