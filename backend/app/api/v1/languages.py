from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app import crud, schemas
from app.db import models
from app.db.session import get_db
from datetime import datetime

router = APIRouter(prefix="/api/v1")


@router.get("/languages", response_model=List[schemas.Language])
def list_languages(db: Session = Depends(get_db)):
    """Get list of all supported languages"""
    # Try to get languages from database first
    db_languages = crud.get_languages(db)
    if db_languages:
        return db_languages
    
    # Fallback to static list if no database languages found
    # Note: This is only for development/testing purposes
    # In production, languages should always come from the database
    languages = [
        {
            "id": 1,
            "code": "en", 
            "name": "English", 
            "native_name": "English", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
        {
            "id": 2,
            "code": "zh-CN", 
            "name": "Simplified Chinese", 
            "native_name": "简体中文", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
        {
            "id": 3,
            "code": "zh-TW", 
            "name": "Traditional Chinese", 
            "native_name": "傳統中文", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
        {
            "id": 4,
            "code": "es", 
            "name": "Spanish", 
            "native_name": "Español", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
        {
            "id": 5,
            "code": "fr", 
            "name": "French", 
            "native_name": "Français", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
        {
            "id": 6,
            "code": "ja", 
            "name": "Japanese", 
            "native_name": "日本語", 
            "direction": "ltr",
            "is_active": True,
            "created_at": datetime.now(),
            "updated_at": datetime.now()
        },
    ]
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