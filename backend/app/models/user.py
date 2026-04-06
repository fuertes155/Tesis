from sqlalchemy import Boolean, Column, Integer, String, DateTime
from datetime import datetime
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    role = Column(String, default="doctor")
    is_active = Column(Boolean, default=True)
    is_available = Column(Boolean, default=True)
    registration_date = Column(DateTime, default=datetime.utcnow)
