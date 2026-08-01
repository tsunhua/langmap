from __future__ import annotations

import os
import shutil
import signal
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
DEV_SH = REPO_ROOT / "dev.sh"
DEV_RUNTIME_DIR = Path("scripts/db/state/dev-runtime")
BACKEND_PIDFILE = DEV_RUNTIME_DIR / "backend.pid"
FRONTEND_PIDFILE = DEV_RUNTIME_DIR / "frontend.pid"


def write_executable(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")
    path.chmod(0o755)


def read_log(path: Path) -> list[str]:
    if not path.exists():
        return []
    return [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def assert_no_pkill_calls(testcase: unittest.TestCase, log_lines: list[str]) -> None:
    testcase.assertFalse(
        any(line.startswith("pkill\t") for line in log_lines),
        msg=f"unexpected broad pkill cleanup: {log_lines}",
    )


def wait_for(predicate, *, timeout: float = 10.0, interval: float = 0.1) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if predicate():
            return
        time.sleep(interval)
    raise AssertionError("timed out waiting for condition")


def terminate_process(process: subprocess.Popen[bytes] | subprocess.Popen[str]) -> None:
    if process.poll() is None:
        process.kill()
    process.wait()


def build_fixture_repo(root: Path) -> tuple[Path, Path, Path]:
    shutil.copy2(DEV_SH, root / "dev.sh")
    (root / "dev.sh").chmod(0o755)
    (root / "backend" / ".wrangler" / "state").mkdir(parents=True, exist_ok=True)
    (root / "backend" / "node_modules").mkdir(parents=True, exist_ok=True)
    (root / "backend" / ".dev.vars").write_text('SECRET_KEY="fixture"\n', encoding="utf-8")
    (root / "backend" / "wrangler.jsonc").write_text('{"name":"langmap-test"}\n', encoding="utf-8")
    (root / "web" / "node_modules").mkdir(parents=True, exist_ok=True)
    (root / "web" / "vite.config.ts").write_text("export default {}\n", encoding="utf-8")
    (root / "scripts" / "db" / "state").mkdir(parents=True, exist_ok=True)

    fake_bin = root / "fake-bin"
    fake_bin.mkdir(parents=True, exist_ok=True)
    event_log = root / "fake-events.log"
    ps_map = root / "fake-ps.tsv"
    _install_fake_commands(fake_bin)
    return fake_bin, event_log, ps_map


def _install_fake_commands(fake_bin: Path) -> None:
    write_executable(
        fake_bin / "manage.sh",
        """#!/usr/bin/env bash
set -euo pipefail
printf 'manage\\t%s\\n' "$*" >> "${FAKE_EVENT_LOG:?}"
case "${1:-}:${2:-}" in
  local:status)
    if [ -n "${FAKE_STATUS_JSON:-}" ]; then
      printf '%s\\n' "$FAKE_STATUS_JSON"
    else
      printf '%s\\n' '{"rebuild_required":false}'
    fi
    ;;
  local:rebuild)
    exit "${FAKE_REBUILD_EXIT:-0}"
    ;;
  local:verify)
    exit "${FAKE_VERIFY_EXIT:-0}"
    ;;
  *)
    echo "unexpected manage command: $*" >&2
    exit 99
    ;;
esac
""",
    )
    write_executable(
        fake_bin / "npx",
        """#!/usr/bin/env bash
set -euo pipefail
printf 'npx\\t%s\\n' "$*" >> "${FAKE_EVENT_LOG:?}"
mode="${FAKE_SERVER_MODE:-hold}"
record_ps() {
  printf '%s\\t%s\\n' "$$" "$0 $*" >> "${FAKE_PS_MAP:?}"
}
run_server() {
  role="$1"
  shift
  if [ "$mode" = "fail" ]; then
    echo "unexpected server start: $role $*" >&2
    exit 88
  fi
  record_ps "$@"
  printf 'server-start\\t%s\\t%s\\n' "$role" "$*" >> "${FAKE_EVENT_LOG:?}"
  trap 'printf "server-stop\\t%s\\n" "$role" >> "${FAKE_EVENT_LOG:?}"; exit 0' TERM INT
  while :; do
    sleep 1
  done
}
case "${1:-}" in
  wrangler)
    if [ "${2:-}" = "dev" ]; then
      run_server backend "$@"
    fi
    ;;
  vite)
    run_server frontend "$@"
    ;;
esac
exit 0
""",
    )
    write_executable(
        fake_bin / "ps",
        """#!/usr/bin/env bash
set -euo pipefail
pid=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p)
      pid="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
if [ -z "$pid" ] || [ ! -f "${FAKE_PS_MAP:-}" ]; then
  exit 1
fi
line="$(awk -F '\\t' -v wanted="$pid" '$1 == wanted { print substr($0, index($0, $2)); found=1 } END { exit found ? 0 : 1 }' "${FAKE_PS_MAP}")" || exit 1
printf '%s\\n' "$line"
""",
    )
    write_executable(
        fake_bin / "pkill",
        """#!/usr/bin/env bash
set -euo pipefail
printf 'pkill\\t%s\\n' "$*" >> "${FAKE_EVENT_LOG:?}"
exit 0
""",
    )
    write_executable(
        fake_bin / "npm",
        """#!/usr/bin/env bash
set -euo pipefail
printf 'npm\\t%s\\n' "$*" >> "${FAKE_EVENT_LOG:?}"
exit 0
""",
    )
    write_executable(
        fake_bin / "openssl",
        """#!/usr/bin/env bash
set -euo pipefail
printf 'openssl\\t%s\\n' "$*" >> "${FAKE_EVENT_LOG:?}"
printf '0123456789abcdef0123456789abcdef\\n'
""",
    )


class DevShellTests(unittest.TestCase):
    maxDiff = None

    def run_dev(
        self,
        root: Path,
        *,
        args: list[str] | None = None,
        env_overrides: dict[str, str] | None = None,
        timeout: float = 10.0,
    ) -> subprocess.CompletedProcess[str]:
        fake_bin = root / "fake-bin"
        event_log = root / "fake-events.log"
        ps_map = root / "fake-ps.tsv"
        env = {
            **os.environ,
            "PATH": f"{fake_bin}:{os.environ['PATH']}",
            "FAKE_EVENT_LOG": str(event_log),
            "FAKE_PS_MAP": str(ps_map),
        }
        if env_overrides:
            env.update(env_overrides)
        return subprocess.run(
            [str(root / "dev.sh"), *(args or [])],
            cwd=root,
            env=env,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

    def start_dev(
        self,
        root: Path,
        *,
        args: list[str] | None = None,
        env_overrides: dict[str, str] | None = None,
    ) -> subprocess.Popen[str]:
        fake_bin = root / "fake-bin"
        event_log = root / "fake-events.log"
        ps_map = root / "fake-ps.tsv"
        env = {
            **os.environ,
            "PATH": f"{fake_bin}:{os.environ['PATH']}",
            "FAKE_EVENT_LOG": str(event_log),
            "FAKE_PS_MAP": str(ps_map),
        }
        if env_overrides:
            env.update(env_overrides)
        return subprocess.Popen(
            [str(root / "dev.sh"), *(args or [])],
            cwd=root,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

    def test_fingerprint_hit_verifies_then_starts_servers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)

            process = self.start_dev(
                root,
                env_overrides={
                    "FAKE_STATUS_JSON": '{"rebuild_required":false}',
                    "FAKE_SERVER_MODE": "hold",
                },
            )
            try:
                wait_for(
                    lambda: any(
                        line.startswith("server-start\tfrontend")
                        for line in read_log(root / "fake-events.log")
                    )
                )
            finally:
                process.send_signal(signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)

            self.assertEqual(process.returncode, 0, msg=f"{stdout}\n{stderr}")
            log_lines = read_log(root / "fake-events.log")
            self.assertEqual(
                [line for line in log_lines if line.startswith("manage\t")][:2],
                ["manage\tlocal status", "manage\tlocal verify"],
            )
            self.assertNotIn("manage\tlocal rebuild", log_lines)
            assert_no_pkill_calls(self, log_lines)
            self.assertTrue(any(line.startswith("server-start\tbackend") for line in log_lines))
            self.assertTrue(any(line.startswith("server-start\tfrontend") for line in log_lines))

    def test_fingerprint_miss_rebuilds_before_starting_servers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)

            process = self.start_dev(
                root,
                env_overrides={
                    "FAKE_STATUS_JSON": '{"rebuild_required":true}',
                    "FAKE_SERVER_MODE": "hold",
                },
            )
            try:
                wait_for(
                    lambda: any(
                        line.startswith("server-start\tfrontend")
                        for line in read_log(root / "fake-events.log")
                    )
                )
            finally:
                process.send_signal(signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)

            self.assertEqual(process.returncode, 0, msg=f"{stdout}\n{stderr}")
            log_lines = read_log(root / "fake-events.log")
            self.assertEqual(
                [line for line in log_lines if line.startswith("manage\t")][:2],
                ["manage\tlocal status", "manage\tlocal rebuild"],
            )
            self.assertNotIn("manage\tlocal verify", log_lines)
            assert_no_pkill_calls(self, log_lines)
            self.assertTrue(any(line.startswith("server-start\tbackend") for line in log_lines))
            self.assertTrue(any(line.startswith("server-start\tfrontend") for line in log_lines))

    def test_force_rebuild_skips_status_and_starts_servers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)

            process = self.start_dev(
                root,
                args=["--rebuild"],
                env_overrides={
                    "FAKE_SERVER_MODE": "hold",
                },
            )
            try:
                wait_for(
                    lambda: any(
                        line.startswith("server-start\tfrontend")
                        for line in read_log(root / "fake-events.log")
                    )
                )
            finally:
                process.send_signal(signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)

            self.assertEqual(process.returncode, 0, msg=f"{stdout}\n{stderr}")
            log_lines = read_log(root / "fake-events.log")
            self.assertEqual(
                [line for line in log_lines if line.startswith("manage\t")][:1],
                ["manage\tlocal rebuild"],
            )
            self.assertNotIn("manage\tlocal status", log_lines)
            self.assertNotIn("manage\tlocal verify", log_lines)
            assert_no_pkill_calls(self, log_lines)

    def test_no_rebuild_fails_without_starting_servers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)

            result = self.run_dev(
                root,
                args=["--no-rebuild"],
                env_overrides={
                    "FAKE_STATUS_JSON": '{"rebuild_required":true}',
                    "FAKE_SERVER_MODE": "fail",
                },
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("--no-rebuild", result.stderr)
            log_lines = read_log(root / "fake-events.log")
            self.assertEqual(
                [line for line in log_lines if line.startswith("manage\t")],
                ["manage\tlocal status"],
            )
            assert_no_pkill_calls(self, log_lines)
            self.assertFalse(any(line.startswith("npx\twrangler dev") for line in log_lines))
            self.assertFalse(any(line.startswith("npx\tvite") for line in log_lines))

    def test_bootstrap_failures_block_server_start(self) -> None:
        scenarios = [
            (
                "verify-failure",
                [],
                {
                    "FAKE_STATUS_JSON": '{"rebuild_required":false}',
                    "FAKE_VERIFY_EXIT": "7",
                    "FAKE_SERVER_MODE": "fail",
                },
                ["manage\tlocal status", "manage\tlocal verify"],
            ),
            (
                "rebuild-failure",
                ["--rebuild"],
                {
                    "FAKE_REBUILD_EXIT": "9",
                    "FAKE_SERVER_MODE": "fail",
                },
                ["manage\tlocal rebuild"],
            ),
        ]

        for name, args, env_overrides, expected_manage in scenarios:
            with self.subTest(name=name):
                with tempfile.TemporaryDirectory() as temp_dir:
                    root = Path(temp_dir)
                    build_fixture_repo(root)

                    result = self.run_dev(root, args=args, env_overrides=env_overrides)

                    self.assertNotEqual(result.returncode, 0)
                    log_lines = read_log(root / "fake-events.log")
                    self.assertEqual(
                        [line for line in log_lines if line.startswith("manage\t")],
                        expected_manage,
                    )
                    assert_no_pkill_calls(self, log_lines)
                    self.assertFalse(any(line.startswith("npx\twrangler dev") for line in log_lines))
                    self.assertFalse(any(line.startswith("npx\tvite") for line in log_lines))

    def test_port_forwarding_and_cleanup_only_stop_repo_owned_processes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)
            resolved_root = root.resolve()
            runtime_dir = root / DEV_RUNTIME_DIR
            runtime_dir.mkdir(parents=True, exist_ok=True)

            repo_owned = subprocess.Popen(["sleep", "60"])
            self.addCleanup(lambda: terminate_process(repo_owned))
            foreign = subprocess.Popen(["sleep", "60"])
            self.addCleanup(lambda: terminate_process(foreign))

            (runtime_dir / BACKEND_PIDFILE.name).write_text(f"{repo_owned.pid}\n", encoding="utf-8")
            (runtime_dir / FRONTEND_PIDFILE.name).write_text(f"{foreign.pid}\n", encoding="utf-8")
            (root / "fake-ps.tsv").write_text(
                f"{repo_owned.pid}\twrangler dev --persist-to {resolved_root / 'backend' / '.wrangler' / 'state'} {resolved_root}\n"
                f"{foreign.pid}\tvite --host --strictPort /other/project/web/vite.config.ts\n",
                encoding="utf-8",
            )

            process = self.start_dev(
                root,
                args=["--port=9911"],
                env_overrides={
                    "FAKE_STATUS_JSON": '{"rebuild_required":false}',
                    "FAKE_SERVER_MODE": "hold",
                },
            )
            try:
                wait_for(
                    lambda: any(
                        line.startswith("server-start\tfrontend")
                        for line in read_log(root / "fake-events.log")
                    )
                )
                wait_for(lambda: repo_owned.poll() is not None)
                self.assertIsNone(foreign.poll())
            finally:
                process.send_signal(signal.SIGTERM)
                stdout, stderr = process.communicate(timeout=10)

            self.assertEqual(process.returncode, 0, msg=f"{stdout}\n{stderr}")
            log_lines = read_log(root / "fake-events.log")
            backend_start = next(
                line for line in log_lines if line.startswith("server-start\tbackend")
            )
            self.assertIn("--port 9911", backend_start)
            assert_no_pkill_calls(self, log_lines)
            self.assertTrue(any(line == "server-stop\tbackend" for line in log_lines))
            self.assertTrue(any(line == "server-stop\tfrontend" for line in log_lines))
            self.assertFalse((runtime_dir / BACKEND_PIDFILE.name).exists())
            self.assertFalse((runtime_dir / FRONTEND_PIDFILE.name).exists())


if __name__ == "__main__":
    unittest.main()
