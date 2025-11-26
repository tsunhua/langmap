from typing import Optional
from sqlalchemy.orm import Session
from app.db import models
from sqlalchemy import or_


def get_expressions(db: Session, skip: int = 0, limit: int = 50):
    return db.query(models.Expression).offset(skip).limit(limit).all()


def create_expression(db: Session, payload, source_type: str = "user", auto_approve: bool = False):
    # create expression and initial version
    expr = models.Expression(
        language=payload.language,
        region=payload.region,
        text=payload.text,
        source_type=source_type,
        source_ref=payload.source_ref,
        audio_url=payload.audio_url,
        review_status="approved" if auto_approve else "pending",
        auto_approved=bool(auto_approve),
    )
    db.add(expr)
    db.flush()  # get id

    version = models.ExpressionVersion(
        expression_id=expr.id,
        language=payload.language,
        region=payload.region,
        text=payload.text,
        source_type=source_type,
        review_status="approved" if auto_approve else "pending",
        auto_approved=bool(auto_approve),
    )
    db.add(version)
    db.commit()
    db.refresh(expr)
    return expr


def create_meaning(db: Session, gloss: Optional[str] = None, description: Optional[str] = None, created_by: Optional[int] = None):
    m = models.Meaning(gloss=gloss, description=description, created_by=created_by)
    db.add(m)
    db.commit()
    db.refresh(m)
    return m


def link_expression_meaning(db: Session, expression_id: int, meaning_id: int, created_by: Optional[int] = None, note: Optional[str] = None):
    # avoid duplicate
    exists = (
        db.query(models.ExpressionMeaning)
        .filter(models.ExpressionMeaning.expression_id == expression_id)
        .filter(models.ExpressionMeaning.meaning_id == meaning_id)
        .first()
    )
    if exists:
        return exists
    link = models.ExpressionMeaning(expression_id=expression_id, meaning_id=meaning_id, created_by=created_by, note=note)
    db.add(link)
    db.commit()
    db.refresh(link)
    return link


def get_meaning(db: Session, meaning_id: int):
    return db.query(models.Meaning).filter(models.Meaning.id == meaning_id).first()


def get_meaning_members(db: Session, meaning_id: int, limit: int = 100):
    m = get_meaning(db, meaning_id)
    if not m:
        return []
    # eager load members via relationship
    return m.expressions[:limit]


def get_expression(db: Session, expr_id: int):
    return db.query(models.Expression).filter(models.Expression.id == expr_id).first()


def get_versions(db: Session, expression_id: int, skip: int = 0, limit: int = 50):
    return (
        db.query(models.ExpressionVersion)
        .filter(models.ExpressionVersion.expression_id == expression_id)
        .order_by(models.ExpressionVersion.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_translations(db: Session, expression_id: int, limit: int = 50):
    """Return list of related expressions grouped by meaning for the given expression id.

    Returns simple dicts suitable for JSON serialization.
    """
    expr = get_expression(db, expression_id)
    if not expr:
        return []
    results = []
    seen = set()
    # iterate meanings
    for meaning in expr.meanings:
        for member in meaning.expressions:
            if member.id == expr.id:
                continue
            if member.id in seen:
                continue
            seen.add(member.id)
            results.append({
                "id": member.id,
                "language": member.language,
                "region": member.region,
                "text": member.text,
                "source_ref": member.source_ref,
            })
            if len(results) >= limit:
                return results
    return results


def get_meanings_by_expression(db: Session, expression_id: int):
    expr = get_expression(db, expression_id)
    if not expr:
        return []
    out = []
    for m in expr.meanings:
        out.append({
            "id": m.id,
            "gloss": m.gloss,
            "description": m.description,
        })
    return out


def search_expressions(db: Session, q: str = None, from_lang: str = None, region: str = None, skip: int = 0, limit: int = 50):
    query = db.query(models.Expression)
    if q:
        likeq = f"%{q}%"
        query = query.filter(or_(models.Expression.text.ilike(likeq), models.Expression.source_ref.ilike(likeq)))
    if from_lang:
        query = query.filter(models.Expression.language == from_lang)
    if region:
        query = query.filter(models.Expression.region == region)
    return query.order_by(models.Expression.created_at.desc()).offset(skip).limit(limit).all()
