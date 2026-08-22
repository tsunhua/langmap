#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd -P)"
BACKEND_PORT="8788"
FORCE_REBUILD=0
ALLOW_REBUILD=1

LOCAL_D1_STATE="$ROOT/backend/.wrangler/state"
DEV_RUNTIME_DIR="$ROOT/scripts/db/state/dev-runtime"
BACKEND_PIDFILE="$DEV_RUNTIME_DIR/backend.pid"
FRONTEND_PIDFILE="$DEV_RUNTIME_DIR/frontend.pid"
MANAGE_BIN="${LANGMAP_DB_MANAGER_BIN:-manage.sh}"
BACKEND_PID=""
FRONTEND_PID=""
CLEANUP_DONE=0

export PATH="$ROOT/scripts/db:$PATH"

usage() {
  cat <<'EOF' >&2
Usage: ./dev.sh [--rebuild | --no-rebuild] [--port=<backend-port>]
EOF
}

trap 'echo "❌ $(basename "$0") 失敗：第 $LINENO 行" >&2' ERR

step() { echo "▶ $*" >&2; }

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少必要指令：$1" >&2
    exit 1
  fi
}

read_pidfile() {
  local pidfile="$1"
  if [ ! -f "$pidfile" ]; then
    return 1
  fi
  tr -d '[:space:]' < "$pidfile"
}

matches_repo_process() {
  local pid="$1"
  local role="$2"
  local command_line

  command_line="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  if [ -z "$command_line" ]; then
    return 1
  fi

  case "$role" in
    backend)
      [[ "$command_line" == *"wrangler dev"* && "$command_line" == *"$ROOT"* ]]
      ;;
    frontend)
      [[ "$command_line" == *"vite"* && "$command_line" == *"$ROOT"* ]]
      ;;
    *)
      return 1
      ;;
  esac
}

stop_pidfile_process() {
  local pidfile="$1"
  local role="$2"
  local pid

  pid="$(read_pidfile "$pidfile" || true)"
  if [ -n "$pid" ] && matches_repo_process "$pid" "$role"; then
    step "停止本 repo 殘留 ${role} process (pid=$pid)"
    kill "$pid" 2>/dev/null || true
  fi

  rm -f "$pidfile"
}

stop_port_process() {
  local port="$1"
  local role="$2"
  local pid
  local pgid
  local group_command
  local process_cwd
  local listener_pids

  listener_pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  for pid in $listener_pids; do
    pgid="$(ps -p "$pid" -o pgid= 2>/dev/null | tr -d '[:space:]')"
    [ -n "$pgid" ] || continue
    group_command="$(ps -p "$pgid" -o command= 2>/dev/null || true)"
    process_cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)"
    [[ "$process_cwd" == "$ROOT" || "$process_cwd" == "$ROOT"/* ]] || continue

    case "$role" in
      backend)
        [[ "$group_command" == *"wrangler dev"* ]] || continue
        ;;
      frontend)
        [[ "$group_command" == *"vite"* ]] || continue
        ;;
      *)
        continue
        ;;
    esac

    step "停止本 repo 佔用 ${port} 的 ${role} process group (pgid=$pgid)"
    kill -TERM -- "-$pgid" 2>/dev/null || true
  done
}

cleanup() {
  if [ "$CLEANUP_DONE" -eq 1 ]; then
    return
  fi
  CLEANUP_DONE=1

  if [ -n "$BACKEND_PID" ] || [ -n "$FRONTEND_PID" ] || [ -f "$BACKEND_PIDFILE" ] || [ -f "$FRONTEND_PIDFILE" ]; then
    echo ""
    echo "停止服務…"
  fi

  stop_pidfile_process "$BACKEND_PIDFILE" backend
  stop_pidfile_process "$FRONTEND_PIDFILE" frontend
}

trap 'cleanup' EXIT
trap 'exit 0' INT TERM

for arg in "$@"; do
  case "$arg" in
    --rebuild)
      FORCE_REBUILD=1
      ;;
    --no-rebuild)
      ALLOW_REBUILD=0
      ;;
    --port=*)
      BACKEND_PORT="${arg#--port=}"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ "$FORCE_REBUILD" -eq 1 ] && [ "$ALLOW_REBUILD" -eq 0 ]; then
  echo "不能同時指定 --rebuild 與 --no-rebuild" >&2
  exit 2
fi

ensure_command "$MANAGE_BIN"
mkdir -p "$DEV_RUNTIME_DIR"

step "停止本 repo 殘留服務"
stop_pidfile_process "$BACKEND_PIDFILE" backend
stop_pidfile_process "$FRONTEND_PIDFILE" frontend
stop_port_process "$BACKEND_PORT" backend
stop_port_process 5173 frontend

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

step "確保前端相依套件已安裝"
cd "$ROOT/web"
[ -d node_modules ] || npm install

step "決定 local bootstrap 流程"
cd "$ROOT"
if [ "$FORCE_REBUILD" -eq 1 ]; then
  step "依旗標強制重建 local D1"
  "$MANAGE_BIN" local rebuild
else
  status_json="$("$MANAGE_BIN" local status)"
  rebuild_required="$(
    printf '%s' "$status_json" | python3 -c 'import json, sys
payload = json.load(sys.stdin)
value = payload.get("rebuild_required")
if not isinstance(value, bool):
    raise SystemExit("status missing boolean rebuild_required")
print("true" if value else "false")'
  )"

  if [ "$rebuild_required" = "true" ]; then
    if [ "$ALLOW_REBUILD" -eq 0 ]; then
      echo "local D1 需要重建，但收到 --no-rebuild；請先執行 ./dev.sh --rebuild。" >&2
      exit 1
    fi
    step "fingerprint miss，重建 local D1"
    "$MANAGE_BIN" local rebuild
  else
    step "fingerprint hit，驗證 local D1"
    "$MANAGE_BIN" local verify
  fi
fi

step "啟動後端 wrangler（port ${BACKEND_PORT}）"
cd "$ROOT/backend"
npx wrangler dev \
  --config "$ROOT/backend/wrangler.jsonc" \
  --persist-to "$LOCAL_D1_STATE" \
  --port "$BACKEND_PORT" &
BACKEND_PID=$!
printf '%s\n' "$BACKEND_PID" > "$BACKEND_PIDFILE"

step "啟動前端 Vite dev server（port 5173，HMR）"
cd "$ROOT/web"
npx vite --host --strictPort --config "$ROOT/web/vite.config.ts" &
FRONTEND_PID=$!
printf '%s\n' "$FRONTEND_PID" > "$FRONTEND_PIDFILE"

echo ""
echo "▶ v2: http://localhost:5173（前端 HMR + /api/v2 → localhost:${BACKEND_PORT}）"
echo "▶ 本機帳號：dev@example.com / dev（僅 local D1）"
echo "按 Ctrl+C 停止"

wait "$BACKEND_PID" "$FRONTEND_PID"
