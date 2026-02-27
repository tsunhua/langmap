#!/usr/bin/env python3
"""
批量新增词句脚本
从 CSV 读取词句，每一行调用一次批量新增 API

CSV 格式要求：
- 表头：语言代码（如 zh-CN, en-US, fr-FR）
- 每一行：不同语言的词句，该行调用一次 batch API
- 关联规则：同一行的词句会被关联到同一个语义锚点
- 注意：表头中非语言代码格式的列会被自动忽略（如中文列名、数字列名等）

使用方法：
    python scripts/025_batch_add_expressions.py expressions.csv -t YOUR_API_TOKEN
"""

import argparse
import csv
import json
import re
import requests
import sys
from pathlib import Path
from typing import List, Dict, Optional

# API 配置
DEFAULT_API_URL = "http://localhost:8787/api/v1/expressions/batch"
BATCH_SIZE = 1  # 每行就是一个 batch


def is_valid_language_code(lang_code: str) -> bool:
    """
    检查是否为有效的语言代码格式

    Args:
        lang_code: 待检查的语言代码

    Returns:
        是否为有效的语言代码
    """
    if not lang_code:
        return False

    # 语言代码通常格式为: xx-YY (如 zh-CN, en-US, ja-JP)
    # 至少包含英文字母和连字符
    pattern = r"^[a-zA-Z]{2,3}(-[a-zA-Z]{2,4})?$"
    return bool(re.match(pattern, lang_code.strip()))


def read_csv_to_expressions(csv_file: Path) -> List[Dict]:
    """
    从 CSV 读取词句数据

    Args:
        csv_file: CSV 文件路径

    Returns:
        词句列表，每个元素是一行数据的语言到文本的映射
    """
    expressions_data = []

    try:
        with open(csv_file, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames or []

            print(f"📋 读取 CSV 文件: {csv_file}")
            print(f"   表头字段（语言代码）: {fieldnames}")
            print(f"   共 {len(fieldnames)} 个列\n")

            for row_num, row in enumerate(reader, 1):
                # 跳过空行
                if not any(row.values()):
                    print(f"⚠️  跳过空行 {row_num}")
                    continue

                expressions_data.append({"row_num": row_num, "row_data": row})

            print(f"✅ 成功读取 {len(expressions_data)} 行数据\n")

            return expressions_data

    except FileNotFoundError:
        print(f"❌ 错误：文件不存在 - {csv_file}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 读取 CSV 文件时出错: {e}")
        sys.exit(1)


def convert_to_batch_format(expressions_data: List[Dict]) -> List[List[Dict]]:
    """
    将 CSV 数据转换为 API 批量提交格式
    每一行作为一个 batch，调用一次 API

    Args:
        expressions_data: 从 CSV 读取的行数据

    Returns:
        批次列表，每批包含该行的多个词句对象
    """
    batches = []
    ignored_columns = set()

    for item in expressions_data:
        row_num = item["row_num"]
        row_data = item["row_data"]

        # 将每一行转换为多个词句对象（该行作为一个 batch）
        expressions = []
        for lang_code, text in row_data.items():
            # 跳过非语言代码格式的列
            if not is_valid_language_code(lang_code):
                if lang_code not in ignored_columns:
                    ignored_columns.add(lang_code)
                    print(f"⚠️  忽略非语言代码列: '{lang_code}'")
                continue

            # 跳过空文本
            if not text or not text.strip():
                continue

            expressions.append(
                {
                    "language_code": lang_code,
                    "text": text.strip(),
                    "source_type": "csv_import_26022718",
                }
            )

        if expressions:
            batches.append(expressions)

    if ignored_columns:
        print(
            f"\n⚠️  共忽略 {len(ignored_columns)} 个非语言代码列: {sorted(ignored_columns)}"
        )

    print(f"🔄 转换为 {len(batches)} 个批次（每行一个批次）\n")

    return batches


def submit_batch(
    api_url: str, token: str, batch: List[Dict], batch_num: int, row_num: int
) -> Optional[Dict]:
    """
    提交一批词句到 API（一行作为一个批次）

    Args:
        api_url: API 端点 URL
        token: 认证 token
        batch: 词句列表
        batch_num: 批次编号
        row_num: CSV 行号

    Returns:
        API 响应或 None（失败时）
    """
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    payload = {"expressions": batch}

    try:
        print(f"📤 提交第 {row_num} 行（{len(batch)} 个词句）到 API...")
        response = requests.post(api_url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        result = response.json()
        print(f"✅ 第 {row_num} 行提交成功")
        print(f"   语义锚点 (meaning_id): {result.get('meaning_id', 'N/A')}")
        print(f"   更新结果数: {len(result.get('results', []))}\n")

        return result

    except requests.exceptions.RequestException as e:
        print(f"❌ 第 {row_num} 行提交失败: {e}")
        if hasattr(e, "response") and e.response is not None:
            try:
                error_data = e.response.json()
                print(
                    f"   错误详情: {json.dumps(error_data, indent=2, ensure_ascii=False)}"
                )
            except:
                print(f"   状态码: {e.response.status_code}")
        return None


def process_batches(api_url: str, token: str, batches: List[List[Dict]]):
    """
    处理所有批次（每行一个批次）

    Args:
        api_url: API 端点 URL
        token: 认证 token
        batches: 所有批次数据
    """
    total_batches = len(batches)
    success_count = 0
    failure_count = 0

    print(f"\n🚀 开始批量提交，共 {total_batches} 个批次（每行一个批次）\n")
    print("=" * 50)

    for batch_num, batch in enumerate(batches):
        row_num = batch_num + 1  # 批次号等于 CSV 行号
        result = submit_batch(api_url, token, batch, batch_num, row_num)

        if result:
            success_count += 1
        else:
            failure_count += 1

        # 添加批次之间的延迟，避免过载
        if batch_num < total_batches - 1:
            import time

            time.sleep(0.5)

    print("=" * 50)
    print(f"\n📊 提交完成:")
    print(f"   总行数: {total_batches}")
    print(f"   成功: {success_count}")
    print(f"   失败: {failure_count}")
    print(f"   成功率: {success_count / total_batches * 100:.1f}%\n")


def main():
    parser = argparse.ArgumentParser(
        description="批量新增词句到 LangMap（每行调用一次 batch API）",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 从 CSV 文件提交（使用默认 API URL）
  python scripts/025_batch_add_expressions.py expressions.csv -t YOUR_TOKEN

  # 指定自定义 API URL
  python scripts/025_batch_add_expressions.py expressions.csv -t YOUR_TOKEN -u https://api.langmap.io/api/v1/expressions/batch

示例 CSV 内容（expressions.csv）:
  zh-CN,en-US,ja-JP,ko-KR,fr-FR,es-ES
  你好,Hello,こんにちは,안녕하세요,Bonjour,Hola
  谢谢,Thank you,ありがとう,감사합니다,Merci,Gracias

说明：
  - CSV 每一行代表一组多语言词句（如"你好"的各种翻译）
  - 每一行调用一次 batch API，自动关联到同一语义锚点
  - 空单元格会被自动跳过
  - 表头中非语言代码格式的列会被自动忽略（如"中文"列名、数字列名等）
  - 语言代码格式通常为: xx-YY (如 zh-CN, en-US, ja-JP)
        """,
    )

    parser.add_argument(
        "csv_file", type=Path, help="CSV 文件路径（表头为语言代码，每行为多个语言词句）"
    )

    parser.add_argument("-t", "--token", required=True, help="API 认证 Token")

    parser.add_argument(
        "-u",
        "--api-url",
        default=DEFAULT_API_URL,
        help=f"API 端点 URL（默认: {DEFAULT_API_URL}）",
    )

    parser.add_argument(
        "-b",
        "--batch-size",
        type=int,
        default=BATCH_SIZE,
        help=f"每批次提交的行数（默认: {BATCH_SIZE}，已调整为每行一个批次）",
    )

    parser.add_argument(
        "--dry-run", action="store_true", help="只显示将要提交的数据，不实际调用 API"
    )

    parser.add_argument(
        "--output", type=Path, help="将转换后的 JSON 数据保存到文件（用于调试）"
    )

    args = parser.parse_args()

    # 检查 CSV 文件是否存在
    if not args.csv_file.exists():
        print(f"❌ 错误：CSV 文件不存在 - {args.csv_file}")
        sys.exit(1)

    if not args.csv_file.suffix.lower() == ".csv":
        print(f"⚠️  警告：文件扩展名不是 .csv - {args.csv_file}")

    # 读取 CSV
    expressions_data = read_csv_to_expressions(args.csv_file)

    if not expressions_data:
        print("❌ 错误：CSV 文件为空或无有效数据")
        sys.exit(1)

    # 转换为 API 格式
    batches = convert_to_batch_format(expressions_data)

    # 如果指定了输出文件，保存 JSON
    if args.output:
        output_data = {
            "total_batches": len(batches),
            "total_rows": len(expressions_data),
            "batches": batches,
        }
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        print(f"💾 已保存转换后的数据到: {args.output}\n")

    # 显示预览（前 2 行）
    if not args.dry_run:
        print("📝 数据预览（前 2 批次）:\n")
        for i, batch in enumerate(batches[:2]):
            print(f"第 {i + 1} 行 ({len(batch)} 个词句）:")
            for expr in batch:
                region = f" ({expr['region_code']})" if expr.get("region_code") else ""
                print(f"  - [{expr['language_code']}{region}] {expr['text']}")
        print()

    # Dry run 模式
    if args.dry_run:
        print("🔍 Dry run 模式：未实际调用 API\n")
        print("如需实际提交，请移除 --dry-run 参数")
        return

    # 确认提交
    print(f"📋 准备提交:")
    print(f"   CSV 文件: {args.csv_file}")
    print(f"   总行数: {len(batches)}")
    print(f"   API URL: {args.api_url}")

    confirm = input("\n⚠️  确认要提交吗？(y/n): ").strip().lower()
    if confirm not in ["y", "yes"]:
        print("❌ 已取消提交")
        sys.exit(0)

    # 执行批量提交
    process_batches(args.api_url, args.token, batches)

    print("\n✅ 全部完成！")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  用户中断操作")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ 未预期的错误: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
