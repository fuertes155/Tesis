from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PatientBase(BaseModel):
    name: str
    age: int
    birth_date: Optional[str] = None
    document_id: Optional[str] = None
    phone: Optional[str] = None
    diagnosis: Optional[str] = None
    doctor_id: Optional[int] = None

class PatientCreate(PatientBase):
    pass

class PatientUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    birth_date: Optional[str] = None
    document_id: Optional[str] = None
    phone: Optional[str] = None
    diagnosis: Optional[str] = None
    doctor_id: Optional[int] = None

class Patient(PatientBase):
    id: int
    registration_date: Optional[datetime] = None

    class Config:
        from_attributes = True
