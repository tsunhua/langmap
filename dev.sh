#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
PORT=""
LOCAL_D1_STATE="$ROOT/backend/.wrangler/state"

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
TABLE_COUNT=$(npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" --command="SELECT count(*) as c FROM sqlite_master WHERE type='table';" 2>/dev/null | grep -oE '"c": [0-9]+' | grep -oE '[0-9]+')
if [ "${TABLE_COUNT:-0}" -eq 0 ]; then
  echo "  本地 D1 無表，套用 schema.sql"
  npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" --file=./schema.sql
  echo "  載入 pinned language-registry.sql"
  npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" \
    --file="$ROOT/scripts/v2/artifacts/language-registry-5.3/language-registry.sql"
else
  echo "  本地 D1 已有 ${TABLE_COUNT} 張表，套用增量遷移"
  npx wrangler d1 migrations apply langmap-v2 --local --persist-to "$LOCAL_D1_STATE" || true
  echo "  確保 language_subtags 表存在（幂等）"
  npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" \
    --command="CREATE TABLE IF NOT EXISTS language_subtags (
      type TEXT NOT NULL,
      value TEXT NOT NULL,
      descriptions TEXT NOT NULL DEFAULT '[]',
      prefixes TEXT NOT NULL DEFAULT '[]',
      preferred_value TEXT,
      suppress_script TEXT,
      deprecated TEXT,
      PRIMARY KEY (type, value)
    );"
  echo "  檢查 languages 表是否需要重建（老 schema 缺少欄位）"
  HAS_DESC=$(npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" \
    --command="SELECT COUNT(*) as c FROM pragma_table_info('languages') WHERE name='description';" 2>/dev/null | grep -oE '"c": [0-9]+' | grep -oE '[0-9]+')
  if [ "${HAS_DESC:-0}" -eq 0 ]; then
    echo "  languages 表是舊 schema，重建為新版⋯"
    npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" \
      --command="DROP TABLE IF EXISTS languages_v2;
      CREATE TABLE languages_v2 (
        code TEXT UNIQUE NOT NULL, name TEXT NOT NULL, name_en TEXT,
        description TEXT, direction TEXT DEFAULT 'ltr',
        base_language TEXT, script_code TEXT, region_code TEXT,
        variants_json TEXT, private_use_json TEXT,
        variety_key TEXT NOT NULL DEFAULT 'migration', glottocode TEXT,
        origin TEXT NOT NULL DEFAULT 'seed', community_reason TEXT,
        alternate_names_json TEXT, references_json TEXT,
        parent_languoid_id TEXT, latitude REAL, longitude REAL,
        created_by TEXT, created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_by TEXT, updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      INSERT OR IGNORE INTO languages_v2
        (code, name, name_en, direction, base_language, script_code,
         region_code, created_by, created_at, updated_by, updated_at)
      SELECT code, name, name_en, direction, base_language, script_code,
             region_code, created_by, created_at, updated_by, updated_at
      FROM languages;
      DROP TABLE languages;
      ALTER TABLE languages_v2 RENAME TO languages;
      CREATE INDEX IF NOT EXISTS idx_languages_name ON languages(name);
      CREATE INDEX IF NOT EXISTS idx_languages_variety_key ON languages(variety_key);
      CREATE INDEX IF NOT EXISTS idx_languages_glottocode ON languages(glottocode);
      CREATE INDEX IF NOT EXISTS idx_languages_base_script_region
        ON languages(base_language, script_code, region_code);"
  else
    echo "  languages 表 schema 已是最新版，跳過重建"
  fi
  echo "  載入 pinned language-registry.sql（幂等）"
  npx wrangler d1 execute langmap-v2 --local --persist-to "$LOCAL_D1_STATE" \
    --file="$ROOT/scripts/v2/artifacts/language-registry-5.3/language-registry.sql"
fi

step "啟動後端 wrangler（port ${PORT:-8788}）"
cd "$ROOT/backend"
npx wrangler dev --persist-to "$LOCAL_D1_STATE" --port "${PORT:-8788}" &
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
