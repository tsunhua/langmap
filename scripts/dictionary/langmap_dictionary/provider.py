"""Safe provider-agnostic JSONL subprocess runner."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence

from .decision_schema import ReconciliationRequest, ReconciliationResponse, decode_response, encode_jsonl


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _truncate(value: bytes | str, limit: int = 4096) -> str:
    text = value.decode("utf-8", errors="replace") if isinstance(value, bytes) else value
    return text[:limit] + ("…" if len(text) > limit else "")


class ProviderError(RuntimeError):
    """Provider process or protocol failure; callers must abstain."""


@dataclass(frozen=True)
class ProviderRun:
    pass_id: int
    requests_path: Path
    responses_path: Path
    requests_sha256: str
    responses_sha256: str
    responses: tuple[ReconciliationResponse, ...]
    provider_id: str
    model_id: str


def run_provider(
    command: Sequence[str],
    requests: Sequence[ReconciliationRequest],
    output_dir: Path,
    timeout_seconds: float = 1800,
    *,
    pass_id: int | None = None,
    environment: Mapping[str, str] | None = None,
) -> ProviderRun:
    """Run a JSONL provider without a shell and validate complete coverage."""
    if isinstance(command, (str, bytes)) or not command:
        raise ValueError("provider command must be a non-empty argument array")
    if timeout_seconds <= 0:
        raise ValueError("timeout_seconds must be positive")
    if not requests:
        raise ValueError("provider request set must not be empty")
    requested_pass = pass_id if pass_id is not None else requests[0].pass_id
    if any(item.pass_id != requested_pass for item in requests):
        raise ValueError("all requests in one provider run must use the same pass_id")
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    requests_path = output_dir / f"requests-pass-{requested_pass}.jsonl"
    responses_path = output_dir / f"responses-pass-{requested_pass}.jsonl"
    if requests_path.exists() or responses_path.exists():
        raise FileExistsError("provider output paths already exist")
    request_bytes = ("\n".join(encode_jsonl(item) for item in requests) + "\n").encode("utf-8")
    requests_path.write_bytes(request_bytes)
    if environment:
        child_env = os.environ.copy()
        child_env.update({str(key): str(value) for key, value in environment.items()})
    else:
        child_env = None
    args = [str(item) for item in command] + ["--input", str(requests_path), "--output", str(responses_path), "--pass-id", str(requested_pass)]
    try:
        result = subprocess.run(args, shell=False, env=child_env, capture_output=True, timeout=timeout_seconds, check=False)
    except subprocess.TimeoutExpired as error:
        raise ProviderError(f"provider timed out after {timeout_seconds:g}s; stderr={_truncate(error.stderr or b'')}") from error
    if result.returncode != 0:
        raise ProviderError(f"provider exited {result.returncode}; stderr={_truncate(result.stderr)}; stdout={_truncate(result.stdout)}")
    if not responses_path.is_file():
        raise ProviderError("provider did not create response JSONL")
    responses: list[ReconciliationResponse] = []
    seen: set[tuple[str, str]] = set()
    try:
        with responses_path.open(encoding="utf-8") as handle:
            for line_number, line in enumerate(handle, 1):
                if not line.strip():
                    raise ValueError(f"response line {line_number}: blank line")
                response = decode_response(line, line_number)
                if response.pass_id != requested_pass:
                    raise ValueError(f"response line {line_number}: mismatched pass_id")
                key = (response.candidate_key.left_claim_key, response.candidate_key.right_claim_key)
                if key in seen:
                    raise ValueError(f"response line {line_number}: duplicate candidate")
                seen.add(key)
                responses.append(response)
    except (OSError, ValueError) as error:
        raise ProviderError(str(error)) from error
    expected = {(item.candidate_key.left_claim_key, item.candidate_key.right_claim_key) for item in requests}
    if seen != expected:
        missing = sorted(expected - seen)
        extra = sorted(seen - expected)
        raise ProviderError(f"provider response coverage mismatch; missing={missing[:5]} extra={extra[:5]}")
    ids = {(item.provider_id, item.model_id) for item in responses}
    if len(ids) != 1:
        raise ProviderError("provider/model identifiers must be uniform within a run")
    provider_id, model_id = next(iter(ids))
    return ProviderRun(requested_pass, requests_path, responses_path, _sha256(requests_path), _sha256(responses_path), tuple(responses), provider_id, model_id)
