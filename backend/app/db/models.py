import datetime
from sqlalchemy import (Column, Integer, String, Text, Float, DateTime,
                        ForeignKey, Boolean)
from .database import Base


class Language(Base):
    __tablename__ = "languages"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True)
    name = Column(String, index=True)
    region_code = Column(String, nullable=True)
    region_name = Column(String, nullable=True)
    region_latitude = Column(Float, nullable=True)
    region_longitude = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))
    updated_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))


class Meaning(Base):
    __tablename__ = "meanings"

    id = Column(Integer, primary_key=True, index=True)
    gloss = Column(String, unique=True, index=True)
    description = Column(Text, nullable=True)
    tags = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))
    updated_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))


class Expression(Base):
    __tablename__ = "expressions"

    id = Column(Integer, primary_key=True, index=True)
    text = Column(String, index=True)
    language_code = Column(String, index=True)
    region_code = Column(String, nullable=True)
    region_name = Column(String, nullable=True)
    region_latitude = Column(Float, nullable=True)
    region_longitude = Column(Float, nullable=True)
    meaning_id = Column(Integer, nullable=True)
    source_type = Column(String(20), default="user")
    review_status = Column(String(20), default="pending")
    auto_approved = Column(Boolean, default=False)
    tags = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))
    updated_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))


class ExpressionVersion(Base):
    __tablename__ = "expression_versions"

    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=True)
    note = Column(Text, nullable=False)  # Modification record
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))


class ExpressionMeaning(Base):
    __tablename__ = "expression_meanings"

    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=False)
    meaning_id = Column(Integer, ForeignKey("meanings.id"), nullable=False)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))
    updated_at = Column(DateTime, default=datetime.datetime.now(datetime.UTC))