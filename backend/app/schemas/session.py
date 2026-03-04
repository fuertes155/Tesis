from pydantic import BaseModel
from typing import Optional
from datetime import date

class SessionBase(BaseModel):
    patient_id: int
    date: date
    status: str = "scheduled"
    notes: Optional[str] = None

class SessionCreate(SessionBase):
    pass

class Session(SessionBase):
    id: int

    class Config:
        from_attributes = True
