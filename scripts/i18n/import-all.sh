#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${LANGMAP_PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
BUNDLE_SQL="$PROJECT_ROOT/scripts/i18n/artifacts/system-ui/system-ui.sql"

usage() {
  echo "Usage: $0 --local | --remote" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

case "$1" in
  --local)
    ;;
  --remote)
    echo "已停用：remote UI translation import 已移轉到 production data manager。" >&2
    echo "請改用對應的 production manager 指令；此 wrapper 不再直接寫入 production。" >&2
    exit 1
    ;;
  *)
    usage
    exit 2
    ;;
esac

echo "生成 managed system UI bundle..."
python3 "$SCRIPT_DIR/generate-bundle.py"

echo "匯入 local bundle..."
(
  cd "$PROJECT_ROOT/backend"
  npx wrangler d1 execute langmap-v2 \
    --local --file "$BUNDLE_SQL"
)

echo "managed system UI bundle 匯入完成。"
