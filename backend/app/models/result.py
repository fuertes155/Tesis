from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Result(Base):
    __tablename__ = "results"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("sessions.id", ondelete="CASCADE"), nullable=True)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"))
    game_name = Column(String, index=True)
    score = Column(Integer)
    details = Column(JSON, nullable=True)
    metrics = Column(JSON, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

    session = relationship("Session")
    patient = relationship("Patient")
