#!/usr/bin/env bash
# LangMap v1 → v2 数据迁移工具
#
# 用法:
#   ./migrate.sh <子命令> [--remote]
#
# 子命令:
#   setup     建立 remote v2 D1 + 回填 wrangler.jsonc 的 database_id（仅 remote）
#   migrate   跑 migrate.ts，旧 D1 → v2-data.sql
#   load      把 v2-data.sql 载入目标 D1（local 用 sqlite3 直载；remote 分批 wrangler）
#   verify    核对目标 D1 行数
#   all       migrate → load → verify（不含 setup）
#   help      显示本说明
#
# --remote 标志作用在 setup/load/verify/all 上。无 --remote 即 local。
#
# 前置假设:
#   - 旧 D1（backend）本地 sqlite 已载好 remote-*.sql（见 README Step 1）
#   - scripts/v2 依赖已装（node_modules 有 better-sqlite3/tsx）
#   - remote 模式需 `wrangler login` 且有 Cloudflare 账号权限
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND="$ROOT/backend"
backend="$ROOT/backend"
V2_DATA="$SCRIPT_DIR/v2-data.sql"
SCHEMA="$backend/schema.sql"
V2_CONFIG="$backend/wrangler.jsonc"
V2_DB_NAME="langmap-v2"
OLD_DB_NAME="langmap"

REMOTE=false
for arg in "$@"; do case "$arg" in --remote) REMOTE=true ;; esac; done

trap 'echo "❌ 失敗：第 $LINENO 行" >&2' ERR
step() { echo "▶ $*" >&2; }
note() { echo "  $*" >&2; }

# 找旧 D1 sqlite 文件（hash 命名，排除 metadata/cache）
find_old_sqlite() {
  find "$BACKEND/.wrangler/state/v3/d1/miniflare-D1DatabaseObject" \
    -maxdepth 1 -name '*.sqlite' ! -name 'metadata.sqlite' 2>/dev/null | head -1
}

# 找 v2 D1 sqlite 文件（hash 命名，排除 metadata）
find_v2_sqlite() {
  find "$backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject" \
    -maxdepth 1 -name '*.sqlite' ! -name 'metadata.sqlite' 2>/dev/null | head -1
}

# 在 v2 D1 上 drop FTS triggers + FTS 表（载入前）
drop_fts() {
  local db="$1"
  sqlite3 "$db" "DROP TRIGGER IF EXISTS expressions_ai; DROP TRIGGER IF EXISTS expressions_ad; DROP TRIGGER IF EXISTS expressions_au; DROP TABLE IF EXISTS expressions_fts;"
}

# 在 v2 D1 上重建 FTS triggers + 重建索引（载入后）
rebuild_fts() {
  local db="$1"
  sqlite3 "$db" "CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(text, content='expressions', content_rowid='id', tokenize='unicode61');
    CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
    CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); END;
    CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
    INSERT INTO expressions_fts(rowid, text) SELECT id, text FROM expressions;"
}

# ---------------------------------------------------------------- setup
cmd_setup() {
  if ! $REMOTE; then echo "✗ setup 仅用于 --remote"; exit 1; fi
  step "建立 remote v2 D1（$V2_DB_NAME）"
  local out; out=$(cd "$backend" && npx wrangler d1 create "$V2_DB_NAME" 2>&1)
  echo "$out"
  local id; id=$(echo "$out" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
  if [ -z "$id" ]; then echo "✗ 抓不到 database_id（D1 可能已存在或未登录）"; exit 1; fi
  step "回填 database_id 到 wrangler.jsonc"
  # 替换 REPLACE_AFTER_CREATE（或旧 id）为真实 id
  if grep -q 'REPLACE_AFTER_CREATE' "$V2_CONFIG"; then
    sed -i.bak 's/REPLACE_AFTER_CREATE/'"$id"'/' "$V2_CONFIG" && rm -f "$V2_CONFIG.bak"
  else
    sed -i.bak -E 's/"database_id": *"[^"]*"/"database_id": "'"${id}"'"/' "$V2_CONFIG" && rm -f "$V2_CONFIG.bak"
  fi
  note "已写入 database_id = $id"
  step "remote 跑 schema.sql"
  cd "$backend" && npx wrangler d1 execute "$V2_DB_NAME" --remote --file=./schema.sql
  note "setup 完成，接下来可跑：./migrate.sh all --remote"
}

# ---------------------------------------------------------------- migrate
cmd_migrate() {
  step "定位旧 D1 sqlite"
  local old; old=$(find_old_sqlite)
  if [ -z "$old" ]; then echo "✗ 找不到旧 D1 sqlite（先按 README Step 1 载入 remote-*.sql）"; exit 1; fi
  note "旧 D1: $old"
  step "跑 migrate.ts"
  cd "$SCRIPT_DIR"
  [ -d node_modules ] || npm install
  npx tsx migrate.ts "$old" "${V2_DATA}"
  note "输出: ${V2_DATA}"
}

# ---------------------------------------------------------------- load
cmd_load() {
  if [ ! -f "${V2_DATA}" ]; then echo "✗ 没有 ${V2_DATA}（先跑 migrate）"; exit 1; fi
  if $REMOTE; then load_remote; else load_local; fi
}

load_local() {
  step "定位 v2 D1 sqlite（local）"
  local db; db=$(find_v2_sqlite)
  if [ -z "$db" ]; then
    echo "✗ 找不到 v2 D1 sqlite（先在 backend 跑一次 `npx wrangler dev` 初始化本地 D1）"; exit 1
  fi
  note "v2 D1: $db"
  step "重跑 schema.sql（清空+重建）"
  sqlite3 "$db" < "$SCHEMA"
  step "drop FTS triggers"
  drop_fts "$db"
  step "载入 v2-data.sql（sqlite3 直载，绕过 SQLITE_TOOBIG）"
  sqlite3 "$db" < "${V2_DATA}"
  step "重建 FTS + reindex"
  rebuild_fts "$db"
  note "local 载入完成"
}

load_remote() {
  step "remote 载入：先 drop FTS triggers（载入前）"
  cd "$backend"
  npx wrangler d1 execute "$V2_DB_NAME" --remote \
    --command="DROP TRIGGER IF EXISTS expressions_ai; DROP TRIGGER IF EXISTS expressions_ad; DROP TRIGGER IF EXISTS expressions_au; DROP TABLE IF EXISTS expressions_fts;"
  step "remote 载入：清空目标表（schema 已由 setup 建好，这里只清数据以保幂等）"
  npx wrangler d1 execute "$V2_DB_NAME" --remote \
    --command="DELETE FROM handbook_section_items; DELETE FROM handbook_sections; DELETE FROM handbooks; DELETE FROM expression_edges; DELETE FROM expressions; DELETE FROM expression_versions; DELETE FROM votes; DELETE FROM language_stats; DELETE FROM ui_locales; DELETE FROM users; DELETE FROM languages; DELETE FROM email_verification_tokens;"
  step "remote 载入：分批载入 v2-data.sql（每批 ${REMOTE_BATCH} 行；遇 SQLITE_TOOBIG 请减小 REMOTE_BATCH）"
  remote_batch_load "${V2_DATA}"
  step "remote 载入：重建 FTS + reindex"
  npx wrangler d1 execute "$V2_DB_NAME" --remote \
    --command="CREATE VIRTUAL TABLE IF NOT EXISTS expressions_fts USING fts5(text, content='expressions', content_rowid='id', tokenize='unicode61');
    CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
    CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); END;
    CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text); INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text); END;
    INSERT INTO expressions_fts(rowid, text) SELECT id, text FROM expressions;"
  note "remote 载入完成"
}

REMOTE_BATCH="${REMOTE_BATCH:-100}"

# 把 v2-data.sql 按行分批，用 wrangler d1 execute --remote --file 载入
# 每批 N 条 INSERT（每行一条，以 ; 结尾）写入临时文件再 --file 载入。
# 用 --file 而非 --command：内容含双引号 / $ （audio_url JSON），--command 经 shell 会破坏。
remote_batch_load() {
  local file="$1"
  local total; total=$(grep -c '^INSERT' "$file")
  local batch="${REMOTE_BATCH}"
  local done=0 in_batch=0
  local tmp; tmp=$(mktemp -t lm_v2_batch.XXXXXX.sql)
  trap 'rm -f "$tmp"' RETURN
  while IFS= read -r line; do
    case "$line" in INSERT*) ;;
      *) continue ;;  # 跳过注释/空行
    esac
    printf '%s\n' "$line" >> "$tmp"
    in_batch=$((in_batch + 1))
    if [ "$in_batch" -ge "$batch" ]; then
      npx wrangler d1 execute "$V2_DB_NAME" --remote --file="$tmp" >/dev/null 2>&1 \
        || { echo ""; echo "✗ 批次载入失败（第 $done 条附近，临时文件 $tmp）"; exit 1; }
      : > "$tmp"; done=$((done + in_batch)); in_batch=0
      printf '\r  已载入 %s / %s' "$done" "$total" >&2
    fi
  done < "$file"
  if [ "$in_batch" -gt 0 ]; then
    npx wrangler d1 execute "$V2_DB_NAME" --remote --file="$tmp" >/dev/null 2>&1 \
      || { echo ""; echo "✗ 批次载入失败（末批，临时文件 $tmp）"; exit 1; }
    done=$((done + in_batch))
  fi
  rm -f "$tmp"
  printf '\r  已载入 %s / %s\n' "$done" "$total" >&2
}

# ---------------------------------------------------------------- verify
cmd_verify() {
  local q="SELECT 'expressions', count(*) FROM expressions UNION ALL SELECT 'expression_edges', count(*) FROM expression_edges UNION ALL SELECT 'handbook_section_items', count(*) FROM handbook_section_items UNION ALL SELECT 'handbooks', count(*) FROM handbooks UNION ALL SELECT 'handbook_sections', count(*) FROM handbook_sections;"
  if $REMOTE; then
    step "核对 remote v2 D1 行数"
    cd "$backend" && npx wrangler d1 execute "$V2_DB_NAME" --remote --command="$q"
  else
    step "核对 local v2 D1 行数"
    local db; db=$(find_v2_sqlite)
    if [ -z "$db" ]; then echo "✗ 找不到 v2 D1 sqlite"; exit 1; fi
    sqlite3 "$db" "$q" | sed 's/|/ → /'
    note "预期: expressions=91625, expression_edges=112860, handbook_section_items=1767, handbooks=4, handbook_sections=65"
  fi
}

# ---------------------------------------------------------------- all
cmd_all() {
  cmd_migrate
  cmd_load
  cmd_verify
}

# ---------------------------------------------------------------- dispatch
SUB="${1:-help}"
case "$SUB" in
  setup)   cmd_setup ;;
  migrate) cmd_migrate ;;
  load)    cmd_load ;;
  verify)  cmd_verify ;;
  all)     cmd_all ;;
  help|--help|-h)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    echo ""
    echo "环境变量:"
    echo "  REMOTE_BATCH  remote 分批每批行数（默认 100）"
    ;;
  *) echo "未知子命令: ${SUB}（用 help 查看）"; exit 1 ;;
esac
