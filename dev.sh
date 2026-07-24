#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
DB="langmap"
REMOTE=0
[ "${1:-}" = "--remote" ] && REMOTE=1

trap 'echo "❌ $(basename "$0") 失敗：第 $LINENO 行" >&2' ERR
step() { echo "▶ $*" >&2; }

step "安裝後端依賴"
# npm --prefix "$ROOT/backend" install

step "建構 (build.sh)"
bash "$ROOT/build.sh" || echo "⚠ build.sh 已失敗，嘗試繼續"

step "停止殘留 wrangler"
pkill -f "wrangler dev" 2>/dev/null || true

# --remote 模式只連線遠端 D1，絕不對遠端跑 init/seed（init-db.sql 會 DROP 表）
if [ "$REMOTE" -eq 0 ]; then
  step "清除舊 D1 本地狀態"
  rm -rf "$ROOT/backend/.wrangler/state/v3/d1"

  step "初始化 D1 schema"
  cd "$ROOT/backend"
  npx wrangler d1 execute "$DB" --local --file=../scripts/init-db.sql

  step "從 SQL 同步語言資料"
  npx wrangler d1 execute "$DB" --local --file=../scripts/002_populate_languages.sql

  step "從 SQL 同步介面語系"
  npx wrangler d1 execute "$DB" --local --file=../scripts/028_migrate_ui_locales.sql

  step "確保本地 secret（.dev.vars）存在"
  if [ ! -f "$ROOT/backend/.dev.vars" ]; then
    echo "SECRET_KEY=\"$(openssl rand -hex 32)\"" > "$ROOT/backend/.dev.vars"
    echo "  已生成 backend/.dev.vars"
  else
    echo "  backend/.dev.vars 已存在，略過"
  fi
fi

step "啟動 wrangler dev（$([ "$REMOTE" -eq 1 ] && echo '遠端 D1' || echo '本地 D1')，按 Ctrl+C 停止）"
cd "$ROOT/backend"
if [ "$REMOTE" -eq 1 ]; then
  npx wrangler dev --remote || echo "⚠ wrangler dev 已停止，可重新執行 dev.sh"
else
  npx wrangler dev || echo "⚠ wrangler dev 已停止，可重新執行 dev.sh"
fi
