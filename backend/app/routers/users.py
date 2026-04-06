from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from typing import List
from app import schemas, models
from app.database import get_db
from app.deps import get_current_user, require_roles
from app.security import get_password_hash, verify_password, create_access_token
import re

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

def _is_strong_password(p: str) -> bool:
    return (
        len(p) >= 8
        and re.search(r"[A-Z]", p) is not None
        and re.search(r"[a-z]", p) is not None
        and re.search(r"\d", p) is not None
        and re.search(r"[^A-Za-z0-9]", p) is not None
    )


def _get_user_by_username_ci(db: Session, username: str) -> models.User | None:
    normalized = username.strip().lower()
    return (
        db.query(models.User)
        .filter(func.lower(models.User.username) == normalized)
        .first()
    )


@router.get("/", response_model=List[schemas.User])
def read_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.post("/", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if not _is_strong_password(user.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña no cumple los requisitos de seguridad",
        )
    normalized = user.username.strip().lower()
    db_user = _get_user_by_username_ci(db, normalized)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email ya registrado",
        )
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        username=normalized,
        hashed_password=hashed_password,
        role=user.role,
        is_active=True,
    )
    db.add(db_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email ya registrado",
        )
    db.refresh(db_user)
    return db_user

@router.post("/login", response_model=schemas.User)
def login(user: schemas.UserLogin, db: Session = Depends(get_db)):
    normalized = user.username.strip().lower()
    db_user = _get_user_by_username_ci(db, normalized)
    if not db_user:
        raise HTTPException(status_code=404, detail="Usuario no registrado. Contacte a un administrador.")

    if db_user.hashed_password.endswith("notreallyhashed"):
        legacy_ok = db_user.hashed_password == user.password + "notreallyhashed"
        if not legacy_ok:
            raise HTTPException(status_code=400, detail="Contraseña incorrecta")
        db_user.hashed_password = get_password_hash(user.password)
        db.commit()
        db.refresh(db_user)
        return db_user

    if not verify_password(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Contraseña incorrecta")

    return db_user

@router.post("/auth/login", response_model=schemas.Token)
def auth_login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    normalized = payload.username.strip().lower()
    user = _get_user_by_username_ci(db, normalized)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no registrado")
    if user.hashed_password.endswith("notreallyhashed"):
        legacy_ok = user.hashed_password == payload.password + "notreallyhashed"
        if not legacy_ok:
            raise HTTPException(status_code=400, detail="Contraseña incorrecta")
        user.hashed_password = get_password_hash(payload.password)
        db.commit()
        db.refresh(user)
    else:
        if not verify_password(payload.password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Contraseña incorrecta")

    token = create_access_token(subject=user.username, role=user.role)
    return schemas.Token(access_token=token, user=user)

@router.post("/auth/register", response_model=schemas.Token, status_code=status.HTTP_201_CREATED)
def auth_register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    if not _is_strong_password(payload.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña no cumple los requisitos de seguridad",
        )
    normalized = payload.username.strip().lower()
    existing = _get_user_by_username_ci(db, normalized)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email ya registrado",
        )
    user = models.User(
        username=normalized,
        hashed_password=get_password_hash(payload.password),
        role=payload.role,
        is_active=True,
        is_available=True,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email ya registrado",
        )
    db.refresh(user)
    token = create_access_token(subject=user.username, role=user.role)
    return schemas.Token(access_token=token, user=user)

@router.post("/reset", response_model=schemas.User)
def reset_password(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if not _is_strong_password(user.password):
        raise HTTPException(status_code=400, detail="Weak password")
    normalized = user.username.strip().lower()
    db_user = _get_user_by_username_ci(db, normalized)
    hashed_password = get_password_hash(user.password)
    if not db_user:
        db_user = models.User(
            username=normalized,
            hashed_password=hashed_password,
            role=user.role,
            is_active=True,
        )
        db.add(db_user)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email ya registrado",
            )
        db.refresh(db_user)
        return db_user
    db_user.hashed_password = hashed_password
    db.commit()
    db.refresh(db_user)
    return db_user

@router.get("/me", response_model=schemas.User)
def read_user_me(user: models.User = Depends(get_current_user)):
    return user

@router.put("/{user_id}/availability", response_model=schemas.User)
def update_user_availability(
    user_id: int,
    is_available: bool,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    db_user.is_available = is_available
    db.commit()
    db.refresh(db_user)
    return db_user
