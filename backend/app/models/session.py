from sqlalchemy import Column, Integer, String, ForeignKey, Date
from sqlalchemy.orm import relationship
from app.database import Base

class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"))
    date = Column(Date)
    status = Column(String, default="scheduled")
    notes = Column(String, nullable=True)
    external_id = Column(String, unique=True, index=True, nullable=True)

    patient = relationship("Patient", back_populates="sessions")
