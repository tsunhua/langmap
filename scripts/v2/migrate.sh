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
#   sync-users 把 remote 或指定的本地旧 D1 用户表同步到 remote v2 D1
#   verify    核对目标 D1 行数
#   all       migrate → load → verify（不含 setup）
#   help      显示本说明
#
# --remote 标志作用在 setup/load/sync-users/verify/all 上。无 --remote 即 local。
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
V2_DB_NAME="${V2_DB_NAME:-langmap-v2}"
OLD_DB_NAME="${OLD_DB_NAME:-langmap}"

REMOTE=false
REPLACE_USERS=false
SOURCE_LOCAL=""
SYNC_USERS_TMP_DIR=""
EXPECT_SOURCE_LOCAL=false
for arg in "$@"; do
  if $EXPECT_SOURCE_LOCAL; then
    SOURCE_LOCAL="$arg"
    EXPECT_SOURCE_LOCAL=false
    continue
  fi
  case "$arg" in
    --remote) REMOTE=true ;;
    --replace-users) REPLACE_USERS=true ;;
    --source-local) EXPECT_SOURCE_LOCAL=true ;;
    --source-local=*) SOURCE_LOCAL="${arg#*=}" ;;
  esac
done
if $EXPECT_SOURCE_LOCAL || { [ -n "$SOURCE_LOCAL" ] && [ "$SOURCE_LOCAL" = "--remote" ]; }; then
  echo "✗ --source-local 必须指定 SQLite 文件路径" >&2
  exit 1
fi

trap 'echo "❌ 失敗：第 $LINENO 行" >&2' ERR
step() { echo "▶ $*" >&2; }
note() { echo "  $*" >&2; }
die() { echo "✗ $*" >&2; exit 1; }

cleanup() {
  if [ -n "$SYNC_USERS_TMP_DIR" ] && [ -d "$SYNC_USERS_TMP_DIR" ]; then
    rm -rf "$SYNC_USERS_TMP_DIR"
  fi
}
trap cleanup EXIT

wrangler() {
  (cd "$backend" && npx wrangler "$@")
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "缺少必要指令：$1"
}

require_remote() {
  $REMOTE || die "$1 仅用于 --remote"
}

remote_db_exists() {
  [ -n "$(remote_database_id "$1")" ]
}

remote_database_id() {
  local database="$1"
  wrangler d1 list --json | node -e '
    const database = process.argv[1];
    let input = "";
    process.stdin.on("data", chunk => input += chunk);
    process.stdin.on("end", () => {
      const payload = JSON.parse(input);
      const databases = Array.isArray(payload) ? payload : payload.result || [];
      const match = databases.find(item => item.name === database);
      if (match) process.stdout.write(match.uuid || match.id || "");
    });
  ' "$database"
}

remote_scalar() {
  local database="$1" query="$2"
  wrangler d1 execute "$database" --remote --json --command="$query" \
    | node -e '
      let input = "";
      process.stdin.on("data", chunk => input += chunk);
      process.stdin.on("end", () => {
        const payload = JSON.parse(input);
        const rows = payload.flatMap(result => result.results || []);
        const row = rows[0] || {};
        const value = Object.values(row)[0];
        if (value === undefined) process.exit(1);
        process.stdout.write(String(value));
      });
    '
}

update_database_id() {
  local id="$1"
  node - "$V2_CONFIG" "$id" <<'NODE'
const fs = require('node:fs');
const [path, id] = process.argv.slice(2);
const source = fs.readFileSync(path, 'utf8');
const pattern = /("binding"\s*:\s*"DB"[\s\S]*?"database_id"\s*:\s*")[^"]*(")/;
if (!pattern.test(source)) {
  console.error('找不到 binding=DB 的 database_id');
  process.exit(1);
}
fs.writeFileSync(path, source.replace(pattern, `$1${id}$2`));
NODE
}

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
  require_remote setup
  require_command node
  local id out
  id=$(remote_database_id "$V2_DB_NAME")
  if [ -n "$id" ]; then
    if grep -q '"database_id": *"REPLACE_AFTER_CREATE"' "$V2_CONFIG"; then
      step "接续未完成的 setup：找到 remote D1「${V2_DB_NAME}」"
      note "database_id = $id"
    else
      die "remote D1「${V2_DB_NAME}」已存在，且 config 已有 database_id；setup 不会覆盖既有数据库"
    fi
  else
    step "建立 remote v2 D1（${V2_DB_NAME}）"
    out=$(wrangler d1 create "$V2_DB_NAME" 2>&1)
    echo "$out"
    id=$(echo "$out" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
    [ -n "$id" ] || die "抓不到 database_id（D1 可能已存在或未登录）"
  fi
  step "回填 database_id 到 wrangler.jsonc"
  update_database_id "$id"
  note "已写入 database_id = $id"
  step "remote 跑 schema.sql"
  wrangler d1 execute "$V2_DB_NAME" --remote --file=./schema.sql
  step "确认 remote schema"
  local table_count
  table_count=$(remote_scalar "$V2_DB_NAME" \
    "SELECT COUNT(*) FROM sqlite_schema WHERE type = 'table' AND name IN ('users', 'expressions', 'expression_edges', 'languoids', 'ui_locales', 'ui_messages');")
  [ "$table_count" = "6" ] || die "schema 验证失败：预期 6 个关键表，实际 ${table_count}"
  note "setup 完成；只同步用户资料请跑：./migrate.sh sync-users --remote"
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
  remote_db_exists "$V2_DB_NAME" || die "找不到 remote D1「${V2_DB_NAME}」；先跑 setup --remote"
  step "remote 载入：先 drop FTS triggers（载入前）"
  wrangler d1 execute "$V2_DB_NAME" --remote \
    --command="DROP TRIGGER IF EXISTS expressions_ai; DROP TRIGGER IF EXISTS expressions_ad; DROP TRIGGER IF EXISTS expressions_au; DROP TABLE IF EXISTS expressions_fts;"
  step "remote 载入：清空目标表（schema 已由 setup 建好，这里只清数据以保幂等）"
  wrangler d1 execute "$V2_DB_NAME" --remote \
    --command="DELETE FROM handbook_section_items; DELETE FROM handbook_sections; DELETE FROM handbooks; DELETE FROM votes; DELETE FROM ui_messages; DELETE FROM ui_locales; DELETE FROM expression_edges; DELETE FROM expression_versions; DELETE FROM expressions; DELETE FROM email_verification_tokens; DELETE FROM users; DELETE FROM language_stats; DELETE FROM languages; DELETE FROM languoids;"
  step "remote 载入：分批载入 v2-data.sql（每批 ${REMOTE_BATCH} 行；遇 SQLITE_TOOBIG 请减小 REMOTE_BATCH）"
  remote_batch_load "${V2_DATA}"
  step "remote 载入：重建 FTS + reindex"
  wrangler d1 execute "$V2_DB_NAME" --remote \
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
      wrangler d1 execute "$V2_DB_NAME" --remote --file="$tmp" >/dev/null \
        || { echo ""; echo "✗ 批次载入失败（第 ${done} 条附近，临时文件 ${tmp}）"; exit 1; }
      : > "$tmp"; done=$((done + in_batch)); in_batch=0
      printf '\r  已载入 %s / %s' "$done" "$total" >&2
    fi
  done < "$file"
  if [ "$in_batch" -gt 0 ]; then
    wrangler d1 execute "$V2_DB_NAME" --remote --file="$tmp" >/dev/null \
      || { echo ""; echo "✗ 批次载入失败（末批，临时文件 ${tmp}）"; exit 1; }
    done=$((done + in_batch))
  fi
  rm -f "$tmp"
  printf '\r  已载入 %s / %s\n' "$done" "$total" >&2
}

# ---------------------------------------------------------------- sync-users
cmd_sync_users() {
  require_remote sync-users
  require_command node
  remote_db_exists "$V2_DB_NAME" || die "找不到目标 remote D1「${V2_DB_NAME}」；先跑 setup --remote"

  local source_users target_users source_tokens target_tokens
  target_users=$(remote_scalar "$V2_DB_NAME" "SELECT COUNT(*) FROM users;")
  target_tokens=$(remote_scalar "$V2_DB_NAME" "SELECT COUNT(*) FROM email_verification_tokens;")

  if [ -n "$SOURCE_LOCAL" ]; then
    require_command sqlite3
    [ -f "$SOURCE_LOCAL" ] || die "找不到本地 SQLite：$SOURCE_LOCAL"
    local source_table_count
    source_table_count=$(sqlite3 -readonly "$SOURCE_LOCAL" \
      "SELECT COUNT(*) FROM sqlite_schema WHERE type = 'table' AND name IN ('users', 'email_verification_tokens');")
    [ "$source_table_count" = "2" ] || die "本地 SQLite 缺少 users 或 email_verification_tokens"
    source_users=$(sqlite3 -readonly "$SOURCE_LOCAL" "SELECT COUNT(*) FROM users;")
    source_tokens=$(sqlite3 -readonly "$SOURCE_LOCAL" "SELECT COUNT(*) FROM email_verification_tokens;")
    note "来源：本地 SQLite $SOURCE_LOCAL"
  else
    remote_db_exists "$OLD_DB_NAME" || die "找不到来源 remote D1「${OLD_DB_NAME}」"
    [ "$OLD_DB_NAME" != "$V2_DB_NAME" ] || die "来源与目标数据库名称相同，拒绝同步"
    source_users=$(remote_scalar "$OLD_DB_NAME" "SELECT COUNT(*) FROM users;")
    source_tokens=$(remote_scalar "$OLD_DB_NAME" "SELECT COUNT(*) FROM email_verification_tokens;")
    note "来源：remote D1 ${OLD_DB_NAME}"
  fi

  note "users：来源 ${source_users}，目标 ${target_users}"
  note "email_verification_tokens：来源 ${source_tokens}，目标 ${target_tokens}"
  if [ "$target_users" != "0" ] || [ "$target_tokens" != "0" ]; then
    $REPLACE_USERS || die "目标已有用户资料；确认要替换时加 --replace-users"
    step "清空目标用户资料（先 token，后 user）"
    wrangler d1 execute "$V2_DB_NAME" --remote \
      --command="DELETE FROM email_verification_tokens; DELETE FROM users;"
  fi

  local users_sql tokens_sql
  SYNC_USERS_TMP_DIR=$(mktemp -d -t lm_v2_users.XXXXXX)
  users_sql="$SYNC_USERS_TMP_DIR/users.sql"
  tokens_sql="$SYNC_USERS_TMP_DIR/email_verification_tokens.sql"

  if [ -n "$SOURCE_LOCAL" ]; then
    step "从本地 v1 SQLite 导出用户相关表"
    sqlite3 -readonly "$SOURCE_LOCAL" ".mode insert users" \
      "SELECT * FROM users ORDER BY id;" > "$users_sql"
    sqlite3 -readonly "$SOURCE_LOCAL" ".mode insert email_verification_tokens" \
      "SELECT * FROM email_verification_tokens ORDER BY token;" > "$tokens_sql"
  else
    step "从「${OLD_DB_NAME}」导出用户相关表"
    wrangler d1 export "$OLD_DB_NAME" --remote --table=users --no-schema --output="$users_sql"
    wrangler d1 export "$OLD_DB_NAME" --remote --table=email_verification_tokens --no-schema --output="$tokens_sql"
  fi

  step "载入「${V2_DB_NAME}」（先 user，后 token）"
  wrangler d1 execute "$V2_DB_NAME" --remote --file="$users_sql"
  if [ "$source_tokens" != "0" ]; then
    wrangler d1 execute "$V2_DB_NAME" --remote --file="$tokens_sql"
  fi

  target_users=$(remote_scalar "$V2_DB_NAME" "SELECT COUNT(*) FROM users;")
  target_tokens=$(remote_scalar "$V2_DB_NAME" "SELECT COUNT(*) FROM email_verification_tokens;")
  [ "$target_users" = "$source_users" ] || die "users 数量不一致：来源 ${source_users}，目标 ${target_users}"
  [ "$target_tokens" = "$source_tokens" ] || die "email_verification_tokens 数量不一致：来源 ${source_tokens}，目标 ${target_tokens}"
  note "用户资料同步完成并通过数量核对"
}

# ---------------------------------------------------------------- verify
cmd_verify() {
  local q="SELECT 'users', count(*) FROM users UNION ALL SELECT 'email_verification_tokens', count(*) FROM email_verification_tokens UNION ALL SELECT 'languages', count(*) FROM languages UNION ALL SELECT 'languoids', count(*) FROM languoids UNION ALL SELECT 'expressions', count(*) FROM expressions UNION ALL SELECT 'expression_edges', count(*) FROM expression_edges UNION ALL SELECT 'handbook_section_items', count(*) FROM handbook_section_items UNION ALL SELECT 'handbooks', count(*) FROM handbooks UNION ALL SELECT 'handbook_sections', count(*) FROM handbook_sections UNION ALL SELECT 'ui_locales', count(*) FROM ui_locales UNION ALL SELECT 'ui_messages', count(*) FROM ui_messages;"
  if $REMOTE; then
    step "核对 remote v2 D1 行数"
    remote_db_exists "$V2_DB_NAME" || die "找不到 remote D1「${V2_DB_NAME}」"
    wrangler d1 execute "$V2_DB_NAME" --remote --command="$q"
    step "检查 foreign key"
    wrangler d1 execute "$V2_DB_NAME" --remote --command="PRAGMA foreign_key_check;"
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
  sync-users) cmd_sync_users ;;
  verify)  cmd_verify ;;
  all)     cmd_all ;;
  help|--help|-h)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    echo ""
    echo "环境变量:"
    echo "  OLD_DB_NAME   remote 来源 D1（默认 langmap）"
    echo "  V2_DB_NAME    v2 目标 D1（默认 langmap-v2）"
    echo "  REMOTE_BATCH  remote 分批每批行数（默认 100）"
    echo ""
    echo "选项:"
    echo "  --replace-users  sync-users 时允许替换目标库既有用户资料"
    echo "  --source-local PATH"
    echo "                   sync-users 从指定的本地 v1 SQLite 读取资料"
    ;;
  *) echo "未知子命令: ${SUB}（用 help 查看）"; exit 1 ;;
esac
