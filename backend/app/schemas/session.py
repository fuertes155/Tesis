from pydantic import BaseModel
from typing import Optional
from datetime import date

class SessionBase(BaseModel):
    patient_id: int
    date: date
    status: str = "scheduled"
    notes: Optional[str] = None
    external_id: Optional[str] = None

class SessionCreate(SessionBase):
    pass

class SessionUpdate(BaseModel):
    date: Optional[date] = None
    status: Optional[str] = None
    notes: Optional[str] = None

class Session(SessionBase):
    id: int

    class Config:
        from_attributes = True
