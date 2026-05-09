from pydantic import BaseModel, ConfigDict, field_validator
from typing import Optional, Any
from datetime import datetime


# ── helpers ───────────────────────────────────────────────────────────────────

def _title_case(name: str) -> str:
    """Capitalize the first letter of each word in a name."""
    return " ".join(w.capitalize() for w in name.split())


# ── User ──────────────────────────────────────────────────────────────────────

class UserBase(BaseModel):
    username: str
    role: str = "doctor"
    full_name: Optional[str] = None

    @field_validator("username")
    @classmethod
    def _normalize_username(cls, v: str) -> str:
        return v.strip().lower()

    @field_validator("full_name")
    @classmethod
    def _capitalize_full_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            return None
        return _title_case(stripped)


class UserCreate(UserBase):
    password: str

    @field_validator("role")
    @classmethod
    def _normalize_role(cls, v: str) -> str:
        return v.strip().lower()


class UserLogin(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def _normalize_login_username(cls, v: str) -> str:
        return v.strip().lower()


class UserUpdate(BaseModel):
    username: Optional[str] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    is_available: Optional[bool] = None

    @field_validator("username")
    @classmethod
    def _normalize_update_username(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return v.strip().lower()

    @field_validator("full_name")
    @classmethod
    def _capitalize_update_full_name(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripped = v.strip()
        if not stripped:
            return None
        return _title_case(stripped)


class User(UserBase):
    id: int
    is_active: bool = True
    is_available: bool = True
    is_2fa_enabled: bool = False
    full_name: Optional[str] = None
    registration_date: Optional[datetime] = None

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User


# ── Patient ───────────────────────────────────────────────────────────────────

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
    created_at: Optional[datetime] = None
    registration_date: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Session ───────────────────────────────────────────────────────────────────

class SessionBase(BaseModel):
    patient_id: int
    date: str
    status: str = "scheduled"
    notes: Optional[str] = None
    duration_ms: int = 0
    external_id: Optional[str] = None


class SessionCreate(SessionBase):
    pass


class SessionUpdate(BaseModel):
    date: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class Session(SessionBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ── Result ────────────────────────────────────────────────────────────────────

class ResultBase(BaseModel):
    game_name: str
    score: int
    details: Optional[dict[str, Any]] = None
    metrics: Optional[dict[str, Any]] = None
    patient_id: int
    session_id: Optional[int] = None


class ResultCreate(ResultBase):
    pass


class Result(ResultBase):
    id: int
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)
