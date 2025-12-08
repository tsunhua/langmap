import os
from opustools import OpusRead
import csv
import sys
import re

# -------------------------------------------------------------
# 設定
# -------------------------------------------------------------
CORPUS = "GNOME"
DOWNLOAD_DIR = "./opus_download"
OUTPUT_DIR = "./gnome_pairs"

LANGS = ["zh_CN", "zh_TW", "en_GB", "ja", "es"]  # 需要的語言
PAIRS = [
    ("zh_CN", "en_GB"),
    ("zh_TW", "en_GB"),
    ("ja", "en_GB"),
    ("es", "en_GB"),
]

os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)


# -------------------------------------------------------------
# 轉換成 cleaned_csv
# -------------------------------------------------------------
def clean_csv(src, tgt):
    print(f"=== Cleaning {src} → {tgt} ===")

    out_file = os.path.join(OUTPUT_DIR, f"{src}_{tgt}.csv")
    cleaned_csv = os.path.join(OUTPUT_DIR, f"{src}_{tgt}_clean.csv")

    # 检查输入文件是否存在
    if not os.path.exists(out_file):
        print(f"Input file {out_file} does not exist")
        return False

    # 轉成 CSV
    lines_written = 0
    translation_set = set()  # 用於記錄已經出現過的翻譯對
    try:
        with open(out_file, "r", encoding="utf-8") as f_in, \
                open(cleaned_csv, "w", encoding="utf-8", newline="") as f_out:

            writer = csv.writer(f_out)
            writer.writerow(["src", "tgt"])

            for line in f_in:
                parts = line.strip().split("\t")
                if len(parts) != 2:
                    continue
                s, t = parts
                if not s or not t:
                    continue
                if s == t:
                    continue
                if len(s) <= 1 or len(t) <= 1:
                    continue
                if len(s) > 100 or len(t) > 100:
                    continue
                # 如果s/t以標點符號開始，那麼也不記錄
                punt = set("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")
                if s[0] in punt or t[0] in punt:
                    continue
                # 郵箱也不記錄
                if "@" in s or "@" in t:
                    continue
                # 包含括號的也不記錄
                brackets = set("()[]{}<>（）【】「」《》")
                if any(bracket in s or bracket in t for bracket in brackets):
                    continue
                # 包含 “%s” 、“%d”、"% s"、"% d" 的也不記錄
                if any(char in s or char in t for char in "%s%d"):
                    continue
                # 包含 “/\｜｜” 之類的也不記錄
                if any(char in s or char in t for char in "/\\|｜"):
                    continue
                # 字符串本身不是數字，但是其中包含帶小數點的數字的
                # 例如 "14.4 Kbps 调制解调器" 的也不記錄
                if re.search(r'\d+\.\d+', s) or re.search(r'\d+\.\d+', t):
                    continue
                # 帶有常見文件名後綴的也不記錄
                if any(ext in s or ext in t for ext in
                       [".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".zip", ".rar", ".7z", ".gz",
                        ".tar", ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".mp3", ".mp4", ".avi", ".wav", ".mov",
                        ".xref",".bak"]):
                    continue
                # 包含 “NULL” 的也不記錄
                if "NULL" in s or "NULL" in t:
                     continue

                # 語言是中文，但是內容沒有中文字符的不記錄
                if 'zh' in src and not re.search(r'[\u4e00-\u9fff]', s):
                    continue

                # 使用元組作為鍵值，檢查是否已存在於集合中
                translation_key = (t)
                if translation_key in translation_set:
                    continue  # 跳過重複的翻譯對
                translation_set.add(translation_key)  # 添加新的翻譯對到集合中

                writer.writerow([s, t])
                lines_written += 1

    except Exception as e:
        print(f"Error processing file {out_file}: {str(e)}")
        # 如果有错误，清理已创建的文件
        if os.path.exists(cleaned_csv):
            os.remove(cleaned_csv)
        return False

    if lines_written <= 1:  # 只有标题行
        print(f"No valid sentence pairs found for {src}-{tgt}")
        # 删除空的清理文件
        if os.path.exists(cleaned_csv):
            os.remove(cleaned_csv)
        return False

    print(f"→ Saved cleaned CSV: {cleaned_csv} with {lines_written - 1} entries")
    return True


# -------------------------------------------------------------
# 抽取單一語言對成句對表
# -------------------------------------------------------------
def extract_pair(src, tgt):
    print(f"=== Extracting {src} → {tgt} ===")

    out_file = os.path.join(OUTPUT_DIR, f"{src}_{tgt}.csv")

    try:
        reader = OpusRead(
            directory=CORPUS,
            download_dir=DOWNLOAD_DIR,
            source=src,
            target=tgt,
            preprocess="xml",  # 明确指定预处理类型
            write=[out_file],
            write_mode="moses",
        )

        reader.printPairs()  # 觸發下載 + 對齊 + 生檔

    except Exception as e:
        print(f"Error processing {src}-{tgt}: {str(e)}")
        # 清理可能损坏的文件
        if os.path.exists(out_file):
            os.remove(out_file)
        return False

    # 检查输出文件是否存在且不为空
    if not os.path.exists(out_file) or os.path.getsize(out_file) == 0:
        print(f"No data extracted for {src}-{tgt} (output file is missing or empty)")
        return False

    # 调用clean_csv函数处理文件
    return clean_csv(src, tgt)


# -------------------------------------------------------------
# 主流程：跑所有語言對
# -------------------------------------------------------------
def main():
    # 检查是否只执行clean操作
    clean_only = len(sys.argv) > 1 and sys.argv[1] == '--clean'

    if clean_only:
        print("Running in clean-only mode")
        success_count = 0
        for src, tgt in PAIRS:
            if clean_csv(src, tgt):
                success_count += 1
        print(f"✔ Successfully cleaned {success_count}/{len(PAIRS)} pairs!")
    else:
        success_count = 0
        for src, tgt in PAIRS:
            if extract_pair(src, tgt):
                success_count += 1
        print(f"✔ Successfully extracted {success_count}/{len(PAIRS)} pairs!")


if __name__ == "__main__":
    main()
