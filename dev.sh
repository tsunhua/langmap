#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd -P)"
BACKEND_PORT="8788"

DEV_RUNTIME_DIR="$ROOT/.dev-runtime"
BACKEND_PIDFILE="$DEV_RUNTIME_DIR/backend.pid"
FRONTEND_PIDFILE="$DEV_RUNTIME_DIR/frontend.pid"
BACKEND_PID=""
FRONTEND_PID=""
CLEANUP_DONE=0


usage() {
  cat <<'EOF' >&2
Usage: ./dev.sh [--port=<backend-port>]
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

trim_dotenv_value() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  case "$value" in
    \"*\") value="${value:1:${#value}-2}" ;;
    \'*\') value="${value:1:${#value}-2}" ;;
  esac
  printf '%s' "$value"
}

load_cloudflare_credentials_from_dev_vars() {
  local vars_file="$ROOT/backend/.dev.vars"
  local line key value

  [ -f "$vars_file" ] || return 0

  # Wrangler loads .dev.vars for the Worker. Keep these credentials available
  # to commands launched by this script as well, including non-interactive CLI
  # invocations.
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"
    case "$line" in
      ""|\#*) continue ;;
    esac

    case "$line" in
      *[=]*) ;;
      *) continue ;;
    esac

    key="${line%%=*}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    case "$key" in
      CLOUDFLARE_API_TOKEN)
        [ -n "${CLOUDFLARE_API_TOKEN:-}" ] && continue
        value="$(trim_dotenv_value "${line#*=}")"
        [ -n "$value" ] && export CLOUDFLARE_API_TOKEN="$value"
        ;;
      CLOUDFLARE_ACCOUNT_ID)
        [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ] && continue
        value="$(trim_dotenv_value "${line#*=}")"
        [ -n "$value" ] && export CLOUDFLARE_ACCOUNT_ID="$value"
        ;;
    esac
  done < "$vars_file"
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
    --port=*)
      BACKEND_PORT="${arg#--port=}"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

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

step "載入 Wrangler 本地認證（若有 backend/.dev.vars）"
load_cloudflare_credentials_from_dev_vars
if [ -z "${DATABASE_URL:-}" ] && ! grep -q "^DATABASE_URL=" "$ROOT/backend/.dev.vars"; then
  echo "請在 backend/.dev.vars 或環境變數設定 DATABASE_URL" >&2
  exit 1
fi

step "確保後端相依套件已安裝"
cd "$ROOT/backend"
[ -d node_modules ] || npm install

step "確保前端相依套件已安裝"
cd "$ROOT/web"
[ -d node_modules ] || npm install

step "啟動後端 wrangler（port ${BACKEND_PORT}）"
cd "$ROOT/backend"
npx wrangler dev \
  --config "$ROOT/backend/wrangler.jsonc" \
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
echo "▶ 本機帳號：dev@example.com / dev（資料庫由 DATABASE_URL 指定）"
echo "按 Ctrl+C 停止"

wait "$BACKEND_PID" "$FRONTEND_PID"
