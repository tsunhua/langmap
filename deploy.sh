#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WRANGLER_BIN="$ROOT/backend/node_modules/.bin/wrangler"
DEPLOY_ARGS=()
SKIP_BUILD=0

usage() {
  cat <<'EOF'
用法：
  ./deploy.sh [選項] [-- Wrangler 參數]

選項：
  --dry-run     只驗證部署內容，不實際上線
  --skip-build  略過前端構建，直接部署現有 backend/public
  -h, --help    顯示說明

範例：
  ./deploy.sh
  ./deploy.sh --dry-run
  ./deploy.sh --skip-build -- --minify
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DEPLOY_ARGS+=(--dry-run)
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      DEPLOY_ARGS+=("$@")
      break
      ;;
    *)
      DEPLOY_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ "$SKIP_BUILD" -eq 0 ]; then
  echo "▶ 構建前端與 Worker 靜態資源"
  "$ROOT/build.sh"
else
  echo "▶ 略過構建，使用現有 backend/public"
fi

if [ ! -x "$WRANGLER_BIN" ]; then
  echo "找不到本地 Wrangler：$WRANGLER_BIN" >&2
  echo "請先執行：cd backend && npm install" >&2
  exit 1
fi

echo "▶ 部署 langmap-backend-v2"
cd "$ROOT/backend"
if [ "${#DEPLOY_ARGS[@]}" -gt 0 ]; then
  exec npx --no-install wrangler deploy \
    --config "$ROOT/backend/wrangler.jsonc" \
    "${DEPLOY_ARGS[@]}"
else
  exec npx --no-install wrangler deploy \
    --config "$ROOT/backend/wrangler.jsonc"
fi
