from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
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

    sessions = relationship(
        "Session",
        back_populates="patient",
        cascade="all, delete-orphan",
    )
