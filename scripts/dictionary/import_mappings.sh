#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
用法：scripts/dictionary/import_mappings.sh CSV_PATH [選項]

選項：
  --remote              寫入遠端 D1；預設為本地 D1
  --max-rows N          只處理前 N 列
  --offset N            跳過前 N 列
  --chunk-size N        每個 SQL 檔最多 N 條 statement（預設 1000）
  --output-dir PATH     SQL 輸出目錄
  --email EMAIL         created_by 使用的 email（預設 dev@example.com）
EOF
}

if [[ $# -eq 1 && "$1" == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 ]]; then usage >&2; exit 2; fi
csv_path=$1; shift
remote_flag="--local"
max_rows=""
offset="0"
chunk_size="1000"
email="dev@example.com"
timestamp=$(date +%Y%m%d-%H%M%S)
output_dir="/tmp/langmap-import-${timestamp}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) remote_flag="--remote"; shift ;;
    --max-rows) max_rows=$2; shift 2 ;;
    --offset) offset=$2; shift 2 ;;
    --chunk-size) chunk_size=$2; shift 2 ;;
    --output-dir) output_dir=$2; shift 2 ;;
    --email) email=$2; shift 2 ;;
    --help) usage; exit 0 ;;
    *) echo "未知選項：$1" >&2; usage >&2; exit 2 ;;
  esac
done

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
backend_dir="${repo_root}/backend"
mkdir -p "$output_dir"

generator_args=(
  "$repo_root/scripts/dictionary/import_mappings.py" "$csv_path"
  --email "$email" --offset "$offset"
  --sql-output "$output_dir/import.sql" --sql-chunk-size "$chunk_size"
)
if [[ -n "$max_rows" ]]; then generator_args+=(--max-rows "$max_rows"); fi

echo "[1/2] 產生 SQL：${output_dir}"
python3 "${generator_args[@]}"

sql_files=()
while IFS= read -r file; do sql_files+=("$file"); done < <(find "$output_dir" -maxdepth 1 -type f -name 'import-*.sql' | sort)
if [[ ${#sql_files[@]} -eq 0 ]]; then
  echo "找不到 SQL 分片檔案：${output_dir}" >&2
  exit 1
fi

echo "[2/2] 匯入 D1：${#sql_files[@]} 個檔案（${remote_flag#--}）"
for index in "${!sql_files[@]}"; do
  file=${sql_files[$index]}
  current=$((index + 1))
  echo "executing ${current}/${#sql_files[@]}: ${file}"
  (cd "$backend_dir" && npx wrangler d1 execute langmap-v2 "$remote_flag" --file="$file")
done

echo "完成：${#sql_files[@]}/${#sql_files[@]} 個 SQL 檔案"
echo "輸出目錄：${output_dir}"
