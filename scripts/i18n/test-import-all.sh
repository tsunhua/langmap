#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPORT_SCRIPT="$SCRIPT_DIR/import-all.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/bin"
mkdir -p "$TEST_DIR/repo/scripts/i18n/artifacts/system-ui"
mkdir -p "$TEST_DIR/repo/backend"
cat > "$TEST_DIR/bin/npx" <<'EOF'
#!/usr/bin/env bash
printf 'npx %s\n' "$*" >> "$I18N_TEST_LOG"
EOF
chmod +x "$TEST_DIR/bin/npx"
cat > "$TEST_DIR/bin/python3" <<'EOF'
#!/usr/bin/env bash
printf 'python3 %s\n' "$*" >> "$I18N_TEST_LOG"
EOF
chmod +x "$TEST_DIR/bin/python3"

run_import() {
  PATH="$TEST_DIR/bin:$PATH" \
    TMPDIR="$TEST_DIR" \
    I18N_TEST_LOG="$TEST_DIR/invocations.log" \
    LANGMAP_PROJECT_ROOT="$TEST_DIR/repo" \
    "$IMPORT_SCRIPT" "$@"
}

assert_local_bundle_import() {
  test "$(wc -l < "$TEST_DIR/invocations.log" | tr -d ' ')" = "2"
  grep -q -- 'python3 .*/generate-bundle.py$' "$TEST_DIR/invocations.log"
  grep -q -- 'npx wrangler d1 execute langmap-v2 --local --file .*/scripts/i18n/artifacts/system-ui/system-ui.sql$' "$TEST_DIR/invocations.log"
}

: > "$TEST_DIR/invocations.log"
run_import --local >/dev/null
assert_local_bundle_import

: > "$TEST_DIR/invocations.log"
if run_import --remote >/dev/null 2>&1; then
  echo "remote import should fail with deprecation guidance" >&2
  exit 1
fi
test ! -s "$TEST_DIR/invocations.log"

if run_import >/dev/null 2>&1; then
  echo "missing mode should fail" >&2
  exit 1
fi

echo "PASS: import-all bundle wrapper behavior"
