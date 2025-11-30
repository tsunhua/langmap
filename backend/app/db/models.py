import datetime
import json
from sqlalchemy import Column, Integer, String, Text, Float
from app.db.base import Base

class Language(Base):
    __tablename__ = "languages"
    
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True)
    name = Column(String, index=True)
    family = Column(String, nullable=True)
    region_name = Column(String, nullable=True)
    region_lat = Column(Float, nullable=True)
    region_lng = Column(Float, nullable=True)
    capital_name = Column(String, nullable=True)
    capital_lat = Column(Float, nullable=True)
    capital_lng = Column(Float, nullable=True)
    tags = Column(Text, nullable=True)

class Meaning(Base):
    __tablename__ = "meanings"
    
    id = Column(Integer, primary_key=True, index=True)
    gloss = Column(String, unique=True, index=True)
    description = Column(Text, nullable=True)
    tags = Column(Text, nullable=True)

class Expression(Base):
    __tablename__ = "expressions"
    
    id = Column(Integer, primary_key=True, index=True)
    text = Column(String, index=True)
    language = Column(String, index=True)
    region_name = Column(String, nullable=True)
    region_lat = Column(Float, nullable=True)
    region_lng = Column(Float, nullable=True)
    meaning_id = Column(Integer, nullable=True)

class ExpressionVersion(Base):
    __tablename__ = "expression_versions"
    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=True)
    language = Column(String(50), nullable=False)
    region_name = Column(String(100), nullable=True)
    region_latitude = Column(String(20), nullable=True)
    region_longitude = Column(String(20), nullable=True)
    country_code = Column(String(10), nullable=True)
    country_name = Column(String(100), nullable=True)
    text = Column(Text, nullable=False)
    source_type = Column(String(20), default="user")
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    review_status = Column(String(20), default="pending")
    auto_approved = Column(Boolean, default=False)
    # keep version-level meaning mapping optional
    # (not adding relationship here to keep version model simple)


class ExpressionMeaning(Base):
    __tablename__ = "expression_meanings"
    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=False)
    meaning_id = Column(Integer, ForeignKey("meanings.id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    note = Column(Text, nullable=True)
    parent_version_id = Column(Integer, nullable=True)