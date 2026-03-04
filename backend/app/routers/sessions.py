from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app import schemas, models
from app.database import get_db

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
    db: Session = Depends(get_db)
):
    query = db.query(models.Session)
    if patient_id is not None:
        query = query.filter(models.Session.patient_id == patient_id)
    sessions = query.offset(skip).limit(limit).all()
    return sessions

@router.post("/", response_model=schemas.Session)
def create_session(session: schemas.SessionCreate, db: Session = Depends(get_db)):
    # Check if patient exists
    patient = db.query(models.Patient).filter(models.Patient.id == session.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
        
    db_session = models.Session(**session.model_dump())
    db.add(db_session)
    db.commit()
    db.refresh(db_session)
    return db_session

@router.get("/{session_id}", response_model=schemas.Session)
def read_session(session_id: int, db: Session = Depends(get_db)):
    session = db.query(models.Session).filter(models.Session.id == session_id).first()
    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")
    return session

@router.get("/count")
def sessions_count(patient_id: int | None = None, db: Session = Depends(get_db)):
    query = db.query(models.Session)
    if patient_id is not None:
        query = query.filter(models.Session.patient_id == patient_id)
    return {"count": query.count()}
