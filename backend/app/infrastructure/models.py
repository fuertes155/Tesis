from typing import List, Optional, Any
from sqlalchemy import Boolean, Integer, String, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship, Mapped, mapped_column
from datetime import datetime, timezone
from .database import Base

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    username: Mapped[str] = mapped_column(String, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String)
    role: Mapped[str] = mapped_column(String, default="doctor")
    full_name: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    is_2fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    totp_secret: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    registration_date: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

class Patient(Base):
    __tablename__ = "patients"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, index=True)
    age: Mapped[int] = mapped_column(Integer)
    birth_date: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    document_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    phone: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    diagnosis: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    doctor_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    user: Mapped[Optional["User"]] = relationship("User", foreign_keys=[user_id])
    doctor: Mapped[Optional["User"]] = relationship("User", foreign_keys=[doctor_id])
    sessions: Mapped[List["Session"]] = relationship("Session", back_populates="patient", cascade="all, delete-orphan")

class Session(Base):
    __tablename__ = "sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    patient_id: Mapped[int] = mapped_column(Integer, ForeignKey("patients.id", ondelete="CASCADE"))
    date: Mapped[str] = mapped_column(String)
    status: Mapped[str] = mapped_column(String)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    duration_ms: Mapped[int] = mapped_column(Integer, default=0)
    external_id: Mapped[Optional[str]] = mapped_column(String, unique=True, index=True, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    patient: Mapped["Patient"] = relationship("Patient", back_populates="sessions")

class Result(Base):
    __tablename__ = "results"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    session_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sessions.id", ondelete="CASCADE"), nullable=True)
    patient_id: Mapped[int] = mapped_column(Integer, ForeignKey("patients.id", ondelete="CASCADE"))
    game_name: Mapped[str] = mapped_column(String, index=True)
    score: Mapped[int] = mapped_column(Integer)
    details: Mapped[Optional[Any]] = mapped_column(JSON, nullable=True)
    metrics: Mapped[Optional[Any]] = mapped_column(JSON, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    session: Mapped[Optional["Session"]] = relationship("Session")
    patient: Mapped["Patient"] = relationship("Patient")

class CognitiveReport(Base):
    __tablename__ = "cognitive_reports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    patient_db_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("patients.id", ondelete="SET NULL"), nullable=True)
    paciente_id: Mapped[str] = mapped_column(String, index=True)
    nombre_paciente: Mapped[str] = mapped_column(String, index=True)
    edad_paciente: Mapped[int] = mapped_column(Integer)
    fecha_evaluacion: Mapped[str] = mapped_column(String, index=True)
    profesional: Mapped[str] = mapped_column(String)
    pruebas: Mapped[Any] = mapped_column(JSON)
    reporte: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    patient: Mapped[Optional["Patient"]] = relationship("Patient")

class Doctor(Base):
    __tablename__ = "doctors"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), unique=True, nullable=True)
    specialty: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    bio: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    user: Mapped[Optional["User"]] = relationship("User")

class Administrator(Base):
    __tablename__ = "administrators"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), unique=True, nullable=True)
    position: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    user: Mapped[Optional["User"]] = relationship("User")

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    action: Mapped[str] = mapped_column(String)  # CREATE, UPDATE, DELETE
    entity_type: Mapped[str] = mapped_column(String)  # Patient, Session, etc.
    entity_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    old_value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON-stringified old state
    new_value: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # JSON-stringified new state
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

