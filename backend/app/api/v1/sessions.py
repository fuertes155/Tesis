from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ....infrastructure.database import get_db
from ....application.services import SessionService
from ....domain import entities

router = APIRouter()

@router.get("/", response_model=list[entities.Session])
def read_sessions(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return SessionService.get_sessions(db, skip=skip, limit=limit)

@router.post("/", response_model=entities.Session)
def create_session(session: entities.SessionCreate, db: Session = Depends(get_db)):
    return SessionService.create_session(db=db, session=session)
