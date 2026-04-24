from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime


def _title_case(name: str) -> str:
    """Capitalize the first letter of each word in a name."""
    return " ".join(w.capitalize() for w in name.split())

class PatientBase(BaseModel):
    name: str
    age: int
    birth_date: Optional[str] = None
    document_id: Optional[str] = None
    phone: Optional[str] = None
    diagnosis: Optional[str] = None
    email: Optional[str] = None
    doctor_id: Optional[int] = None

    @field_validator("name")
    @classmethod
    def _capitalize_name(cls, v: str) -> str:
        stripped = v.strip()
        if not stripped:
            return stripped
        return _title_case(stripped)

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

    @field_validator("name")
    @classmethod
    def _capitalize_update_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            return None
        return _title_case(stripped)

class Patient(PatientBase):
    id: int
    registration_date: Optional[datetime] = None

    class Config:
        from_attributes = True
