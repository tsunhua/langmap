#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
PORT=""

for arg in "$@"; do
  case "$arg" in
    --port=*) PORT="${arg#--port=}" ;;
  esac
done

trap 'echo "❌ $(basename "$0") 失敗：第 $LINENO 行" >&2' ERR
step() { echo "▶ $*" >&2; }

step "停止殘留 wrangler"
pkill -f "wrangler dev" 2>/dev/null || true

step "確保 v2 本地 secret（.dev.vars）存在"
if [ ! -f "$ROOT/backend_v2/.dev.vars" ]; then
  echo "SECRET_KEY=\"$(openssl rand -hex 32)\"" > "$ROOT/backend_v2/.dev.vars"
  echo "  已生成 backend_v2/.dev.vars"
else
  echo "  backend_v2/.dev.vars 已存在，略過"
fi

step "啟動 v2 後端（本地 D1，port ${PORT:-8789}）"
cd "$ROOT/backend_v2"
npx wrangler dev --port "${PORT:-8789}" &
BACKEND_PID=$!

step "啟動前端（port 5173）"
cd "$ROOT/web_v2"
npx vite --port 5173 &
FRONTEND_PID=$!

trap 'echo ""; echo "停止所有服務…"; kill '"$BACKEND_PID"' '"$FRONTEND_PID"' 2>/dev/null; exit 0' INT TERM
echo ""
echo "▶ v2 後端: http://localhost:${PORT:-8789}"
echo "▶ 前端:    http://localhost:5173"
echo "按 Ctrl+C 停止全部"
wait || true
