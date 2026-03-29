#!/usr/bin/env python3
"""
Script to parse Taigi CSV and generate SQL for bulk import.

CSV columns mapped to language codes:
  PojUnicode       -> nan-TW-POJ (main)
  PojUnicodeOthers -> nan-TW-POJ
  KipUnicode       -> nan-TW-TL
  KipUnicodeOthers -> nan-TW-TL
  HoaBun           -> zh-TW
  EngBun           -> en-US

All word variants in a row are linked together via expression_meaning.
LekuPoj/LekuHoabun/LekuEngbun (example sentences) are linked via LekuEngbun as meaning_id.
"""

import csv
import re
import uuid


def stable_hash_id(content: str) -> int:
    h = 0x811C9DC5
    for i in range(len(content)):
        h ^= ord(content[i])
        h = (h * 0x01000193) & 0xFFFFFFFF
    h = h & 0xFFFFFFFF
    return (h % (2**31 - 1)) + 1


def escape_sql(s):
    if s is None:
        return ""
    return s.replace("'", "''")


def get_or_create_expression(text, lang, processed_expressions, expressions_data):
    if not text:
        return None
    text = text.strip()
    if not text:
        return None
    key = (text, lang)
    if key not in processed_expressions:
        expr_id = stable_hash_id(f"{text}|{lang}")
        processed_expressions[key] = expr_id
        expressions_data.append(
            {"id": expr_id, "text": text, "language_code": lang, "desc": None}
        )
    return processed_expressions[key]


def generate_sql(csv_path, output_sql_path):
    processed_expressions = {}
    processed_meanings = {}
    expressions_data = []
    meanings_data = []
    expression_meanings_data = []

    with open(csv_path, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)

        for row in reader:
            poj = row.get("PojUnicode", "").strip()
            if not poj:
                continue
            if poj.startswith('"') or poj.startswith("'"):
                continue

            # === Build desc from example sentences ===
            leku_hoabun = row.get("LekuHoabun", "").strip()
            leku_poj = row.get("LekuPoj", "").strip()
            leku_engbun = row.get("LekuEngbun", "").strip()

            desc = None
            if leku_poj:
                leku_pojs = leku_poj.split("/")
                for p in leku_pojs:
                    if not desc:
                        desc = ""
                    desc = desc + "- {{" + p + "}}" + "\n"

            # === Create main expression (PojUnicode) with desc ===
            main_id = get_or_create_expression(
                poj, "nan-TW-POJ", processed_expressions, expressions_data
            )
            # Update desc on main expression
            for expr in reversed(expressions_data):
                if expr["id"] == main_id:
                    expr["desc"] = desc
                    break

            # === Create linked word variants ===
            poj_others = row.get("PojUnicodeOthers", "").strip()
            kip = row.get("KipUnicode", "").strip()
            kip_others = row.get("KipUnicodeOthers", "").strip()
            hoa_bun = row.get("HoaBun", "").strip()
            eng_bun = row.get("EngBun", "").strip()

            word_variants = [
                (poj_others, "nan-TW-POJ", r"[/\\]"),
                (kip, "nan-TW-TL", r"[/\\,，、]"),
                (kip_others, "nan-TW-TL", r"[/\\,，、]"),
                (hoa_bun, "zh-TW", r"[/\\,，、]"),
                (eng_bun, "en-US", r"[/\\,，、]"),
            ]

            linked_expr_ids = [main_id]
            for text, lang, sep_pattern in word_variants:
                if not text:
                    continue
                parts = [x.strip() for x in re.split(sep_pattern, text) if x.strip()]
                for part in parts:
                    eid = get_or_create_expression(
                        part, lang, processed_expressions, expressions_data
                    )
                    if eid:
                        linked_expr_ids.append(eid)

            # === Link all word variants via first EngBun expression_id as meaning ===
            first_eng_id = None
            for text, lang, _ in word_variants:
                if lang == "en-US" and text:
                    parts = [
                        x.strip() for x in re.split(r"[/\\,，、]", text) if x.strip()
                    ]
                    if parts:
                        first_eng_id = get_or_create_expression(
                            parts[0], "en-US", processed_expressions, expressions_data
                        )
                    break

            if first_eng_id and len(linked_expr_ids) >= 2:
                eng_meaning_key = f"word_eng|{eng_bun}"
                if eng_meaning_key not in processed_meanings:
                    processed_meanings[eng_meaning_key] = first_eng_id
                    meanings_data.append({"id": first_eng_id, "text": eng_meaning_key})
                for eid in linked_expr_ids:
                    expression_meanings_data.append(
                        {"expression_id": eid, "meaning_id": first_eng_id}
                    )
            elif main_id:
                self_meaning_key = f"self|{poj}"
                if self_meaning_key not in processed_meanings:
                    processed_meanings[self_meaning_key] = main_id
                    meanings_data.append({"id": main_id, "text": self_meaning_key})
                expression_meanings_data.append(
                    {"expression_id": main_id, "meaning_id": main_id}
                )

            # === Example sentences: link via LekuEngbun expression_id ===
            poj_examples = [
                x.strip() for x in re.split(r"[/\\]", leku_poj) if x.strip()
            ]
            hoabun_examples = [
                x.strip() for x in re.split(r"[/\\]", leku_hoabun) if x.strip()
            ]
            engbun_examples = [
                x.strip() for x in re.split(r"[/\\]", leku_engbun) if x.strip()
            ]

            max_examples = max(
                len(poj_examples), len(hoabun_examples), len(engbun_examples)
            )

            for idx in range(max_examples):
                poj_text = poj_examples[idx] if idx < len(poj_examples) else None
                hoabun_text = (
                    hoabun_examples[idx] if idx < len(hoabun_examples) else None
                )
                engbun_text = (
                    engbun_examples[idx] if idx < len(engbun_examples) else None
                )

                ex_poj_id = get_or_create_expression(
                    poj_text, "nan-TW-POJ", processed_expressions, expressions_data
                )
                ex_hoabun_id = get_or_create_expression(
                    hoabun_text, "zh-TW", processed_expressions, expressions_data
                )
                ex_eng_id = get_or_create_expression(
                    engbun_text, "en-US", processed_expressions, expressions_data
                )

                # Use LekuEngbun expression_id as meaning_id
                if ex_eng_id:
                    eng_meaning_key = f"leku_eng|{engbun_examples[idx] if idx < len(engbun_examples) else ''}"
                    if eng_meaning_key not in processed_meanings:
                        processed_meanings[eng_meaning_key] = ex_eng_id
                        meanings_data.append({"id": ex_eng_id, "text": eng_meaning_key})

                    for eid in [ex_poj_id, ex_hoabun_id, ex_eng_id]:
                        if eid:
                            expression_meanings_data.append(
                                {"expression_id": eid, "meaning_id": ex_eng_id}
                            )

    # Deduplicate
    unique_expressions = {}
    for expr in expressions_data:
        key = (expr["id"], expr["text"], expr["language_code"])
        unique_expressions[key] = expr
    expressions_data = list(unique_expressions.values())

    unique_meanings = {}
    for m in meanings_data:
        unique_meanings[m["id"]] = m
    meanings_data = list(unique_meanings.values())

    unique_em = []
    seen_em = set()
    for em in expression_meanings_data:
        key = (em["expression_id"], em["meaning_id"])
        if key not in seen_em:
            seen_em.add(key)
            unique_em.append(em)
    expression_meanings_data = unique_em

    # Write SQL
    BATCH_SIZE = 100

    with open(output_sql_path, "w", encoding="utf-8") as f:
        f.write("-- Generated SQL for Taigi expressions import\n")
        f.write(f"-- Source: {csv_path}\n")
        f.write(f"-- Language mapping:\n")
        f.write(f"--   PojUnicode/PojUnicodeOthers -> nan-TW-POJ\n")
        f.write(f"--   KipUnicode/KipUnicodeOthers -> nan-TW-TL\n")
        f.write(f"--   HoaBun -> zh-TW\n")
        f.write(f"--   EngBun -> en-US\n")
        f.write(f"-- Uses stableHashId for all IDs\n")
        f.write(
            f"-- Expressions: {len(expressions_data)}, Meanings: {len(meanings_data)}, Links: {len(expression_meanings_data)}\n\n"
        )

        # Step 1: Insert expressions (multi-row batch INSERT)
        with_desc = [e for e in expressions_data if e["desc"]]
        without_desc = [e for e in expressions_data if not e["desc"]]

        f.write("-- ============================================\n")
        f.write(
            "-- Step 1: Insert expressions (multi-row INSERT, 100 rows per batch)\n"
        )
        f.write(
            f"--   With desc: {len(with_desc)}, Without desc: {len(without_desc)}\n"
        )
        f.write("-- ============================================\n\n")

        TAG = '["1956 台灣白話基礎語句"]'
        TAG_JSON = '"1956 台灣白話基礎語句"'

        for i in range(0, len(with_desc), BATCH_SIZE):
            batch = with_desc[i : i + BATCH_SIZE]
            f.write(
                "INSERT INTO expressions (id, text, language_code, source_type, review_status, created_by, desc, tags) VALUES\n"
            )
            for j, expr in enumerate(batch):
                comma = "," if j < len(batch) - 1 else ""
                f.write(
                    f"    ({expr['id']}, '{escape_sql(expr['text'])}', '{expr['language_code']}', 'dictionary', 'approved', 'system', '{escape_sql(expr['desc'])}', '{TAG}'){comma}\n"
                )
            f.write(
                f"ON CONFLICT(id) DO UPDATE SET text = excluded.text, desc = COALESCE(excluded.desc, expressions.desc), tags = json_insert(COALESCE(expressions.tags, '[]'), '$[#]', '{TAG_JSON}');\n\n"
            )

        for i in range(0, len(without_desc), BATCH_SIZE):
            batch = without_desc[i : i + BATCH_SIZE]
            f.write(
                "INSERT INTO expressions (id, text, language_code, source_type, review_status, created_by, tags) VALUES\n"
            )
            for j, expr in enumerate(batch):
                comma = "," if j < len(batch) - 1 else ""
                f.write(
                    f"    ({expr['id']}, '{escape_sql(expr['text'])}', '{expr['language_code']}', 'dictionary', 'approved', 'system', '{TAG}'){comma}\n"
                )
            f.write(
                f"ON CONFLICT(id) DO UPDATE SET text = excluded.text, tags = json_insert(COALESCE(expressions.tags, '[]'), '$[#]', '{TAG_JSON}');\n\n"
            )

        # Step 2: Multi-row insert meanings
        f.write("\n-- ============================================\n")
        f.write("-- Step 2: Insert meanings (multi-row INSERT, 100 rows per batch)\n")
        f.write("-- ============================================\n\n")

        for i in range(0, len(meanings_data), BATCH_SIZE):
            batch = meanings_data[i : i + BATCH_SIZE]
            f.write("INSERT INTO meanings (id, created_by) VALUES\n")
            for j, meaning in enumerate(batch):
                comma = "," if j < len(batch) - 1 else ""
                f.write(f"    ({meaning['id']}, 'system'){comma}\n")
            f.write("ON CONFLICT(id) DO NOTHING;\n\n")

        # Step 3: Multi-row insert expression_meaning
        f.write("\n-- ============================================\n")
        f.write(
            "-- Step 3: Link expressions to meanings (multi-row INSERT, 100 rows per batch)\n"
        )
        f.write("-- ============================================\n\n")

        for i in range(0, len(expression_meanings_data), BATCH_SIZE):
            batch = expression_meanings_data[i : i + BATCH_SIZE]
            f.write(
                "INSERT INTO expression_meaning (id, expression_id, meaning_id) VALUES\n"
            )
            for j, em in enumerate(batch):
                em_id = str(uuid.uuid4())
                comma = "," if j < len(batch) - 1 else ""
                f.write(
                    f"    ('{em_id}', {em['expression_id']}, {em['meaning_id']}){comma}\n"
                )
            f.write("ON CONFLICT(id) DO NOTHING;\n\n")

        f.write(f"\n-- Summary:\n")
        f.write(f"-- - {len(expressions_data)} expressions\n")
        f.write(f"-- - {len(meanings_data)} meanings\n")
        f.write(f"-- - {len(expression_meanings_data)} expression_meaning links\n")

    print(f"Generated SQL:")
    print(f"  - {len(expressions_data)} expressions")
    print(f"  - {len(meanings_data)} meanings")
    print(f"  - {len(expression_meanings_data)} expression_meaning links")
    print(f"Output: {output_sql_path}")


if __name__ == "__main__":
    csv_path = "/Users/lim/Documents/Code/tsunhua/langmap/scripts/041_taigi/ChhoeTaigi_TaioanPehoeKichhooGiku.csv"
    output_sql_path = (
        "/Users/lim/Documents/Code/tsunhua/langmap/scripts/041_taigi/import_taigi.sql"
    )
    generate_sql(csv_path, output_sql_path)
