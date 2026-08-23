"""Deterministic JSON/Markdown corpus quality reports."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .quality import QualityGate


def write_quality_report(output: Path, gate: QualityGate, *, release_id: str) -> Path:
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = {"release_id": release_id, **gate.to_dict()}
    output.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return output
