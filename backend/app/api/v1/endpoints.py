from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from app import crud, schemas
from app.db.session import get_db

router = APIRouter(prefix="/api/v1")


@router.get("/expressions")
def list_expressions(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    items = crud.get_expressions(db, skip=skip, limit=limit)
    return items


@router.post("/expressions", status_code=201)
def create_expression(payload: schemas.ExpressionCreate, db: Session = Depends(get_db)):
    # user submissions become pending
    created = crud.create_expression(db, payload, source_type="user")
    return created


@router.post("/ai/suggest", status_code=201)
def ai_suggest(payload: schemas.ExpressionCreate, db: Session = Depends(get_db)):
    # For skeleton: accept AI suggestion payload and auto-approve
    created = crud.create_expression(db, payload, source_type="ai", auto_approve=True)
    return created


@router.get("/search")
def search(q: Optional[str] = None, from_lang: Optional[str] = None, region: Optional[str] = None, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    if not q:
        return []
    items = crud.search_expressions(db, q=q, from_lang=from_lang, region=region, skip=skip, limit=limit)
    return items


@router.get("/expressions/{expr_id}")
def get_expression(expr_id: int, db: Session = Depends(get_db)):
    item = crud.get_expression(db, expr_id)
    if not item:
        raise HTTPException(status_code=404, detail="Expression not found")
    return item


@router.get("/expressions/{expr_id}/versions")
def get_expression_versions(expr_id: int, skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    versions = crud.get_versions(db, expression_id=expr_id, skip=skip, limit=limit)
    return versions


@router.get("/expressions/{expr_id}/translations")
def get_expression_translations(expr_id: int, limit: int = 50, db: Session = Depends(get_db)):
    translations = crud.get_translations(db, expression_id=expr_id, limit=limit)
    return translations


@router.get("/expressions/{expr_id}/meanings")
def get_expression_meanings(expr_id: int, db: Session = Depends(get_db)):
    meanings = crud.get_meanings_by_expression(db, expression_id=expr_id)
    return meanings


@router.post("/meanings", status_code=201)
def create_meaning(payload: schemas.MeaningCreate, db: Session = Depends(get_db)):
    m = crud.create_meaning(db, gloss=payload.gloss, description=payload.description)
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
