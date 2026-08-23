#!/usr/bin/env python3
"""Small deterministic provider fixture for subprocess protocol tests."""

import argparse
import json
from pathlib import Path


parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--pass-id", required=True, type=int)
parser.add_argument("--mode", default="normal")
args = parser.parse_args()

requests = [json.loads(line) for line in Path(args.input).read_text().splitlines() if line.strip()]
if args.mode == "malformed":
    Path(args.output).write_text("not-json\n")
else:
    responses = []
    for request in requests:
        response = {"candidate_key": request["candidate_key"], "pass_id": args.pass_id, "decision": "merge", "confidence": 0.999, "evidence_codes": ["same_text", "definition_overlap"], "conflict_codes": [], "summary": "fixture", "provider_id": "fake", "model_id": "fixture-1"}
        responses.append(response)
    if args.mode == "duplicate" and responses:
        responses.append(responses[0])
    Path(args.output).write_text("\n".join(json.dumps(item, sort_keys=True) for item in responses) + "\n")
