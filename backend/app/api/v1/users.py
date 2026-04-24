from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.infrastructure import models
from app.infrastructure.database import get_db
from app.application.services import UserService
from app.domain import entities
from app.core import security
from app.api.deps import get_current_user, require_roles

router = APIRouter()

@router.get("/", response_model=List[entities.User])
def read_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    _user = Depends(require_roles("doctor", "gestor"))
):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.get("/me", response_model=entities.User)
def read_user_me(current_user = Depends(get_current_user)):
    return current_user

@router.post("/login")
def login(user: entities.UserCreate, db: Session = Depends(get_db)):
    db_user = UserService.get_user_by_username(db, username=user.username)
    if not db_user or not security.verify_password(user.password, db_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = security.create_access_token(
        subject=db_user.username, role=db_user.role
    )
    return {"access_token": access_token, "token_type": "bearer", "user": db_user}

@router.post("/register", response_model=entities.User)
def register(user: entities.UserCreate, db: Session = Depends(get_db)):
    db_user = UserService.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return UserService.create_user(db=db, user=user)

@router.put("/{user_id}/availability", response_model=entities.User)
def update_availability(
    user_id: int, 
    is_available: bool, 
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    if current_user.id != user_id and current_user.role != "gestor":
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_user.is_available = is_available
    db.commit()
    db.refresh(db_user)
    return db_user
