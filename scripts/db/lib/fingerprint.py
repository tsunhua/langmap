from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from lib.paths import ProjectPaths


@dataclass(frozen=True)
class FingerprintInputs:
    schema_path: Path
    migration_lock_path: Path
    language_manifest_path: Path
    ui_bundle_manifest_path: Path
    dev_fixture_version: str


def compute_bootstrap_fingerprint(inputs: FingerprintInputs) -> str:
    payload = {
        "schema": _describe_file(inputs.schema_path),
        "migration_lock": _describe_file(inputs.migration_lock_path),
        "language_manifest": _describe_file(inputs.language_manifest_path),
        "ui_bundle_manifest": _describe_file(inputs.ui_bundle_manifest_path),
        "dev_fixture_version": inputs.dev_fixture_version,
    }
    serialized = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def build_local_status(paths: ProjectPaths) -> dict[str, Any]:
    desired = compute_bootstrap_fingerprint(default_fingerprint_inputs(paths))
    stored = load_stored_fingerprint(paths.local_fingerprint_path)
    state_exists = paths.local_d1_state_dir.exists()
    return {
        "environment": "local",
        "command": "status",
        "repo_root": str(paths.repo_root),
        "desired_fingerprint": desired,
        "stored_fingerprint": stored,
        "state_exists": state_exists,
        "rebuild_required": (stored != desired) or (not state_exists),
    }


def default_fingerprint_inputs(paths: ProjectPaths) -> FingerprintInputs:
    return FingerprintInputs(
        schema_path=paths.backend_dir / "schema.sql",
        migration_lock_path=paths.migration_lock_path,
        language_manifest_path=paths.language_manifest_path,
        ui_bundle_manifest_path=paths.ui_bundle_manifest_path,
        dev_fixture_version=load_dev_fixture_version(paths),
    )


def load_dev_fixture_version(paths: ProjectPaths) -> str:
    manifest_path = paths.language_manifest_path
    if manifest_path.exists():
        try:
            payload = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return f"sha256:{_sha256_path(manifest_path)}"
        version = payload.get("fixture_version") or payload.get("manifest_version")
        if version is not None:
            return str(version)
        return f"sha256:{_sha256_path(manifest_path)}"
    return "missing"


def load_stored_fingerprint(path: Path) -> str | None:
    if not path.exists():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    fingerprint = payload.get("fingerprint")
    if fingerprint is None:
        raise ValueError(f"stored fingerprint file is missing fingerprint: {path}")
    return str(fingerprint)


def _describe_file(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"exists": False}
    return {
        "exists": True,
        "size": path.stat().st_size,
        "sha256": _sha256_path(path),
    }


def _sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()
