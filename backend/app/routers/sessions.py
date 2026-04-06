from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from app import schemas, models
from app.database import get_db
from app.deps import get_current_user, require_roles

router = APIRouter(
    prefix="/sessions",
    tags=["sessions"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[schemas.Session])
def read_sessions(
    skip: int = 0,
    limit: int = 100,
    patient_id: int | None = None,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    query = db.query(models.Session)
    if patient_id is not None:
        query = query.filter(models.Session.patient_id == patient_id)
    sessions = query.offset(skip).limit(limit).all()
    return sessions

@router.post("/", response_model=schemas.Session)
def create_session(
    session: schemas.SessionCreate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(get_current_user),
):
    # Check if patient exists
    patient = db.query(models.Patient).filter(models.Patient.id == session.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    if session.external_id:
        existing = (
            db.query(models.Session)
            .filter(models.Session.external_id == session.external_id)
            .first()
        )
        if existing:
            return existing

    db_session = models.Session(**session.model_dump())
    db.add(db_session)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if session.external_id:
            existing = (
                db.query(models.Session)
                .filter(models.Session.external_id == session.external_id)
                .first()
            )
            if existing:
                return existing
        raise
    db.refresh(db_session)
    return db_session

@router.get("/{session_id}", response_model=schemas.Session)
def read_session(
    session_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    session = db.query(models.Session).filter(models.Session.id == session_id).first()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")
    return session

@router.get("/count")
def sessions_count(
    patient_id: int | None = None,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    query = db.query(models.Session)
    if patient_id is not None:
        query = query.filter(models.Session.patient_id == patient_id)
    return {"count": query.count()}
