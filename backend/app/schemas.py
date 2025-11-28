from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ExpressionBase(BaseModel):
    language: str
    region_name: Optional[str] = None
    region_latitude: Optional[str] = None
    region_longitude: Optional[str] = None
    country_code: Optional[str] = None
    country_name: Optional[str] = None
    text: str
    source_ref: Optional[str] = None
    audio_url: Optional[str] = None
    tags: Optional[List[str]] = None


class ExpressionCreate(ExpressionBase):
    pass


class ExpressionOut(ExpressionBase):
    id: int
    source_type: str
    review_status: str
    auto_approved: bool
    created_at: Optional[datetime] = None
    created_by: Optional[int] = None

    class Config:
        from_attributes = True


class VersionOut(BaseModel):
    id: int
    expression_id: Optional[int] = None
    language: str
    region_name: Optional[str] = None
    region_latitude: Optional[str] = None
    region_longitude: Optional[str] = None
    country_code: Optional[str] = None
    country_name: Optional[str] = None
    text: str
    source_type: str
    review_status: str
    auto_approved: bool
    change_summary: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MeaningCreate(BaseModel):
    gloss: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None


class MeaningOut(BaseModel):
    id: int
    gloss: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class LanguageBase(BaseModel):
    code: str
    name: str
    native_name: Optional[str] = None
    direction: str = "ltr"


class LanguageCreate(LanguageBase):
    pass


class Language(LanguageBase):
    id: int
    is_active: bool
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True