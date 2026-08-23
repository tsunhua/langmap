import json

from scripts.dictionary.langmap_dictionary.candidates import deterministic_blockers, generate_candidates
from scripts.dictionary.langmap_dictionary.features import CandidateFeatures
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


def _db(tmp_path, *, markers=(None, None), texts=("cod", "cod"), languages=("eng", "eng")):
    db = create_staging_database(tmp_path / "stage.sqlite")
    db.execute("INSERT INTO staging_releases(id,manifest_hash,schema_version,status) VALUES ('r1',?,1,'staged')", ("a" * 64,))
    for i, claim in enumerate(("a", "b")):
        entry, sense = f"e{i}", f"s{i}"
        db.execute("INSERT INTO input_entries VALUES (?,?,?,?,?,?,?,?,?)", ("r1", entry, "fixture", texts[i], texts[i], markers[i], None, "b" * 64, "{}"))
        db.execute("INSERT INTO input_senses VALUES (?,?,?,?,?,?,?,?,?,?,?)", ("r1", sense, entry, 1, json.dumps(["meaning"]), json.dumps(["noun"]), "[]", "[]", "[]", "[]", "{}"))
        db.execute("INSERT INTO lexical_occurrences VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", ("r1", claim, "headword", entry, sense, texts[i], texts[i], languages[i], None, f"cluster:{claim}", "{}", "[]"))
    db.commit()
    return db


def test_same_language_and_text_generates_one_candidate(tmp_path):
    summary = generate_candidates(_db(tmp_path), "r1")
    assert len(summary.candidates) == 1
    assert summary.candidates[0].key.value == "a\x00b"


def test_homograph_marker_conflict_is_blocked(tmp_path):
    summary = generate_candidates(_db(tmp_path, markers=("1", "2")), "r1")
    assert "explicit_homograph_conflict" in summary.candidates[0].blockers


def test_deterministic_blockers_cover_published_ids_and_pos():
    features = CandidateFeatures("eng", "cod", "a", "b", left_pos=("noun",), right_pos=("verb",), left_definitions=("x",), right_definitions=("y",), left_published_expression_ids=("x",), right_published_expression_ids=("y",))
    blockers = deterministic_blockers(features)
    assert "pos_conflict" in blockers
    assert "published_identity_conflict" in blockers
