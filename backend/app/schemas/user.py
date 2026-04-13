from pydantic import BaseModel, field_validator
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str
    role: str = "doctor"

    @field_validator("username")
    @classmethod
    def _normalize_username(cls, v: str) -> str:
        return v.strip().lower()

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

    @field_validator("username")
    @classmethod
    def _normalize_login_username(cls, v: str) -> str:
        return v.strip().lower()

class User(UserBase):
    id: int
    is_active: bool = True
    is_available: bool = True
    registration_date: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    username: Optional[str] = None
    is_active: Optional[bool] = None
    is_available: Optional[bool] = None

    @field_validator("username")
    @classmethod
    def _normalize_update_username(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return v.strip().lower()

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User
