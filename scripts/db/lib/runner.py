from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence


@dataclass(frozen=True)
class CommandResult:
    args: tuple[str, ...]
    returncode: int
    stdout: str
    stderr: str


class CommandError(RuntimeError):
    def __init__(
        self,
        *,
        args: Sequence[str],
        returncode: int,
        stdout: str,
        stderr: str,
        command_text: str,
    ) -> None:
        super().__init__(f"command failed with exit code {returncode}: {command_text}")
        self.args_list = tuple(args)
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr
        self.command_text = command_text


def run_command(
    args: Sequence[str],
    *,
    cwd: Path,
    timeout: float = 30.0,
    env: Mapping[str, str] | None = None,
    redact: set[str] | frozenset[str] = frozenset(),
) -> CommandResult:
    if not args:
        raise ValueError("command args must not be empty")

    completed = subprocess.run(
        list(args),
        cwd=str(cwd),
        env=dict(env) if env is not None else None,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
        shell=False,
    )
    result = CommandResult(
        args=tuple(args),
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )
    if completed.returncode != 0:
        raise CommandError(
            args=args,
            returncode=completed.returncode,
            stdout=completed.stdout,
            stderr=completed.stderr,
            command_text=_format_command(args, redact=redact),
        )
    return result


def _format_command(args: Sequence[str], *, redact: set[str] | frozenset[str]) -> str:
    return " ".join("**REDACTED**" if item in redact else item for item in args)
