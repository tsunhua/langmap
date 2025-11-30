from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime


class ExpressionBase(BaseModel):
    language: str
    region_name: Optional[str] = None
    region_latitude: Optional[str] = None
    region_longitude: Optional[str] = None
    country_code: Optional[str] = None
    country_name: Optional[str] = None


class ExpressionCreate(ExpressionBase):
    text: str
    source_ref: Optional[str] = None
    audio_url: Optional[str] = None
    tags: Optional[List[str]] = None


class ExpressionOut(ExpressionBase):
    id: int
    text: str
    source_type: str
    review_status: str
    auto_approved: bool
    source_ref: Optional[str] = None
    audio_url: Optional[str] = None
    tags: Optional[List[str]] = None

    class Config:
        from_attributes = True


class MeaningBase(BaseModel):
    gloss: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None


class MeaningCreate(MeaningBase):
    pass


class MeaningOut(MeaningBase):
    id: int

    class Config:
        from_attributes = True


class LanguageBase(BaseModel):
    code: str
    name: str
    native_name: Optional[str] = None
    direction: str = "ltr"
    region_name: Optional[str] = None
    latitude: Optional[str] = None
    longitude: Optional[str] = None


class LanguageCreate(LanguageBase):
    pass


class Language(LanguageBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class VersionOut(BaseModel):
    id: int
    expression_id: int
    language: str
    region: Optional[str] = None
    region_name: Optional[str] = None
    region_latitude: Optional[str] = None
    region_longitude: Optional[str] = None
    country_code: Optional[str] = None
    country_name: Optional[str] = None
    text: str
    source_type: str
    review_status: str
    auto_approved: bool
    created_at: datetime

    class Config:
        from_attributes = True