#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPORT_SCRIPT="$SCRIPT_DIR/import-all.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/bin"
cat > "$TEST_DIR/bin/npx" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$I18N_TEST_LOG"
EOF
chmod +x "$TEST_DIR/bin/npx"

run_import() {
  PATH="$TEST_DIR/bin:$PATH" \
    TMPDIR="$TEST_DIR" \
    I18N_TEST_LOG="$TEST_DIR/invocations.log" \
    "$IMPORT_SCRIPT" "$@"
}

assert_mode_imported_four_times() {
  local mode="$1"
  test "$(wc -l < "$TEST_DIR/invocations.log" | tr -d ' ')" = "4"
  test "$(grep -c -- "$mode" "$TEST_DIR/invocations.log")" = "4"
  test "$(grep -c -- '--file' "$TEST_DIR/invocations.log")" = "4"
}

: > "$TEST_DIR/invocations.log"
run_import --local >/dev/null
assert_mode_imported_four_times --local

: > "$TEST_DIR/invocations.log"
if printf 'no\n' | run_import --remote >/dev/null 2>&1; then
  echo "remote import should stop unless the user enters yes" >&2
  exit 1
fi
test ! -s "$TEST_DIR/invocations.log"

: > "$TEST_DIR/invocations.log"
printf 'yes\n' | run_import --remote >/dev/null
assert_mode_imported_four_times --remote

if run_import >/dev/null 2>&1; then
  echo "missing mode should fail" >&2
  exit 1
fi

echo "PASS: import-all local/remote behavior"
