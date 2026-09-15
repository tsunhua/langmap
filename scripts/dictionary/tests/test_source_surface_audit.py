import json

from scripts.dictionary.langmap_dictionary.source_surface_audit import audit_file


def test_audit_file_counts_surface_issues_and_bounds_samples(tmp_path):
    path = tmp_path / "source.jsonl"
    path.write_text(
        json.dumps({
            "record_type": "dictionary",
            "schema_version": 2,
            "dictionary_key": "test.source",
            "entry_count": 1,
        })
        + "\n"
        + json.dumps({
            "record_type": "entry",
            "entry_key": "entry-1",
            "raw_headword": "Hello ,",
            "canonical_headword": "Hello ,",
                "forms": ["[]"],
            "senses": [{"equivalents": ["Boa tarde (, /ˈbo.ɐ ˈtaɾ.dɨ/)"]}],
        })
        + "\n",
        encoding="utf-8",
    )
    report = audit_file(path, sample_limit=1)
    assert report["entries"] == 1
    assert report["stats"]["placeholder_surface"] == 1
    assert report["stats"]["terminal_punctuation"] >= 1
    assert report["stats"]["embedded_reading"] == 1
    assert len(report["samples"]["placeholder_surface"]) == 1


def test_audit_file_can_seek_a_bounded_head_middle_tail_sample(tmp_path):
    path = tmp_path / "source.jsonl"
    lines = [
        json.dumps({
            "record_type": "dictionary",
            "schema_version": 2,
            "dictionary_key": "test.source",
            "entry_count": 30,
        })
    ]
    for index in range(30):
        lines.append(json.dumps({
            "record_type": "entry",
            "entry_key": f"entry-{index}",
            "canonical_headword": "Hello ," if index == 29 else f"Word {index}",
        }))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    report = audit_file(path, sample_entries=6, sample_limit=2)

    assert report["sampled"] is True
    assert report["entries"] <= 6
    assert report["stats"]["terminal_punctuation"] >= 1


def test_single_entry_sample_does_not_expand_to_the_whole_tail(tmp_path):
    path = tmp_path / "source.jsonl"
    path.write_text(
        json.dumps({"record_type": "dictionary", "entry_count": 3, "dictionary_key": "test.source"})
        + "\n"
        + "\n".join(
            json.dumps({"record_type": "entry", "entry_key": str(index), "canonical_headword": str(index)})
            for index in range(3)
        )
        + "\n",
        encoding="utf-8",
    )
    assert audit_file(path, sample_entries=1)["entries"] == 1
