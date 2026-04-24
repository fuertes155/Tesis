from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from datetime import datetime
from app.database import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String)  # CREATE, UPDATE, DELETE
    entity_type = Column(String)  # Patient, Session, etc.
    entity_id = Column(Integer, nullable=True)
    old_value = Column(Text, nullable=True)  # JSON-stringified old state
    new_value = Column(Text, nullable=True)  # JSON-stringified new state
    timestamp = Column(DateTime, default=datetime.utcnow)
