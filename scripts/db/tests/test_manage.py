from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from importlib import util as importlib_util
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MANAGE_PY = REPO_ROOT / "scripts" / "db" / "manage.py"
PATHS_PY = REPO_ROOT / "scripts" / "db" / "lib" / "paths.py"
RUNNER_PY = REPO_ROOT / "scripts" / "db" / "lib" / "runner.py"


def run_manage(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(MANAGE_PY), *args],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )


def load_module(module_path: Path, module_name: str):
    spec = importlib_util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise AssertionError(f"unable to load module from {module_path}")
    module = importlib_util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


class ManageCliTests(unittest.TestCase):
    def test_requires_environment_and_command(self) -> None:
        result = run_manage()

        self.assertEqual(result.returncode, 2)
        self.assertIn("usage:", result.stderr)

    def test_rejects_unknown_environment(self) -> None:
        result = run_manage("staging", "status")

        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid choice", result.stderr)
        self.assertIn("local", result.stderr)
        self.assertIn("production", result.stderr)

    def test_local_accepts_only_supported_commands(self) -> None:
        for command in ("status", "rebuild", "verify"):
            with self.subTest(command=command):
                result = run_manage("local", command)
                self.assertEqual(
                    result.returncode,
                    0,
                    msg=f"expected local {command} to be accepted: {result.stderr}",
                )

        result = run_manage("local", "inventory")

        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid choice", result.stderr)

    def test_production_accepts_only_supported_commands(self) -> None:
        for command in ("inventory", "plan", "apply", "verify"):
            with self.subTest(command=command):
                result = run_manage("production", command)
                self.assertEqual(
                    result.returncode,
                    0,
                    msg=f"expected production {command} to be accepted: {result.stderr}",
                )

        result = run_manage("production", "status")

        self.assertEqual(result.returncode, 2)
        self.assertIn("invalid choice", result.stderr)

    def test_restore_requires_bookmark(self) -> None:
        result = run_manage("production", "restore")

        self.assertEqual(result.returncode, 2)
        self.assertIn("bookmark", result.stderr)

    def test_rejects_unknown_trailing_args(self) -> None:
        result = run_manage("local", "status", "DROP TABLE users;")

        self.assertEqual(result.returncode, 2)
        self.assertIn("unrecognized arguments", result.stderr)

    def test_restore_accepts_exactly_one_bookmark(self) -> None:
        result = run_manage("production", "restore", "bookmark-123")

        self.assertEqual(
            result.returncode,
            0,
            msg=f"expected restore bookmark to be accepted: {result.stderr}",
        )

        extra = run_manage("production", "restore", "bookmark-123", "extra")
        self.assertEqual(extra.returncode, 2)
        self.assertIn("unrecognized arguments", extra.stderr)


class ProjectPathsTests(unittest.TestCase):
    def test_discovers_expected_repository_paths(self) -> None:
        if not PATHS_PY.exists():
            self.fail("paths.py missing")

        paths_module = load_module(PATHS_PY, "db_paths")
        paths = paths_module.ProjectPaths.discover(REPO_ROOT)

        self.assertEqual(paths.repo_root, REPO_ROOT)
        self.assertEqual(paths.backend_dir, REPO_ROOT / "backend")
        self.assertEqual(paths.migrations_dir, REPO_ROOT / "backend" / "migrations")
        self.assertEqual(paths.local_d1_state_dir, REPO_ROOT / "backend" / ".wrangler" / "state")
        self.assertEqual(paths.state_dir, REPO_ROOT / "scripts" / "db" / "state")
        self.assertEqual(paths.artifacts_dir, REPO_ROOT / "scripts" / "db" / "state" / "artifacts")
        self.assertEqual(paths.operations_dir, REPO_ROOT / "scripts" / "db" / "state" / "operations")

    def test_rejects_unsafe_cleanup_targets(self) -> None:
        if not PATHS_PY.exists():
            self.fail("paths.py missing")

        paths_module = load_module(PATHS_PY, "db_paths")
        paths = paths_module.ProjectPaths.discover(REPO_ROOT)

        for unsafe_path in (Path("/"), Path.home(), REPO_ROOT):
            with self.subTest(unsafe_path=unsafe_path):
                with self.assertRaises(ValueError):
                    paths.ensure_safe_cleanup_target(unsafe_path)

    def test_rejects_symlink_escape_cleanup_target(self) -> None:
        if not PATHS_PY.exists():
            self.fail("paths.py missing")

        paths_module = load_module(PATHS_PY, "db_paths")
        paths = paths_module.ProjectPaths.discover(REPO_ROOT)

        with tempfile.TemporaryDirectory(dir=REPO_ROOT) as temp_dir:
            temp_root = Path(temp_dir)
            allowed = temp_root / "allowed"
            allowed.mkdir()
            external_root = Path(tempfile.mkdtemp())
            self.addCleanup(lambda: shutil.rmtree(external_root))
            escape = temp_root / "escape"
            escape.symlink_to(external_root, target_is_directory=True)

            self.assertEqual(paths.ensure_safe_cleanup_target(allowed), allowed.resolve())
            with self.assertRaises(ValueError):
                paths.ensure_safe_cleanup_target(escape)

    def test_rejects_cleanup_target_inside_symlinked_parent_directory(self) -> None:
        if not PATHS_PY.exists():
            self.fail("paths.py missing")

        paths_module = load_module(PATHS_PY, "db_paths")
        paths = paths_module.ProjectPaths.discover(REPO_ROOT)

        with tempfile.TemporaryDirectory(dir=REPO_ROOT) as temp_dir:
            temp_root = Path(temp_dir)
            external_root = Path(tempfile.mkdtemp())
            self.addCleanup(lambda: shutil.rmtree(external_root))
            outside_child = external_root / "child"
            outside_child.mkdir()
            jump = temp_root / "jump"
            jump.symlink_to(external_root, target_is_directory=True)

            with self.assertRaises(ValueError):
                paths.ensure_safe_cleanup_target(jump / "child")


class RunnerTests(unittest.TestCase):
    def test_run_command_captures_output(self) -> None:
        if not RUNNER_PY.exists():
            self.fail("runner.py missing")

        runner_module = load_module(RUNNER_PY, "db_runner")
        result = runner_module.run_command(
            [sys.executable, "-c", "print('ok')"],
            cwd=REPO_ROOT,
        )

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "ok")
        self.assertEqual(result.stderr, "")

    def test_run_command_redacts_sensitive_arguments_in_errors(self) -> None:
        if not RUNNER_PY.exists():
            self.fail("runner.py missing")

        runner_module = load_module(RUNNER_PY, "db_runner")

        with self.assertRaises(runner_module.CommandError) as context:
            runner_module.run_command(
                [
                    sys.executable,
                    "-c",
                    "import sys; sys.stderr.write('boom\\n'); sys.exit(7)",
                    "token-123",
                ],
                cwd=REPO_ROOT,
                redact={"token-123"},
            )

        error = context.exception
        self.assertEqual(error.returncode, 7)
        self.assertIn("boom", error.stderr)
        self.assertIn("**REDACTED**", error.command_text)
        self.assertNotIn("token-123", error.command_text)


if __name__ == "__main__":
    unittest.main()
