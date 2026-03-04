from pydantic import BaseModel
from typing import Optional

class PatientBase(BaseModel):
    name: str
    age: int
    birth_date: Optional[str] = None
    document_id: Optional[str] = None
    phone: Optional[str] = None
    diagnosis: Optional[str] = None

class PatientCreate(PatientBase):
    pass

class Patient(PatientBase):
    id: int

    class Config:
        from_attributes = True
