#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOCALES=(zh-Hans-CN zh-Hant-TW es-ES ja-JP)

usage() {
  echo "Usage: $0 --local | --remote" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

case "$1" in
  --local)
    mode="--local"
    ;;
  --remote)
    mode="--remote"
    echo "即將匯入遠端 D1：${LOCALES[*]}"
    read -r -p "輸入 yes 繼續： " confirmation
    if [[ "$confirmation" != "yes" ]]; then
      echo "已取消遠端匯入。"
      exit 1
    fi
    ;;
  *)
    usage
    exit 2
    ;;
esac

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/langmap-i18n.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT

for locale in "${LOCALES[@]}"; do
  echo "生成 $locale SQL..."
  python3 "$SCRIPT_DIR/generate-i18n-sql.py" \
    "$locale" "$SCRIPT_DIR/$locale.json" \
    > "$temp_dir/$locale-import.sql"
done

for locale in "${LOCALES[@]}"; do
  echo "匯入 $locale ($mode)..."
  (
    cd "$PROJECT_ROOT/backend"
    npx wrangler d1 execute langmap-v2 \
      "$mode" --file "$temp_dir/$locale-import.sql"
  )
done

echo "全部語言匯入完成。"
