from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime

class UserBase(BaseModel):
    username: EmailStr
    role: str = "doctor"
    full_name: Optional[str] = None

    @field_validator("username")
    @classmethod
    def _normalize_username(cls, v: str) -> str:
        return v.strip().lower()

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool = True
    is_available: bool = True
    is_2fa_enabled: bool = False
    registration_date: datetime

    class Config:
        from_attributes = True

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

class Patient(PatientBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class SessionBase(BaseModel):
    patient_id: int
    date: str
    status: str
    notes: str
    duration_ms: int = 0
    external_id: Optional[str] = None

class SessionCreate(SessionBase):
    pass

class Session(SessionBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
