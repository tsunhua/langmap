from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ExpressionBase(BaseModel):
    language: str
    region: Optional[str] = None
    text: str
    source_ref: Optional[str] = None
    audio_url: Optional[str] = None


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
    region: Optional[str] = None
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


class MeaningOut(BaseModel):
    id: int
    gloss: Optional[str] = None
    description: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True