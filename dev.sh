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

step "確保後端相依套件已安裝"
cd "$ROOT/backend_v2"
[ -d node_modules ] || npm install

step "確保本地 D1 schema 已遷移（無表才應用 schema.sql）"
TABLE_COUNT=$(npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) as c FROM sqlite_master WHERE type='table';" 2>/dev/null | grep -oE '"c": [0-9]+' | grep -oE '[0-9]+')
if [ "${TABLE_COUNT:-0}" -eq 0 ]; then
  echo "  本地 D1 無表，套用 schema.sql"
  npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
else
  echo "  本地 D1 已有 ${TABLE_COUNT} 張表，略過遷移"
fi

step "啟動後端 wrangler（port ${PORT:-8789}）"
cd "$ROOT/backend_v2"
npx wrangler dev --port "${PORT:-8789}" &
BACKEND_PID=$!

step "啟動前端 Vite dev server（port 5173，HMR）"
cd "$ROOT/web_v2"
[ -d node_modules ] || npm install
npx vite --host &
FRONTEND_PID=$!

trap 'echo ""; echo "停止服務…"; kill '"$BACKEND_PID"' '"$FRONTEND_PID"' 2>/dev/null; exit 0' INT TERM
echo ""
echo "▶ v2: http://localhost:5173（前端 HMR + /api/v2 → localhost:${PORT:-8789}）"
echo "按 Ctrl+C 停止"
wait || true
