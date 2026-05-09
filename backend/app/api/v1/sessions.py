from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from app.infrastructure import models
from app.infrastructure.database import get_db
from app.domain import entities
from app.api.deps import get_current_user, require_roles
from app.core.audit import log_action

router = APIRouter()


@router.get("/", response_model=List[entities.Session])
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


@router.post("/", response_model=entities.Session)
def create_session(
    session: entities.SessionCreate,
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

    log_action(
        db=db,
        user_id=_user.id,
        action="CREATE",
        entity_type="Session",
        entity_id=db_session.id,
        new_value=session.model_dump(),
    )

    return db_session


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


@router.post("/results", status_code=201, response_model=entities.Result)
def submit_results(
    data: entities.ResultCreate,
    db: Session = Depends(get_db),
    _user: models.User = Depends(get_current_user),
):
    # If session_id is provided, verify it exists
    if data.session_id:
        session = db.query(models.Session).filter(models.Session.id == data.session_id).first()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")

    db_result = models.Result(**data.model_dump())
    db.add(db_result)
    db.commit()
    db.refresh(db_result)

    log_action(
        db=db,
        user_id=_user.id,
        action="CREATE",
        entity_type="Result",
        entity_id=db_result.id,
        new_value=data.model_dump(),
    )

    return db_result


@router.get("/results/latest", response_model=List[entities.Result])
def get_latest_results(
    patient_id: int,
    limit: int = 10,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    results = (
        db.query(models.Result)
        .filter(models.Result.patient_id == patient_id)
        .order_by(models.Result.timestamp.desc())
        .limit(limit)
        .all()
    )
    return results


@router.get("/{session_id}", response_model=entities.Session)
def read_session(
    session_id: int,
    db: Session = Depends(get_db),
    _user: models.User = Depends(require_roles("doctor", "gestor")),
):
    session = db.query(models.Session).filter(models.Session.id == session_id).first()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")
    return session
