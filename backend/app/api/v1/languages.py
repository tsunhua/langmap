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
            "region_name": "London",
            "native_region_name": "London",
            "latitude": "51.5074",
            "longitude": "-0.1278",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 2,
            "code": "zh-Hans", 
            "name": "Simplified Chinese", 
            "native_name": "简体中文", 
            "direction": "ltr",
            "region_name": "Beijing",
            "native_region_name": "北京",
            "latitude": "39.9042",
            "longitude": "116.4074",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 3,
            "code": "zh-Hant", 
            "name": "Traditional Chinese", 
            "native_name": "繁體中文", 
            "direction": "ltr",
            "region_name": "Taipei",
            "native_region_name": "台北",
            "latitude": "25.0330",
            "longitude": "121.5654",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 4,
            "code": "es", 
            "name": "Spanish", 
            "native_name": "Español", 
            "direction": "ltr",
            "region_name": "Madrid",
            "native_region_name": "Madrid",
            "latitude": "40.4168",
            "longitude": "-3.7038",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 5,
            "code": "fr", 
            "name": "French", 
            "native_name": "Français", 
            "direction": "ltr",
            "region_name": "Paris",
            "native_region_name": "Paris",
            "latitude": "48.8566",
            "longitude": "2.3522",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 6,
            "code": "ja", 
            "name": "Japanese", 
            "native_name": "日本語", 
            "direction": "ltr",
            "region_name": "Tokyo",
            "native_region_name": "東京",
            "latitude": "35.6762",
            "longitude": "139.6503",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 7,
            "code": "ko",
            "name": "Korean",
            "native_name": "한국어",
            "direction": "ltr",
            "region_name": "Seoul",
            "native_region_name": "서울",
            "latitude": "37.5665",
            "longitude": "126.9780",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 8,
            "code": "ar",
            "name": "Arabic",
            "native_name": "العربية",
            "direction": "rtl",
            "region_name": "Cairo",
            "native_region_name": "القاهرة",
            "latitude": "30.0444",
            "longitude": "31.2357",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 9,
            "code": "pt",
            "name": "Portuguese",
            "native_name": "Português",
            "direction": "ltr",
            "region_name": "Lisbon",
            "native_region_name": "Lisboa",
            "latitude": "38.7223",
            "longitude": "-9.1393",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 10,
            "code": "ru",
            "name": "Russian",
            "native_name": "Русский",
            "direction": "ltr",
            "region_name": "Moscow",
            "native_region_name": "Москва",
            "latitude": "55.7558",
            "longitude": "37.6176",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 11,
            "code": "de",
            "name": "German",
            "native_name": "Deutsch",
            "direction": "ltr",
            "region_name": "Berlin",
            "native_region_name": "Berlin",
            "latitude": "52.5200",
            "longitude": "13.4050",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 12,
            "code": "hi",
            "name": "Hindi",
            "native_name": "हिन्दी",
            "direction": "ltr",
            "region_name": "New Delhi",
            "native_region_name": "नई दिल्ली",
            "latitude": "28.6139",
            "longitude": "77.2090",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": 13,
            "code": "it",
            "name": "Italian",
            "native_name": "Italiano",
            "direction": "ltr",
            "region_name": "Rome",
            "native_region_name": "Roma",
            "latitude": "41.9028",
            "longitude": "12.4964",
            "is_active": True,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
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