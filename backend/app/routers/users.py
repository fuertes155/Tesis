from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from typing import List
from app import schemas, models
from app.database import get_db
from app.deps import get_current_user, require_roles
from app.security import get_password_hash, verify_password, create_access_token
from app.core.audit import log_action
import re

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

def _is_strong_password(p: str) -> bool:
    return len(p) >= 6


def _get_user_by_username_ci(db: Session, username: str) -> models.User | None:
    normalized = username.strip().lower()
    return (
        db.query(models.User)
        .filter(func.lower(models.User.username) == normalized)
        .first()
    )


def _create_role_profile(db: Session, user: models.User) -> None:
    """Create the role-specific profile (Doctor, Administrator, or Patient) for a user."""
    role = user.role.strip().lower()
    if role == "doctor":
        # Check if already exists to avoid unique constraint errors
        existing = db.query(models.Doctor).filter(models.Doctor.user_id == user.id).first()
        if not existing:
            db.add(models.Doctor(user_id=user.id))
    elif role == "gestor":
        existing = db.query(models.Administrator).filter(models.Administrator.user_id == user.id).first()
        if not existing:
            db.add(models.Administrator(user_id=user.id))
    elif role == "user":
        existing = db.query(models.Patient).filter(models.Patient.user_id == user.id).first()
        if not existing:
            db.add(models.Patient(
                user_id=user.id,
                name=user.full_name or user.username,
                age=0,
            ))
    try:
        db.commit()
    except Exception as e:
        print(f"ERROR: Failed to create role profile: {e}")
        db.rollback()


# ─── READ ─────────────────────────────────────────────────────────────────────

@router.get("/", response_model=List[schemas.User])
def read_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users


@router.get("/me", response_model=schemas.User)
def read_user_me(user: models.User = Depends(get_current_user)):
    return user


# ─── AUTH ──────────────────────────────────────────────────────────────────────

@router.post("/auth/login", response_model=schemas.Token)
def auth_login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    normalized = payload.username.strip().lower()
    user = _get_user_by_username_ci(db, normalized)
    if not user:
        raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")
    try:
        valid_password = verify_password(payload.password, user.hashed_password)
    except Exception as e:
        print(f"ERROR: Password verification failed: {e}")
        valid_password = False

    if not valid_password:
        raise HTTPException(status_code=401, detail="Usuario o contraseña incorrectos")
    
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Cuenta de usuario inactiva. Contacte al administrador.")

    token = create_access_token(subject=user.username, role=user.role)
    return schemas.Token(access_token=token, user=user)


@router.post("/auth/register", response_model=schemas.Token, status_code=status.HTTP_201_CREATED)
def auth_register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    """Public self-registration. Returns JWT token."""
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
        full_name=payload.full_name,
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

    _create_role_profile(db, user)

    token = create_access_token(subject=user.username, role=user.role)
    return schemas.Token(access_token=token, user=user)


# ─── ADMIN (gestor-only) ──────────────────────────────────────────────────────

@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_user(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    _admin: models.User = Depends(require_roles("gestor")),
):
    """Admin-only endpoint to register new users (doctors, gestors, patients)."""
    if not _is_strong_password(user.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La contraseña no cumple los requisitos de seguridad",
        )
    normalized = user.username.strip().lower()
    existing = _get_user_by_username_ci(db, normalized)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email ya registrado",
        )
    hashed_password = get_password_hash(user.password)
    print(f"DEBUG: Registering user with role: {user.role}", flush=True)
    db_user = models.User(
        username=normalized,
        hashed_password=hashed_password,
        full_name=user.full_name,
        role=user.role,
        is_active=True,
        is_available=True,
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

    _create_role_profile(db, db_user)

    log_action(
        db=db,
        user_id=_admin.id,
        action="CREATE",
        entity_type="User",
        entity_id=db_user.id,
        new_value={"username": normalized, "role": user.role},
    )

    return db_user


@router.post("/reset", response_model=schemas.User)
def reset_password(
    user: schemas.UserCreate,
    db: Session = Depends(get_db),
    _admin: models.User = Depends(require_roles("gestor")),
):
    """Admin-only: Reset a user's password, or create a new user if not found."""
    if not _is_strong_password(user.password):
        raise HTTPException(status_code=400, detail="La contraseña no cumple los requisitos de seguridad")
    normalized = user.username.strip().lower()
    db_user = _get_user_by_username_ci(db, normalized)
    hashed_password = get_password_hash(user.password)
    if not db_user:
        # User doesn't exist, create a new one
        db_user = models.User(
            username=normalized,
            hashed_password=hashed_password,
            full_name=user.full_name,
            role=user.role,
            is_active=True,
            is_available=True,
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
        _create_role_profile(db, db_user)

        log_action(
            db=db,
            user_id=_admin.id,
            action="CREATE",
            entity_type="User",
            entity_id=db_user.id,
            new_value={"username": normalized, "role": user.role},
        )

        return db_user

    # User exists, update password
    old_role = db_user.role
    db_user.hashed_password = hashed_password
    db.commit()
    db.refresh(db_user)

    log_action(
        db=db,
        user_id=_admin.id,
        action="UPDATE",
        entity_type="User",
        entity_id=db_user.id,
        old_value={"username": normalized},
        new_value={"password_reset": True},
    )

    return db_user


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


@router.put("/{user_id}", response_model=schemas.User)
def update_user(
    user_id: int,
    payload: schemas.UserUpdate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("gestor")),
):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    data = payload.model_dump(exclude_unset=True)

    if "username" in data and data["username"] is not None:
        normalized = data["username"].strip()
        if normalized != db_user.username:
            existing = _get_user_by_username_ci(db, normalized)
            if existing and existing.id != db_user.id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email ya registrado",
                )
            db_user.username = normalized

    if "full_name" in data and data["full_name"] is not None:
        db_user.full_name = data["full_name"]

    if "role" in data and data["role"] is not None:
        new_role = data["role"].strip().lower()
        if new_role != db_user.role:
            db_user.role = new_role
            # Ensure the new profile is created if it doesn't exist
            _create_role_profile(db, db_user)

    if "is_active" in data and data["is_active"] is not None:
        db_user.is_active = bool(data["is_active"])

    if "is_available" in data and data["is_available"] is not None:
        db_user.is_available = bool(data["is_available"])

    db.commit()
    db.refresh(db_user)
    return db_user


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    _admin: models.User = Depends(require_roles("gestor")),
):
    """Admin-only: permanently delete a user and their role profile."""
    if _admin.id == user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puedes eliminarte a ti mismo",
        )

    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    old_data = {
        "id": db_user.id,
        "username": db_user.username,
        "role": db_user.role,
    }

    # Remove role-specific profiles
    db.query(models.Doctor).filter(models.Doctor.user_id == user_id).delete(
        synchronize_session=False
    )
    db.query(models.Administrator).filter(
        models.Administrator.user_id == user_id
    ).delete(synchronize_session=False)

    # Remove sessions tied to patients owned by this user, then the patients
    owned_patients = (
        db.query(models.Patient)
        .filter(models.Patient.user_id == user_id)
        .all()
    )
    for p in owned_patients:
        db.query(models.Session).filter(
            models.Session.patient_id == p.id
        ).delete(synchronize_session=False)
    db.query(models.Patient).filter(
        models.Patient.user_id == user_id
    ).delete(synchronize_session=False)

    db.delete(db_user)
    db.commit()

    log_action(
        db=db,
        user_id=_admin.id,
        action="DELETE",
        entity_type="User",
        entity_id=user_id,
        old_value=old_data,
    )

    return {"status": "deleted", "id": user_id}
