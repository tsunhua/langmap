import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False)
    role = Column(String(20), default="user")


class Expression(Base):
    __tablename__ = "expressions"
    id = Column(Integer, primary_key=True, index=True)
    language = Column(String(50), nullable=False)
    region = Column(String(100), nullable=True)
    text = Column(Text, nullable=False)
    source_type = Column(String(20), default="user")
    source_ref = Column(String(255), nullable=True)
    audio_url = Column(String(255), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    review_status = Column(String(20), default="pending")
    auto_approved = Column(Boolean, default=False)
    # many-to-many via ExpressionMeaning
    meanings = relationship("Meaning", secondary="expression_meanings", back_populates="expressions")


class ExpressionVersion(Base):
    __tablename__ = "expression_versions"
    id = Column(Integer, primary_key=True, index=True)
    expression_id = Column(Integer, ForeignKey("expressions.id"), nullable=True)
    language = Column(String(50), nullable=False)
    region = Column(String(100), nullable=True)
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
