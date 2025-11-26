#!/usr/bin/env python3
"""Seed the backend sqlite with mock 'hello' expressions in multiple languages."""
from app.db.session import engine, SessionLocal
from app.db import models


SAMPLES = [
    ("en", "Hello", "Global"),
    ("zh-CN", "你好", "China"),
    ("es", "Hola", "Spain"),
    ("fr", "Bonjour", "France"),
    ("de", "Hallo", "Germany"),
    ("ja", "こんにちは", "Japan"),
    ("ko", "안녕하세요", "Korea"),
    ("ru", "Здравствуйте", "Russia"),
    ("ar", "مرحبا", "Arabic"),
    ("hi", "नमस्ते", "India"),
    ("pt", "Olá", "Portugal"),
]


def seed():
    # ensure tables
    models.Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        inserted_ids = []
        for lang, text, region in SAMPLES:
            # avoid duplicates
            exists = (
                db.query(models.Expression)
                .filter(models.Expression.language == lang)
                .filter(models.Expression.text == text)
                .first()
            )
            if exists:
                print(f"Skipping existing: {lang} - {text}")
                # include existing id so it gets linked to the meaning
                inserted_ids.append(exists.id)
                continue

            expr = models.Expression(
                language=lang,
                region=region,
                text=text,
                source_type="authoritative",
                source_ref="mock",
                review_status="approved",
                auto_approved=True,
            )
            db.add(expr)
            db.flush()
            inserted_ids.append(expr.id)

            ver = models.ExpressionVersion(
                expression_id=expr.id,
                language=lang,
                region=region,
                text=text,
                source_type="authoritative",
                review_status="approved",
                auto_approved=True,
            )
            db.add(ver)
            db.commit()
            print(f"Inserted: {lang} - {text}")
        # after inserting, create or reuse a single Meaning and link expressions
        if inserted_ids and hasattr(models, "Meaning") and hasattr(models, "ExpressionMeaning"):
            # find or create the meaning
            gloss = "greeting"
            meaning = (
                db.query(models.Meaning).filter(models.Meaning.gloss == gloss).first()
            )
            if not meaning:
                meaning = models.Meaning(gloss=gloss, description="Common greeting (seeded)")
                db.add(meaning)
                db.commit()
                db.refresh(meaning)
                print(f"Created meaning: {meaning.id} ({meaning.gloss})")
            else:
                print(f"Reusing meaning: {meaning.id} ({meaning.gloss})")

            # link each inserted expression (avoid duplicate links)
            for eid in inserted_ids:
                exists_link = (
                    db.query(models.ExpressionMeaning)
                    .filter(models.ExpressionMeaning.expression_id == eid)
                    .filter(models.ExpressionMeaning.meaning_id == meaning.id)
                    .first()
                )
                if exists_link:
                    print(f"Link exists for expression {eid} -> meaning {meaning.id}")
                    continue
                link = models.ExpressionMeaning(expression_id=eid, meaning_id=meaning.id, note="seed link")
                db.add(link)
            db.commit()
            print(f"Linked {len(inserted_ids)} expressions to meaning {meaning.id}")
    finally:
        db.close()


if __name__ == '__main__':
    seed()
