#!/usr/bin/env bash
# Import the next not-yet-imported dictionary into the local D1, small-file first.
#
# Usage:
#   ./scripts/dictionary/import_next.sh                # next single file
#   ./scripts/dictionary/import_next.sh 5              # next up to 5 files
#   ./scripts/dictionary/import_next.sh --all          # everything remaining
#
# Resume is driven by /Volumes/DATA/langmap-incremental-state.json. Files whose
# sha256 and release are already recorded (and present in D1) are skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd -P)"
INPUT_DIR="/Volumes/DATA/langmap-structured-jsonl"
STATE="/Volumes/DATA/langmap-incremental-state.json"
STAGING_ROOT="/Volumes/DATA/langmap-staging-parts"
BATCH_SIZE="${LANGMAP_IMPORT_BATCH:-5000}"
COMMIT_EVERY="${LANGMAP_IMPORT_COMMIT:-20000}"

D1="$(find "$ROOT/backend/.wrangler/state" -path '*d1*' -name '*.sqlite' ! -name 'metadata.sqlite' -print -quit)"
if [ -z "$D1" ]; then
  echo "找不到本地 D1（backend/.wrangler/state/v3/d1/...）" >&2
  exit 1
fi

LIMIT="1"
if [[ "${1:-}" == "--all" ]]; then
  LIMIT=""
elif [ -n "${1:-}" ]; then
  LIMIT="$1"
fi

PYTHONPATH="$ROOT/scripts/dictionary" python3 "$ROOT/scripts/dictionary/incremental_import.py" \
  --input-dir "$INPUT_DIR" \
  --d1-database "$D1" \
  --state "$STATE" \
  --staging-root "$STAGING_ROOT" \
  --batch-size "$BATCH_SIZE" \
  --commit-every "$COMMIT_EVERY" \
  ${LIMIT:+--limit-files "$LIMIT"}

echo ""
echo "已完成。進度："
python3 -c "import json;d=json.load(open('$STATE'));[print('  %-45s %s' % (k,v.get('status'))) for k,v in sorted(d['files'].items())]"