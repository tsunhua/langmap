from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProjectPaths:
    repo_root: Path
    backend_dir: Path
    migrations_dir: Path
    migration_lock_path: Path
    state_dir: Path
    local_state_dir: Path
    local_fingerprint_path: Path
    artifacts_dir: Path
    operations_dir: Path
    local_d1_state_dir: Path
    language_manifest_path: Path
    ui_bundle_manifest_path: Path

    @classmethod
    def discover(cls, repo_root: Path | None = None) -> "ProjectPaths":
        root = (repo_root or Path(__file__).resolve().parents[3]).resolve()
        backend_dir = root / "backend"
        migrations_dir = backend_dir / "migrations"
        migration_lock_path = root / "scripts" / "db" / "migration-lock.json"
        state_dir = root / "scripts" / "db" / "state"
        local_state_dir = state_dir / "local"
        local_fingerprint_path = local_state_dir / "bootstrap-fingerprint.json"
        artifacts_dir = state_dir / "artifacts"
        operations_dir = state_dir / "operations"
        local_d1_state_dir = backend_dir / ".wrangler" / "state"
        language_manifest_path = root / "scripts" / "v2" / "fixtures" / "language-migration.json"
        ui_bundle_manifest_path = (
            root / "scripts" / "i18n" / "artifacts" / "system-ui" / "manifest.json"
        )

        expected_paths = {
            "backend directory": backend_dir,
            "migrations directory": migrations_dir,
            "scripts/db directory": root / "scripts" / "db",
        }
        for label, expected_path in expected_paths.items():
            if not expected_path.exists():
                raise ValueError(f"missing {label}: {expected_path}")

        return cls(
            repo_root=root,
            backend_dir=backend_dir,
            migrations_dir=migrations_dir,
            migration_lock_path=migration_lock_path,
            state_dir=state_dir,
            local_state_dir=local_state_dir,
            local_fingerprint_path=local_fingerprint_path,
            artifacts_dir=artifacts_dir,
            operations_dir=operations_dir,
            local_d1_state_dir=local_d1_state_dir,
            language_manifest_path=language_manifest_path,
            ui_bundle_manifest_path=ui_bundle_manifest_path,
        )

    def ensure_safe_cleanup_target(
        self, candidate: Path, *, allowed_root: Path | None = None
    ) -> Path:
        boundary_root = (
            allowed_root.resolve(strict=False)
            if allowed_root is not None
            else self.repo_root.resolve()
        )
        resolved = candidate.resolve(strict=False)
        resolved_parent = candidate.parent.resolve(strict=False)
        forbidden = {
            Path("/").resolve(),
            Path.home().resolve(),
            self.repo_root.resolve(),
        }
        if resolved in forbidden or resolved_parent in forbidden:
            raise ValueError(f"unsafe cleanup target: {resolved}")

        if resolved == boundary_root:
            raise ValueError(f"cleanup target cannot be root: {resolved}")

        for path_to_check in (resolved_parent, resolved):
            try:
                path_to_check.relative_to(boundary_root)
            except ValueError as exc:
                raise ValueError(
                    f"cleanup target escapes allowed root: {path_to_check}"
                ) from exc

        return resolved
