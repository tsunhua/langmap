import json

from scripts.dictionary.export_swatow_book_jsonl import export_book_csv, normalize_initial


def test_normalize_initial_distinguishes_words_from_sentences():
    assert normalize_initial("Si-kue") == "si-kue"
    assert normalize_initial("Iū") == "iū"
    assert normalize_initial("bô, uá lâi") == "Bô, uá lâi"
    assert normalize_initial("We not including") == "We not including"


def test_export_preserves_selected_forms_and_source_location(tmp_path):
    source = tmp_path / "book.csv"
    source.write_text(
        "puj,puj_proofread,han,han_orig,en,source,page_num\n"
        "Si-kue,,四,四原,I.,Book > A,7\n"
        "bô, ,無,,no,Book > B,8\n"
        '"bô, uá lâi",,無,,No,Book > C,9\n',
        encoding="utf-8",
    )
    output = tmp_path / "book.jsonl"

    summary = export_book_csv(source, output, "org.example.swatow")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]

    assert summary.entry_count == 3
    assert records[0]["entry_count"] == 3
    assert records[1]["raw_headword"] == "Si-kue"
    assert records[1]["canonical_headword"] == "si-kue"
    assert records[1]["native_locator"] == "Book > A > page 7"
    assert records[1]["senses"][0]["equivalents"] == [
        {"language_hint": "nan-Hant-CN_Swatow", "value": "四"},
        {"language_hint": "nan-Hant-CN_Swatow", "value": "四原"},
        {"language_hint": "eng-Latn-US", "value": "i."},
    ]
    assert records[2]["canonical_headword"] == "bô"
    assert records[3]["canonical_headword"] == "Bô, uá lâi"
    assert records[3]["senses"][0]["equivalents"][-1]["value"] == "no"
