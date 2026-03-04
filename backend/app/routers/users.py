from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app import schemas, models
from app.database import get_db
import re

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[schemas.User])
def read_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    fake_hashed_password = user.password + "notreallyhashed"
    db_user = models.User(username=user.username, hashed_password=fake_hashed_password, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.post("/login", response_model=schemas.User)
def login(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if not db_user:
        # Auto-register for demo purposes
        fake_hashed_password = user.password + "notreallyhashed"
        db_user = models.User(username=user.username, hashed_password=fake_hashed_password, role=user.role)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    
    if db_user.hashed_password != user.password + "notreallyhashed":
        raise HTTPException(status_code=400, detail="Incorrect password")
    
    return db_user

@router.post("/reset", response_model=schemas.User)
def reset_password(user: schemas.UserCreate, db: Session = Depends(get_db)):
    def is_strong(p: str) -> bool:
        return (
            len(p) >= 8
            and re.search(r"[A-Z]", p) is not None
            and re.search(r"[a-z]", p) is not None
            and re.search(r"\d", p) is not None
            and re.search(r"[^A-Za-z0-9]", p) is not None
        )
    if not is_strong(user.password):
        raise HTTPException(status_code=400, detail="Weak password")
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    fake_hashed_password = user.password + "notreallyhashed"
    if not db_user:
        db_user = models.User(username=user.username, hashed_password=fake_hashed_password, role=user.role)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    db_user.hashed_password = fake_hashed_password
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/me", response_model=schemas.User)
async def read_user_me(db: Session = Depends(get_db)):
    # Placeholder for current user profile - returning the first user for now if exists
    user = db.query(models.User).first()
    if not user:
         raise HTTPException(status_code=404, detail="No users found")
    return user
