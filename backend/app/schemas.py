from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime


class ExpressionBase(BaseModel):
    language_code: str
    region_code: Optional[str] = None
    region_name: Optional[str] = None
    region_latitude: Optional[float] = None
    region_longitude: Optional[float] = None


class ExpressionCreate(ExpressionBase):
    text: str
    tags: Optional[List[str]] = None


class ExpressionOut(ExpressionBase):
    id: int
    text: str
    source_type: str
    review_status: str
    auto_approved: bool
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
    region_code: Optional[str] = None
    region_name: Optional[str] = None
    region_latitude: Optional[float] = None
    region_longitude: Optional[float] = None


class LanguageCreate(LanguageBase):
    pass


class Language(LanguageBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class VersionOut(BaseModel):
    id: int
    expression_id: int
    note: str
    created_at: datetime

    class Config:
        from_attributes = True