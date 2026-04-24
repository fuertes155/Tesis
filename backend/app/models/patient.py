from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.database import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    age = Column(Integer)
    birth_date = Column(String, nullable=True)
    document_id = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    diagnosis = Column(String, nullable=True)
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, unique=True)
    registration_date = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", foreign_keys=[user_id])
    doctor = relationship("User", foreign_keys=[doctor_id])

    sessions = relationship(
        "Session",
        back_populates="patient",
        cascade="all, delete-orphan",
    )
