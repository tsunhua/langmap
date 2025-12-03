from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from app import crud, schemas
from app.db.session import get_db

router = APIRouter(prefix="/api/v1")

@router.get("/search")
def search(q: Optional[str] = None, from_lang: Optional[str] = None, region: Optional[str] = None, skip: int = 0,
           limit: int = 20, db: Session = Depends(get_db)):
    if not q:
        return []
    items = crud.search_expressions(db, q=q, from_lang=from_lang, region=region, skip=skip, limit=limit)
    return items


@router.get("/expressions")
def list_expressions(
        skip: int = 0,
        limit: int = 20,
        language_code: Optional[str] = None,
        tags: Optional[List[str]] = Query(None),
        db: Session = Depends(get_db)
):
    # If language_code and tags are provided, use the specialized function
    if language_code and tags is not None:
        items = crud.get_expressions_by_tags(db, language_code=language_code, tags=tags, skip=skip, limit=limit)
    else:
        items = crud.get_expressions(db, skip=skip, limit=limit)
    return items


@router.post("/expressions", status_code=201)
def create_expression(payload: schemas.ExpressionCreate, db: Session = Depends(get_db)):
    # user submissions become pending
    created = crud.create_expression(db, payload, source_type="user")
    return created


@router.get("/expressions/{expr_id}")
def get_expression(expr_id: int, db: Session = Depends(get_db)):
    item = crud.get_expression(db, expr_id)
    if not item:
        raise HTTPException(status_code=404, detail="Expression not found")
    return item


@router.get("/expressions/{expr_id}/versions")
def get_expression_versions(expr_id: int, skip: int = 0, limit: int = 20, db: Session = Depends(get_db)):
    versions = crud.get_versions(db, expression_id=expr_id, skip=skip, limit=limit)
    return versions


@router.get("/expressions/{expr_id}/translations")
def get_expression_translations(expr_id: int, limit: int = 20, db: Session = Depends(get_db)):
    translations = crud.get_translations(db, expression_id=expr_id, limit=limit)
    return translations


@router.get("/expressions/{expr_id}/meanings")
def get_expression_meanings(expr_id: int, db: Session = Depends(get_db)):
    meanings = crud.get_meanings_by_expression(db, expression_id=expr_id)
    return meanings


@router.post("/meanings", status_code=201)
def create_meaning(payload: schemas.MeaningCreate, db: Session = Depends(get_db)):
    m = crud.create_meaning(db, gloss=payload.gloss, description=payload.description, tags=payload.tags)
    return m


@router.post("/meanings/{mid}/link", status_code=201)
def link_expression(mid: int, expression_id: int, db: Session = Depends(get_db)):
    link = crud.link_expression_meaning(db, expression_id=expression_id, meaning_id=mid)
    return link


@router.get("/meanings/{mid}")
def get_meaning(mid: int, db: Session = Depends(get_db)):
    m = crud.get_meaning(db, mid)
    if not m:
        raise HTTPException(status_code=404, detail="Meaning not found")
    return m


@router.get("/meanings/{mid}/members")
def get_meaning_members(mid: int, db: Session = Depends(get_db)):
    members = crud.get_meaning_members(db, meaning_id=mid)
    return members


@router.get("/languages", response_model=List[schemas.Language])
def list_languages(db: Session = Depends(get_db)):
    """Get list of all supported languages"""
    languages = crud.get_languages(db)
    return languages


@router.post("/languages", response_model=schemas.Language)
def create_language(language: schemas.LanguageCreate, db: Session = Depends(get_db)):
    """Create a new language"""
    # Check if language with this code already exists
    db_language = crud.get_language_by_code(db, language.code)
    if db_language:
        raise HTTPException(status_code=400, detail="Language with this code already exists")

    # Create the new language
    return crud.create_language(db, language)


@router.get("/ui-translations/{language_code}")
def get_ui_translations(language_code: str, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get UI translations for a specific language by meaning tags"""
    translations = crud.get_ui_translations_by_meaning_tags(db, language_code=language_code, skip=skip, limit=limit)
    return translations
