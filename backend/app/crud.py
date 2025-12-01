from typing import Optional, List
from sqlalchemy.orm import Session
from app.db import models
from sqlalchemy import or_, and_, text


def get_expressions(db: Session, skip: int = 0, limit: int = 50):
    return db.query(models.Expression).offset(skip).limit(limit).all()


def get_expressions_by_tags(db: Session, language_code: str, tags: List[str], skip: int = 0, limit: int = 50):
    """Get expressions filtered by language and tags for UI translations"""
    query = db.query(models.Expression).filter(models.Expression.language_code == language_code)
    
    # If tags are provided, filter by them
    if tags:
        # For SQLite compatibility, we need to handle array queries differently
        if db.bind.dialect.name == 'sqlite':
            # Use JSON operations for SQLite
            tag_conditions = []
            for tag in tags:
                tag_conditions.append(text("tags LIKE '%{}%'".format(tag)))
            if tag_conditions:
                query = query.filter(or_(*tag_conditions))
        else:
            # For PostgreSQL, use native array operations
            tag_conditions = []
            for tag in tags:
                tag_conditions.append(models.Expression.tags.contains([tag]))
            query = query.filter(or_(*tag_conditions))
    
    return query.order_by(models.Expression.created_at.desc()).offset(skip).limit(limit).all()


def create_expression(db: Session, payload, source_type: str = "user", auto_approve: bool = False, created_by: Optional[int] = None):
    # create expression and initial version
    expr = models.Expression(
        language_code=payload.language_code,
        region_code=payload.region_code,
        region_name=payload.region_name,
        region_latitude=payload.region_latitude,
        region_longitude=payload.region_longitude,
        text=payload.text,
        tags=payload.tags,
        source_type=source_type,
        review_status="approved" if auto_approve else "pending",
        auto_approved=bool(auto_approve),
    )
    db.add(expr)
    db.flush()  # get id

    version = models.ExpressionVersion(
        expression_id=expr.id,
        note=f"Created expression with text: {payload.text}",
    )
    db.add(version)
    db.commit()
    db.refresh(expr)
    return expr


def create_meaning(db: Session, gloss: Optional[str] = None, description: Optional[str] = None, tags: Optional[List[str]] = None, created_by: Optional[int] = None):
    m = models.Meaning(gloss=gloss, description=description, tags=tags)
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
    link = models.ExpressionMeaning(expression_id=expression_id, meaning_id=meaning_id, note=note)
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
    # We'll query for all ExpressionMeaning entries with this meaning_id
    # and join with Expression to get the actual expressions
    return db.query(models.Expression).join(models.ExpressionMeaning).filter(
        models.ExpressionMeaning.meaning_id == meaning_id
    ).limit(limit).all()


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
    
    # Find all meanings associated with this expression
    expression_meanings = db.query(models.ExpressionMeaning).filter(
        models.ExpressionMeaning.expression_id == expression_id
    ).all()
    
    meaning_ids = [em.meaning_id for em in expression_meanings]
    
    # Find all expressions associated with these meanings
    related_expressions = db.query(models.Expression).join(models.ExpressionMeaning).filter(
        models.ExpressionMeaning.meaning_id.in_(meaning_ids),
        models.Expression.id != expression_id
    ).limit(limit).all()
    
    for member in related_expressions:
        if member.id in seen:
            continue
        seen.add(member.id)
        results.append({
            "id": member.id,
            "language_code": member.language_code,
            "region_code": member.region_code,
            "region_name": member.region_name,
            "region_latitude": member.region_latitude,
            "region_longitude": member.region_longitude,
            "text": member.text,
        })
        if len(results) >= limit:
            return results
    return results


def get_meanings_by_expression(db: Session, expression_id: int):
    expr = get_expression(db, expression_id)
    if not expr:
        return []
        
    # Get all meanings associated with this expression
    expression_meanings = db.query(models.ExpressionMeaning).filter(
        models.ExpressionMeaning.expression_id == expression_id
    ).all()
    
    meaning_ids = [em.meaning_id for em in expression_meanings]
    
    meanings = db.query(models.Meaning).filter(
        models.Meaning.id.in_(meaning_ids)
    ).all()
    
    out = []
    for m in meanings:
        out.append({
            "id": m.id,
            "gloss": m.gloss,
            "description": m.description,
            "tags": m.tags
        })
    return out


def search_expressions(db: Session, q: str = None, from_lang: str = None, region: str = None, skip: int = 0, limit: int = 50):
    query = db.query(models.Expression)
    if q:
        likeq = f"%{q}%"
        query = query.filter(or_(models.Expression.text.ilike(likeq)))
    if from_lang:
        query = query.filter(models.Expression.language_code == from_lang)
    if region:
        query = query.filter(models.Expression.region_name == region)
    return query.order_by(models.Expression.created_at.desc()).offset(skip).limit(limit).all()


def get_languages(db: Session):
    """Get all languages from the database"""
    return db.query(models.Language).all()


def get_language_by_code(db: Session, code: str):
    """Get a language by its code"""
    return db.query(models.Language).filter(models.Language.code == code).first()


def create_language(db: Session, language, created_by: Optional[int] = None):
    """Create a new language"""
    db_language = models.Language(
        code=language.code,
        name=language.name,
        region_code=language.region_code,
        region_name=language.region_name,
        region_latitude=language.region_latitude,
        region_longitude=language.region_longitude,
    )
    db.add(db_language)
    db.commit()
    db.refresh(db_language)
    return db_language


def get_ui_translations_by_meaning(db: Session, language_code: str, skip: int = 0, limit: int = 100):
    """Get UI translations for a specific language by joining expressions with meanings that have 'langmap.' glosses"""
    # Query expressions that are linked to meanings with gloss starting with 'langmap.'
    # and match the specified language
    query = (
        db.query(models.Expression, models.Meaning.gloss)
        .join(models.ExpressionMeaning, models.Expression.id == models.ExpressionMeaning.expression_id)
        .join(models.Meaning, models.Meaning.id == models.ExpressionMeaning.meaning_id)
        .filter(models.Expression.language_code == language_code)
        .filter(models.Meaning.gloss.like('langmap.%'))
    )
    
    results = query.offset(skip).limit(limit).all()
    
    # Transform to the format expected by the frontend
    translations = []
    for expression, gloss in results:
        translations.append({
            'id': expression.id,
            'text': expression.text,
            'language_code': expression.language_code,
            'gloss': gloss
        })
    
    return translations


def get_ui_translations_by_meaning_tags(db: Session, language_code: str, skip: int = 0, limit: int = 100):
    """Get UI translations for a specific language by querying meanings with 'langmap' tag 
    and finding linked expressions in the specified language"""
    
    # For SQLite compatibility, we need to handle array queries differently
    if db.bind.dialect.name == 'sqlite':
        # Use JSON operations for SQLite
        meanings_query = db.query(models.Meaning).filter(text("tags LIKE '%langmap%'"))
    else:
        # For PostgreSQL, use native array operations
        meanings_query = db.query(models.Meaning).filter(models.Meaning.tags.contains(['langmap']))
    
    # Get meanings with langmap tag
    meanings = meanings_query.all()
    
    # For each meaning, find the expression in the specified language
    translations = []
    for meaning in meanings:
        # Look for expressions linked to this meaning in the specified language
        expression = db.query(models.Expression).join(models.ExpressionMeaning).filter(
            models.ExpressionMeaning.meaning_id == meaning.id,
            models.Expression.language_code == language_code
        ).first()
        
        if expression:
            translations.append({
                'id': expression.id,
                'text': expression.text,
                'language_code': expression.language_code,
                'gloss': meaning.gloss
            })
    
    # Apply pagination
    return translations[skip:skip+limit]