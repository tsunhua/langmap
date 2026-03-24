#!/usr/bin/env python3
import os
import glob
from zhconv import convert


def convert_to_traditional(text):
    """將簡體中文轉換爲繁體中文"""
    return convert(text, "zh-hant")


def process_file(filepath):
    """處理單個文件：讀取、轉換、寫回"""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # 轉換爲繁體中文
        traditional_content = convert_to_traditional(content)

        # 寫回文件
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(traditional_content)

        print(f"✓ 轉換成功: {filepath}")
        return True
    except Exception as e:
        print(f"✗ 轉換失敗 {filepath}: {e}")
        return False


def main():
    docs_dir = os.path.join(os.path.dirname(__file__), "..", "docs")
    policies_dir = os.path.join(docs_dir, "policies")

    # 獲取所有 .md 文件
    md_files = glob.glob(os.path.join(docs_dir, "**", "*.md"), recursive=True)

    # 過濾掉 policies 目錄
    md_files = [f for f in md_files if not f.startswith(policies_dir)]

    print(f"找到 {len(md_files)} 個文件需要轉換（排除 policies/ 目錄）")
    print("=" * 60)

    success_count = 0
    fail_count = 0

    for filepath in md_files:
        if process_file(filepath):
            success_count += 1
        else:
            fail_count += 1

    print("=" * 60)
    print(f"轉換完成！成功: {success_count}, 失敗: {fail_count}")


if __name__ == "__main__":
    main()
