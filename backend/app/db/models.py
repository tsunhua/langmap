import datetime
import json
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.types import TypeDecorator, TEXT
from .base import Base


class ArrayType(TypeDecorator):
    """Platform-independent array type that serializes to JSON for SQLite and uses native arrays for PostgreSQL."""
    impl = TEXT
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is not None:
            if dialect.name == 'sqlite':
                return json.dumps(value)
            # For PostgreSQL, we can use the native array type
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            if dialect.name == 'sqlite':
                try:
                    return json.loads(value)
                except (ValueError, TypeError):
                    return []
            # For PostgreSQL, return the native array
        return value


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    role = Column(String(20), default="user")


class Language(Base):
    __tablename__ = "languages"
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), nullable=False)
    native_name = Column(String(100), nullable=True)
    direction = Column(String(3), default="ltr")
    is_active = Column(Boolean, default=True)
    region_name = Column(String(100), nullable=True)  # Region name (could be capital or other significant region)
    latitude = Column(String(20), nullable=True)  # Region latitude
    longitude = Column(String(20), nullable=True)  # Region longitude
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)


class Expression(Base):
    __tablename__ = "expressions"
    id = Column(Integer, primary_key=True, index=True)
    language = Column(String(50), nullable=False)
    region_name = Column(String(100), nullable=True)
    region_latitude = Column(String(20), nullable=True)
    region_longitude = Column(String(20), nullable=True)
    country_code = Column(String(10), nullable=True)
    country_name = Column(String(100), nullable=True)
    text = Column(Text, nullable=False)
    source_type = Column(String(20), default="user")
    source_ref = Column(String(255), nullable=True)
    audio_url = Column(String(255), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    review_status = Column(String(20), default="pending")
    auto_approved = Column(Boolean, default=False)
    tags = Column(ArrayType, nullable=True)  # Add tags field for UI translations
    # many-to-many via ExpressionMeaning
    meanings = relationship("Meaning", secondary="expression_meanings", back_populates="expressions")


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


class Meaning(Base):
    __tablename__ = "meanings"
    id = Column(Integer, primary_key=True, index=True)
    gloss = Column(String(255), nullable=True)  # short gloss or label, e.g. 'hello'
    description = Column(Text, nullable=True)
    tags = Column(ArrayType, nullable=True)  # Add tags field for identifying UI translations
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    # expressions linked (many-to-many)
    expressions = relationship("Expression", secondary="expression_meanings", back_populates="meanings")


class ExpressionMeaning(Base):
    __tablename__ = "expression_meanings"
    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=False)
    meaning_id = Column(Integer, ForeignKey("meanings.id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    note = Column(Text, nullable=True)
    parent_version_id = Column(Integer, nullable=True)