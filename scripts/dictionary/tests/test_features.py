import json

from scripts.dictionary.langmap_dictionary.features import build_features
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


def _db(tmp_path):
    db = create_staging_database(tmp_path / "stage.sqlite")
    db.execute("INSERT INTO staging_releases(id,manifest_hash,schema_version,status) VALUES ('r1','a'*64,1,'staged')")
    for claim, entry, sense in (("a", "e1", "s1"), ("b", "e2", "s2")):
        db.execute("INSERT INTO input_entries VALUES (?,?,?,?,?,?,?,?,?)", ("r1", entry, "fixture", "cod", "cod", None, "eng-zh", "b" * 64, "{}"))
        db.execute("INSERT INTO input_senses VALUES (?,?,?,?,?,?,?,?,?,?,?)", ("r1", sense, entry, 1, json.dumps(["an invented definition"]), json.dumps(["noun"]), json.dumps([{"value": "魚", "language": "cmn"}]), "[]", json.dumps([{"text": "example"}]), json.dumps(["common"]), "{}"))
        db.execute("INSERT INTO lexical_occurrences VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", ("r1", claim, "headword", entry, sense, "cod", "cod", "eng", "eng-Latn-US", f"cluster:{claim}", "{}", "[]"))
    db.commit()
    return db


def test_features_are_stable_and_keep_raw_evidence_order(tmp_path):
    db = _db(tmp_path)
    value = build_features(db, "r1", "a", "b")
    assert value.language_code == "eng"
    assert value.canonical_text == "cod"
    assert value.left_pos == ("noun",)
    assert value.right_definitions == ("an invented definition",)
    assert value.left_raw_evidence_order == ('{"language":"cmn","value":"魚"}',)
    assert value.features_fingerprint == build_features(db, "r1", "a", "b").features_fingerprint
    assert "stage.sqlite" not in json.dumps(value.to_dict(), ensure_ascii=False)
