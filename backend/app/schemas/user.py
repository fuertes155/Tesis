from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: EmailStr
    role: str = "doctor"

    @field_validator("username")
    @classmethod
    def _normalize_username(cls, v: str) -> str:
        return v.strip().lower()

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: EmailStr
    password: str

    @field_validator("username")
    @classmethod
    def _normalize_login_username(cls, v: str) -> str:
        return v.strip().lower()

class User(UserBase):
    id: int
    is_active: bool = True
    is_available: bool = True
    registration_date: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User
