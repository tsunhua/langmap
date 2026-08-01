from __future__ import annotations

import hashlib
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


MIGRATION_FILENAME_RE = re.compile(r"^(?P<sequence>\d{4})_[A-Za-z0-9_]+\.sql$")


@dataclass(frozen=True)
class MigrationFile:
    sequence: int
    filename: str
    path: Path
    size: int
    sha256: str


def discover_migrations(migrations_dir: Path) -> list[MigrationFile]:
    if not migrations_dir.exists():
        raise FileNotFoundError(f"migrations directory is missing: {migrations_dir}")
    if not migrations_dir.is_dir():
        raise ValueError(f"migrations path is not a directory: {migrations_dir}")

    migrations: list[MigrationFile] = []
    seen_sequences: dict[int, str] = {}
    for entry in sorted(migrations_dir.iterdir(), key=lambda path: path.name):
        if entry.name.startswith("."):
            continue
        if entry.is_symlink():
            raise ValueError(f"migration entry cannot be a symlink: {entry.name}")
        if not entry.is_file():
            raise ValueError(f"migration entry must be a regular file: {entry.name}")

        match = MIGRATION_FILENAME_RE.match(entry.name)
        if match is None:
            raise ValueError(f"invalid migration filename: {entry.name}")

        sequence = int(match.group("sequence"))
        if sequence in seen_sequences:
            raise ValueError(
                f"duplicate migration sequence {sequence:04d}: "
                f"{seen_sequences[sequence]} and {entry.name}"
            )

        size = entry.stat().st_size
        if size <= 0:
            raise ValueError(f"empty migration file: {entry.name}")

        migration = MigrationFile(
            sequence=sequence,
            filename=entry.name,
            path=entry,
            size=size,
            sha256=_sha256_file(entry),
        )
        migrations.append(migration)
        seen_sequences[sequence] = entry.name

    for previous, current in zip(migrations, migrations[1:]):
        expected = previous.sequence + 1
        if current.sequence != expected:
            raise ValueError(
                f"missing migration sequence between {previous.sequence:04d} and "
                f"{current.sequence:04d}"
            )

    return migrations


def sync_migration_lock(
    migrations_dir: Path,
    lock_path: Path,
    *,
    update: bool,
    baseline_created_at: str,
    git_commit: str,
) -> dict[str, Any]:
    discovered = discover_migrations(migrations_dir)
    existing = _load_lock(lock_path) if lock_path.exists() else None

    if existing is None and not update:
        raise FileNotFoundError(f"migration lock file is missing: {lock_path}")

    if existing is None:
        lock_data = _build_lock_payload(
            discovered,
            baseline_created_at=baseline_created_at,
            git_commit=git_commit,
        )
        _write_lock(lock_path, lock_data)
        return lock_data

    verified_entries: list[dict[str, Any]] = []
    locked_by_filename = {
        entry["filename"]: entry for entry in existing.get("migrations", [])
    }
    discovered_by_filename = {migration.filename: migration for migration in discovered}

    for locked_entry in existing.get("migrations", []):
        filename = locked_entry["filename"]
        migration = discovered_by_filename.get(filename)
        if migration is None:
            raise ValueError(f"missing migration file from lock: {filename}")
        if migration.sha256 != locked_entry["sha256"]:
            raise ValueError(f"published migration checksum changed: {filename}")
        if migration.size != locked_entry["size"]:
            raise ValueError(f"published migration size changed: {filename}")
        verified_entries.append(
            {
                "sequence": migration.sequence,
                "filename": migration.filename,
                "size": migration.size,
                "sha256": migration.sha256,
            }
        )

    new_entries = [
        {
            "sequence": migration.sequence,
            "filename": migration.filename,
            "size": migration.size,
            "sha256": migration.sha256,
        }
        for migration in discovered
        if migration.filename not in locked_by_filename
    ]
    if new_entries and not update:
        raise ValueError(
            "unlocked migration(s) detected: "
            + ", ".join(entry["filename"] for entry in new_entries)
        )

    lock_data = {
        "baseline_created_at": existing["baseline_created_at"],
        "baseline_git_commit": existing["baseline_git_commit"],
        "migrations": verified_entries + new_entries,
    }
    if update:
        _write_lock(lock_path, lock_data)
    return lock_data


def _build_lock_payload(
    migrations: list[MigrationFile], *, baseline_created_at: str, git_commit: str
) -> dict[str, Any]:
    return {
        "baseline_created_at": baseline_created_at,
        "baseline_git_commit": git_commit,
        "migrations": [
            {
                "sequence": migration.sequence,
                "filename": migration.filename,
                "size": migration.size,
                "sha256": migration.sha256,
            }
            for migration in migrations
        ],
    }


def _load_lock(lock_path: Path) -> dict[str, Any]:
    payload = json.loads(lock_path.read_text(encoding="utf-8"))
    if "baseline_created_at" not in payload or "baseline_git_commit" not in payload:
        raise ValueError(f"invalid migration lock metadata: {lock_path}")
    if not isinstance(payload.get("migrations"), list):
        raise ValueError(f"invalid migration lock entries: {lock_path}")
    return payload


def _write_lock(lock_path: Path, payload: dict[str, Any]) -> None:
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()
