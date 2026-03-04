from pydantic import BaseModel
from typing import Optional

class UserBase(BaseModel):
    username: str
    role: str = "doctor"

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool = True

    class Config:
        from_attributes = True
