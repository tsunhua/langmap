"""Immutable, deterministic contracts for managed dictionary releases.

The compiler emits a directory rather than one large SQL file.  This module
keeps the directory self-describing and makes every file verifiable before it
is handed to a database executor.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping


def canonical_json(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


@dataclass(frozen=True)
class ArtifactFile:
    path: str
    bytes: int
    sha256: str

    def to_dict(self) -> dict[str, Any]:
        return {"path": self.path, "bytes": self.bytes, "sha256": self.sha256}

    @classmethod
    def from_dict(cls, value: Mapping[str, Any]) -> "ArtifactFile":
        path = value.get("path")
        size = value.get("bytes")
        digest = value.get("sha256")
        if not isinstance(path, str) or not path or Path(path).is_absolute() or ".." in Path(path).parts:
            raise ValueError("artifact file path must be relative and contained")
        if not isinstance(size, int) or size < 0 or not isinstance(digest, str) or len(digest) != 64:
            raise ValueError(f"invalid artifact file descriptor: {value!r}")
        return cls(path, size, digest)


@dataclass(frozen=True)
class ReleaseArtifact:
    root: Path
    manifest: dict[str, Any]

    @property
    def release_id(self) -> str:
        return str(self.manifest["release_id"])

    @property
    def manifest_hash(self) -> str:
        return str(self.manifest["manifest_hash"])

    @property
    def manifest_path(self) -> Path:
        return self.root / "manifest.json"

    @property
    def chunks(self) -> tuple[ArtifactFile, ...]:
        return tuple(ArtifactFile.from_dict(item) for item in self.manifest.get("chunks", []))

    @property
    def sql_paths(self) -> tuple[Path, ...]:
        return tuple(self.root / item.path for item in self.chunks)

    def verify(self) -> None:
        verify_artifact(self.root)


def _file_descriptor(root: Path, relative: str) -> ArtifactFile:
    path = root / relative
    if not path.is_file():
        raise FileNotFoundError(path)
    return ArtifactFile(relative, path.stat().st_size, sha256_file(path))


def content_hash(files: Iterable[ArtifactFile]) -> str:
    digest = hashlib.sha256()
    for item in sorted(files, key=lambda entry: entry.path):
        digest.update(item.path.encode("utf-8"))
        digest.update(b"\0")
        digest.update(str(item.bytes).encode("ascii"))
        digest.update(b"\0")
        digest.update(item.sha256.encode("ascii"))
        digest.update(b"\0")
    return digest.hexdigest()


def write_release_artifact(
    output_dir: Path,
    *,
    release_id: str,
    metadata: Mapping[str, Any],
    files: Mapping[str, bytes],
    chunks: Iterable[str],
    quality_report: Mapping[str, Any] | None = None,
) -> ReleaseArtifact:
    """Atomically create an artifact, refusing to replace a different one."""

    output_dir = Path(output_dir)
    if output_dir.exists():
        existing = output_dir / "manifest.json"
        if not existing.is_file():
            raise FileExistsError(f"refusing incomplete artifact: {output_dir}")
        artifact = load_artifact(output_dir)
        artifact.verify()
        return artifact

    temp = Path(tempfile.mkdtemp(prefix=f".{output_dir.name}.", dir=str(output_dir.parent)))
    try:
        (temp / "sql").mkdir(parents=True)
        (temp / "rollback").mkdir(parents=True)
        for relative, payload in sorted(files.items()):
            target = temp / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(payload)
            with target.open("rb") as handle:
                os.fsync(handle.fileno())
        if quality_report is not None:
            quality_path = temp / "quality-report.json"
            quality_path.write_bytes(canonical_json(dict(quality_report)))
        descriptors = tuple(_file_descriptor(temp, item) for item in chunks)
        if not descriptors:
            raise ValueError("release artifact must contain at least one SQL chunk")
        all_files = tuple(_file_descriptor(temp, item) for item in sorted(files))
        manifest: dict[str, Any] = {
            **dict(metadata),
            "release_id": release_id,
            "manifest_version": 1,
            "chunks": [item.to_dict() for item in descriptors],
            "files": [item.to_dict() for item in all_files],
        }
        manifest["manifest_hash"] = content_hash(descriptors)
        (temp / "manifest.json").write_bytes(canonical_json(manifest))
        (temp / "rollback" / "manifest.json").write_bytes(canonical_json({"release_id": release_id, "parent_release_id": metadata.get("parent_release_id"), "manifest_hash": manifest["manifest_hash"]}))
        os.replace(temp, output_dir)
    except Exception:
        shutil.rmtree(temp, ignore_errors=True)
        raise
    return load_artifact(output_dir)


def load_artifact(root: Path) -> ReleaseArtifact:
    root = Path(root)
    try:
        manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"invalid release artifact manifest: {root}") from exc
    if not isinstance(manifest, dict) or not isinstance(manifest.get("release_id"), str):
        raise ValueError("artifact manifest must contain release_id")
    artifact = ReleaseArtifact(root, manifest)
    artifact.verify()
    return artifact


def verify_artifact(root: Path) -> None:
    root = Path(root)
    try:
        manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError("invalid release artifact manifest") from exc
    if not isinstance(manifest, dict):
        raise ValueError("artifact manifest must be an object")
    chunks = manifest.get("chunks")
    if not isinstance(chunks, list) or not chunks:
        raise ValueError("artifact manifest must contain chunks")
    descriptors = tuple(ArtifactFile.from_dict(item) for item in chunks if isinstance(item, dict))
    if len(descriptors) != len(chunks):
        raise ValueError("invalid chunk descriptor")
    if len({item.path for item in descriptors}) != len(descriptors):
        raise ValueError("duplicate chunk path")
    for item in descriptors:
        actual = _file_descriptor(root, item.path)
        if actual != item:
            raise ValueError(f"artifact checksum mismatch: {item.path}")
    if manifest.get("manifest_hash") != content_hash(descriptors):
        raise ValueError("artifact manifest hash mismatch")
