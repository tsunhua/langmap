from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProjectPaths:
    repo_root: Path
    backend_dir: Path
    migrations_dir: Path
    state_dir: Path
    artifacts_dir: Path
    operations_dir: Path
    local_d1_state_dir: Path

    @classmethod
    def discover(cls, repo_root: Path | None = None) -> "ProjectPaths":
        root = (repo_root or Path(__file__).resolve().parents[3]).resolve()
        backend_dir = root / "backend"
        migrations_dir = backend_dir / "migrations"
        state_dir = root / "scripts" / "db" / "state"
        artifacts_dir = state_dir / "artifacts"
        operations_dir = state_dir / "operations"
        local_d1_state_dir = backend_dir / ".wrangler" / "state"

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
            state_dir=state_dir,
            artifacts_dir=artifacts_dir,
            operations_dir=operations_dir,
            local_d1_state_dir=local_d1_state_dir,
        )

    def ensure_safe_cleanup_target(
        self, candidate: Path, *, allowed_root: Path | None = None
    ) -> Path:
        resolved = candidate.resolve(strict=False)
        forbidden = {
            Path("/").resolve(),
            Path.home().resolve(),
            self.repo_root.resolve(),
        }
        if resolved in forbidden:
            raise ValueError(f"unsafe cleanup target: {resolved}")

        try:
            candidate.relative_to(candidate.parent)
        except ValueError as exc:
            raise ValueError(f"invalid cleanup target: {candidate}") from exc

        if allowed_root is not None:
            allowed_resolved = allowed_root.resolve(strict=False)
            if resolved == allowed_resolved:
                raise ValueError(f"cleanup target cannot be root: {resolved}")
            try:
                resolved.relative_to(allowed_resolved)
            except ValueError as exc:
                raise ValueError(
                    f"cleanup target escapes allowed root: {resolved}"
                ) from exc

        return resolved
