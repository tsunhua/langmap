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
if [ ! -f "$ROOT/backend/.dev.vars" ]; then
  echo "SECRET_KEY=\"$(openssl rand -hex 32)\"" > "$ROOT/backend/.dev.vars"
  echo "  已生成 backend/.dev.vars"
else
  echo "  backend/.dev.vars 已存在，略過"
fi

step "確保後端相依套件已安裝"
cd "$ROOT/backend"
[ -d node_modules ] || npm install

step "確保本地 D1 schema 已遷移（無表才應用 schema.sql）"
TABLE_COUNT=$(npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) as c FROM sqlite_master WHERE type='table';" 2>/dev/null | grep -oE '"c": [0-9]+' | grep -oE '[0-9]+')
if [ "${TABLE_COUNT:-0}" -eq 0 ]; then
  echo "  本地 D1 無表，套用 schema.sql"
  npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
else
  echo "  本地 D1 已有 ${TABLE_COUNT} 張表，略過遷移"
fi

step "啟動後端 wrangler（port ${PORT:-8788}）"
cd "$ROOT/backend"
npx wrangler dev --port "${PORT:-8788}" &
BACKEND_PID=$!

step "釋放可能殘留的 workerd 檢查器埠 9229（若屬於本 repo 的 workerd）"
INSPECTOR_PID=$(lsof -t -iTCP:9229 -sTCP:LISTEN 2>/dev/null || true)
if [ -n "$INSPECTOR_PID" ]; then
  INSPECTOR_CMD=$(ps -p "$INSPECTOR_PID" -o args= 2>/dev/null || true)
  if echo "$INSPECTOR_CMD" | grep -qE 'workerd|wrangler|langmap'; then
    step "釋放 9229 (pid=$INSPECTOR_PID) — 因為命令看起來屬於本專案或 workerd"
    kill "$INSPECTOR_PID" 2>/dev/null || true
    sleep 1
  else
    echo "  9229 已被其他程序佔用: $INSPECTOR_CMD — 不會強行關閉，若需要請手動處理"
  fi
fi

step "使用 v2 後端作為主要 local API，不再自動啟動舊版後端"

step "啟動前端 Vite dev server（port 5173，HMR）"
cd "$ROOT/web"
[ -d node_modules ] || npm install
npx vite --host --strictPort &
FRONTEND_PID=$!

cleanup() {
  echo ""
  echo "停止服務…"
  kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
  exit 0
}
trap cleanup INT TERM
echo ""
echo "▶ v2: http://localhost:5173（前端 HMR + /api/v2 → localhost:${PORT:-8788}）"
echo "按 Ctrl+C 停止"
wait || true
